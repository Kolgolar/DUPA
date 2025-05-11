extends CanvasLayer

class_name DialogController

enum Modes {PLAIN_TEXT, DEFAULT}

@export var mode := Modes.DEFAULT:
	set(value):
		mode = value
		_prepare_for_mode(mode)

# export(String, "TimelineDropdown") var timeline : String
# Если включено отображение реплик сбоку от кнопок выбора, и если это мобильное устройство,
# то сама реплика будет выбираться нажатием на РЕПЛИКУ, а не кнопку
@export var _mobile_mode := false
@export var _auto_detect_player_line := true
@export var _drag_player_line_prompt_to_coursor := true
@export var _player_lines_on_choice_buttons := false
@export var _player_lines_prompt := true
@export var _print_player_choosen_line := false
@export var _player_if_no_name := true
@export var _character_text : RichTextLabel
@export var _player_choices_container : VBoxContainer
@export var _player_line : RichTextLabel
@export var _timeline : String = ""
@export var _next_line_button : Button
@export var _max_line_length := 200
@export var _showing_speed : float = 60
@export var _char_showing_sounds_folder := ""
@export var delete_when_finished := false
@export var _force_custom_csv := false
@export var _custom_csv_file := ""
@export var _voice_lines_directory := ""
@export_enum("ru", "en") var _locale = "ru"


var char_name_clr := Color("ffb45b") # Цвет имени персонада, НЕ игрока

var _csv_data := {}

var _is_player_speaking := false

var _dynamic_line_base := ""
var _dynamic_line_from := -1
var _dynamic_line_to := -1
var _dynamic_line_curr := -1

var _visible_characters_tweener : Tween

var _dialog_started := false
var _multiple_choices := false
@export var _test_mode := false

var _condition := false
var _is_hiding := false
#var _timelines_directory := "res://game/dupa/timelines/"
var _curr_node := ""
var _td := {} # TimelineData

var _line_segments := []
var _curr_segment := 0
var _curr_character := ""

var _char_sounds := []
var _prev_char_sound_time : float = 0

var _choice_text_tween: Tween
var _voice_line_players := {}


@export var dv : DialogsVariables

@onready var _cinematic_borders := []
@onready var _player_line_container = %SelectLine
@onready var _char_sound_players := $CharSounds

signal dialog_started
signal dialog_ended
signal line_text_tags_detected(tag: PackedStringArray)
signal voice_line_found(stream: AudioStream)


func _ready():
	_player_line_container.modulate.a = 0.0
	_player_line_container.hide()
	if _char_showing_sounds_folder:
		set_char_sounds(_char_showing_sounds_folder)
	# print_debug("Char sounds: " + str(_char_sounds))
	
	if get_parent() == get_viewport() or _test_mode:
		_test_mode = true
		start_dialog(_timeline)

# TODO:
# Уникальные имена для нодов в редакторе диалогов (мб скрытое поле присваивать?)
# Работа с глобальными переменными из диалогов
# Работа с сигналами из диалогов


func _process(delta) -> void:
	if _player_line_container.visible and _drag_player_line_prompt_to_coursor:
		_player_line_container.position = get_viewport().get_mouse_position() + Vector2(20, 20)

	# if _can_print_next_line():
	# 	if Input.is_action_just_pressed("next_dialog_line"):
	# 		_next_line()
	if _test_mode:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
			

func set_voice_player(char_name: String, player):
	if player is AudioStreamPlayer3D || player is AudioStreamPlayer2D || player is AudioStreamPlayer:
		_voice_line_players[char_name] = player
	else:
		printerr("Audio player should be AudioStreamPlayer[''/2D/3D]")


func set_char_sounds(folder: String):
	_char_sounds = DupaUtility.get_all_files_at(folder, ".mp3")


static func _read_csv_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var err = FileAccess.get_open_error()
	if err != OK:
		push_error("Не найден csv-файл в директории %s. Ошибка: %s" % [file_path, err])
		return {}
		
	var data = {}
	if err == 0:
		var is_first_line := true
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if is_first_line:
				is_first_line = false
				continue
			# FIXME: Не учитывается количество локалей, не учитывается, что могут появляться
			# другие столбцы. Сначала нужно сканировать название столбцов, и исходя из этого
			# заполнять словарь. Возможно, стоит обозначать каждую локаль названием типа
			# locale_**
			if line != "":  # Пропустить пустые строки
				var row := line.split(";")  # Разделить строку по табам
				if row[1] == "": continue # Если id пустой
				var id = row[1]
				row.remove_at(0) # Удаляем комментарий
				row.remove_at(0)
				data[id] = {
					"tags": row[1],
					"line": row[2],
				}
		file.close()
	
	return data




func _prepare_for_mode(mode:Modes):
	match mode:
		Modes.PLAIN_TEXT:
			%TextPanel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			%CharacterName.hide()
			%ChoicesArea.hide()
			%MainContainer.alignment = BoxContainer.AlignmentMode.ALIGNMENT_CENTER
		Modes.DEFAULT:
			%TextPanel.add_theme_stylebox_override("panel", preload("res://addons/dupa/project/dialog_controller/text_panel_default.tres"))
			%CharacterName.show()
			%ChoicesArea.show()
			%MainContainer.alignment = BoxContainer.AlignmentMode.ALIGNMENT_END

func _reset():
	_csv_data.clear()
	_change_player_choices_visibillity(false)
	_player_line_container.hide()
	_character_text.text = ""


func _is_final_segment() -> bool:
	return _line_segments.size() == 0 or _curr_segment == _line_segments.size() - 1


func start_dialog(timeline_name := _timeline) -> void:
	# _show_borders()
	_reset()
	show()
	# PIZDEC!!!!!!!
	#var path := _timelines_directory + timeline_name + ".json"
	var path := timeline_name
	# var file := FileAccess.open(path, FileAccess.READ)
	if path.is_empty() or not FileAccess.file_exists(path):
		printerr("Can't found timeline at " + path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text()) # TimelineData
	_td = test_json_conv.get_data()["TIMELINE"]
	file.close()

	# var start_node = "FEATURE_Start"
	# print(_td)
	var start_node = "0"
	_curr_node = start_node
	if _td[start_node]["type"] != DupaLib.NodeType.START:
		printerr("Node with id == 0 is not StartNode!")
		return
	if _force_custom_csv:
		_csv_data = _read_csv_file(_custom_csv_file)
	elif _td[start_node].has("source"):
		_csv_data = _read_csv_file(_td[start_node]["source"])
	_next_line()


	# _read_timeline(path)
	emit_signal('dialog_started')
	await get_tree().create_timer(0.33).timeout
	_dialog_started = true


func stop_dialog(forced_stop := false) -> void:
	# if not forced_stop:
	# 	_hide_borders()
	# hide()
	_dialog_started = false
	hide()
	emit_signal('dialog_ended')
	#await $Background/AnimationPlayer.animation_finished
	if delete_when_finished && !_test_mode:
		queue_free()


func force_char_name(char_name: String):
	_curr_character = char_name


func _can_print_next_line() -> bool:
	return not _multiple_choices and _dialog_started


func _get_node_type(node_name) -> String:
	return _td[node_name]["type"]


func _get_go_to_nodes(node_name) -> Array:
	var go_to_arr := []
	match _td[node_name].type:
		DupaLib.NodeType.CONDITION:
			if _condition:
				go_to_arr = _td[node_name]["go_to_true"]
			else:
				go_to_arr = _td[node_name]["go_to_false"]
		_:
			go_to_arr = _td[node_name]["go_to"]
	
	return go_to_arr


func _display_choices(choices : Array) -> void:
	for b in _player_choices_container.get_children():
		b.queue_free()
	for c in choices.size():
		print(_td[choices[c]])
		var b_text := ""
		var choice_text := ""
		# TODO: Учитывать разные настройки вывода текста выбора (только на кнопках или нет и т.д.)
		if _player_lines_on_choice_buttons:
			if _td[choices[c]].has("line_text"):
				b_text = _td[choices[c]]["line_text"]
			else:
				b_text = _td[choices[c]]["text"]
		else:
			var full_text = ""
			if _td[choices[c]].has("line_text"):
				full_text = _td[choices[c]]["line_text"]
			else:
				full_text = _td[choices[c]]["text"]
			
			if _csv_data.is_empty():
				full_text = tr(full_text)
			else:
				full_text = _csv_data[full_text].line
			b_text = full_text
			var regex = RegEx.new()
			regex.compile("(?<=^\\[choice:).*(?=\\])")
			var result := regex.search(b_text)
			if result:
				b_text = result.get_string().strip_edges()
				regex.compile("(?<=\\]).*")
				var only_text = regex.search(full_text)
				if only_text:
					choice_text = only_text.get_string().strip_edges()
				
		if b_text.is_empty(): continue
		
		var button = preload("res://addons/dupa/project/dialog_controller/dialog_choice_button.tscn").instantiate()
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.text = b_text
		_player_choices_container.add_child(button)
		if _mobile_mode && !choice_text.is_empty():
			button.toggle_mode = true
			button.toggled.connect(_on_choice_button_toggled.bind(button, c, choice_text))
		else:
			button.connect("pressed", Callable(self, "_on_choice_button_pressed").bind(c))
	
		if _player_lines_prompt:
			var player_line := ""
			if _auto_detect_player_line:
				pass
			if !_mobile_mode:
				button.connect("mouse_entered", _on_choice_button_mouse_entered.bind(choice_text, button))
				button.connect("mouse_exited", _on_choice_button_mouse_exited)
		
		_player_line_container.visible = !choice_text.is_empty()
	
	_change_player_choices_visibillity(true)


func _separate_to_sentences(line : String) -> Array:
	var regex = RegEx.new()
	# regex.compile(".+\\n|\\. ")
	# regex.compile(".*?[.!?\\n]+\\s*")
	regex.compile(".*?[.!?\\n]+(?:\\s+|$)")
	var results = []
	for result in regex.search_all(line):
		results.push_back(result.get_string())
	return results
	

func _next_line(idx := 0) -> void:
	# print(_curr_node)
	# Получить количество вариантов ответов
	# Если их больше 1, то показать кнопки
	# Выбор кнопки = вызов этой функции с idx > -1
	# print(_td[_curr_node])
	var go_to_arr := _get_go_to_nodes(_curr_node)
	# If there are any nodes after current:
	if go_to_arr.size() > 0 || _dynamic_line_curr >= 0:
		# if go_to_arr.size() > 1 and not _print_player_choosen_line:
		# 	_next_line()
		#var prev_node = _curr_node
		
		if _dynamic_line_curr < 0:
			_curr_node = go_to_arr[idx]

		var line_text := ""
		var node_type = _td[_curr_node]["type"]
		if DupaLib.NodeType.LINE == node_type || DupaLib.NodeType.DYNAMIC_ID_LINE == node_type:
			if node_type == DupaLib.NodeType.DYNAMIC_ID_LINE:
				if _dynamic_line_curr < 0:
					_dynamic_line_base = _td[_curr_node]["base"]
					_dynamic_line_from = int(_td[_curr_node]["from"])
					_dynamic_line_to = int(_td[_curr_node]["to"])
					_dynamic_line_curr = _dynamic_line_from
				else:
					_dynamic_line_curr += 1
				
				if _dynamic_line_curr <= _dynamic_line_to:
					line_text =_dynamic_line_base + str(_dynamic_line_curr)
				else:
					_dynamic_line_curr = -1
					_set_next_step()
					return
				
			else:
				if _td[_curr_node].has("line_text"):
					line_text = _td[_curr_node]["line_text"]
				else:
					line_text = _td[_curr_node]["text"]
			var has_player_line_tag := false
			var text = ""
			if _csv_data.is_empty(): 
				text = tr(line_text)
			else:
				text = _csv_data[line_text].line
				var tags_list = _csv_data[line_text].tags.split(',', false)
				var tags_data := {}
				if tags_list.size() > 0:
					for data in tags_list:
						var key_value = data.split(':')
						tags_data[key_value[0]] = key_value[1]
					line_text_tags_detected.emit(tags_data)
					if tags_data.has("char"):
						has_player_line_tag = tags_data.char == "player"
			
			if text.is_empty():
				print("FUCK")
			
			if _td[_curr_node].has("is_player") && _td[_curr_node]["is_player"] || has_player_line_tag:
				_curr_character = dv.player_name
				%CharacterName.self_modulate = Color("94ff7c")
				_is_player_speaking = true
			else:
				_curr_character = dv.character_name
				%CharacterName.self_modulate = char_name_clr
				_is_player_speaking = false
			
			
			_line_segments.clear()
			_curr_segment = 0
			

			# print(text.length())
			if text.length() > _max_line_length:
				var sentences = _separate_to_sentences(text)
				# print(sentences)
				var combined_sentences := ""
				for s in sentences:
					var comb : String = combined_sentences + s
					if comb.length() < _max_line_length:
						combined_sentences = comb
					else:
						_line_segments.append(combined_sentences)
						combined_sentences = s
				_line_segments.append(combined_sentences)

				# # var splitted_text = text.split(". ", false)
				# var splitted_text = text.split(". ", false)
				# # print(splitted_text)
				# var combined_text := ""
				# for line in splitted_text:
				# 	line += ". "
				# 	var total = combined_text + line
				# 	if total.length() < _max_line_length + 2:
				# 		combined_text = total
				# 		# print(line)
				# 	else:
				# 		# print(combined_text)
				# 		if combined_text.length() > 0:
				# 			_line_segments.append(combined_text)
				# 		combined_text = line
				# # print(_line_segments)
				text = _line_segments[0]
			if go_to_arr.size() > 1 and not _print_player_choosen_line and _dynamic_line_curr < 0:
				_set_next_step()
				return
			_show_character_line(_curr_character, text)
			return
			
		elif node_type == DupaLib.NodeType.CONDITION:
			var node_data : Dictionary = _td[_curr_node]
			var condition_var : bool = dv.get(node_data["var_name"])
			if condition_var == null:
				printerr("Condition variable '" + node_data["var_name"] + "' does not exist!")
				return
			if condition_var:
				_condition = true
			else:
				_condition = false
			_set_next_step()
			return

		elif node_type == "SETTER":
			var node_data : Dictionary = _td[_curr_node]
			var var_value = node_data["var_value"]
			var var_name = node_data["var_name"]
			if dv.get(var_name) == null:
				print_debug("Can't set variable '" + var_name + "' that does not exists!")
				return
			var set_to = _determine_type(var_value)
			dv.set(var_name, set_to)
			_set_next_step()
			return
					
		elif node_type == "CALLER":
			var node_data : Dictionary = _td[_curr_node]
			var func_name = node_data["var_name"]
			var args_values = node_data["var_value"]
			if not dv.has_method(func_name):
				printerr("Method '" + func_name + "' does not exists!")
				return
			
			var args := []
			if not args_values.is_empty():
				for arg in args_values.split(",", false):
					args.append(_determine_type(arg))
				dv.callv(func_name, args)
			else:
				dv.call(func_name)
			_set_next_step()
			return

	stop_dialog()
		

func _set_next_step(next_line_if_no_choices := true) -> void:
	var choices : Array = _get_go_to_nodes(_curr_node)
	if choices.size() > 1:
		_next_line_button.hide()
		_display_choices(choices)
	else:
		# TODO: Задержка принятия нажатия после появления кнопок
		# TODO: Индикатор доступности вывода следующей реплики
		_next_line_button.show()
		_change_player_choices_visibillity(false)
		if next_line_if_no_choices:
			_next_line()


func _determine_type(value: String):
	var set_to
	# print(value.to_upper())
	if value.begins_with('"'):
		value = value.trim_prefix('"')
		value = value.trim_suffix('"')
		set_to = str(value)
	else:
		match value.to_upper():
			"TRUE":
				set_to = true
			"FALSE":
				set_to = false
			_:
				set_to = int(value)

	return set_to


func _change_player_choices_visibillity(v : bool) -> void:
	# for b in _player_choices_container.get_children():
	# 	b.disabled = true
	_player_choices_container.get_parent().modulate.a = 0.0
	_player_choices_container.get_parent().visible = v
	_multiple_choices = v
	#await get_tree().create_timer(0.5).timeout
	_player_choices_container.get_parent().modulate.a = 1.0
	# await get_tree().create_timer(0.5).timeout
	# for b in _player_choices_container.get_children():
	# 	b.disabled = false


func _show_character_line(character : String, line : String) -> void:
	%CharacterName.text = "[i][b]%s:[/b][/i]" % character
	_character_text.visible_characters = 0
	_character_text.text = line
	var parsed_text_length := _character_text.get_parsed_text().length()
	var time := float(parsed_text_length) / _showing_speed
	_prev_char_sound_time = 0
	_visible_characters_tweener = create_tween().set_parallel(true)
	_visible_characters_tweener.finished.connect(_on_text_showing_tween_finished)
	_visible_characters_tweener.tween_method(_change_visible_characters, 0, parsed_text_length, time)
	if !_is_player_speaking:
		_visible_characters_tweener.tween_method(_play_char_showing_sound, 0.0, time, time)
	
	# TODO: Не проигрывает звуки, не выводит текст (не считывает сами реплики из csv, хотя остальное видит?)
	
	if !_voice_lines_directory.is_empty():
		var line_text := ""
		if _td[_curr_node].has("line_text"):
			line_text = _td[_curr_node]["line_text"]
		else:
			line_text = _td[_curr_node]["text"]
		var path = _voice_lines_directory.path_join(_locale).path_join(line_text + ".mp3")
		var is_exists = FileAccess.file_exists(path)
		if is_exists:
			var player
			if _voice_line_players.has(character):
				player = _voice_line_players[character]
			else:
				player = %VoiceLinePlayer
			var audio_stream: AudioStream = load(path)
			#if _voice_line_players.has(character):
				#voice_line_found.emit(audio_stream)
			#else:
			player.stream = audio_stream
			player.play()
		
				
			

func _change_visible_characters(value : int) -> void:
	_character_text.visible_characters = value
	var parsed_text := _character_text.get_parsed_text()
	if value > 0 && value < parsed_text.length() && parsed_text[value] == ' ':
		#if _character_text.size() - visible_chars > 1:
			
		var time := -1.
		match parsed_text[value - 1]:
			",":
				time = 0.04
			"…", ".", "!", "?":
				time = 0.08
		if time > 0:
			_visible_characters_tweener.pause()
			await get_tree().create_timer(time).timeout
			_visible_characters_tweener.play()


func _play_char_showing_sound(time : float) -> void:
	if time - _prev_char_sound_time > 0.08:
		#var node = _char_sound_players.get_child(randi_range(0, 7))
		var node = _char_sound_players.get_child(0)
		if _char_sounds.size() > 0:
			node.stream = load(_char_sounds.pick_random())
		# _char_sound_player.pitch_scale = randf_range(0.95, 1.15)
		node.play()
		_prev_char_sound_time = time


func _show_player_line(line: String, button: Button):
	_player_line.size.y *= 0
	_player_line_container.size.y *= 0
	
	_player_line.set_deferred("text", line)
	
	if _choice_text_tween != null:
		_choice_text_tween.kill()
	_choice_text_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	#if _choice_text_tween.is_running():
		#_choice_text_tween.stop()
	var time := 0.25
	var final_pos = button.global_position + Vector2(_player_choices_container.size.x + 30, 0)
	_choice_text_tween.tween_property(_player_line_container, "global_position", final_pos, time).from(final_pos - Vector2(100, 0))
	_choice_text_tween.tween_property(_player_line_container, "modulate:a", 1.0, time)
	#_player_line_container.modulate.a = 1.0
	
	


func _hide_player_line():
	_player_line_container.modulate.a = 0.0


func _on_choice_button_mouse_entered(line : String, button: Button) -> void:
	_show_player_line(line, button)
	

func _on_choice_button_mouse_exited() -> void:
	_hide_player_line()

# Если НЕ мобильный режим
func _on_choice_button_pressed(idx: int) -> void:
	_next_line(idx)
	_player_line_container.hide()


func force_choice_by_num(num: int):
	var choices = _get_go_to_nodes(_curr_node)
	if choices.size() > num:
		_next_line(choices[num])


# Если мобильный режим
func _on_choice_button_toggled(toggled: bool, button: Button, idx: int, line: String):
	if %SelectLine.pressed.is_connected(_on_select_line_pressed):
		%SelectLine.pressed.disconnect(_on_select_line_pressed)
	if toggled:
		for b in _player_choices_container.get_children():
			if b != button:
				b.button_pressed = false
				#b.modulate.a = 0.7
			#else:
				#b.modulate.a = 1.0
		_show_player_line(line, button)
		%SelectLine.pressed.connect(_on_select_line_pressed.bind(idx))
	else:
		_hide_player_line()

# Если мобильный режим:
func _on_select_line_pressed(idx: int) -> void:
	_next_line(idx)
	_player_line_container.hide()


func _proceed() -> void:
	if _visible_characters_tweener and _visible_characters_tweener.is_running():
		_visible_characters_tweener.kill()
		_character_text.visible_ratio = 1.0
		_on_text_showing_tween_finished()
	else:
		if _is_final_segment():
			if _can_print_next_line():
				_next_line()
		else:
			_curr_segment += 1
			_show_character_line(_curr_character, _line_segments[_curr_segment])
	


func _on_text_showing_tween_finished() -> void:
	if _is_final_segment() && _dynamic_line_curr < 0:
		_set_next_step(false)


func _on_Frame_pressed() -> void:
	_proceed()


func _on_NextLine_pressed() -> void:
	_proceed()
