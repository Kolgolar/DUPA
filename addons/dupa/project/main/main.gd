extends Control

@export var _mouse_popup: PopupMenu
@export var _node_params_popup: PopupMenu

@export var _lite_line_nodes := false

var dialog = {}
var dialog_for_localisation = []
var file_name := ""
var directory := ""
var initial_pos = Vector2(40,40)

var focused_nodes := []
var _context_menu_node: GraphNode
var _rmb_on_node_was_pressed := false

var max_id = 1
var _start_node: StartNode

var from_empty_to_node : String
var slot_to_connect : int
var from_node_to_empty : String

@onready var error_popup = $Error
@onready var error_popup_label = $Error/RichTextLabel
@onready var graph_edit = $GraphEdit


func _ready():
	_node_params_popup.hide()
	show_start_screen()
	


func _search_for_localization():
	if _start_node:
		var path = _start_node.data.source



# SAVE 
func _on_save_pressed(): 
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
	if event.is_action_pressed("save"):
		_on_save_pressed()


func _on_graph_edit_node_selected(node):
	focused_nodes.append(node)


func _on_graph_edit_node_deselected(node):
	focused_nodes.erase(node)


func _on_graph_node_rmb_pressed(node: GraphNode):
	if !node is DefaultNode:
		printerr("Choosen node does not inherit DefaultNode class!")
		return
	_context_menu_node = node
	_configure_node_popup(node)
	_node_params_popup.set_item_disabled(0, node is StartNode)
	_node_params_popup.popup()
	_node_params_popup.position = get_local_mouse_position()
	node.selected = true
	_rmb_on_node_was_pressed = true


func _configure_node_popup(node: DefaultNode):
	_node_params_popup.set_item_checked(0, node.desc_visible)
	#print("Config")


func _create_graph_node(scene : String, pos := Vector2.ZERO, _is_start_node := false, set_to_defaults := true) -> GraphNode:
	var node = load(scene).instantiate()
	graph_edit.add_child(node)
	node.rmb_pressed.connect(_on_graph_node_rmb_pressed.bind(node))
	if node is StartNode:
		$MousePopup.set_item_disabled(0, true)
		node.connect("on_delete", Callable(self, "_on_start_node_deleted"))
		node.connect("focus_entered", Callable(self, "_on_graph_node_focus_entered"))
		node.connect("focus_exited", Callable(self, "_on_graph_node_focus_exited"))
		_start_node = node
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
	node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom - Vector2(0, node.size.y / 2)
	initial_pos = node.position_offset



func _validation() -> int:
	error_popup_label.clear()
	var err := OK
	if not _start_node:
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

	%SaveNotify.show()
	await get_tree().create_timer(3.0).timeout
	%SaveNotify.hide()
	

func load_save(path: String):
	var fn = path.split("/")[-1]
	if path.is_empty() or fn.is_empty():
		print("File not found at %s" % path)
		return

	_clear()
	_set_filename(fn)

	var file = FileAccess.open(path, FileAccess.READ)
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
					node_scene_path = "res://addons/dupa/project/nodes/node_line_lite.tscn"
				else:
					node_scene_path = "res://addons/dupa/project/nodes/node_line.tscn"
			"DYNAMIC_LINE":
				node_scene_path = "res://addons/dupa/project/nodes/node_dynamic_line_lite.tscn"
			"CONDITION":
				node_scene_path = "res://addons/dupa/project/nodes/node_condition.tscn"
			"START":
				node_scene_path = "res://addons/dupa/project/nodes/node_start.tscn"
			"SETTER":
				node_scene_path = "res://addons/dupa/project/nodes/node_setter.tscn"
			"CALLER":
				node_scene_path = "res://addons/dupa/project/nodes/node_caller.tscn"
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
	_set_filename("")


func _call_mouse_popup() -> void:
	_mouse_popup.position = get_global_mouse_position()
	_mouse_popup.popup()


func _on_graph_edit_connection_request(from, from_slot, to, to_slot):
	graph_edit.connect_node(from, from_slot, to, to_slot)


func _on_grap_edit_disconnection_request(from, from_slot, to, to_slot):
	graph_edit.disconnect_node(from, from_slot, to, to_slot)


func _on_graph_edit_gui_input(event):
	pass
	#if Input.is_action_just_pressed("right_click"):
		#await get_tree().process_frame
		#if !_node_params_popup.visible:
			#_call_mouse_popup()


func _unhandled_input(event: InputEvent):
	if Input.is_action_just_pressed("right_click"):
		#_call_mouse_popup()
		pass
	

func _on_open_new_pressed():
	$DialogsSearcher.popup_centered()


func _on_save_as_pressed():
	$ConfirmationDialog.popup_centered()


func _on_confirmation_dialog_save_dialog_as(fn : String):
	_set_filename(fn)
	_on_save_pressed()
	save_dialog(directory, fn)


func _on_dialogs_searcher_directory_updated(path : String):
	directory = path


func _on_clear_pressed():
	$Deletion.popup_centered()


func _on_mous_popup_id_pressed(id:int):
	match id:
		0:
			_create_graph_node("res://addons/dupa/project/nodes/node_start.tscn", _mouse_popup.position, true)
		1:
			if _lite_line_nodes:
				_create_graph_node("res://addons/dupa/project/nodes/node_line_lite.tscn", _mouse_popup.position)
			else:
				_create_graph_node("res://addons/dupa/project/nodes/node_line.tscn", _mouse_popup.position)
		2:
			_create_graph_node("res://addons/dupa/project/nodes/node_condition.tscn", _mouse_popup.position)
		3:
			_create_graph_node("res://addons/dupa/project/nodes/node_setter.tscn", _mouse_popup.position)
		4:
			_create_graph_node("res://addons/dupa/project/nodes/node_caller.tscn", _mouse_popup.position)
		5:
			_create_graph_node("res://addons/dupa/project/nodes/node_dynamic_line_lite.tscn", _mouse_popup.position)
		_:
			printerr("Unknown id!")

func _on_start_node_deleted():
	$MousePopup.set_item_disabled(0, false)
	_start_node = null


func _on_graph_edit_connection_from_empty(to, to_slot, release_position):
	from_empty_to_node = to
	slot_to_connect = to_slot
	_call_mouse_popup()


func _on_graph_edit_connection_to_empty(from, from_slot, release_position):
	from_node_to_empty = from
	slot_to_connect = from_slot
	_call_mouse_popup()


func _on_deletion_confirmed():
	_clear()


func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	if _rmb_on_node_was_pressed:
		_rmb_on_node_was_pressed = false
	else:
		_call_mouse_popup()
	

func _duplicate_all_focused_nodes():
	var shift := Vector2(30, 30)
	for n in focused_nodes:
		if is_instance_valid(n) and not n is StartNode:
			var new_node : GraphNode = n.duplicate()
			new_node.rmb_pressed.disconnect(_on_graph_node_rmb_pressed)
			new_node.rmb_pressed.connect(_on_graph_node_rmb_pressed.bind(new_node))
			new_node.position_offset += shift
			(n as GraphNode).selected = false
			new_node.selected = true
			focused_nodes.erase(n)
			focused_nodes.append(new_node)
			graph_edit.add_child(new_node)
		else:
			printerr("Node is not valid or you're trying to duplicate Start Node (u cant, bro)")


func _on_graph_edit_duplicate_nodes_request() -> void:
	_duplicate_all_focused_nodes()


func _delete_all_focused_nodes():
	for n in focused_nodes:
		if is_instance_valid(n):
			n.delete()
	focused_nodes.clear()


func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	_delete_all_focused_nodes()


func _on_node_params_popup_id_pressed(id: int) -> void:
	match id:
		0:
			_context_menu_node.desc_visible = !_context_menu_node.desc_visible
		10:
			_delete_all_focused_nodes()
		11:
			_duplicate_all_focused_nodes()


func show_start_screen():
	$StartMenu.show()
	$Editor.hide()


func _on_dialogs_searcher_file_selected(path: String) -> void:
	load_save(path)
	$Editor.show()



func _on_start_menu_open_timeline() -> void:
	%DialogsSearcher.show()


func _on_dialogs_searcher_canceled() -> void:
	show_start_screen()
