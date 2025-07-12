extends VBoxContainer


func _ready() -> void:
	#_clear_choices()
	pass


func set_mode(mode: DUPA_Display.PlayerChoiceLinePreviewMode):
	var pm = DUPA_Display.PlayerChoiceLinePreviewMode
	match mode:
		pm.DISABLED:
			pass
		pm.SHOW_ON_HOVER:
			pass
		pm.SHOW_ON_PRESS:
			pass


func set_choices(choices: Array[DUPA_Display] = []):
	_clear_choices()
	for c in choices.size():
		pass


func _clear_choices():
	for b in get_children(): queue_free()
