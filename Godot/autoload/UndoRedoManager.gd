extends Node

signal history_changed

const MAX_HISTORY := 200

var _ur := UndoRedo.new()
var _action_count := 0

func begin(action_name: String, merge_mode: int = UndoRedo.MERGE_DISABLE) -> void:
	_ur.create_action(action_name, merge_mode)

func add_do(target: Object, method: String, args: Array = []) -> void:
	_ur.add_do_method(_safe_call.bind(target, method, args))

func add_undo(target: Object, method: String, args: Array = []) -> void:
	_ur.add_undo_method(_safe_call.bind(target, method, args))

func _safe_call(target: Object, method: String, args: Array) -> void:
	if not is_instance_valid(target):
		return
	if not target.has_method(method):
		return
	target.callv(method, args)

# Chỉ dùng property version cho target chắc chắn không bị queue_free
# (VD: singleton panel), vì không có guard is_instance_valid ở đây.
func add_do_property(target: Object, prop: String, value) -> void:
	_ur.add_do_property(target, prop, value)

func add_undo_property(target: Object, prop: String, value) -> void:
	_ur.add_undo_property(target, prop, value)

func commit() -> void:
	_ur.commit_action()
	_action_count += 1
	history_changed.emit()
	if _action_count > MAX_HISTORY:
		_trim_history()

func _trim_history() -> void:
	# UndoRedo không có API trim, tạo mới để giải phóng bộ nhớ cũ
	_ur = UndoRedo.new()
	_action_count = 0

func undo() -> void:
	if _ur.has_undo():
		_ur.undo()
		history_changed.emit()

func redo() -> void:
	if _ur.has_redo():
		_ur.redo()
		history_changed.emit()

func can_undo() -> bool:
	return _ur.has_undo()

func can_redo() -> bool:
	return _ur.has_redo()

func clear_history() -> void:
	_ur = UndoRedo.new()
	_action_count = 0
	history_changed.emit()
