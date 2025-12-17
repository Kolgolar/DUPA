class_name DUPA_Lib
extends Node

# WARNING: If you want to delete/change a node type, do not use the same value,
# always increment it, so you don't break compatibility with previous versions of DUPA.
# TODO: Мб стоит обмозговать, как избежать этой проблемы?
enum NodeType {
	BASE = 0,
	START = 1,
	LINE = 2,
	DYNAMIC_ID_LINE = 3,
	CONDITION = 4,
	ACTION = 5,
}
static var graph_node_paths: Dictionary [NodeType, String] = {
		NodeType.LINE: "res://addons/dupa/editor/graph_nodes/node_line.tscn",
		NodeType.DYNAMIC_ID_LINE: "res://addons/dupa/editor/graph_nodes/node_dynamic_id_line.tscn",
		NodeType.CONDITION: "res://addons/dupa/editor/graph_nodes/node_condition.tscn",
		NodeType.START: "res://addons/dupa/editor/graph_nodes/node_start.tscn",
		NodeType.ACTION: "res://addons/dupa/editor/graph_nodes/node_action.tscn",
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
	NodeType.CONDITION: &"Condition",
	NodeType.ACTION: &"Action",
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
	#var tags: PackedStringArray
	
	func _init(data: Dictionary) -> void:
		type = int(data.type)
		id = int(data.id)
		#go_to = data.go_to TODO: Why??
		#tags = data.tags

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


class DN_Action:
	extends DN_Base
	var action_type: DUPA_GraphNodeAction.ActionType
	var arg_name: String
	var arg_value: Variant
	
	func _init(data: Dictionary) -> void:
		super(data)
		action_type = data.action_type
		arg_name = data.arg_name
		
		var arg_value_str = data.arg_value
		
		var args_typed := []
		if !arg_value_str.is_empty():
			for arg in arg_value_str.split(",", false):
				args_typed.append(DUPA_Utils.convert_to_determined_type(arg))
		if args_typed.size() == 0:
			arg_value = null # No args
		elif args_typed.size() == 1:
			arg_value = args_typed[0] # Signle value
		else:
			arg_value = args_typed # Array


class DN_LineBase:
	extends DN_Base
	
	func get_line_id() -> Variant:
		return null
	

class DN_Line:
	extends DN_LineBase
	var line_id: StringName
	var speaker: DUPA_SpeakerData
	
	func _init(data: Dictionary) -> void:
		super(data)
		line_id = data.get(&"line_id", "")
	
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
	var speakers: Array[DUPA_SpeakerData]
	var is_random := false
	
	func _init(data: Dictionary) -> void:
		super(data)
		base = data.base
		from = int(data.from)
		to = int(data.to)
		count = from
		is_random = data.is_random
	
	
	func are_lines_left() -> bool:
		return count <= to
	
	
	func get_line_id() -> Variant:
		if is_random:
			var rnd: int = randi_range(from, to)
			count = to + 1
			return base + str(rnd)
			
		if !are_lines_left:
			DUPA_Logger.add_err("No lines left to show with DynamicIDLine!")
			return ""
		var full_id: String = base + str(count)
		count += 1
		return full_id
	

class DN_LineChoice:
	extends DN_Line
	var line_choice := ""
	var line_full := ""
