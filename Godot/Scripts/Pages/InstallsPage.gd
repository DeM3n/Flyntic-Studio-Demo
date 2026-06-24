# InstallsPage.gd
extends Control
const T = preload("res://DashBoard/UITheme.gd")

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)
	vbox.add_child(_build_header())
	vbox.add_child(T.hsep())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	scroll.add_child(list)

	# TODO: thay bằng danh sách engine thật đã cài (đọc từ thư mục cài đặt)
	var installs := [{"version": "Flyntic 1.0", "channel": "Stable", "path": "C:/FlynticEngine/1.0"}]
	if installs.is_empty():
		var empty := Label.new()
		empty.text = "Chưa có bản engine nào được cài đặt"
		empty.add_theme_color_override("font_color", T.C_TEXT_MUTED)
		list.add_child(empty)
	else:
		for item in installs:
			list.add_child(_build_row(item))
			list.add_child(T.hsep())

func _build_header() -> Control:
	var pad := MarginContainer.new()
	for m in ["left", "right"]: pad.add_theme_constant_override("margin_" + m, 28)
	for m in ["top", "bottom"]: pad.add_theme_constant_override("margin_" + m, 24)
	var hbox := HBoxContainer.new()
	pad.add_child(hbox)
	var title := Label.new()
	title.text = "Installs"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", T.C_TEXT)
	hbox.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	var add_btn := T.make_btn("+ Locate / Install version", true)
	hbox.add_child(add_btn)
	return pad

func _build_row(item: Dictionary) -> Control:
	var pad := MarginContainer.new()
	for m in ["left", "right"]: pad.add_theme_constant_override("margin_" + m, 28)
	for m in ["top", "bottom"]: pad.add_theme_constant_override("margin_" + m, 12)
	var hbox := HBoxContainer.new()
	pad.add_child(hbox)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = "%s  (%s)" % [item.version, item.channel]
	name_lbl.add_theme_color_override("font_color", T.C_TEXT)
	vbox.add_child(name_lbl)
	var path_lbl := Label.new()
	path_lbl.text = item.path
	path_lbl.add_theme_font_size_override("font_size", 11)
	path_lbl.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	vbox.add_child(path_lbl)
	var open_btn := T.make_btn("Show in Explorer", false)
	open_btn.pressed.connect(func(): OS.shell_open(item.path))
	hbox.add_child(open_btn)
	return pad
