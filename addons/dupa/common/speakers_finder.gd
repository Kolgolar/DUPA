class_name DUPA_SpeakersFinder
extends Resource

const SPEAKER_DATA_CLASS_STR := "DUPA_SpeakerData"

var search_root := ""
var max_search_depth := 1
var speakers: Array[DUPA_SpeakerData] = []



static func find_all_speakers(
		write_to: Array[DUPA_SpeakerData],
		search_root := "res://",
		max_search_depth := 5,
		max_depth: int = max_search_depth
	):
	
	var regex := RegEx.new()
	regex.compile('script_class\\s*=\\s*"([^"]+)"')

	_scan_recursive(write_to, search_root, regex, 0, max_depth)


static func _scan_recursive(write_to: Array[DUPA_SpeakerData], path: String, regex: RegEx, depth: int, max_depth: int) -> void:
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
			var resource_class := regex_result.get_string(1)
			if resource_class == SPEAKER_DATA_CLASS_STR:
				DUPA_Logger.add_msg("Appending resource: %s" % file_path)
				var speaker_data: DUPA_SpeakerData = load(file_path)
				write_to.append(speaker_data)
