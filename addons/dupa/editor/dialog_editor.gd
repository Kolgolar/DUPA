extends Control

#signal saving_complete(err_code: int)
signal viewer_requested(blueprint_file_path: String)
signal main_menu_requested

@export var _compare_versions := true

@export var graph_edit: GraphEdit
@export var error_popup: AcceptDialog
@export var error_popup_label: RichTextLabel
@export var deletion_popup: ConfirmationDialog

var blueprint_file_path := "":
	set(value):
		blueprint_file_path = value
		if value.is_empty():
			%TimelineName.text = "(not saved!)"
		else:
			%TimelineName.text = value.get_file()

@export var _actions_master: ActionsMaster

@onready var can_launch_viewer := true:
	set(value):
		can_launch_viewer = value
		%LaunchViewer.disabled = !value
		
var _on_saving_complete: Callable



func _ready():
	var save_event = InputEventKey.new()
	save_event.keycode = KEY_S
	save_event.ctrl_pressed = true
	InputMap.add_action(&"dupa_save")
	InputMap.action_add_event(&"dupa_save", save_event)



func _input(event):
	if event.is_action_pressed(&"dupa_save"):
		_on_save_pressed()
	
	elif event.is_action_pressed(&"ui_undo"):
		_actions_master.undo()
	elif event.is_action_pressed(&"ui_redo"):
		_actions_master.redo()


func reset() -> void:
	# TODO: graph_edit.reset()
	graph_edit.clear_nodes()
	can_launch_viewer = true
	blueprint_file_path = ""
	#_set_filename("(not saved!)")


#--------------------------------------------
# Логика сохранения или открытия файла таймлайна
#--------------------------------------------
#region Saving&Loading

func save_blueprint_changes_to_file(path: String) -> void:
	error_popup_label.text = ""
	var validation_err = graph_edit.validate_timeline()
	var fn = path.get_file()
	if fn.is_empty():
		printerr("File name is empty!")
		return
	# file_path = file_path
	if not ".json" in fn:
		fn += ".json"
	
	var data = {}
	data[&"CONFIG"] = {
		&"max_id": graph_edit.max_id,
		&"dupa_version": DUPA_Utils.get_dupa_config_value(&"meta", &"version"),
		&"speakers": graph_edit.get_used_speakers_paths(),
	}
	data[&"TIMELINE"] = graph_edit.get_timeline()
	var file = FileAccess.open(path, FileAccess.WRITE)
	var opening_err = file.get_open_error()
	if opening_err == OK:
		var stringified_data := JSON.new().stringify(data, "\t")
		file.store_line(stringified_data)
		file.close()
	else:
		show_popup_error("Error on opening file to save timeline at: %s" % path)
	
	if validation_err != OK:
		printerr("Error on validation!")
		show_popup_error("---> Saving complete, but you must resolve errors!")
		#saving_complete.emit(validation_err)
	else:
		#saving_complete.emit(OK)
		if _on_saving_complete.is_valid():
			_on_saving_complete.call()
	
	blueprint_file_path = path
	_show_save_notify()



func _show_save_notify() -> void:
	%SaveNotify.show()
	await get_tree().create_timer(3.0).timeout
	%SaveNotify.hide()


func open_timeline_file(path: String):
	var fn = path.split("/")[-1]
	if path.is_empty() or fn.is_empty():
		print("File not found at %s" % path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	file.close()
	
	var timeline: Dictionary = data[&"TIMELINE"]
	var config: Dictionary = data[&"CONFIG"]
	
	var confirmation_text = ""
	var show_version_warning := false
	var timeline_dupa_version := ""
	var current_dupa_version: String = DUPA_Utils.get_dupa_config_value(&"meta", &"version")
	
	if _compare_versions:
		if config.has(&"dupa_version"):
			timeline_dupa_version = config.dupa_version
			if current_dupa_version != timeline_dupa_version:# || int(current_dupa_version) != int(timeline_dupa_version):
				confirmation_text = (
					"Выбранный файл был создан в DUPA %s. Текущая версия программы: %s.
					Возможны ошибки отображения содержания файла.
					
					Рекомендуется сделать бэкап перед дальнейшей работой.
					
					Вы желаете продолжить операцию?" % [timeline_dupa_version, current_dupa_version]
				)
		else:
			confirmation_text = (
				"Не найдена информация о версии DUPA, в которой был создан выбранный файл.
				Возможны ошибки отображения содержания файла.
				
				Рекомендуется сделать бэкап перед дальнейшей работой.
				
				Вы желаете продолжить операцию?"
			)
			
	if confirmation_text.is_empty():
		_load_timeline(path, timeline, config)
	else:
		DUPA_Utils.create_confirmation_dialog(confirmation_text, self, _load_timeline.bind(path, timeline, config))


func _load_timeline(path: String, timeline: Dictionary, config: Dictionary):
	reset()
	blueprint_file_path = path
	graph_edit.set_timeline(timeline, config)
	show()


func _on_dupa_file_manager_file_selected(path: String) -> void:
	open_timeline_file(path)


func _create_blueprint_file():
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.SAVE_TIMELINE, true, save_blueprint_changes_to_file)
	add_child(fm)
	fm.canceled.connect(_on_blueprint_file_creating_canceled)


func _on_blueprint_file_creating_canceled() -> void:
	_on_saving_complete = Callable()


# Сигналы от кнопок интерфейса:

func _on_open_new_pressed():
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.OPEN_TIMELINE, true, _on_dupa_file_manager_file_selected)
	add_child(fm)


func _on_save_pressed() -> void:
	if !blueprint_file_path:
		_create_blueprint_file()
		return

	save_blueprint_changes_to_file(blueprint_file_path)


func _on_save_as_pressed():
	_create_blueprint_file()


func _on_launch_viewer_pressed() -> void:
	_on_saving_complete = func(): viewer_requested.emit(blueprint_file_path)
	_on_save_pressed()
	
#endregion



#--------------------------------------------
# Тестирование диалога
#--------------------------------------------

#region Testing

#func _launch_viewer(blueprint_path: String) -> void:
	#pass
	
#endregion




#--------------------------------------------
# Показ попапа ошибки
#--------------------------------------------


func show_popup_error(error_text : String) -> void:
	var time = Time.get_time_dict_from_system()
	#error_popup_label.text += "[{0}:{1}:{2}".format([time["hour"], time["minute"], time["second"]]) + "]  " + error_text + "\n"
	error_popup_label.text += error_text + "\n"
	error_popup.popup()


func _on_dupa_graph_edit_error(error_text: String) -> void:
	show_popup_error(error_text)



#--------------------------------------------
# Прочая логика интерфейса редактора
#--------------------------------------------


func new_timeline():
	if blueprint_file_path.is_empty():
		# TODO: Стыбзить из лмстудио код создания конфёрм попапов
		# Спросить, точно ли пользователь хочет создать новый таймлайн, ведь тут есть
		# несохранённые изменения
		# TODO: Соответственно, нужен механизм туду реду, чтобы определять, были
		# ли совершены действия, которые не были сохранены.
		pass
	graph_edit.find_avaliable_speakers()
	show()
	reset()


func _on_new_pressed():
	new_timeline()


func _on_clear_pressed():
	deletion_popup.popup_centered()


func _on_deletion_confirmed():
	reset()


func _on_refresh_speakers_pressed() -> void:
	var backup_warning := \
		"ВНИМАНИЕ:
		Сделай бэкап перед тем, как обновлять список спикеров.
		Я эту фигню ещё нормально не реализовал."
	DUPA_Utils.create_confirmation_dialog(backup_warning, self, graph_edit.find_avaliable_speakers)


func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()


#--------------------------------------------
# История действий
#--------------------------------------------


func _on_undo_action_pressed() -> void:
	_actions_master.undo()


func _on_redo_action_pressed() -> void:
	_actions_master.redo()
