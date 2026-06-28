extends Control

const T = preload("res://DashBoard/UITheme.gd")

# Thay link bằng docs riêng của Flyntic khi có
var _resources := [
	{
		"tag":   "REF",
		"tag_role": "accent",
		"title": "Documentation",
		"desc":  "API reference, scene system, physics engine, và toàn bộ module của Flyntic.",
		"meta":  "flyntic.dev/docs · tiếng Việt + English",
		"url":   "https://docs.godotengine.org",
		"label": "Mở tài liệu",
		"featured": true,
	},
	{
		"tag":   "GDN",
		"tag_role": "success",
		"title": "Step-by-step",
		"desc":  "Từ cài đặt đến bay thử đầu tiên — hướng dẫn có thứ tự cho người mới.",
		"meta":  "",
		"url":   "https://docs.godotengine.org/en/stable/getting_started/step_by_step/index.html",
		"label": "Bắt đầu",
		"featured": false,
	},
	{
		"tag":   "COMM",
		"tag_role": "warning",
		"title": "Community tutorials",
		"desc":  "Video và bài viết từ cộng đồng — tips thực tế, case study, build log.",
		"meta":  "",
		"url":   "https://docs.godotengine.org/en/stable/community/tutorials.html",
		"label": "Khám phá",
		"featured": false,
	},
]

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	root.add_child(_build_header())
	root.add_child(T.hsep())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)

	var body_pad := MarginContainer.new()
	body_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		body_pad.add_theme_constant_override("margin_" + side, T.PAD_LG)
	body_pad.add_child(body)
	scroll.add_child(body_pad)

	# ── featured card (full width) ────────────────────────────────────────────
	for r in _resources:
		if r.get("featured", false):
			body.add_child(_build_card(r, true))

	# ── secondary cards (2 cột) ───────────────────────────────────────────────
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)

	for r in _resources:
		if not r.get("featured", false):
			grid.add_child(_build_card(r, false))

# ─────────────────────────────────────────────────────────────────────────────
#  HEADER
# ─────────────────────────────────────────────────────────────────────────────
func _build_header() -> Control:
	return T.make_section_header("Resources", "Learn", null, T.FONT_SIZE_2XL)

# ─────────────────────────────────────────────────────────────────────────────
#  CARD
# ─────────────────────────────────────────────────────────────────────────────
func _build_card(r: Dictionary, featured: bool) -> Control:
	# Outer wrapper: [strip | content]
	var outer := HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 0)
	outer.add_theme_stylebox_override("panel",
		T.flat_border(T.C_BG_SIDEBAR, T.C_BORDER, T.RADIUS_LG))

	# ── accent strip ──────────────────────────────────────────────────────────
	var strip_color := _role_color(r.get("tag_role", "accent"))
	var strip := ColorRect.new()
	strip.custom_minimum_size = Vector2(3, 0)
	strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip.color = strip_color

	# wrap outer in PanelContainer for the border
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",
		T.flat_border(T.C_BG_SIDEBAR, T.C_BORDER, T.RADIUS_LG))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)
	row.add_child(strip)

	# ── inner padding ─────────────────────────────────────────────────────────
	var pad_c := MarginContainer.new()
	pad_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		pad_c.add_theme_constant_override("margin_" + side, T.PAD_MD)
	for side in ["top", "bottom"]:
		pad_c.add_theme_constant_override("margin_" + side, T.PAD_MD)
	row.add_child(pad_c)

	if featured:
		# horizontal layout: [info | button]
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", T.PAD_LG)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		pad_c.add_child(hbox)

		hbox.add_child(_build_card_info(r, true))

		var btn := T.make_btn(r.get("label", "Open"), false)
		btn.pressed.connect(func(): OS.shell_open(r.url))
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(btn)
	else:
		# vertical layout: [info on top, button bottom]
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", T.PAD_MD)
		pad_c.add_child(vbox)

		vbox.add_child(_build_card_info(r, false))

		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(spacer)

		var btn := T.make_btn(r.get("label", "Open"), false)
		btn.pressed.connect(func(): OS.shell_open(r.url))
		vbox.add_child(btn)

	return panel

# ─────────────────────────────────────────────────────────────────────────────
func _build_card_info(r: Dictionary, with_meta: bool) -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	# tag badge
	vbox.add_child(T.make_badge(r.get("tag", ""), r.get("tag_role", "accent")))

	# title
	var title := Label.new()
	title.text = r.get("title", "")
	title.add_theme_font_size_override("font_size", T.FONT_SIZE_MD)
	title.add_theme_color_override("font_color", T.C_TEXT)
	vbox.add_child(title)

	# desc
	var desc := Label.new()
	desc.text = r.get("desc", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", T.FONT_SIZE_BASE)
	desc.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	vbox.add_child(desc)

	# meta (chỉ featured card)
	if with_meta and r.get("meta", "") != "":
		var meta := Label.new()
		meta.text = r.get("meta", "")
		meta.add_theme_font_size_override("font_size", T.FONT_SIZE_XS)
		meta.add_theme_color_override("font_color", T.C_TEXT_DIM)
		vbox.add_child(meta)

	return vbox

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _role_color(role: String) -> Color:
	match role:
		"accent":  return T.C_ACCENT
		"success": return T.C_SUCCESS
		"warning": return T.C_WARNING
		"danger":  return T.C_DANGER
		"pro":     return T.C_PRO
		_:         return T.C_BORDER
