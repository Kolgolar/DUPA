extends DefaultNode

class_name DynamicLineNode

@export var is_player_line: CheckButton
@export var _from: LineEdit
@export var _to: LineEdit
@export var _base: LineEdit


func _ready():
	type = "DYNAMIC_LINE"


func _update_title_text(new_text : String, update_node_text := true) -> void:
	title = "DYNAMIC LINE" + ": " + new_text
	short_title = new_text
	if update_node_text:
		node_title.text = short_title


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	if "is_player" in data:
		is_player_line.button_pressed = data["is_player"]
	if "base" in data:
		_base.text = data["base"]
	if "from" in data:
		_from.text = str(data["from"])
	if "to" in data:
		_to.text = str(data["to"])
	

func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["base"] = _base.text
	data["from"] = int(_from.text)
	data["to"] = int(_to.text)
	data["is_player"] = is_player_line.pressed
	data["go_to"] = _arrange_go_to(graph_edit)
	
	return data
