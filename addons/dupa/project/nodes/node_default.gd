extends GraphNode

class_name DefaultNode

@onready var main = $HBoxContainer/MainColumn
@onready var _prev_pos_offset := position_offset
@onready var type := &"DEFAULT"

@onready var _description = %Description

@onready var _cached_data := {}

var id : int
var short_title := ""

var desc_visible := false:
	set(value):
		desc_visible = value
		_description.visible = value
		size.y -= 64

signal name_changed
signal rmb_pressed
signal param_changed(param: StringName, new_value, prev_value)

func _ready():
	_description.hide()


func _get_fields_to_track() -> Array[Control]:
	var fields: Array[Control] = [_description]
	return fields


# Вызывается ПОСЛЕ того, как нода была добавлена в граф и настроена. Иначе будут
# ненужные реагирования на изменения во время настройки ноды.
func activate_data_managing():
	for node in _get_fields_to_track():
		#print(node.get_class())
		match node.get_class():
			&"CheckButton":
				node.toggled.connect(func(toggled: bool): register_action())
			&"TextEdit":
				node.focus_exited.connect(register_action)
				node.text_set.connect(register_action)
				node.visibility_changed.connect(register_action)
			&"LineEdit":
				node.text_submitted.connect(func(new_text: String): register_action())
				node.focus_exited.connect(register_action)
	
	await get_tree().process_frame
	if _cached_data.is_empty():
		_cached_data = gen_data(get_parent(), true)


func set_data(graph_edit : GraphEdit, data : Dictionary) -> void:
	for param in data:
		set_param(param, data[param])
		


func set_param(param_name: StringName, value):
	match param_name:
		# NOTE: offset_x и offset_y сохраняются в json-файл, а offset используется
		# в операциях REDO/UNDO. Возможно, стоит полностью отказаться от offset_x и 
		# offset_y (но как сохранять Vector2 в json?)
		&"offset":
			position_offset = value
		&"offset_x":
			position_offset.x = value
		&"offset_y":
			position_offset.y = value
		&"type":
			type = value
		&"desc":
			_description.text = value
		&"desc_visible":
			set_block_signals(true)
			desc_visible = value
			set_block_signals(false)
			

func gen_data(graph_edit: GraphEdit, allow_empty := false) -> Dictionary:
	var data := {}
	# data["id"] = id
	data[&"type"] = type
	data[&"offset_x"] = position_offset.x
	data[&"offset_y"] = position_offset.y
	data[&"desc"] = _description.text
	data[&"desc_visible"] = desc_visible
	return data


func delete() -> void:
	clear_all_slots()
	queue_free()


func _arrange_go_to(graph_edit : GraphEdit, port_id := 0) -> Array:
	var to_nodes_pos_y := {}
	for connection in graph_edit.get_connection_list():
		if connection["from_node"] == self.name and connection["from_port"] == port_id:
			var to_node : GraphNode = graph_edit.get_node(NodePath(connection["to_node"]))
			to_nodes_pos_y[to_node.position_offset.y] = str(to_node.id)

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
		_description.text = short_title


func _on_GraphNode_resize_request(new_minsize):
	size = new_minsize


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && !event.is_echo():
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.is_pressed():
					rmb_pressed.emit()
			MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					_prev_pos_offset = position_offset
				else:
					if _prev_pos_offset.is_equal_approx(position_offset): return
					register_action()


func register_action():
	var new_data = gen_data(get_parent(), true)
	# NOTE: Если за раз было изменено несколько параметров, то это будет засчитано
	# как разные действия. Возможно, следует доработать логику, чтобы избежать этого 
	
	# _cached_data пустой в случае, если нода была только что создана, значит
	# производится первоначальная настройка
	if !_cached_data.is_empty():
		var offset_changed := false
		for param in new_data:
			if _cached_data[param] != new_data[param]:
				# TODO: Лютый костыль, чтобы при изменении offset_x или offset_y запоминать
				# значение сразу по двум осям.
				if &"offset" in (param as StringName):
					if !offset_changed:
						param_changed.emit(
							&"offset",
							Vector2(new_data[&"offset_x"], new_data[&"offset_y"]),
							Vector2(_cached_data[&"offset_x"], _cached_data[&"offset_y"])
						)
						offset_changed = true
				else:
					param_changed.emit(param, new_data[param], _cached_data[param])
					
	_cached_data = gen_data(get_parent(), true)
