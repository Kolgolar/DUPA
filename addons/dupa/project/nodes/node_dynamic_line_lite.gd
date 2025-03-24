extends DefaultNode

class_name DynamicLineNode


func _ready():
	super()
	type = "DYNAMIC_LINE"


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([%IsPlayerLine, %IDBase, %IDFrom, %IDTo])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"is_player":
			%IsPlayerLine.button_pressed = value
		&"base":
			%IDBase.text = value
		&"from":
			%IDFrom.text = str(value)
		&"to":
			%IDTo.text = str(value)


func gen_data(graph_edit : GraphEdit, allow_empty := false) -> Dictionary:
	var data = super(graph_edit)
	data["base"] = %IDBase.text
	data["from"] = int(%IDFrom.text)
	data["to"] = int(%IDTo.text)
	data["is_player"] = %IsPlayerLine.pressed
	data["go_to"] = _arrange_go_to(graph_edit)
	
	return data
