extends DefaultNode

class_name LineNodeLite

onready var localization_id = $HBoxContainer/MainColumn/Text/LocalizationLine
onready var is_player_line = $HBoxContainer/MainColumn/IsPlayer/IsPlayerLine



func _ready():
	type = "LINE"


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	if "localization_id" in data:
		localization_id.text = data["localization_id"]
	if "is_player" in data:
		is_player_line.pressed = data["is_player"]


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["go_to"] = []
	data["is_player"] = is_player_line.pressed
	if not localization_id.text.empty():
		data["localization_id"] = localization_id.text
	
	data["go_to"] = _arrange_go_to(graph_edit)
	return data


func _on_IsPlayerLine_toggled(button_pressed):
	pass # Replace with function body.
