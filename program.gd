extends Control

@onready var screen = $Screen

@onready var texture_cube = $SubViewportContainer/SubViewport/SliceVisualizer/TextureCube

@onready var intersection_plane = $SubViewportContainer/SubViewport/SliceVisualizer/IntersectionPlane

@onready var label = $Label

@onready var volume = $SubViewportContainer2/SubViewport/VolumetricTextureViewer/VolumetricTexture

@onready var volume_camera = $SubViewportContainer2/SubViewport/VolumetricTextureViewer/Pivot

var matrix := Basis.IDENTITY

var volume_texture_matrix := Basis.IDENTITY

var display_size := 0.5

var z_offset := 0.5

var image: Image

# Max is 128, works better with powers of two
var image_size := 16

var old_integer_mouse_coord: Vector2i

var brush_color := Color.WHITE

var past_images: Array[Image]

var point_in_history := 0

var volumetric_shader: ShaderMaterial

var brush_radius := 0.0

var drag_start: Vector3

var volume_cam_speed := 1.0

var tool := 0

@onready var tool_label := $CurrentTool

func _ready():
	if Globals.new_file:
		image_size = Globals.resolution
		var empty = Image.create_empty(image_size, image_size * image_size, false, Image.FORMAT_RGBA8)
		empty.fill(Globals.background_color)
		
		load_image(empty)
	else:
		load_image(Image.load_from_file(Globals.file_path))

func load_image(to_load: Image) -> void:
	image = to_load.duplicate(true)
	image_size = image.get_width()
	past_images.append(image.duplicate(true))
	screen.material.set_shader_parameter("z_width", image_size)
	
	var placeholder = PlaceholderTexture2D.new()
	placeholder.size = Vector2(image_size, image_size) * 2
	volumetric_shader = ShaderMaterial.new()
	volumetric_shader.shader = load("res://volumetric slice.gdshader")
	volumetric_shader.set_shader_parameter("image_size", image_size)
	for i in image_size * 2:
		var sprite = Sprite3D.new()
		
		sprite.texture = placeholder
		sprite.pixel_size = 2.0 / float(image_size)
		sprite.material_override = volumetric_shader
		sprite.position.z = (float(i) / float(image_size)) * 2.0 - 2.0
		
		volume.add_child(sprite)
	
	update_image()

func _process(delta):
	if Input.is_action_just_pressed("brush"):
		tool = 0
	if Input.is_action_just_pressed("fill"):
		tool = 1
	
	match tool:
		0:
			tool_label.text = "Tool: Brush"
		1:
			tool_label.text = "Tool: Fill"
	
	label.text = str(Engine.get_frames_per_second())
	
	if Input.is_action_just_pressed("save"):
		if Globals.file_path == "":
			$FileDialog.popup()
		else:
			image.save_png(Globals.file_path)
	
	if Input.is_action_pressed("rotate left"):
		matrix = Basis.from_euler(Vector3(0.0, -delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate right"):
		matrix = Basis.from_euler(Vector3(0.0, delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate up"):
		matrix = Basis.from_euler(Vector3(delta, 0.0, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate down"):
		matrix = Basis.from_euler(Vector3(-delta, 0.0, 0.0) * 2.0) * matrix
	
	if Input.is_action_just_pressed("z axis") and !Input.is_action_pressed("undo"):
		matrix = Basis.IDENTITY
	if Input.is_action_just_pressed("x axis"):
		matrix = Basis.from_euler(Vector3(0.0, -PI * 0.5, 0.0))
	if Input.is_action_just_pressed("y axis") and !Input.is_action_pressed("redo"):
		matrix = Basis.from_euler(Vector3(PI * 0.5, 0.0, 0.0))
	
	screen.material.set_shader_parameter("rotation", matrix)
	texture_cube.basis = matrix
	
	var mouse_position_2d = get_global_mouse_position() / Vector2(2560.0, 1440.0)
	mouse_position_2d *= Vector2(16.0, 9.0) / 9.0
	mouse_position_2d *= 1.0 / display_size
	mouse_position_2d -= Vector2(16.0 / 9.0 * (1.0 / (display_size * 2.0)), (1.0 / (display_size * 2.0)))
	mouse_position_2d += Vector2(1.0, 0.5)
	
	var mouse_position_3d := Vector3(mouse_position_2d.x, mouse_position_2d.y, z_offset)
	mouse_position_3d -= Vector3.ONE * 0.5
	mouse_position_3d *= matrix
	mouse_position_3d += Vector3.ONE * 0.5
	
	screen.material.set_shader_parameter("mouse_position", mouse_position_3d)
	
	if get_global_mouse_position().x < 1280:
		if Input.is_action_just_released("scroll_down"):
			if Input.is_action_pressed("shift"):
				z_offset -= 1.0 / 8.0
			else:
				z_offset -= 1.0 / float(image_size)
		if Input.is_action_just_released("scroll_up"):
			if Input.is_action_pressed("shift"):
				z_offset += 1.0 / 8.0
			else:
				z_offset += 1.0 / float(image_size)
	else:
		if Input.is_action_just_released("scroll_down"):
			volume_camera.position.z += 0.25
		if Input.is_action_just_released("scroll_up"):
			volume_camera.position.z -= 0.25
		volume_camera.position.z = clampf(volume_camera.position.z, 0.25, 3.0)
	z_offset = clampf(z_offset, 0.0, float(image_size - 1) / float(image_size))
	screen.material.set_shader_parameter("z_offset", z_offset + (1.0 / 1000.0))
	intersection_plane.position.z = z_offset - 0.5
	
	if AABB(Vector3.ZERO, Vector3.ONE).has_point(mouse_position_3d):
		#if Input.is_action_just_pressed("paint"):
			#drag_start = mouse_position_3d
		#if Input.is_action_just_released("paint"):
			#sphere(drag_start, mouse_position_3d, brush_color)
		if Input.is_action_pressed("paint"):
			brush(mouse_position_3d, brush_color)
		if Input.is_action_pressed("erase"):
			brush(mouse_position_3d, Globals.background_color)
		if Input.is_action_just_released("paint") or Input.is_action_just_released("erase"):
			past_images.append(image.duplicate(true)) # save in case of undo
			while past_images.size() > point_in_history + 2:
				past_images.remove_at(point_in_history + 1)
			point_in_history = past_images.size() - 1
			old_integer_mouse_coord = -Vector2i.ONE
	
	if past_images.size() > 16:
		past_images.remove_at(0)
		point_in_history -= 1
	
	if Input.is_action_just_pressed("undo") and !Input.is_action_pressed("shift"):
		if !past_images.is_empty():
			point_in_history -= 1
			if point_in_history > -1:
				image = past_images[point_in_history].duplicate(true)
				update_image()
			else:
				point_in_history = 0
	
	if Input.is_action_just_pressed("redo"):
		if !past_images.is_empty():
			point_in_history += 1
			if point_in_history < past_images.size():
				image = past_images[point_in_history].duplicate(true)
				update_image()
			else:
				point_in_history = past_images.size() - 1
				image = past_images[-1].duplicate(true)
				update_image()
	
	if Input.is_action_just_pressed("export"):
		export_project()

func brush(mouse_position_3d: Vector3, color: Color):
	var current_integer_mouse_coord := calculate_integer_mouse_coordinate(mouse_position_3d)
	var selected_pixel_3d = Vector3i(floor(mouse_position_3d * float(image_size)))
	if old_integer_mouse_coord != current_integer_mouse_coord:
		if brush_radius > 1.0:
			for x in range(selected_pixel_3d.x - int(ceil(brush_radius)), selected_pixel_3d.x + int(ceil(brush_radius) + 1)):
				for y in range(selected_pixel_3d.y - int(ceil(brush_radius)), selected_pixel_3d.y + int(ceil(brush_radius) + 1)):
					for z in range(selected_pixel_3d.z - int(ceil(brush_radius)), selected_pixel_3d.z + int(ceil(brush_radius) + 1)):
						if Vector3(x, y, z).distance_squared_to(Vector3(selected_pixel_3d)) < brush_radius * brush_radius:
							color_pixel(Vector3(x, y, z) / float(image_size), color)
		else:
			color_pixel(mouse_position_3d, color)
		
		old_integer_mouse_coord = current_integer_mouse_coord
		update_image()

func sphere(start: Vector3, end: Vector3, color: Color):
	var center := (start + end) * 0.5 * float(image_size)
	var extents = abs(end - start) * float(image_size)
	for x in range(int(start.x * image_size), int(end.x * image_size) + 1):
		for y in range(int(start.y * image_size), int(end.y * image_size) + 1):
			for z in range(int(start.z * image_size), int(end.z * image_size) + 1):
				var distance = ((Vector3(x, y, z) - center) / extents).length_squared()
				if distance < 0.5 * 0.5 and distance > 0.48 * 0.48:
					color_pixel(Vector3(x, y, z) / float(image_size), color)
	
	update_image()

func export_project() -> void:
	var id := randi() % 4096
	image.save_png("user://" + str(id) + ".png")

func color_pixel(mouse_position_3d: Vector3, color: Color) -> void:
	image.set_pixelv(calculate_integer_mouse_coordinate(mouse_position_3d.clamp(Vector3.ZERO, Vector3.ONE * 0.9999)), color)

func calculate_integer_mouse_coordinate(mouse_position_3d: Vector3) -> Vector2i:
	var pixel_3d = Vector3i(floor(mouse_position_3d * float(image_size)))
	return Vector2i(pixel_3d.x, pixel_3d.y + (pixel_3d.z * image_size))
	#return Vector2i(int(mouse_position_3d.x * image_size), int(mouse_position_3d.y * image_size) + (int(mouse_position_3d.z * image_size) * image_size))

func update_image():
	var linear_image = image.duplicate(true)
	linear_image.srgb_to_linear()
	var texture = ImageTexture.create_from_image(linear_image)
	
	screen.material.set_shader_parameter("image", ImageTexture.create_from_image(image))
	volumetric_shader.set_shader_parameter("image", texture)
	volumetric_shader.set_shader_parameter("rotation", volume_texture_matrix)

func _input(event):
	if event is InputEventMouseMotion:
		if get_global_mouse_position().x > 1280:
			if Input.is_action_pressed("pan"):
				volume_texture_matrix *= Basis.from_euler(Vector3(0.0, -event.relative.x / 432.0, 0.0))
				volume_texture_matrix *= Basis.from_euler(Vector3(event.relative.y / 432.0, 0.0, 0.0))
				volumetric_shader.set_shader_parameter("rotation", volume_texture_matrix)


func _on_color_picker_button_color_changed(color):
	brush_color = color
	screen.material.set_shader_parameter("brush_color", brush_color)

func _on_h_slider_value_changed(value):
	brush_radius = value

func _on_file_dialog_file_selected(path):
	image.save_png(path)
	Globals.file_path = path

func _on_alpha_slider_value_changed(value):
	volumetric_shader.set_shader_parameter("alpha", value)

func _on_disable_black_toggled(toggled_on):
	volumetric_shader.set_shader_parameter("disable_black", toggled_on)
