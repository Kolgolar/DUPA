class_name LineNodeLite
extends DUPA_DefaultNode

@export var line: LineEdit
@export var is_player_line: CheckButton


func _ready():
	super()
	type = &"LINE"


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([is_player_line, line])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"localization_id":
			line.text = value
		&"is_player":
			is_player_line.set_pressed_no_signal(value)


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	data[&"go_to"] = []
	data[&"is_player"] = is_player_line.button_pressed
	if not line.text.is_empty() || allow_empty:
		data[&"localization_id"] = line.text
	
	data[&"go_to"] = _arrange_go_to()
	return data
