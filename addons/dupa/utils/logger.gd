class_name DUPA_Logger
extends Node

enum MsgVisibility {DEBUG, ESSENTIAL}
enum LogType {NEUTRAL, WARNING, ERROR, CONFIRMATION}

static var _log_colors := {
	LogType.NEUTRAL: &"ffffff",
	LogType.WARNING: &"ffe300",
	LogType.ERROR: &"ff4000",
	LogType.CONFIRMATION: &"00ff02",
}

#signal new_msg(msg_text: String, color: Color) 


static func add_msg(msg_text: String, visibility := MsgVisibility.DEBUG):
	_construct_entry(msg_text, visibility, LogType.NEUTRAL)


static func add_warning(msg_text: String, visibility := MsgVisibility.DEBUG):
	_construct_entry(msg_text, visibility, LogType.WARNING)


static func add_error(msg_text: String, visibility := MsgVisibility.DEBUG):
	_construct_entry(msg_text, visibility, LogType.ERROR)

#
#static func add_confirmation(msg_text: String, visibility := MsgVisibility.ESSENTIAL):
	#_construct_entry(msg_text, visibility, LogType.CONFIRMATION)



static func _construct_entry(msg_text: String, visibility: MsgVisibility, type := LogType.NEUTRAL):
	if !OS.has_feature("editor") && visibility == MsgVisibility.DEBUG: return
	var color = _log_colors[type]
	var time = Time.get_time_string_from_system()
	var msec := Time.get_ticks_msec() % 1000
	var bbcode_msg = "[color=%s]DUPA: [%s.%s] %s[/color]" % [color, time, msec, msg_text]
	
	#if visibility == MsgVisibility.OUTPUT || visibility == MsgVisibility.BOTH:
	print_rich(bbcode_msg)
	#if visibility == MsgVisibility.DEBUG_PANELS || visibility == MsgVisibility.BOTH:
		#new_msg.emit(bbcode_msg)
