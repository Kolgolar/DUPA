# TODO: Добавить возможность АВТОМАТИЧЕСКОГО определения говорящего. В этом
# случае путь до CharacterData должен браться из тэга.

class_name DUPA_GraphNodeLine
extends DUPA_GraphNodeLineBase

@export var speaker: BoxContainer
@export var line_id: TextEdit
# TODO: Сделать приватными все поля, указывающие на ноды, т.к. на них не должна быть возможность
# ссылаться извне.
#TODO: Добавить подобные поля во все ноды? Или не нужно, пусть это будет только для реально нужных?
@onready var speaker_idx:
	set(idx):
		speaker.speaker_idx = idx
	get:
		return speaker.speaker_idx
@onready var custom_speaker_name: String:
	set(value):
		speaker.custom_speaker_name = value
	get:
		return speaker.custom_speaker_name



func _ready():
	super()
	type = DUPA_Lib.NodeType.LINE
	speaker.removable = false
	speaker.speaker_selected.connect(_on_speaker_selected)
	speaker.update_speakers_list(all_speakers)


func _on_avaliable_speakers_changed(speakers_map: Dictionary[int, int]) -> void:
	speaker.update_speakers_list(all_speakers, speakers_map)


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"line_id":
			line_id.text = value
		&"speaker_idx": 
			speaker_idx = int(value)
		&"custom_speaker_name":
			speaker.custom_speaker_name = value


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	if not line_id.text.is_empty() || allow_empty:
		data[&"line_id"] = line_id.text
	data[&"speaker_idx"] = speaker_idx
	data[&"custom_speaker_name"] = speaker.custom_speaker_name
	return data


func _reset_speakers_list() -> void:
	speaker.reset_speakers_list()


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([line_id, speaker.speaker, speaker.custom_speaker_name_line])
	return fields
