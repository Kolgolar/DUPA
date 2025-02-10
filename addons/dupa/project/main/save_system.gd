extends Node

const _SAVE_DIR = "user://saves/"
const _SAVE_PATH = _SAVE_DIR + "save.dat"

const _VARS_TO_SAVE := [
	"default_directory",
]

# Vars, used in save file:
#############
var default_directory := ""
#############


func _ready():
	load_data()


func load_data() -> void:
	var loaded_data
	var file = FileAccess.open(_SAVE_PATH, FileAccess.READ)
	var err = file.get_open_error()
	if err == OK:
		loaded_data = file.get_var()
	elif err == ERR_FILE_NOT_FOUND:
		print_debug("DUPA save file was not found at %s" % _SAVE_PATH)
		return
	else:
		printerr("Error opening DUPA save file at %s. Error code: %s" % [_SAVE_PATH, err])
		return
		
		for key in loaded_data.keys():
			if get(key) != null:
				set(key, loaded_data[key])
			else:
				print_stack()
				printerr("Error on data loading! The variable '" + key + "' does not exist!")
				print_debug("Save file keys: " + str(loaded_data.keys()))
		print_debug("Загрузка завершена!")


func save_data() -> void:
	print_debug("Сохранение локальных данных...")
	var data_to_save : Dictionary = {}
	for key in _VARS_TO_SAVE:
		data_to_save[key] = get(key)
	
	if !DirAccess.dir_exists_absolute(_SAVE_DIR):
		DirAccess.make_dir_absolute(_SAVE_DIR)
	var file := FileAccess.open(_SAVE_PATH, FileAccess.WRITE)
	var err := file.get_open_error()
	if err == OK:
		file.store_var(data_to_save)
		file.close()
	elif err == ERR_FILE_NOT_FOUND:
		printerr("Файл диалога не найден!")
	else:
		printerr("Ошибка открытия файла диалога! Код ошибки: " + str(err))
	print_debug("Данные сохранены!")
