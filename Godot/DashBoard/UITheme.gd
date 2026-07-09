class_name UITheme
extends RefCounted

# ─────────────────────────────────────────────
#  COLOR PALETTE
# ─────────────────────────────────────────────
const C_BG_DARK    := Color(0.13, 0.13, 0.13)
const C_BG_SIDEBAR := Color(0.17, 0.17, 0.17)
const C_BG_MAIN    := Color(0.15, 0.15, 0.15)
const C_BG_HOVER   := Color(0.22, 0.22, 0.24)
const C_BG_ACTIVE  := Color(0.24, 0.24, 0.28)
const C_BG_PRESSED := Color(0.20, 0.20, 0.23)

const C_ACCENT     := Color(0.25, 0.50, 0.90)   # HUD blue
const C_SUCCESS    := Color(0.18, 0.72, 0.45)   # status green
const C_WARNING    := Color(0.88, 0.62, 0.12)   # amber
const C_DANGER     := Color(0.85, 0.28, 0.28)   # red
const C_PRO        := Color(0.52, 0.38, 0.88)   # purple / beta

const C_TEXT       := Color(0.90, 0.90, 0.90)
const C_TEXT_MUTED := Color(0.55, 0.55, 0.55)
const C_TEXT_DIM   := Color(0.38, 0.38, 0.40)   # placeholder / disabled

const C_BORDER        := Color(0.25, 0.25, 0.25)
const C_BORDER_STRONG := Color(0.32, 0.32, 0.34)

# Tint fills (bg behind colored text)
const C_TINT_ACCENT  := Color(0.25, 0.50, 0.90, 0.12)
const C_TINT_SUCCESS := Color(0.18, 0.72, 0.45, 0.12)
const C_TINT_WARNING := Color(0.88, 0.62, 0.12, 0.12)
const C_TINT_DANGER  := Color(0.85, 0.28, 0.28, 0.12)
const C_TINT_PRO     := Color(0.52, 0.38, 0.88, 0.12)

# ─────────────────────────────────────────────
#  TYPOGRAPHY
# ─────────────────────────────────────────────
const FONT_SIZE_XS   := 12
const FONT_SIZE_SM   := 13
const FONT_SIZE_BASE := 15
const FONT_SIZE_MD   := 16
const FONT_SIZE_LG   := 18
const FONT_SIZE_XL   := 24
const FONT_SIZE_2XL  := 28

# ─────────────────────────────────────────────
#  SPACING
# ─────────────────────────────────────────────
const PAD_XS := 4
const PAD_SM := 8
const PAD_MD := 14
const PAD_LG := 20
const PAD_XL := 28

const RADIUS_SM := 4
const RADIUS_MD := 6
const RADIUS_LG := 8

# ─────────────────────────────────────────────
#  STYLEBOX HELPERS
# ─────────────────────────────────────────────
static func flat(color: Color, radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left    = radius
	s.corner_radius_top_right   = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s

static func flat_border(color: Color, border: Color, radius: int = 6, bw: int = 1) -> StyleBoxFlat:
	var s := flat(color, radius)
	s.border_color        = border
	s.border_width_top    = bw
	s.border_width_bottom = bw
	s.border_width_left   = bw
	s.border_width_right  = bw
	return s

static func pad(s: StyleBoxFlat, h: int, v: int) -> StyleBoxFlat:
	s.content_margin_left   = h
	s.content_margin_right  = h
	s.content_margin_top    = v
	s.content_margin_bottom = v
	return s

# ─────────────────────────────────────────────
#  SEPARATORS
# ─────────────────────────────────────────────
static func hsep() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", C_BORDER)
	sep.add_theme_constant_override("separation", 1)
	return sep

## Horizontal separator with a centered label — useful for section dividers
static func hsep_label(text: String) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", PAD_SM)
	hbox.add_child(hsep())
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", FONT_SIZE_XS)
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hbox.add_child(lbl)
	var sep2 := hsep()
	sep2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sep2)
	# make the first sep also expand
	(hbox.get_child(0) as HSeparator).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return hbox

# ─────────────────────────────────────────────
#  BUTTONS
# ─────────────────────────────────────────────
static func make_btn(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", FONT_SIZE_BASE)
	if primary:
		btn.add_theme_stylebox_override("normal",   pad(flat(C_ACCENT,              RADIUS_MD), PAD_MD, 6))
		btn.add_theme_stylebox_override("hover",    pad(flat(C_ACCENT.lightened(0.08), RADIUS_MD), PAD_MD, 6))
		btn.add_theme_stylebox_override("pressed",  pad(flat(C_ACCENT.darkened(0.1),  RADIUS_MD), PAD_MD, 6))
		btn.add_theme_stylebox_override("focus",    pad(flat(C_ACCENT,              RADIUS_MD), PAD_MD, 6))
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		btn.add_theme_stylebox_override("normal",   pad(flat_border(Color.TRANSPARENT, C_BORDER,       RADIUS_MD), PAD_MD, 6))
		btn.add_theme_stylebox_override("hover",    pad(flat_border(C_BG_HOVER,        C_BORDER_STRONG, RADIUS_MD), PAD_MD, 6))
		btn.add_theme_stylebox_override("pressed",  pad(flat(C_BG_ACTIVE,             RADIUS_MD), PAD_MD, 6))
		btn.add_theme_stylebox_override("focus",    pad(flat_border(Color.TRANSPARENT, C_BORDER,       RADIUS_MD), PAD_MD, 6))
		btn.add_theme_color_override("font_color", C_TEXT)
	return btn

## Small square icon button (28×28). color_role: "default" | "danger" | "accent"
static func make_icon_btn(icon_text: String, color_role: String = "default") -> Button:
	var btn := Button.new()
	btn.text = icon_text
	btn.custom_minimum_size = Vector2(28, 28)
	btn.add_theme_font_size_override("font_size", 14)
	var normal_style := flat_border(Color.TRANSPARENT, C_BORDER, RADIUS_SM)
	btn.add_theme_stylebox_override("normal",  pad(normal_style, 0, 0))
	match color_role:
		"danger":
			btn.add_theme_stylebox_override("hover",   pad(flat_border(C_TINT_DANGER,  C_DANGER,         RADIUS_SM), 0, 0))
			btn.add_theme_stylebox_override("pressed", pad(flat(C_TINT_DANGER,         RADIUS_SM), 0, 0))
			btn.add_theme_color_override("font_color_hover",    C_DANGER)
			btn.add_theme_color_override("font_color_pressed",  C_DANGER)
		"accent":
			btn.add_theme_stylebox_override("hover",   pad(flat_border(C_TINT_ACCENT,  C_ACCENT,          RADIUS_SM), 0, 0))
			btn.add_theme_stylebox_override("pressed", pad(flat(C_TINT_ACCENT,          RADIUS_SM), 0, 0))
			btn.add_theme_color_override("font_color_hover",    C_ACCENT)
			btn.add_theme_color_override("font_color_pressed",  C_ACCENT)
		_:
			btn.add_theme_stylebox_override("hover",   pad(flat_border(C_BG_HOVER, C_BORDER_STRONG, RADIUS_SM), 0, 0))
			btn.add_theme_stylebox_override("pressed", pad(flat(C_BG_ACTIVE,       RADIUS_SM), 0, 0))
			btn.add_theme_color_override("font_color_hover",    C_TEXT)
			btn.add_theme_color_override("font_color_pressed",  C_TEXT)
	btn.add_theme_color_override("font_color", C_TEXT_MUTED)
	btn.add_theme_stylebox_override("focus", pad(flat_border(Color.TRANSPARENT, C_BORDER, RADIUS_SM), 0, 0))
	return btn

# ─────────────────────────────────────────────
#  BADGES / PILLS
# ─────────────────────────────────────────────
## Channel / status badge. role: "stable" | "beta" | "dev" | "active" | "danger"
static func make_badge(text: String, role: String = "stable") -> Label:
	var lbl := Label.new()
	lbl.text = "  " + text + "  "   # padding via spaces (stylebox margin doesn't clip text)
	lbl.add_theme_font_size_override("font_size", FONT_SIZE_XS)
	match role:
		"stable":
			lbl.add_theme_stylebox_override("normal", flat_border(C_TINT_SUCCESS, C_SUCCESS.darkened(0.3), RADIUS_LG))
			lbl.add_theme_color_override("font_color", C_SUCCESS)
		"beta":
			lbl.add_theme_stylebox_override("normal", flat_border(C_TINT_WARNING, C_WARNING.darkened(0.2), RADIUS_LG))
			lbl.add_theme_color_override("font_color", C_WARNING)
		"dev":
			lbl.add_theme_stylebox_override("normal", flat_border(C_TINT_PRO, C_PRO.darkened(0.2), RADIUS_LG))
			lbl.add_theme_color_override("font_color", C_PRO)
		"active":
			lbl.add_theme_stylebox_override("normal", flat_border(C_TINT_ACCENT, C_ACCENT.darkened(0.2), RADIUS_LG))
			lbl.add_theme_color_override("font_color", C_ACCENT)
		"danger":
			lbl.add_theme_stylebox_override("normal", flat_border(C_TINT_DANGER, C_DANGER.darkened(0.2), RADIUS_LG))
			lbl.add_theme_color_override("font_color", C_DANGER)
	return lbl

# ─────────────────────────────────────────────
#  STAT TILE  (mini metric card)
# ─────────────────────────────────────────────
## Returns a VBoxContainer with a muted eyebrow label and a larger value label.
## Useful for stats bars / dashboards.
static func make_stat(label_text: String, value_text: String, value_role: String = "default") -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var lbl := Label.new()
	lbl.text = label_text.to_upper()
	lbl.add_theme_font_size_override("font_size", FONT_SIZE_XS)
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	box.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", FONT_SIZE_MD)
	match value_role:
		"accent":  val.add_theme_color_override("font_color", C_ACCENT)
		"success": val.add_theme_color_override("font_color", C_SUCCESS)
		"warning": val.add_theme_color_override("font_color", C_WARNING)
		"danger":  val.add_theme_color_override("font_color", C_DANGER)
		_:         val.add_theme_color_override("font_color", C_TEXT)
	box.add_child(val)
	return box

# ─────────────────────────────────────────────
#  SECTION HEADER  (eyebrow + title row)
# ─────────────────────────────────────────────
## Padded header block: small eyebrow + large title + optional right-side node.
## right_node can be null, a Button, HBoxContainer of buttons, etc.
static func make_section_header(
		eyebrow: String,
		title: String,
		right_node: Control = null,
		title_size: int = FONT_SIZE_XL
) -> Control:
	var pad_c := MarginContainer.new()
	for side in ["left", "right"]:
		pad_c.add_theme_constant_override("margin_" + side, PAD_XL)
	for side in ["top", "bottom"]:
		pad_c.add_theme_constant_override("margin_" + side, PAD_LG)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	pad_c.add_child(vbox)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	hbox.add_child(left)

	if eyebrow != "":
		var eye := Label.new()
		eye.text = eyebrow.to_upper()
		eye.add_theme_font_size_override("font_size", FONT_SIZE_XS)
		eye.add_theme_color_override("font_color", C_ACCENT)
		left.add_child(eye)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", title_size)
	t.add_theme_color_override("font_color", C_TEXT)
	left.add_child(t)

	if right_node:
		var align_wrap := VBoxContainer.new()
		align_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
		align_wrap.add_child(right_node)
		hbox.add_child(align_wrap)

	return pad_c

# ─────────────────────────────────────────────
#  GRID OVERLAY PANEL  (HUD scanline header bg)
# ─────────────────────────────────────────────
## Returns a Panel styled with a subtle dot-grid — use as background for hero headers.
static func make_grid_panel(_h: int = 28, _v: int = 28) -> Panel:
	var panel := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_BG_DARK
	# draw a very faint grid using the border trick on a very small inset
	# (Godot doesn't support CSS background-image, so we fake it with a custom draw)
	# For a proper grid you'd use a shader or _draw(); this gives a solid dark bg.
	panel.add_theme_stylebox_override("panel", s)
	return panel

# ─────────────────────────────────────────────
#  LINE EDIT  (styled text input)
# ─────────────────────────────────────────────
static func make_line_edit(placeholder: String = "") -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.custom_minimum_size = Vector2(0, 32)
	le.add_theme_font_size_override("font_size", FONT_SIZE_BASE)
	le.add_theme_color_override("font_color",          C_TEXT)
	le.add_theme_color_override("font_placeholder_color", C_TEXT_DIM)
	le.add_theme_stylebox_override("normal",   pad(flat_border(C_BG_MAIN,   C_BORDER,        RADIUS_MD), PAD_MD, 6))
	le.add_theme_stylebox_override("focus",    pad(flat_border(C_BG_MAIN,   C_ACCENT,        RADIUS_MD), PAD_MD, 6))
	le.add_theme_stylebox_override("read_only",pad(flat_border(C_BG_SIDEBAR, C_BORDER,       RADIUS_MD), PAD_MD, 6))
	return le
