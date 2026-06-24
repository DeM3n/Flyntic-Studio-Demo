class_name UITheme
extends RefCounted

const C_BG_DARK    := Color(0.13, 0.13, 0.13)
const C_BG_SIDEBAR := Color(0.17, 0.17, 0.17)
const C_BG_MAIN    := Color(0.15, 0.15, 0.15)
const C_BG_HOVER   := Color(0.22, 0.22, 0.24)
const C_BG_ACTIVE  := Color(0.24, 0.24, 0.28)
const C_BG_PRESSED := Color(0.20, 0.20, 0.23)
const C_ACCENT     := Color(0.25, 0.50, 0.90)
const C_TEXT       := Color(0.90, 0.90, 0.90)
const C_TEXT_MUTED := Color(0.55, 0.55, 0.55)
const C_BORDER     := Color(0.25, 0.25, 0.25)

static func flat(color: Color, radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s

static func flat_border(color: Color, border: Color, radius: int = 6, bw: int = 1) -> StyleBoxFlat:
	var s := flat(color, radius)
	s.border_color = border
	s.border_width_top = bw
	s.border_width_bottom = bw
	s.border_width_left = bw
	s.border_width_right = bw
	return s

static func pad(s: StyleBoxFlat, h: int, v: int) -> StyleBoxFlat:
	s.content_margin_left = h
	s.content_margin_right = h
	s.content_margin_top = v
	s.content_margin_bottom = v
	return s

static func hsep() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", C_BORDER)
	sep.add_theme_constant_override("separation", 1)
	return sep

static func make_btn(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", 13)
	if primary:
		btn.add_theme_stylebox_override("normal",  pad(flat(C_ACCENT, 6), 14, 6))
		btn.add_theme_stylebox_override("hover",   pad(flat(C_ACCENT.lightened(0.1), 6), 14, 6))
		btn.add_theme_stylebox_override("pressed", pad(flat(C_ACCENT.darkened(0.1), 6), 14, 6))
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		btn.add_theme_stylebox_override("normal",  pad(flat_border(Color.TRANSPARENT, C_BORDER, 6), 14, 6))
		btn.add_theme_stylebox_override("hover",   pad(flat(C_BG_HOVER, 6), 14, 6))
		btn.add_theme_stylebox_override("pressed", pad(flat(C_BG_ACTIVE, 6), 14, 6))
		btn.add_theme_color_override("font_color", C_TEXT)
	return btn
