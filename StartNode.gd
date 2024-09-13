extends DefaultNode

class_name StartNode

signal on_delete

func _ready():
	type = "START"


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["go_to"] = _arrange_go_to(graph_edit)
	return data

	
func _on_GraphNode_close_request() -> void:
	emit_signal("on_delete")
	delete()
