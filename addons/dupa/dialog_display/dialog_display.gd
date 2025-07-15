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
signal action_condition(bool_var_name: StringName, return_to: Callable)
signal action_msg(msg: StringName, value: Variant)


enum Tag {EMOTE}
enum PlayerChoiceLinePreviewMode {
	DISABLED, ## Full player lines should be displayed on choice buttons.[br]
	SHOW_ON_HOVER, ## The choice buttons should contain the brief of the choice lines, while the full line will be displayed in the separate panel if a mouse cursor is hovering the choice button.[br]
	SHOW_ON_PRESS ## The same as the previous, but the full choice line will be displayed on PRESSING the choice button.[br]
}
enum OnDialogFinished {
	DO_NOTHING,
	HIDE,
	HIDE_IF_NOT_DEBUG,
	DELETE,
	DELETE_IF_NOT_DEBUG,
}

var _blueprint_config: Dictionary
var _csv_data: Dictionary

var _dialog_data: Array[DN_Base]
var _curr_dialog_node: DN_Base

var _visible_characters_tween: Tween

# TODO: Каждый персонаж может иметь свой путь к репликам?
@export_category("Main")
#@export var blueprint: DUPA_Blueprint
@export_file var blueprint_file: String
@export var game_logic_interactor_script: Script
@export var on_dialog_finished := OnDialogFinished.DO_NOTHING
@export var clear_speaker_panel_on_proceeding := true
@export_range(1, 1000, 1, "suffix:chars/s") var line_showing_speed := 30.

@export_category("Choices")
@export var player_choice_line_preview_mode: PlayerChoiceLinePreviewMode = PlayerChoiceLinePreviewMode.SHOW_ON_HOVER
## Should the choosen line be printed in the dialog box after it was selected
@export var print_player_line_after_choice := false

@export_category("Debug")
@export var debug_mode := false
@export var ignore_no_localization := true
@export var ignore_no_speaker_data := true
@export var speaker_placeholder_name := "[b][i]Character name[/i][/b]"

# TODO: Динамически подбирать размер кнопок выбора реплики в зависимости от их количества
@export_category("Node references")
#@export var text_panel: Control ## The node that holds the line and the speaker's name 
@export var speaker_name: RichTextLabel ## The RichTextLabel that displays the speaker's name.
@export var speaker_line: RichTextLabel ## The RichTextLable that displays the line.
@export var choices_container: Control ## The node that should hold the choice buttons.
@export var choice_full_line: Control
@export var dialog_choice_button: PackedScene

#@export_category("Other")



func _ready() -> void:
	if game_logic_interactor_script:
		_set_game_logic_interactor_script()
	else:
		DUPA_Logger.add_msg("The Game Logic Interactor script was not set. Ignore, if it's intended.")
	%ChoicesContainer.set_mode(player_choice_line_preview_mode)
	if debug_mode:
		start_dialog()
	
	#_remove_all_choices()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dupa_proceed"):
		# TODO: Не переходить далее, если в процессе показа текста
		if _curr_dialog_node is DN_LineBase:
			if _is_printing_line():
				_visible_characters_tween.kill()
				speaker_line.visible_ratio = 1.0
			else:
				_proceed_dialog(_curr_dialog_node.go_to)


func start_dialog(blueprint_file := blueprint_file) -> void:
	# TODO: На основе словаря создавать массив объектов, объявленных ниже в этом скрипте.
	# Помни, что сначала надо перенести весь имеющийся функционал, а потом уже выпендриваться.
	
	if blueprint_file.is_empty() || !FileAccess.file_exists(blueprint_file):
		DUPA_Logger.add_error("Can't find blueprint at " + blueprint_file)
		return
		
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
	
	if int(blueprint_data[start_node][&"type"]) != DUPA_Lib.NodeType.START:
		DUPA_Logger.add_error("Node with id == 0 should be only the Start node! Can't proceed.")
		return
	if !blueprint_data[start_node].has(&"source"):
		DUPA_Logger.add_error("The blueprint does not have a start node!")
		return
	
	_dialog_data = _construct_dialog_data(blueprint_data)
	# The start node is always expected to be first because of id == 0
	_curr_dialog_node = _dialog_data[0]
	
	# TODO: Избавиться от одного _csv_data, вместо этого открывать файлы
	# с репликами персонажей, участвующих в диалоге
	_csv_data = DUPA_Utils.read_csv_file(blueprint_data[start_node][&"source"])
	_proceed_dialog(_curr_dialog_node.go_to)
	
	dialog_started.emit()


func _is_printing_line() -> bool:
	return _visible_characters_tween.is_valid() && _visible_characters_tween.is_running()


func _construct_dialog_data(blueprint_data: Dictionary) -> Array[DN_Base]:
	var dialog_data: Dictionary[StringName, DN_Base] = {}
	var connections: Dictionary[StringName, Dictionary]= {}
	# bn - blueprint_node
	for id in blueprint_data:
		var blueprint_node_data = blueprint_data[id]
		var dialog_node: DN_Base
		connections[id] = {}
		blueprint_node_data["id"] = int(id)
		match int(blueprint_node_data.type):
			DUPA_Lib.NodeType.START:
				dialog_node = DN_Start.new(blueprint_node_data)
			DUPA_Lib.NodeType.LINE:
				dialog_node = DN_Line.new(blueprint_node_data)
			DUPA_Lib.NodeType.DYNAMIC_ID_LINE: # TODO: Заменить DYNAMIC_LINE на DYNAMIC_ID_LINE
				dialog_node = DN_DynamicIdLine.new(blueprint_node_data)
			DUPA_Lib.NodeType.SETTER:
				dialog_node = DN_Setter.new(blueprint_node_data)
			DUPA_Lib.NodeType.CALLER:
				dialog_node = DN_Caller.new(blueprint_node_data)
			DUPA_Lib.NodeType.CONDITION:
				dialog_node = DN_Condition.new(blueprint_node_data)
				connections[id][DUPA_Lib.OUTPUT_FALSE_PORT] = PackedInt32Array(blueprint_node_data.go_to_false)
			
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


func stop_dialog(action_on_finished := on_dialog_finished) -> void:
	dialog_ended.emit()
	DUPA_Logger.add_msg("Dialog ended!")
	if action_on_finished == OnDialogFinished.DELETE || action_on_finished == OnDialogFinished.DELETE_IF_NOT_DEBUG && !debug_mode:
		queue_free()
	elif action_on_finished == OnDialogFinished.HIDE || action_on_finished == OnDialogFinished.HIDE_IF_NOT_DEBUG && !debug_mode:
		hide()


func _set_game_logic_interactor_script() -> void:
	var base_script := game_logic_interactor_script.get_base_script()
	if base_script:
		if base_script.get_global_name() == &"DUPA_GameLogicInteractor":
			%GameLogicInteractor.set_script(game_logic_interactor_script)
			return
	DUPA_Logger.add_error("Can't assign to the Game Logic Interactor script that does not inherits [b]DUPA_GameLogicInteractor[/b] class!")


func _proceed_dialog(go_to_nodes: Array[DN_Base]) -> void:
	if _curr_dialog_node is DN_DynamicIdLine:
		if _curr_dialog_node.are_lines_left():
			_show_line(_curr_dialog_node)
			return
			
	#var go_to_nodes: Array[DN_Base] = _curr_dialog_node.go_to
	if go_to_nodes.size() == 0:
		call_deferred("stop_dialog", on_dialog_finished)
		return

	if go_to_nodes.size() == 1:
		_go_to_node(go_to_nodes[0])
		return
	elif !(_curr_dialog_node is DN_Condition):
		_show_choices(go_to_nodes)
		return


func _go_to_node(dialog_node: DN_Base) -> void:
	_curr_dialog_node = dialog_node
	var go_to_nodes: Array[DN_Base] = _curr_dialog_node.go_to
	var nd := DUPA_Lib.NodeType
	var instant_proceed := true
	_show_line(null)
	DUPA_Logger.add_msg("Processing the %s node (ID: %s)..." % [
		DUPA_Lib.NODE_NAMES[dialog_node.type], dialog_node.id
	])
	match _curr_dialog_node.type:
		nd.LINE || nd.DYNAMIC_ID_LINE:
			_show_line(_curr_dialog_node)
			instant_proceed = false
		nd.SETTER:
			var cdn := (_curr_dialog_node as DN_Setter)
			var var_name: StringName = cdn.var_name
			var value_str: String = cdn.var_value
			var value_typed := DUPA_Utils.convert_to_determined_type(value_str)
			action_set.emit(var_name, value_typed)
			if action_set.get_connections().size() == 0:
				DUPA_Logger.add_error("The signal 'action_set' has no connections!")
		nd.CALLER:
			var cdn := (_curr_dialog_node as DN_Caller)
			var func_name: StringName = _curr_dialog_node.var_name
			var args_str: String = _curr_dialog_node.var_value
			var args_typed := []
			if !args_str.is_empty():
				for arg in args_str.split(",", false):
					args_typed.append(DUPA_Utils.convert_to_determined_type(arg))
			action_call.emit(func_name, args_typed)
			if action_call.get_connections().size() == 0:
				DUPA_Logger.add_error("The signal 'action_call' has no connections!")
		nd.CONDITION:
			var go_to_false_nodes: Array[DN_Base] = _curr_dialog_node.go_to_false
			if go_to_nodes.size() < 1 && go_to_false_nodes.size() < 1:
				DUPA_Logger.add_error("Condition node hasn't any attached output!")
				return
			instant_proceed = false
			var var_name: StringName = _curr_dialog_node.var_name
			action_condition.emit(var_name, _condition_return)
			if action_condition.get_connections().size() == 0:
				DUPA_Logger.add_error("The signal 'action_condition' has no connections!")

	# Immediatly proceed dialog, if current node is not line/dynamic id line
	if instant_proceed:
		_proceed_dialog(_curr_dialog_node.go_to)
	
	
	#DUPA_Logger.add_error("For some reason DUPA couldn't handle node of a type '%s'..." % _curr_dialog_node.type)

func _condition_return(value: bool) -> void:
	if value == null:
		DUPA_Logger.add_warning("Condition variable is null!", DUPA_Logger.MsgVisibility.ESSENTIAL)
	var next_dialog_nodes: Array[DN_Base]
	if value:
		next_dialog_nodes = _curr_dialog_node.go_to
	else:
		next_dialog_nodes = _curr_dialog_node.go_to_false
	_proceed_dialog(next_dialog_nodes)


func _show_line(dialog_node: DN_LineBase):
	if !dialog_node:
		if clear_speaker_panel_on_proceeding:
			speaker_line.text = ""
			speaker_name.text = ""
		return
	var line_id = _curr_dialog_node.get_line_id()
	DUPA_Logger.add_msg("Printing the line: '%s'." % [line_id])
	speaker_line.text = line_id
	speaker_line.visible_characters = 0
	var parsed_text_length: int = speaker_line.get_parsed_text().length()
	var time := float(parsed_text_length) / line_showing_speed
	#_prev_char_sound_time = 0
	_visible_characters_tween = create_tween().set_parallel(true)
	_visible_characters_tween.finished.connect(_on_text_showing_tween_finished)
	_visible_characters_tween.tween_method(_change_visible_characters, 0, parsed_text_length, time)
	
	var speaker: DUPA_SpeakerData = (_curr_dialog_node as DN_LineBase).speaker
	if !speaker:
		if !ignore_no_speaker_data:
			DUPA_Logger.add_error("No speaker data was found for the node (ID: %s)." % _curr_dialog_node.id)
		speaker_name.text = speaker_placeholder_name
		return
	if speaker.localization_file:
		#var speaker = _curr_dialog_node.character
		pass
	elif !ignore_no_localization:
		DUPA_Logger.add_error("No localization file was found for speaker '%s'." % speaker.id_name)
	#if !_is_player_speaking:
		#_visible_characters_tween.tween_method(_play_char_showing_sound, 0.0, time, time)


func _remove_all_choices() -> void:
	for b in choices_container.get_children():
		queue_free()


func _show_choices(dialog_nodes: Array[DN_Base]) -> void:
	DUPA_Logger.add_msg("Showing choices.")
	_remove_all_choices()
	for n in dialog_nodes:
		var dn := n as DN_Line 
		var line_id: StringName = dn.line_id
		var line_text := get_line_localized_text(line_id, null)
		var regex = RegEx.new()
		regex.compile("(?<=^\\[choice:).*(?=\\])")
		var result := regex.search(line_text)
		var shorted_line_text := ""
		if result:
			shorted_line_text = result.get_string().strip_edges()
			#if shorted_line_text.is_empty():
				#DUPA_Logger.add_error("The result button text is empty!")
			regex.compile("(?<=\\]).*")
			var only_text = regex.search(line_text)
			if only_text:
				line_text = only_text.get_string().strip_edges()
				#if line_text.is_empty():
					#DUPA_Logger.add_error("The result line text is empty!")
		
		if shorted_line_text.is_empty():
			#DUPA_Logger.add_error("The result button text is empty!")
			#if !line_text.is_empty():
			shorted_line_text = line_text
			line_text = ""
		
		var button: Button = dialog_choice_button.instantiate()
		#if !(button is Button):
			#DUPA_Logger.add_error("Check if 'dialog_choice_button' is a Button node.")
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if player_choice_line_preview_mode == PlayerChoiceLinePreviewMode.DISABLED && !line_text.is_empty():
			button.text = line_text
		else:
			button.text = shorted_line_text
		choices_container.add_child(button)
		match player_choice_line_preview_mode:
			PlayerChoiceLinePreviewMode.DISABLED:
				button.toggle_mode = false
				button.pressed.connect(_on_choice_button_pressed.bind(dn, button))
			PlayerChoiceLinePreviewMode.SHOW_ON_HOVER:
				button.toggle_mode = false
				button.pressed.connect(_on_choice_button_pressed.bind(dn, button))
				button.mouse_entered.connect(_on_choice_button_mouse_entered.bind(dn, button))
				button.mouse_exited.connect(_on_choice_button_mouse_exited.bind(dn, button))
			PlayerChoiceLinePreviewMode.SHOW_ON_PRESS:
				button.toggle_mode = true
				button.toggled.connect(_on_choice_button_toggled.bind(dn, button))
				

func _on_choice_full_line_pressed() -> void:
	pass # Replace with function body.


func _on_choice_button_toggled(button_toggled: bool, dialog_node: DN_LineBase, button: Button) -> void:
	pass


func _on_choice_button_mouse_entered(dialog_node: DN_LineBase, button: Button) -> void:
	choice_full_line.show()


func _on_choice_button_mouse_exited(dialog_node: DN_LineBase, button: Button) -> void:
	choice_full_line.hide()


func _on_choice_button_pressed(dialog_node: DN_LineBase, button: Button) -> void:
	pass


func get_line_localized_text(line_id: StringName, speaker: DUPA_SpeakerData = null) -> String:
	var line_text := ""
	if !speaker:
		if _csv_data.has(line_id):
			line_text = _csv_data[line_id]
	else:
		# TODO: Some code here...
		pass
	return line_text


func _change_visible_characters(value : int) -> void:
	speaker_line.visible_characters = value
	var parsed_text: String = speaker_line.get_parsed_text()
	if value > 0 && value < parsed_text.length() && parsed_text[value] == ' ':
		var time := -1.
		match parsed_text[value - 1]:
			",":
				time = 0.04
			"…", ".", "!", "?":
				time = 0.08
		if time > 0:
			_visible_characters_tween.pause()
			await get_tree().create_timer(time).timeout
			_visible_characters_tween.play()


func _on_text_showing_tween_finished() -> void:
	pass



#class PrintingSoundsPlayer:
	#extends Node
	


class Blueprint:
	var config: Dictionary # TODO: Расширить до класса. Хранить ссылку на скрипт? 
	var nodes: Array[DN_Base]
	var speakers: Array[DUPA_SpeakerData]


# BN -- Blueprint Node
class DN_Base: # Abstract
	var id: int
	var type: DUPA_Lib.NodeType
	var go_to: Array[DN_Base]
	
	func _init(data: Dictionary) -> void:
		type = int(data.type)
		id = int(data.id)
		#go_to = data.go_to

# TODO: Скрыть приватные поля через _

class DN_Start:
	extends DN_Base
	var source: StringName
	
	func _init(data: Dictionary) -> void:
		super(data)
		source = data.source


class DN_Condition:
	extends DN_Base
	var var_name: StringName
	#var go_to_true: PackedStringArray # Вместо этого go_to
	var go_to_false: Array[DN_Base]
	
	func _init(data: Dictionary) -> void:
		super(data)
		var_name = data.var_name
		#go_to_false = data.go_to_false


class DN_Setter:
	extends DN_Base
	var var_name: StringName
	var var_value: String
	
	func _init(data: Dictionary) -> void:
		super(data)
		var_name = data.var_name
		var_value = data.var_value


class DN_Caller:
	extends DN_Setter


class DN_LineBase:
	extends DN_Base
	var speaker: DUPA_SpeakerData
	var tags: PackedStringArray
	var is_player: bool # FIXME: УБРАТЬ! Уже есть SpeakerData
	
	func _init(data: Dictionary) -> void:
		super(data)
		#character = data.character
		#tags = data.tags
		is_player = data.is_player
	
	func get_line_id() -> Variant:
		return null
	

class DN_Line:
	extends DN_LineBase
	var line_id: StringName
	
	func _init(data: Dictionary) -> void:
		super(data)
		line_id = data.line_id
	
	func get_line_id() -> Variant:
		return line_id
	
	func get_tags() -> PackedStringArray:
		return []
	
	func get_short_choice_text(line: String) -> String:
		return ""


class DN_DynamicIdLine:
	extends DN_LineBase
	var base: String
	var from: int
	var to: int
	var count: int
	
	func _init(data: Dictionary) -> void:
		super(data)
		base = data.base
		from = int(data.from)
		to = int(data.to)
		count = from
	
	
	func are_lines_left() -> bool:
		return count <= to
	
	
	func get_line_id() -> Variant:
		if !are_lines_left:
			DUPA_Logger.add_error("No lines left to show with DynamicIDLine!")
			return ""
		var full_id: String = base + str(count)
		count += 1
		return full_id
	
	
	func foo():
		pass
		# TODO: Всякий индивидуальный функционал нод, типа получения по порядку реплик
		# из 


#class LineChoice:
	#extends DN_Line
	#var choice_short: String
	#
	#func _init(data: Dictionary) -> void:
		#super(data)
		#choice_short = data.choice_short
