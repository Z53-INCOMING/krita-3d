extends Control

@onready var screen = $ColorRect

var matrix = Basis.IDENTITY

func _process(delta):
	if Input.is_action_pressed("ui_down"):
		matrix = Basis.from_euler(Vector3(0.0, delta, 0.0) * 2.0) * matrix
	if Input.is_action_pressed("ui_right"):
		matrix = Basis.from_euler(Vector3(0.0, 0.0, delta) * 2.0) * matrix
	if Input.is_action_pressed("ui_left"):
		matrix = Basis.from_euler(Vector3(delta, 0.0, 0.0) * 2.0) * matrix
	screen.material.set_shader_parameter("rotation", matrix)
