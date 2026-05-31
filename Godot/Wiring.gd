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
		# FC signal bus — giữa bên phải
		{"name":"FC_BUS","side":"bottom","offset":0.50,"type":"signal_out","label":"FC","color":Color(0.22,0.80,0.55),"big":true,"connector_style":"wide_inset"},
		# Power — trên đỉnh giữa
		{"name":"PWR+","side":"top","offset":0.38,"type":"power_pos","label":"+","color":Color(0.88,0.22,0.22),"big":false},
		{"name":"PWR-","side":"top","offset":0.62,"type":"power_neg","label":"–","color":Color(0.45,0.45,0.45),"big":false},
		{"name":"GND","side":"top","offset":0.80,"type":"ground","label":"G","color":Color(0.35,0.35,0.35),"big":false},
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
			{"name":"S1","side":"bottom","offset":0.20,"type":"pwm_out","label":"S1","color":Color(0.92,0.72,0.10),"big":false},
			{"name":"S2","side":"bottom","offset":0.36,"type":"pwm_out","label":"S2","color":Color(0.92,0.72,0.10),"big":false},
			{"name":"S3","side":"bottom","offset":0.52,"type":"pwm_out","label":"S3","color":Color(0.92,0.72,0.10),"big":false},
			{"name":"S4","side":"bottom","offset":0.68,"type":"pwm_out","label":"S4","color":Color(0.92,0.72,0.10),"big":false},
			{"name":"GND","side":"bottom","offset":0.86,"type":"ground","label":"G","color":Color(0.35,0.35,0.35),"big":false},
			{"name":"ESC_BUS","side":"top","offset":0.50,"type":"signal_in","label":"ESC","color":Color(0.22,0.80,0.55),"big":true,"connector_style":"wide_inset"},
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

	var sv = VBoxContainer.new()
	sv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sv.add_theme_constant_override("separation", 0)
	sidebar.add_child(sv)

	var hdr = Label.new()
	hdr.text = "   Components"
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	hdr.custom_minimum_size = Vector2(0, 30)
	hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sv.add_child(hdr)

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
	btn.text = "▾  " + cat
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
	btn.custom_minimum_size = Vector2(0, 28)
	var bsb = StyleBoxFlat.new()
	bsb.bg_color = Color(0.16, 0.16, 0.18)
	bsb.content_margin_left = 8
	for st in ["normal","hover","pressed"]:
		btn.add_theme_stylebox_override(st, bsb)
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
	isb.border_color = cdef.color.darkened(0.15)
	isb.border_width_left = 3
	isb.corner_radius_top_right = 4
	isb.corner_radius_bottom_right = 4
	isb.content_margin_left = 10
	item.add_theme_stylebox_override("panel", isb)

	var lbl = Label.new()
	lbl.text = comp_name
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(lbl)
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
	#for conn in connections:
		#var fp = _port_world_pos(conn.from_comp, conn.from_port)
		#var tp = _port_world_pos(conn.to_comp,   conn.to_port)
		#var wc = _wire_color(conn.from_port.get("type",""))
		#if not conn.get("valid", true): wc = Color(0.88, 0.22, 0.22)
		#_draw_wire(fp, tp, wc)
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

	# Rotation toolbar for selected component
	var sel = _get_selected_comp()
	if sel.size() > 0:
		_draw_rotation_toolbar(sel)

	# Tooltip
	if wire_tip_text != "" and wire_tip_timer > 0:
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

func _draw_component(comp: Dictionary):
	var cv  = canvas
	var pos = comp.pos
	var sz  = comp.size
	var col = comp.color
	var rot = comp.get("rotation_deg", 0)

	# Push transform for rotation around component center
	var ctr = pos + sz * 0.5
	cv.draw_set_transform(pan_offset + ctr * zoom_level, deg_to_rad(rot), Vector2(zoom_level, zoom_level))
	var local_pos = -sz * 0.5   # draw relative to center

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

	# Selection glow (outer rect)
	if comp.selected:
		cv.draw_rect(Rect2(local_pos - Vector2(3,3), sz + Vector2(6,6)),
			Color(1,1,1,0.18), false, 1.0)

	# Ports (in local rotated space — ports are positioned without pan/zoom since transform handles it)
	#for port in comp.ports:
		#_draw_port_local(cv, sz, port)
	## Restore world transform BEFORE drawing the name so text never rotates
	#cv.draw_set_transform(pan_offset, 0.0, Vector2(zoom_level, zoom_level))
	## Name label in world space (always upright, centered on component)
	#cv.draw_string(ThemeDB.fallback_font,
		#pos + Vector2(0, sz.y * 0.5 + 5),
		#comp.name, HORIZONTAL_ALIGNMENT_CENTER, int(sz.x),
		#int(11 * zoom_level), Color(0.95, 0.95, 0.95))
	# Ports (in local rotated space — shape only, no label)
	for port in comp.ports:
		_draw_port_local(cv, sz, port)

	# Restore world transform — tất cả text vẽ sau đây đều upright
	cv.draw_set_transform(pan_offset, 0.0, Vector2(zoom_level, zoom_level))

	# Port labels — tính world pos của từng port rồi vẽ thẳng, không bị xoay
	for port in comp.ports:
		var wp  = _port_world_pos(comp, port)
		var big = port.get("big", false)
		var pc  = port.get("color", Color(0.6, 0.6, 0.6))
		var loff = _port_label_offset_world(comp, port, big)
		cv.draw_string(ThemeDB.fallback_font, wp + loff,
			port.get("label", port.name), HORIZONTAL_ALIGNMENT_CENTER, -1,
			int(9 * zoom_level), pc.lightened(0.35))

	# Name label
	cv.draw_string(ThemeDB.fallback_font,
		pos + Vector2(0, sz.y * 0.5 + 5),
		comp.name, HORIZONTAL_ALIGNMENT_CENTER, int(sz.x),
		int(11 * zoom_level), Color(0.95, 0.95, 0.95))



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

	# Port in local space
	#for port in comp.ports:
		#_draw_port_local_circle(cv, r, port)
#
	## Restore world transform BEFORE drawing the label so text never rotates
	#cv.draw_set_transform(pan_offset, 0.0, Vector2(zoom_level, zoom_level))
#
	## Label in world space (centered on motor, always upright)
	#cv.draw_string(ThemeDB.fallback_font,
		#ctr + Vector2(-r, 5),
		#"Motor", HORIZONTAL_ALIGNMENT_CENTER, int(r * 2),
		#int(11 * zoom_level), Color(0.95, 0.95, 0.95))
	# Port in local space (shape only)
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

	#var loff = _port_label_offset(port, big)
	#cv.draw_string(ThemeDB.fallback_font, pp + loff,
		#port.get("label", port.name), HORIZONTAL_ALIGNMENT_CENTER, -1, 9,
		#pc.lightened(0.35))


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

	#var loff = _port_label_offset(port, big)
	#cv.draw_string(ThemeDB.fallback_font, pp + loff,
		#port.get("label", port.name), HORIZONTAL_ALIGNMENT_CENTER, -1, 9,
		#pc.lightened(0.35))

#func _draw_wire(from: Vector2, to: Vector2, col: Color):
	#var cv  = canvas
	#var dx  = to.x - from.x
	#var cp1 = from + Vector2(dx * 0.55, 0)
	#var cp2 = to   - Vector2(dx * 0.55, 0)
	#var pts = PackedVector2Array()
	#for i in range(25):
		#var t = float(i) / 24.0
		#pts.append(_cubic_bezier(from, cp1, cp2, to, t))
	#for i in range(pts.size() - 1):
		#cv.draw_line(pts[i], pts[i+1], col, 2.2, true)
	#cv.draw_circle(from, 4.0, col)
	#cv.draw_circle(to,   4.0, col)
#
#func _cubic_bezier(p0,p1,p2,p3: Vector2, t: float) -> Vector2:
	#var u = 1.0 - t
	#return u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3
	#them moi
func _draw_wire(from: Vector2, to: Vector2, col: Color, bend_pts: Array = [], conn_idx: int = -1):
	var cv = canvas

	# Gom tất cả điểm: from → bends → to
	var all_pts: Array[Vector2] = []
	all_pts.append(from)
	for bp in bend_pts:
		all_pts.append(bp)
	all_pts.append(to)

	# Vẽ orthogonal giữa từng cặp điểm liền kề
	for i in range(all_pts.size() - 1):
		var a = all_pts[i]
		var b = all_pts[i + 1]
		var corner = Vector2(b.x, a.y)   # ngang trước, dọc sau
		cv.draw_line(a, corner, col, 2.2, true)
		cv.draw_line(corner, b, col, 2.2, true)
		# Chấm tròn tại góc khuỷu để dễ thấy
		cv.draw_circle(corner, 3.0, col.darkened(0.2))

	# Endpoint dots
	cv.draw_circle(from, 4.5, col)
	cv.draw_circle(to,   4.5, col)

	# Bend handles — chỉ vẽ khi là connection thật
	if conn_idx >= 0:
		for bp in bend_pts:
			cv.draw_circle(bp, BEND_RADIUS + 2, Color(0.08, 0.08, 0.10, 0.85))
			cv.draw_circle(bp, BEND_RADIUS, col.darkened(0.3))
			cv.draw_arc(bp, BEND_RADIUS, 0, TAU, 18, col.lightened(0.2), 2.0, true)

		# Chấm gợi ý tại giữa mỗi đoạn ngang + đoạn dọc (click để thêm bend)
		for i in range(all_pts.size() - 1):
			var a = all_pts[i]
			var b = all_pts[i + 1]
			var corner = Vector2(b.x, a.y)
			# midpoint của đoạn ngang
			var mh = (a + corner) * 0.5
			# midpoint của đoạn dọc
			var mv = (corner + b) * 0.5
			for hint in [mh, mv]:
				cv.draw_circle(hint, 4.0, Color(col.r, col.g, col.b, 0.18))
				cv.draw_arc(hint, 4.0, 0, TAU, 12, Color(col.r, col.g, col.b, 0.45), 1.5, true)
# ─────────────────────────────── INPUT ────────────────────────────
func _canvas_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mp = event.position

		# ── Zoom via scroll wheel ──────────────────────────────────
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(zoom_level * (1.0 + ZOOM_STEP), mp)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(zoom_level * (1.0 - ZOOM_STEP), mp)
			return

		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
			pan_start = mp - pan_offset
			return

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var bh = _hit_bend_point(mp)
			if bh.size() > 0:
				var bps = connections[bh.conn_idx]["bend_points"]
				bps.remove_at(bh.pt_idx)
				connections[bh.conn_idx]["bend_points"] = bps
				canvas.queue_redraw()
				return
			var comp = _hit_component(mp)
			if comp.size() > 0:
				ctx_uid = comp.uid
				for c in canvas_components: c.selected = false
				comp.selected = true
				selected_uid  = comp.uid
				canvas.queue_redraw()
				ctx_menu.position = Vector2i(
					int(canvas.global_position.x + mp.x),
					int(canvas.global_position.y + mp.y)
				)
				ctx_menu.popup()
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check rotation toolbar buttons first
				if rot_toolbar_rect.has_point(mp):
					_handle_toolbar_click(mp)
					return
				var bh = _hit_bend_point(mp)
				if bh.size() > 0:
					drag_bend = bh
					canvas.queue_redraw()
					return

				# Click vào hint dot → thêm bend point mới rồi kéo ngay
				var wh = _hit_wire_hint(mp)
				if wh.size() > 0 and not wire_active:
					var bps = connections[wh.conn_idx].get("bend_points", [])
					bps.insert(wh.insert_after, wh.pos)
					connections[wh.conn_idx]["bend_points"] = bps
					drag_bend = {"conn_idx": wh.conn_idx, "pt_idx": wh.insert_after}
					canvas.queue_redraw()
					return

				# Port hit?
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

				# Component drag / selection
				var comp = _hit_component(mp)
				if comp.size() > 0:
					drag_comp   = comp
					drag_offset = mp - _world_to_screen(comp.pos)
					for c in canvas_components: c.selected = false
					comp.selected = true
					selected_uid  = comp.uid
					canvas.queue_redraw()
				else:
					# Click on empty canvas — deselect
					for c in canvas_components: c.selected = false
					selected_uid = -1
					canvas.queue_redraw()
			else:
				if drag_comp.size() > 0:
					drag_comp.pos = _snap_to_grid(drag_comp.pos)
					drag_comp = {}
					canvas.queue_redraw()
				if drag_bend.size() > 0:
					drag_bend = {}
					canvas.queue_redraw()

	elif event is InputEventMouseMotion:
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
			comp["rotation_deg"] = (comp.get("rotation_deg", 0) + delta_deg + 360) % 360
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

	connections.append({
		"from_comp": from.comp, "from_port": from.port,
		"to_comp":   to.comp,   "to_port":   to.port,
		"valid": ok,
		"bend_points": [],
	})

	if not ok:
		_show_tip("⚠ Incompatible: " + ft + " ↔ " + tt, _world_to_screen(from.pos))
	else:
		wire_tip_text = ""

	canvas.queue_redraw()

func _delete_component(uid: int):
	canvas_components = canvas_components.filter(func(c): return c.uid != uid)
	connections = connections.filter(func(c):
		return c.from_comp.uid != uid and c.to_comp.uid != uid)
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

func is_wiring_complete() -> Dictionary:
	var result = {"ok": false, "reason": ""}
	
	# Kiểm tra có đủ components cần thiết không
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
	
	# Kiểm tra connections bắt buộc
	var bat_to_esc = false      # Battery+ → ESC PWR+
	var esc_to_fc = false       # ESC FC_BUS → FC ESC_BUS
	var motors_connected = 0    # ESC M1-M4 → Motor PHASE
	var esc_gnd_to_fc = false   # ESC GND → FC GND
	
	for conn in connections:
		if not conn.get("valid", false):
			continue
		
		var fn = conn.from_comp.name
		var tn = conn.to_comp.name
		var fp = conn.from_port.name
		var tp = conn.to_port.name
		
		# Battery → ESC power
		if (fn == "Battery" and tn == "4-in-1 ESC") or (fn == "4-in-1 ESC" and tn == "Battery"):
			if fp in ["BAT+","BAT-","PWR+","PWR-"] or tp in ["BAT+","BAT-","PWR+","PWR-"]:
				bat_to_esc = true
		
		# ESC → FC signal
		if (fn == "4-in-1 ESC" and tn == "Flight Controller") or (fn == "Flight Controller" and tn == "4-in-1 ESC"):
			if fp in ["FC_BUS","ESC_BUS"] or tp in ["FC_BUS","ESC_BUS"]:
				esc_to_fc = true
			if fp == "GND" or tp == "GND":
				esc_gnd_to_fc = true
		
		# ESC → Motor
		if (fn == "4-in-1 ESC" and tn == "Motor") or (fn == "Motor" and tn == "4-in-1 ESC"):
			motors_connected += 1
	
	if not bat_to_esc:
		result.reason = "Wiring: Battery not connected to ESC"
		return result
	if not esc_to_fc:
		result.reason = "Wiring: ESC not connected to Flight Controller"
		return result
	if not esc_gnd_to_fc:
		result.reason = "Wiring: ESC GND not connected to Flight Controller GND"
		return result
	if motors_connected < motor_count:
		result.reason = "Wiring: %d/%d motors connected to ESC" % [motors_connected, motor_count]
		return result
	
	result.ok = true
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
	var steps = (rot / 90) % 4
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
