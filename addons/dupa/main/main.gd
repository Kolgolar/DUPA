extends Control


func _ready():
	show_start_screen()


func show_start_screen():
	%StartScreen.show()
	$Editor.hide()


func _on_open_timeline() -> void:
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.OPEN_TIMELINE, true, %Editor._on_dupa_file_manager_file_selected)
	add_child(fm)


func _on_create_timeline() -> void:
	%Editor.new_timeline()
