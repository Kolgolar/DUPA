extends ConfirmationDialog

signal save_dialog_as

func _on_ConfirmationDialog_confirmed():
	var file_name = $VBoxContainer/LineEdit.text
	if not file_name.empty():
		emit_signal("save_dialog_as", file_name)
