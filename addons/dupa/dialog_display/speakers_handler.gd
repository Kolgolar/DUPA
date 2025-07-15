# TODO: Нужен ли class_name?
@tool
extends Resource

const SPEAKER_DATA_CLASS_STR := "DUPA_SpeakerData"

@export_dir var search_speakers_at = "res://"
@export var max_search_depth := 2
@export_tool_button("Update speakers list") var find_all_speakers_action = find_all_speakers
@export var speakers: Array[DUPA_SpeakerData] = []


func find_all_speakers(max_depth: int = max_search_depth) -> void:
	speakers.clear()
	
	var regex := RegEx.new()
	regex.compile('script_class\\s*=\\s*"([^"]+)"')
	
	_scan_recursive(search_speakers_at, regex, 0, max_depth)
	
	notify_property_list_changed()


func _scan_recursive(path: String, regex: RegEx, depth: int, max_depth: int) -> void:
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
		_scan_recursive(sub_path, regex, depth + 1, max_depth)
		
	var files := dir.get_files()
	for file in files:
		if !file.ends_with(".tres"):
			continue
		var file_path := path.path_join(file)
		DUPA_Logger.add_msg("Open file: %s" % file_path)
		
		var content := FileAccess.get_file_as_string(file_path)
		var regex_result := regex.search(content)
		
		if regex_result:
			var resource_class := regex_result.get_string(1)
			if resource_class == SPEAKER_DATA_CLASS_STR:
				DUPA_Logger.add_msg("Appending resource: %s" % file_path)
				var speaker_data: DUPA_SpeakerData = load(file_path)
				speakers.append(speaker_data)
