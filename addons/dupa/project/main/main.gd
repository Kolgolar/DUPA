extends Control

@export var _mouse_popup: PopupMenu
@export var _node_params_popup: PopupMenu

@export var _lite_line_nodes := false

var dialog = {}
var dialog_for_localisation = []
var file_name := ""
var directory := ""
var initial_pos = Vector2(40,40)

var _focused_nodes := []
var _focused_nodes_names: Array[StringName] = []
var _context_menu_node: GraphNode
var _rmb_on_node_was_pressed := false

var max_id := 1
var _start_node: StartNode

var from_empty_to_node : String
var slot_to_connect : int
var from_node_to_empty : String

var _created_nodes: Dictionary[int, GraphNode]
var _deleted_nodes: Dictionary[int, Dictionary]

@onready var error_popup = $Error
@onready var error_popup_label = $Error/RichTextLabel
@onready var graph_edit = $Editor/GraphEdit


func _ready():
	_node_params_popup.hide()
	show_start_screen()
	_reset()

	


func _search_for_localization():
	if _start_node:
		var path = _start_node.data.source



# SAVE 
func _save_as_requested():
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.SAVE_TIMELINE, true, _on_save_dialog_as)
	add_child(fm)



func _on_save_pressed(): 
	if file_name.is_empty() || directory.is_empty():
		_save_as_requested()
		return
	
	dialog.clear()
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		dialog[str(node.id)].merge(node.gen_data(graph_edit))

	# print(dialog)
	save_dialog(directory, file_name)
	

func _input(event):
	if event.is_action_pressed(&"save"):
		_on_save_pressed()
	
	elif event.is_action_pressed(&"ui_undo"):
		ActionsMaster.undo()
	elif event.is_action_pressed(&"ui_redo"):
		ActionsMaster.redo()


func _on_graph_edit_node_selected(node):
	if Input.is_action_pressed("right_click"):
		for n in _focused_nodes:
			n.selected = false
		_focused_nodes.clear()
		_focused_nodes_names.clear()
	_focused_nodes.append(node)
	_focused_nodes_names.append(node.name)
	

func _on_graph_edit_node_deselected(node):
	_focused_nodes.erase(node)
	_focused_nodes_names.erase(node.name)


func _on_graph_node_rmb_pressed(node: GraphNode):
	if !node is DefaultNode:
		printerr("Choosen node does not inherit DefaultNode class!")
		return
	_context_menu_node = node
	_configure_node_popup(node)
	_node_params_popup.popup()
	_node_params_popup.position = get_local_mouse_position()
	node.selected = true
	_rmb_on_node_was_pressed = true


func _configure_node_popup(node: DefaultNode):
	_node_params_popup.set_item_checked(0, node.desc_visible)
	#print("Config")


func _on_graph_node_position_offset_changed(from: Vector2, to: Vector2, node: GraphNode):
	#ActionsMaster.register_property_action("Move Node", node, &"position_offset", from, to)
	pass

func _create_graph_node(scene_path: String, pos := Vector2.ZERO, _is_start_node := false, remember_created := true, id := -1) -> GraphNode:
	var node = load(scene_path).instantiate()
	graph_edit.add_child(node)

	node.rmb_pressed.connect(_on_graph_node_rmb_pressed.bind(node))
	#node.position_offset_changed_action.connect(_on_graph_node_position_offset_changed.bind(node))
	
	if node is StartNode:
		node.connect("focus_entered", Callable(self, "_on_graph_node_focus_entered"))
		node.connect("focus_exited", Callable(self, "_on_graph_node_focus_exited"))
		_start_node = node
	#node.on_delete.connect(_on_node_deletion.bind(node))
	
	if id == -1:
		if node is StartNode:
			id = 0
		else:
			max_id += 1
			id = max_id
		
	node.id = id

	node.param_changed.connect(_on_graph_node_param_changed.bind(node.id))

	var real_size = graph_edit.size / graph_edit.zoom
	var offset = graph_edit.scroll_offset
	node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom - Vector2(0, node.size.y / 2)
	initial_pos = node.position_offset
	
	
	if not from_empty_to_node.is_empty():
		graph_edit.connect_node(node.name, 0, from_empty_to_node, slot_to_connect)
		#ActionsMaster.register_method_action(
			#"Connect nodes",
			#graph_edit.connect_node.bind(node.name, 0, from_empty_to_node, slot_to_connect),
			#graph_edit.disconnect_node(node.name, 0, from_empty_to_node, slot_to_connect)
		#)
		from_empty_to_node = ""
	elif not from_node_to_empty.is_empty():
		graph_edit.connect_node(from_node_to_empty, slot_to_connect, node.name, 0)
		from_node_to_empty = ""
	slot_to_connect = -1
	
	if remember_created:
		_created_nodes[node.id] = node
	if _deleted_nodes.has(node.id):
		node.set_data(graph_edit, _deleted_nodes[node.id], "")
		print(_deleted_nodes[node.id])
		_deleted_nodes.erase(node.id)
	
	_mouse_popup.disable_start_node(_created_nodes.has(0))
	
	node.activate_data_managing()
	
	return node


func _on_graph_node_param_changed(param_name: StringName, new_value, prev_value, graph_node_id: int):
	ActionsMaster.register_method_action("Param %s changed" % param_name, set_graph_node_param.bind(graph_node_id, param_name, new_value), set_graph_node_param.bind(graph_node_id, param_name, prev_value), false)


func set_graph_node_param(graph_node_id: int, param_name: StringName, value):
	_created_nodes[graph_node_id].set_param(param_name, value)





#func _set_new_node_params(node : GraphNode, pos : Vector2, _is_start_node := false) -> void:
	#if node is StartNode:
		#node.id = 0
	#else:
		#max_id += 1
		#node.id = max_id
	#var real_size = graph_edit.size / graph_edit.zoom
	#var offset = graph_edit.scroll_offset
	#node.position_offset = (pos + graph_edit.scroll_offset) / graph_edit.zoom - Vector2(0, node.size.y / 2)
	#initial_pos = node.position_offset



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
					if connection["from_node"] == node.name:
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
	error_popup_label.text = "[{0}:{1}:{2}".format([time["hour"], time["minute"], time["second"]]) + "]  " + error_text + "\n"
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
	
	if err != OK:
		printerr("Error on validation!")
		show_popup_error("Saving complete, but you must resolve errors!")

	%SaveNotify.show()
	await get_tree().create_timer(3.0).timeout
	%SaveNotify.hide()
	

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
			"SETTER":
				return "res://addons/dupa/project/nodes/node_setter.tscn"
			"CALLER":
				return "res://addons/dupa/project/nodes/node_caller.tscn"
			_:
				printerr("Unknown node type!")
				return ""


func load_save(path: String):
	var fn = path.split("/")[-1]
	if path.is_empty() or fn.is_empty():
		print("File not found at %s" % path)
		return

	_reset()
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
		var node_scene_path = _get_graph_node_scene_path_by_type(timeline[graph_node]["type"])
		
		# node = node.instance()
		var node = _create_graph_node(node_scene_path, Vector2.ZERO, false, false)
		# graph_edit.add_child(node)
		#node.set_base_data(graph_edit, timeline[graph_node], graph_node)
		node.set_data(graph_edit, timeline[graph_node], graph_node)
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
	%TimelineName.text = new_name
	file_name = new_name


func _reset() -> void:
	_clear_nodes()
	_set_filename("(not saved!)")


func _clear_nodes():
	graph_edit.clear_connections()
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		node.delete()


func _call_mouse_popup() -> void:
	_mouse_popup.position = get_global_mouse_position()
	_mouse_popup.popup()


func _on_graph_edit_connection_request(from, from_slot, to, to_slot):
	ActionsMaster.register_method_action(
		"Connect nodes",
		graph_edit.connect_node.bind(from, from_slot, to, to_slot),
		graph_edit.disconnect_node.bind(from, from_slot, to, to_slot)
	)


func _on_grap_edit_disconnection_request(from, from_slot, to, to_slot):
	ActionsMaster.register_method_action(
		"Disconnect nodes",
		graph_edit.disconnect_node.bind(from, from_slot, to, to_slot),
		graph_edit.connect_node.bind(from, from_slot, to, to_slot),
	)



func _unhandled_input(event: InputEvent):
	if Input.is_action_just_pressed("right_click"):
		#_call_mouse_popup()
		pass
	

func _on_open_new_pressed():
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.OPEN_TIMELINE, true, _on_dupa_file_manager_file_selected)
	add_child(fm)


func _on_save_as_pressed():
	#$ConfirmationDialog.popup_centered()
	_save_as_requested()


func _on_save_dialog_as(path : String):
	var directory = path.get_base_dir()
	var fn = path.get_file()
	_set_filename(fn)
	#_on_save_pressed()
	save_dialog(directory, fn)


func _on_dialogs_searcher_directory_updated(path : String):
	directory = path


func _on_clear_pressed():
	$Deletion.popup_centered()


func _on_mous_popup_id_pressed(id:int):
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
			node_path = "res://addons/dupa/project/nodes/node_caller.tscn"
		_:
			printerr("Unknown id!")
			return
	
	var op_name = "Create Node"
	ActionsMaster.register_property_action(op_name, self, "from_empty_to_node", "", from_empty_to_node, false)
	ActionsMaster.register_property_action(op_name, self, "from_node_to_empty", "", from_node_to_empty, false, UndoRedo.MERGE_ALL)
	ActionsMaster.register_property_action(op_name, self, "slot_to_connect", -1, slot_to_connect, false, UndoRedo.MERGE_ALL)
	var is_start_node = id == 0
	var node = _create_graph_node(node_path, _mouse_popup.position, is_start_node)
	ActionsMaster.register_method_action(
		op_name,
		_create_graph_node.bind(
			node_path,
			_mouse_popup.position,
			is_start_node,
			true,
			node.id
		),
		_delete_by_id.bind(node.id),
		false,
		UndoRedo.MERGE_ALL
	)
	

func _on_graph_edit_connection_from_empty(to, to_slot, release_position):
	from_empty_to_node = to
	slot_to_connect = to_slot
	_call_mouse_popup()


func _on_graph_edit_connection_to_empty(from, from_slot, release_position):
	from_node_to_empty = from
	slot_to_connect = from_slot
	_mouse_popup.disable_start_node(true)
	_call_mouse_popup()


# Запоминать индексы в массиве всех нод???
func _delete_by_id(id: int):
	_deleted_nodes[id] = _created_nodes[id].gen_data(graph_edit)
	_created_nodes[id].delete()
	_created_nodes.erase(id)


func _on_deletion_confirmed():
	_clear_nodes()


func _on_graph_edit_popup_request(at_position: Vector2) -> void:
	if _rmb_on_node_was_pressed:
		_rmb_on_node_was_pressed = false
	else:
		_call_mouse_popup()
	

func _duplicate_all_focused_nodes():
	var shift := Vector2(30, 30)
	for n in _focused_nodes:
		if is_instance_valid(n) and not n is StartNode:
			var new_node : GraphNode = n.duplicate()
			new_node.rmb_pressed.disconnect(_on_graph_node_rmb_pressed)
			new_node.rmb_pressed.connect(_on_graph_node_rmb_pressed.bind(new_node))
			new_node.position_offset += shift
			(n as GraphNode).selected = false
			new_node.selected = true
			_on_graph_edit_node_deselected(n)
			graph_edit.add_child(new_node)
			_on_graph_edit_node_selected(new_node)
			#_focused_nodes.append(new_node)
		else:
			printerr("Node is not valid or you're trying to duplicate Start Node (u cant, bro)")


func _on_graph_edit_duplicate_nodes_request() -> void:
	_duplicate_all_focused_nodes()


func _delete_all_focused_nodes():
	var ids_to_delete: PackedInt32Array = []
	
	for n in _focused_nodes:
		ids_to_delete.append(n.id)
	ActionsMaster.register_method_action(
		"Delete node(s)",
		__delete_nodes_by_ids.bind(ids_to_delete),
		__restore_nodes_by_ids.bind(ids_to_delete),
		true,
		UndoRedo.MERGE_ALL if ids_to_delete.size() > 1 else UndoRedo.MERGE_DISABLE
	)

func __restore_nodes_by_ids(ids: PackedInt32Array):
	for id in ids:
		var node_data: Dictionary = _deleted_nodes[id]
		_create_graph_node(
			_get_graph_node_scene_path_by_type(node_data.type),
			Vector2(node_data.offset_x, node_data.offset_y),
			id == 0,
			true,
			id
		)


func __delete_nodes_by_ids(ids: PackedInt32Array):
	for id in ids:
		if is_instance_valid(_created_nodes[id]):
			if id == 0:
				_mouse_popup.disable_start_node(false)
				_start_node = null
			_delete_by_id(id)
	_focused_nodes.clear()


func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]) -> void:
	_delete_all_focused_nodes()


func _on_node_params_popup_id_pressed(id: int) -> void:
	match id:
		0:
			_context_menu_node.desc_visible = !_context_menu_node.desc_visible
		4:
			for connection_data in graph_edit.get_connection_list():
				if connection_data.from_node in _focused_nodes_names || connection_data.to_node in _focused_nodes_names:
					graph_edit.disconnect_node(
						connection_data.from_node,
						connection_data.from_port,
						connection_data.to_node,
						connection_data.to_port
					)
				
		10:
			_delete_all_focused_nodes()
		11:
			_duplicate_all_focused_nodes()


func show_start_screen():
	$StartPanels.show()
	$Editor.hide()


func _on_dupa_file_manager_file_selected(path: String) -> void:
	load_save(path)
	$Editor.show()


func _on_dupa_file_manager_timeline_saved(path: String):
	load_save(path)


func _on_open_timeline() -> void:
	var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.OPEN_TIMELINE, true, _on_dupa_file_manager_file_selected)
	add_child(fm)


func _on_create_timeline() -> void:
	#var fm = DupaFileManager.create(DupaFileManager.FileManagerMode.SAVE_TIMELINE, true, _on_dupa_file_manager_timeline_saved)
	#add_child(fm)
	#_set_filename("")
	#directory = ""
	if !file_name.is_empty():
		# TODO: Стыбзить из лмстудио код создания конфёрм попапов
		# Спросить, точно ли пользователь хочет создать новый таймлайн, ведь тут есть
		# несохранённые изменения
		# TODO: Соответственно, нужен механизм туду реду, чтобы определять, были
		# ли совершены действия, которые не были сохранены.
		pass
	%Editor.show()
	_reset()


func _on_undo_action_pressed() -> void:
	ActionsMaster.undo()
	

func _on_redo_action_pressed() -> void:
	ActionsMaster.redo()


func _on_mouse_popup_popup_hide() -> void:
	_mouse_popup.disable_start_node(_created_nodes.has(0))
