extends Control

const PRICING_URL = "https://flyntic.site/en/subscription"

var _claim_btn: Button
var _already_claimed := false

func _ready():
	_build_ui()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AuthManager.access_granted.connect(
		func(_tier, _tier_name, _days_left):
			AuthManager.get_tree().change_scene_to_file("res://DashBoard/Dashboard.tscn"),
		CONNECT_ONE_SHOT
	)

func show_offer(already_claimed: bool):
	_already_claimed = already_claimed
	_build_ui()
	show()

# ── Build UI ───────────────────────────────────────────────────────
func _build_ui():
	# Xóa children cũ nếu rebuild
	for c in get_children():
		c.queue_free()

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Overlay mờ
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	## Panel trung tâm
	#var panel = PanelContainer.new()
	#panel.custom_minimum_size = Vector2(420, 300)
	#panel.set_anchors_preset(Control.PRESET_CENTER)
	#panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	#panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
#
	#var style = StyleBoxFlat.new()
	#style.bg_color                   = Color(0.13, 0.13, 0.16)
	#style.corner_radius_top_left     = 18
	#style.corner_radius_top_right    = 18
	#style.corner_radius_bottom_left  = 18
	#style.corner_radius_bottom_right = 18
	#style.border_width_left          = 1
	#style.border_width_right         = 1
	#style.border_width_top           = 1
	#style.border_width_bottom        = 1
	#style.border_color               = Color(0.28, 0.28, 0.35)
	#panel.add_theme_stylebox_override("panel", style)
	#add_child(panel)
	# Wrapper để đặt nút X chồng lên góc panel
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(420, 300)
	wrapper.set_anchors_preset(Control.PRESET_CENTER)
	wrapper.grow_horizontal = Control.GROW_DIRECTION_BOTH
	wrapper.grow_vertical   = Control.GROW_DIRECTION_BOTH
	add_child(wrapper)

	# Panel trung tâm
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var style = StyleBoxFlat.new()
	style.bg_color                   = Color(0.13, 0.13, 0.16)
	style.corner_radius_top_left     = 18
	style.corner_radius_top_right    = 18
	style.corner_radius_bottom_left  = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left          = 1
	style.border_width_right         = 1
	style.border_width_top           = 1
	style.border_width_bottom        = 1
	style.border_color               = Color(0.28, 0.28, 0.35)
	panel.add_theme_stylebox_override("panel", style)
	wrapper.add_child(panel)

	# Nút X đóng popup
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.anchor_left   = 1.0
	close_btn.anchor_right  = 1.0
	close_btn.anchor_top    = 0.0
	close_btn.anchor_bottom = 0.0
	close_btn.offset_left   = -42
	close_btn.offset_right  = -14
	close_btn.offset_top    = 14
	close_btn.offset_bottom = 42
	close_btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
	close_btn.add_theme_color_override("font_color_hover", Color(1, 1, 1))
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(func(): hide())
	wrapper.add_child(close_btn)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   36)
	margin.add_theme_constant_override("margin_right",  36)
	margin.add_theme_constant_override("margin_top",    32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	if not _already_claimed:
		_build_offer_ui(vbox)
	else:
		_build_expired_ui(vbox)

func _build_offer_ui(vbox: VBoxContainer):
	# Badge
	var badge = Label.new()
	badge.text = "✦  LIMITED OFFER"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	vbox.add_child(badge)

	# Title
	var title = Label.new()
	title.text = "Try Flyntic Pro Free"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)

	# Desc
	var desc = Label.new()
	desc.text = "Get full access to all Pro features\nfor 14 days — no credit card required.\nOne-time offer per account."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Spacer
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(sp)

	# Claim button
	_claim_btn = Button.new()
	_claim_btn.text = ""
	_claim_btn.custom_minimum_size = Vector2(0, 50)
	_style_primary_btn(_claim_btn)
	_claim_btn.pressed.connect(_on_claim_pressed)
	vbox.add_child(_claim_btn)

	# Nội dung icon + text tự dựng, đè lên button (chỉ để hiển thị)
	var btn_content = HBoxContainer.new()
	btn_content.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_content.add_theme_constant_override("separation", 8)
	btn_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim_btn.add_child(btn_content)

	var icon_rect = TextureRect.new()
	icon_rect.texture = preload("res://Assets/rocket.svg")
	icon_rect.custom_minimum_size = Vector2(20, 20)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	btn_content.add_child(icon_rect)

	var label = Label.new()
	label.text = "Start 14-Day Free Trial"
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_content.add_child(label)

	# Pricing link
	var link = Button.new()
	link.text = "View pricing plans →"
	link.flat = true
	link.add_theme_color_override("font_color", Color(0.45, 0.65, 1.0))
	link.add_theme_font_size_override("font_size", 12)
	link.pressed.connect(func(): OS.shell_open(PRICING_URL))
	vbox.add_child(link)

func _build_expired_ui(vbox: VBoxContainer):
	# Icon
	var icon = TextureRect.new()
	icon.texture = load("res://Assets/hourglass.svg")
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # để icon tự căn giữa trong vbox
	vbox.add_child(icon)

	# Title
	var title = Label.new()
	title.text = "Trial Ended"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)

	# Desc
	var desc = Label.new()
	desc.text = "Your free trial has been used.\nUpgrade to Pro to continue using Flyntic."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Spacer
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(sp)

	# Upgrade button
	var upgrade_btn = Button.new()
	upgrade_btn.text = "⚡  Upgrade to Pro"
	upgrade_btn.custom_minimum_size = Vector2(0, 50)
	_style_primary_btn(upgrade_btn)
	upgrade_btn.pressed.connect(func(): OS.shell_open(PRICING_URL))
	vbox.add_child(upgrade_btn)

	# Pricing link
	var link = Button.new()
	link.text = "View all pricing plans →"
	link.flat = true
	link.add_theme_color_override("font_color", Color(0.45, 0.65, 1.0))
	link.add_theme_font_size_override("font_size", 12)
	link.pressed.connect(func(): OS.shell_open(PRICING_URL))
	vbox.add_child(link)

# ── Claim ──────────────────────────────────────────────────────────
func _on_claim_pressed():
	_claim_btn.disabled = true
	_claim_btn.text     = "Activating..."
	AuthManager.claim_trial()

# ── Style helpers ──────────────────────────────────────────────────
func _style_primary_btn(btn: Button):
	var s = StyleBoxFlat.new()
	s.bg_color                   = Color(0.25, 0.55, 1.0)
	s.corner_radius_top_left     = 10
	s.corner_radius_top_right    = 10
	s.corner_radius_bottom_left  = 10
	s.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", s)

	var sh = s.duplicate()
	sh.bg_color = Color(0.30, 0.62, 1.0)
	btn.add_theme_stylebox_override("hover", sh)

	var sp = s.duplicate()
	sp.bg_color = Color(0.20, 0.48, 0.90)
	btn.add_theme_stylebox_override("pressed", sp)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 15)
