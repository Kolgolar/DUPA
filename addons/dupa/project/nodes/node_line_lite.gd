extends DefaultNode

class_name LineNodeLite

@export var localization_id: LineEdit
@export var is_player_line: CheckButton


func _ready():
	super()
	type = "LINE"


func set_param(param_name: StringName, value):
	super(param_name, value)
	print(param_name)
	match param_name:
		&"localization_id":
			localization_id.text = value
		&"is_player":
			is_player_line.set_pressed_no_signal(value)


func gen_data(graph_edit : GraphEdit, allow_empty := false) -> Dictionary:
	var data := super(graph_edit)
	data["go_to"] = []
	data["is_player"] = is_player_line.button_pressed
	if not localization_id.text.is_empty() || allow_empty:
		data["localization_id"] = localization_id.text
	
	data["go_to"] = _arrange_go_to(graph_edit)
	return data
