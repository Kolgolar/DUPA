extends Control

@onready var _dc = $DialogController

func _ready():
	_dc.start_dialog("res://game/dupa/intro/coach_loose.json")
