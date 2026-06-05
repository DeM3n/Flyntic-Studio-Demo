
extends Control

# ── Node refs ──────────────────────────────────────────────────────
var email_input:     LineEdit
var password_input:  LineEdit
var login_btn:       Button
var error_label:     Label
var loading_label:   Label
var show_pass_btn:   Button
var forgot_btn:      Button
var version_label:   Label

# ── Color palette ─────────────────────────────────────────────────
const C_BG_LEFT      = Color(0.051, 0.055, 0.078)   # #0D0E14
const C_BG_RIGHT     = Color(0.043, 0.047, 0.063)   # #0B0C10
const C_DIVIDER      = Color(0.110, 0.114, 0.149)   # #1C1D26
const C_ACCENT       = Color(0.188, 0.502, 0.957)   # #3080F4
const C_ACCENT_HOVER = Color(0.239, 0.553, 1.000)
const C_ACCENT_PRESS = Color(0.157, 0.424, 0.843)
const C_INPUT_BG     = Color(0.059, 0.063, 0.078)   # #0F1014
const C_INPUT_BORDER = Color(0.165, 0.169, 0.220)   # #2A2B38
const C_INPUT_FOCUS  = Color(0.188, 0.502, 0.957, 0.70)
const C_TEXT_PRIMARY = Color(0.925, 0.929, 0.961)   # #ECEDF5
const C_TEXT_MUTED   = Color(0.314, 0.322, 0.392)   # #50526A
const C_TEXT_LABEL   = Color(0.616, 0.627, 0.690)   # #9DA0B0
const C_TEXT_FOOTER  = Color(0.165, 0.169, 0.235)   # #2A2B3C
const C_ERROR        = Color(1.000, 0.380, 0.380)
const C_GRID         = Color(0.110, 0.114, 0.149, 0.90)
const C_STUDIO_TAG   = Color(0.188, 0.502, 0.957)
const C_BRAND        = Color(0.925, 0.929, 0.961)

# ── Ready ──────────────────────────────────────────────────────────
func _ready():
	_build_ui()
	AuthManager.access_granted.connect(_on_granted, CONNECT_ONE_SHOT)
	AuthManager.access_denied.connect(_on_denied, CONNECT_ONE_SHOT)
	AuthManager.login_failed.connect(_on_login_failed, CONNECT_ONE_SHOT)
	if AuthManager.has_session():
		_set_loading(true)
		AuthManager.check_license()

# ══════════════════════════════════════════════════════════════════
func _build_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Root HBox (full screen split) ─────────────────────────────
	var root_hbox = HBoxContainer.new()
	root_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_hbox.add_theme_constant_override("separation", 0)
	add_child(root_hbox)

	# ══ LEFT PANEL (60%) ══════════════════════════════════════════
	var left = _build_left_panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.6
	root_hbox.add_child(left)

	# ══ RIGHT PANEL (40%) ═════════════════════════════════════════
	var right = _build_right_panel()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.4
	root_hbox.add_child(right)


func _build_left_panel() -> Control:
	var left = Control.new()
	left.clip_contents = false

	var bg = ColorRect.new()
	bg.color = C_BG_LEFT
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(bg)

	var grid = _GridDraw.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(grid)

	var edge = ColorRect.new()
	edge.color = C_DIVIDER
	edge.set_anchor(SIDE_LEFT,   1.0)
	edge.set_anchor(SIDE_RIGHT,  1.0)
	edge.set_anchor(SIDE_TOP,    0.0)
	edge.set_anchor(SIDE_BOTTOM, 1.0)
	edge.offset_left  = -1
	edge.offset_right = 0
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(edge)

	## Drone — full panel, nhận mouse toàn vùng
	#var drone_graphic = _DroneDraw.new()
	#drone_graphic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#drone_graphic.mouse_filter = Control.MOUSE_FILTER_PASS
	#left.add_child(drone_graphic)

	# Text content — đặt sau drone để hiện lên trên
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   52)
	margin.add_theme_constant_override("margin_right",  48)
	margin.add_theme_constant_override("margin_top",    48)
	margin.add_theme_constant_override("margin_bottom", 36)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(margin)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 0)
	outer_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ← KHÔNG dùng SIZE_EXPAND_FILL, để vbox tự co theo nội dung
	outer_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(outer_vbox)

	# ── Logo row ──────────────────────────────────────────────────
	#var logo_row = HBoxContainer.new()
	#logo_row.add_theme_constant_override("separation", 12)
	#logo_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#outer_vbox.add_child(logo_row)
#
	#logo_row.add_child(_make_logo_icon())
#
	#var brand_lbl = Label.new()
	#brand_lbl.text = "FLYNTIC"
	#brand_lbl.add_theme_font_size_override("font_size", 22)
	#brand_lbl.add_theme_color_override("font_color", C_BRAND)
	#brand_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	#brand_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#logo_row.add_child(brand_lbl)
	# ── Logo row ──────────────────────────────────────────────────────
	var logo_row = HBoxContainer.new()
	logo_row.add_theme_constant_override("separation", 12)
	logo_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(logo_row)

	logo_row.add_child(_make_logo_icon())

# VBox chứa FLYNTIC + STUDIO xếp dọc
	var brand_vbox = VBoxContainer.new()
	brand_vbox.add_theme_constant_override("separation", 2)
	brand_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_row.add_child(brand_vbox)

	var brand_lbl = Label.new()
	brand_lbl.text = "FLYNTIC"
	brand_lbl.add_theme_font_size_override("font_size", 22)
	brand_lbl.add_theme_color_override("font_color", C_BRAND)
	brand_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_vbox.add_child(brand_lbl)

	var studio_lbl = Label.new()
	studio_lbl.text = "STUDIO"
	studio_lbl.add_theme_font_size_override("font_size", 10)
	studio_lbl.add_theme_color_override("font_color", C_STUDIO_TAG)
	studio_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_vbox.add_child(studio_lbl)
	_add_spacer(outer_vbox, 5)




	# ← KHÔNG có center_spacer nữa, thay bằng khoảng cách cố định
	_add_spacer(outer_vbox, 28)

	var tagline1 = Label.new()
	tagline1.text = "Digital"
	tagline1.add_theme_font_size_override("font_size", 32)
	tagline1.add_theme_color_override("font_color", C_TEXT_PRIMARY)
	tagline1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(tagline1)

	var tagline2 = Label.new()
	tagline2.text = "Drone Training"
	tagline2.add_theme_font_size_override("font_size", 32)
	tagline2.add_theme_color_override("font_color", C_ACCENT)
	tagline2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(tagline2)

	var tagline3 = Label.new()
	tagline3.text = "Platform"
	tagline3.add_theme_font_size_override("font_size", 32)
	tagline3.add_theme_color_override("font_color", C_TEXT_PRIMARY)
	tagline3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(tagline3)

	_add_spacer(outer_vbox, 14)

	var sub_tag = Label.new()
	sub_tag.text = "Simulation · Certification · Navigation"
	sub_tag.add_theme_font_size_override("font_size", 13)
	sub_tag.add_theme_color_override("font_color", C_TEXT_MUTED)
	sub_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_vbox.add_child(sub_tag)

	# Copyright — đặt riêng, anchor xuống bottom-left
	var copy_lbl = Label.new()
	copy_lbl.text = "© 2025 Flyntic Inc. All rights reserved."
	copy_lbl.add_theme_font_size_override("font_size", 11)
	copy_lbl.add_theme_color_override("font_color", C_TEXT_FOOTER)
	copy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_lbl.set_anchor(SIDE_LEFT,   0.0)
	copy_lbl.set_anchor(SIDE_RIGHT,  1.0)
	copy_lbl.set_anchor(SIDE_TOP,    1.0)
	copy_lbl.set_anchor(SIDE_BOTTOM, 1.0)
	copy_lbl.offset_top    = -52
	copy_lbl.offset_bottom = -36
	copy_lbl.offset_left   = 52
	left.add_child(copy_lbl)  # thêm thẳng vào left, không qua vbox
	var drone_graphic = _DroneDraw.new()
	drone_graphic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drone_graphic.mouse_filter = Control.MOUSE_FILTER_PASS
	left.add_child(drone_graphic)
	return left
# ── RIGHT: Login form panel ───────────────────────────────────────
func _build_right_panel() -> Control:
	var right = Control.new()

	var bg = ColorRect.new()
	bg.color = C_BG_RIGHT
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right.add_child(bg)

	# Center the form vertically
	var vcenter = VBoxContainer.new()
	vcenter.set_anchor(SIDE_LEFT,   0.0)
	vcenter.set_anchor(SIDE_RIGHT,  1.0)
	vcenter.set_anchor(SIDE_TOP,    0.5)
	vcenter.set_anchor(SIDE_BOTTOM, 0.5)
	vcenter.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vcenter.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vcenter.add_theme_constant_override("separation", 0)
	right.add_child(vcenter)

	# Horizontal margin inside right panel
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  40)
	margin.add_theme_constant_override("margin_right", 40)
	vcenter.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)

	# ── Welcome heading ───────────────────────────────────────────
	var welcome = Label.new()
	welcome.text = "Welcome back"
	welcome.add_theme_font_size_override("font_size", 22)
	welcome.add_theme_color_override("font_color", C_TEXT_PRIMARY)
	vbox.add_child(welcome)

	_add_spacer(vbox, 6)

	var sub = Label.new()
	sub.text = "Sign in to your account"
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", C_TEXT_MUTED)
	vbox.add_child(sub)

	_add_spacer(vbox, 32)

	# ── Email ─────────────────────────────────────────────────────
	_add_field_label(vbox, "Email address")
	_add_spacer(vbox, 6)
	email_input = LineEdit.new()
	email_input.placeholder_text = "you@example.com"
	email_input.custom_minimum_size = Vector2(0, 46)
	_style_input(email_input)
	vbox.add_child(email_input)

	_add_spacer(vbox, 14)

	# ── Password ──────────────────────────────────────────────────
	_add_field_label(vbox, "Password")
	_add_spacer(vbox, 6)

	var pass_container = Control.new()
	pass_container.custom_minimum_size = Vector2(0, 46)
	pass_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(pass_container)

	password_input = LineEdit.new()
	password_input.placeholder_text = "Enter your password"
	password_input.secret = true
	password_input.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_style_input(password_input)
	password_input.text_submitted.connect(func(_t): _on_login_pressed())
	pass_container.add_child(password_input)

	show_pass_btn = Button.new()
	show_pass_btn.text = "Show"
	show_pass_btn.flat = true
	show_pass_btn.set_anchor(SIDE_LEFT,   1.0)
	show_pass_btn.set_anchor(SIDE_RIGHT,  1.0)
	show_pass_btn.set_anchor(SIDE_TOP,    0.0)
	show_pass_btn.set_anchor(SIDE_BOTTOM, 1.0)
	show_pass_btn.offset_left  = -58
	show_pass_btn.offset_right = -6
	show_pass_btn.add_theme_color_override("font_color",       C_TEXT_MUTED)
	show_pass_btn.add_theme_color_override("font_hover_color", C_ACCENT)
	show_pass_btn.add_theme_font_size_override("font_size", 11)
	show_pass_btn.pressed.connect(_toggle_password_visibility)
	pass_container.add_child(show_pass_btn)

	# ── Forgot password ───────────────────────────────────────────
	_add_spacer(vbox, 10)
	var opt_row = HBoxContainer.new()
	vbox.add_child(opt_row)

	var spacer_fill = Control.new()
	spacer_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_row.add_child(spacer_fill)

	forgot_btn = Button.new()
	forgot_btn.text = "Forgot password?"
	forgot_btn.flat = true
	forgot_btn.add_theme_color_override("font_color",       C_ACCENT)
	forgot_btn.add_theme_color_override("font_hover_color", C_ACCENT_HOVER)
	forgot_btn.add_theme_font_size_override("font_size", 12)
	# forgot_btn.pressed.connect(_on_forgot_pressed)
	opt_row.add_child(forgot_btn)

	# ── Error label ───────────────────────────────────────────────
	_add_spacer(vbox, 8)
	error_label = Label.new()
	error_label.text = ""
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 12)
	error_label.add_theme_color_override("font_color", C_ERROR)
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(error_label)

	_add_spacer(vbox, 8)

	# ── Sign In button ────────────────────────────────────────────
	login_btn = Button.new()
	login_btn.text = "Sign In"
	login_btn.custom_minimum_size = Vector2(0, 50)
	_style_primary_button(login_btn)
	login_btn.pressed.connect(_on_login_pressed)
	vbox.add_child(login_btn)

	# ── Loading state ─────────────────────────────────────────────
	loading_label = Label.new()
	loading_label.text = "Authenticating…"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 13)
	loading_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	loading_label.custom_minimum_size = Vector2(0, 50)
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.visible = false
	vbox.add_child(loading_label)

	# ── Version ───────────────────────────────────────────────────
	_add_spacer(vbox, 24)
	version_label = Label.new()
	version_label.text = "v0.1.0 · Flyntic Studio"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 11)
	version_label.add_theme_color_override("font_color", C_TEXT_FOOTER)
	vbox.add_child(version_label)

	return right

# ── Helpers ───────────────────────────────────────────────────────
func _add_field_label(parent: Control, text: String):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_TEXT_LABEL)
	parent.add_child(lbl)

func _add_spacer(parent: Control, h: int):
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)

func _add_spacer_h(parent: Control, w: int):
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(w, 0)
	parent.add_child(sp)

func _make_logo_icon() -> Control:
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(30, 30)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load("res://Assets/Logo.png")
	return icon

func _style_input(input: LineEdit):
	var s = StyleBoxFlat.new()
	s.bg_color = C_INPUT_BG
	s.set_corner_radius_all(10)
	s.border_width_left = 1; s.border_width_right  = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.border_color = C_INPUT_BORDER
	s.content_margin_left = 14; s.content_margin_right = 14
	input.add_theme_stylebox_override("normal", s)
	var sf = StyleBoxFlat.new()
	sf.bg_color = C_INPUT_BG
	sf.set_corner_radius_all(10)
	sf.border_width_left = 1; sf.border_width_right  = 1
	sf.border_width_top  = 1; sf.border_width_bottom = 1
	sf.border_color = C_INPUT_FOCUS
	sf.content_margin_left = 14; sf.content_margin_right = 14
	input.add_theme_stylebox_override("focus", sf)
	input.add_theme_color_override("font_color",             C_TEXT_PRIMARY)
	input.add_theme_color_override("font_placeholder_color", C_TEXT_MUTED)
	input.add_theme_color_override("caret_color",            C_ACCENT)
	input.add_theme_color_override("selection_color",        Color(C_ACCENT, 0.28))
	input.add_theme_font_size_override("font_size", 14)

func _style_primary_button(btn: Button):
	var states = {"normal": C_ACCENT, "hover": C_ACCENT_HOVER, "pressed": C_ACCENT_PRESS}
	for state in states:
		var s = StyleBoxFlat.new()
		s.bg_color = states[state]
		s.set_corner_radius_all(10)
		btn.add_theme_stylebox_override(state, s)
	var sd = StyleBoxFlat.new()
	sd.bg_color = Color(C_ACCENT, 0.40)
	sd.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("disabled", sd)
	btn.add_theme_color_override("font_color",          Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color",    Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color",  Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))
	btn.add_theme_font_size_override("font_size", 15)

func _toggle_password_visibility():
	password_input.secret = not password_input.secret
	show_pass_btn.text = "Hide" if not password_input.secret else "Show"

# ── Logic (unchanged) ─────────────────────────────────────────────
func _on_login_pressed():
	var email    = email_input.text.strip_edges()
	var password = password_input.text
	if email == "" or password == "":
		error_label.text = "Please enter your email and password"
		return
	_set_loading(true)
	AuthManager.login(email, password)

func _on_granted(tier: String, tier_name: String, days_left: int):
	print("=== GRANTED: ", tier, " / ", tier_name, " / ", days_left)
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_denied(reason: String):
	print("=== DENIED: ", reason)
	_set_loading(false)
	AuthManager.access_denied.connect(_on_denied, CONNECT_ONE_SHOT)
	match reason:
		"no_subscription", "trial_expired":
			var popup = preload("res://Auth/TrialPopup.tscn").instantiate()
			add_child(popup)
			popup.show_offer(reason == "trial_expired")
		"invalid_token":
			error_label.text = "Your session has expired. Please sign in again"
		_:
			error_label.text = "Access denied"

func _on_login_failed(reason: String):
	print("=== LOGIN FAILED: ", reason)
	_set_loading(false)
	error_label.text = reason
	AuthManager.login_failed.connect(_on_login_failed, CONNECT_ONE_SHOT)

func _set_loading(on: bool):
	login_btn.visible       = not on
	loading_label.visible   = on
	email_input.editable    = not on
	password_input.editable = not on
	error_label.text        = ""

# ══ Inner class: Grid background ══════════════════════════════════
class _GridDraw extends Control:
	func _draw():
		var w = size.x; var h = size.y
		var col = Color(0.110, 0.114, 0.149, 0.90)
		var step = 52.0
		var x = 0.0
		while x <= w:
			draw_line(Vector2(x, 0), Vector2(x, h), col, 1.0)
			x += step
		var y = 0.0
		while y <= h:
			draw_line(Vector2(0, y), Vector2(w, y), col, 1.0)
			y += step
		# Corner brackets
		var bc = Color(0.188, 0.502, 0.957, 0.22)
		var blen = 18.0; var pad = 20.0
		draw_line(Vector2(pad, pad),         Vector2(pad+blen, pad),         bc, 1.5)
		draw_line(Vector2(pad, pad),         Vector2(pad, pad+blen),         bc, 1.5)
		draw_line(Vector2(w-pad, pad),       Vector2(w-pad-blen, pad),       bc, 1.5)
		draw_line(Vector2(w-pad, pad),       Vector2(w-pad, pad+blen),       bc, 1.5)
		draw_line(Vector2(pad, h-pad),       Vector2(pad+blen, h-pad),       bc, 1.5)
		draw_line(Vector2(pad, h-pad),       Vector2(pad, h-pad-blen),       bc, 1.5)
		draw_line(Vector2(w-pad, h-pad),     Vector2(w-pad-blen, h-pad),     bc, 1.5)
		draw_line(Vector2(w-pad, h-pad),     Vector2(w-pad, h-pad-blen),     bc, 1.5)

# ══ Inner class: Drone graphic ════════════════════════════════════
# ══ Inner class: Drone graphic (redesigned) ═══════════════════════
#class _DroneDraw extends Control:
	#const ACC     = Color(0.188, 0.502, 0.957)
	#const BODY_BG = Color(0.075, 0.086, 0.122)
	#const BODY_IN = Color(0.102, 0.125, 0.208)
	#const SHELL   = Color(0.165, 0.169, 0.220)
#
	#var _drone_pos  : Vector2 = Vector2.ZERO
	#var _target_pos : Vector2 = Vector2.ZERO
	#var _initialized: bool    = false
		## Idle state
	#var _is_hovering : bool    = false
	#var _idle_time   : float   = 0.0
	#var _idle_angle  : float   = 0.0
	#var _idle_center : Vector2 = Vector2.ZERO 
	#func _ready():
		#mouse_filter = Control.MOUSE_FILTER_PASS
		#set_process(true)
#
	#func _process(delta: float):
		#if not _initialized and size != Vector2.ZERO:
			#_drone_pos  = size * 0.5
			#_target_pos = size * 0.5
			#_initialized = true
		#if _is_hovering:
			## Theo chuột
			#_drone_pos = _drone_pos.lerp(_target_pos, 0.04)
		#else:
			## Idle: bay lượn theo hình sin chậm, tự drift
			#_idle_time  += delta
			#_idle_angle += delta * 0.4  # tốc độ xoay vòng
			## Lượn nhẹ theo ellipse quanh idle_center
			#var radius_x = size.x * 0.18
			#var radius_y = size.y * 0.10
			#var idle_target = _idle_center + Vector2(
				#cos(_idle_angle)        * radius_x,
				#sin(_idle_angle * 1.3)  * radius_y   # lệch tần số → hình 8 mềm
			#)
			#_drone_pos = _drone_pos.lerp(idle_target, 0.012) 
		#queue_redraw()
#
	#func _gui_input(event):
		#if event is InputEventMouseMotion:
			#_target_pos = event.position
#
	#func _notification(what: int):
		#if what == NOTIFICATION_MOUSE_EXIT:
			## Khi chuột rời panel: cập nhật idle_center = vị trí hiện tại
			## để drone không giật mạnh về góc nào
			#_idle_center = _drone_pos
			#_idle_angle  = 0.0
			#_is_hovering = false
#
	#func _draw():
		#var w = size.x
		#var h = size.y
#
		#var pts = _bezier_points(
			#Vector2(w * 0.04, h * 0.82),
			#Vector2(w * 0.35, h * 0.20),
			#Vector2(w * 0.70, h * 0.55),
			#Vector2(w * 0.96, h * 0.08),
			#40
		#)
		#var dash_on = true; var dash_len = 5.0; var acc_d = 0.0
		#for i in range(pts.size() - 1):
			#var seg_len = pts[i].distance_to(pts[i + 1])
			#if dash_on:
				#draw_line(pts[i], pts[i + 1], Color(ACC, 0.18), 1.0)
			#acc_d += seg_len
			#if acc_d >= dash_len:
				#acc_d   = 0.0
				#dash_on = not dash_on
#
		#var wp1 = Vector2(w * 0.04, h * 0.82)
		#var wp3 = Vector2(w * 0.96, h * 0.08)
		#draw_circle(wp1, 3.0, Color(ACC, 0.40))
		#draw_circle(wp3, 4.0, Color(ACC, 0.75))
		#draw_line(wp3 + Vector2(-12, 0), wp3 + Vector2(12, 0), Color(ACC, 0.50), 1.0)
		#draw_line(wp3 + Vector2(0, -12), wp3 + Vector2(0, 12), Color(ACC, 0.50), 1.0)
#
		#for rf in [0.06, 0.10]:
			#draw_arc(_drone_pos, w * rf, 0, TAU, 48, Color(ACC, 0.09), 1.0)
#
		#_draw_hud_box(Vector2(w * 0.60, h * 0.20), "ALT 320m")
		#_draw_hud_box(Vector2(w * 0.02, h * 0.62), "WP 01")
#
		#_draw_drone(_drone_pos, w * 0.10)
#
	#func _draw_drone(center: Vector2, arm: float):
		#var bw  = arm * 1.30
		#var bh  = arm * 0.80
		#var mt  = arm * 0.13
		#var bl  = arm * 0.88
#
		#var tips = []
		#for ang_deg in [-135.0, -45.0, 45.0, 135.0]:
			#tips.append(center + Vector2(cos(deg_to_rad(ang_deg)), sin(deg_to_rad(ang_deg))) * bl)
#
		#for tip in tips:
			#draw_line(center, tip, Color(ACC, 0.65), 1.3)
#
		#var prop_offsets = [-135.0, -45.0, 45.0, 135.0]
		#for i in range(4):
			#var tip = tips[i]
			#var base_ang = deg_to_rad(prop_offsets[i])
			#for blade_rot in [0.0, PI * 0.5]:
				#_draw_propeller_blade(tip, base_ang + blade_rot, arm * 0.30, arm * 0.065)
			#draw_circle(tip, mt + 1.5, Color(0.059, 0.063, 0.078))
			#draw_arc(tip, mt + 1.5, 0, TAU, 32, Color(ACC, 0.80), 1.0)
			#draw_circle(tip, mt * 0.35, Color(ACC, 0.55))
#
		## Body
		#var body_rect = Rect2(center - Vector2(bw * 0.5, bh * 0.5), Vector2(bw, bh))
		#draw_rect(body_rect, BODY_BG)
		#_draw_rect_border(body_rect, SHELL, 1.2)
#
		#var ir = Rect2(center - Vector2(bw * 0.33, bh * 0.28), Vector2(bw * 0.66, bh * 0.56))
		#draw_rect(ir, BODY_IN)
		#_draw_rect_border(ir, Color(ACC, 0.50), 0.8)
#
		## Accent stripe — cạnh TRÁI (mặt sau)
		#var stripe = Rect2(ir.position, Vector2(bw * 0.08, ir.size.y))
		#draw_rect(stripe, Color(ACC, 0.22))
#
		## Camera — cạnh PHẢI thân drone (mặt trước)
		#var cam_w = bh * 0.22   # mỏng theo chiều ngang
		#var cam_h = bh * 0.38
		#var cam_pos = Vector2(
			#center.x + bw * 0.5,                    # sát cạnh phải thân
			#center.y - cam_h * 0.5                  # căn giữa theo chiều dọc
		#)
		#var cam_rect = Rect2(cam_pos, Vector2(cam_w, cam_h))
		#draw_rect(cam_rect, Color(0.043, 0.047, 0.063))
		#_draw_rect_border(cam_rect, Color(ACC, 0.70), 0.8)
		## Lens
		#var lens_center = cam_pos + Vector2(cam_w * 0.5, cam_h * 0.5)
		#draw_circle(lens_center, cam_h * 0.28, Color(ACC, 0.45))
		#draw_circle(lens_center, cam_h * 0.14, Color(ACC, 0.85))
#
		## Center LED
		#draw_circle(center, 3.5, Color(ACC, 0.90))
		#draw_circle(center, 2.0, Color(0.925, 0.929, 0.961, 0.95))
#
	## Vẽ 1 cánh quạt dạng lá (ellipse dẹt, 2 đầu nhọn)
	#func _draw_propeller_blade(motor_center: Vector2, angle: float, length: float, width: float):
		#var points = PackedVector2Array()
		#var steps  = 12
		#for i in range(steps + 1):
			#var t   = float(i) / float(steps)
			## Tạo hình ellipse dọc theo trục angle
			## x theo trục cánh: từ -length đến +length
			## y vuông góc: sin curve tạo độ phồng giữa, nhọn 2 đầu
			#var lx  = (t * 2.0 - 1.0) * length          # -length .. +length
			#var ly  = sin(t * PI) * width                # 0 → width → 0 (1 phía)
			## Rotate theo angle
			#var px  = lx * cos(angle) - ly * sin(angle) + motor_center.x
			#var py  = lx * sin(angle) + ly * cos(angle) + motor_center.y
			#points.append(Vector2(px, py))
		## Phía dưới cánh (mirror)
		#for i in range(steps + 1):
			#var t   = 1.0 - float(i) / float(steps)
			#var lx  = (t * 2.0 - 1.0) * length
			#var ly  = -sin(t * PI) * width
			#var px  = lx * cos(angle) - ly * sin(angle) + motor_center.x
			#var py  = lx * sin(angle) + ly * cos(angle) + motor_center.y
			#points.append(Vector2(px, py))
		#draw_colored_polygon(points, Color(ACC, 0.45))
		## Outline cánh
		#draw_polyline(points, Color(ACC, 0.65), 0.7)
#
	#func _draw_rect_border(r: Rect2, col: Color, width: float):
		#var p = r.position; var s = r.size
		#draw_line(p,                     p + Vector2(s.x, 0), col, width)
		#draw_line(p + Vector2(s.x, 0),   p + s,               col, width)
		#draw_line(p + s,                 p + Vector2(0, s.y), col, width)
		#draw_line(p + Vector2(0, s.y),   p,                   col, width)
#
	#func _draw_hud_box(pos: Vector2, text: String):
		#var bw = 58.0; var bh = 18.0
		#var r  = Rect2(pos, Vector2(bw, bh))
		#draw_line(r.position,                   r.position + Vector2(bw, 0),  Color(ACC, 0.28), 0.8)
		#draw_line(r.position + Vector2(bw, 0),  r.position + Vector2(bw, bh), Color(ACC, 0.28), 0.8)
		#draw_line(r.position + Vector2(bw, bh), r.position + Vector2(0, bh),  Color(ACC, 0.28), 0.8)
		#draw_line(r.position + Vector2(0, bh),  r.position,                   Color(ACC, 0.28), 0.8)
#
	#func _bezier_points(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps: int) -> Array:
		#var result = []
		#for i in range(steps + 1):
			#var t  = float(i) / float(steps)
			#var mt = 1.0 - t
			#result.append(mt*mt*mt*p0 + 3*mt*mt*t*p1 + 3*mt*t*t*p2 + t*t*t*p3)
		#return result
# ══ Inner class: Drone graphic (redesigned) ═══════════════════════
class _DroneDraw extends Control:
	const ACC     = Color(0.188, 0.502, 0.957)
	const BODY_BG = Color(0.075, 0.086, 0.122)
	const BODY_IN = Color(0.102, 0.125, 0.208)
	const SHELL   = Color(0.165, 0.169, 0.220)

	var _drone_pos   : Vector2 = Vector2.ZERO
	var _target_pos  : Vector2 = Vector2.ZERO
	var _initialized : bool    = false

	# Idle state
	var _is_hovering : bool    = false
	var _idle_time   : float   = 0.0
	var _idle_angle  : float   = 0.0
	var _idle_center : Vector2 = Vector2.ZERO  # điểm neo idle bay quanh

	func _ready():
		mouse_filter = Control.MOUSE_FILTER_PASS
		set_process(true)

	func _process(delta: float):
		if not _initialized and size != Vector2.ZERO:
			_drone_pos   = size * Vector2(0.65, 0.55)
			_idle_center = _drone_pos
			_target_pos  = _drone_pos
			_initialized  = true

		if _is_hovering:
			# Theo chuột
			_drone_pos = _drone_pos.lerp(_target_pos, 0.04)
		else:
			# Idle: bay lượn theo hình sin chậm, tự drift
			_idle_time  += delta
			_idle_angle += delta * 0.4  # tốc độ xoay vòng

			# Lượn nhẹ theo ellipse quanh idle_center
			var radius_x = size.x * 0.18
			var radius_y = size.y * 0.10
			var idle_target = _idle_center + Vector2(
				cos(_idle_angle)        * radius_x,
				sin(_idle_angle * 1.3)  * radius_y   # lệch tần số → hình 8 mềm
			)
			_drone_pos = _drone_pos.lerp(idle_target, 0.012)  # rất chậm, mượt

		queue_redraw()

	func _gui_input(event: InputEvent):
		if event is InputEventMouseMotion:
			_target_pos  = event.position
			_is_hovering = true
		elif event is InputEventMouseButton:
			pass

	func _notification(what: int):
		if what == NOTIFICATION_MOUSE_EXIT:
			# Khi chuột rời panel: cập nhật idle_center = vị trí hiện tại
			# để drone không giật mạnh về góc nào
			_idle_center = _drone_pos
			_idle_angle  = 0.0
			_is_hovering = false

	func _draw():
		var w = size.x
		var h = size.y

		var pts = _bezier_points(
			Vector2(w * 0.04, h * 0.82),
			Vector2(w * 0.35, h * 0.20),
			Vector2(w * 0.70, h * 0.55),
			Vector2(w * 0.96, h * 0.08),
			40
		)
		var dash_on = true; var dash_len = 5.0; var acc_d = 0.0
		for i in range(pts.size() - 1):
			var seg_len = pts[i].distance_to(pts[i + 1])
			if dash_on:
				draw_line(pts[i], pts[i + 1], Color(ACC, 0.18), 1.0)
			acc_d += seg_len
			if acc_d >= dash_len:
				acc_d   = 0.0
				dash_on = not dash_on

		var wp1 = Vector2(w * 0.04, h * 0.82)
		var wp3 = Vector2(w * 0.96, h * 0.08)
		draw_circle(wp1, 3.0, Color(ACC, 0.40))
		draw_circle(wp3, 4.0, Color(ACC, 0.75))
		draw_line(wp3 + Vector2(-12, 0), wp3 + Vector2(12, 0), Color(ACC, 0.50), 1.0)
		draw_line(wp3 + Vector2(0, -12), wp3 + Vector2(0, 12), Color(ACC, 0.50), 1.0)

		for rf in [0.06, 0.10]:
			draw_arc(_drone_pos, w * rf, 0, TAU, 48, Color(ACC, 0.09), 1.0)

		_draw_hud_box(Vector2(w * 0.60, h * 0.20), "ALT 320m")
		_draw_hud_box(Vector2(w * 0.02, h * 0.62), "WP 01")

		_draw_drone(_drone_pos, w * 0.10)

	func _draw_drone(center: Vector2, arm: float):
		var bw  = arm * 1.30
		var bh  = arm * 0.80
		var mt  = arm * 0.13
		var bl  = arm * 0.88

		var tips = []
		for ang_deg in [-135.0, -45.0, 45.0, 135.0]:
			tips.append(center + Vector2(cos(deg_to_rad(ang_deg)), sin(deg_to_rad(ang_deg))) * bl)

		for tip in tips:
			draw_line(center, tip, Color(ACC, 0.65), 1.3)

		for i in range(4):
			var tip      = tips[i]
			var base_ang = deg_to_rad([-135.0, -45.0, 45.0, 135.0][i])
			for blade_rot in [0.0, PI * 0.5]:
				_draw_propeller_blade(tip, base_ang + blade_rot, arm * 0.30, arm * 0.065)
			draw_circle(tip, mt + 1.5, Color(0.059, 0.063, 0.078))
			draw_arc(tip, mt + 1.5, 0, TAU, 32, Color(ACC, 0.80), 1.0)
			draw_circle(tip, mt * 0.35, Color(ACC, 0.55))

		var body_rect = Rect2(center - Vector2(bw * 0.5, bh * 0.5), Vector2(bw, bh))
		draw_rect(body_rect, BODY_BG)
		_draw_rect_border(body_rect, SHELL, 1.2)

		var ir = Rect2(center - Vector2(bw * 0.33, bh * 0.28), Vector2(bw * 0.66, bh * 0.56))
		draw_rect(ir, BODY_IN)
		_draw_rect_border(ir, Color(ACC, 0.50), 0.8)

		var stripe = Rect2(ir.position, Vector2(bw * 0.08, ir.size.y))
		draw_rect(stripe, Color(ACC, 0.22))

		var cam_w    = bh * 0.22
		var cam_h    = bh * 0.38
		var cam_pos  = Vector2(center.x + bw * 0.5, center.y - cam_h * 0.5)
		var cam_rect = Rect2(cam_pos, Vector2(cam_w, cam_h))
		draw_rect(cam_rect, Color(0.043, 0.047, 0.063))
		_draw_rect_border(cam_rect, Color(ACC, 0.70), 0.8)
		var lens_center = cam_pos + Vector2(cam_w * 0.5, cam_h * 0.5)
		draw_circle(lens_center, cam_h * 0.28, Color(ACC, 0.45))
		draw_circle(lens_center, cam_h * 0.14, Color(ACC, 0.85))

		draw_circle(center, 3.5, Color(ACC, 0.90))
		draw_circle(center, 2.0, Color(0.925, 0.929, 0.961, 0.95))

	func _draw_propeller_blade(motor_center: Vector2, angle: float, length: float, width: float):
		var points = PackedVector2Array()
		var steps  = 12
		for i in range(steps + 1):
			var t  = float(i) / float(steps)
			var lx = (t * 2.0 - 1.0) * length
			var ly = sin(t * PI) * width
			points.append(Vector2(
				lx * cos(angle) - ly * sin(angle) + motor_center.x,
				lx * sin(angle) + ly * cos(angle) + motor_center.y
			))
		for i in range(steps + 1):
			var t  = 1.0 - float(i) / float(steps)
			var lx = (t * 2.0 - 1.0) * length
			var ly = -sin(t * PI) * width
			points.append(Vector2(
				lx * cos(angle) - ly * sin(angle) + motor_center.x,
				lx * sin(angle) + ly * cos(angle) + motor_center.y
			))
		draw_colored_polygon(points, Color(ACC, 0.45))
		draw_polyline(points, Color(ACC, 0.65), 0.7)

	func _draw_rect_border(r: Rect2, col: Color, width: float):
		var p = r.position; var s = r.size
		draw_line(p,                     p + Vector2(s.x, 0), col, width)
		draw_line(p + Vector2(s.x, 0),   p + s,               col, width)
		draw_line(p + s,                 p + Vector2(0, s.y), col, width)
		draw_line(p + Vector2(0, s.y),   p,                   col, width)

	func _draw_hud_box(pos: Vector2, text: String):
		var bw = 58.0; var bh = 18.0
		var r  = Rect2(pos, Vector2(bw, bh))
		draw_line(r.position,                   r.position + Vector2(bw, 0),  Color(ACC, 0.28), 0.8)
		draw_line(r.position + Vector2(bw, 0),  r.position + Vector2(bw, bh), Color(ACC, 0.28), 0.8)
		draw_line(r.position + Vector2(bw, bh), r.position + Vector2(0, bh),  Color(ACC, 0.28), 0.8)
		draw_line(r.position + Vector2(0, bh),  r.position,                   Color(ACC, 0.28), 0.8)

	func _bezier_points(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps: int) -> Array:
		var result = []
		for i in range(steps + 1):
			var t  = float(i) / float(steps)
			var mt = 1.0 - t
			result.append(mt*mt*mt*p0 + 3*mt*mt*t*p1 + 3*mt*t*t*p2 + t*t*t*p3)
		return result
