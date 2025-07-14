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

#const NODE_NAMES_TO_TYPES := {
	##&"Base": NodeType.BASE,
	#&"START": NodeType.START,
	#&"LINE": NodeType.LINE,
	#&"DYNAMIC_LINE": NodeType.DYNAMIC_ID_LINE,
	#&"SETTER": NodeType.SETTER,
	#&"CALLER": NodeType.CALLER,
	#&"CONDITION": NodeType.CONDITION
#}
