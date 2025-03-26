extends GraphEdit

signal error(error_text: String)

@export var _mouse_popup: PopupMenu
@export var _node_params_popup: PopupMenu
@export var _lite_line_nodes := false
@export var _actions_master: ActionsMaster

var dialog = {}
var max_id := 1

var _focused_nodes := []
var _focused_nodes_names: Array[StringName] = []
var _context_menu_node: GraphNode
var _rmb_on_node_was_pressed := false
var _start_node: StartNode
var _from_empty_to_node: String
var _from_node_to_empty: String
var _slot_to_connect: int
var _created_nodes: Dictionary[int, GraphNode]
var _deleted_nodes: Dictionary[int, Dictionary]



func _ready() -> void:
	_node_params_popup.hide()



#-------------------------------------------
# Методы, вызываемые для операций Undo/Redo
#-------------------------------------------
#region Actions


func __delete_nodes_by_ids(ids: PackedInt32Array):
	for id in ids:
		var node = _created_nodes[id]
		if is_instance_valid(node):
			if id == 0:
				_mouse_popup.disable_start_node(false)
				_start_node = null
			_deleted_nodes[id] = node.gen_data()
			_created_nodes[id].delete()
			_created_nodes.erase(id)
			_focused_nodes.erase(node)
			_focused_nodes_names.erase(node.name)
	_focused_nodes.clear()


func __remove_connections(all_connections_data: Array):
	for connection_data in all_connections_data:
		disconnect_node(
			_created_nodes[connection_data.from_node].name,
			connection_data.from_port,
			_created_nodes[connection_data.to_node].name,
			connection_data.to_port
		)


func __retrieve_connections(all_connections_data: Array):
	for connection_data in all_connections_data:
		connect_node(
			_created_nodes[connection_data.from_node].name,
			connection_data.from_port,
			_created_nodes[connection_data.to_node].name,
			connection_data.to_port
		)


func __restore_nodes_by_ids(ids: PackedInt32Array):
	for id in ids:
		var node_data: Dictionary = _deleted_nodes[id]
		var node = _create_graph_node(
			_get_graph_node_scene_path_by_type(node_data.type),
			Vector2(node_data.offset_x, node_data.offset_y),
			id
		)
		node.set_data(_deleted_nodes[id])
		_deleted_nodes.erase(id)
		
		
func __duplicate_nodes(nodes_to_duplicate_ids: PackedInt32Array, forced_ids := PackedInt32Array()) -> PackedInt32Array:
	var created_nodes_ids: PackedInt32Array
	var shift := Vector2(30, 30)
	for i in nodes_to_duplicate_ids.size():
		var node = _created_nodes[nodes_to_duplicate_ids[i]]
		(node as GraphNode).set_deferred(&"selected", false)
		var id := -1
		if !forced_ids.is_empty():
			id = forced_ids[i]
		var new_node: DUPA_DefaultNode = _create_graph_node(node.scene_file_path, Vector2.ZERO, id)
		new_node.set_data(node.gen_data())
		new_node.position_offset = node.position_offset + shift
		new_node.set_deferred(&"selected", true)
		created_nodes_ids.append(new_node.id)
	return created_nodes_ids

#endregion



#-------------------------------------------
# Локальные операции с нодами графа
#-------------------------------------------
#region Local Operations

func _on_node_params_popup_id_pressed(id: int) -> void:
	match id:
		0:
			_context_menu_node.desc_visible = !_context_menu_node.desc_visible
		4:
			_remove_focused_nodes_connections()
		5:
			print("Нужно выводить краткую справку по ноде")
		10:
			_delete_all_focused_nodes()
		11:
			_duplicate_all_focused_nodes()


func _on_mouse_popup_popup_hide() -> void:
	_mouse_popup.disable_start_node(_created_nodes.has(0))


func _on_mouse_popup_id_pressed(id:int):
	var node_path: String
	match id:
		0:
			node_path = "res://addons/dupa/project/nodes/node_start.tscn"
		1:
			if _lite_line_nodes:
				node_path = "res://addons/dupa/project/nodes/node_line_lite.tscn"
			else:
				node_path = "res://addons/dupa/project/nodes/node_line.tscn"
		2:
			node_path = "res://addons/dupa/project/nodes/node_condition.tscn"
		3:
			node_path = "res://addons/dupa/project/nodes/node_setter.tscn"
		4:
			node_path = "res://addons/dupa/project/nodes/node_caller.tscn"
		5:
			node_path = "res://addons/dupa/project/nodes/node_dynamic_line_lite.tscn"
		_:
			printerr("Unknown action id %s!" % id)
			return
	
	var op_name := "Create Node"
	_actions_master.register_property_action(op_name, self, &"_from_empty_to_node", &"", _from_empty_to_node, false)
	_actions_master.register_property_action(op_name, self, &"_from_node_to_empty", &"", _from_node_to_empty, false, UndoRedo.MERGE_ALL)
	_actions_master.register_property_action(op_name, self, &"_slot_to_connect", -1, _slot_to_connect, false, UndoRedo.MERGE_ALL)
	var node = _create_graph_node(node_path, _mouse_popup.position)
	
	_actions_master.register_method_action(
		op_name,
		_create_graph_node.bind(
			node_path,
			_mouse_popup.position,
			true,
			node.id
		),
		__delete_nodes_by_ids.bind([node.id]),
		false,
		UndoRedo.MERGE_ALL
	)


func set_graph_node_param(graph_node_id: int, param_name: StringName, value):
	_created_nodes[graph_node_id].set_param(param_name, value)


func _get_graph_node_scene_path_by_type(type: StringName) -> String:
	match type:
			&"LINE":
				if _lite_line_nodes:
					return "res://addons/dupa/project/nodes/node_line_lite.tscn"
				else:
					return "res://addons/dupa/project/nodes/node_line.tscn"
			&"DYNAMIC_LINE":
				return "res://addons/dupa/project/nodes/node_dynamic_line_lite.tscn"
			&"CONDITION":
				return "res://addons/dupa/project/nodes/node_condition.tscn"
			&"START":
				return "res://addons/dupa/project/nodes/node_start.tscn"
			&"SETTER":
				return "res://addons/dupa/project/nodes/node_setter.tscn"
			&"CALLER":
				return "res://addons/dupa/project/nodes/node_caller.tscn"
			_:
				printerr("Unknown node type '%s'!" % type)
				return ""


func _create_graph_node(scene_path: String, pos := Vector2.ZERO, id := -1) -> GraphNode:
	var node = load(scene_path).instantiate()
	add_child(node)

	if id == -1:
		if node is StartNode:
			id = 0
			_start_node = node
		else:
			max_id += 1
			id = max_id
	elif id == 0:
		_start_node = node
		
	node.id = id

	node.rmb_pressed.connect(_on_graph_node_rmb_pressed.bind(node))
	node.param_changed.connect(_on_graph_node_param_changed.bind(node.id))
	
	var real_size = size / zoom
	var offset = scroll_offset
	node.position_offset = (pos + scroll_offset) / zoom - Vector2(0, node.size.y / 2)
	
	#if remember_created:
	_created_nodes[node.id] = node
	
	# Создаём соединение с другой нодой, если необходимо
	if not _from_empty_to_node.is_empty():
		connect_node(node.name, 0, _from_empty_to_node, _slot_to_connect)
		_from_empty_to_node = &""
	elif not _from_node_to_empty.is_empty():
		connect_node(_from_node_to_empty, _slot_to_connect, node.name, 0)
		_from_node_to_empty = &""
	_slot_to_connect = -1
	
	_mouse_popup.disable_start_node(_created_nodes.has(0))
	node.activate_data_managing()

	return node


func _duplicate_all_focused_nodes():
	# TODO: Сохранять связи с нодами, которые тоже были продублированы?
	# TODO: Некорректная работа undo операции дублирования
	var nodes_to_duplicate_ids: PackedInt32Array
	for node in _focused_nodes:
		(node as GraphNode).set_deferred(&"selected", false)
		if !is_instance_valid(node) || node is StartNode:
			printerr("Node is not valid or you're trying to duplicate Start Node (u cant, bro)")
			continue
		else:
			nodes_to_duplicate_ids.append(node.id)
			
	var created_nodes_ids: PackedInt32Array = __duplicate_nodes(nodes_to_duplicate_ids)
	
	_actions_master.register_method_action(
		&"Duplicate node(s)",
		__duplicate_nodes.bind(nodes_to_duplicate_ids, created_nodes_ids),
		__delete_nodes_by_ids.bind(created_nodes_ids),
		false
	)
	

func _delete_all_focused_nodes():
	var ids_to_delete: PackedInt32Array = []
	
	for n in _focused_nodes:
		ids_to_delete.append(n.id)
	var act_name := "Delete node(s)"
	_remove_focused_nodes_connections(act_name)
	_actions_master.register_method_action(
		act_name,
		__delete_nodes_by_ids.bind(ids_to_delete),
		__restore_nodes_by_ids.bind(ids_to_delete),
		true,
		UndoRedo.MERGE_ALL,
		true
	)


func _remove_focused_nodes_connections(act_name := "Remove node(s) connections"):
	var all_connections_data: Array
	for connection_data in get_connection_list():
		if connection_data.from_node in _focused_nodes_names || connection_data.to_node in _focused_nodes_names:
			all_connections_data.append({
				&"from_node": get_node(NodePath(connection_data.from_node)).id,
				&"from_port": connection_data.from_port,
				&"to_node": get_node(NodePath(connection_data.to_node)).id,
				&"to_port": connection_data.from_port,
			})
	_actions_master.register_method_action(
		act_name,
		__remove_connections.bind(all_connections_data),
		__retrieve_connections.bind(all_connections_data),
		true,
		UndoRedo.MERGE_DISABLE,
		true
	)

	
func _call_mouse_popup() -> void:
	_mouse_popup.position = get_global_mouse_position()
	_mouse_popup.popup()

#endregion



#-------------------------------------------
# Глобальные операции с нодами графа (например, удалить всё и т.д.)
#-------------------------------------------
#region Global Operations


func get_timeline() -> Dictionary:
	var timeline := {}
	for node in get_tree().get_nodes_in_group(&"graph_nodes"):
		timeline[str(node.id)] = node.gen_data()
	return timeline


func clear_nodes():
	clear_connections()
	for node in get_tree().get_nodes_in_group(&"graph_nodes"):
		node.delete()
	_created_nodes.clear()
	_deleted_nodes.clear()


func set_timeline(timeline: Dictionary, config: Dictionary):
	max_id = config[&"max_id"]

	var graph_names := {}
	for graph_node_id in timeline:
		var node_scene_path = _get_graph_node_scene_path_by_type(timeline[graph_node_id][&"type"])
		
		var node = _create_graph_node(node_scene_path, Vector2.ZERO, int(graph_node_id))
		node.set_data(timeline[graph_node_id])
		graph_names[graph_node_id] = node.name
	
	for graph_node_id in timeline:
		for tag in timeline[graph_node_id]:
			var from_port_num := -1
			match tag:
				&"go_to":
					from_port_num = 0
				&"go_to_true":
					from_port_num = 0
				&"go_to_false":
					from_port_num = 1
				_:
					pass
			if from_port_num >= 0:
				var go_to_count = 0
				for go_to in timeline[graph_node_id][tag]: # get each in array
					connect_node(graph_names[graph_node_id], from_port_num, graph_names[timeline[graph_node_id][tag][go_to_count]], 0)
					go_to_count += 1


func validate_timeline() -> int:
	var err := OK
	if not _start_node:
		error.emit("Add start node to the graph!")
		err = ERR_DOES_NOT_EXIST
	for node in get_tree().get_nodes_in_group(&"graph_nodes"):
		match node.type:
			&"LINE", &"DYNAMIC_LINE":
				pass
			&"CONDITION":
				if node.condition_var.text.is_empty():
					err = ERR_INVALID_DATA
					error.emit("No condition variable at node '" + node.title + "'")
			&"START":
				var connected := false
				for connection in get_connection_list():
					if connection[&"from_node"] == node.name:
						connected = true
						break
				if not connected:
					error.emit("Start node should have at least 1 connection!")
					err = ERR_DOES_NOT_EXIST
			&"SETTER":
				if node.var_name.text.is_empty() or node.var_value.text.is_empty():
					error.emit("Setter node '" + node.title + "' has empty parameters!")
					err = ERR_INVALID_DATA
			&"CALLER":
				if node.var_name.text.is_empty():
					error.emit("Caller node '" + node.title + "' has empty function name!")
					err = ERR_INVALID_DATA
			_:
				err = ERR_INVALID_DATA
				error.emit("Unknown node type " + str(node.type) + ". Can't make validation.")
	return err

#endregion



#-------------------------------------------
# Сигналы от нод графа
#-------------------------------------------
#region GraphNodes Signals

func _on_graph_node_param_changed(param_name: StringName, new_value, prev_value, graph_node_id: int):
	_actions_master.register_method_action("Param %s changed" % param_name, set_graph_node_param.bind(graph_node_id, param_name, new_value), set_graph_node_param.bind(graph_node_id, param_name, prev_value), false)


func _configure_node_popup(node: DUPA_DefaultNode):
	_node_params_popup.set_item_checked(0, node.desc_visible)


func _on_graph_node_rmb_pressed(node: GraphNode):
	if !node is DUPA_DefaultNode:
		printerr("Choosen node does not inherit DUPA_DefaultNode class!")
		return
	_context_menu_node = node
	_configure_node_popup(node)
	_node_params_popup.popup()
	_node_params_popup.position = get_local_mouse_position()
	node.selected = true
	_rmb_on_node_was_pressed = true
	
#endregion



#-------------------------------------------
# Сигналы от графа
#-------------------------------------------
#region GraphEdit signals

func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	_from_empty_to_node = to_node
	_slot_to_connect = to_port
	_call_mouse_popup()


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	_from_node_to_empty = from_node
	_slot_to_connect = from_port
	_mouse_popup.disable_start_node(true)
	_call_mouse_popup()


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_actions_master.register_method_action(
		"Connect nodes",
		connect_node.bind(from_node, from_port, to_node, to_port),
		disconnect_node.bind(from_node, from_port, to_node, to_port)
	)


func _on_delete_nodes_request(_nodes: Array[StringName]) -> void:
	_delete_all_focused_nodes()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_actions_master.register_method_action(
		"Disconnect nodes",
		connect_node.bind(from_node, from_port, to_node, to_port),
		disconnect_node.bind(from_node, from_port, to_node, to_port)
	)


func _on_duplicate_nodes_request() -> void:
	_duplicate_all_focused_nodes()


func _on_node_selected(node: Node) -> void:
	if Input.is_action_pressed("right_click"):
		for n in _focused_nodes:
			n.selected = false
		_focused_nodes.clear()
		_focused_nodes_names.clear()
	_focused_nodes.append(node)
	_focused_nodes_names.append(node.name)


func _on_node_deselected(node: Node) -> void:
	_focused_nodes.erase(node)
	_focused_nodes_names.erase(node.name)


func _on_popup_request(at_position: Vector2) -> void:
	if _rmb_on_node_was_pressed:
		_rmb_on_node_was_pressed = false
	else:
		_call_mouse_popup()

#endregion



#-------------------------------------------
# Всё, что касается локализации
#-------------------------------------------
#region Localization

func _search_for_localization():
	if _start_node:
		var path = _start_node.data.source
		
#endregion
