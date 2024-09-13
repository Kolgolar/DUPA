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
	var file = File.new()
	print_debug("Поиск файла сохранений")
	if file.file_exists(_SAVE_PATH):
		var error = file.open(_SAVE_PATH, File.READ)
#		var error = file.open_encrypted_with_pass(_SAVE_PATH, File.READ, "P@paB3ar6969")
		if error == OK:
			loaded_data = file.get_var()
			file.close()
		else:
			printerr("Ошибка загрузки сохранения! Код ошибки: " + str(error))
	
		for key in loaded_data.keys():
			if get(key) != null:
				set(key, loaded_data[key])
			else:
				print_stack()
				printerr("Error on data loading! The variable '" + key + "' does not exist!")
				print_debug("Save file keys: " + str(loaded_data.keys()))
		print_debug("Загрузка завершена!")
	else:
		print_debug("Файл сохранений не найден.")


func save_data() -> void:
	print_debug("Сохранение локальных данных...")
	var data_to_save : Dictionary = {}
	for key in _VARS_TO_SAVE:
		data_to_save[key] = get(key)
	
	var dir = Directory.new()
	if not dir.dir_exists(_SAVE_DIR):
		dir.make_dir_recursive(_SAVE_DIR)
	var file = File.new()
	var error = file.open(_SAVE_PATH, File.WRITE)
#	var error = file.open_encrypted_with_pass(_SAVE_PATH, File.WRITE, "P@paB3ar6969")
	if error == OK:
		file.store_var(data_to_save)
		file.close()
	print_debug("Данные сохранены!")
