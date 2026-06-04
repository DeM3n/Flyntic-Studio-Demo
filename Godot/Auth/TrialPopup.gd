extends Control

const PRICING_URL = "https://flyntic.site/en/subscription"

var _claim_btn: Button
var _already_claimed := false

func _ready():
	_build_ui()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AuthManager.access_granted.connect(func(type, tier, days):
		queue_free()
		get_tree().change_scene_to_file("res://Main.tscn")
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

	# Panel trung tâm
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH

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
	add_child(panel)

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
	_claim_btn.text = "🚀  Start 14-Day Free Trial"
	_claim_btn.custom_minimum_size = Vector2(0, 50)
	_style_primary_btn(_claim_btn)
	_claim_btn.pressed.connect(_on_claim_pressed)
	vbox.add_child(_claim_btn)

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
	var icon = Label.new()
	icon.text = "⏳"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 40)
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
