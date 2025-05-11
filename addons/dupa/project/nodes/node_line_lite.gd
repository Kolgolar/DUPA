class_name LineNodeLite
extends DupaNodeBase

@export var line_text: LineEdit
@export var is_player_line: CheckButton


func _ready():
	super()
	type = DupaLib.NodeType.LINE


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([is_player_line, line_text])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"line_text":
			line_text.text = value
		&"is_player":
			is_player_line.set_pressed_no_signal(value)


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	data[&"is_player"] = is_player_line.button_pressed
	if not line_text.text.is_empty() || allow_empty:
		data[&"line_text"] = line_text.text
	data[&"go_to"] = _arrange_go_to()
	return data
