extends Control

const T = preload("res://DashBoard/UITheme.gd")

# ── mock data (thay bằng dữ liệu thật khi tích hợp) ──────────────────────────
var _installs: Array[Dictionary] = [
	{
		"version": "Flyntic 1.2.0",
		"channel": "stable",
		"path": "C:/FlynticEngine/1.2.0",
		"size_mb": 1884,
		"date": "Jun 2026",
		"active": true,
		# đặt đường dẫn SVG ở đây khi có: "icon": "res://Assets/Icons/engine_stable.svg"
		"icon": "res://Assets/rocket.svg",
	},
	{
		"version": "Flyntic 1.1.3",
		"channel": "stable",
		"path": "C:/FlynticEngine/1.1.3",
		"size_mb": 1792,
		"date": "Mar 2026",
		"active": false,
		"icon": "res://Assets/rocket.svg",
	},
	{
		"version": "Flyntic 1.3.0-beta",
		"channel": "beta",
		"path": "C:/FlynticEngine/1.3.0-beta",
		"size_mb": 524,
		"date": "Jun 2026",
		"active": false,
		"icon": "res://Assets/Icons/Experiment.svg",
	},
]

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	root.add_child(_build_header())
	root.add_child(T.hsep())
	root.add_child(_build_stats_bar())
	root.add_child(T.hsep())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)

	if _installs.is_empty():
		list.add_child(_build_empty_state())
	else:
		for item in _installs:
			list.add_child(_build_row(item))
			list.add_child(T.hsep())

# ─────────────────────────────────────────────────────────────────────────────
#  HEADER
# ─────────────────────────────────────────────────────────────────────────────
func _build_header() -> Control:
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", T.PAD_SM)
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var locate_btn := T.make_btn("Locate existing", false)
	action_row.add_child(locate_btn)

	var install_btn := T.make_btn("+ Install version", true)
	action_row.add_child(install_btn)

	return T.make_section_header("Engine Manager", "Installs", action_row, T.FONT_SIZE_2XL)

# ─────────────────────────────────────────────────────────────────────────────
#  STATS BAR
# ─────────────────────────────────────────────────────────────────────────────
func _build_stats_bar() -> Control:
	var total_mb := 0
	for item in _installs:
		total_mb += item.get("size_mb", 0)
	var active_count := _installs.filter(func(i): return i.get("active", false)).size()

	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 0)

	var stats := [
		["Installed",     str(_installs.size()),       "accent"],
		["Active",        str(active_count),            "success"],
		["Latest stable", "1.2.0",                     "default"],
		["Disk used",     _fmt_mb(total_mb),            "default"],
	]

	for i in stats.size():
		var stat_data: Array = stats[i]
		var cell := MarginContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for side in ["left", "right"]:
			cell.add_theme_constant_override("margin_" + side, T.PAD_LG)
		for side in ["top", "bottom"]:
			cell.add_theme_constant_override("margin_" + side, T.PAD_SM + 2)

		cell.add_child(T.make_stat(stat_data[0], stat_data[1], stat_data[2]))
		container.add_child(cell)

		if i < stats.size() - 1:
			var vsep := VSeparator.new()
			vsep.add_theme_color_override("color", T.C_BORDER)
			vsep.add_theme_constant_override("separation", 1)
			container.add_child(vsep)

	return container

# ─────────────────────────────────────────────────────────────────────────────
#  LIST ROW
# ─────────────────────────────────────────────────────────────────────────────
func _build_row(item: Dictionary) -> Control:
	# Wrapper: [color strip | padded content]
	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)

	# ── left color strip ─────────────────────────────────────────────────────
	var strip_color: Color
	match item.get("channel", "stable"):
		"stable": strip_color = T.C_SUCCESS
		"beta":   strip_color = T.C_WARNING
		"dev":    strip_color = T.C_PRO
		_:        strip_color = T.C_BORDER
	var strip := ColorRect.new()
	strip.custom_minimum_size = Vector2(3, 0)
	strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip.color = strip_color
	outer.add_child(strip)

	# ── content ───────────────────────────────────────────────────────────────
	var pad_c := MarginContainer.new()
	pad_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		pad_c.add_theme_constant_override("margin_" + side, T.PAD_XL)
	for side in ["top", "bottom"]:
		pad_c.add_theme_constant_override("margin_" + side, T.PAD_SM + 4)
	outer.add_child(pad_c)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", T.PAD_MD)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pad_c.add_child(hbox)

	# ── icon box ─────────────────────────────────────────────────────────────
	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(40, 40)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_bg_color: Color
	var icon_border_color: Color
	match item.get("channel", "stable"):
		"stable":
			icon_bg_color     = T.C_TINT_SUCCESS
			icon_border_color = T.C_SUCCESS.darkened(0.3)
		"beta":
			icon_bg_color     = T.C_TINT_WARNING
			icon_border_color = T.C_WARNING.darkened(0.2)
		"dev":
			icon_bg_color     = T.C_TINT_PRO
			icon_border_color = T.C_PRO.darkened(0.2)
		_:
			icon_bg_color     = T.C_BG_HOVER
			icon_border_color = T.C_BORDER
	icon_box.add_theme_stylebox_override("panel",
		T.flat_border(icon_bg_color, icon_border_color, T.RADIUS_LG))
	hbox.add_child(icon_box)

	var icon_path: String = item.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		# SVG / PNG đã download về res://
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(icon_path)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(24, 24)
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex_rect.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		icon_box.add_child(tex_rect)
	else:
		# Emoji fallback theo channel
		var icon_lbl := Label.new()
		match item.get("channel", "stable"):
			"stable": icon_lbl.text = "🛩"
			"beta":   icon_lbl.text = "🧪"
			"dev":    icon_lbl.text = "⚙"
			_:        icon_lbl.text = "📦"
		icon_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_BASE )
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		icon_box.add_child(icon_lbl)

	# ── left: version info ───────────────────────────────────────────────────
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 4)
	hbox.add_child(info)

	# name + badges row — căn trái, không căn giữa
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", T.PAD_SM)
	name_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = item.version
	name_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_BASE)
	name_lbl.add_theme_color_override("font_color", T.C_TEXT)
	name_row.add_child(name_lbl)

	name_row.add_child(T.make_badge(item.channel.capitalize(), item.channel))

	if item.get("active", false):
		name_row.add_child(T.make_badge("Active", "active"))

	# path
	var path_lbl := Label.new()
	path_lbl.text = item.path
	path_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_SM)
	path_lbl.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	path_lbl.clip_text = true
	path_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(path_lbl)

	# ── middle: size + date ──────────────────────────────────────────────────
	var meta := VBoxContainer.new()
	meta.add_theme_constant_override("separation", 2)
	hbox.add_child(meta)

	var size_lbl := Label.new()
	size_lbl.text = _fmt_mb(item.get("size_mb", 0))
	size_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_SM)
	size_lbl.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	size_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(size_lbl)

	var date_lbl := Label.new()
	date_lbl.text = item.get("date", "")
	date_lbl.add_theme_font_size_override("font_size", T.FONT_SIZE_SM)
	date_lbl.add_theme_color_override("font_color", T.C_TEXT_DIM)
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(date_lbl)

	# ── right: action buttons ────────────────────────────────────────────────
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(actions)

	if not item.get("active", false):
		var set_btn := T.make_icon_btn("⚡", "accent")
		set_btn.tooltip_text = "Set as active"
		set_btn.pressed.connect(_on_set_active.bind(item))
		actions.add_child(set_btn)

	var explore_btn := T.make_icon_btn("📁", "default")
	explore_btn.tooltip_text = "Show in Explorer"
	explore_btn.pressed.connect(func(): OS.shell_open(item.path))
	actions.add_child(explore_btn)

	var copy_btn := T.make_icon_btn("⧉", "default")
	copy_btn.tooltip_text = "Copy path"
	copy_btn.pressed.connect(func(): DisplayServer.clipboard_set(item.path))
	actions.add_child(copy_btn)

	var del_btn := T.make_icon_btn("✕", "danger")
	del_btn.tooltip_text = "Uninstall"
	del_btn.pressed.connect(_on_uninstall.bind(item))
	actions.add_child(del_btn)

	return outer

# ─────────────────────────────────────────────────────────────────────────────
#  EMPTY STATE
# ─────────────────────────────────────────────────────────────────────────────
func _build_empty_state() -> Control:
	var pad_c := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad_c.add_theme_constant_override("margin_" + side, 60)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", T.PAD_SM)
	pad_c.add_child(vbox)

	var icon := Label.new()
	icon.text = "🛸"
	icon.add_theme_font_size_override("font_size", 32)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)

	var title := Label.new()
	title.text = "No engine versions installed"
	title.add_theme_font_size_override("font_size", T.FONT_SIZE_MD)
	title.add_theme_color_override("font_color", T.C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Install a version or locate an existing one on disk."
	sub.add_theme_font_size_override("font_size", T.FONT_SIZE_BASE)
	sub.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = T.PAD_MD
	vbox.add_child(spacer)

	vbox.add_child(T.make_btn("+ Install version", true))
	return pad_c

# ─────────────────────────────────────────────────────────────────────────────
#  CALLBACKS  (hookup logic di chuyển vào đây)
# ─────────────────────────────────────────────────────────────────────────────
func _on_set_active(item: Dictionary) -> void:
	for i in _installs:
		i["active"] = (i == item)
	_refresh()

func _on_uninstall(item: Dictionary) -> void:
	# TODO: hiện confirm dialog trước khi xóa
	_installs.erase(item)
	_refresh()

func _refresh() -> void:
	# xóa toàn bộ children rồi build lại
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	_ready()

# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────
static func _fmt_mb(mb: int) -> String:
	if mb >= 1024:
		return "%.1f GB" % (mb / 1024.0)
	return "%d MB" % mb
