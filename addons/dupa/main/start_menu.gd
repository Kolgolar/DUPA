extends PanelContainer

signal create_timeline
signal open_timeline


func _on_new_pressed() -> void:
	create_timeline.emit()


func _on_open_pressed() -> void:
	open_timeline.emit()


func _on_help_pressed() -> void:
	OS.shell_open("https://github.com/Kolgolar/DUPA/blob/rework/README.md")


func _on_exit_pressed() -> void:
	get_tree().quit()
