class_name DUPA_SpeakerData
extends Resource

#enum VoicingType {
	#PRINTING, ## A lot of short sounds should be played while character speaks.
	#ACTING ## A single audio should be played when character says the line.
#}

@export var id_name := ""
#@export var voicelines_type := VoicingType.PRINTING
@export_dir var voicelines_folder
@export_dir var char_printing_sounds_folder
@export_file var localization_file
@export var name_color := Color.WHITE
