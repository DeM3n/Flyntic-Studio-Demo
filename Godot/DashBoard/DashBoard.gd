extends Control

const SAVE_DIR := "user://projects/"

var _all_projects: Array = []
var search_input: LineEdit
var projects_container: VBoxContainer
var empty_label: Label
var modal_overlay: Control
var new_name_input: LineEdit
var section_label: Label

# ── Colors ──────────────────────────────────────────────────────
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
const C_ROW_HOVER  := Color(0.20, 0.20, 0.23)

func _ready() -> void:
	print("=== DASHBOARD READY ===")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_scan_projects()

# ── Styleboxes ──────────────────────────────────────────────────
func _flat(color: Color, radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

func _flat_border(color: Color, border: Color, radius: int = 6, bw: int = 1) -> StyleBoxFlat:
	var s := _flat(color, radius)
	s.border_color = border
	s.border_width_top    = bw
	s.border_width_bottom = bw
	s.border_width_left   = bw
	s.border_width_right  = bw
	return s

func _pad(s: StyleBoxFlat, h: int, v: int) -> StyleBoxFlat:
	s.content_margin_left   = h
	s.content_margin_right  = h
	s.content_margin_top    = v
	s.content_margin_bottom = v
	return s

# ── Build UI ────────────────────────────────────────────────────
func _build_ui() -> void:
	# Root background
	var root_bg := ColorRect.new()
	root_bg.color = C_BG_DARK
	root_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)

	hbox.add_child(_build_sidebar())
	hbox.add_child(_build_main_area())

	modal_overlay = _build_modal()
	add_child(modal_overlay)
	modal_overlay.hide()

# ── Sidebar ─────────────────────────────────────────────────────
func _build_sidebar() -> Control:
	var bg := PanelContainer.new()
	bg.custom_minimum_size = Vector2(220, 0)
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bg.add_theme_stylebox_override("panel", _flat(C_BG_SIDEBAR))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	bg.add_child(vbox)

	# Header
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _pad(_flat(C_BG_SIDEBAR), 16, 14))
	var logo := Label.new()
	logo.text = "  Flyntic Studio"
	logo.add_theme_font_size_override("font_size", 15)
	logo.add_theme_color_override("font_color", C_TEXT)
	header.add_child(logo)
	vbox.add_child(header)

	# Separator
	vbox.add_child(_hsep())

	# Nav
	var nav_items := [
		["Projects",  true,  "res://Assets/folders.svg"],
		["Installs",  false, "res://Assets/server.svg"],
		["Learn",      false, "res://Assets/graduation-cap.svg"],
		["Community", false, "res://Assets/building-2.svg"],
	]
	var nav_pad := MarginContainer.new()
	for m in ["left","right","top","bottom"]:
		nav_pad.add_theme_constant_override("margin_" + m, 8)
	var nav_vbox := VBoxContainer.new()
	nav_vbox.add_theme_constant_override("separation", 2)
	nav_pad.add_child(nav_vbox)
	vbox.add_child(nav_pad)

	for item in nav_items:
		var btn := Button.new()
		btn.text = ""
		btn.flat = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 44)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if item[1]:
			btn.add_theme_stylebox_override("normal", _pad(_flat(C_BG_ACTIVE, 6), 10, 12))
		else:
			btn.add_theme_stylebox_override("normal", _pad(_flat(Color.TRANSPARENT, 6), 10, 12))
			btn.add_theme_stylebox_override("hover",  _pad(_flat(C_BG_HOVER, 6), 10, 12))
		btn.add_theme_stylebox_override("pressed", _pad(_flat(C_BG_ACTIVE, 6), 10, 12))
		btn.add_theme_stylebox_override("focus",   _pad(_flat(Color.TRANSPARENT), 10, 12))

		var content_margin := MarginContainer.new()
		content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_margin.add_theme_constant_override("margin_left", 12)
		content_margin.add_theme_constant_override("margin_right", 12)
		content_margin.add_theme_constant_override("margin_top", 12)
		content_margin.add_theme_constant_override("margin_bottom", 12)
		btn.add_child(content_margin)

		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_margin.add_child(content)

		var text_color := C_TEXT if item[1] else C_TEXT_MUTED
		content.add_child(_make_nav_icon(item[2], text_color))

		var lbl := Label.new()
		lbl.text = item[0]
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", text_color)
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(lbl)

		nav_vbox.add_child(btn)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Footer
	vbox.add_child(_hsep())
	var footer := MarginContainer.new()
	for m in ["left","right","top","bottom"]:
		footer.add_theme_constant_override("margin_" + m, 14)
	var fvbox := VBoxContainer.new()
	fvbox.add_theme_constant_override("separation", 3)
	footer.add_child(fvbox)

	var user_lbl := Label.new()
	user_lbl.text = ProjectState.user_name if ProjectState.user_name  != "" else "User"
	user_lbl.add_theme_font_size_override("font_size", 13)
	user_lbl.add_theme_color_override("font_color", C_TEXT)
	fvbox.add_child(user_lbl)

	var tier_lbl := Label.new()
	tier_lbl.text = ProjectState.tier_name if ProjectState.tier_name != "" else "Trial"
	tier_lbl.add_theme_font_size_override("font_size", 11)
	tier_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	fvbox.add_child(tier_lbl)

	vbox.add_child(footer)
	return bg

func _build_main_area() -> Control:
	var bg := PanelContainer.new()
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	bg.add_theme_stylebox_override("panel", _flat(C_BG_MAIN))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	bg.add_child(vbox)

	# Topbar (chứa luôn tiêu đề Projects)
	var topbar := PanelContainer.new()

	topbar.add_theme_stylebox_override("panel", _pad(_flat(C_BG_SIDEBAR), 12, 10))
	var topbar_vbox := VBoxContainer.new()
	topbar_vbox.add_theme_constant_override("separation", 0)
	topbar.add_child(topbar_vbox)
	var tbar_hbox := HBoxContainer.new()
	tbar_hbox.add_theme_constant_override("separation", 8)
	tbar_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topbar.add_child(tbar_hbox)
	# Khoảng đệm thêm bên dưới, cùng màu với topbar
	var topbar_extra := Control.new()
	topbar_extra.custom_minimum_size = Vector2(0, 80)
	topbar_vbox.add_child(topbar_extra)

	# Page title — bên trái
	var page_title := Label.new()
	page_title.text = "Projects"
	page_title.add_theme_font_size_override("font_size", 28)
	page_title.add_theme_color_override("font_color", C_TEXT)
	page_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tbar_hbox.add_child(page_title)

	# Spacer đẩy Search + Open + New project sang phải
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tbar_hbox.add_child(spacer)

	# Search
	search_input = LineEdit.new()
	search_input.placeholder_text = "Search..."
	search_input.custom_minimum_size = Vector2(220, 32)
	search_input.size_flags_horizontal = Control.SIZE_SHRINK_END
	search_input.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	search_input.add_theme_stylebox_override("normal", _pad(_flat_border(C_BG_DARK, C_BORDER, 6), 10, 6))
	search_input.add_theme_stylebox_override("focus",  _pad(_flat_border(C_BG_DARK, C_ACCENT, 6), 10, 6))
	search_input.add_theme_color_override("font_color", C_TEXT)
	search_input.add_theme_color_override("font_placeholder_color", C_TEXT_MUTED)
	search_input.text_changed.connect(_on_search_changed)
	tbar_hbox.add_child(search_input)

	# Open
	var open_btn := _make_btn("Open", false)
	open_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	open_btn.pressed.connect(_on_open_btn)
	tbar_hbox.add_child(open_btn)

	# + New project
	var new_btn := _make_btn("+ New project", true)
	new_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	new_btn.pressed.connect(_on_new_project_btn)
	tbar_hbox.add_child(new_btn)

	vbox.add_child(topbar)
	vbox.add_child(_hsep())


	# Table header
	vbox.add_child(_build_table_header())
	vbox.add_child(_hsep())

	# Scroll + list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	projects_container = VBoxContainer.new()
	projects_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	projects_container.add_theme_constant_override("separation", 0)
	scroll.add_child(projects_container)

	# Empty state label
	empty_label = Label.new()
	empty_label.text = "No projects yet"
	empty_label.add_theme_font_size_override("font_size", 13)
	empty_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	return bg

func _build_table_header() -> Control:
	const ROW_PAD_H := 28

	var pad := MarginContainer.new()
	for m in ["left","right"]: pad.add_theme_constant_override("margin_" + m, ROW_PAD_H)
	for m in ["top","bottom"]: pad.add_theme_constant_override("margin_" + m, 7)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	pad.add_child(hbox)

	# Font đậm dùng chung cho header
	var bold_font := FontVariation.new()
	bold_font.set_variation_embolden(1.0)

	# NAME col — expand fill
	var name_lbl := Label.new()
	name_lbl.text = "NAME"
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_font_override("font", bold_font)
	name_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	hbox.add_child(name_lbl)

	# MODIFIED col — fixed width
	var mod_lbl := Label.new()
	mod_lbl.text = "MODIFIED"
	mod_lbl.custom_minimum_size = Vector2(180, 0)
	mod_lbl.add_theme_font_size_override("font_size", 13)
	mod_lbl.add_theme_font_override("font", bold_font)
	mod_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	hbox.add_child(mod_lbl)

	# EDITOR VERSION col — fixed width
	var ver_lbl := Label.new()
	ver_lbl.text = "EDITOR VERSION"
	ver_lbl.custom_minimum_size = Vector2(180, 0)
	ver_lbl.add_theme_font_size_override("font_size", 13)
	ver_lbl.add_theme_font_override("font", bold_font)
	ver_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	hbox.add_child(ver_lbl)

	return pad

func _make_project_row(p: Dictionary) -> Control:
	const ROW_PAD_H := 28
	const ROW_PAD_V := 12

	var btn := Button.new()
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_stylebox_override("normal",  _pad(_flat(Color.TRANSPARENT), ROW_PAD_H, ROW_PAD_V))
	btn.add_theme_stylebox_override("hover",   _pad(_flat(C_ROW_HOVER), ROW_PAD_H, ROW_PAD_V))
	btn.add_theme_stylebox_override("pressed", _pad(_flat(C_BG_PRESSED), ROW_PAD_H, ROW_PAD_V))
	btn.add_theme_stylebox_override("focus",   _pad(_flat(Color.TRANSPARENT), ROW_PAD_H, ROW_PAD_V))
	btn.pressed.connect(func(): _open_project(p.path))

	# Margin lồng bên trong = đúng padding của stylebox button,
	# để hbox align chuẩn với content_margin của Button (không hardcode riêng lẻ)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left",   ROW_PAD_H)
	margin.add_theme_constant_override("margin_right",  ROW_PAD_H)
	margin.add_theme_constant_override("margin_top",    ROW_PAD_V)
	margin.add_theme_constant_override("margin_bottom", ROW_PAD_V)
	btn.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 0)
	margin.add_child(hbox)

	# Name col — tên to + path nhỏ bên dưới
	var name_vbox := VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	name_vbox.add_theme_constant_override("separation", 2)
	name_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_vbox)

	var name_lbl := Label.new()
	name_lbl.text = p.name
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(name_lbl)

	var path_lbl := Label.new()
	path_lbl.text = p.path
	path_lbl.clip_text = true
	path_lbl.add_theme_font_size_override("font_size", 11)
	path_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	path_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(path_lbl)

	# Modified col
	var mod_lbl := Label.new()
	mod_lbl.text = _time_ago(p.modified)
	mod_lbl.custom_minimum_size = Vector2(180, 0)
	mod_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mod_lbl.add_theme_font_size_override("font_size", 13)
	mod_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	mod_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(mod_lbl)

	# Version col
	var ver_lbl := Label.new()
	ver_lbl.text = "Flyntic 1.0"
	ver_lbl.custom_minimum_size = Vector2(180, 0)
	ver_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ver_lbl.add_theme_font_size_override("font_size", 13)
	ver_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	ver_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(ver_lbl)

	return btn

# ── Modal ────────────────────────────────────────────────────────
func _build_modal() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_stylebox_override("panel", _pad(_flat_border(C_BG_SIDEBAR, C_BORDER, 8), 24, 20))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Create new project"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_TEXT)
	vbox.add_child(title)

	var lbl := Label.new()
	lbl.text = "Project name"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	vbox.add_child(lbl)

	new_name_input = LineEdit.new()
	new_name_input.placeholder_text = "My Drone Project"
	new_name_input.custom_minimum_size = Vector2(0, 34)
	new_name_input.add_theme_stylebox_override("normal", _pad(_flat_border(C_BG_DARK, C_BORDER, 6), 10, 6))
	new_name_input.add_theme_stylebox_override("focus",  _pad(_flat_border(C_BG_DARK, C_ACCENT, 6), 10, 6))
	new_name_input.add_theme_color_override("font_color", C_TEXT)
	new_name_input.add_theme_color_override("font_placeholder_color", C_TEXT_MUTED)
	new_name_input.gui_input.connect(_on_modal_input)
	vbox.add_child(new_name_input)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(hbox)

	var cancel_btn := _make_btn("Cancel", false)
	cancel_btn.pressed.connect(_on_modal_cancel)
	hbox.add_child(cancel_btn)

	var confirm_btn := _make_btn("Create", true)
	confirm_btn.pressed.connect(_on_modal_confirm)
	hbox.add_child(confirm_btn)

	return overlay

# ── Helpers ──────────────────────────────────────────────────────
func _make_btn(text: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", 13)
	if primary:
		btn.add_theme_stylebox_override("normal",  _pad(_flat(C_ACCENT, 6), 14, 6))
		btn.add_theme_stylebox_override("hover",   _pad(_flat(C_ACCENT.lightened(0.1), 6), 14, 6))
		btn.add_theme_stylebox_override("pressed", _pad(_flat(C_ACCENT.darkened(0.1), 6), 14, 6))
		btn.add_theme_stylebox_override("focus",   _pad(_flat(C_ACCENT, 6), 14, 6))
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		btn.add_theme_stylebox_override("normal",  _pad(_flat_border(Color.TRANSPARENT, C_BORDER, 6), 14, 6))
		btn.add_theme_stylebox_override("hover",   _pad(_flat(C_BG_HOVER, 6), 14, 6))
		btn.add_theme_stylebox_override("pressed", _pad(_flat(C_BG_ACTIVE, 6), 14, 6))
		btn.add_theme_stylebox_override("focus",   _pad(_flat_border(Color.TRANSPARENT, C_BORDER, 6), 14, 6))
		btn.add_theme_color_override("font_color", C_TEXT)
	return btn

func _hsep() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", C_BORDER)
	sep.add_theme_constant_override("separation", 1)
	return sep

# ── Scan & Render ────────────────────────────────────────────────
func _scan_projects() -> void:
	_all_projects.clear()
	
	var index_path := "user://projects_index.json"
	if not FileAccess.file_exists(index_path):
		_render_projects([])
		return
	
	var f := FileAccess.open(index_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		_render_projects([])
		f.close()
		return
	f.close()
	
	for path in json.data:
		if FileAccess.file_exists(path):  # file còn tồn tại không
			_all_projects.append({
				"name":     path.get_file().get_basename(),
				"path":     path,
				"modified": FileAccess.get_modified_time(path),
			})
	
	_all_projects.sort_custom(func(a, b): return a.modified > b.modified)
	_render_projects(_all_projects)

func _render_projects(list: Array) -> void:
	for child in projects_container.get_children():
		child.queue_free()

	#section_label.text = "%d project%s" % [list.size(), "s" if list.size() != 1 else ""]
	empty_label.visible = list.is_empty()

	if list.is_empty():
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_top", 40)
		pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if empty_label.get_parent() != null and empty_label.get_parent() != projects_container:
			empty_label.get_parent().queue_free()
		projects_container.add_child(pad)
		pad.add_child(empty_label)
		return

	for p in list:
		projects_container.add_child(_make_project_row(p))
		projects_container.add_child(_hsep())

# ── Actions ──────────────────────────────────────────────────────
func _on_search_changed(q: String) -> void:
	var filtered := _all_projects.filter(func(p): return p.name.to_lower().contains(q.to_lower()))
	_render_projects(filtered)

func _on_new_project_btn() -> void:
	new_name_input.text = ""
	modal_overlay.show()
	new_name_input.grab_focus()

func _on_modal_confirm() -> void:
	var proj_name := new_name_input.text.strip_edges()
	if proj_name.is_empty():
		return
	modal_overlay.hide()
	ProjectState.pending_name = proj_name
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_modal_cancel() -> void:
	modal_overlay.hide()

func _on_modal_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:  _on_modal_confirm()
		if event.keycode == KEY_ESCAPE: _on_modal_cancel()

func _on_open_btn() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters   = ["*.flyntic ; Flyntic Project"]
	dialog.access    = FileDialog.ACCESS_FILESYSTEM
	dialog.min_size  = Vector2i(640, 420)
	add_child(dialog)
	dialog.popup_centered()
	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		_open_project(path)
	)
	dialog.canceled.connect(func(): dialog.queue_free())

func _open_project(path: String) -> void:
	ProjectState.pending_path = path
	get_tree().change_scene_to_file("res://Main.tscn")

func _time_ago(unix: int) -> String:
	var diff := int(Time.get_unix_time_from_system()) - unix
	if diff < 60:     return "Just now"
	if diff < 3600:   return "%dm ago" % int(float(diff) / 60)
	if diff < 86400:  return "%dh ago" % int(float(diff) / 3600)
	if diff < 604800: return "%dd ago" % int(float(diff) / 86400)
	return "%dw ago"  % int(float(diff) / 604800)

func _make_nav_icon(path: String, color: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(path)
	icon.custom_minimum_size = Vector2(20, 20)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode  = TextureRect.EXPAND_KEEP_SIZE   # <-- đổi từ EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.clip_contents = true  
	icon.modulate = color
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon
#=============ket noi voi main ====================================
func _on_dashboard_open_project(path: String) -> void:
	# Lưu path vào autoload để Main.gd đọc sau khi scene load xong
	ProjectState.pending_path = path
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_dashboard_new_project(proj_name: String) -> void:
	ProjectState.pending_path = ""
	ProjectState.pending_name = proj_name
	get_tree().change_scene_to_file("res://Main.tscn")
