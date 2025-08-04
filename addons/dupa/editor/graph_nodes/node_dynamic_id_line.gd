class_name DUPA_GraphNodeDynamicIDLine
extends DUPA_GraphNodeLineBase

const SPEAKER_DATA := preload("res://addons/dupa/editor/graph_nodes/line_speaker.tscn")

@export var id_base: LineEdit
@export var id_from: SpinBox
@export var id_to: SpinBox
@export var speakers_container: BoxContainer
@export var random_check_button: CheckButton

var _speakers: Array[BoxContainer]

@onready var speaker_idx:
	set(idx):
		_reset_idxed_speakers()
		for i in idx:
			_on_add_speaker_pressed()
			# Не работает, ибо списка спикеров нет!!!!!!
			_speakers[-1].speaker_idx = int(i)
	get:
		var idxs: PackedInt32Array = _speakers.map(func(sp): return sp.speaker_idx)
		return idxs



func _ready():
	super()
	type = DUPA_Lib.NodeType.DYNAMIC_ID_LINE
	# FIXME: При загрузке блупринта, этот созданный спикер будет сразу удалён...
	_on_add_speaker_pressed()


func _on_avaliable_speakers_changed(speakers_map: Dictionary[int, int]) -> void:
	for speaker: BoxContainer in speakers_container.get_children():
		speaker.update_speakers_list(all_speakers, speakers_map)


func _get_fields_to_track() -> Array[Control]:
	# NOTE: Добавление/удаление speaker'ов не отслеживается!
	var fields = super()
	fields.append_array([id_base, id_from, id_to])
	return fields


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"base":
			id_base.text = value
		&"from":
			id_from.value = int(value)
		&"to":
			id_to.value = int(value)
		&"is_random":
			random_check_button.button_pressed = value
		&"speaker_idx":
			speaker_idx = value
		&"custom_speaker_name":
			_reset_custom_speakers()
			for custom_name in value:
				_on_add_speaker_pressed()
				_speakers[-1].custom_speaker_name = custom_name


func gen_data(allow_empty := false) -> Dictionary:
	var data = super()
	data[&"base"] = id_base.text
	data[&"from"] = int(id_from.value)
	data[&"to"] = int(id_to.value)
	data[&"is_random"] = random_check_button.button_pressed
	var all_speakers_idx: PackedInt32Array
	var all_speakers_custon_names: PackedStringArray
	for speaker in _speakers:
		var idx = speaker.speaker_idx
		if idx > -1:
			all_speakers_idx.append(speaker.speaker_idx)
		else:
			all_speakers_custon_names.append(speaker.custom_speaker_name)
	data[&"speaker_idx"] = all_speakers_idx
	data[&"custom_speaker_name"] = all_speakers_custon_names
	
		
	
	return data


func refresh_speakers_list() -> void:
	for speaker in _speakers:
		speaker.update_speakers_list(all_speakers)


func _reset_idxed_speakers() -> void:
	for i in _speakers.size():
		var speaker = _speakers[i]
		if speaker.speaker_idx >= 0:
			speaker.queue_free()
			_speakers.remove_at(i)


func _reset_custom_speakers() -> void:
	for i in _speakers.size():
		var speaker = _speakers[i]
		if speaker.speaker_idx <= 0:
			speaker.queue_free()
			_speakers.remove_at(i)


func _check_quantity() -> void:
	_speakers[0].removable = _speakers.size() > 1
	# Does not work with one await...
	await get_tree().process_frame
	await get_tree().process_frame
	size.y = 0


func _on_speaker_removed(speaker: Control) -> void:
	_speakers.erase(speaker)
	_check_quantity()


func _on_add_speaker_pressed() -> void:
	var new_speaker = SPEAKER_DATA.instantiate()
	new_speaker.allow_custom_speaker = false
	speakers_container.add_child(new_speaker)
	new_speaker.update_speakers_list(all_speakers)
	new_speaker.removed.connect(_on_speaker_removed.bind(new_speaker))
	new_speaker.speaker_selected.connect(_on_speaker_selected)
	new_speaker.update_speakers_list(all_speakers)
	_speakers.append(new_speaker)
	_check_quantity()
