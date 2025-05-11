extends DupaNodeBase

class_name LineNode

@onready var text = $HBoxContainer/MainColumn/Text/Text
@onready var line_text = $HBoxContainer/MainColumn/Title/LocalizationLine
@onready var choice_name = $HBoxContainer/MainColumn/Choice/ChoiceName
@onready var custom_char_name = $HBoxContainer/MainColumn/Character/CustomCharName
@onready var character_drop = $HBoxContainer/MainColumn/Character/CharacterDrop

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


func set_data(data : Dictionary) -> void:
	character_drop.text = data["character"]
	text.text = data["text"]
	if "choice_name" in data:
		choice_name.text = data["choice_name"]
	if "line_text" in data:
		line_text.text = data["line_text"]
	if "custom_char_name" in data:
		custom_char_name.text = data["custom_char_name"]


func gen_data(allow_empty := false) -> Dictionary:
	var data := {}
	data["go_to"] = []
	data["character"] = character_drop.text
	data["text"] = text.text
	if not choice_name.text.is_empty():
		data["choice_name"] = choice_name.text
	if not line_text.text.is_empty():
		data["line_text"] = line_text.text
	if not custom_char_name.text.is_empty():
		data["custom_char_name"] = custom_char_name.text
	
	data["go_to"] = _arrange_go_to()
	return data
