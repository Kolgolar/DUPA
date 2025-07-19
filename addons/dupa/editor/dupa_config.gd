extends Node

const _CONFIG_PATH = "user://dupa_config.cfg"

var data := {
	"filemanager": {
		"last_directory": "res://"
	}
}


func _ready():
	load_config()


func _set(property: StringName, value: Variant) -> bool:
	var splitted = property.split("_")
	var section = splitted[0]
	splitted.remove_at(0)
	var param = "_".join(splitted)
	if data.has(section):
		if data[section].has(param):
			data[section][param] = value
			return true
		else:
			printerr("Can't find param %s at section %s" % [param, section])
	else:
		printerr("Can't find section %s" % section)
	
	return false


func _get(property: StringName):
	var splitted = property.split("_")
	var section = splitted[0]
	splitted.remove_at(0)
	var param = "_".join(splitted)
	if data.has(section):
		if data[section].has(param):
			return data[section][param]
		else:
			printerr("Can't find param %s at section %s" % [param, section])
	else:
		printerr("Can't find section %s" % section)
	
	return null


func load_config():
	var config = ConfigFile.new()
	if !FileAccess.file_exists(_CONFIG_PATH):
		return
	var err = config.load(_CONFIG_PATH)
	if err != OK:
		printerr("Can't open config file. Error code: %s" % err)
		return
	
	for section in config.get_sections():
		for param in config.get_section_keys(section):
			var value = config.get_value(section, param)
			_set("%s_%s" % [section, param], value)


func save_config():
	var config = ConfigFile.new()
	for section in data:
		for param in data[section]:
			config.set_value(section, param, data[section][param])
	config.save(_CONFIG_PATH)
