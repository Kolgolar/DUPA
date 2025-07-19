class_name DUPA_GraphNodeLineBase
extends DUPA_GraphNodeBase

#const CUSTOM_SPEAKER_ID := 9999

@export var speaker: OptionButton
@export var custom_speaker_name_label: Label
@export var custom_speaker_name_line: LineEdit


func _ready() -> void:
	super()
	speaker.add_item("<CUSTOM>")
	speaker.item_selected.connect(_on_speaker_item_selected)
	_speaker_changed(0)


func fill_speakers_list(all_speakers: PackedStringArray) -> void:
	for i in all_speakers.size():
		speaker.add_item(all_speakers[i])


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"speaker_idx": 
			var real_idx: int = value + 1
			speaker.selected = real_idx
			_speaker_changed(real_idx)
		&"custom_speaker_name":
			speaker.text = value


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	# Shifts the speaker_idx by 1 so it points at the corresponding element
	# at "speakers_paths" value at the .json save file. We need to do this, because
	# we always have <CUSTOM> element at index 0, so indexes of all other elements
	# shift by 1.
	data[&"speaker_idx"] = speaker.selected - 1
	data[&"custom_speaker_name"] = custom_speaker_name_line.text
	return data


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([speaker, custom_speaker_name_line])
	return fields


func _speaker_changed(idx: int) -> void:
	var show_custom_speaker_fields = idx == 0
	custom_speaker_name_label.visible = show_custom_speaker_fields
	custom_speaker_name_line.visible = show_custom_speaker_fields


func _on_speaker_item_selected(idx: int) -> void:
	_speaker_changed(idx)
