extends Node

class_name DupaUtility

# TODO: Сделать отдельный статик-скрипт, в котором будет всё, что относится к конфигам?
# И тогда на вход подавать не StringName, а константы из enum?
static func get_dupa_config_value(section: StringName, key: StringName):
	var path := "res://addons/dupa/project/misc/config.cfg"
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


static func wait(time: float, node: Node):
	await node.get_tree().create_timer(time).timeout


static func is_inside_control(pos: Vector2, control: Control) -> bool:
	var c_pos = control.global_position
	var c_size = control.size
	return pos.x >= c_pos.x && pos.x <= c_pos.x + c_size.x && pos.y >= c_pos.y && pos.y <= c_pos.y + c_size.y


static func read_csv_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var err = FileAccess.get_open_error()
	if err != OK:
		push_error("CSV файл не найден: %s. Ошибка: %d", [file_path, err])
		return {}
		
	var data = {}
	if err == 0:
		var is_first_line := true
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if is_first_line:
				is_first_line = false
				continue
			if line != "":  # Пропустить пустые строки
				var row := line.split(";")  # Разделить строку по табам
				if row[1] == "": continue # Если id пустой
				var id = row[1]
				row.remove_at(0) # Удаляем комментарий
				row.remove_at(0)
				data[id] = {
					"tags": row[0],
					"line": row[1],
				}
		file.close()
	
	return data


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
