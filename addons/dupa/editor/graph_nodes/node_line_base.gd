class_name DUPA_GraphNodeLineBase
extends DUPA_GraphNodeBase

const SPEAKER_CUSTOM = -1

static var all_speakers: PackedStringArray


func _ready() -> void:
	super()
	#_reset_speakers_list()
	

func _on_speaker_selected(idx: int) -> void:
	await get_tree().process_frame
	size.y = 0


#func fill_speakers_list(all_speakers: PackedStringArray) -> void:
	#self.all_speakers = all_speakers


func _on_avaliable_speakers_changed(speakers_map: Dictionary[int, int]) -> void:
	pass


#func _reset_speakers_list() -> void:
	#pass
#
#
#func _speaker_selected(idx: int) -> void:
	#pass
#
#
#func _on_speaker_item_selected(idx: int) -> void:
	#pass
