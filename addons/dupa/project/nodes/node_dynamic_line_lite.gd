class_name DynamicLineNode
extends DUPA_DefaultNode

@export var is_player_line: CheckButton
@export var id_base: LineEdit
@export var id_from: LineEdit
@export var id_to: LineEdit



func _ready():
	super()
	type = &"DYNAMIC_LINE"


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([is_player_line, id_base, id_from, id_to])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"is_player":
			is_player_line.button_pressed = value
		&"base":
			id_base.text = value
		&"from":
			id_from.text = str(value)
		&"to":
			id_to.text = str(value)


func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"base"] = id_base.text
	data[&"from"] = int(id_from.text)
	data[&"to"] = int(id_to.text)
	data[&"is_player"] = is_player_line.button_pressed
	data[&"go_to"] = _arrange_go_to()
	
	return data
