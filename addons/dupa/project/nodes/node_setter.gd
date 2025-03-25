class_name SetterNode
extends DUPA_DefaultNode


func _ready():
	super()
	type = &"SETTER"


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([%VarName, %VarValue])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"var_name":
			%VarName.text = value
		&"var_value":
			%VarValue.text = value


func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"var_name"] = %VarName.text
	data[&"var_value"] = %VarValue.text
	data[&"go_to"] = []
	data[&"go_to"] = _arrange_go_to()
	return data
