class_name DUPA_GameLogicInteractor
extends Node

signal dialog_ended
signal change_background

var dialog_viewer: DUPA_Display


func connect_dialog_viewer_signals(dialog_viewer: DUPA_Display) -> void:
	self.dialog_viewer = dialog_viewer
	dialog_viewer.get_bool.connect(on_get_bool)
	dialog_viewer.action_message.connect(on_action_message)
	dialog_viewer.action_set.connect(on_action_set)
	dialog_viewer.action_call.connect(on_action_call)
	dialog_viewer.dialog_ended.connect(on_dialog_ended)
	dialog_viewer.dialog_started.connect(on_dialog_started)


func on_get_bool(bool_var_name: StringName, return_to: Callable) -> void:
	pass


func on_action_message(msg_name: StringName, value: Variant) -> void:
	pass


func on_action_set(var_name: StringName, value: Variant) -> void:
	pass


func on_action_call(func_name: StringName, arg: Variant = null) -> void:
	if has_method(func_name):
		if arg:
			call(func_name, arg)
		else:
			call(func_name)


func on_dialog_ended() -> void:
	pass


func on_dialog_started() -> void:
	pass
