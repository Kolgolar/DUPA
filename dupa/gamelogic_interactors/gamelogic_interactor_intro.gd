extends DUPA_GameLogicInteractor

const HANDY_INTRODUCTION_SCN := preload("res://dupa/additional_scenes/handy_introduction.tscn")

var _handy_dialog_showed := false

@onready var parent := get_parent()

signal set_background(path: String)


func play_sound(sound_name: String) -> void:
	var sound_file := ""
	match sound_name:
		"NewsBroad":
			sound_file = "res://game/assets/sounds/effects/novel/NewsBroad.wav"
		
	SFX.play_file(sound_file)



func ChangeBack() -> void:
	get_parent().show_noise()
	get_parent().set_background(load("res://game/assets/backgrounds/background_intro.png"))


func on_dialog_started() -> void:
	dialog_viewer.on_dialog_finished = DUPA_Display.OnDialogFinished.HIDE


func on_dialog_ended() -> void:
	if !_handy_dialog_showed:
		_handy_dialog_showed = true
		var scn := HANDY_INTRODUCTION_SCN.instantiate()
		parent.add_child(scn)
		await scn.handy_showed
		dialog_viewer.start_dialog("res://dupa/scene_dialogues/scene_1.json")
	else:
		dialog_ended.emit()
	
