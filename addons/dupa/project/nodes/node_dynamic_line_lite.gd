# FIXME: LineLite и DynamicIDLine должны наследовать один базовый класс,
# по аналогии с DN_Line и DN_DynamicIDLine 
class_name DynamicIDLineNode
extends DupaNodeBase

@export var is_player_line: CheckButton
@export var id_base: LineEdit
@export var id_from: SpinBox
@export var id_to: SpinBox



func _ready():
	super()
	type = DUPA_Lib.NodeType.DYNAMIC_ID_LINE


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
			id_from.value = int(value)
		&"to":
			id_to.value = int(value)


func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"base"] = id_base.text
	data[&"from"] = int(id_from.value)
	data[&"to"] = int(id_to.value)
	data[&"is_player"] = is_player_line.button_pressed
	
	return data
