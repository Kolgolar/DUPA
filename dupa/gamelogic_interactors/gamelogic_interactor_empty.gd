extends DUPA_GameLogicInteractor


func on_dialog_ended() -> void:
	dialog_ended.emit()
	

func play_sound(sound_name: String) -> void:
	var sound_file := ""
	match sound_name:
		"NewsBroad":
			sound_file = "res://game/assets/sounds/effects/novel/NewsBroad.wav"
		"MeatEnd":
			sound_file = "res://game/assets/sounds/effects/novel/MeatEnd.wav"
	SFX.play_file(sound_file)


func play_sound_seq(sound_name: String) -> void:
	pass


func ChangeBackEternal() -> void:
	get_parent().show_noise_eternal()
