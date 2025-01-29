extends Control

@onready var screen = $Screen

@onready var texture_cube = $SubViewportContainer/SubViewport/SliceVisualizer/TextureCube

var matrix := Basis.IDENTITY

var display_size := 0.5

func _process(delta):
	if Input.is_action_pressed("ui_down"):
		matrix = Basis.from_euler(Vector3(0.0, delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("ui_right"):
		matrix = Basis.from_euler(Vector3(0.0, 0.0, delta) * 2.0) * matrix
	if Input.is_action_pressed("ui_left"):
		matrix = Basis.from_euler(Vector3(delta, 0.0, 0.0) * 2.0) * matrix
	screen.material.set_shader_parameter("rotation", matrix)
	texture_cube.basis = matrix
	
	var mouse_position_2d = get_global_mouse_position() / Vector2(2560.0, 1440.0)
	mouse_position_2d *= Vector2(16.0, 9.0) / 9.0
	mouse_position_2d *= 1.0 / display_size
	mouse_position_2d -= Vector2(16.0 / 9.0 * (1.0 / (display_size * 2.0)), (1.0 / (display_size * 2.0)))
	mouse_position_2d += Vector2(0.5, 0.5)
	
	var mouse_position_3d := Vector3(mouse_position_2d.x, mouse_position_2d.y, 0.5)
	mouse_position_3d -= Vector3.ONE * 0.5
	mouse_position_3d *= matrix
	mouse_position_3d += Vector3.ONE * 0.5
	
	screen.material.set_shader_parameter("mouse_position", mouse_position_3d)
