extends PopupMenu


func _ready() -> void:
	pass


func disable_start_node(disabled: bool):
	set_item_disabled(0, disabled)
