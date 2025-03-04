extends FileDialog
class_name DupaFileManager

signal file_saved(path: String)

const TIMELINE_FILTERS: PackedStringArray = ["*.json", "*.dupa"]
const LOCALIZATION_FILTERS: PackedStringArray = ["*.csv"]

enum FileManagerMode {SAVE_TIMELINE, OPEN_TIMELINE, OPEN_LOCALIZATION}

var cache_dir := true


func _ready():
	popup_centered(Vector2(600, 400))


static func create(file_manager_mode: FileManagerMode, should_cache_dir := true, on_ok: Callable = func(): pass) -> DupaFileManager:
	var fm := DupaFileManager.new()
	fm.cache_dir = should_cache_dir
	match file_manager_mode:
		FileManagerMode.OPEN_TIMELINE:
			fm.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			fm.title = "Open a Timeline"
		FileManagerMode.OPEN_LOCALIZATION:
			fm.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			fm.title = "Open a Localization"
		FileManagerMode.SAVE_TIMELINE:
			fm.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			fm.title = "Save the timeline as..."
	
	if file_manager_mode >= FileManagerMode.OPEN_LOCALIZATION:
		fm.filters = LOCALIZATION_FILTERS
	else:
		fm.filters = TIMELINE_FILTERS
	
	fm.use_native_dialog = true
	
	fm.access = FileDialog.ACCESS_FILESYSTEM
	fm.current_dir = DupaConfig.filemanager_last_directory
	
	#if file_manager_mode == FileManagerMode.SAVE_TIMELINE:
		#fm.confirmed.connect(on_ok)
	#else:
	fm.file_selected.connect(on_ok)
	fm.file_selected.connect(fm._on_file_selected)
	fm.canceled.connect(fm._on_canceled)
	#fm.confirmed.connect(fm._on_confirmed)
	
	return fm


func _remember_path():
	if cache_dir:
		DupaConfig.filemanager_last_directory = current_dir

#
#func _on_confirmed():
	#_remember_path()
	#file_saved.emit(current_dir)


func _on_file_selected(_path: String):
	_remember_path()
	queue_free()


func _on_canceled():
	queue_free()
