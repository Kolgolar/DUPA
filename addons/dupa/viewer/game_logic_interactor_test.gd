extends DUPA_GameLogicInteractor



func _on_dialog_viewer_get_bool(bool_var_name: StringName, return_to: Callable) -> void:
	return_to.call(true)


func _on_dialog_viewer_action_message(msg_name: StringName, value: Variant) -> void:
	print(msg_name)
	print(value)


func _on_dialog_viewer_action_set(var_name: StringName, value: Variant) -> void:
	print(var_name)
	print(value)


func _on_dialog_viewer_action_call(func_name: StringName, arg: Variant) -> void:
	print(func_name)
	print(arg)
