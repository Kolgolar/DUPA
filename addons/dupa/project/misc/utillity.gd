extends RefCounted


static func _read_csv_file(file_path: String) -> Dictionary:
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
