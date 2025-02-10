extends ConfirmationDialog

signal save_dialog_as

func _on_confirmation_dialog_confirmed():
	var file_name = $VBoxContainer/LineEdit.text
	if not file_name.is_empty():
		emit_signal("save_dialog_as", file_name)
