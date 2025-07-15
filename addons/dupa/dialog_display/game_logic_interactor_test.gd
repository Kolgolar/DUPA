extends DUPA_GameLogicInteractor


func _on_dialog_display_action_condition(bool_var_name: StringName, return_to: Callable) -> void:
	return_to.call(true)
