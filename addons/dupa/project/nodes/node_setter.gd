class_name SetterNode
extends DupaNodeBase

@export var var_name: LineEdit
@export var var_value: LineEdit


func _ready():
	super()
	type = DupaLib.NodeType.SETTER


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([var_name, var_value])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"var_name":
			var_name.text = value
		&"var_value":
			var_value.text = value


func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"var_name"] = var_name.text
	data[&"var_value"] = var_value.text
	data[&"go_to"] = _arrange_go_to()
	return data
