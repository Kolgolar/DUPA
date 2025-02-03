extends DefaultNode

class_name LineNodeLite

@export var localization_id: LineEdit
@export var is_player_line: CheckButton



func _ready():
	type = "LINE"


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	if "localization_id" in data:
		localization_id.text = data["localization_id"]
	if "is_player" in data:
		is_player_line.button_pressed = data["is_player"]


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["go_to"] = []
	data["is_player"] = is_player_line.pressed
	if not localization_id.text.is_empty():
		data["localization_id"] = localization_id.text
	
	data["go_to"] = _arrange_go_to(graph_edit)
	return data
