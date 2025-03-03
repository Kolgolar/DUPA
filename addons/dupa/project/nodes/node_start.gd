extends DefaultNode

class_name StartNode

signal on_delete

@export var source: LineEdit


func _ready():
	type = "START"
	desc_visible = false


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["go_to"] = _arrange_go_to(graph_edit)
	data["source"] = source.text
	return data


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	if "source" in data:
		source.text = data["source"]


func delete():
	super()
	on_delete.emit()
