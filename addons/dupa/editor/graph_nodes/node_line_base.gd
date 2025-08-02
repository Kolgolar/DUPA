class_name DUPA_GraphNodeLineBase
extends DUPA_GraphNodeBase

static var SPEAKER_CUSTOM = -1

#const CUSTOM_SPEAKER_ID := 9999
# TODO: Сделать приватными все поля, указывающие на ноды, т.к. на них не должна быть возможность
# ссылаться извне.
@export var speaker: OptionButton
@export var custom_speaker_name_label: Label
@export var custom_speaker_name_line: LineEdit
#TODO: Добавить подобные поля во все ноды? Или не нужно, пусть это будет только для реально нужных?
@onready var speaker_idx:
	set(idx):
		var list_idx = idx + 1
		speaker.set_deferred("selected", list_idx)
		_speaker_selected(list_idx)
	get:
		return speaker.selected - 1
		

func _ready() -> void:
	super()
	_reset_speakers_list()
	speaker.item_selected.connect(_on_speaker_item_selected)


func fill_speakers_list(all_speakers: PackedStringArray) -> void:
	_reset_speakers_list()
	for i in all_speakers.size():
		speaker.add_item(all_speakers[i])


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"speaker_idx": 
			speaker_idx = int(value)
		&"custom_speaker_name":
			speaker.text = value


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	# Shifts the speaker_idx by 1 so it points at the corresponding element
	# at "speakers_paths" value at the .json save file. We need to do this, because
	# we always have <CUSTOM> element at index 0, so indexes of all other elements
	# shift by 1.
	data[&"speaker_idx"] = speaker_idx
	data[&"custom_speaker_name"] = custom_speaker_name_line.text
	return data


func _reset_speakers_list() -> void:
	speaker.clear()
	speaker.add_item(&"<CUSTOM>")


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([speaker, custom_speaker_name_line])
	return fields


func _speaker_selected(idx: int) -> void:
	var show_custom_speaker_fields = idx == SPEAKER_CUSTOM
	custom_speaker_name_label.visible = show_custom_speaker_fields
	custom_speaker_name_line.visible = show_custom_speaker_fields


func _on_speaker_item_selected(idx: int) -> void:
	_speaker_selected(idx)
