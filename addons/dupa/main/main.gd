extends Control

@export var _viewer_scn: PackedScene = preload("res://addons/dupa/viewer/dialog_viewer.tscn")

var _viewer: DUPA_Display


func _ready():
	show_start_screen()


func show_start_screen():
	%StartScreen.show()
	%Editor.hide()


func _on_open_timeline() -> void:
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.OPEN_TIMELINE, true, %Editor._on_dupa_file_manager_file_selected)
	add_child(fm)


func _on_create_timeline() -> void:
	%Editor.new_timeline()


func _on_editor_viewer_requested(blueprint_file_path: String) -> void:
	if _viewer:
		push_error("Dialog viewer is already created!")
		return
	$Editor.can_launch_viewer = false
	_viewer = _viewer_scn.instantiate()
	_viewer.blueprint_file = blueprint_file_path
	var window := Window.new()
	add_child(window)
	window.add_child(_viewer)
	window.popup_centered(get_viewport_rect().size * 0.9)
	window.close_requested.connect(_on_viewer_close_requested)
	_viewer.start_dialog(blueprint_file_path)

# TODO: Завершать диалог в случае ошибок (или после того, как они были показаны?) И передавать код/текст ошибки.
func _on_viewer_close_requested() -> void:
	_viewer.get_parent().queue_free()
	%Editor.can_launch_viewer = true


func _on_editor_main_menu_requested() -> void:
	%StartScreen.show()
	%Editor.hide()
