extends DefaultNode

class_name DynamicLineNode

@export var is_player_line: CheckButton
@export var _from: LineEdit
@export var _to: LineEdit
@export var _base: LineEdit


func _ready():
	super()
	type = "DYNAMIC_LINE"


func _update_title_text(new_text : String, update_node_text := true) -> void:
	title = "DYNAMIC LINE" + ": " + new_text
	short_title = new_text
	if update_node_text:
		node_title.text = short_title


func _set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"is_player":
			is_player_line.button_pressed = value
		&"base":
			_base.text = value
		&"from":
			_from.text = str(value)
		&"to":
			_to.text = str(value)


func gen_data(graph_edit : GraphEdit, allow_empty := false) -> Dictionary:
	var data = super(graph_edit)
	data["base"] = _base.text
	data["from"] = int(_from.text)
	data["to"] = int(_to.text)
	data["is_player"] = is_player_line.pressed
	data["go_to"] = _arrange_go_to(graph_edit)
	
	return data
