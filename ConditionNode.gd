extends DefaultNode

onready var condition_var = $ConditionVar/ConditionVar

const TRUE_PORT_ID = 0
const FALSE_PORT_ID = 1

func _ready():
	type = "CONDITION"


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	condition_var.text = data["var_name"]



func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["var_name"] = condition_var.text
	data["go_to_true"] = _arrange_go_to(graph_edit, TRUE_PORT_ID)
	data["go_to_false"] = _arrange_go_to(graph_edit, FALSE_PORT_ID)
	return data
