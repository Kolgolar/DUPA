extends DefaultNode

class_name DynamicLineNode

onready var line_var_name = $HBoxContainer/MainColumn/Var/Var


func _ready():
	type = "LINE"


func _update_title_text(new_text : String, update_node_text := true) -> void:
	title = "DYNAMIC LINE" + ": " + new_text
	short_title = new_text
	if update_node_text:
		node_title.text = short_title


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	line_var_name.text = data["line_var_name"]


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["line_var_name"] = line_var_name.text
	data["go_to"] = []
	data["go_to"] = _arrange_go_to(graph_edit)
	return data
