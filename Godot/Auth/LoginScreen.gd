extends Control

# ── Node refs (tạo bằng code) ──────────────────────────────────────
var email_input:    LineEdit
var password_input: LineEdit
var login_btn:      Button
var error_label:    Label
var loading_label:  Label

func _ready():
	_build_ui()
	AuthManager.access_granted.connect(_on_granted, CONNECT_ONE_SHOT)
	AuthManager.access_denied.connect(_on_denied, CONNECT_ONE_SHOT)
	AuthManager.login_failed.connect(_on_login_failed, CONNECT_ONE_SHOT)

	if AuthManager.has_session():
		_set_loading(true)
		AuthManager.check_license()

# ── Build UI ───────────────────────────────────────────────────────
func _build_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Background tối
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

# Panel trung tâm
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 420)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color          = Color(0.13, 0.13, 0.16)
	style.corner_radius_top_left     = 16
	style.corner_radius_top_right    = 16
	style.corner_radius_bottom_left  = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.25, 0.30)
	panel.add_theme_stylebox_override("panel", style)
#add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    36)
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.add_child(vbox)
	panel.add_child(margin)

	# Logo / Title
	var title = Label.new()
	title.text = "FLYNTIC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Sign in to your account"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
	vbox.add_child(subtitle)

	# Spacer
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sp1)

	# Email label + input
	var email_lbl = Label.new()
	email_lbl.text = "Email"
	email_lbl.add_theme_font_size_override("font_size", 12)
	email_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.80))
	vbox.add_child(email_lbl)

	email_input = LineEdit.new()
	email_input.placeholder_text = "you@example.com"
	email_input.custom_minimum_size = Vector2(0, 44)
	_style_input(email_input)
	vbox.add_child(email_input)

	# Password label + input
	var pass_lbl = Label.new()
	pass_lbl.text = "Password"
	pass_lbl.add_theme_font_size_override("font_size", 12)
	pass_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.80))
	vbox.add_child(pass_lbl)

	password_input = LineEdit.new()
	password_input.placeholder_text = "••••••••"
	password_input.secret = true
	password_input.custom_minimum_size = Vector2(0, 44)
	_style_input(password_input)
	password_input.text_submitted.connect(func(_t): _on_login_pressed())
	vbox.add_child(password_input)

	# Error label
	error_label = Label.new()
	error_label.text = ""
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_font_size_override("font_size", 12)
	error_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(error_label)

	# Login button
	login_btn = Button.new()
	login_btn.text = "Sign In"
	login_btn.custom_minimum_size = Vector2(0, 48)
	_style_button(login_btn)
	login_btn.pressed.connect(_on_login_pressed)
	vbox.add_child(login_btn)

	# Loading label
	loading_label = Label.new()
	loading_label.text = "Signing in..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 13)
	loading_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
	loading_label.visible = false
	vbox.add_child(loading_label)

func _style_input(input: LineEdit):
	var s = StyleBoxFlat.new()
	s.bg_color    = Color(0.18, 0.18, 0.22)
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.border_color        = Color(0.30, 0.30, 0.35)
	s.content_margin_left  = 12
	s.content_margin_right = 12
	input.add_theme_stylebox_override("normal", s)
	input.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	input.add_theme_color_override("font_placeholder_color", Color(0.4, 0.4, 0.45))
	input.add_theme_font_size_override("font_size", 14)

func _style_button(btn: Button):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.25, 0.55, 1.0)
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", s)

	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(0.30, 0.62, 1.0)
	sh.corner_radius_top_left     = 10
	sh.corner_radius_top_right    = 10
	sh.corner_radius_bottom_left  = 10
	sh.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("hover", sh)

	var sp = StyleBoxFlat.new()
	sp.bg_color = Color(0.20, 0.48, 0.90)
	sp.corner_radius_top_left     = 10
	sp.corner_radius_top_right    = 10
	sp.corner_radius_bottom_left  = 10
	sp.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("pressed", sp)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 15)

# ── Logic ──────────────────────────────────────────────────────────
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
	#reconnect
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
	login_btn.visible     = not on
	loading_label.visible = on
	email_input.editable  = not on
	password_input.editable = not on
	error_label.text      = ""
