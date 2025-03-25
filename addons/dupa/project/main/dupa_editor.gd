extends Control

@export var graph_edit: GraphEdit
@export var error_popup: AcceptDialog
@export var error_popup_label: RichTextLabel
@export var deletion_popup: ConfirmationDialog

var file_name := ""
var directory := ""

@export var _actions_master: ActionsMaster



func _input(event):
	if event.is_action_pressed(&"save"):
		_on_save_pressed()
	
	elif event.is_action_pressed(&"ui_undo"):
		_actions_master.undo()
	elif event.is_action_pressed(&"ui_redo"):
		_actions_master.redo()


func reset() -> void:
	graph_edit.clear_nodes()
	_set_filename("(not saved!)")



#--------------------------------------------
# Логика сохранения или открытия файла таймлайна
#--------------------------------------------
#region Saving&Loading

func save_dialog(path, fn):
	# save file
	var err = graph_edit.validation()
	if fn.is_empty():
		printerr("File name is empty!")
		return
	# file_path = file_path
	if not ".json" in fn:
		fn += ".json"
	
	var data = {}
	data[&"CONFIG"] = {"max_id" : graph_edit.max_id}
	data[&"TIMELINE"] = graph_edit.dialog
	var file = FileAccess.open(path.path_join(fn), FileAccess.WRITE)
	file.store_line(JSON.new().stringify(data))
	
	file.close()
	
	if err != OK:
		printerr("Error on validation!")
		show_popup_error("Saving complete, but you must resolve errors!")

	%SaveNotify.show()
	await get_tree().create_timer(3.0).timeout
	%SaveNotify.hide()


func load_save(path: String):
	var fn = path.split("/")[-1]
	if path.is_empty() or fn.is_empty():
		print("File not found at %s" % path)
		return
	
	show()
	reset()
	_set_filename(fn)

	var file = FileAccess.open(path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	file.close()
	
	
	
	var timeline = data[&"TIMELINE"]
	var config = data[&"CONFIG"]

	graph_edit.set_timeline(timeline, config)


func _set_filename(new_name : String) -> void:
	%TimelineName.text = new_name
	file_name = new_name


func _on_dupa_file_manager_file_selected(path: String) -> void:
	load_save(path)
	show()


func _on_save_dialog_as(path: String):
	var directory = path.get_base_dir()
	var fn = path.get_file()
	_set_filename(fn)
	#_on_save_pressed()
	save_dialog(directory, fn)


func _save_as():
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.SAVE_TIMELINE, true, _on_save_dialog_as)
	add_child(fm)


func _on_open_new_pressed():
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.OPEN_TIMELINE, true, _on_dupa_file_manager_file_selected)
	add_child(fm)


func _on_save_pressed(): 
	graph_edit.dialog.clear()
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		graph_edit.dialog[str(node.id)] = (node.gen_data())
	
	if file_name.is_empty() || directory.is_empty():
		_save_as()
		return

	save_dialog(directory, file_name)


func _on_save_as_pressed():
	_save_as()

#endregion



#--------------------------------------------
# Показ попапа ошибки
#--------------------------------------------


func show_popup_error(error_text : String) -> void:
	error_popup_label.clear()
	var time = Time.get_time_dict_from_system()
	error_popup_label.text = "[{0}:{1}:{2}".format([time["hour"], time["minute"], time["second"]]) + "]  " + error_text + "\n"
	error_popup.popup()


func _on_dupa_graph_edit_error(error_text: String) -> void:
	show_popup_error(error_text)



#--------------------------------------------
# Прочая логика интерфейса редактора
#--------------------------------------------


func new_timeline():
	if !file_name.is_empty():
		# TODO: Стыбзить из лмстудио код создания конфёрм попапов
		# Спросить, точно ли пользователь хочет создать новый таймлайн, ведь тут есть
		# несохранённые изменения
		# TODO: Соответственно, нужен механизм туду реду, чтобы определять, были
		# ли совершены действия, которые не были сохранены.
		pass
	show()
	reset()


func _on_new_pressed():
	new_timeline()


func _on_clear_pressed():
	deletion_popup.popup_centered()


func _on_deletion_confirmed():
	graph_edit.clear_nodes()



#--------------------------------------------
# История действий
#--------------------------------------------


func _on_undo_action_pressed() -> void:
	_actions_master.undo()


func _on_redo_action_pressed() -> void:
	_actions_master.redo()
