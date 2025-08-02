class_name DUPA_Display
extends MarginContainer

"""
Под каждого перса нужно создавать папку
char_name
	|
	voicelines
	|
	speaker_name_lines.csv
	|
	speaker_data.tres

"""

signal dialog_started
signal dialog_ended
signal line_tags_detected(tags: PackedStringArray)

signal action_set(var_name: StringName, value: Variant)
signal action_call(func_name: StringName, arg: Variant)
signal action_message(msg_name: StringName, value: Variant)

signal get_bool(bool_var_name: StringName, return_to: Callable)

enum Tag {EMOTE}

enum OnDialogFinished {
	DO_NOTHING,
	HIDE,
	HIDE_IF_NOT_DEBUG,
	DELETE,
	DELETE_IF_NOT_DEBUG,
}

var _blueprint_config: Dictionary

var _dialog_data: Array[DUPA_Lib.DN_Base]
var _dialog_speakers: Array[DUPA_SpeakerData]
var _curr_dialog_node: DUPA_Lib.DN_Base
var _visible_characters_tween: Tween
var _is_dialog_ended := false

# TODO: Каждый персонаж может иметь свой путь к репликам?
@export_category("Main")
#@export var blueprint: DUPA_Blueprint
@export_file var blueprint_file: String
#@export var game_logic_interactor_script: Script
@export var on_dialog_finished := OnDialogFinished.DO_NOTHING
@export var clear_speaker_panel_on_proceeding := true
## Controls the speed at which line is printing.[br]
## If 0, then line prints instantly.
@export_range(0, 1000, 1, "suffix:chars/s") var line_showing_speed := 60.
## If [b]true[/b], the choice buttons will be showed [b]immediately[/b] after the previous node was fully processed, while [b]keeping line panel VISIBLE[/b].[br]
## If [b]false[/b], the choice buttons will be shown only [b]after user forced dialog processing[/b] (pressed LMB and etc.). [b]The dialog panel will be HIDDEN[/b] while choices are on the screen.
@export var auto_show_choices := true
## Should the choosen line be printed in the dialog box after it was selected
@export var print_player_line_after_choice := false

@export_category("Printing")
@export_range(0., 2.0, 0.01) var end_sentence_pause_length := 0.08
@export_range(0., 2.0, 0.01) var comma_pause_length := 0.04

@export_category("Debug")
@export var debug_mode := false
@export var ignore_no_localization := true
@export var ignore_no_speaker_data := true
@export var speaker_placeholder_name := "[b][i]Character name[/i][/b]"

# TODO: Динамически подбирать размер кнопок выбора реплики в зависимости от их количества
@export_category("Node references")
@export var localization_master: DUPA_LocalizationMaster
@export var dialog_panel: PanelContainer
@export var speaker_name: RichTextLabel ## The RichTextLabel that displays the speaker's name.
@export var speaker_line: RichTextLabel ## The RichTextLable that displays the line.
@export var choices_controller: Control



func _ready() -> void:
	reset_all()
	#if game_logic_interactor_script:
		#_set_game_logic_interactor_script()
	#else:
		#DUPA_Logger.add_msg("The Game Logic Interactor script was not set. Ignore, if it's intended.")
	%RestartDebug.visible = debug_mode
	%LabelDebug.visible = debug_mode
	if debug_mode:
		start_dialog()
	
	choices_controller.localization_master = localization_master
	choices_controller.choice_made.connect(_on_choices_controller_choice_made)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dupa_proceed"):
		# TODO: Не переходить далее, если в процессе показа текста
		if !_is_dialog_ended && _curr_dialog_node is DUPA_Lib.DN_LineBase:
			if _is_printing_line():
				_visible_characters_tween.kill()
				speaker_line.visible_ratio = 1.0
			elif !choices_controller.is_showing_choices():
				_check_next_step(_curr_dialog_node.go_to)


func get_is_dialog_ended() -> bool:
	return _is_dialog_ended


func start_dialog(blueprint_file := blueprint_file) -> void:
	reset_all()
	# TODO: На основе словаря создавать массив объектов, объявленных ниже в этом скрипте.
	# Помни, что сначала надо перенести весь имеющийся функционал, а потом уже выпендриваться.
	assert(
		!blueprint_file.is_empty() && FileAccess.file_exists(blueprint_file),
		"Can't find blueprint at " + blueprint_file
	)
	var file := FileAccess.open(blueprint_file, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	var json_as_dict := json.get_data()
	_blueprint_config = json_as_dict[&"CONFIG"]
	var blueprint_data = json_as_dict[&"TIMELINE"]
	file.close()
	
	# TODO: Заменить строки на числа там, где это возможно.
	# Например, в node id и в node_type
	var start_node := &"0"
	#_curr_node_id = start_node
	assert(
		int(blueprint_data[start_node][&"type"]) == DUPA_Lib.NodeType.START,
		"Node with id == 0 should be only the Start node! Can't proceed."
	)
	assert(
		blueprint_data[start_node].has(&"source"),
		"The blueprint does not have a start node!"
	)
	var speakers_paths = _blueprint_config[&"speakers"]
	var speakers_data := DUPA_Utils.load_speakers_data_from_config(speakers_paths)
	for speaker in speakers_data:
		localization_master.create_speaker_localization(speaker)
		_dialog_speakers.append(speaker)
		
	_dialog_data = _construct_dialog_data(blueprint_data)
	# The start node is always expected to be first because of id == 0
	_curr_dialog_node = _dialog_data[0]
	_check_next_step(_curr_dialog_node.go_to)
	dialog_started.emit()


func stop_dialog(action_on_finished := on_dialog_finished) -> void:
	speaker_line.text = ""
	speaker_name.text = ""
	dialog_ended.emit()
	_is_dialog_ended = true
	DUPA_Logger.add_msg("Dialog ended!")
	if action_on_finished == OnDialogFinished.DELETE || action_on_finished == OnDialogFinished.DELETE_IF_NOT_DEBUG && !debug_mode:
		queue_free()
	elif action_on_finished == OnDialogFinished.HIDE || action_on_finished == OnDialogFinished.HIDE_IF_NOT_DEBUG && !debug_mode:
		hide()


func reset_all() -> void:
	dialog_panel.hide()
	_is_dialog_ended = false
	_dialog_data.clear()
	_curr_dialog_node = null
	if _visible_characters_tween:
		_visible_characters_tween.kill()
	_blueprint_config.clear()
	choices_controller.clear()
	speaker_line.text = ""
	speaker_name.text = ""


func _is_printing_line() -> bool:
	return _visible_characters_tween && _visible_characters_tween.is_running()


func _construct_dialog_data(blueprint_data: Dictionary) -> Array[DUPA_Lib.DN_Base]:
	var dialog_data: Dictionary[StringName, DUPA_Lib.DN_Base] = {}
	var connections: Dictionary[StringName, Dictionary]= {}
	# bn - blueprint_node
	for id in blueprint_data:
		var blueprint_node_data = blueprint_data[id]
		var dialog_node: DUPA_Lib.DN_Base
		connections[id] = {}
		blueprint_node_data["id"] = int(id)
		match int(blueprint_node_data.type):
			DUPA_Lib.NodeType.START:
				dialog_node = DUPA_Lib.DN_Start.new(blueprint_node_data)
			DUPA_Lib.NodeType.LINE:
				if blueprint_node_data.get(&"is_choice"):
					dialog_node = DUPA_Lib.DN_LineChoice.new(blueprint_node_data)
				else:
					dialog_node = DUPA_Lib.DN_Line.new(blueprint_node_data)
				dialog_node.speaker = _dialog_speakers[blueprint_node_data.speaker_idx]
			DUPA_Lib.NodeType.DYNAMIC_ID_LINE: # TODO: Заменить DYNAMIC_LINE на DYNAMIC_ID_LINE
				dialog_node = DUPA_Lib.DN_DynamicIdLine.new(blueprint_node_data)
			DUPA_Lib.NodeType.CONDITION:
				dialog_node = DUPA_Lib.DN_Condition.new(blueprint_node_data)
				connections[id][DUPA_Lib.OUTPUT_FALSE_PORT] = PackedInt32Array(blueprint_node_data.go_to_false)
			DUPA_Lib.NodeType.ACTION:
				dialog_node = DUPA_Lib.DN_Action.new(blueprint_node_data)
			_:
				assert(false, "Unknown graph node type: %s" % int(blueprint_node_data.type))
		dialog_data[id] = dialog_node
		connections[id][DUPA_Lib.OUTPUT_PORT] = PackedInt32Array(blueprint_node_data.go_to)
	
	# Fills the go_to fields with references to other dialog nodes
	for id in dialog_data:
		var dialog_node = dialog_data[id]
		for go_to_id in connections[id][DUPA_Lib.OUTPUT_PORT]:
			dialog_node.go_to.append(dialog_data[str(go_to_id)])
		if connections[id].has(DUPA_Lib.OUTPUT_FALSE_PORT):
			for go_to_id in connections[id][DUPA_Lib.OUTPUT_FALSE_PORT]:
				dialog_node.go_to_false.append(dialog_data[str(go_to_id)])
	
	return dialog_data.values()


func _check_next_step(go_to_nodes: Array[DUPA_Lib.DN_Base]) -> void:
	if _curr_dialog_node is DUPA_Lib.DN_DynamicIdLine:
		if _curr_dialog_node.are_lines_left():
			_show_line(_curr_dialog_node)
			return
			
	#var go_to_nodes: Array[DUPA_Lib.DN_Base] = _curr_dialog_node.go_to
	if go_to_nodes.size() == 0:
		call_deferred("stop_dialog", on_dialog_finished)
		return

	if go_to_nodes.size() == 1:
		_go_to_node(go_to_nodes[0])
		return
	elif !(_curr_dialog_node is DUPA_Lib.DN_Condition):
		_show_choices(go_to_nodes)
		return


func _go_to_node(dialog_node: DUPA_Lib.DN_Base) -> void:
	_curr_dialog_node = dialog_node
	var go_to_nodes: Array[DUPA_Lib.DN_Base] = _curr_dialog_node.go_to
	var nd := DUPA_Lib.NodeType
	var instant_proceed := true
	#_show_line(null)
	DUPA_Logger.add_msg("Processing the %s node (ID: %s)..." % [
		DUPA_Lib.NODE_NAMES[dialog_node.type], dialog_node.id
	])
	match _curr_dialog_node.type:
		nd.LINE, nd.DYNAMIC_ID_LINE:
			_show_line(_curr_dialog_node)
			instant_proceed = false
		nd.ACTION:
			var dna = _curr_dialog_node as DUPA_Lib.DN_Action
			var at = DUPA_GraphNodeAction.ActionType
			var target_signal: Signal
			match dna.action_type:
				at.CALL:
					target_signal = action_call
				at.SET:
					target_signal = action_set
				at.MESSAGE:
					target_signal = action_message
			target_signal.emit(dna.arg_name, dna.arg_value)
			if target_signal.get_connections().size() == 0:
				assert(false, "The signal '%s' has no connections!" % target_signal)
		nd.CONDITION:
			var go_to_false_nodes: Array[DUPA_Lib.DN_Base] = _curr_dialog_node.go_to_false
			if go_to_nodes.size() < 1 && go_to_false_nodes.size() < 1:
				push_error(false, "Condition node hasn't any attached output!")
				return
			instant_proceed = false
			var var_name: StringName = _curr_dialog_node.var_name
			get_bool.emit(var_name, _condition_return)
			if get_bool.get_connections().size() == 0:
				assert(false, "The signal 'get_bool' has no connections! The condition can't be resolved!")
	
	# Immediatly proceed dialog, if current node is not line/dynamic id line
	if instant_proceed:
		_check_next_step(_curr_dialog_node.go_to)
	#push_error("For some reason DUPA couldn't handle node of a type '%s'..." % _curr_dialog_node.type)


func _condition_return(value: bool) -> void:
	if value == null:
		DUPA_Logger.add_warning("Condition variable is null!", DUPA_Logger.MsgVisibility.ESSENTIAL)
	var next_dialog_nodes: Array[DUPA_Lib.DN_Base]
	if value:
		next_dialog_nodes = _curr_dialog_node.go_to
	else:
		next_dialog_nodes = _curr_dialog_node.go_to_false
	_check_next_step(next_dialog_nodes)


func _show_line(dialog_node: DUPA_Lib.DN_LineBase):
	dialog_panel.show()
	assert(dialog_node, "Dialog node data is null!")
	var line_text := ""
	# NOTE: Реплика хранится внутри ноды только в случае DN_LineChoice!
	# Assuming that .line_full and line_choice variables was assigned before
	if dialog_node is DUPA_Lib.DN_LineChoice:
		line_text = dialog_node.line_full
		if line_text.is_empty():
			line_text = dialog_node.line_choice
		DUPA_Logger.add_msg("Printing the choice.")
	elif dialog_node is DUPA_Lib.DN_Line:
		var line_id = _curr_dialog_node.get_line_id()
		DUPA_Logger.add_msg("Printing the line: '%s'." % [line_id])
		var speaker = dialog_node.speaker
		var speaker_localization = localization_master.speakers_localization[speaker]
		assert(
			speaker_localization.has(line_id),
			"Blueprint node ID: %s.\nLine '%s' was not found at speaker localization." % [dialog_node.id, line_id]
		)
		line_text = speaker_localization[line_id][&"line"]
	elif dialog_node is DUPA_Lib.DN_DynamicIdLine:
		pass
		
	speaker_line.text = line_text
	
	if line_showing_speed > 0:
		speaker_line.visible_characters = 0
		var parsed_text_length: int = speaker_line.get_parsed_text().length()
		var time := float(parsed_text_length) / line_showing_speed
		#_prev_char_sound_time = 0
		_visible_characters_tween = create_tween().set_parallel(true)
		_visible_characters_tween.finished.connect(_on_all_line_characters_shown)
		_visible_characters_tween.tween_method(_change_visible_characters, 0, parsed_text_length, time)
	else:
		speaker_line.visible_ratio = 1.
		call_deferred("_on_all_line_characters_shown")
		
	var speaker: DUPA_SpeakerData = (_curr_dialog_node as DUPA_Lib.DN_LineBase).speaker
	if !speaker:
		if !ignore_no_speaker_data:
			push_error("No speaker data was found for the node (ID: %s)." % _curr_dialog_node.id)
		speaker_name.text = speaker_placeholder_name
	else:
		var sp_name_data: Dictionary = localization_master.speakers_localization[speaker].get(&"name", {})
		if sp_name_data.is_empty():
			push_error("The ID 'name' was not found in localization! Can't define the speaker's name.")
			speaker_name.text = speaker_placeholder_name
		else:
			speaker_name.text = sp_name_data[&"line"]
	if localization_master.speakers_localization.has(speaker):
		#var speaker = _curr_dialog_node.character
		pass
	elif !ignore_no_localization:
		pass
	#if !_is_player_speaking:
		#_visible_characters_tween.tween_method(_play_char_showing_sound, 0.0, time, time)


func _show_choices(dialog_nodes: Array[DUPA_Lib.DN_Base]) -> void:
	dialog_panel.visible = auto_show_choices
	for dialog_node in dialog_nodes:
		assert(
			dialog_node is DUPA_Lib.DN_LineBase,
			"The dialog node (ID: %s) assigned as a choice node, which is forbidden. Probably there is a problem in the blueprint." % dialog_node.id
		)
		var speaker = dialog_node.speaker
		var line_id = dialog_node.get_line_id()
		# TODO: Дублирует аналогичный код в show_choices(), мб заменить общей функцией?
		var speaker_localization = localization_master.speakers_localization[speaker]
		assert(
			speaker_localization.has(line_id),
			"Blueprint node ID: %s.\nLine '%s' was not found at speaker localization." % [dialog_node.id, line_id]
		)
		var line = speaker_localization[line_id][&"line"]
		dialog_node.line_full = line
	choices_controller.show_choices(dialog_nodes)


func _change_visible_characters(value : int) -> void:
	speaker_line.visible_characters = value
	if comma_pause_length == 0 && end_sentence_pause_length == 0: return
	
	var parsed_text: String = speaker_line.get_parsed_text()
	if value > 0 && value < parsed_text.length() && parsed_text[value] == ' ':
		var time := -1.
		match parsed_text[value - 1]:
			",":
				time = comma_pause_length
			"…", ".", "!", "?":
				time = end_sentence_pause_length
		if time > 0:
			_visible_characters_tween.pause()
			await get_tree().create_timer(time).timeout
			_visible_characters_tween.play()


func _on_choices_controller_choice_made(dialog_node: DUPA_Lib.DN_LineChoice) -> void:
	if print_player_line_after_choice:
		_go_to_node(dialog_node)
	else:
		_check_next_step(dialog_node.go_to)


func _on_all_line_characters_shown() -> void:
	# If can automatically show choices 
	if !(_curr_dialog_node is DUPA_Lib.DN_Condition) && _curr_dialog_node.go_to.size() > 1 && auto_show_choices:
		_show_choices(_curr_dialog_node.go_to)


func _on_restart_debug_pressed() -> void:
	start_dialog()
