extends Node


var undo_redo := UndoRedo.new()


func undo():
	if !undo_redo.has_undo():
		print("There is no actions to undo!")
		return
	print("Undoing action '%s'" % undo_redo.get_current_action_name())
	undo_redo.undo()


func redo():
	if !undo_redo.has_redo():
		print("There is no actions to redo!")
		return
	undo_redo.redo()
	print("Redoing action '%s'" % undo_redo.get_current_action_name())


func dummy_method():
	pass


func register_method_action(act_name: String, do_method: Callable, undo_method: Callable, execute := true, merge_mode := UndoRedo.MERGE_DISABLE):
	undo_redo.create_action(act_name, merge_mode)
	undo_redo.add_do_method(do_method)
	undo_redo.add_undo_method(undo_method)
	undo_redo.commit_action(execute)
	if merge_mode == UndoRedo.MERGE_DISABLE:
		print("Action '%s' was commited!" % act_name)


func register_property_action(act_name: String, node: Node, property_name: StringName, prev_value, new_value, execute := true, merge_mode := UndoRedo.MERGE_DISABLE):
	undo_redo.create_action(act_name, merge_mode)
	undo_redo.add_do_property(node, property_name, new_value)
	undo_redo.add_undo_property(node, property_name, prev_value)
	undo_redo.commit_action(execute)
	if merge_mode == UndoRedo.MERGE_DISABLE:
		print("Action '%s' was commited!" % act_name)


func _register_action():
	pass
