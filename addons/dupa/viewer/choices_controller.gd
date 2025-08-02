extends Control

signal choice_made(dialog_choice_data: DUPA_Lib.DN_LineChoice)

enum PlayerChoiceLinePreviewMode {
	DISABLED, ## Full player lines should be displayed on choice buttons.[br]
	SHOW_ON_HOVER, ## The choice buttons should contain the brief of the choice lines, while the full line will be displayed in the separate panel if a mouse cursor is hovering the choice button.[br]
	SHOW_ON_PRESS ## The same as the previous, but the full choice line will be displayed on PRESSING the choice button, so the final choice should be done by pressing on the full choice line.[br]
}

var localization_master: DUPA_LocalizationMaster
var _toggled_choice_data: DUPA_Lib.DN_LineChoice

@export var player_choice_line_preview_mode: PlayerChoiceLinePreviewMode = PlayerChoiceLinePreviewMode.SHOW_ON_HOVER
@export var choices_container: Container ## The node that should hold the choice buttons.
@export var choice_full_line_button: Button
@export var choice_full_line: RichTextLabel
@export_range(0, 9999, 1) var max_short_choice_length := 48
@export var dialog_choice_button: PackedScene
@export var dialog_choice_button_toggle: PackedScene


func _ready() -> void:
	clear()
	choice_full_line_button.pressed.connect(_on_choice_full_line_button_pressed)


func clear() -> void:
	for b in choices_container.get_children(): b.queue_free()
	choice_full_line_button.hide()


func is_showing_choices() -> bool:
	return choices_container.get_child_count() > 0


func show_choices(dialog_nodes: Array[DUPA_Lib.DN_Base]) -> void:
	DUPA_Logger.add_msg("Showing choices.")
	for n in dialog_nodes:
		assert(n is DUPA_Lib.DN_LineChoice, "All choice nodes should inherit LineChoice class!")
		var dialog_node := n as DUPA_Lib.DN_LineChoice
		var line_id: StringName = dialog_node.line_id
		#var line_full := get_line_localized_text(line_id, null)
		var line_full: String = dialog_node.line_full
		var regex = RegEx.new()
		regex.compile("(?<=^\\[choice:).*(?=\\])")
		var result := regex.search(line_full)
		var line_choice := ""
		if result:
			line_choice = result.get_string().strip_edges()
			regex.compile("(?<=\\]).*")
			var only_text = regex.search(line_full)
			if only_text:
				line_full = only_text.get_string().strip_edges()
				#if line_full.is_empty():
					#push_errororor("The result line text is empty!")
		
		if line_choice.is_empty():
			#push_errororor("The result button text is empty!")
			#if !line_full.is_empty():
			line_choice = line_full
			line_full = ""
		
		if max_short_choice_length > 0 && line_choice.length() > max_short_choice_length:
			if line_full.is_empty():
				line_full = line_choice
			line_choice = line_choice.left(max_short_choice_length - 3)
			line_choice += "..."
			
		var button: Button
		if player_choice_line_preview_mode == PlayerChoiceLinePreviewMode.SHOW_ON_PRESS:
			assert(dialog_choice_button_toggle, "Dialog choice button toggle was not set! Check the Inspector of the 'ChoicesController' node.")
			button = dialog_choice_button_toggle.instantiate()
		else:
			assert(dialog_choice_button, "Dialog choice button was not set! Check the Inspector of the 'ChoicesController' node.")
			button = dialog_choice_button.instantiate()
		#button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if player_choice_line_preview_mode == PlayerChoiceLinePreviewMode.DISABLED && !line_full.is_empty():
			button.text = line_full
		else:
			button.text = line_choice
		choices_container.add_child(button)
		
		dialog_node.line_choice = line_choice
		dialog_node.line_full = line_full
		
		match player_choice_line_preview_mode:
			# Button contains a full line, no preview text panel
			PlayerChoiceLinePreviewMode.DISABLED:
				button.toggle_mode = false
				button.pressed.connect(_on_choice_button_pressed.bind(dialog_node, button))
			# Button contains a sort line, a full line is displayed on button HOVERING 
			PlayerChoiceLinePreviewMode.SHOW_ON_HOVER:
				button.toggle_mode = false
				button.pressed.connect(_on_choice_button_pressed.bind(dialog_node, button))
				button.mouse_entered.connect(_on_choice_button_mouse_entered.bind(dialog_node, button))
				button.mouse_exited.connect(_on_choice_button_mouse_exited.bind(dialog_node, button))
			# Button contains a short line, a full line is displayed on button PRESS
			PlayerChoiceLinePreviewMode.SHOW_ON_PRESS:
				button.toggle_mode = true
				button.button_pressed = false
				button.toggled.connect(_on_choice_button_toggled.bind(dialog_node, button))
				if line_full.is_empty():
					push_error("Full choice line is empty, but it's mandatory to be displayed on the choice full line button.")
					dialog_node.line_full = line_choice
				
# DISABLED preview mode
func _on_choice_button_pressed(dialog_choice_data: DUPA_Lib.DN_LineChoice, button: Button) -> void:
	__on_choice_made(dialog_choice_data)



# SHOW_ON_HOVER preview mode
func _on_choice_button_mouse_entered(dialog_choice_data: DUPA_Lib.DN_LineChoice, button: Button) -> void:
	if dialog_choice_data.line_full.is_empty(): return
	choice_full_line.text = dialog_choice_data.line_full
	choice_full_line_button.show()


func _on_choice_button_mouse_exited(dialog_choice_data: DUPA_Lib.DN_LineChoice, button: Button) -> void:
	choice_full_line_button.hide()



# SHOW_ON_PRESS preview mode
func _on_choice_full_line_button_pressed() -> void:
	__on_choice_made(_toggled_choice_data)
		


func _on_choice_button_toggled(button_toggled: bool, dialog_choice_data: DUPA_Lib.DN_LineChoice, button: Button) -> void:
	choice_full_line.text = dialog_choice_data.line_full
	choice_full_line_button.visible = button_toggled && !choice_full_line.text.is_empty()
	if !button_toggled:
		_toggled_choice_data = null
		return
	_toggled_choice_data = dialog_choice_data
	for b in choices_container.get_children() as Array[Button]:
		b.set_pressed_no_signal(b == button)



func __on_choice_made(dialog_choice_data: DUPA_Lib.DN_LineChoice) -> void:
	choice_made.emit(dialog_choice_data)
	clear()
