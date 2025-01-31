extends Window

var _folder_path : String

@onready var _directory = $VBoxContainer/HBoxContainer/LineEdit

signal load_dialog
signal directory_updated


func _ready() -> void:
	_directory.text = SaS.default_directory
	if not _directory.text.is_empty():
		_get_dialogues()


func _get_dialogues() -> void:
	var path = _directory.text
	if path.is_empty(): return
	_folder_path = path
	if not _folder_path.ends_with("\\"):
		_folder_path += "\\"
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".json"): # TODO: Check for super.json
			files.append(file)

	dir.list_dir_end()

	if files.size() == 0:
		return
	
	emit_signal("directory_updated", _folder_path)
	
	var butt_container : VBoxContainer = $VBoxContainer/ScrollContainer/Dialogues
	
	for b in butt_container.get_children():
		b.queue_free()

	for f in files:
		var butt = Button.new()
		butt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		butt.text = f
		$VBoxContainer/ScrollContainer/Dialogues.add_child(butt)
		butt.connect("pressed", Callable(self, "_on_dialogue_choosen").bind(f))
	

func _refresh() -> void:
	_get_dialogues()
	SaS.default_directory = _directory.text
	SaS.save_data()


func _on_dialogue_choosen(file_name : String) -> void:
	# file_name = file_name.split(".json")[0]
	print(_folder_path)
	print(file_name)
	emit_signal("load_dialog", _folder_path, file_name)
	popup()


func _on_Refresh_pressed() -> void:
	_refresh()


func _on_DialoguesSearcher_about_to_show():
	_refresh()


func _on_close_requested() -> void:
	hide()
