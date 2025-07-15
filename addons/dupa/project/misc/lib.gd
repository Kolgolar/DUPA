class_name DUPA_Lib
extends Node

# WARNING: If you want to delete/change a node type, do not use the same value,
# always increment it, so you don't break compatibility with previous versions of DUPA.
enum NodeType {
	BASE = 0,
	START = 1,
	LINE = 2,
	DYNAMIC_ID_LINE = 3,
	SETTER = 4,
	CALLER = 5,
	CONDITION = 6,
}

const INPUT_PORT := 0
const OUTPUT_PORT := 0
#const OUTPUT_TRUE_PORT := 0
const OUTPUT_FALSE_PORT := 1

const NODE_NAMES := {
	NodeType.BASE: &"Base",
	NodeType.START: &"Start",
	NodeType.LINE: &"Line",
	NodeType.DYNAMIC_ID_LINE: &"Dynamic ID Line",
	NodeType.SETTER: &"Setter",
	NodeType.CALLER: &"Caller",
	NodeType.CONDITION: &"Condition",
}

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
	#var tags: PackedStringArray
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
			DUPA_Logger.add_err("No lines left to show with DynamicIDLine!")
			return ""
		var full_id: String = base + str(count)
		count += 1
		return full_id
	
	
	func foo():
		pass
		# TODO: Всякий индивидуальный функционал нод, типа получения по порядку реплик
		# из 


class DN_LineChoice:
	extends DN_Line
	var line_choice := ""
	var line_full := ""
