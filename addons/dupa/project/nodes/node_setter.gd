extends DefaultNode

class_name SetterNode

@export var var_name: LineEdit
@export var var_value: LineEdit


func _ready():
	super()
	type = "SETTER"


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"var_name":
			var_name.text = value
		&"var_value":
			var_value.text = value


func gen_data(graph_edit : GraphEdit, allow_empty := false) -> Dictionary:
	var data = super(graph_edit)
	data["var_name"] = var_name.text
	data["var_value"] = var_value.text
	data["go_to"] = []
	data["go_to"] = _arrange_go_to(graph_edit)
	return data
