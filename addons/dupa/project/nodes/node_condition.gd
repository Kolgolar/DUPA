class_name ConditionNode
extends DupaNodeBase


@export var condition_var: LineEdit


func _ready():
	super()
	#input_port_id = 1
	type = DUPA_Lib.NodeType.CONDITION


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([condition_var])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"var_name":
			condition_var.text = value



func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"var_name"] = condition_var.text
	data[&"go_to_false"] = _arrange_go_to(DUPA_Lib.OUTPUT_FALSE_PORT)
	return data
