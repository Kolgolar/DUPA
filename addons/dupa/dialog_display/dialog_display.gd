class_name DUPA_Display
extends MarginContainer

"""
Под каждого перса нужно создавать папку
char_name
	|
	voicelines
	|
	char_name_lines.csv
	|
	character_data.tres

"""

signal dialog_started
signal dialog_ended
signal line_tags_detected(tags: PackedStringArray)

enum Tag {EMOTE}
enum PlayerChoiceLinePreviewMode {
	DISABLED, ## Full player lines should be displayed on choice buttons.[br]
	SHOW_ON_HOVER, ## The choice buttons should contain the brief of the choice lines, while the full line will be displayed in the separate panel if a mouse cursor is hovering the choice button.[br]
	SHOW_ON_PRESS ## The same as the previous, but the full choice line will be displayed on PRESSING the choice button.[br]
}

var _blueprint_config: Dictionary
var _blueprint_data: Dictionary
var _curr_node_id: StringName
var _csv_data: Dictionary

# TODO: Динамически подбирать размер кнопок выбора реплики в зависимости от их количества
@export_category("Display nodes")
#@export var text_panel: Control ## The node that holds the line and the speaker's name 
@export var character_name: RichTextLabel ## The RichTextLabel that displays the speaker's name.
@export var character_line: RichTextLabel ## The RichTextLable that displays the line.
@export var choices_container: Control ## The node that should hold the choice buttons.

@export_category("Choices")
@export var player_choice_line_preview_mode: PlayerChoiceLinePreviewMode = PlayerChoiceLinePreviewMode.SHOW_ON_HOVER
## Should the choosen line be printed in the dialog box after it was selected
@export var print_player_line_after_choice := false

# TODO: Каждый персонаж может иметь свой путь к репликам?
@export_category("Main")
#@export var blueprint: DUPA_Blueprint
@export_file var blueprint_file: String
@export var game_logic_interactor_script: Script
@export var test_mode := false
@export var delete_on_finished := true


func _ready() -> void:
	if game_logic_interactor_script:
		_set_game_logic_interactor_script()
	else:
		DUPA_Logger.add_msg("The Game Logic Interactor script was not set. Ignore, if it's intended.")
	%ChoicesContainer.set_mode(player_choice_line_preview_mode)
	if test_mode:
		start_dialog()


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
	_blueprint_data = json_as_dict[&"TIMELINE"]
	file.close()
	
	# TODO: Заменить строки на числа там, где это возможно.
	# Например, в node id и в node_type
	var start_node := &"0"
	_curr_node_id = start_node
	if _blueprint_data[start_node][&"type"] != &"START":
		DUPA_Logger.add_error("Node with id == 0 should be only the Start node! Can't proceed.")
		return
	
	if _blueprint_data[start_node].has(&"source"):
		# TODO: Избавиться от одного _csv_data, вместо этого открывать файлы
		# с репликами персонажей, участвующих в диалоге
		_csv_data = DUPA_Utils.read_csv_file(_blueprint_data[start_node][&"source"])
		_next_line()
	
	dialog_started.emit()


func stop_dialog(should_delete := true) -> void:
	dialog_ended.emit()
	if should_delete && !test_mode:
		queue_free()


func _set_game_logic_interactor_script() -> void:
	var base_script := game_logic_interactor_script.get_base_script()
	if base_script:
		if base_script.get_global_name() == &"DUPA_GameLogicInteractor":
			%GameLogicInteractor.set_script(game_logic_interactor_script)
			return
	DUPA_Logger.add_error("Can't assign to the Game Logic Interactor script that does not inherits [b]DUPA_GameLogicInteractor[/b] class!")


func _next_line() -> void:
	pass


func _get_go_to_nodes(node_name: StringName) -> void:
	#var go_to_arr: PackedStringArray = []
	#match _blueprint_data[node_name].type:
		#"CONDITION":
			#if _condition:
				#go_to_arr = _blueprint_data[node_name]["go_to_true"]
			#else:
				#go_to_arr = _blueprint_data[node_name]["go_to_false"]
		#_:
			#go_to_arr = _blueprint_data[node_name]["go_to"]
	#
	#return go_to_arr
	pass


class Blueprint:
	var config: Dictionary # TODO: Расширить до класса. Хранить ссылку на скрипт? 
	var nodes: Array[BN_Base]
	var characters: Array[DUPA_CharacterData]
	


# BN -- Blueprint Node
class BN_Base: # Abstract
	var go_to: PackedStringArray
	
	func _init(data: Dictionary) -> void:
		go_to = data.go_to

# TODO: Скрыть приватные поля через _

class BN_Start:
	extends BN_Base
	var source: StringName
	
	func _init(data: Dictionary) -> void:
		source = data.source


class BN_Condition:
	extends BN_Base
	var var_name: StringName
	#var go_to_true: PackedStringArray # Вместо этого go_to
	var go_to_false: PackedStringArray
	
	func _init(data: Dictionary) -> void:
		var_name = data.var_name
		go_to_false = data.go_to_false


class BN_Setter:
	extends BN_Base
	var var_name: StringName
	var var_value: String
	
	func _init(data: Dictionary) -> void:
		var_name = data.var_name
		var_value = data.var_value


class BN_Caller:
	extends BN_Setter


class BN_LineBase:
	extends BN_Base
	var character: DUPA_CharacterData
	var tags: PackedStringArray
	var is_player: bool # FIXME: УБРАТЬ! Уже есть CharacterData
	
	func _init(data: Dictionary) -> void:
		character = data.character
		tags = data.tags
		is_player = data.is_player
	

class BN_LineLite:
	extends BN_LineBase
	var line_text: String
	
	func _init(data: Dictionary) -> void:
		line_text = data.line_text


class BN_DynamicIdLine:
	extends BN_LineBase
	var base: StringName
	var from: StringName
	var to: StringName
	
	func _init(data: Dictionary) -> void:
		base = data.base
		from = data.from
		to = data.to
	
	func foo():
		pass
		# TODO: Всякий индивидуальный функционал нод, типа получения по порядку реплик
		# из 


class LineChoice:
	extends BN_LineLite
	var choice_short: String
	
	func _init(data: Dictionary) -> void:
		choice_short = data.choice_short
