extends DefaultNode

class_name LineNodeLite


func _ready():
	super()
	type = "LINE"


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([%IsPlayerLine, %LocalizationLine])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"localization_id":
			%LocalizationLine.text = value
		&"is_player":
			%IsPlayerLine.set_pressed_no_signal(value)


func gen_data(graph_edit : GraphEdit, allow_empty := false) -> Dictionary:
	var data := super(graph_edit)
	data["go_to"] = []
	data["is_player"] = %IsPlayerLine.button_pressed
	if not %LocalizationLine.text.is_empty() || allow_empty:
		data["localization_id"] = %LocalizationLine.text
	
	data["go_to"] = _arrange_go_to(graph_edit)
	return data
