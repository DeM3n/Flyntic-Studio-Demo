extends Control
const T = preload("res://DashBoard/UITheme.gd")

# ─────────────────────────────────────────────
#  DATA — replace urls with real Flyntic links
# ─────────────────────────────────────────────
var SPACES := [
	{
		"bay": "01", "title": "Ready Room",
		"desc": "Voice and text chat with builders flying right now",
		"status": "●  38 ONLINE", "status_color": T.C_SUCCESS,
		"btn_text": "JOIN", "primary": true,
		"url": "https://discord.com"
	},
	{
		"bay": "02", "title": "Hangar Bay",
		"desc": "Show off finished builds, pick up tuning tips",
		"status": "214 BUILDS POSTED", "status_color": T.C_TEXT_MUTED,
		"btn_text": "VIEW", "primary": false,
		"url": "https://godotengine.org/community/"
	},
	{
		"bay": "03", "title": "Maintenance Log",
		"desc": "Report a bug or help squash one for the next release",
		"status": "●  7 OPEN ISSUES", "status_color": T.C_WARNING,
		"btn_text": "VIEW", "primary": false,
		"url": "https://github.com"
	},
	{
		"bay": "04", "title": "Parts Locker",
		"desc": "Frames, motors, and presets other builders are sharing",
		"status": "●  52 NEW", "status_color": T.C_PRO,
		"btn_text": "VIEW", "primary": false,
		"url": "https://godotengine.org/asset-library/"
	},
]

const COL_BAY    := 60
const COL_STATUS := 190
const COL_BTN    := 90


func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var pad := MarginContainer.new()
	for m in ["left", "right"]: pad.add_theme_constant_override("margin_" + m, T.PAD_XL)
	for m in ["top", "bottom"]: pad.add_theme_constant_override("margin_" + m, T.PAD_LG)
	vbox.add_child(pad)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	pad.add_child(header_box)

	var eyebrow := Label.new()
	eyebrow.text = "FLYNTIC BUILDERS"
	eyebrow.add_theme_font_size_override("font_size", T.FONT_SIZE_XS)
	eyebrow.add_theme_color_override("font_color", T.C_ACCENT)
	header_box.add_child(eyebrow)

	var title := Label.new()
	title.text = "Pit Lane"
	title.add_theme_font_size_override("font_size", T.FONT_SIZE_2XL)
	title.add_theme_color_override("font_color", T.C_TEXT)
	header_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Where builders hang out. Share rigs, fix problems, swap parts."
	subtitle.add_theme_font_size_override("font_size", T.FONT_SIZE_BASE)
	subtitle.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	header_box.add_child(subtitle)

	var board_pad := MarginContainer.new()
	for m in ["left", "right", "bottom"]: board_pad.add_theme_constant_override("margin_" + m, T.PAD_XL)
	board_pad.add_theme_constant_override("margin_top", T.PAD_LG)
	vbox.add_child(board_pad)

	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", T.flat_border(Color.TRANSPARENT, T.C_BORDER, T.RADIUS_MD))
	board_pad.add_child(board)

	var board_vbox := VBoxContainer.new()
	board_vbox.add_theme_constant_override("separation", 0)
	board.add_child(board_vbox)

	board_vbox.add_child(_build_column_header())
	board_vbox.add_child(T.hsep())

	for i in SPACES.size():
		board_vbox.add_child(_build_row(SPACES[i]))
		if i < SPACES.size() - 1:
			board_vbox.add_child(T.hsep())


func _build_column_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", T.PAD_MD)
	row.add_theme_stylebox_override("panel", T.pad(T.flat(T.C_BG_SIDEBAR), T.PAD_MD, T.PAD_SM))

	var bay := Label.new()
	bay.text = "BAY"
	bay.custom_minimum_size = Vector2(COL_BAY, 0)
	bay.add_theme_font_size_override("font_size", T.FONT_SIZE_XS)
	bay.add_theme_color_override("font_color", T.C_TEXT_DIM)
	row.add_child(bay)

	var space_lbl := Label.new()
	space_lbl.text = "SPACE"
	space_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_XS)
	space_lbl.add_theme_color_override("font_color", T.C_TEXT_DIM)
	row.add_child(space_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "STATUS"
	status_lbl.custom_minimum_size = Vector2(COL_STATUS, 0)
	status_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_XS)
	status_lbl.add_theme_color_override("font_color", T.C_TEXT_DIM)
	row.add_child(status_lbl)

	var go_lbl := Label.new()
	go_lbl.text = "GO"
	go_lbl.custom_minimum_size = Vector2(COL_BTN, 0)
	go_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	go_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_XS)
	go_lbl.add_theme_color_override("font_color", T.C_TEXT_DIM)
	row.add_child(go_lbl)

	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", T.pad(T.flat(T.C_BG_SIDEBAR), T.PAD_MD, T.PAD_SM))
	wrap.add_child(row)
	return wrap


func _build_row(data: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", T.pad(T.flat(T.C_BG_MAIN), T.PAD_MD, T.PAD_MD))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", T.PAD_MD)
	wrap.add_child(row)

	var bay := Label.new()
	bay.text = data.bay
	bay.custom_minimum_size = Vector2(COL_BAY, 0)
	bay.add_theme_font_size_override("font_size", T.FONT_SIZE_LG)
	bay.add_theme_color_override("font_color", T.C_ACCENT)
	row.add_child(bay)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var title := Label.new()
	title.text = data.title
	title.add_theme_font_size_override("font_size", T.FONT_SIZE_MD)
	title.add_theme_color_override("font_color", T.C_TEXT)
	info.add_child(title)

	var desc := Label.new()
	desc.text = data.desc
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", T.FONT_SIZE_SM)
	desc.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	info.add_child(desc)

	var status := Label.new()
	status.text = data.status
	status.custom_minimum_size = Vector2(COL_STATUS, 0)
	status.add_theme_font_size_override("font_size", T.FONT_SIZE_SM)
	status.add_theme_color_override("font_color", data.status_color)
	row.add_child(status)

	var btn_wrap := VBoxContainer.new()
	btn_wrap.custom_minimum_size = Vector2(COL_BTN, 0)
	btn_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	var btn := T.make_btn(data.btn_text, data.primary)
	btn.custom_minimum_size = Vector2(COL_BTN, 32)
	btn.pressed.connect(func(): OS.shell_open(data.url))
	btn_wrap.add_child(btn)
	row.add_child(btn_wrap)

	return wrap
