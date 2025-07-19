# TODO: Добавить возможность АВТОМАТИЧЕСКОГО определения говорящего. В этом
# случае путь до CharacterData должен браться из тэга.

class_name DUPA_GraphNodeLine
extends DUPA_GraphNodeLineBase

@export var line_id: LineEdit


func _ready():
	super()
	type = DUPA_Lib.NodeType.LINE


func set_param(param_name: StringName, value):
	super(param_name, value)
	match param_name:
		&"line_id":
			line_id.text = value


func gen_data(allow_empty := false) -> Dictionary:
	var data := super()
	if not line_id.text.is_empty() || allow_empty:
		data[&"line_id"] = line_id.text
	return data


func _get_fields_to_track() -> Array[Control]:
	var fields = super()
	fields.append_array([line_id, speaker])
	return fields
