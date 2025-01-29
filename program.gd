extends Control

@onready var screen = $Screen

@onready var texture_cube = $SubViewportContainer/SubViewport/SliceVisualizer/TextureCube

@onready var intersection_plane = $SubViewportContainer/SubViewport/SliceVisualizer/IntersectionPlane

@onready var label = $Label

var matrix := Basis.IDENTITY

var display_size := 0.5

var z_offset := 0.5

var image: Image

# Max is 128
var image_size := 128

var old_integer_mouse_coord: Vector2i

var brush_color := Color.WHITE

func _ready():
	image = Image.create_empty(image_size, image_size * image_size, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	update_image()
	screen.material.set_shader_parameter("z_width", image_size)

func _process(delta):
	label.text = str(Engine.get_frames_per_second())
	
	if Input.is_action_pressed("rotate left"):
		matrix = Basis.from_euler(Vector3(0.0, delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate right"):
		matrix = Basis.from_euler(Vector3(0.0, -delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate up"):
		matrix = Basis.from_euler(Vector3(delta, 0.0, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate down"):
		matrix = Basis.from_euler(Vector3(-delta, 0.0, 0.0) * 2.0) * matrix
	
	if Input.is_action_just_pressed("z axis"):
		matrix = Basis.IDENTITY
	if Input.is_action_just_pressed("x axis"):
		matrix = Basis.from_euler(Vector3(0.0, PI * 0.5, 0.0))
	if Input.is_action_just_pressed("y axis"):
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
	z_offset = clampf(z_offset, 0.0, 0.99)
	screen.material.set_shader_parameter("z_offset", z_offset)
	intersection_plane.position.z = z_offset - 0.5
	
	if Input.is_action_pressed("paint"):
		if old_integer_mouse_coord != calculate_integer_mouse_coordinate(mouse_position_3d):
			color_pixel(mouse_position_3d, brush_color)
			update_image()
	
	old_integer_mouse_coord = calculate_integer_mouse_coordinate(mouse_position_3d)

func color_pixel(mouse_position_3d: Vector3, color: Color) -> void:
	image.set_pixelv(calculate_integer_mouse_coordinate(mouse_position_3d), color)

func calculate_integer_mouse_coordinate(mouse_position_3d: Vector3) -> Vector2i:
	return Vector2i(int(mouse_position_3d.x * image_size), int(mouse_position_3d.y * image_size) + (int(mouse_position_3d.z * image_size) * image_size))

func update_image():
	var texture = ImageTexture.create_from_image(image)
	
	screen.material.set_shader_parameter("image", texture)
