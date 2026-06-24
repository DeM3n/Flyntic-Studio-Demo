# CommunityPage.gd
extends Control
const T = preload("res://DashBoard/UITheme.gd")

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var pad := MarginContainer.new()
	for m in ["left", "right"]: pad.add_theme_constant_override("margin_" + m, 28)
	for m in ["top", "bottom"]: pad.add_theme_constant_override("margin_" + m, 24)
	var title := Label.new()
	title.text = "Community"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", T.C_TEXT)
	pad.add_child(title)
	vbox.add_child(pad)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var grid_pad := MarginContainer.new()
	for m in ["left", "right", "bottom"]: grid_pad.add_theme_constant_override("margin_" + m, 28)
	grid_pad.add_child(grid)
	vbox.add_child(grid_pad)

	# Giống tab Community Unity Hub / trang community Godot — thay bằng link Discord/Forum/GitHub thật của Flyntic
	var links := [
		{"title": "Discord", "desc": "Trao đổi trực tiếp với người dùng Flyntic.", "url": "https://discord.com"},
		{"title": "Forum", "desc": "Đặt câu hỏi, chia sẻ project.", "url": "https://godotengine.org/community/"},
		{"title": "GitHub", "desc": "Theo dõi source & báo lỗi.", "url": "https://github.com"},
		{"title": "Asset Library", "desc": "Plugin & tài nguyên chia sẻ.", "url": "https://godotengine.org/asset-library/"},
	]
	for l in links:
		grid.add_child(_build_card(l))

func _build_card(l: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 100)
	panel.add_theme_stylebox_override("panel", T.pad(T.flat_border(T.C_BG_SIDEBAR, T.C_BORDER, 8), 16, 16))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	var title := Label.new()
	title.text = l.title
	title.add_theme_color_override("font_color", T.C_TEXT)
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = l.desc
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	vbox.add_child(desc)
	var open_btn := T.make_btn("Open", false)
	open_btn.custom_minimum_size = Vector2(70, 28)
	open_btn.pressed.connect(func(): OS.shell_open(l.url))
	hbox.add_child(open_btn)
	return panel
