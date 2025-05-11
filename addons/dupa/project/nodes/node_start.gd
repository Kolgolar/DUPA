extends DupaNodeBase

class_name StartNode

@export var source: LineEdit


func _ready():
	super()
	type = DupaLib.NodeType.START
	desc_visible = false


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	data[&"go_to"] = _arrange_go_to()
	data[&"source"] = source.text
	return data


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"source":
			source.text = value
