# LearnPage.gd
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
	title.text = "Learn"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", T.C_TEXT)
	pad.add_child(title)
	vbox.add_child(pad)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var grid_pad := MarginContainer.new()
	for m in ["left", "right", "bottom"]: grid_pad.add_theme_constant_override("margin_" + m, 28)
	grid_pad.add_child(grid)
	vbox.add_child(grid_pad)

	# Giống tab "Learn" của Unity Hub / trang docs của Godot — thay link bằng docs riêng của Flyntic
	var resources := [
		{"title": "Documentation", "desc": "Tài liệu chính thức, API reference.", "url": "https://docs.godotengine.org"},
		{"title": "Step-by-step", "desc": "Hướng dẫn làm quen từng bước.", "url": "https://docs.godotengine.org/en/stable/getting_started/step_by_step/index.html"},
		{"title": "Community tutorials", "desc": "Video & bài viết từ cộng đồng.", "url": "https://docs.godotengine.org/en/stable/community/tutorials.html"},
	]
	for r in resources:
		grid.add_child(_build_card(r))

func _build_card(r: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 140)
	panel.add_theme_stylebox_override("panel", T.pad(T.flat_border(T.C_BG_SIDEBAR, T.C_BORDER, 8), 16, 16))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = r.title
	title.add_theme_color_override("font_color", T.C_TEXT)
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = r.desc
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", T.C_TEXT_MUTED)
	vbox.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	var open_btn := T.make_btn("Open", false)
	open_btn.pressed.connect(func(): OS.shell_open(r.url))
	vbox.add_child(open_btn)
	return panel
