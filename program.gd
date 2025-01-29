extends Control

@onready var screen = $Screen

@onready var texture_cube = $SubViewportContainer/SubViewport/SliceVisualizer/TextureCube

@onready var intersection_plane = $SubViewportContainer/SubViewport/SliceVisualizer/IntersectionPlane

var matrix := Basis.IDENTITY

var display_size := 0.5

var z_offset := 0.5

func _process(delta):
	if Input.is_action_pressed("rotate left"):
		matrix = Basis.from_euler(Vector3(0.0, delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate right"):
		matrix = Basis.from_euler(Vector3(0.0, -delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate up"):
		matrix = Basis.from_euler(Vector3(delta, 0.0, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("rotate down"):
		matrix = Basis.from_euler(Vector3(-delta, 0.0, 0.0) * 2.0) * matrix
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
		z_offset -= 1.0 / 32.0
	if Input.is_action_just_released("scroll_up"):
		z_offset += 1.0 / 32.0
	z_offset = clampf(z_offset, 0.0, 0.99)
	screen.material.set_shader_parameter("z_offset", z_offset)
	intersection_plane.position.z = z_offset - 0.5
