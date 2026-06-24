extends Control
class_name DockManager

## Quản lý toàn bộ workspace nhiều panel (Canvas / Wiring / Code Editor...).
## Cây cấu trúc: root_container -> (DockLeaf) hoặc (HSplitContainer/VSplitContainer
## chứa 2 nhánh con, mỗi nhánh lại là DockLeaf hoặc Split...).

@export var root_container_path: NodePath
@export var dock_leaf_scene: PackedScene = preload("res://Scripts/Dock/DockLeaf.tscn")

## kind (String) -> Node thật trong scene (Canvas, Blocks, Wiring...).
## Đây là các node DUY NHẤT (không phải PackedScene) -> khi load lại layout,
## DockManager tái sử dụng lại đúng instance này, không tạo node mới.
var panel_nodes: Dictionary = {}   # kind -> Control
var panel_titles: Dictionary = {}  # kind -> String hiển thị trên tab

@onready var root_container: Control = get_node(root_container_path)

var _overlay: DockDropOverlay

const SAVE_PATH := "user://dock_layout.json"
const MIN_LEAF_SIZE := 120.0

func _ready() -> void:

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # thêm dòng này
	root_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay = DockDropOverlay.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	_overlay.top_level = true
	add_child(_overlay)

func create_leaf() -> DockLeaf:
	var leaf: DockLeaf = dock_leaf_scene.instantiate()
	leaf.dock_manager = self
	leaf.closed_empty.connect(_on_leaf_emptied)
	return leaf

## Gọi 1 LẦN cho mỗi panel (Canvas/Blocks/Wiring) ở _ready() của scene cha,
## TRƯỚC khi build layout mặc định hoặc load_layout().
## Tự gỡ node khỏi parent cũ (vd TabContainer cũ) để có thể đem vào DockLeaf.
func register_panel(kind: String, node: Control, title: String) -> void:
	panel_nodes[kind] = node
	panel_titles[kind] = title
	_track_order(kind)
	if node.get_parent():
		node.get_parent().remove_child(node)

## Mở 1 panel theo kind: nếu đang hiển thị ở leaf nào rồi -> focus tab đó,
## nếu chưa có -> mở mới cạnh leaf đang được truyền vào (hoặc tạo leaf đầu tiên).
func open_panel(kind: String, reference_leaf: DockLeaf = null, zone: String = "right") -> void:
	var existing := _find_leaf_with_kind(kind)
	if existing.leaf:
		existing.leaf._show_tab(existing.index)
		return
	var node: Control = panel_nodes.get(kind)
	if node == null:
		push_warning("DockManager: panel kind '%s' chưa register_panel()" % kind)
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	open_panel_beside(reference_leaf, node, panel_titles.get(kind, kind), kind, zone)

func _find_leaf_with_kind(kind: String) -> Dictionary:
	var stack: Array = [root_container]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is DockLeaf:
			for i in n.panels.size():
				if n.panels[i].get_meta("dock_kind", "") == kind:
					return {"leaf": n, "index": i}
		else:
			for c in n.get_children():
				stack.append(c)
	return {"leaf": null, "index": -1}

# ============================================================
# PRESET LAYOUT (kiểu Windows Snap / Google Sheets split view)
# Khác với free-drag 5 vùng ở trên: đây là sắp lại TOÀN BỘ panel
# đang mở vào 1 khung cố định, gọi 1 lần qua apply_preset().
# ============================================================

var _panel_order: Array[String] = []  # thứ tự kind đã register, dùng để chia đều

func _track_order(kind: String) -> void:
	if not _panel_order.has(kind):
		_panel_order.append(kind)

## preset: "two_columns" | "grid_four" | "three_pane"
## big_position (chỉ dùng cho "three_pane"): "left" hoặc "right" -> bên nào là ô lớn.
func apply_preset(preset: String, big_position: String = "right") -> void:
	var kinds: Array[String] = []
	for k in _panel_order:
		if panel_nodes.has(k):
			kinds.append(k)
	if kinds.is_empty():
		return

	for kind in panel_nodes:
		var node: Control = panel_nodes[kind]
		if node.get_parent():
			node.get_parent().remove_child(node)
	for c in root_container.get_children():
		root_container.remove_child(c)
		c.queue_free()

	var built: Control
	match preset:
		"two_columns":
			built = _build_n_column_layout(kinds, 2)
		"grid_four":
			built = _build_grid_four(kinds)
		"three_pane":
			built = _build_three_pane(kinds, big_position)
		_:
			push_warning("apply_preset: preset '%s' không tồn tại" % preset)
			return

	if built:
		root_container.add_child(built)

## Chia kinds đều vào n leaf cạnh nhau theo chiều ngang, mỗi leaf 50/50 (n=2,3...).
func _build_n_column_layout(kinds: Array[String], n: int) -> Control:
	var groups := _distribute(kinds, n)
	var leaves: Array[DockLeaf] = []
	for g in groups:
		leaves.append(_make_leaf_from_kinds(g))
	return _chain_horizontal(leaves)

## Lưới 2x2 bằng nhau: HSplit( VSplit(leaf0,leaf1), VSplit(leaf2,leaf3) )
func _build_grid_four(kinds: Array[String]) -> Control:
	var groups := _distribute(kinds, 4)
	var l0 := _make_leaf_from_kinds(groups[0])
	var l1 := _make_leaf_from_kinds(groups[1])
	var l2 := _make_leaf_from_kinds(groups[2])
	var l3 := _make_leaf_from_kinds(groups[3])

	var left_col := VSplitContainer.new()
	left_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_col.add_child(l0)
	left_col.add_child(l1)

	var right_col := VSplitContainer.new()
	right_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_col.add_child(l2)
	right_col.add_child(l3)

	var outer := HSplitContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_child(left_col)
	outer.add_child(right_col)
	return outer

## 3 ô: 1 ô lớn (~62%) + 2 ô nhỏ xếp dọc bên cạnh (~38%, chia đôi theo chiều cao).
func _build_three_pane(kinds: Array[String], big_position: String) -> Control:
	var groups := _distribute(kinds, 3)
	var big_leaf := _make_leaf_from_kinds(groups[0])
	var small_top := _make_leaf_from_kinds(groups[1])
	var small_bottom := _make_leaf_from_kinds(groups[2])

	var small_col := VSplitContainer.new()
	small_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	small_col.add_child(small_top)
	small_col.add_child(small_bottom)

	var outer := HSplitContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if big_position == "left":
		outer.add_child(big_leaf)
		outer.add_child(small_col)
	else:
		outer.add_child(small_col)
		outer.add_child(big_leaf)
	return outer

func _make_leaf_from_kinds(kinds: Array[String]) -> DockLeaf:
	var leaf := create_leaf()
	for kind in kinds:
		var node: Control = panel_nodes.get(kind)
		if node:
			if node.get_parent():
				node.get_parent().remove_child(node)
			leaf.add_panel(node, panel_titles.get(kind, kind), kind)
	return leaf

func _chain_horizontal(leaves: Array[DockLeaf]) -> Control:
	if leaves.size() == 1:
		return leaves[0]
	var outer := HSplitContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_child(leaves[0])
	outer.add_child(_chain_horizontal(leaves.slice(1)))
	return outer

## Chia mảng kinds thành n nhóm gần bằng nhau, nhóm rỗng vẫn giữ (leaf trống không add panel).
func _distribute(kinds: Array[String], n: int) -> Array:
	var groups: Array = []
	for i in n:
		groups.append([])
	for i in kinds.size():
		groups[i % n].append(kinds[i])
	return groups

## Gọi khi muốn mở 1 panel mới ngay từ code (không qua kéo-thả),
## ví dụ click nút "Open Wiring" -> mở thêm 1 leaf cạnh leaf hiện tại.
func open_panel_beside(reference_leaf: DockLeaf, panel: Control, title: String, kind: String, zone: String = "right") -> void:
	if reference_leaf == null:
		var leaf := create_leaf()
		leaf.add_panel(panel, title, kind)
		root_container.add_child(leaf)
		return
	_split_leaf(reference_leaf, zone, panel, title, kind)

# ---------------- OVERLAY ----------------
func show_drop_overlay(leaf: DockLeaf, at_position: Vector2) -> void:
	var r := leaf.get_global_rect()
	_overlay.global_position = r.position
	_overlay.size = r.size
	_overlay.visible = true
	_overlay.set_hover_zone(DockDropOverlay.zone_at(at_position, leaf.size))

func hide_drop_overlay() -> void:
	_overlay.visible = false

# ---------------- XỬ LÝ THẢ TAB ----------------
func handle_tab_drop(target_leaf: DockLeaf, at_position: Vector2, data: Dictionary) -> void:
	hide_drop_overlay()
	var zone := DockDropOverlay.zone_at(at_position, target_leaf.size)
	print("=== handle_tab_drop ===")
	print("zone: ", zone)
	print("source == target: ", data["source_leaf"] == target_leaf)
	print("source panels count: ", (data["source_leaf"] as DockLeaf).panels.size())
	var source_leaf: DockLeaf = data["source_leaf"]
	var panel: Control = data["panel"]
	var title: String = data["title"]
	var tab_index: int = data["tab_index"]
	var kind: String = panel.get_meta("dock_kind", "")

	# Không làm gì nếu cùng leaf + center, hoặc cùng leaf chỉ có 1 tab
	if source_leaf == target_leaf and zone == "center":
		return
	if source_leaf == target_leaf and source_leaf.panels.size() == 1:
		return

	# Tạm disconnect để tránh _on_leaf_emptied chạy giữa chừng
	if source_leaf.closed_empty.is_connected(_on_leaf_emptied):
		source_leaf.closed_empty.disconnect(_on_leaf_emptied)

	# Gỡ panel khỏi source trước
	source_leaf.stack.remove_child(panel)
	source_leaf.panels.remove_at(tab_index)
	source_leaf.tab_bar.remove_tab(tab_index)
	if source_leaf.tab_bar.tab_count > 0:
		source_leaf._show_tab(min(tab_index, source_leaf.tab_bar.tab_count - 1))

	var source_empty := source_leaf.panels.is_empty()

	if zone == "center":
		target_leaf.add_panel(panel, title, kind)
	else:
		_split_leaf(target_leaf, zone, panel, title, kind)

	# Reconnect rồi mới xử lý empty
	source_leaf.closed_empty.connect(_on_leaf_emptied)
	if source_empty:
		_on_leaf_emptied(source_leaf)

func _split_leaf(target_leaf: DockLeaf, zone: String, panel: Control, title: String, kind: String) -> void:
	var parent: Node = target_leaf.get_parent()
	var idx_in_parent := target_leaf.get_index()

	var new_leaf := create_leaf()
	new_leaf.add_panel(panel, title, kind)
	new_leaf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_leaf.size_flags_vertical = Control.SIZE_EXPAND_FILL
	target_leaf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_leaf.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Nếu zone là right/left nhưng parent đã là HSplitContainer
	# -> đổi thành top/bottom để tránh tạo 3 cột ngang
	var effective_zone := zone
	if (zone == "right" or zone == "left") and parent is HSplitContainer:
		effective_zone = "bottom" if zone == "right" else "top"

	var split: Container
	if effective_zone == "left" or effective_zone == "right":
		split = HSplitContainer.new()
	else:
		split = VSplitContainer.new()

	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL

	parent.remove_child(target_leaf)

	if effective_zone == "left" or effective_zone == "top":
		split.add_child(new_leaf)
		split.add_child(target_leaf)
	else:
		split.add_child(target_leaf)
		split.add_child(new_leaf)

	parent.add_child(split)
	parent.move_child(split, idx_in_parent)

# ---------------- DỌN LEAF RỖNG (khi kéo hết tab ra khỏi 1 ô) ----------------
func _on_leaf_emptied(leaf: DockLeaf) -> void:
	var parent := leaf.get_parent()

	if parent == root_container:
		leaf.queue_free()
		return

	var sibling: Node = null
	for c in parent.get_children():
		if c != leaf:
			sibling = c
			break

	if sibling == null:
		leaf.queue_free()
		parent.queue_free()
		return

	var grandparent := parent.get_parent()
	var idx_in_grandparent := parent.get_index()

	parent.remove_child(sibling)
	parent.remove_child(leaf)

	grandparent.add_child(sibling)
	grandparent.move_child(sibling, idx_in_grandparent)

	if sibling is Control:
		var s := sibling as Control
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# grandparent là root_container -> cần FULL_RECT
		if grandparent == root_container:
			s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	leaf.queue_free()
	parent.queue_free()

# ---------------- SAVE / LOAD LAYOUT ----------------
func save_layout(slot_name: String = "default") -> void:
	var root_child: Node = root_container.get_child(0) if root_container.get_child_count() > 0 else null
	var data := _serialize_node(root_child)

	var all_data: Dictionary = {}
	if FileAccess.file_exists(SAVE_PATH):
		var existing := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(existing.get_as_text())
		if parsed is Dictionary:
			all_data = parsed

	all_data[slot_name] = data
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(all_data, "\t"))

func load_layout(slot_name: String = "default") -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var all_data = JSON.parse_string(f.get_as_text())
	if not (all_data is Dictionary) or not all_data.has(slot_name):
		return false

	# QUAN TRỌNG: panel_nodes (Canvas/Blocks/Wiring) là node DUY NHẤT, không phải
	# bản instantiate. Phải gỡ chúng ra khỏi leaf cũ trước, nếu không leaf.queue_free()
	# sẽ free luôn các node thật này theo cây con.
	for kind in panel_nodes:
		var node: Control = panel_nodes[kind]
		if node.get_parent():
			node.get_parent().remove_child(node)

	for c in root_container.get_children():
		root_container.remove_child(c)
		c.queue_free()

	var built := _deserialize_node(all_data[slot_name])
	if built:
		root_container.add_child(built)
	return true

func _serialize_node(node: Node) -> Dictionary:
	if node == null:
		return {}
	if node is DockLeaf:
		var tabs := []
		for i in node.panels.size():
			tabs.append({
				"kind": node.panels[i].get_meta("dock_kind", ""),
				"title": node.tab_bar.get_tab_title(i),
			})
		return {"type": "leaf", "tabs": tabs, "active": node.tab_bar.current_tab}
	elif node is HSplitContainer or node is VSplitContainer:
		return {
			"type": "hsplit" if node is HSplitContainer else "vsplit",
			"offset": node.split_offset,
			"a": _serialize_node(node.get_child(0)),
			"b": _serialize_node(node.get_child(1)),
		}
	return {}

func _deserialize_node(data) -> Control:
	if not (data is Dictionary) or data.is_empty():
		return null

	if data["type"] == "leaf":
		var leaf := create_leaf()
		for tab in data["tabs"]:
			var kind: String = tab.get("kind", "")
			var node: Control = panel_nodes.get(kind)
			if node:
				if node.get_parent():
					node.get_parent().remove_child(node)
				leaf.add_panel(node, tab.get("title", panel_titles.get(kind, kind)), kind)
		if leaf.tab_bar.tab_count > 0:
			leaf.tab_bar.current_tab = clamp(data.get("active", 0), 0, leaf.tab_bar.tab_count - 1)
		return leaf

	var split: Container = HSplitContainer.new() if data["type"] == "hsplit" else VSplitContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var a := _deserialize_node(data.get("a"))
	var b := _deserialize_node(data.get("b"))
	if a:
		split.add_child(a)
	if b:
		split.add_child(b)
	split.split_offset = data.get("offset", 0)
	return split
