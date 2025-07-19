extends DUPA_GraphNodeBase

class_name DUPA_GraphNodeStart

@export var source: LineEdit


func _ready():
	super()
	type = DUPA_Lib.NodeType.START
	desc_visible = false


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	data[&"source"] = source.text
	return data


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"source":
			source.text = value
