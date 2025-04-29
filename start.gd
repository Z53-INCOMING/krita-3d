extends Control

func _on_create_button_down():
	$create.hide()
	$load.hide()
	$createOptions.show()

func _on_create_file_button_down():
	Globals.resolution = clampi(int($createOptions/resolutionPicker.text), 2, 128)
	Globals.background_color = $createOptions/ColorPicker.color
	get_tree().change_scene_to_file("res://program.tscn")

func _on_load_button_down():
	$FileDialog.popup()


func _on_file_dialog_file_selected(path):
	var image := Image.load_from_file(path)
	
	if image.get_size().y == image.get_size().x * image.get_size().x:
		Globals.new_file = false
		Globals.file_path = path
		get_tree().change_scene_to_file("res://program.tscn")
	else:
		$imageWarning.show()
		$create.show()
		$load.show()
