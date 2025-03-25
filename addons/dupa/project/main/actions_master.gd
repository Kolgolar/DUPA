class_name ActionsMaster
extends Node

@export var report_actions := true

var undo_redo := UndoRedo.new()


func undo():
	if !undo_redo.has_undo():
		_report("There is no actions to undo!")
		return
	_report("Undoing action '%s'" % undo_redo.get_current_action_name())
	undo_redo.undo()


func redo():
	if !undo_redo.has_redo():
		_report("There is no actions to redo!")
		return
	undo_redo.redo()
	_report("Redoing action '%s'" % undo_redo.get_current_action_name())


func register_method_action(act_name: String, do_method: Callable, undo_method: Callable, execute := true, merge_mode := UndoRedo.MERGE_DISABLE, backwards_undo := false):
	undo_redo.create_action(act_name, merge_mode, backwards_undo)
	undo_redo.add_do_method(do_method)
	undo_redo.add_undo_method(undo_method)
	undo_redo.commit_action(execute)
	if merge_mode == UndoRedo.MERGE_DISABLE:
		_report("Action '%s' was commited!" % act_name)


func register_property_action(act_name: String, node: Node, property_name: StringName, prev_value, new_value, execute := true, merge_mode := UndoRedo.MERGE_DISABLE):
	undo_redo.create_action(act_name, merge_mode)
	undo_redo.add_do_property(node, property_name, new_value)
	undo_redo.add_undo_property(node, property_name, prev_value)
	undo_redo.commit_action(execute)
	if merge_mode == UndoRedo.MERGE_DISABLE:
		_report("Action '%s' was commited!" % act_name)


func _report(action_text: String):
	if report_actions:
		print_rich("[color=#888888]DUPA: %s[/color]" % action_text)
