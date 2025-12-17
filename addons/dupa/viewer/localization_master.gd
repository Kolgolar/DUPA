class_name DUPA_LocalizationMaster
extends Node

var speakers_localization: Dictionary[DUPA_SpeakerData, Dictionary] = {}
#var localization_heap: Dictionary[String, Dictionary]

@export var keep_cache_between_dialogs := true
# Reset on dialog restart/end? Or keep caching?


func create_speaker_localization(speaker: DUPA_SpeakerData, locale := "en"):
	if speakers_localization.has(speaker):
		DUPA_Logger.add_msg("A localization data of the %s character was already created." % speaker.id_name)
		return
	var file_path: String = speaker.localization_file
	if file_path.is_empty():
		push_error("No localization file was found for speaker '%s'." % speaker.id_name)
	var localization_data: Dictionary[String, Dictionary] =\
		DUPA_Utils.read_localization_csv_file(file_path, TranslationServer.get_locale())
	if localization_data.is_empty():
		push_error("No localization data was found at file '%s" % file_path)
	
	speakers_localization[speaker] = localization_data
	DUPA_Logger.add_msg("Adding the localization data of the %s character" % speaker.id_name)
	#localization_heap.assign(localization_data)
