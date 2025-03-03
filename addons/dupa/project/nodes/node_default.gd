extends GraphNode

class_name DefaultNode

@onready var main = $HBoxContainer/MainColumn
@export var node_title: TextEdit
@onready var comment_box = $HBoxContainer/MainColumn/Comment

@onready var type := "DEFAULT"

var id : int
var short_title := ""

var desc_visible := false:
	set(value):
		desc_visible = value
		node_title.visible = value
		size.y -= 64

signal name_changed
signal rmb_pressed


func _ready():
	node_title.hide()


func set_base_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	id = int(id_name)
	position_offset.x  = data["offset_x"]
	position_offset.y = data["offset_y"]
	type = data["type"]
	#_update_title_text(data["title"])


func gen_base_data() -> Dictionary:
	var data := {}
	# data["id"] = id
	data["type"] = type
	data["title"] = short_title
	data["offset_x"] = position_offset.x
	data["offset_y"] = position_offset.y
	data["desc_visible"] = desc_visible
	return {str(id) : data}


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	pass


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	return {}


func delete() -> void:
	clear_all_slots()
	queue_free()


func _arrange_go_to(graph_edit : GraphEdit, port_id := 0) -> Array:
	var to_nodes_pos_y := {}
	for connection in graph_edit.get_connection_list():
		if connection["from"] == self.name and connection["from_port"] == port_id:
			var to_node : GraphNode = graph_edit.get_node(connection["to"])
			to_nodes_pos_y[to_node.offset.y] = str(to_node.id)

	var coords = to_nodes_pos_y.keys()
	coords.sort()
	var arranged_arr := []
	for n in coords:
		arranged_arr.append(to_nodes_pos_y[n])
	return arranged_arr


func _update_title_text(new_text : String, update_node_text := true) -> void:
	title = type + ": " + new_text
	short_title = new_text
	if update_node_text:
		node_title.text = short_title


func _on_GraphNode_resize_request(new_minsize):
	size = new_minsize


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed() && !event.is_echo():
		rmb_pressed.emit()

func _on_delete_pressed() -> void:
	delete()


func _on_title_text_changed() -> void:
	#_update_title_text(node_title.text, false)
	pass
