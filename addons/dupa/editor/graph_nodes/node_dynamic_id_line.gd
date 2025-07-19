class_name DUPA_GraphNodeDynamicIDLine
extends DUPA_GraphNodeLineBase

@export var id_base: LineEdit
@export var id_from: SpinBox
@export var id_to: SpinBox



func _ready():
	super()
	type = DUPA_Lib.NodeType.DYNAMIC_ID_LINE


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([id_base, id_from, id_to])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"base":
			id_base.text = value
		&"from":
			id_from.value = int(value)
		&"to":
			id_to.value = int(value)


func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"base"] = id_base.text
	data[&"from"] = int(id_from.value)
	data[&"to"] = int(id_to.value)
	
	return data
