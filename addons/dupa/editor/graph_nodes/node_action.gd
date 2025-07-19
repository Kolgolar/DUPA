class_name DUPA_GraphNodeAction
extends DUPA_GraphNodeBase

enum ActionType {
	CALL = 0,
	SET = 1,
	MESSAGE = 2,
}

var _action_fields_names := {
	ActionType.CALL: {
		&"name": "Func",
		&"value": "Arg",
		&"type": "Call",
	},
	ActionType.SET: {
		&"name": "Var",
		&"value": "Value",
		&"type": "Set"
	},
	ActionType.MESSAGE: {
		&"name": "Msg",
		&"value": "Value",
		&"type": "Message"
	},
}

@export var arg_name: LineEdit
@export var arg_value: LineEdit
@export var action_type: OptionButton



func _ready():
	super()
	type = DUPA_Lib.NodeType.ACTION
	for act in _action_fields_names:
		action_type.add_item(_action_fields_names[act].type, act)
	action_type.select(0)
	_action_type_changed(0)


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"arg_name":
			arg_name.text = value
		&"arg_value":
			arg_value.text = value
		&"action_type":
			action_type.selected = value
			_action_type_changed(value)


func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"arg_name"] = arg_name.text
	data[&"arg_value"] = arg_value.text
	data[&"action_type"] = action_type.selected
	return data


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([arg_name, arg_value, action_type])
	return fields


func _action_type_changed(value: ActionType) -> void:
	%NameLabel.text = _action_fields_names[value].name
	%ValueLabel.text = _action_fields_names[value].value


func _on_type_button_item_selected(index: int) -> void:
	_action_type_changed(index)
