extends Control





func _on_start_pressed():
	get_tree().change_scene_to_file("res://level_select.tscn") 

func _on_option_pressed():
	get_tree().change_scene_to_file("res://scene/settings.tscn") 

func _on_quit_pressed():
	get_tree().quit()
