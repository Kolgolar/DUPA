extends DefaultNode

@onready var condition_var = $ConditionVar/ConditionVar

const TRUE_PORT_ID = 0
const FALSE_PORT_ID = 1

func _ready():
	super()
	type = "CONDITION"


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"var_name":
			condition_var.text = value



func gen_data(graph_edit : GraphEdit, allow_empty := false) -> Dictionary:
	var data = super(graph_edit)
	data["var_name"] = condition_var.text
	data["go_to_true"] = _arrange_go_to(graph_edit, TRUE_PORT_ID)
	data["go_to_false"] = _arrange_go_to(graph_edit, FALSE_PORT_ID)
	return data
