extends Control

@export var _version_label: Label


func _ready():
	var version = DUPA_Utils.get_dupa_config_value(&"meta", &"version")
	_version_label.text = "Dialogic Universal Professional Asset v%s" % version
