class_name DUPA_Utils
extends Node


static func separate_line_to_sentences(line: String) -> Array:
	var regex = RegEx.new()
	regex.compile(".*?[.!?\\n]+(?:\\s+|$)")
	var results = []
	for result in regex.search_all(line):
		results.push_back(result.get_string())
	return results


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
