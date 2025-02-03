extends DefaultNode

class_name SetterNode

@export var var_name: LineEdit
@export var var_value: LineEdit


func _ready():
	type = "SETTER"


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	var_name.text = data["var_name"]
	var_value.text = data["var_value"]


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["var_name"] = var_name.text
	data["var_value"] = var_value.text
	data["go_to"] = []
	data["go_to"] = _arrange_go_to(graph_edit)
	return data
