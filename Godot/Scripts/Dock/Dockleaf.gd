extends Control
class_name DockLeaf

signal closed_empty(leaf: DockLeaf)

var tab_bar: TabBar
var stack: Control
var dock_manager: Node = null
var panels: Array[Control] = []

const DRAG_PREVIEW_SIZE := Vector2(160, 36)

var _drag_tab_idx: int = -1
var _drag_start_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _preview_node: Control = null

func _ready() -> void:
	_ensure_refs()
	gui_input.connect(_on_leaf_gui_input)


func _ensure_refs() -> void:
	if tab_bar == null:
		tab_bar = $VBox/TabBar
		stack = $VBox/Stack
		tab_bar.tab_clicked.connect(_on_tab_clicked)
		tab_bar.gui_input.connect(_on_tabbar_gui_input)

func add_panel(panel: Control, title: String, kind: String = "") -> void:
	_ensure_refs()
	if kind != "":
		panel.set_meta("dock_kind", kind)
	panels.append(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	stack.add_child(panel)
	tab_bar.add_tab(title)
	_show_tab(tab_bar.tab_count - 1)
	_notify_active()

func remove_tab(idx: int) -> void:
	var panel := panels[idx]
	stack.remove_child(panel)
	panels.remove_at(idx)
	tab_bar.remove_tab(idx)
	if tab_bar.tab_count == 0:
		closed_empty.emit(self)
	else:
		_show_tab(min(idx, tab_bar.tab_count - 1))

func _show_tab(idx: int) -> void:
	for i in panels.size():
		panels[i].visible = (i == idx)
	if tab_bar.tab_count > 0:
		tab_bar.current_tab = idx

func _on_tab_clicked(idx: int) -> void:
	_show_tab(idx)
	_notify_active()

# ---------------- KÉO TAB ----------------
func _on_tabbar_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		var idx := tab_bar.get_tab_idx_at_point(event.position)
		if idx >= 0:
			_drag_tab_idx = idx
			_drag_start_pos = tab_bar.get_global_mouse_position()
			_is_dragging = false
	# KHÔNG xử lý release ở đây — để _input xử lý

func _input(event: InputEvent) -> void:
	if _drag_tab_idx < 0:
		return

	if event is InputEventMouseMotion:
		var gpos := get_global_mouse_position()
		if not _is_dragging:
			if gpos.distance_to(_drag_start_pos) > 8.0:
				_is_dragging = true
				_create_preview()
		if _is_dragging:
			_update_preview(gpos)
			_update_overlay(gpos)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var was_dragging := _is_dragging
			# Reset state TRƯỚC khi gọi _end_drag để tránh gọi 2 lần
			var saved_idx := _drag_tab_idx
			_drag_tab_idx = -1
			_is_dragging = false
			if was_dragging:
				_end_drag(saved_idx)
			_cleanup_preview()

func _create_preview() -> void:
	if _preview_node:
		return
	_preview_node = PanelContainer.new()
	_preview_node.custom_minimum_size = DRAG_PREVIEW_SIZE
	_preview_node.top_level = true
	_preview_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.text = tab_bar.get_tab_title(_drag_tab_idx)
	_preview_node.add_child(lbl)
	add_child(_preview_node)

func _cleanup_preview() -> void:
	if _preview_node:
		_preview_node.queue_free()
		_preview_node = null
	if dock_manager:
		dock_manager.hide_drop_overlay()

func _update_preview(gpos: Vector2) -> void:
	if _preview_node:
		_preview_node.global_position = gpos + Vector2(8, 8)

func _update_overlay(gpos: Vector2) -> void:
	if not dock_manager:
		return
	var target := _find_leaf_at(gpos)
	if target:
		var local_pos: Vector2 = gpos - target.get_global_rect().position
		dock_manager.show_drop_overlay(target, local_pos)
	else:
		dock_manager.hide_drop_overlay()

func _end_drag(idx: int) -> void:
	_cleanup_preview()

	if not dock_manager:
		return

	# Validate idx vẫn còn hợp lệ
	if idx < 0 or idx >= panels.size():
		return

	var gpos := get_global_mouse_position()
	var target := _find_leaf_at(gpos)
	if target == null:
		return

	var local_pos: Vector2 = gpos - target.get_global_rect().position
	var data := {
		"type": "dock_tab",
		"source_leaf": self,
		"tab_index": idx,
		"panel": panels[idx],
		"title": tab_bar.get_tab_title(idx),
	}
	dock_manager.handle_tab_drop(target, local_pos, data)

func _find_leaf_at(gpos: Vector2) -> DockLeaf:
	if not dock_manager:
		return null
	var stack_search: Array = [dock_manager.root_container]
	while not stack_search.is_empty():
		var n: Node = stack_search.pop_back()
		if n is DockLeaf and n != self:
			if n.get_global_rect().has_point(gpos):
				return n
		for c in n.get_children():
			stack_search.append(c)
	if get_global_rect().has_point(gpos):
		return self
	return null
func _notify_active() -> void:
	if dock_manager and dock_manager.has_method("set_active_leaf"):
		dock_manager.set_active_leaf(self)
func _on_leaf_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_notify_active()
