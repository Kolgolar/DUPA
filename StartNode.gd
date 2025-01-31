extends DefaultNode

class_name StartNode

signal on_delete

@onready var source := $HBoxContainer/MainColumn/Source/Var


func _ready():
	type = "START"


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["go_to"] = _arrange_go_to(graph_edit)
	data["source"] = source.text
	return data


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	if "source" in data:
		source.text = data["source"]

	
func _on_GraphNode_close_request() -> void:
	emit_signal("on_delete")
	delete()
