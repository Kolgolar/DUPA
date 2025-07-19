extends GraphEdit

signal error(error_text: String)

@export var _mouse_popup: PopupMenu
@export var _node_params_popup: PopupMenu
@export var _lite_line_nodes := false
@export var _actions_master: ActionsMaster
@export_dir var speakers_root_folder := "res://"
@export var all_speakers: Array[DUPA_SpeakerData]

var dialog = {}
var max_id := 0

var _focused_nodes := []
var _focused_nodes_names: Array[StringName] = []
var _context_menu_node: GraphNode
var _rmb_on_node_was_pressed := false
var _start_node: DUPA_GraphNodeStart
var _from_empty_to_node: String
var _from_node_to_empty: String
var _slot_to_connect: int
var _created_nodes: Dictionary[int, GraphNode]
var _deleted_nodes: Dictionary[int, Dictionary]
var _cached_speakers_names: PackedStringArray



func _ready() -> void:
	_node_params_popup.hide()


func check_for_speakers_changes() -> void:
	pass


func find_all_speakers() -> void:
	if all_speakers.is_empty():
		DUPA_Utils.find_all_resources(
			all_speakers,
			"DUPA_SpeakerData",
			speakers_root_folder,
			5
		)
	_cache_all_speakers_names()


func _cache_all_speakers_names() -> void:
	_cached_speakers_names.clear()
	_cached_speakers_names = all_speakers.map(
		func(sp): return "%s [%s]" % [sp.id_name, sp.resource_path]
	)


func get_all_speakers_paths() -> Array[Dictionary]:
	var paths: Array[Dictionary] = []
	for speaker in all_speakers:
		var res_path: String = speaker.resource_path
		var res_unqique_id: int = ResourceLoader.get_resource_uid(res_path)
		if !ResourceUID.has_id(res_unqique_id):
			DUPA_Logger.add_msg("Generating UID for %s." % res_path)
			res_unqique_id = ResourceUID.create_id()
			ResourceUID.add_id(res_unqique_id, res_path)
		paths.append({
			"path": res_path,
			"uid": res_unqique_id
		})
	return paths
		

	#return PackedStringArray(all_speakers.map(func(elem):
			#return (elem as DUPA_SpeakerData).resource_path)
	#)


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
		var new_node: DUPA_GraphNodeBase = _create_graph_node(node.scene_file_path, Vector2.ZERO, id)
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
		6:
			_context_menu_node.line_voice_visible = !_context_menu_node.line_voice_visible
		10:
			_delete_all_focused_nodes()
		11:
			_duplicate_all_focused_nodes()


func _on_mouse_popup_popup_hide() -> void:
	_mouse_popup.disable_start_node(_created_nodes.has(0))


func _on_mouse_popup_id_pressed(id:int):
	#node_path = "res://addons/dupa/project/graph_nodes/node_line.tscn"
	var dl := DUPA_Lib
	var node_path: String
	match id:
		0: node_path = dl.graph_node_paths[dl.NodeType.START]
		1: node_path = dl.graph_node_paths[dl.NodeType.LINE]
		2: node_path = dl.graph_node_paths[dl.NodeType.CONDITION]
		3: node_path = dl.graph_node_paths[dl.NodeType.DYNAMIC_ID_LINE]
		4: node_path = dl.graph_node_paths[dl.NodeType.ACTION]
		_:
			push_error("Unknown action id %s!" % id)
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


func set_graph_node_param(graph_node_id_str: int, param_name: StringName, value):
	_created_nodes[graph_node_id_str].set_param(param_name, value)


func _get_graph_node_scene_path_by_type(type: DUPA_Lib.NodeType) -> String:
	var path: String = DUPA_Lib.graph_node_paths.get(type, "")
	if path.is_empty():
		push_error("Unknown node type '%s'!" % type)
	return path


func _create_graph_node(scene_path: String, pos := Vector2.ZERO, id := -1) -> GraphNode:
	var node = load(scene_path).instantiate()
	add_child(node)

	if id == -1:
		if node is DUPA_GraphNodeStart:
			id = 0
			_start_node = node
		else:
			max_id += 1
			id = max_id
	elif id == 0:
		_start_node = node
		
	node.id = id
	
	if node is DUPA_GraphNodeLineBase:
		node.fill_speakers_list(_cached_speakers_names)

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
	node.call_deferred("activate_data_managing")

	return node


func _duplicate_all_focused_nodes():
	# TODO: Сохранять связи с нодами, которые тоже были продублированы?
	# TODO: Некорректная работа undo операции дублирования
	var nodes_to_duplicate_ids: PackedInt32Array
	for node in _focused_nodes:
		(node as GraphNode).set_deferred(&"selected", false)
		if !is_instance_valid(node) || node is DUPA_GraphNodeStart:
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
# Глобальные операции с нодами графа (например, 
# генерация словаря с данными таймлайна, удалить всё и т.д.)
#-------------------------------------------
#region Global Operations


func get_timeline() -> Dictionary:
	var timeline := {}
	var config_speakers := {}
	for node in get_tree().get_nodes_in_group(&"graph_nodes"):
		timeline[node.id] = node.gen_data()
	
	# Marks choice nodes. Adds "is_choice" field to a LINE nodes data in save file
	for node in timeline:
		var graph_node_data = timeline[node]
		if graph_node_data.type == DUPA_Lib.NodeType.CONDITION:
			continue
		var connected_nodes_ids = graph_node_data.go_to
		if connected_nodes_ids.size() <= 1: continue
		for choice_node_id in connected_nodes_ids:
			assert(
				timeline[choice_node_id].type == DUPA_Lib.NodeType.LINE,
				"Only a LINE node can represent choice"
			)
			timeline[choice_node_id][&"is_choice"] = true
	return timeline


func clear_nodes():
	clear_connections()
	for node in get_tree().get_nodes_in_group(&"graph_nodes"):
		node.delete()
	_created_nodes.clear()
	_deleted_nodes.clear()


func set_timeline(timeline: Dictionary, config: Dictionary):
	max_id = config[&"max_id"]
	var speakers = config[&"speakers"]
	all_speakers.clear()
	# Do not use map, because all_speakers is typed array
	for sp in speakers:
		var speaker_data: DUPA_SpeakerData
		var uid_path: String = ResourceUID.id_to_text(sp.uid)
		if FileAccess.file_exists(uid_path):
			speaker_data = load(uid_path)
		else:
			DUPA_Logger.add_warning("Speaker data was not found at %s. Searching by relative path..." % uid_path)
			speaker_data = load(sp.path)
		if !speaker_data:
			DUPA_Utils.create_confirmation_dialog("Speaker data was not found at %s. Perhaps it was deleted. You may try to manually update path to the file in .json file." % sp.path, self)
		all_speakers.append(speaker_data)
	_cache_all_speakers_names()
	var graph_nodes_names: Dictionary[int, StringName] = {}
	for graph_node_id_str in timeline:
		var graph_node_id_int := int(graph_node_id_str)
		var node_scene_path = _get_graph_node_scene_path_by_type(timeline[graph_node_id_str][&"type"])
		
		var node = _create_graph_node(node_scene_path, Vector2.ZERO, graph_node_id_int)
		node.set_data(timeline[graph_node_id_str])
		graph_nodes_names[graph_node_id_int] = node.name
	

	var set_go_to_nodes_connections = \
		func foo(graph_node_id_str: StringName, tag: StringName, from_port: int):
			if !timeline[graph_node_id_str].has(tag):
				DUPA_Logger.add_err("Tag %s was not found in blueprint node data!" % tag)
				return
				
			var graph_node_id_int := int(graph_node_id_str)
			var go_to_nodes: PackedInt32Array = timeline[graph_node_id_str][tag]
			for to_node_id in go_to_nodes: # Get each go_to node to connect to
				connect_node(
					graph_nodes_names[graph_node_id_int],
					from_port,
					graph_nodes_names[to_node_id],
					DUPA_Lib.INPUT_PORT
				)

	for graph_node_id_str in timeline:
		set_go_to_nodes_connections.call(graph_node_id_str, &"go_to", DUPA_Lib.OUTPUT_PORT)
		var graph_node_type: DUPA_Lib.NodeType = timeline[graph_node_id_str].type
		if graph_node_type != DUPA_Lib.NodeType.CONDITION: continue
		set_go_to_nodes_connections.call(graph_node_id_str, &"go_to_false", DUPA_Lib.OUTPUT_FALSE_PORT)


func validate_timeline() -> int:
	var err := OK
	if not _start_node:
		error.emit("Add start node to the graph!")
		err = ERR_DOES_NOT_EXIST
	for node in get_tree().get_nodes_in_group(&"graph_nodes"):
		var nt = DUPA_Lib.NodeType
		match node.type:
			nt.LINE, nt.DYNAMIC_ID_LINE:
				pass
			nt.CONDITION:
				if node.condition_var.text.is_empty():
					err = ERR_INVALID_DATA
					error.emit("No condition variable at node '" + node.title + "'")
			nt.START:
				var connected := false
				for connection in get_connection_list():
					if connection[&"from_node"] == node.name:
						connected = true
						break
				if not connected:
					error.emit("Start node should have at least 1 connection!")
					err = ERR_DOES_NOT_EXIST
			#nt.SETTER:
				#if node.var_name.text.is_empty() or node.var_value.text.is_empty():
					#error.emit("Setter node '" + node.title + "' has empty parameters!")
					#err = ERR_INVALID_DATA
			#nt.CALLER:
				#if node.var_name.text.is_empty():
					#error.emit("Caller node '" + node.title + "' has empty function name!")
					#err = ERR_INVALID_DATA
			nt.ACTION:
				if node.arg_name.text.is_empty():
					error.emit("Action node '" + node.title + "' has empty arg name!")
					err = ERR_INVALID_DATA
				if node.arg_name.text.is_empty():
					error.emit("Action node '" + node.title + "' has empty arg value!")
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

func _on_graph_node_param_changed(param_name: StringName, new_value, prev_value, graph_node_id_str: int):
	_actions_master.register_method_action("Param %s changed" % param_name, set_graph_node_param.bind(graph_node_id_str, param_name, new_value), set_graph_node_param.bind(graph_node_id_str, param_name, prev_value), false)


func _configure_node_popup(node: DUPA_GraphNodeBase):
	_node_params_popup.set_item_checked(0, node.desc_visible)
	if node.type == DUPA_Lib.NodeType.LINE:
		_node_params_popup.set_item_checked(1, node.line_voice_visible)


func _on_graph_node_rmb_pressed(node: GraphNode):
	if !node is DUPA_GraphNodeBase:
		printerr("Choosen node does not inherit DUPA_GraphNodeBase class!")
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
