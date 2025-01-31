extends Control

@export var _mouse_popup: PopupMenu

@export var _lite_line_nodes := false

var dialog = {}
var dialog_for_localisation = []
var file_name := ""
var directory := ""
var initial_pos = Vector2(40,40)

var focused_nodes := []

var max_id = 1
var start_node : StartNode

var from_empty_to_node : String
var slot_to_connect : int
var from_node_to_empty : String

@onready var error_popup = $Error
@onready var error_popup_label = $Error/RichTextLabel
@onready var graph_edit = $GraphEdit
@onready var timer = $Timer


func _ready():
	pass
	
# ADD NEW NODE
func _on_NewNode_pressed():
	# _create_new_node("res://LineNodeLite.tscn")
	pass
	# TODO: Autosave?
	
# SAVE 
func _on_Save_pressed(): 
	if file_name.is_empty():
		$ConfirmationDialog.popup()
		return
	
	dialog.clear()
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		dialog.merge(node.gen_base_data())
		dialog[str(node.id)].merge(node.gen_data($GraphEdit))

	# print(dialog)
	save_dialog(directory, file_name)
	

func _input(event):
	if event.is_action_pressed("duplicate"):
		var shift := Vector2(30, 30)
		for n in focused_nodes:
			if is_instance_valid(n) and not n is StartNode:
				var new_node : GraphNode = n.duplicate()
				new_node.offset += shift
				(n as GraphNode).selected = false
				new_node.selected = true
				focused_nodes.erase(n)
				focused_nodes.append(new_node)
				graph_edit.add_child(new_node)
			else:
				printerr("Node is not valid or you're trying to duplicate Start Node (u cant, bro)")
	elif event.is_action_pressed("delete"):
		for n in focused_nodes:
			if is_instance_valid(n):
				n.delete()
		focused_nodes.clear()
	elif event.is_action_pressed("save"):
		_on_Save_pressed()


func _on_GraphEdit_node_selected(node):
	focused_nodes.append(node)


func _on_GraphEdit_node_unselected(node):
	focused_nodes.erase(node)


func _create_graph_node(scene : String, pos := Vector2.ZERO, _is_start_node := false, set_to_defaults := true) -> GraphNode:
	var node = load(scene).instantiate()
	graph_edit.add_child(node)
	if node is StartNode:
		$MousePopup.set_item_disabled(0, true)
		node.connect("on_delete", Callable(self, "_on_StartNode_delete"))
		node.connect("focus_entered", Callable(self, "_on_graph_node_focus_entered"))
		node.connect("focus_exited", Callable(self, "_on_graph_node_focus_exited"))
		start_node = node
	if set_to_defaults:
		_set_new_node_params(node, pos, _is_start_node)
	if not from_empty_to_node.is_empty():
		graph_edit.connect_node(node.name, 0, from_empty_to_node, slot_to_connect)
		from_empty_to_node = ""
	elif not from_node_to_empty.is_empty():
		graph_edit.connect_node(from_node_to_empty, slot_to_connect, node.name, 0)
		from_node_to_empty = ""
	slot_to_connect = -1
	
	return node


func _set_new_node_params(node : GraphNode, pos : Vector2, _is_start_node := false) -> void:
	if node is StartNode:
		node.id = 0
	else:
		max_id += 1
		node.id = max_id
	var real_size = graph_edit.size / graph_edit.zoom
	var offset = graph_edit.scroll_offset
	node.offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom - Vector2(0, node.size.y / 2)
	initial_pos = node.offset



func _validation() -> int:
	error_popup_label.clear()
	var err := OK
	if not start_node:
		show_popup_error("Add start node to the graph!")
		err = ERR_DOES_NOT_EXIST
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		match node.type:
			"LINE", "DYNAMIC_LINE":
				pass
			"CONDITION":
				if node.condition_var.text.is_empty():
					err = ERR_INVALID_DATA
					show_popup_error("No condition variable at node '" + node.title + "'")
			"START":
				var connected := false
				for connection in graph_edit.get_connection_list():
					print(connection)
					if connection["from"] == node.name:
						connected = true
						break
				if not connected:
					show_popup_error("Start node should have at least 1 connection!")
					err = ERR_DOES_NOT_EXIST
			"SETTER":
				if node.var_name.text.is_empty() or node.var_value.text.is_empty():
					show_popup_error("Setter node '" + node.title + "' has empty parameters!")
					err = ERR_INVALID_DATA
			"CALLER":
				if node.var_name.text.is_empty():
					show_popup_error("Caller node '" + node.title + "' has empty function name!")
					err = ERR_INVALID_DATA
			_:
				err = ERR_INVALID_DATA
				show_popup_error("Unknown node type " + str(node.type) + ". Can't make validation.")
	return err


func show_popup_error(error_text : String) -> void:
	var time = Time.get_time_dict_from_system()
	error_popup_label.text += "\n[{0}:{1}:{2}".format([time["hour"], time["minute"], time["second"]]) + "]  " + error_text
	error_popup.popup()


func save_dialog(path, fn):	
	# save file
	var err = _validation()
	if fn.is_empty():
		# printerr("File name is empty!")
		return
	# file_path = file_path
	if not ".json" in fn:
		fn += ".json"
	
	var data = {}
	data["CONFIG"] = {"max_id" : max_id}
	data["TIMELINE"] = dialog
	var file = FileAccess.open(path + fn, FileAccess.WRITE)
	file.store_line(JSON.new().stringify(data))
	
	file.close()
	# $FileName.text = fn
	
	if err != OK:
		printerr("Error on validation!")
		show_popup_error("Saving complete, but you must resolve errors!")


	$VBoxContainer/HBoxContainer/Notification.visible = true
	timer.start()
	await timer.timeout
	$VBoxContainer/HBoxContainer/Notification.visible = false
	

func load_save(path, fn):
	if path.is_empty() or fn.is_empty():
		print("File not found!")
		return

	_clear()
	_set_filename(fn)

	var file = FileAccess.open(path + fn, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	file.close()
	var timeline = data["TIMELINE"]
	var config = data["CONFIG"]

	max_id = config["max_id"]

	var graph_names := {}

	for graph_node in timeline:
		var node_scene_path
		match timeline[graph_node]["type"]:
			"LINE":
				if _lite_line_nodes:
					node_scene_path = "res://LineNodeLite.tscn"
				else:
					node_scene_path = "res://LineNode.tscn"
			"DYNAMIC_LINE":
				node_scene_path = "res://DynamicLineNodeLite.tscn"
			"CONDITION":
				node_scene_path = "res://ConditionNode.tscn"
			"START":
				node_scene_path = "res://StartNode.tscn"
			"SETTER":
				node_scene_path = "res://SetterNode.tscn"
			"CALLER":
				node_scene_path = "res://CallerNode.tscn"
			_:
				printerr("Unknown node type!")
		# node = node.instance()
		var node = _create_graph_node(node_scene_path, Vector2.ZERO, false, false)
		# graph_edit.add_child(node)
		node.set_base_data($GraphEdit, timeline[graph_node], graph_node)
		node.set_data($GraphEdit, timeline[graph_node], graph_node)
		graph_names[graph_node] = node.name

	for graph_node in timeline:
		for tag in timeline[graph_node]:
			var from_port_num := -1
			match tag:
				"go_to":
					from_port_num = 0
				"go_to_true":
					from_port_num = 0
				"go_to_false":
					from_port_num = 1
				_:
					pass
			if from_port_num >= 0:
				var go_to_count = 0
				for go_to in timeline[graph_node][tag]: # get each in array
					graph_edit.connect_node(graph_names[graph_node], from_port_num, graph_names[timeline[graph_node][tag][go_to_count]], 0)
					go_to_count += 1


func _set_filename(new_name : String) -> void:
	$FileName.text = new_name
	file_name = new_name


func _clear() -> void:
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		node.delete()
	graph_edit.clear_connections()
	_on_StartNode_delete()
	_set_filename("")


func _call_mouse_popup() -> void:
	_mouse_popup.global_position = get_global_mouse_position()
	_mouse_popup.popup()


func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	graph_edit.connect_node(from, from_slot, to, to_slot)


func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	graph_edit.disconnect_node(from, from_slot, to, to_slot)


func _on_GraphEdit_gui_input(event):
	if Input.is_action_pressed("right_click"):
		_call_mouse_popup()
	

func _on_OpenNew_pressed():
	$DialoguesSearcher.popup_centered()


func _on_SaveAs_pressed():
	$ConfirmationDialog.popup_centered()


func _on_ConfirmationDialog_save_dialog_as(fn : String):
	_set_filename(fn)
	_on_Save_pressed()
	save_dialog(directory, fn)


func _on_DialoguesSearcher_directory_updated(path : String):
	directory = path


func _on_Clear_pressed():
	$Deletion.popup_centered()


func _on_MousePopup_id_pressed(id:int):
	match id:
		0:
			_create_graph_node("res://StartNode.tscn", _mouse_popup.global_position, true)
		1:
			if _lite_line_nodes:
				_create_graph_node("res://LineNodeLite.tscn", _mouse_popup.global_position)
			else:
				_create_graph_node("res://LineNode.tscn", _mouse_popup.global_position)
		2:
			_create_graph_node("res://ConditionNode.tscn", _mouse_popup.global_position)
		3:
			_create_graph_node("res://SetterNode.tscn", _mouse_popup.global_position)
		4:
			_create_graph_node("res://CallerNode.tscn", _mouse_popup.global_position)
		5:
			_create_graph_node("res://DynamicLineNodeLite.tscn", _mouse_popup.global_position)
		_:
			printerr("Unknown id!")

func _on_StartNode_delete():
	$MousePopup.set_item_disabled(0, false)


func _on_GraphEdit_connection_from_empty(to, to_slot, release_position):
	from_empty_to_node = to
	slot_to_connect = to_slot
	_call_mouse_popup()


func _on_GraphEdit_connection_to_empty(from, from_slot, release_position):
	from_node_to_empty = from
	slot_to_connect = from_slot
	_call_mouse_popup()


func _on_Deletion_confirmed():
	_clear()
