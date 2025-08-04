extends VBoxContainer

signal removed
signal speaker_selected(idx: int)

@export var speaker: OptionButton
@export var custom_speaker_container: BoxContainer
@export var custom_speaker_name_line: LineEdit
@export var remove_button: Button
# TODO: Сделать приватными все поля, указывающие на ноды, т.к. на них не должна быть возможность
# ссылаться извне.

@onready var removable := false:
	set(value):
		removable = value
		remove_button.disabled = !removable
		remove_button.self_modulate.a = float(removable)
#TODO: Добавить подобные поля во все ноды? Или не нужно, пусть это будет только для реально нужных?
@onready var speaker_idx:
	# Shifts the speaker_idx by 1 so it points at the corresponding element
	# at "speakers_paths" value at the .json save file. We need to do this, because
	# we always have <CUSTOM> element at index 0, so indexes of all other elements
	# shift by 1.
	set(idx):
		var list_idx = idx + 1
		speaker.selected = list_idx
		_speaker_selected(idx)
	get:
		return speaker.selected - 1

@onready var custom_speaker_name := "":
	set(value):
		custom_speaker_name_line.text = value
	get:
		return custom_speaker_name_line.text


func _ready() -> void:
	speaker.item_selected.connect(_on_speaker_item_selected)
	#custom_speaker_container.hide()


func update_speakers_list(all_speakers: PackedStringArray, speakers_map: Dictionary[int, int] = {}) -> void:
	var cached_idx = speaker_idx
	reset_speakers_list()
	for i in all_speakers.size():
		speaker.add_item(all_speakers[i])
	
	if speakers_map.is_empty(): return
	var set_to_idx := -1
	if speakers_map.has(cached_idx):
		set_to_idx = speakers_map[cached_idx]
	speaker_idx = set_to_idx
	

func reset_speakers_list() -> void:
	speaker.clear()
	speaker.add_item(&"<CUSTOM>")


func _speaker_selected(idx: int) -> void:
	var show_custom_speaker_fields = idx == DUPA_GraphNodeLineBase.SPEAKER_CUSTOM
	custom_speaker_container.visible = show_custom_speaker_fields
	speaker_selected.emit(idx)


func _on_speaker_item_selected(idx: int) -> void:
	_speaker_selected(idx - 1)


func _on_remove_pressed() -> void:
	removed.emit()
	queue_free()
