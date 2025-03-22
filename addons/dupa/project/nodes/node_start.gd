extends DefaultNode

class_name StartNode

@export var source: LineEdit


func _ready():
	super()
	type = "START"
	desc_visible = false


func gen_data(graph_edit : GraphEdit, allow_empty := false) -> Dictionary:
	var data := super(graph_edit)
	data["go_to"] = _arrange_go_to(graph_edit)
	data["source"] = source.text
	return data


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"source":
			source.text = value
