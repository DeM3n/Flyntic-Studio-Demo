extends Control

# ─────────────────────────────────────────────
#  Wiring2D.gd  —  Flyntic Studio
#  2D circuit wiring panel (Arduino-style)
#  v2: rotation + zoom support
# ─────────────────────────────────────────────

const PORT_RADIUS     := 9.0
const PORT_RADIUS_BIG := 14.0   # FC bus connector
const SNAP_DIST       := 18.0
const GRID            := 20
const MOTOR_RADIUS    := 52.0   # Motor drawn as circle

const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0
const ZOOM_STEP := 0.12   # multiplicative step per wheel tick

# ── Component definitions ──────────────────────────────────────────
const COMP_DEFS := {
	"Battery": {
		"category": "POWER",
		"color": Color(0.85, 0.55, 0.05),
		"size": Vector2(160, 90),
		"shape": "rect",
		"ports": [
			{"name":"BAT+","side":"left","offset":0.35,"type":"power_pos","label":"+","color":Color(0.88,0.22,0.22),"big":false},
			{"name":"BAT-","side":"left","offset":0.65,"type":"power_neg","label":"–","color":Color(0.45,0.45,0.45),"big":false},
		]
	},
	"Motor": {
		"category": "MOTORS",
		"color": Color(0.75, 0.22, 0.22),
		"size": Vector2(MOTOR_RADIUS*2, MOTOR_RADIUS*2),
		"shape": "circle",
		"ports": [
			{"name":"PHASE","side":"left","offset":0.50,"type":"motor_phase","label":"~","color":Color(0.88,0.45,0.10),"big":true},
		]
	},
	"4-in-1 ESC": {
	"category": "ELECTRONICS",
	"color": Color(0.15, 0.38, 0.72),
	"size": Vector2(200, 200),  # Đổi thành hình vuông cho dễ bố trí 4 góc
	"shape": "rect",
	"ports": [
		# 4 góc — mỗi góc 1 motor output
		# Góc trên-trái
		{"name":"M1","side":"left","offset":0.18,"type":"esc_out","label":"M1","color":Color(0.88,0.45,0.10),"big":false},
		# Góc dưới-trái
		{"name":"M2","side":"left","offset":0.82,"type":"esc_out","label":"M2","color":Color(0.88,0.45,0.10),"big":false},
		# Góc trên-phải
		{"name":"M3","side":"right","offset":0.18,"type":"esc_out","label":"M3","color":Color(0.88,0.45,0.10),"big":false},
		# Góc dưới-phải
		{"name":"M4","side":"right","offset":0.82,"type":"esc_out","label":"M4","color":Color(0.88,0.45,0.10),"big":false},
		# ── Cạnh trên — CHỈ Battery ────────────────────────
		{"name":"PWR+","side":"top","offset":0.25,"type":"power_pos","label":"+","color":Color(0.88,0.22,0.22),"big":false},
		{"name":"PWR-","side":"top","offset":0.50,"type":"power_neg","label":"–","color":Color(0.45,0.45,0.45),"big":false},
		{"name":"GND","side":"top","offset":0.75,"type":"ground","label":"G","color":Color(0.35,0.35,0.35),"big":false},

		# ── Cạnh dưới — TẤT CẢ tín hiệu đi về FC ───────────
		{"name":"5V","side":"bottom","offset":0.12,"type":"power_5v","label":"5V","color":Color(0.95,0.55,0.15),"big":false},
		{"name":"VBAT","side":"bottom","offset":0.28,"type":"voltage_sense","label":"VBAT","color":Color(0.65,0.35,0.78),"big":false},
		{"name":"FC_BUS","side":"bottom","offset":0.50,"type":"signal_out","label":"FC","color":Color(0.22,0.80,0.55),"big":true,"connector_style":"wide_inset"},
		{"name":"CURR","side":"bottom","offset":0.72,"type":"current_sense","label":"CURR","color":Color(0.92,0.85,0.25),"big":false},
		{"name":"TLM","side":"bottom","offset":0.88,"type":"telemetry","label":"TLM","color":Color(0.35,0.65,0.92),"big":false},
	]
},
	"ESC (Single)": {
		"category": "ELECTRONICS",
		"color": Color(0.20, 0.28, 0.65),
		"size": Vector2(140, 100),
		"shape": "rect",
		"ports": [
			{"name":"IN+","side":"left","offset":0.30,"type":"power_pos","label":"+","color":Color(0.88,0.22,0.22),"big":false},
			{"name":"IN-","side":"left","offset":0.70,"type":"power_neg","label":"–","color":Color(0.45,0.45,0.45),"big":false},
			{"name":"OUT","side":"right","offset":0.50,"type":"esc_out","label":"M","color":Color(0.88,0.45,0.10),"big":true},
			{"name":"SIG","side":"bottom","offset":0.50,"type":"signal_in","label":"S","color":Color(0.22,0.80,0.55),"big":false},
		]
	},
	"Flight Controller": {
		"category": "ELECTRONICS",
		"color": Color(0.08, 0.50, 0.38),
		"size": Vector2(180, 180),
		"shape": "rect",
		"ports": [
		# ── Cạnh dưới — dùng khi đấu 4 ESC rời (không dùng 4-in-1) ─
		{"name":"S1","side":"bottom","offset":0.20,"type":"pwm_out","label":"S1","color":Color(0.92,0.72,0.10),"big":false},
		{"name":"S2","side":"bottom","offset":0.36,"type":"pwm_out","label":"S2","color":Color(0.92,0.72,0.10),"big":false},
		{"name":"S3","side":"bottom","offset":0.52,"type":"pwm_out","label":"S3","color":Color(0.92,0.72,0.10),"big":false},
		{"name":"S4","side":"bottom","offset":0.68,"type":"pwm_out","label":"S4","color":Color(0.92,0.72,0.10),"big":false},
		{"name":"GND","side":"bottom","offset":0.86,"type":"ground","label":"G","color":Color(0.35,0.35,0.35),"big":false},

		# ── Cạnh trên — cụm khớp thẳng hàng với ESC (4-in-1) ─────
		{"name":"5V_IN","side":"top","offset":0.12,"type":"power_5v_in","label":"5V","color":Color(0.95,0.55,0.15),"big":false},
		{"name":"VBAT_IN","side":"top","offset":0.28,"type":"voltage_sense_in","label":"VBAT","color":Color(0.65,0.35,0.78),"big":false},
		{"name":"ESC_BUS","side":"top","offset":0.50,"type":"signal_in","label":"ESC","color":Color(0.22,0.80,0.55),"big":true,"connector_style":"wide_inset"},
		{"name":"CURR_IN","side":"top","offset":0.72,"type":"current_sense_in","label":"CURR","color":Color(0.92,0.85,0.25),"big":false},
		{"name":"TLM_IN","side":"top","offset":0.88,"type":"telemetry_in","label":"TLM","color":Color(0.35,0.65,0.92),"big":false},
		]
	},
}

const COMPATIBLE := [
	["power_pos",  "power_pos"],
	["power_neg",  "power_neg"],
	["ground",     "ground"],
	["esc_out",    "motor_phase"],
	["signal_out", "signal_in"],
	["pwm_out",    "signal_in"],
	##moi
	["power_5v",       "power_5v_in"],       # ESC (BEC out) → FC (nguồn vào)
	["voltage_sense",  "voltage_sense_in"],  # ESC → FC (đọc áp pin)
	["current_sense",  "current_sense_in"],  # ESC → FC (đọc dòng điện)
	["telemetry",      "telemetry_in"],      # ESC → FC (RPM/nhiệt độ)
]

# Runtime state
var canvas_components: Array[Dictionary] = []
var connections: Array[Dictionary]       = []
var drag_comp: Dictionary  = {}
var drag_offset: Vector2   = Vector2.ZERO
var wire_from: Dictionary  = {}
var wire_active            := false
var wire_cur_pos: Vector2  = Vector2.ZERO
var uid_counter            := 0
var wire_tip_text          := ""
var wire_tip_pos           := Vector2.ZERO
var wire_tip_timer         := 0.0

# Context menu state
var ctx_menu: PopupMenu    = null
var ctx_uid                := -1

# Panning
var pan_offset: Vector2    = Vector2.ZERO
var panning                := false
var pan_start: Vector2     = Vector2.ZERO

# Zoom
var zoom_level: float      = 1.0
var zoom_center: Vector2   = Vector2.ZERO   # canvas-space pivot for zoom

# Selection / rotation toolbar
var selected_uid           := -1
var rot_toolbar_rect: Rect2 = Rect2()       # screen rect of the toolbar (for hit-test)

# UI refs
var sidebar: Control       = null
var canvas: Control        = null
var cat_state: Dictionary  = {}
# Bend points
const BEND_RADIUS := 7.0
var drag_bend: Dictionary = {}   # {conn_idx, pt_idx}
var hovered_wire: int = -1   
var _pending_delete_wire: int = -1
# Thay vì dùng wire_tip_timer cho lỗi
var persistent_error: Dictionary = {}  # { text: String, screen_pos: Vector2, conn_idx: int }
# Box selection
var box_selecting    : bool    = false
var box_start        : Vector2 = Vector2.ZERO
var box_end          : Vector2 = Vector2.ZERO
var selected_uids    : Array   = []   # multi-select list

# Multi-drag
var multi_dragging   : bool    = false
var multi_drag_start : Vector2 = Vector2.ZERO   # screen pos khi bắt đầu drag
var multi_drag_origins : Dictionary = {}         # uid → world pos ban đầu
var _wiring_help_layer: CanvasLayer = null
# ─────────────────────────────── INIT ─────────────────────────────
func _ready():
	name = "Wiring"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_build_context_menu()

func _build_ui():
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	# ── Sidebar ──────────────────────────────────────────────────────
	sidebar = Panel.new()
	sidebar.custom_minimum_size = Vector2(165, 0)
	var sb_style = StyleBoxFlat.new()
	sb_style.bg_color = Color(0.12, 0.12, 0.14)
	sb_style.border_color = Color(0.22, 0.22, 0.25)
	sb_style.border_width_right = 1
	sidebar.add_theme_stylebox_override("panel", sb_style)
	hbox.add_child(sidebar)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)

	var sv = VBoxContainer.new()
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_theme_constant_override("separation", 0)
	scroll.add_child(sv)
	#var hdr = Label.new()
	#hdr.text = "  COMPONENTS"
	#hdr.add_theme_font_size_override("font_size", 10)
	#hdr.add_theme_color_override("font_color", Color(0.42, 0.42, 0.50))
	#hdr.custom_minimum_size = Vector2(0, 38)
	#hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	#sv.add_child(hdr)
	var hdr_row = HBoxContainer.new()
	hdr_row.custom_minimum_size = Vector2(0, 38)
	sv.add_child(hdr_row)

	var hdr = Label.new()
	hdr.text = "  COMPONENTS"
	hdr.add_theme_font_size_override("font_size", 10)
	hdr.add_theme_color_override("font_color", Color(0.42, 0.42, 0.50))
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr_row.add_child(hdr)

	var help_btn = Button.new()
	help_btn.text = "?"
	help_btn.custom_minimum_size = Vector2(24, 18)
	help_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	help_btn.tooltip_text = "Wiring guide"
	help_btn.focus_mode = Control.FOCUS_NONE
	var help_style = StyleBoxFlat.new()
	help_style.bg_color = Color(0.22, 0.22, 0.26)
	help_style.set_corner_radius_all(11)
	help_btn.add_theme_stylebox_override("normal", help_style)
	help_btn.add_theme_font_size_override("font_size", 12)
	help_btn.pressed.connect(_open_wiring_help)
	hdr_row.add_child(help_btn)

	var hdr_pad = Control.new()
	hdr_pad.custom_minimum_size = Vector2(8, 0)
	hdr_row.add_child(hdr_pad)
	var div = Panel.new()
	div.custom_minimum_size = Vector2(0, 1)
	var div_sb = StyleBoxFlat.new()
	div_sb.bg_color = Color(0.22, 0.22, 0.25)
	div.add_theme_stylebox_override("panel", div_sb)
	sv.add_child(div)

	var categories: Dictionary = {}
	for cn in COMP_DEFS:
		var cat = COMP_DEFS[cn].get("category", "OTHER")
		if not categories.has(cat): categories[cat] = []
		categories[cat].append(cn)

	for cat in categories:
		cat_state[cat] = true
		_build_category(sv, cat, categories[cat])

	# ── Canvas ───────────────────────────────────────────────────────
	canvas = Control.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	canvas.clip_contents         = true
	hbox.add_child(canvas)
	canvas.draw.connect(_draw_canvas)
	canvas.gui_input.connect(_canvas_input)

func _build_category(parent: VBoxContainer, cat: String, items: Array):
	var btn = Button.new()
	btn.text = "  ▾   " + cat
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	btn.custom_minimum_size = Vector2(0, 32)
	var bsb = StyleBoxFlat.new()
	bsb.bg_color = Color(0.14, 0.14, 0.16)
	bsb.content_margin_left = 12
	bsb.content_margin_top = 2
	bsb.content_margin_bottom = 2
	var bsb_hover = StyleBoxFlat.new()
	bsb_hover.bg_color = Color(0.18, 0.18, 0.21)
	bsb_hover.content_margin_left = 12
	for st in ["normal","pressed"]:
		btn.add_theme_stylebox_override(st, bsb)
	btn.add_theme_stylebox_override("hover", bsb_hover)
	parent.add_child(btn)

	var box = VBoxContainer.new()
	box.name = "Cat_" + cat
	box.add_theme_constant_override("separation", 3)
	parent.add_child(box)

	for cn in items:
		_build_sidebar_item(box, cn)

	btn.pressed.connect(func():
		cat_state[cat] = !cat_state[cat]
		box.visible = cat_state[cat]
		btn.text = ("▾  " if cat_state[cat] else "▸  ") + cat
	)

func _build_sidebar_item(parent: VBoxContainer, comp_name: String):
	var cdef = COMP_DEFS[comp_name]
	var item = Panel.new()
	item.custom_minimum_size = Vector2(0, 46)
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


	var isb = StyleBoxFlat.new()
	isb.bg_color = cdef.color.darkened(0.58)
	isb.border_color = cdef.color.lightened(0.05)
	isb.border_width_left = 4
	isb.corner_radius_top_right = 5
	isb.corner_radius_bottom_right = 5
	isb.content_margin_left = 14
	isb.content_margin_right = 8
	isb.content_margin_top = 4
	isb.content_margin_bottom = 4
	var isb_hover = isb.duplicate()
	isb_hover.bg_color = cdef.color.darkened(0.38)
	isb_hover.border_color = cdef.color.lightened(0.25)
	item.add_theme_stylebox_override("panel", isb)

	var lbl = Label.new()
	lbl.text = comp_name
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 14
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(lbl)

	# Hover effect
	item.mouse_entered.connect(func():
		item.add_theme_stylebox_override("panel", isb_hover))
	item.mouse_exited.connect(func():
		item.add_theme_stylebox_override("panel", isb))

	parent.add_child(item)

	item.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_spawn_component(comp_name, canvas.size * 0.5)
	)

func _build_context_menu():
	ctx_menu = PopupMenu.new()
	ctx_menu.add_item("Delete component", 0)
	ctx_menu.add_separator()
	ctx_menu.add_item("Disconnect all wires", 1)
	ctx_menu.add_separator()
	ctx_menu.add_item("Rotate 90° CW", 2)
	ctx_menu.add_item("Reset rotation", 3)
	add_child(ctx_menu)
	ctx_menu.id_pressed.connect(_on_ctx_menu)
	wire_ctx_menu = PopupMenu.new()
	wire_ctx_menu.add_item("🗑  Delete wire", 0)
	add_child(wire_ctx_menu)
	wire_ctx_menu.id_pressed.connect(_on_wire_ctx_menu)


func _on_ctx_menu(id: int):
	match id:
		0: _delete_component(ctx_uid)
		1: _disconnect_all(ctx_uid)
		2: _rotate_component(ctx_uid, 90)
		3: _rotate_component_to(ctx_uid, 0)

# ─────────────────────────────── SPAWN ────────────────────────────
func _spawn_component(comp_name: String, pos: Vector2):
	var cdef = COMP_DEFS[comp_name]
	uid_counter += 1
	var entry = {
		"uid":          uid_counter,
		"name":         comp_name,
		"pos":          _snap_to_grid(_screen_to_world(pos) - cdef.size * 0.5),
		"size":         cdef.size,
		"color":        cdef.color,
		"shape":        cdef.get("shape", "rect"),
		"ports":        cdef.ports.duplicate(true),
		"selected":     false,
		"rotation_deg": 0,
	}
	canvas_components.append(entry)
	canvas.queue_redraw()

# ─────────────────────────────── COORD HELPERS ────────────────────
# World space = component space (pan & zoom applied by draw transform)
# Screen space = raw canvas pixel position

func _world_to_screen(world_pos: Vector2) -> Vector2:
	return world_pos * zoom_level + pan_offset

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - pan_offset) / zoom_level

# ─────────────────────────────── ROTATION HELPERS ─────────────────
# Rotate a Vector2 by degrees around origin
func _rotate_vec(v: Vector2, deg: float) -> Vector2:
	var rad = deg_to_rad(deg)
	return Vector2(
		v.x * cos(rad) - v.y * sin(rad),
		v.x * sin(rad) + v.y * cos(rad)
	)

# Effective side of a port after rotation (for label placement)
func _rotated_side(side: String, rot_deg: int) -> String:
	const SIDES = ["top", "right", "bottom", "left"]
	var idx = SIDES.find(side)
	if idx == -1: return side
	var steps = (rot_deg / 90) % 4
	return SIDES[(idx + steps + 4) % 4]

# ─────────────────────────────── DRAW ─────────────────────────────
func _draw_canvas():
	var cv = canvas
	var sz = cv.size

	# Background
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.09, 0.09, 0.11))

	# Grid dots — account for pan AND zoom
	var gc  = Color(0.20, 0.20, 0.23, 0.8)
	var gs  = GRID * zoom_level
	var ox  = fmod(pan_offset.x, gs)
	var oy  = fmod(pan_offset.y, gs)
	var xi  = ox
	while xi < sz.x:
		var yi = oy
		while yi < sz.y:
			cv.draw_rect(Rect2(xi - 1, yi - 1, 2, 2), gc)
			yi += gs
		xi += gs

	# Apply zoom+pan transform for all world-space drawing
	cv.draw_set_transform(pan_offset, 0.0, Vector2(zoom_level, zoom_level))

	# Connections
	for i in range(connections.size()):
		var conn = connections[i]
		var fp = _port_world_pos(conn.from_comp, conn.from_port)
		var tp = _port_world_pos(conn.to_comp,   conn.to_port)
		var wc = _wire_color(conn.from_port.get("type",""))
		if not conn.get("valid", true): wc = Color(0.88, 0.22, 0.22)
		_draw_wire(fp, tp, wc, conn.get("bend_points", []), i)

	# Live wire
	if wire_active and not wire_from.is_empty():
		var fp = _port_world_pos(wire_from.comp, wire_from.port)
		var live_world = _screen_to_world(wire_cur_pos)
		_draw_wire(fp, live_world, _wire_color(wire_from.port.get("type","")))

	# Components
	for comp in canvas_components:
		if comp.get("shape","rect") == "circle":
			_draw_motor(comp)
		else:
			_draw_component(comp)

	# Reset transform before drawing screen-space UI overlays
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# ── Box selection overlay ──────────────────────────────────────────
	if box_selecting:
		var r = Rect2(box_start, box_end - box_start).abs()
		cv.draw_rect(r, Color(0.3, 0.6, 1.0, 0.15), true)
		cv.draw_rect(r, Color(0.3, 0.6, 1.0, 0.8),  false)
	# Rotation toolbar for selected component
	var sel = _get_selected_comp()
	if sel.size() > 0:
		_draw_rotation_toolbar(sel)
	# Tooltip
	if persistent_error.size() > 0:
		var msg = persistent_error.text
		var pos = persistent_error.screen_pos
		var tp_w = max(len(msg) * 8.0 + 30, 160.0)
		var tp_rect = Rect2(pos + Vector2(14, -42), Vector2(tp_w, 32))
	
		cv.draw_rect(tp_rect, Color(0.18, 0.06, 0.06, 0.97), true)
		cv.draw_rect(tp_rect, Color(0.95, 0.25, 0.25, 0.95), false, 2.0)
		cv.draw_string(ThemeDB.fallback_font, pos + Vector2(22, -20),
		msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.7, 0.7))
	else:
	# Tooltip bình thường (nếu có)
		if wire_tip_text != "" and wire_tip_timer > 0:
			# ... code tooltip cũ của bạn giữ nguyên
			var tp_w = max(len(wire_tip_text) * 7.5 + 20, 130.0)
			var tp_rect = Rect2(wire_tip_pos + Vector2(14, -36), Vector2(tp_w, 26))
			cv.draw_rect(tp_rect, Color(0.12, 0.08, 0.08, 0.96), true)
			cv.draw_rect(tp_rect, Color(0.88, 0.22, 0.22, 0.9), false, 1.5)
			cv.draw_string(ThemeDB.fallback_font, wire_tip_pos + Vector2(22, -18),
			wire_tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.65, 0.65))
	# Zoom indicator (bottom-right, fades out)
	
	_draw_zoom_indicator()

# ── Rotation toolbar ───────────────────────────────────────────────
const ROT_BTN_W  := 54.0
const ROT_BTN_H  := 26.0
const ROT_BTN_GAP := 0.0
# Single rotate CW button
const ROT_BUTTONS := [
	["↻ 90°", 90],
]

func _draw_rotation_toolbar(comp: Dictionary):
	var cv     = canvas
	# Place toolbar above the component's screen-space bounding box
	var comp_screen_center = _world_to_screen(_comp_world_center(comp))
	var total_w = ROT_BUTTONS.size() * (ROT_BTN_W + ROT_BTN_GAP) - ROT_BTN_GAP + 16
	var tx = comp_screen_center.x - total_w * 0.5
	var ty = _comp_screen_top(comp) - ROT_BTN_H - 10

	# Clamp to canvas
	tx = clamp(tx, 4, canvas.size.x - total_w - 4)
	ty = clamp(ty, 4, canvas.size.y - ROT_BTN_H - 4)

	# Background pill
	var bg_rect = Rect2(tx - 4, ty - 4, total_w, ROT_BTN_H + 8)
	cv.draw_rect(bg_rect, Color(0.10, 0.10, 0.13, 0.95), true)
	cv.draw_rect(bg_rect, Color(0.35, 0.35, 0.40, 0.9), false, 1.2)

	# Rotation label
	var rot_label = "rot: %d°" % comp.get("rotation_deg", 0)
	cv.draw_string(ThemeDB.fallback_font,
		Vector2(tx + total_w - 4, ty + 14),
		rot_label, HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, Color(0.55, 0.55, 0.60))

	# Buttons
	var bx = tx + 4
	var btn_rects: Array = []
	for i in range(ROT_BUTTONS.size()):
		var binfo = ROT_BUTTONS[i]
		var brect = Rect2(bx, ty, ROT_BTN_W, ROT_BTN_H)
		btn_rects.append(brect)

		var hovered = brect.has_point(canvas.get_local_mouse_position())
		var bg_col  = Color(0.22, 0.50, 0.88, 0.85) if hovered else Color(0.18, 0.20, 0.25, 0.9)
		cv.draw_rect(brect, bg_col, true)
		cv.draw_rect(brect, Color(0.35, 0.55, 0.88, 0.7) if hovered else Color(0.28, 0.28, 0.35), false, 1.0)
		cv.draw_string(ThemeDB.fallback_font,
			Vector2(bx + ROT_BTN_W * 0.5 - 12, ty + 16),
			binfo[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color(1,1,1) if hovered else Color(0.82, 0.82, 0.88))
		bx += ROT_BTN_W + ROT_BTN_GAP

	rot_toolbar_rect = Rect2(tx - 4, ty - 4, total_w, ROT_BTN_H + 8)

func _comp_world_center(comp: Dictionary) -> Vector2:
	return comp.pos + comp.size * 0.5

func _comp_screen_top(comp: Dictionary) -> float:
	# Approximate top edge of the (possibly rotated) component in screen space
	var ctr = _world_to_screen(_comp_world_center(comp))
	var half_h = comp.size.y * 0.5 * zoom_level
	var half_w = comp.size.x * 0.5 * zoom_level
	return ctr.y - max(half_h, half_w) - 4

# ── Zoom indicator ─────────────────────────────────────────────────
var _zoom_display_timer := 0.0

func _draw_zoom_indicator():
	if _zoom_display_timer <= 0.0: return
	var cv  = canvas
	var alpha = clamp(_zoom_display_timer / 1.0, 0.0, 1.0)
	var txt  = "%.0f%%" % (zoom_level * 100)
	var pos  = canvas.size - Vector2(60, 28)
	cv.draw_string(ThemeDB.fallback_font, pos, txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color(0.75, 0.75, 0.80, alpha))


#func _draw_component(comp: Dictionary):
	#var cv  = canvas
	#var pos = comp.pos
	#var sz  = comp.size 
	#var col = comp.color
	#var rot = comp.get("rotation_deg", 0)
#
	## Push transform for rotation around component center
	#var ctr = pos + sz * 0.5
	#cv.draw_set_transform(pan_offset + ctr * zoom_level, deg_to_rad(rot), Vector2(zoom_level, zoom_level))
	#var local_pos = -sz * 0.5   # draw relative to center
#
	## Shadow
	#cv.draw_rect(Rect2(local_pos + Vector2(4,4), sz), Color(0,0,0,0.4), true)
	## Body
	#cv.draw_rect(Rect2(local_pos, sz), col.darkened(0.52), true)
	## Top accent
	#cv.draw_rect(Rect2(local_pos, Vector2(sz.x, 6)), col, true)
#
	## Border — bright when selected
	#var bc = Color(1,1,1,0.9) if comp.selected else col.lightened(0.1)
	#var bw = 2.8 if comp.selected else 1.5
	#cv.draw_rect(Rect2(local_pos, sz), bc, false, bw)
#
	## Selection glow (outer rect)
	#if comp.selected:
		#cv.draw_rect(Rect2(local_pos - Vector2(3,3), sz + Vector2(6,6)),
			#Color(1,1,1,0.18), false, 1.0)
#
	## NEW — chi tiết PCB riêng cho Flight Controller
	#if comp.name == "Flight Controller":
		#_draw_fc_details(cv, sz)
	#elif comp.name == "4-in-1 ESC":
		#_draw_esc_details(cv, sz,comp.ports)
	## Ports (in local rotated space — shape only, no label)
	#for port in comp.ports:
		#_draw_port_local(cv, sz, port)
#
	## Restore world transform — tất cả text vẽ sau đây đều upright
	#cv.draw_set_transform(pan_offset, 0.0, Vector2(zoom_level, zoom_level))
#
	## Port labels — tính world pos của từng port rồi vẽ thẳng, không bị xoay
	#for port in comp.ports:
		#var wp  = _port_world_pos(comp, port)
		#var big = port.get("big", false)
		#var pc  = port.get("color", Color(0.6, 0.6, 0.6))
		#var loff = _port_label_offset_world(comp, port, big)
		#cv.draw_string(ThemeDB.fallback_font, wp + loff,
			#port.get("label", port.name), HORIZONTAL_ALIGNMENT_CENTER, -1,
			#int(9 * zoom_level), pc.lightened(0.35))
#
	## Name label
	#cv.draw_string(ThemeDB.fallback_font,
		#pos + Vector2(0, sz.y * 0.5 + 5),
		#comp.name, HORIZONTAL_ALIGNMENT_CENTER, int(sz.x),
		#int(11 * zoom_level), Color(0.95, 0.95, 0.95))
func _draw_component(comp: Dictionary):
	var cv  = canvas
	var pos = comp.pos
	var sz  = comp.size
	var col = comp.color
	var rot = comp.get("rotation_deg", 0)
	var ctr = pos + sz * 0.5
	cv.draw_set_transform(pan_offset + ctr * zoom_level, deg_to_rad(rot), Vector2(zoom_level, zoom_level))
	var local_pos = -sz * 0.5

	# ── Shadow / Body / Border ──────────────────────────
	if comp.name == "Battery":
		_draw_battery_body(cv, sz, col, comp.selected)
	else:
		# Shadow
		cv.draw_rect(Rect2(local_pos + Vector2(4,4), sz), Color(0,0,0,0.4), true)
		# Body
		cv.draw_rect(Rect2(local_pos, sz), col.darkened(0.52), true)
		# Top accent
		cv.draw_rect(Rect2(local_pos, Vector2(sz.x, 6)), col, true)
		# Border — bright when selected
		var bc = Color(1,1,1,0.9) if comp.selected else col.lightened(0.1)
		var bw = 2.8 if comp.selected else 1.5
		cv.draw_rect(Rect2(local_pos, sz), bc, false, bw)

	# Selection glow — chung cho mọi component, kể cả Battery
	if comp.selected:
		cv.draw_rect(Rect2(local_pos - Vector2(3,3), sz + Vector2(6,6)),
			Color(1,1,1,0.18), false, 1.0)

	# Chi tiết riêng từng loại
	if comp.name == "Flight Controller":
		_draw_fc_details(cv, sz)
	elif comp.name == "4-in-1 ESC":
		_draw_esc_details(cv, sz, comp.ports)
	elif comp.name == "Battery":
		_draw_battery_details(cv, sz, col)

	# Ports (không đổi)
	for port in comp.ports:
		_draw_port_local(cv, sz, port)

	cv.draw_set_transform(pan_offset, 0.0, Vector2(zoom_level, zoom_level))
	for port in comp.ports:
		var wp  = _port_world_pos(comp, port)
		var big = port.get("big", false)
		var pc  = port.get("color", Color(0.6, 0.6, 0.6))
		var loff = _port_label_offset_world(comp, port, big)
		cv.draw_string(ThemeDB.fallback_font, wp + loff,
			port.get("label", port.name), HORIZONTAL_ALIGNMENT_CENTER, -1,
			int(9 * zoom_level), pc.lightened(0.35))

	cv.draw_string(ThemeDB.fallback_font,
		pos + Vector2(0, sz.y * 0.5 + 5),
		comp.name, HORIZONTAL_ALIGNMENT_CENTER, int(sz.x),
		int(11 * zoom_level), Color(0.95, 0.95, 0.95))

func _draw_fc_details(cv: Control, sz: Vector2):
	var half = sz * 0.5

	# --- 4 lỗ bắt vít ở góc (chuẩn mounting FC) ---
	var hole_pad = 14.0
	var hole_r   = 4.0
	var holes = [
		Vector2(-half.x + hole_pad, -half.y + hole_pad),
		Vector2( half.x - hole_pad, -half.y + hole_pad),
		Vector2(-half.x + hole_pad,  half.y - hole_pad),
		Vector2( half.x - hole_pad,  half.y - hole_pad),
	]
	for h in holes:
		cv.draw_circle(h, hole_r + 1.5, Color(0.75, 0.76, 0.78, 0.9))  # viền kim loại
		cv.draw_circle(h, hole_r, Color(0.05, 0.05, 0.05))            # lỗ đen

	# --- Đường trace mờ nối chip ra các cạnh ---
	var trace_col = Color(0.85, 0.85, 0.7, 0.25)
	cv.draw_line(Vector2(-half.x + 20, 0), Vector2(-16, 0), trace_col, 1.2)
	cv.draw_line(Vector2( half.x - 20, 0), Vector2( 16, 0), trace_col, 1.2)
	cv.draw_line(Vector2(0, -half.y + 20), Vector2(0, -16), trace_col, 1.2)
	cv.draw_line(Vector2(0,  half.y - 20), Vector2(0,  16), trace_col, 1.2)

	# --- Chip trung tâm (MCU/Gyro) ---
	var chip_size = Vector2(34, 34)
	var chip_rect = Rect2(-chip_size * 0.5, chip_size)
	cv.draw_rect(chip_rect, Color(0.03, 0.03, 0.03), true)
	cv.draw_rect(chip_rect, Color(0.35, 0.35, 0.38), false, 1.2)

	# Chân pin quanh chip
	var pin_count = 5
	for side in range(4):
		for i in range(pin_count):
			var t = (float(i) + 0.5) / pin_count
			var pin_pos: Vector2
			match side:
				0: pin_pos = Vector2(lerp(-chip_size.x*0.5, chip_size.x*0.5, t), -chip_size.y*0.5 - 2)
				1: pin_pos = Vector2(lerp(-chip_size.x*0.5, chip_size.x*0.5, t),  chip_size.y*0.5 + 2)
				2: pin_pos = Vector2(-chip_size.x*0.5 - 2, lerp(-chip_size.y*0.5, chip_size.y*0.5, t))
				_: pin_pos = Vector2( chip_size.x*0.5 + 2, lerp(-chip_size.y*0.5, chip_size.y*0.5, t))
			cv.draw_rect(Rect2(pin_pos - Vector2(1.5,1.5), Vector2(3,3)), Color(0.7,0.7,0.72), true)

	# Chấm nhỏ đánh dấu pin 1 (kiểu IC thật)
	cv.draw_circle(chip_rect.position + Vector2(4,4), 1.6, Color(0.5,0.5,0.5))

	# Chữ in trên chip
	cv.draw_string(ThemeDB.fallback_font, Vector2(-11, 4), "FC",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.55, 0.6))

	# --- Đèn LED trạng thái, có glow ---
	var led_pos = Vector2(half.x - 10, -half.y + 10)
	cv.draw_circle(led_pos, 5.0, Color(0.15, 0.85, 1.0, 0.25))  # glow
	cv.draw_circle(led_pos, 3.0, Color(0.15, 0.85, 1.0, 0.95))  # lõi LED

func _draw_motor(comp: Dictionary):
	var cv  = canvas
	var pos = comp.pos
	var r   = MOTOR_RADIUS
	var col = comp.color
	var rot = comp.get("rotation_deg", 0)

	var ctr = pos + Vector2(r, r)
	cv.draw_set_transform(pan_offset + ctr * zoom_level, deg_to_rad(rot), Vector2(zoom_level, zoom_level))

	# Shadow
	cv.draw_circle(Vector2(3,4), r, Color(0,0,0,0.35))
	# Outer ring
	cv.draw_circle(Vector2.ZERO, r, col.darkened(0.5))
	cv.draw_arc(Vector2.ZERO, r, 0, TAU, 40,
		col if not comp.selected else Color(1,1,1,0.9),
		2.5 if comp.selected else 1.8, true)
	if comp.selected:
		cv.draw_arc(Vector2.ZERO, r + 4, 0, TAU, 40, Color(1,1,1,0.18), 1.0, true)
	# Inner rings
	cv.draw_arc(Vector2.ZERO, r * 0.72, 0, TAU, 32, col.darkened(0.2), 1.2, true)
	cv.draw_arc(Vector2.ZERO, r * 0.40, 0, TAU, 24, col.lightened(0.15), 1.0, true)
	cv.draw_circle(Vector2.ZERO, r * 0.18, col.lightened(0.2))


	for port in comp.ports:
		_draw_port_local_circle(cv, r, port)

	# Restore world transform
	cv.draw_set_transform(pan_offset, 0.0, Vector2(zoom_level, zoom_level))

	# Port labels upright
	for port in comp.ports:
		var wp  = _port_world_pos(comp, port)
		var big = port.get("big", false)
		var pc  = port.get("color", Color(0.6, 0.6, 0.6))
		var loff = _port_label_offset_world(comp, port, big)
		cv.draw_string(ThemeDB.fallback_font, wp + loff,
			port.get("label", port.name), HORIZONTAL_ALIGNMENT_CENTER, -1,
			int(9 * zoom_level), pc.lightened(0.35))
	# Motor name
	cv.draw_string(ThemeDB.fallback_font,
		ctr + Vector2(-r, 5),
		"Motor", HORIZONTAL_ALIGNMENT_CENTER, int(r * 2),
		int(11 * zoom_level), Color(0.95, 0.95, 0.95))

# Draw a port in the component's LOCAL coordinate space (center = origin for motors,
# top-left = -size/2 for rects). Transform is already pushed by caller.

func _draw_port_local(cv: Control, sz: Vector2, port: Dictionary):
	var lp  = _port_local_pos(sz, port)
	var pp  = lp - sz * 0.5
	var pc  = port.get("color", Color(0.6,0.6,0.6))
	var big = port.get("big", false)

	if big:
		var style = port.get("connector_style", "default")
		var side  = port.get("side", "right")
		var rect: Rect2

		if style == "wide_inset":
			# Chỉ FC_BUS của 4-in-1 ESC dùng style này
			var rw = 32.0
			var rh = 18.0
			match side:
				"left":   rect = Rect2(pp + Vector2(2, -rh*0.5),    Vector2(rw, rh))
				"right":  rect = Rect2(pp - Vector2(rw+2, rh*0.5),  Vector2(rw, rh))
				"top":    rect = Rect2(pp - Vector2(rw*0.5, rh-12),  Vector2(rw, rh))
				"bottom": rect = Rect2(pp - Vector2(rw*0.5, 10),    Vector2(rw, rh))
				_:        rect = Rect2(pp - Vector2(rw*0.5, rh*0.5),Vector2(rw, rh))
			cv.draw_rect(rect, pc.darkened(0.4), true)
			cv.draw_rect(rect, pc, false, 1.8)
			var num_holes = 3
			for hi in range(num_holes):
				var hx = rect.position.x + (float(hi) + 0.5) * (rw / num_holes)
				var hy = rect.position.y + rect.size.y * 0.5
				cv.draw_circle(Vector2(hx, hy), 2.0, Color(0.05,0.05,0.05))

		else:
			var rw = 18.0
			var rh = 26.0
			match side:
				"left":   rect = Rect2(pp - Vector2(rw, rh*0.5),    Vector2(rw, rh))
				"right":  rect = Rect2(pp - Vector2(0,  rh*0.5),    Vector2(rw, rh))
				"top":    rect = Rect2(pp - Vector2(rw*0.5, rh),    Vector2(rw, rh))
				"bottom": rect = Rect2(pp - Vector2(rw*0.5, 0),     Vector2(rw, rh))
				_:        rect = Rect2(pp - Vector2(rw*0.5, rh*0.5),Vector2(rw, rh))
			cv.draw_rect(rect, pc.darkened(0.4), true)
			cv.draw_rect(rect, pc, false, 1.8)

			# Lỗ pin: ngang nếu top/bottom, dọc nếu left/right
			if side == "top" or side == "bottom":
				# Xoay ngang — 3 lỗ theo chiều X
				for hi in range(3):
					var hx = rect.position.x + (float(hi) + 0.5) * (rw / 3.0)
					var hy = rect.position.y + rect.size.y * 0.5
					cv.draw_circle(Vector2(hx, hy), 2.0, Color(0.05,0.05,0.05))
			else:
				# Giữ dọc — 3 lỗ theo chiều Y
				for hi in range(3):
					var hole_y = rect.position.y + 5 + hi * 7
					cv.draw_circle(Vector2(rect.position.x + rect.size.x*0.5, hole_y),
						2.0, Color(0.05,0.05,0.05))

	else:
		cv.draw_circle(pp, PORT_RADIUS, pc.darkened(0.35))
		cv.draw_arc(pp, PORT_RADIUS, 0, TAU, 18, pc, 1.8, true)




func _draw_port_local_circle(cv: Control, r: float, port: Dictionary):
	var pp: Vector2
	match port.get("side","left"):
		"left":   pp = Vector2(-r, 0)
		"right":  pp = Vector2( r, 0)
		"top":    pp = Vector2(0, -r)
		"bottom": pp = Vector2(0,  r)
		_:        pp = Vector2(-r, 0)

	var pc  = port.get("color", Color(0.6,0.6,0.6))
	var big = port.get("big", false)
	if big:
		var rw = 18.0; var rh = 26.0
		var side = port.get("side","left")
		var rect: Rect2
		match side:
			"left":   rect = Rect2(pp - Vector2(rw, rh*0.5), Vector2(rw, rh))
			"right":  rect = Rect2(pp - Vector2(0,  rh*0.5), Vector2(rw, rh))
			"top":    rect = Rect2(pp - Vector2(rw*0.5, rh), Vector2(rw, rh))
			"bottom": rect = Rect2(pp - Vector2(rw*0.5, 0),  Vector2(rw, rh))
			_:        rect = Rect2(pp - Vector2(rw*0.5, rh*0.5), Vector2(rw, rh))
		cv.draw_rect(rect, pc.darkened(0.4), true)
		cv.draw_rect(rect, pc, false, 1.8)
		for hi in range(3):
			cv.draw_circle(Vector2(rect.position.x + rect.size.x*0.5,
				rect.position.y + 5 + hi*7), 2.0, Color(0.05,0.05,0.05))
	else:
		cv.draw_circle(pp, PORT_RADIUS, pc.darkened(0.35))
		cv.draw_arc(pp, PORT_RADIUS, 0, TAU, 18, pc, 1.8, true)


func _draw_wire(from: Vector2, to: Vector2, col: Color, bend_pts: Array = [], conn_idx: int = -1):
	var cv = canvas
	var is_hovered = (conn_idx >= 0 and conn_idx == hovered_wire)
	# === KIỂM TRA DÂY LỖI ===
	var is_error = false
	if conn_idx >= 0 and conn_idx < connections.size():
		is_error = not connections[conn_idx].get("valid", true)
	var draw_col = col.lightened(0.25) if is_hovered else col
	var line_w   = 4.5 if is_hovered else 2.2

	if is_error:
		draw_col = Color(0.55, 0.0, 0.0)    # Màu đỏ cho dây lỗi
		line_w = 3.8

	# Gom tất cả điểm: from → bends → to
	# Gom tất cả điểm
	var all_pts: Array[Vector2] = []
	all_pts.append(from)
	for bp in bend_pts:
		all_pts.append(bp)
	all_pts.append(to)

	# Vẽ glow phía dưới khi hover
	if is_hovered:
		for i in range(all_pts.size() - 1):
			var a = all_pts[i]
			var b = all_pts[i + 1]
			var corner = Vector2(b.x, a.y)
			cv.draw_line(a, corner, Color(col.r, col.g, col.b, 0.10), 8.0, true)
			cv.draw_line(corner, b, Color(col.r, col.g, col.b, 0.10), 8.0, true)

	# Vẽ các đoạn orthogonal
	for i in range(all_pts.size() - 1):
		var a = all_pts[i]
		var b = all_pts[i + 1]

		var corner = Vector2(b.x, a.y)
		cv.draw_line(a, corner, draw_col, line_w, true)
		cv.draw_line(corner, b, draw_col, line_w, true)
		#cv.draw_circle(corner, 4.0 if not is_hovered else 5.5, draw_col.darkened(0.2))


	# Endpoint dots
	cv.draw_circle(from, 4.5 if not is_hovered else 6.0, draw_col)
	cv.draw_circle(to,   4.5 if not is_hovered else 6.0, draw_col)

	# Bend handles
	if conn_idx >= 0:
		for bp in bend_pts:
			cv.draw_circle(bp, BEND_RADIUS + 2, Color(0.08, 0.08, 0.10, 0.85))
			cv.draw_circle(bp, BEND_RADIUS, col.darkened(0.3))
			cv.draw_arc(bp, BEND_RADIUS, 0, TAU, 18, draw_col.lightened(0.2), 2.0, true)
			#_draw_bend_node(cv, bp, draw_col, true, true)

		# Hint dots
		if bend_pts.size() == 0 and not is_hovered:
			for i in range(all_pts.size() - 1):
				var a = all_pts[i]
				var b = all_pts[i + 1]
				var corner = Vector2(b.x, a.y)
				for hint in [(a + corner) * 0.5, (corner + b) * 0.5]:
					cv.draw_circle(hint, 4.0, Color(col.r, col.g, col.b, 0.18))
					cv.draw_arc(hint, 4.0, 0, TAU, 12, Color(col.r, col.g, col.b, 0.45), 1.5, true)

# ─────────────────────────────── INPUT ────────────────────────────

func _canvas_input(event: InputEvent):
	if not canvas.is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		var mp = event.position

		# ── Zoom via scroll wheel ──────────────────────────────────
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_level * (1.0 + ZOOM_STEP), mp)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(zoom_level * (1.0 - ZOOM_STEP), mp)
			return

		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# 1. Kiểm tra các hit trước (ưu tiên cao)
				var bh = _hit_bend_point(mp)
				if bh.size() > 0:
					var bps = connections[bh.conn_idx]["bend_points"]
					bps.remove_at(bh.pt_idx)
					connections[bh.conn_idx]["bend_points"] = bps
					canvas.queue_redraw()
					return

				var wi = _hit_wire(mp)
				if wi >= 0:
					hovered_wire = wi
					canvas.queue_redraw()
					_show_wire_context_menu(wi, mp)
					return

				var comp = _hit_component(mp)
				if comp.size() > 0:
					ctx_uid = comp.uid
					for c in canvas_components: c.selected = false
					comp.selected = true
					selected_uid = comp.uid
					canvas.queue_redraw()
					
					ctx_menu.position = Vector2i(
						int(canvas.global_position.x + mp.x),
						int(canvas.global_position.y + mp.y)
					)
					ctx_menu.popup()
					return

				# 2. Nếu không hit gì → bắt đầu Pan
				panning = true
				pan_start = mp - pan_offset
				return

			else:  # RIGHT button released
				if panning:
					panning = false
					canvas.queue_redraw()
				return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Rotation toolbar
				if rot_toolbar_rect.has_point(mp):
					_handle_toolbar_click(mp)
					return

				# Bend point drag
				var bh = _hit_bend_point(mp)
				if bh.size() > 0:
					drag_bend = bh
					canvas.queue_redraw()
					return

				# Wire hint → add bend point
				var wh = _hit_wire_hint(mp)
				if wh.size() > 0 and not wire_active:
					var bps = connections[wh.conn_idx].get("bend_points", [])
					bps.insert(wh.insert_after, wh.pos)
					connections[wh.conn_idx]["bend_points"] = bps
					drag_bend = {"conn_idx": wh.conn_idx, "pt_idx": wh.insert_after}
					canvas.queue_redraw()
					return

				# Port hit
				var ph = _hit_port(mp)
				if ph.size() > 0:
					if not wire_active:
						wire_active  = true
						wire_from    = ph
						wire_cur_pos = mp
					else:
						_try_connect(wire_from, ph)
						wire_active = false
						wire_from   = {}
					canvas.queue_redraw()
					return

				# Cancel wire
				if wire_active:
					wire_active = false
					wire_from   = {}
					canvas.queue_redraw()
					return

				# ── Component hit ──────────────────────────────────
				var comp = _hit_component(mp)
				if comp.size() > 0:
					if comp.uid in selected_uids:
						# Click vào component đã được chọn trong multi-select
						# → bắt đầu multi-drag ngay, giữ nguyên selection
						multi_dragging    = true
						multi_drag_start  = mp
						multi_drag_origins.clear()
						for c in canvas_components:
							if c.uid in selected_uids:
								multi_drag_origins[c.uid] = c.pos
						# Lưu bend_points origins của các wire nằm hoàn toàn trong selection
						multi_drag_origins["_bends"] = {}
						for i in range(connections.size()):
							var conn = connections[i]
							if conn.from_comp.uid in selected_uids and conn.to_comp.uid in selected_uids:
								var bps = conn.get("bend_points", [])
								if bps.size() > 0:
									multi_drag_origins["_bends"][i] = bps.duplicate(true)
					else:
						# Click vào component mới → single select + drag
						for c in canvas_components: c.selected = false
						selected_uids = [comp.uid]
						comp.selected = true
						selected_uid  = comp.uid
						drag_comp     = comp
						drag_offset   = mp - _world_to_screen(comp.pos)
					canvas.queue_redraw()
					return

				# ── Empty canvas → bắt đầu box selection ──────────
				for c in canvas_components: c.selected = false
				selected_uid  = -1
				selected_uids = []
				box_selecting = true
				box_start     = mp
				box_end       = mp
				canvas.queue_redraw()

			else:  # LEFT released
				# Kết thúc box selection → chọn các component nằm trong rect
				if box_selecting:
					box_selecting = false
					var sel_rect  = Rect2(box_start, box_end - box_start).abs()
					selected_uids = []
					for c in canvas_components:
						var sp = _world_to_screen(c.pos)
						# dùng center của component để kiểm tra (hoặc toàn bộ bounds nếu bạn có)
						if sel_rect.has_point(sp):
							c.selected    = true
							selected_uids.append(c.uid)
						else:
							c.selected = false
					selected_uid = selected_uids[0] if selected_uids.size() > 0 else -1
					canvas.queue_redraw()
					return

				# Kết thúc multi-drag → snap tất cả
				if multi_dragging:
					multi_dragging = false
					for c in canvas_components:
						if c.uid in selected_uids:
							c.pos = _snap_to_grid(c.pos)
					multi_drag_origins.clear()
					canvas.queue_redraw()
					return

				# Kết thúc single drag
				if drag_comp.size() > 0:
					drag_comp.pos = _snap_to_grid(drag_comp.pos)
					drag_comp = {}
					canvas.queue_redraw()
				if drag_bend.size() > 0:
					drag_bend = {}
					canvas.queue_redraw()
# ══════════════════════ MOUSE MOTION ══════════════════════════
	elif event is InputEventMouseMotion:
		var new_hovered = _hit_wire(event.position)
		if new_hovered != hovered_wire:
			hovered_wire = new_hovered
			canvas.queue_redraw()
		if drag_bend.size() > 0:
			var idx  = drag_bend.conn_idx
			var pidx = drag_bend.pt_idx
			var wpos = _screen_to_world(event.position)
			connections[idx]["bend_points"][pidx] = wpos
			canvas.queue_redraw()
			return
		if panning:
			pan_offset = event.position - pan_start
			canvas.queue_redraw()
		elif drag_comp.size() > 0:
			drag_comp.pos = _screen_to_world(event.position - drag_offset)
			canvas.queue_redraw()
		# ── Box selection đang kéo ─────────────────────────────────
		if box_selecting:
			box_end = event.position
			# Preview highlight
			var sel_rect = Rect2(box_start, box_end - box_start).abs()
			for c in canvas_components:
				c.selected = sel_rect.has_point(_world_to_screen(c.pos))
			canvas.queue_redraw()
			return

		# ── Multi-drag ─────────────────────────────────────────────
		if multi_dragging:
			var delta_screen = event.position - multi_drag_start
			var delta_world  = delta_screen / zoom_level
			for c in canvas_components:
				if c.uid in selected_uids:
					c.pos = multi_drag_origins[c.uid] + delta_world
			# Dịch chuyển bend_points theo
			var bends_origins = multi_drag_origins.get("_bends", {})
			for i in bends_origins:
				var orig_bps : Array = bends_origins[i]
				var new_bps = []
				for bp in orig_bps:
					new_bps.append(bp + delta_world)
				connections[i]["bend_points"] = new_bps
			canvas.queue_redraw()
			return
		elif wire_active:
			wire_cur_pos = event.position
			canvas.queue_redraw()
		elif _get_selected_comp().size() > 0:
			# Repaint toolbar hover highlight
			canvas.queue_redraw()

func _process(delta: float):
	if wire_tip_timer > 0:
		wire_tip_timer -= delta
		if wire_tip_timer <= 0:
			wire_tip_text = ""
		canvas.queue_redraw()
	if _zoom_display_timer > 0:
		_zoom_display_timer -= delta
		canvas.queue_redraw()
	# Auto cleanup persistent error nếu connection không còn tồn tại
	if persistent_error.size() > 0:
		var idx = persistent_error.conn_idx
		if idx < 0 or idx >= connections.size():
			persistent_error.clear()
		elif not connections[idx].get("valid", true):  # optional
			pass

# ─────────────────────────────── ZOOM ─────────────────────────────
func _apply_zoom(new_zoom: float, pivot_screen: Vector2):
	new_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
	# Adjust pan so the point under the cursor stays fixed
	var world_pivot = _screen_to_world(pivot_screen)
	zoom_level = new_zoom
	pan_offset  = pivot_screen - world_pivot * zoom_level
	_zoom_display_timer = 1.5
	canvas.queue_redraw()

# ─────────────────────────────── TOOLBAR CLICK ────────────────────
func _handle_toolbar_click(mp: Vector2):
	var sel = _get_selected_comp()
	if sel.is_empty(): return
	var tx = rot_toolbar_rect.position.x + 4
	var ty = rot_toolbar_rect.position.y + 4
	for i in range(ROT_BUTTONS.size()):
		var brect = Rect2(tx, ty, ROT_BTN_W, ROT_BTN_H)
		if brect.has_point(mp):
			var delta = ROT_BUTTONS[i][1]
			if delta == 0:
				_rotate_component_to(sel.uid, 0)
			else:
				_rotate_component(sel.uid, delta)
			return
		tx += ROT_BTN_W + ROT_BTN_GAP

# ─────────────────────────────── ROTATION ─────────────────────────
func _rotate_component(uid: int, delta_deg: int):
	for comp in canvas_components:
		if comp.uid == uid:
			comp["rotation_deg"] = (int(comp.get("rotation_deg", 0) + delta_deg + 360) % 360)
			canvas.queue_redraw()
			return

func _rotate_component_to(uid: int, deg: int):
	for comp in canvas_components:
		if comp.uid == uid:
			comp["rotation_deg"] = deg
			canvas.queue_redraw()
			return

# ─────────────────────────────── WIRING ───────────────────────────
func _try_connect(from: Dictionary, to: Dictionary):
	if from.comp.uid == to.comp.uid:
		_show_tip("Cannot connect to itself!", _world_to_screen(from.pos))
		return

	var ft = from.port.get("type","")
	var tt = to.port.get("type","")
	var ok = false
	for pair in COMPATIBLE:
		if (pair[0]==ft and pair[1]==tt) or (pair[1]==ft and pair[0]==tt):
			ok = true; break

	connections = connections.filter(func(c):
		return not (
			(c.from_comp.uid==from.comp.uid and c.from_port.name==from.port.name) or
			(c.to_comp.uid  ==to.comp.uid   and c.to_port.name  ==to.port.name)   or
			(c.from_comp.uid==to.comp.uid   and c.from_port.name==to.port.name)   or
			(c.to_comp.uid  ==from.comp.uid and c.to_port.name  ==from.port.name)
		)
	)

	var new_conn = {
		"from_comp": from.comp, 
		"from_port": from.port,
		"to_comp": to.comp, 
		"to_port": to.port,
		"valid": ok,
		"bend_points": [],
	}

	# === TẠO BEND POINT TẠI GÓC ORTHOGONAL TỰ ĐỘNG ===
	var fp = _port_world_pos(from.comp, from.port)
	var tp = _port_world_pos(to.comp, to.port)
	
	if abs(fp.x - tp.x) > 5 and abs(fp.y - tp.y) > 5:
		var corner = Vector2(tp.x, fp.y)   # Default: ngang trước, dọc sau
		new_conn.bend_points = [corner]

	connections.append(new_conn)
	print("bend_points sau khi connect: ", new_conn.bend_points)  # ← thêm dòng này

	if not ok:

		persistent_error = {
			"text": "⚠ Incompatible: " + ft + " ↔ " + tt,
			"screen_pos": _world_to_screen(from.pos),
			"conn_idx": connections.size() - 1
			
		}
	else:
		persistent_error.clear()
	canvas.queue_redraw()

func _delete_component(uid: int):
	canvas_components = canvas_components.filter(func(c): return c.uid != uid)
	connections = connections.filter(func(c):
		return c.from_comp.uid != uid and c.to_comp.uid != uid)
	# === PHẦN MỚI: Xóa persistent_error nếu nó liên quan đến component vừa xóa ===
	if persistent_error.size() > 0:
		var err_idx = persistent_error.conn_idx
		# Nếu conn_idx không còn hợp lệ hoặc component đã bị xóa
		if err_idx >= connections.size() or \
		   (connections.size() > err_idx and \
			(connections[err_idx].from_comp.uid == uid or connections[err_idx].to_comp.uid == uid)):
			persistent_error.clear()
	if selected_uid == uid: selected_uid = -1
	canvas.queue_redraw()

func _disconnect_all(uid: int):
	connections = connections.filter(func(c):
		return c.from_comp.uid != uid and c.to_comp.uid != uid)
	canvas.queue_redraw()

# ─────────────────────────────── HIT TEST ─────────────────────────
func _hit_port(mp: Vector2) -> Dictionary:
	for comp in canvas_components:
		for port in comp.ports:
			var pp = _world_to_screen(_port_world_pos(comp, port))
			var r = (PORT_RADIUS_BIG if port.get("big", false) else PORT_RADIUS) * zoom_level
			if mp.distance_to(pp) <= r + 5.0:
				return {"comp": comp, "port": port, "pos": _port_world_pos(comp, port)}
	return {}

func _hit_component(mp: Vector2) -> Dictionary:
	for i in range(canvas_components.size() - 1, -1, -1):
		var comp = canvas_components[i]
		var rot  = comp.get("rotation_deg", 0)
		var ctr  = _world_to_screen(_comp_world_center(comp))

		if comp.get("shape","rect") == "circle":
			if mp.distance_to(ctr) <= MOTOR_RADIUS * zoom_level:
				return comp
		else:
			# Transform mouse pos into local component space for rotated hit test
			var local_mp = _rotate_vec(mp - ctr, -rot) / zoom_level
			var half = comp.size * 0.5
			if abs(local_mp.x) <= half.x and abs(local_mp.y) <= half.y:
				return comp
	return {}

# ─────────────────────────────── HELPERS ──────────────────────────
# Port position in WORLD space (accounting for rotation)
func _port_world_pos(comp: Dictionary, port: Dictionary) -> Vector2:
	var s     = comp.size
	var shape = comp.get("shape","rect")
	var rot   = comp.get("rotation_deg", 0)

	var local_offset: Vector2   # offset from component center in local (unrotated) space

	if shape == "circle":
		var r = MOTOR_RADIUS
		match port.get("side","left"):
			"left":   local_offset = Vector2(-r, 0)
			"right":  local_offset = Vector2( r, 0)
			"top":    local_offset = Vector2(0, -r)
			"bottom": local_offset = Vector2(0,  r)
			_:        local_offset = Vector2(-r, 0)
	else:
		var lp = _port_local_pos(s, port)  # top-left relative
		local_offset = lp - s * 0.5        # center-relative

	var rotated = _rotate_vec(local_offset, rot)
	return comp.pos + s * 0.5 + rotated

# Port position within a rect component, relative to component top-left, UNROTATED
func _port_local_pos(sz: Vector2, port: Dictionary) -> Vector2:
	match port.get("side","right"):
		"left":   return Vector2(0,        sz.y * port.offset)
		"right":  return Vector2(sz.x,     sz.y * port.offset)
		"top":    return Vector2(sz.x * port.offset, 0)
		"bottom": return Vector2(sz.x * port.offset, sz.y)
	return Vector2.ZERO

func _port_label_offset(port: Dictionary, big: bool) -> Vector2:
	var d = PORT_RADIUS_BIG + 4 if big else PORT_RADIUS + 4
	match port.get("side","right"):
		"left":   return Vector2(-(d + 16), 4)
		"right":  return Vector2(d + 2, 4)
		"top":    return Vector2(-8, -(d + 8))
		"bottom": return Vector2(-8,  d + 10)
	return Vector2(8, 4)

func _wire_color(t: String) -> Color:
	match t:
		"power_pos":   return Color(0.88, 0.22, 0.22)
		"power_neg":   return Color(0.50, 0.50, 0.50)
		"ground": return Color(0.38,0.38,0.38)
		"esc_out","motor_phase": return Color(0.88, 0.50, 0.10)
		"signal_out","signal_in": return Color(0.22, 0.82, 0.55)
		"pwm_out":     return Color(0.92, 0.78, 0.10)
		"power_5v","power_5v_in":         return Color(0.95, 0.55, 0.15)
		"voltage_sense","voltage_sense_in": return Color(0.65, 0.35, 0.78)
		"current_sense","current_sense_in": return Color(0.92, 0.85, 0.25)
		"telemetry","telemetry_in":         return Color(0.35, 0.65, 0.92)
	return Color(0.6, 0.6, 0.6)

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(round(pos.x / GRID) * GRID, round(pos.y / GRID) * GRID)

func _show_tip(msg: String, screen_pos: Vector2):
	wire_tip_text  = msg
	wire_tip_pos   = screen_pos
	wire_tip_timer = 2.5
	canvas.queue_redraw()

func _get_selected_comp() -> Dictionary:
	if selected_uid == -1: return {}
	for comp in canvas_components:
		if comp.uid == selected_uid and comp.selected:
			return comp
	return {}

# ─────────────────────────────── WIRE HIT TEST ────────────────────
func _hit_wire(mp: Vector2) -> int:
	# Trả về conn_idx nếu click/hover gần wire, -1 nếu không
	var wmp = _screen_to_world(mp)
	var threshold = 6.0 / zoom_level
	for i in range(connections.size()):
		var conn = connections[i]
		var fp   = _port_world_pos(conn.from_comp, conn.from_port)
		var tp   = _port_world_pos(conn.to_comp,   conn.to_port)
		var bps  = conn.get("bend_points", [])
		var all_pts: Array[Vector2] = []
		all_pts.append(fp)
		for bp in bps: all_pts.append(bp)
		all_pts.append(tp)
		# Kiểm tra từng đoạn (ngang + dọc)
		for s in range(all_pts.size() - 1):
			var a      = all_pts[s]
			var b      = all_pts[s + 1]
			var corner = Vector2(b.x, a.y)
			# Đoạn ngang: a → corner
			if _dist_point_segment(wmp, a, corner) <= threshold:
				return i
			# Đoạn dọc: corner → b
			if _dist_point_segment(wmp, corner, b) <= threshold:
				return i
	return -1

func _dist_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var len_sq = ab.dot(ab)
	if len_sq < 0.0001: return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func is_wiring_complete() -> Dictionary:
	var result = {"ok": false, "reason": ""}

	var has_battery = false
	var has_esc = false
	var has_fc = false
	var motor_count = 0

	for comp in canvas_components:
		match comp.name:
			"Battery": has_battery = true
			"4-in-1 ESC": has_esc = true
			"Flight Controller": has_fc = true
			"Motor": motor_count += 1

	if not has_battery:
		result.reason = "Wiring: No battery in circuit"
		return result
	if not has_esc:
		result.reason = "Wiring: No ESC in circuit"
		return result
	if not has_fc:
		result.reason = "Wiring: No Flight Controller in circuit"
		return result
	if motor_count == 0:
		result.reason = "Wiring: No motors in circuit"
		return result

	# Connections bắt buộc
	var bat_to_esc = false      # Battery → ESC (PWR+/PWR-/GND, cạnh trên)
	var esc_to_fc = false       # ESC FC_BUS → FC ESC_BUS
	var esc_5v_to_fc = false    # ESC 5V (BEC) → FC power — bắt buộc, FC cần sống
	var motors_connected = 0    # ESC M1-M4 → Motor PHASE

	# Connections tùy chọn (không chặn "ok")
	var esc_vbat_to_fc = false
	var esc_curr_to_fc = false
	var esc_tlm_to_fc = false

	for conn in connections:
		if not conn.get("valid", false):
			continue

		var fn = conn.from_comp.name
		var tn = conn.to_comp.name
		var fp = conn.from_port.name
		var tp = conn.to_port.name

		# Battery → ESC power (cạnh trên: PWR+, PWR-, GND)
		if (fn == "Battery" and tn == "4-in-1 ESC") or (fn == "4-in-1 ESC" and tn == "Battery"):
			if fp in ["BAT+","BAT-","PWR+","PWR-","GND"] or tp in ["BAT+","BAT-","PWR+","PWR-","GND"]:
				bat_to_esc = true

		# ESC → FC (cạnh dưới: 5V, VBAT, FC_BUS, CURR, TLM)
		if (fn == "4-in-1 ESC" and tn == "Flight Controller") or (fn == "Flight Controller" and tn == "4-in-1 ESC"):
			if fp in ["FC_BUS","ESC_BUS"] or tp in ["FC_BUS","ESC_BUS"]:
				esc_to_fc = true
			if fp == "5V" or tp == "5V":
				esc_5v_to_fc = true
			if fp == "VBAT" or tp == "VBAT":
				esc_vbat_to_fc = true
			if fp == "CURR" or tp == "CURR":
				esc_curr_to_fc = true
			if fp == "TLM" or tp == "TLM":
				esc_tlm_to_fc = true

		# ESC → Motor
		if (fn == "4-in-1 ESC" and tn == "Motor") or (fn == "Motor" and tn == "4-in-1 ESC"):
			motors_connected += 1

	if not bat_to_esc:
		result.reason = "Wiring: Battery not connected to ESC"
		return result
	if not esc_to_fc:
		result.reason = "Wiring: ESC not connected to Flight Controller"
		return result
	if not esc_5v_to_fc:
		result.reason = "Wiring: ESC 5V (BEC) not connected to Flight Controller"
		return result
	if motors_connected < motor_count:
		result.reason = "Wiring: %d/%d motors connected to ESC" % [motors_connected, motor_count]
		return result

	result.ok = true
	result.optional = {
		"vbat": esc_vbat_to_fc,
		"current": esc_curr_to_fc,
		"telemetry": esc_tlm_to_fc,
	}
	return result
# ─────────────────────────────── BEND HELPERS ─────────────────────
func _hit_bend_point(mp: Vector2) -> Dictionary:
	var wmp = _screen_to_world(mp)
	for i in range(connections.size()):
		var bps = connections[i].get("bend_points", [])
		for j in range(bps.size()):
			if wmp.distance_to(bps[j]) <= (BEND_RADIUS + 4.0) / zoom_level:
				return {"conn_idx": i, "pt_idx": j}
	return {}

func _hit_wire_hint(mp: Vector2) -> Dictionary:
	# Trả về {conn_idx, insert_after, pos} nếu click trúng hint dot giữa đoạn
	var wmp = _screen_to_world(mp)
	var threshold = 10.0 / zoom_level
	for i in range(connections.size()):
		var conn = connections[i]
		var fp   = _port_world_pos(conn.from_comp, conn.from_port)
		var tp   = _port_world_pos(conn.to_comp,   conn.to_port)
		var bps  = conn.get("bend_points", [])
		var all_pts: Array[Vector2] = []
		all_pts.append(fp)
		for bp in bps: all_pts.append(bp)
		all_pts.append(tp)

		for s in range(all_pts.size() - 1):
			var a      = all_pts[s]
			var b      = all_pts[s + 1]
			var corner = Vector2(b.x, a.y)
			var mh     = (a + corner) * 0.5   # midpoint đoạn ngang
			var mv     = (corner + b) * 0.5   # midpoint đoạn dọc
			if wmp.distance_to(mh) <= threshold:
				return {"conn_idx": i, "insert_after": s, "pos": mh}
			if wmp.distance_to(mv) <= threshold:
				return {"conn_idx": i, "insert_after": s, "pos": mv}
	return {}

func _port_label_offset_world(comp: Dictionary, port: Dictionary, big: bool) -> Vector2:
	# Tính side thực tế sau khi rotate
	var rot  = comp.get("rotation_deg", 0)
	var side = port.get("side", "right")
	# Xoay side theo rotation
	const SIDES = ["top", "right", "bottom", "left"]
	var idx   = SIDES.find(side)
	var steps = (int(rot / 90)) % 4
	var real_side = side
	if idx >= 0:
		real_side = SIDES[(idx + steps + 4) % 4]

	var d = (PORT_RADIUS_BIG + 6) if big else (PORT_RADIUS + 5)
	d *= zoom_level
	match real_side:
		"left":   return Vector2(-(d + 14 * zoom_level), 4 * zoom_level)
		"right":  return Vector2(d + 2 * zoom_level, 4 * zoom_level)
		"top":    return Vector2(-8 * zoom_level, -(d + 6 * zoom_level))
		"bottom": return Vector2(-8 * zoom_level,  d + 8 * zoom_level)
	return Vector2(d, 0)

var wire_ctx_menu: PopupMenu = null
func _show_wire_context_menu(conn_idx: int, mp: Vector2):
	_pending_delete_wire = conn_idx
	wire_ctx_menu.set_item_text(0, "Delete wire" % [
		connections[conn_idx].from_port.get("label", "?"),
		connections[conn_idx].to_port.get("label", "?")
	])
	wire_ctx_menu.position = Vector2i(
		int(canvas.global_position.x + mp.x),
		int(canvas.global_position.y + mp.y)
	)
	wire_ctx_menu.popup()

#func _on_wire_ctx_menu(id: int):
	#if id == 0 and hovered_wire >= 0 and hovered_wire < connections.size():
		#connections.remove_at(hovered_wire)
	#_pending_delete_wire = -1
	#hovered_wire = -1
	#canvas.queue_redraw()
func _on_wire_ctx_menu(id: int):
	if id == 0 and hovered_wire >= 0 and hovered_wire < connections.size():
		# Xóa persistent error nếu dây đang bị lỗi
		if persistent_error.size() > 0 and persistent_error.conn_idx == hovered_wire:
			persistent_error.clear()
		
		# Xóa dây
		connections.remove_at(hovered_wire)
		hovered_wire = -1
		_pending_delete_wire = -1
		canvas.queue_redraw()

# ─────────────────────────────── SAVE / LOAD API ──────────────────
func serialize() -> Dictionary:
	var comps := []
	for c in canvas_components:
		comps.append({
			"uid":          c.uid,
			"name":         c.name,
			"pos":          [c.pos.x, c.pos.y],
			"rotation_deg": c.get("rotation_deg", 0),
		})
	var conns := []
	for conn in connections:
		var bps := []
		for bp in conn.get("bend_points", []):
			bps.append([bp.x, bp.y])
		conns.append({
			"from_uid":    conn.from_comp.uid,
			"from_port":   conn.from_port.name,
			"to_uid":      conn.to_comp.uid,
			"to_port":     conn.to_port.name,
			"valid":       conn.get("valid", true),
			"bend_points": bps,
		})
	return {"components": comps, "connections": conns}

# ─────────────────────── IMPORT MERGE (không clear) ───────────────
func import_merge(data: Dictionary) -> void:
	var local_uid_map := {}

	for c in data.get("components", []):
		var cdef = COMP_DEFS.get(c.name, {})
		if cdef.is_empty():
			continue
		var old_uid = int(c.uid)
		uid_counter += 1
		var new_uid = uid_counter
		local_uid_map[old_uid] = new_uid

		canvas_components.append({
			"uid":          new_uid,
			"name":         c.name,
			"pos":          Vector2(c.pos[0], c.pos[1]) + Vector2(40, 40),
			"size":         cdef.size,
			"color":        cdef.color,
			"shape":        cdef.get("shape", "rect"),
			"ports":        cdef.ports.duplicate(true),
			"selected":     false,
			"rotation_deg": c.get("rotation_deg", 0),
		})

	var comp_by_new_uid := {}
	for c in canvas_components:
		comp_by_new_uid[c.uid] = c

	for conn in data.get("connections", []):
		var new_from = local_uid_map.get(int(conn.from_uid), -1)
		var new_to   = local_uid_map.get(int(conn.to_uid), -1)
		var fc = comp_by_new_uid.get(new_from)
		var tc = comp_by_new_uid.get(new_to)
		if fc == null or tc == null:
			continue
		var fp = _find_port_by_name(fc, conn.from_port)
		var tp = _find_port_by_name(tc, conn.to_port)
		if fp.is_empty() or tp.is_empty():
			continue
		var bps: Array[Vector2] = []
		for bp in conn.get("bend_points", []):
			bps.append(Vector2(bp[0], bp[1]) + Vector2(40, 40))
		connections.append({
			"from_comp":   fc, "from_port": fp,
			"to_comp":     tc, "to_port":   tp,
			"valid":       conn.get("valid", true),
			"bend_points": bps,
		})

	canvas.queue_redraw()
func deserialize(data: Dictionary):
	# Clear
	canvas_components.clear()
	connections.clear()
	persistent_error.clear()
	uid_counter = 0

	# Restore components
	for c in data.get("components", []):
		var cdef = COMP_DEFS.get(c.name, {})
		if cdef.is_empty():
			continue
		uid_counter = max(uid_counter, int(c.uid))
		canvas_components.append({
			"uid":          int(c.uid),
			"name":         c.name,
			"pos":          Vector2(c.pos[0], c.pos[1]),
			"size":         cdef.size,
			"color":        cdef.color,
			"shape":        cdef.get("shape", "rect"),
			"ports":        cdef.ports.duplicate(true),
			"selected":     false,
			"rotation_deg": c.get("rotation_deg", 0),
		})

	# Build uid → comp map
	var uid_map := {}
	for c in canvas_components:
		uid_map[c.uid] = c

	# Restore connections
	for conn in data.get("connections", []):
		var fc = uid_map.get(int(conn.from_uid))
		var tc = uid_map.get(int(conn.to_uid))
		if fc == null or tc == null:
			continue
		var fp = _find_port_by_name(fc, conn.from_port)
		var tp = _find_port_by_name(tc, conn.to_port)
		if fp.is_empty() or tp.is_empty():
			continue
		var bps: Array[Vector2] = []
		for bp in conn.get("bend_points", []):
			bps.append(Vector2(bp[0], bp[1]))
		connections.append({
			"from_comp":   fc, "from_port": fp,
			"to_comp":     tc, "to_port":   tp,
			"valid":       conn.get("valid", true),
			"bend_points": bps,
		})

	canvas.queue_redraw()

func _find_port_by_name(comp: Dictionary, port_name: String) -> Dictionary:
	for p in comp.ports:
		if p.name == port_name:
			return p
	return {}
func _draw_esc_details(cv: CanvasItem, sz: Vector2,ports: Array) -> void:
	var w := sz.x
	var h := sz.y
	var l := -w * 0.5
	var t := -h * 0.5

	var chip_col  := Color(0.05, 0.05, 0.07)
	var chip_edge := Color(0.25, 0.25, 0.28)
	var silver    := Color(0.75, 0.75, 0.78)
	var cap_col   := Color(0.12, 0.12, 0.14)
	var silk      := Color(0.65, 0.68, 0.72, 0.85)

	var min_side: float = minf(w, h)   # <-- minf() thay vì min()
	# ---- 3. Cụm MOSFET đen dọc 2 bên ----
	var mos_w := w * 0.16
	var mos_h := h * 0.09
	for side_sign: float in [-1.0, 1.0]:      # <-- type tường minh
		var x: float = (w * 0.5 - mos_w * 0.65) * side_sign
		for row in range(3):
			var y: float = t + h * 0.30 + row * (mos_h * 1.35)
			var rpos: Vector2 = Vector2(x - mos_w * 0.5, y)
			cv.draw_rect(Rect2(rpos, Vector2(mos_w, mos_h)), chip_col, true)
			cv.draw_rect(Rect2(rpos, Vector2(mos_w, mos_h)), chip_edge, false, 1.0)
			for lead in range(3):
				var lx: float = rpos.x + mos_w * (0.2 + 0.3 * lead)
				cv.draw_line(Vector2(lx, rpos.y + mos_h), Vector2(lx, rpos.y + mos_h + 3), silver, 1.2)

	# ---- 4. 2 IC trung tâm ----
	var ic_w := w * 0.16
	var ic_h := h * 0.16
	var ic_y := t + h * 0.30
	for dx: float in [-1.0, 1.0]:             # <-- type tường minh
		var icx: float = dx * w * 0.11 - ic_w * 0.5
		var rpos: Vector2 = Vector2(icx, ic_y)
		cv.draw_rect(Rect2(rpos, Vector2(ic_w, ic_h)), chip_col, true)
		cv.draw_rect(Rect2(rpos, Vector2(ic_w, ic_h)), chip_edge, false, 1.0)
		cv.draw_circle(rpos + Vector2(4, 4), 1.6, silver)
		for pin in range(5):
			var py: float = rpos.y + ic_h * (0.15 + 0.7 * pin / 4.0)
			cv.draw_line(Vector2(rpos.x, py), Vector2(rpos.x - 3, py), silver, 1.0)
			cv.draw_line(Vector2(rpos.x + ic_w, py), Vector2(rpos.x + ic_w + 3, py), silver, 1.0)

	# ---- 5. Dãy chấm tín hiệu giữa 2 IC ----
	var dot_y0 := ic_y + ic_h * 0.15
	var dot_y1 := ic_y + ic_h * 0.85
	for i in range(6):
		var dy: float = lerp(dot_y0, dot_y1, float(i) / 5.0)
		cv.draw_circle(Vector2(0.0, dy), 1.8, silver)

	# ---- 6. Tụ điện nhỏ 4 góc trong ----
	var cap_positions := [
		Vector2(l + w * 0.28, t + h * 0.14),
		Vector2(l + w * 0.72, t + h * 0.14),
		Vector2(l + w * 0.28, t + h * 0.88),
		Vector2(l + w * 0.72, t + h * 0.88),
	]
	for cp in cap_positions:
		var cr: float = min_side * 0.03
		cv.draw_circle(cp, cr, cap_col)
		cv.draw_arc(cp, cr, 0, TAU, 16, Color(0.4, 0.4, 0.42), 1.0)

	# ---- 7. Nhãn silkscreen ----
	# ---- 7. Nhãn silkscreen — LẤY THẲNG TỪ PORTS "top" HIỆN CÓ ----
	var silk_text := {
		"PWR+": "VCC",
		"PWR-": "BAT",
		"GND":  "GND",
		"VBAT": "VBAT",
		"CURR": "CURR",
	}
	for port in ports:
		if port.get("side", "") != "top":
			continue
		var offset: float = port.get("offset", 0.5)
		var lx: float = l + w * offset
		var text: String = silk_text.get(port.name, port.get("label", port.name))
		cv.draw_string(ThemeDB.fallback_font, Vector2(lx, t + h * 0.09), text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 8, silk)
func _open_wiring_help() -> void:
	if is_instance_valid(_wiring_help_layer):
		return  # đã mở, tránh mở chồng

	_wiring_help_layer = CanvasLayer.new()
	_wiring_help_layer.layer = 100
	add_child(_wiring_help_layer)

	# Nền mờ — click ra ngoài để đóng
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_wiring_help()
	)
	_wiring_help_layer.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)

	var modal = PanelContainer.new()
	modal.mouse_filter = Control.MOUSE_FILTER_STOP  # chặn click xuyên xuống dim
	var modal_style = StyleBoxFlat.new()
	modal_style.bg_color = Color(0.13, 0.13, 0.16)
	modal_style.border_color = Color(0.28, 0.28, 0.32)
	modal_style.set_border_width_all(1)
	modal_style.set_corner_radius_all(8)
	modal_style.content_margin_left = 18
	modal_style.content_margin_right = 18
	modal_style.content_margin_top = 14
	modal_style.content_margin_bottom = 14
	modal.add_theme_stylebox_override("panel", modal_style)
	center.add_child(modal)

	var _resize_modal = func():
		if not is_instance_valid(modal): return
		var vp = get_viewport().get_visible_rect().size
		modal.custom_minimum_size = Vector2(
			clamp(vp.x * 0.6, 320, 620),
			clamp(vp.y * 0.75, 300, 640)
		)
	_resize_modal.call()
	get_viewport().size_changed.connect(_resize_modal)
	_wiring_help_layer.tree_exiting.connect(func():
		if get_viewport().size_changed.is_connected(_resize_modal):
			get_viewport().size_changed.disconnect(_resize_modal)
	)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	modal.add_child(vbox)

	# Header: tiêu đề + nút đóng
	var head_row = HBoxContainer.new()
	vbox.add_child(head_row)
	var title = Label.new()
	title.text = "Hướng dẫn đấu dây"
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(title)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(26, 26)
	close_btn.pressed.connect(_close_wiring_help)
	head_row.add_child(close_btn)

	var div2 = Panel.new()
	div2.custom_minimum_size = Vector2(0, 1)
	var div2_sb = StyleBoxFlat.new()
	div2_sb.bg_color = Color(0.24, 0.24, 0.28)
	div2.add_theme_stylebox_override("panel", div2_sb)
	vbox.add_child(div2)

	# Nội dung cuộn được
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	_add_help_section(content, "Sơ đồ đấu dây", _build_wiring_diagram())
	_add_help_text_section(content, "Kết nối chân (pin-to-pin)", [
		"• FC → ESC: tín hiệu PWM/DShot theo từng kênh motor",
		"• ESC → Motor: 3 dây pha (A, B, C), đảo 2 dây bất kỳ nếu quay sai chiều",
		"• Battery → ESC: dây nguồn (+)/(-) qua giắc XT60/XT30",
		"• FC → Battery: dây đo áp, nếu ESC không có BEC báo áp tích hợp",
	])
	_add_help_text_section(content, "Các bước kết nối", [
		"1. Gắn Frame, xác định vị trí 4 motor theo cấu hình X",
		"2. Lắp Motor vào từng góc, cố định ESC gần motor tương ứng",
		"3. Nối 3 dây pha Motor → ESC",
		"4. Nối tín hiệu ESC → FC đúng thứ tự kênh (motor mixing)",
		"5. Cấp nguồn Battery → ESC, kiểm tra cực tính trước khi cắm",
		"6. Gắn Propeller đúng chiều xoay (CW/CCW) theo từng góc",
	])
	content.add_child(_build_safety_note(
		"⚠ Luôn kiểm tra cực tính (+/-) trước khi cắm pin. Đấu ngược cực có thể " +
		"cháy ESC/FC ngay lập tức. Tháo cánh quạt khi test motor không tải."
	))


func _close_wiring_help() -> void:
	if is_instance_valid(_wiring_help_layer):
		_wiring_help_layer.queue_free()
	_wiring_help_layer = null
func _add_help_section(parent: VBoxContainer, title_text: String, body: Control) -> void:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	var lbl = Label.new()
	lbl.text = title_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	section.add_child(lbl)
	section.add_child(body)
	parent.add_child(section)

func _add_help_text_section(parent: VBoxContainer, title_text: String, lines: Array) -> void:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)
	var lbl = Label.new()
	lbl.text = title_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	section.add_child(lbl)
	for line in lines:
		var l = Label.new()
		l.text = line
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		section.add_child(l)
	parent.add_child(section)

func _build_safety_note(text: String) -> Control:
	var box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.18, 0.05, 0.35)
	style.border_color = Color(0.9, 0.55, 0.15)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", style)
	var lbl = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.7))
	box.add_child(lbl)
	return box

func _build_wiring_diagram() -> Control:
	var wrap = CenterContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var diagram = Control.new()
	diagram.custom_minimum_size = Vector2(480, 150)
	diagram.draw.connect(_draw_wiring_diagram.bind(diagram))
	wrap.add_child(diagram)
	return wrap

func _draw_wiring_diagram(diagram: Control) -> void:
	var box_size = Vector2(110, 40)
	var battery_pos = Vector2(10, 55)
	var esc_pos     = Vector2(185, 55)
	var motor_pos   = Vector2(360, 55)
	var fc_pos      = Vector2(185, 5)

	var box_color = Color(0.20, 0.20, 0.24)
	var border    = Color(0.4, 0.75, 0.95)
	var text_col  = Color(0.85, 0.85, 0.9)
	var font: Font = ThemeDB.fallback_font
	var font_size := 12

	for b in [
		{"pos": battery_pos, "label": "Battery"},
		{"pos": esc_pos,     "label": "ESC"},
		{"pos": motor_pos,   "label": "Motor"},
		{"pos": fc_pos,      "label": "FC"},
	]:
		var r = Rect2(b.pos, box_size)
		diagram.draw_rect(r, box_color, true)
		diagram.draw_rect(r, border, false, 1.5)
		var text_size = font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = b.pos + box_size * 0.5 - text_size * 0.5 + Vector2(0, text_size.y * 0.3)
		diagram.draw_string(font, text_pos, b.label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_col)

	var arrow_col = Color(0.9, 0.6, 0.2)
	_draw_arrow(diagram, battery_pos + Vector2(box_size.x, box_size.y * 0.5), esc_pos + Vector2(0, box_size.y * 0.5), arrow_col)
	_draw_arrow(diagram, esc_pos + Vector2(box_size.x, box_size.y * 0.5), motor_pos + Vector2(0, box_size.y * 0.5), arrow_col)
	_draw_arrow(diagram, fc_pos + Vector2(box_size.x * 0.5, box_size.y), esc_pos + Vector2(box_size.x * 0.5, 0), Color(0.5, 0.85, 0.5))

func _draw_arrow(diagram: Control, from: Vector2, to: Vector2, color: Color) -> void:
	diagram.draw_line(from, to, color, 2.0)
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var head := 6.0
	diagram.draw_line(to, to - dir * head + perp * head * 0.6, color, 2.0)
	diagram.draw_line(to, to - dir * head - perp * head * 0.6, color, 2.0)
func _draw_battery_body(cv: CanvasItem, sz: Vector2, col: Color, selected: bool) -> void:
	var local_pos = -sz * 0.5
	var radius := 8

	# Shadow (bo góc)
	var sb_shadow := StyleBoxFlat.new()
	sb_shadow.bg_color = Color(0, 0, 0, 0.35)
	sb_shadow.set_corner_radius_all(radius)
	cv.draw_style_box(sb_shadow, Rect2(local_pos + Vector2(4, 4), sz))

	# Body (bo góc)
	var sb_body := StyleBoxFlat.new()
	sb_body.bg_color = col.darkened(0.55)
	sb_body.set_corner_radius_all(radius)
	cv.draw_style_box(sb_body, Rect2(local_pos, sz))

	# Border (bo góc)
	var sb_border := StyleBoxFlat.new()
	sb_border.bg_color = Color(0, 0, 0, 0)
	sb_border.set_corner_radius_all(radius)
	sb_border.set_border_width_all(3 if selected else 1.5)
	sb_border.border_color = Color(1, 1, 1, 0.9) if selected else col.lightened(0.1)
	cv.draw_style_box(sb_border, Rect2(local_pos, sz))


func _draw_battery_details(cv: CanvasItem, sz: Vector2, col: Color) -> void:
	var local_pos = -sz * 0.5
	var pad := 6.0
	var inner := Rect2(local_pos + Vector2(pad, pad), sz - Vector2(pad * 2, pad * 2))

	# Panel vỏ pin (sáng hơn body 1 chút)
	var sb_wrap := StyleBoxFlat.new()
	sb_wrap.bg_color = col.darkened(0.28)
	sb_wrap.set_corner_radius_all(5)
	cv.draw_style_box(sb_wrap, inner)

	# Các vạch dọc mô phỏng nhãn cuốn quanh pin LiPo
	var stripe_color := col.lightened(0.15)
	stripe_color.a = 0.55
	var n_stripes := 4
	var gap := inner.size.x / float(n_stripes + 1)
	for i in range(n_stripes):
		var x = inner.position.x + gap * (i + 1)
		cv.draw_rect(Rect2(Vector2(x - 2, inner.position.y + 4), Vector2(4, inner.size.y - 8)),
			stripe_color, true)
