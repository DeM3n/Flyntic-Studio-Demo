
extends Panel
signal drag_started
signal drag_ended
signal value_changed(new_value)
var dragging = false
var drag_offset = Vector2.ZERO
var block_type = "" 
var value = "50" 
@onready var label: Label = $L
var input_field: LineEdit = null

# Stack drag: danh sách các block bên dưới sẽ đi theo
var _dragging_children: Array = []  # Array[{block, offset}]

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if has_node("Input"):
		input_field = $Input
		input_field.text = value
		input_field.text_submitted.connect(_on_value_submitted)
		input_field.focus_exited.connect(func(): _on_value_submitted(input_field.text))
		input_field.gui_input.connect(func(event): 
			if event is InputEventMouseButton: 
				accept_event()
		)

func _on_value_submitted(new_text):
	value = new_text
	value_changed.emit(value)

func _gui_input(event):
	if input_field and input_field.has_focus():
		return
	if has_node("input_bg"):
		var bg = get_node("input_bg")
		if bg.get_global_rect().has_point(get_global_mouse_position()):
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_local_mouse_position()
				z_index = 100
				# ── Thu thập tất cả block bên dưới trong stack ──
				_collect_stack_below()
				drag_started.emit()
				# Đưa block này và toàn bộ stack lên trên cùng (z-order)
				var p = get_parent()
				if p:
					p.move_child(self, p.get_child_count() - 1)
					for entry in _dragging_children:
						if is_instance_valid(entry.block):
							p.move_child(entry.block, p.get_child_count() - 1)
			else:
				dragging = false
				z_index = 0
				# Reset z_index cho các block con
				for entry in _dragging_children:
					if is_instance_valid(entry.block):
						entry.block.z_index = 0
				_dragging_children.clear()
				drag_ended.emit()

func _collect_stack_below():
	_dragging_children.clear()
	var p = get_parent()
	if not is_instance_valid(p):
		return
	
	# Tìm tất cả block bên dưới theo vị trí Y, theo thứ tự từ trên xuống
	var all_blocks = []
	for child in p.get_children():
		if child == self: continue
		if not "block_type" in child: continue
		if not is_instance_valid(child): continue
		all_blocks.append(child)
	
	# Build stack theo chain: tìm block ngay bên dưới, rồi block bên dưới block đó...
	var chain: Array = []
	var current = self
	var visited = {}
	visited[self.get_instance_id()] = true
	
	while true:
		var next = _find_direct_below(current, all_blocks, visited)
		if next == null:
			break
		visited[next.get_instance_id()] = true
		chain.append(next)
		current = next
	
	# Lưu offset so với block đang drag (self)
	for b in chain:
		_dragging_children.append({
			"block": b,
			"offset": b.position - self.position  # relative offset
		})
		b.z_index = 99  # Nổi lên nhưng dưới block đang drag

func _find_direct_below(ref_block, all_blocks: Array, visited: Dictionary):
	var expected_y = ref_block.position.y + ref_block.custom_minimum_size.y
	var best = null
	var best_dist = 25.0  # tolerance pixel
	for b in all_blocks:
		if not is_instance_valid(b): continue
		if visited.has(b.get_instance_id()): continue
		var dy = abs(b.position.y - expected_y)
		var dx = abs(b.position.x - ref_block.position.x)
		if dy < best_dist and dx < 30.0:
			best_dist = dy
			best = b
	return best

func _process(_delta):
	if dragging:
		var target_pos = get_global_mouse_position() - drag_offset
		var new_pos = Vector2.ZERO
		if get_parent() != null:
			new_pos = get_parent().get_global_transform().affine_inverse() * target_pos
		else:
			new_pos = target_pos
		
		position = new_pos
		
		# Di chuyển tất cả block trong stack theo đúng offset
		for entry in _dragging_children:
			if is_instance_valid(entry.block):
				entry.block.position = new_pos + entry.offset
