extends MenuButton
class_name EditMenuController

@export var dock_manager_path: NodePath

var dock_manager: Node

const IDX_UNDO := 0
const IDX_REDO := 1
const IDX_COPY := 2
const IDX_PASTE := 3
const IDX_DELETE := 4
const IDX_SELECT_ALL := 5

func _ensure_refs() -> void:
	if dock_manager == null and dock_manager_path != NodePath():
		dock_manager = get_node(dock_manager_path)
	#print(">>> EditMenuController dock_manager = ", dock_manager)

func _ready() -> void:
	_ensure_refs()
	_setup_edit_menu()
	UndoRedoManager.history_changed.connect(_update_menu_state)
	_update_menu_state()

func _setup_edit_menu() -> void:
	text = "Edit"
	var popup = get_popup()
	popup.add_theme_font_size_override("font_size", 12)
	popup.clear()
	popup.add_item("Undo", IDX_UNDO, KEY_MASK_CTRL | KEY_Z)
	popup.add_item("Redo", IDX_REDO, KEY_MASK_CTRL | KEY_Y)
	popup.add_separator()
	popup.add_item("Copy", IDX_COPY, KEY_MASK_CTRL | KEY_C)
	popup.add_item("Paste", IDX_PASTE, KEY_MASK_CTRL | KEY_V)
	popup.add_item("Delete", IDX_DELETE, KEY_DELETE)
	popup.add_separator()
	popup.add_item("Select All", IDX_SELECT_ALL, KEY_MASK_CTRL | KEY_A)

	if popup.id_pressed.is_connected(_on_edit_id_pressed):
		popup.id_pressed.disconnect(_on_edit_id_pressed)
	popup.id_pressed.connect(_on_edit_id_pressed)

	if not popup.about_to_popup.is_connected(_update_menu_state):
		popup.about_to_popup.connect(_update_menu_state)

func _on_edit_id_pressed(id: int) -> void:
	match id:
		IDX_UNDO: UndoRedoManager.undo()
		IDX_REDO: UndoRedoManager.redo()
		IDX_COPY: _dispatch("copy_selected")
		IDX_PASTE: _dispatch("paste")
		IDX_DELETE: _dispatch("delete_selected")
		IDX_SELECT_ALL: _dispatch("select_all")

func _update_menu_state() -> void:
	var popup = get_popup()
	popup.set_item_disabled(popup.get_item_index(IDX_UNDO), not UndoRedoManager.can_undo())
	popup.set_item_disabled(popup.get_item_index(IDX_REDO), not UndoRedoManager.can_redo())

func _get_active_panel() -> Node:
	_ensure_refs()
	if dock_manager and dock_manager.has_method("get_active_panel"):
		return dock_manager.get_active_panel()
	return null

func _dispatch(method_name: String) -> void:
	var panel = _get_active_panel()
	print(">>> dispatch: ", method_name, " -> panel = ", panel)
	if panel == null or not is_instance_valid(panel):
		return
	if panel.has_method(method_name):
		panel.call(method_name)
	else:
		print(">>> panel không có method: ", method_name)

# ---------------- GLOBAL SHORTCUT (hoạt động cả khi menu Edit đang đóng) ----------------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	var ctrl := key_event.ctrl_pressed
	match event.keycode:
		KEY_Z:
			if ctrl:
				UndoRedoManager.undo()
				get_viewport().set_input_as_handled()
		KEY_Y:
			if ctrl:
				UndoRedoManager.redo()
				get_viewport().set_input_as_handled()
		KEY_C:
			if ctrl:
				_dispatch("copy_selected")
				get_viewport().set_input_as_handled()
		KEY_V:
			if ctrl:
				_dispatch("paste")
				get_viewport().set_input_as_handled()
		KEY_A:
			if ctrl:
				_dispatch("select_all")
				get_viewport().set_input_as_handled()
		KEY_DELETE:
			_dispatch("delete_selected")
			get_viewport().set_input_as_handled()
