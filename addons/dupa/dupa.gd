@tool
extends EditorPlugin

var button: Button
const SCENE_PATH := "res://addons/dupa/main/main.tscn"

func _enter_tree():
	button = Button.new()
	button.text = "▶ Launch DUPA"
	#button.expand_icon = true
	button.icon = load("res://addons/dupa/common/ui/textures/dupa_icon_small.png")
	button.tooltip_text = "Запускает сцену: " + SCENE_PATH
	button.pressed.connect(_on_button_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, button)

func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	button.queue_free()

func _on_button_pressed():
	var file = FileAccess.open(SCENE_PATH, FileAccess.READ)
	if file:
		get_editor_interface().play_custom_scene(SCENE_PATH)
	else:
		printerr("Сцена не найдена: ", SCENE_PATH)
