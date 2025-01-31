extends Control

@onready var screen = $Screen

@onready var texture_cube = $SubViewportContainer/SubViewport/SliceVisualizer/TextureCube

@onready var intersection_plane = $SubViewportContainer/SubViewport/SliceVisualizer/IntersectionPlane

@onready var label = $Label

@onready var volume = $SubViewportContainer2/SubViewport/VolumetricTextureViewer/VolumetricTexture

@onready var volume_camera = $SubViewportContainer2/SubViewport/VolumetricTextureViewer/Pivot

var matrix := Basis.IDENTITY

var display_size := 0.5

var z_offset := 0.5

var image: Image

# Max is 128, works better with powers of two
var image_size := 32

var old_integer_mouse_coord: Vector2i

var brush_color := Color.WHITE

var past_images: Array[Image]

var point_in_history := 0

var volumetric_shader: ShaderMaterial

func _ready():
	if false:
		load_image(Image.load_from_file(""))
	else:
		var empty = Image.create_empty(image_size, image_size * image_size, false, Image.FORMAT_RGBA8)
		empty.fill(Color.BLACK)
		
		load_image(empty)

func load_image(to_load: Image) -> void:
	image = to_load.duplicate(true)
	image_size = image.get_width()
	past_images.append(image.duplicate(true))
	screen.material.set_shader_parameter("z_width", image_size)
	
	var placeholder = PlaceholderTexture2D.new()
	placeholder.size = Vector2(image_size, image_size)
	volumetric_shader = ShaderMaterial.new()
	volumetric_shader.shader = load("res://volumetric slice.gdshader")
	volumetric_shader.set_shader_parameter("image_size", image_size)
	for i in image_size:
		var sprite = Sprite3D.new()
		
		sprite.texture = placeholder
		sprite.pixel_size = 2.0 / float(image_size)
		sprite.material_override = volumetric_shader
		sprite.position.z = (float(i) / float(image_size)) * 2.0 - 1.0
		
		volume.add_child(sprite)
	
	update_image()

func _process(delta):
	label.text = str(Engine.get_frames_per_second())
	
	volume_camera.rotation.y = sin(float(Time.get_ticks_msec()) / 250.0) * 0.125
	
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
	mouse_position_2d += Vector2(0.5, 0.5)
	
	var mouse_position_3d := Vector3(mouse_position_2d.x, mouse_position_2d.y, z_offset)
	mouse_position_3d -= Vector3.ONE * 0.5
	mouse_position_3d *= matrix
	mouse_position_3d += Vector3.ONE * 0.5
	
	screen.material.set_shader_parameter("mouse_position", mouse_position_3d)
	
	if Input.is_action_just_released("scroll_down"):
		z_offset -= 1.0 / float(image_size)
	if Input.is_action_just_released("scroll_up"):
		z_offset += 1.0 / float(image_size)
	z_offset = clampf(z_offset, 0.0, float(image_size - 1) / float(image_size))
	screen.material.set_shader_parameter("z_offset", z_offset)
	intersection_plane.position.z = z_offset - 0.5
	
	if Input.is_action_pressed("paint"):
		if old_integer_mouse_coord != calculate_integer_mouse_coordinate(mouse_position_3d):
			color_pixel(mouse_position_3d, brush_color)
			old_integer_mouse_coord = calculate_integer_mouse_coordinate(mouse_position_3d)
			update_image()
	if Input.is_action_pressed("erase"):
		if old_integer_mouse_coord != calculate_integer_mouse_coordinate(mouse_position_3d):
			color_pixel(mouse_position_3d, Color.BLACK)
			old_integer_mouse_coord = calculate_integer_mouse_coordinate(mouse_position_3d)
			update_image()
	if Input.is_action_just_released("paint") or Input.is_action_just_released("erase"):
		past_images.append(image.duplicate(true)) # save in case of undo
		while past_images.size() > point_in_history + 2:
			past_images.remove_at(point_in_history + 1)
		point_in_history = past_images.size() - 1
	
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

func export_project() -> void:
	var id := randi() % 4096
	image.save_png("user://" + str(id) + ".png")

func color_pixel(mouse_position_3d: Vector3, color: Color) -> void:
	image.set_pixelv(calculate_integer_mouse_coordinate(mouse_position_3d), color)

func calculate_integer_mouse_coordinate(mouse_position_3d: Vector3) -> Vector2i:
	return Vector2i(int(mouse_position_3d.x * image_size), int(mouse_position_3d.y * image_size) + (int(mouse_position_3d.z * image_size) * image_size))

func update_image():
	var texture = ImageTexture.create_from_image(image)
	
	screen.material.set_shader_parameter("image", texture)
	volumetric_shader.set_shader_parameter("image", texture)
