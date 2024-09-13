extends DefaultNode

class_name LineNode

onready var text = $HBoxContainer/MainColumn/Text/Text
onready var localization_id = $HBoxContainer/MainColumn/Title/LocalizationLine
onready var choice_name = $HBoxContainer/MainColumn/Choice/ChoiceName
onready var custom_char_name = $HBoxContainer/MainColumn/Character/CustomCharName
onready var character_drop = $HBoxContainer/MainColumn/Character/CharacterDrop

var characters = [
	"Player",
	"Char1",
	"Char2",
	"Char3",
	"Char4",
	"Char5",
	"Char6",
	"Char7",
	"Char8",
]


func _ready():
	type = "LINE"
	var char_index = 0
	for ch in characters:
		character_drop.add_item(ch, char_index)
		char_index += 1 


func set_data(graph_edit : GraphEdit, data : Dictionary, id_name : String) -> void:
	character_drop.text = data["character"]
	text.text = data["text"]
	if "choice_name" in data:
		choice_name.text = data["choice_name"]
	if "localization_id" in data:
		localization_id.text = data["localization_id"]
	if "custom_char_name" in data:
		custom_char_name.text = data["custom_char_name"]


func gen_data(graph_edit : GraphEdit) -> Dictionary:
	var data := {}
	data["go_to"] = []
	data["character"] = character_drop.text
	data["text"] = text.text
	if not choice_name.text.empty():
		data["choice_name"] = choice_name.text
	if not localization_id.text.empty():
		data["localization_id"] = localization_id.text
	if not custom_char_name.text.empty():
		data["custom_char_name"] = custom_char_name.text
	
	data["go_to"] = _arrange_go_to(graph_edit)
	return data
