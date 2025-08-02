extends Node

class_name DUPA_Utils

# TODO: Сделать отдельный статик-скрипт, в котором будет всё, что относится к конфигам?
# И тогда на вход подавать не StringName, а константы из enum?
static func get_dupa_config_value(section: StringName, key: StringName):
	var path := "res://addons/dupa/common/misc/config.cfg"
	var cfg := ConfigFile.new()
	var err = cfg.load(path)
	if err != OK:
		printerr("Can't find config file at: %s" % path)
		return null
	var value = cfg.get_value(section, key)
	return value


static func create_confirmation_dialog(
text: String, add_to: Node, on_ok_pressed: Callable = func(): pass,
on_cancel_pressed: Callable = func(): pass):
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = text
	confirmation_dialog.confirmed.connect(on_ok_pressed)
	confirmation_dialog.canceled.connect(on_cancel_pressed)	
	add_to.add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()
	return confirmation_dialog


#static func wait(time: float, node: Node):
	#await node.get_tree().create_timer(time).timeout


static func is_inside_control(pos: Vector2, control: Control) -> bool:
	var c_pos = control.global_position
	var c_size = control.size
	return pos.x >= c_pos.x && pos.x <= c_pos.x + c_size.x && pos.y >= c_pos.y && pos.y <= c_pos.y + c_size.y


static func load_speakers_data_from_config(speakers: Array, append_error_popup_to: Node = null) -> Array[DUPA_SpeakerData]: 
	var data: Array[DUPA_SpeakerData]
	var speaker_data: DUPA_SpeakerData
	# Does not use .map(), because avaliable_speakers is typed array
	for sp in speakers:
		if FileAccess.file_exists(sp.uid):
			speaker_data = load(sp.uid)
		else:
			DUPA_Logger.add_warning("Speaker data was not found at %s. Searching by relative path..." % sp.uid)
			speaker_data = load(sp.path)
			if !speaker_data:
				if append_error_popup_to:
					DUPA_Utils.create_confirmation_dialog("Speaker data was not found at %s. Perhaps it was deleted. You may try to manually update path to the file in .json file." % sp.path, append_error_popup_to)
				else:
					DUPA_Logger.add_warning("Speaker data was not found at %s." % sp.path)
		if speaker_data:
			data.append(speaker_data)
	return data


static func read_localization_csv_file(file_path: String, primary_locale := "en", fallback_locale := "en") -> Dictionary[String, Dictionary]:
	if file_path.is_empty():
		push_error("File path is empty!")
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	var err = FileAccess.get_open_error()
	if err != OK:
		push_error("CSV файл не найден: %s. Ошибка: %s" % [file_path, err])
		return {}
		
	var data: Dictionary[String, Dictionary]
	if err == 0:
		var is_first_line := true
		var fallback_locale_column := -1
		var primary_locale_column := -1
		var tags_column := -1
		var id_column := -1
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line != "":  # Пропустить пустые строки
				var row: Array = line.split(";")  # Разделить строку по столбцам
				if is_first_line:
					is_first_line = false
					primary_locale_column = row.find(primary_locale)
					fallback_locale_column = row.find(fallback_locale)
					tags_column = row.find("tags")
					id_column = row.find("id")
					
					if primary_locale_column < 0:
						push_error("Primary locale '%s' column was not found!" % primary_locale_column)
					if fallback_locale_column < 0:
						push_error("Fallback locale column '%s' was not found!" % fallback_locale_column)
					if tags_column < 0:
						push_error("'tags' column was not found!" % tags_column)
					if id_column < 0:
						push_error("ID column was not found!")
						break
					if primary_locale_column < 0 && fallback_locale_column < 0:
						break
					continue
				
				var id = row[id_column]
				if id == "": continue # Если id пустой
				data[id] = {
					&"tags": row[tags_column],
					&"line": row[primary_locale_column],
				}
				if primary_locale != fallback_locale:
					data[id][&"fallback_line"] = row[fallback_locale_column] 
		file.close()
	
	return data


## Converts to String, Bool or Int
static func convert_to_determined_type(value: String) -> Variant:
	var set_to: Variant
	if value.begins_with('"'):
		value = value.trim_prefix('"')
		value = value.trim_suffix('"')
		set_to = str(value)
	else:
		match value.to_upper():
			"TRUE":
				set_to = true
			"FALSE":
				set_to = false
			_:
				set_to = int(value)

	return set_to


static func separate_line_to_sentences(line: String) -> Array:
	var regex = RegEx.new()
	regex.compile(".*?[.!?\\n]+(?:\\s+|$)")
	var results = []
	for result in regex.search_all(line):
		results.push_back(result.get_string())
	return results


static func get_all_files_at(folder_path : String, extension : String) -> Array:
	DirAccess.open(folder_path)
	if DirAccess.get_open_error() == OK:
		var files := DirAccess.get_files_at(folder_path)
		var paths := []
		for f in files:
			if f.ends_with(extension + ".import"):
				paths.append(folder_path + f.replace(".import", ""))
		# print(paths)
		return paths
	else:
		printerr("Can't open folder at " + folder_path)
		return []


static func find_all_resources(
		write_to: Array[DUPA_SpeakerData],
		resource_class_name := "",
		search_root := "res://",
		max_depth := 5
	) -> void:
	
	var pattern := 'script_class\\s*=\\s*"' + resource_class_name + '"'
	var regex := RegEx.new()
	regex.compile(pattern)

	_scan_recursive(write_to, search_root, regex, 0, max_depth)


static func _scan_recursive(write_to: Array, path: String, regex: RegEx, depth: int, max_depth: int) -> void:
	if depth > max_depth:
		return

	var dir := DirAccess.open(path)
	if not dir:
		push_error("Can't open the directory: %s" % path)
		return

	DUPA_Logger.add_msg("Scanning folder: %s" % path)
	
	var entries := dir.get_directories()
	for folder in entries:
		if folder == "." or folder == "..":
			continue
		var sub_path := path.path_join(folder)
		_scan_recursive(write_to, sub_path, regex, depth + 1, max_depth)
		
	var files := dir.get_files()
	for file in files:
		if !file.ends_with(".tres"):
			continue
		var file_path := path.path_join(file)
		DUPA_Logger.add_msg("Open file: %s" % file_path)
		
		var content := FileAccess.get_file_as_string(file_path)
		var regex_result := regex.search(content)
		
		if regex_result:
			#var resource_class := regex_result.get_string(1)
			#if resource_class == SPEAKER_DATA_CLASS_STR:
			DUPA_Logger.add_msg("Appending resource: %s" % file_path)
			var speaker_data: DUPA_SpeakerData = load(file_path)
			write_to.append(speaker_data)
