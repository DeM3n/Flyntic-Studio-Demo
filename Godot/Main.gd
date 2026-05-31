extends Control
## Flyntic Studio — Godot Drone Assembly & Simulation
## Ported from web demo (Three.js) with full physics preview

# ──────────────────────────── NODE REFS ────────────────────────────
# These paths EXACTLY match Main.tscn node tree

# Left sidebar
@onready var comp_list: ItemList = $Root/Content/Left/CompPanel/V/CompList
@onready var hier_tree: Tree   = $Root/Content/Left/HierarchyPanel/V/Tree
@onready var hier_del_btn: Button = $Root/Content/Left/HierarchyPanel/V/H/DelBtn
@onready var left_panel: Control  = $Root/Content/Left
@onready var center_right: Control  = $Root/Content/CenterRight
@onready var topbar_h: HBoxContainer = $Root/TopBar/H 
# 3D scene nodes
@onready var scene_root: Node3D     = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC/VP/Scene
@onready var pivot: Node3D           = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC/VP/Scene/Pivot
@onready var camera: Camera3D        = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC/VP/Scene/Pivot/Camera
@onready var components_group: Node3D = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC/VP/Scene/Components
@onready var snap_hints: Node3D      = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC/VP/Scene/SnapHints
@onready var wires_group: Node3D     = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC/VP/Scene/Components/Wires
@onready var viewport: SubViewport   = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC/VP

# Console & monitors
@onready var log_box: RichTextLabel = $Root/Content/CenterRight/Center/Console/V/Log
@onready var weight_val: Label = $Root/Content/CenterRight/Right/Scroll/V/Perf/Weight/Val
@onready var thrust_val: Label = $Root/Content/CenterRight/Right/Scroll/V/Perf/Thrust/Val
@onready var twr_val: Label    = $Root/Content/CenterRight/Right/Scroll/V/Perf/TWR/Val
@onready var cap_val: Label    = $Root/Content/CenterRight/Right/Scroll/V/Perf/Capability/Val
@onready var bat_val: Label    = $Root/Content/CenterRight/Right/Scroll/V/Power/Battery/Val
@onready var ft_val: Label     = $Root/Content/CenterRight/Right/Scroll/V/Power/FlightTime/Val
@onready var diag_text: RichTextLabel = $Root/Content/CenterRight/Right/Scroll/V/Diag/DiagText
@onready var comp_count: Label = $Root/StatusBar/H/Comp
@onready var tabs: TabContainer = $Root/Content/CenterRight/Center/Tabs
@onready var console_panel: Panel = $Root/Content/CenterRight/Center/Console
@onready var vpc: SubViewportContainer = $Root/Content/CenterRight/Center/Tabs/Canvas/VPC

# Blocks UI
@onready var workspace: Panel = $Root/Content/CenterRight/Center/Tabs/Blocks/MainH/Workspace
@onready var toolbox: Panel = $Root/Content/CenterRight/Center/Tabs/Blocks/MainH/Toolbox
@onready var toolbox_v: VBoxContainer = $Root/Content/CenterRight/Center/Tabs/Blocks/MainH/Toolbox/V
@onready var block_script = preload("res://Block.gd")

# Simulation buttons
@onready var play_btn: Button  = $Root/Content/CenterRight/Right/Scroll/V/SimPanel/PlayBtn
@onready var pause_btn: Button = $Root/Content/CenterRight/Right/Scroll/V/SimPanel/PauseBtn
@onready var stop_btn: Button  = $Root/Content/CenterRight/Right/Scroll/V/SimPanel/StopBtn
@onready var sim_label: Label  = $Root/Content/CenterRight/Right/Scroll/V/SimPanel/StatusLbl
@onready var topbar_status: Label = $Root/TopBar/H/Status
@onready var cat_sidebar: VBoxContainer = $Root/Content/CenterRight/Center/Tabs/Blocks/MainH/Sidebar/V

# Scale factors for components
const OBJ_SCALE := 0.01 # convert mm to Godot units

# Physics bridge
var bridge: Node = null
var bridge_connected := false
var use_bridge_physics := true  # Set false to force kinematic fallback
var wiring_panel: Control = null
var CATEGORIES := {
	"FRAME": ["PVC Pipe Frame", "Carbon Fiber Body"],
	"MOTOR": ["Motor 2205 2300KV", "Motor 2207 2400KV", "Motor 2212 920KV"],
	"PROPELLER": ["Propeller 5045", "Propeller 6045"],
	"BATTERY": ["Lipo 4S 1500mAh"],
	"ELECTRONICS": ["F4 Flight Controller", "4-in-1 ESC"],
}
#======= Block category
# Thay thế BLOCK_CATEGORIES cũ
var BLOCK_CATEGORIES := {
	"BtnE":      {"label": "Events",    "color": Color(0.85, 0.65, 0.0),
		"blocks": [
			{"type": "start",   "label": "When ⚐ clicked", "color": Color(0.85, 0.65, 0)},
		]},
	"BtnM":      {"label": "Motion",    "color": Color(0.25, 0.45, 0.85),
		"blocks": [
			{"type": "forward", "label": "Forward [ 50 ] cm", "color": Color(0.25, 0.55, 0.95)},
			{"type": "hover",   "label": "Hover (2s)",         "color": Color(0.2,  0.5,  0.9)},
		]},
	"BtnC":      {"label": "Flight",    "color": Color(0.2, 0.6, 0.35),
		"blocks": [
			{"type": "take_off","label": "Take Off",   "color": Color(0.3, 0.6, 1.0)},
			{"type": "land",    "label": "Land drone", "color": Color(0.9, 0.5, 0.1)},
		]},
	"Variables": {"label": "Variables", "color": Color(0.8, 0.3, 0.25),
		"blocks": []},
}

var _active_block_cat := "BtnE"

var _block_cat_collapsed  := {}  # { "Events": false, "Flight": true, ... }
var COMPONENTS := {
	"PVC Pipe Frame": {
		"type": "Frame", "weight": 250, "thrust": 0, "capacity": 0,
		"color": Color(0.9, 0.9, 0.85),
		"use_obj": true, "obj_path": "res://Components/quad_pvc_frame.obj",
		"ports": [
			{"name": "fl", "pos": Vector3(2.28, 2.01, 2.28), "slot": true, "allowed": ["Motor"]},
			{"name": "fr", "pos": Vector3(2.28, 2.01, -2.28), "slot": true, "allowed": ["Motor"]},
			{"name": "bl", "pos": Vector3(-2.28, 2.01, 2.28), "slot": true, "allowed": ["Motor"]},
			{"name": "br", "pos": Vector3(-2.28, 2.01, -2.28), "slot": true, "allowed": ["Motor"]},
			#{"name": "center_top", "pos": Vector3(0, 1.8, 0), "slot": true, "allowed": ["FC", "ESC"]},
			{"name": "fc_slot", "pos": Vector3(0, 1.8, 0), "slot": true, "allowed": ["FC"]},
			{"name": "esc_slot", "pos": Vector3(0, 1.2, 0), "slot": true, "allowed": ["ESC"]},
			{"name": "center_bot", "pos": Vector3(0, 0.5, 0), "slot": true, "allowed": ["Battery"]},
		]
	},
	"Carbon Fiber Body": {
		"type": "Frame", "weight": 180, "thrust": 0, "capacity": 0,
		"color": Color(0.4, 0.4, 0.42),
		"use_obj": false,
		"ports": [
			{"name": "fl", "pos": Vector3(2, 1.5, 2), "slot": true, "allowed": ["Motor"]},
			{"name": "fr", "pos": Vector3(2, 1.5, -2), "slot": true, "allowed": ["Motor"]},
			{"name": "bl", "pos": Vector3(-2, 1.5, 2), "slot": true, "allowed": ["Motor"]},
			{"name": "br", "pos": Vector3(-2, 1.5, -2), "slot": true, "allowed": ["Motor"]},
			{"name": "center", "pos": Vector3(0, 1.0, 0), "slot": true, "allowed": ["FC", "Battery", "ESC"]},
		]
	},
	"Motor 2205 2300KV": {
		"type": "Motor", "weight": 35, "thrust": 850, "capacity": 0,
		"color": Color(0.6, 0.25, 0.25),
		"ground_offset": 0.3,
		"ports": [{"name": "prop", "pos": Vector3(0, 0.5, 0), "slot": true, "allowed": ["Propeller"]}]
	},
	"Motor 2207 2400KV": {
		"type": "Motor", "weight": 42, "thrust": 1100, "capacity": 0,
		"color": Color(0.25, 0.45, 0.8),
		"ground_offset": 0.3,
		"ports": [{"name": "prop", "pos": Vector3(0, 0.5, 0), "slot": true, "allowed": ["Propeller"]}]
	},
	"Motor 2212 920KV": {
		"type": "Motor", "weight": 56, "thrust": 980, "capacity": 0,
		"color": Color(0.8, 0.55, 0.1),
		"ground_offset": 0.3,
		"ports": [{"name": "prop", "pos": Vector3(0, 0.5, 0), "slot": true, "allowed": ["Propeller"]}]
	},
	"Propeller 5045": {
		"type": "Propeller", "weight": 8, "thrust": 0, "capacity": 0,
		"ground_offset": 0.07,
		"color": Color(0.8, 0.1, 0.1), "ports": []
	},
	"Propeller 6045": {
		"type": "Propeller", "weight": 12, "thrust": 0, "capacity": 0,
		"ground_offset": 0.07,
		"color": Color(0.1, 0.1, 0.8), "ports": []
	},
	"Lipo 4S 1500mAh": {
		"type": "Battery", "weight": 185, "thrust": 0, "capacity": 1500,
		 "ground_offset": 0.1,
		"color": Color(0.85, 0.7, 0.15), "ports": []
	},
	"F4 Flight Controller": {
		"type": "FC", "weight": 7, "thrust": 0, "capacity": 0,
		 "ground_offset": 0.1,
		"color": Color(0.0, 0.35, 0.0), "ports": []
	},
	"4-in-1 ESC": {
		"type": "ESC", "weight": 15, "thrust": 0, "capacity": 0,
		 "ground_offset": 0.1,
		"color": Color(0.0, 0.0, 0.5), "ports": []
	},
}

# Runtime state
var placed: Array[Dictionary] = []
var wires_data: Array[Dictionary] = []
var ghost: Node3D = null
var cur_id := ""
var ghost_rot := 0.0
var orbiting := false
var panning := false
var zoom := 12.0
var camera_rot := Vector2(-0.5, 0.0) # Vertical (X) and Horizontal (Y) rotation
var sim_state := "stopped" # stopped | playing | paused
var sim_time := 0.0
var sim_sequence: Array[Dictionary] = []
var sim_step_idx := 0
var sim_step_timer := 0.0
var sim_target_pos := Vector3.ZERO
var sim_target_rot := Vector3.ZERO
var trash_panel: Panel = null

# ──────────────────────────── INIT ────────────────────────────────
func _ready():
	_build_comp_list()
	_build_floor()
	_build_grid()
	_place("PVC Pipe Frame", Vector3.ZERO)
	_focus_camera_on_drone()
	_update_all()
	play_btn.pressed.connect(_on_play)
	pause_btn.pressed.connect(_on_pause)
	stop_btn.pressed.connect(_on_stop)
	comp_list.item_selected.connect(_on_item_selected)
	# ==================== HIERARCHY SETUP ====================
	
	hier_tree.item_selected.connect(_on_hier_item_selected)
	hier_del_btn.pressed.connect(_remove_selected)
	hier_tree.hide_root = true
	hier_tree.columns = 1
	hier_tree.allow_reselect = true
	hier_tree.hide_folding = false
	hier_tree.enable_recursive_folding = true
	
	_build_hierarchy_tree()
	
	_setup_blocks()
	_create_trash_zone()
	# Pre-populate workspace with a standard 'When flag clicked' stack
	_create_block("start", "When ⚐ clicked", Color(0.85, 0.65, 0), Vector2(50, 50))
	# Initialize physics bridge
	_init_bridge()
	var w2d = load("res://Wiring.gd").new()
	w2d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tabs.add_child(w2d)
	wiring_panel = w2d
	_create_hier_toggle()
	
	_log("Flyntic Studio initialized", "success")


func _init_bridge():
	var bridge_script = load("res://PhysicsBridge.gd")
	if bridge_script == null:
		_log("PhysicsBridge.gd not found — kinematic mode only", "warning")
		return
	bridge = Node.new()
	bridge.set_script(bridge_script)
	bridge.name = "PhysicsBridge"
	add_child(bridge)
	bridge.bridge_connected.connect(_on_bridge_connected)
	bridge.bridge_disconnected.connect(_on_bridge_disconnected)
	bridge.state_received.connect(_on_bridge_state)
	_log("Physics bridge initialized — connecting to TCP server...", "info")

func _on_bridge_connected():
	bridge_connected = true
	_log("Bridge: Connected (" + bridge.bridge_mode + " mode)", "success")

func _on_bridge_disconnected():
	bridge_connected = false
	_log("Bridge: Disconnected — using kinematic fallback", "warning")

#func _setup_blocks():
	## Wire up toolbox buttons to spawn blocks
	#for child in toolbox_v.get_children():
		#if is_instance_valid(child) and (child is Button or child is Panel):
			#child.gui_input.connect(_on_toolbox_input.bind(child))
#
#func _on_toolbox_input(event, node):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var type = node.name.to_lower()
		#var label = ""
		#var color = Color(1, 0.7, 0)
		#
		#match type:
			#"b1": # Events
				#label = "When ⚐ clicked"
				#type = "start"
			#"bt1": # Take off
				#label = "Take Off"
				#type = "take_off"
				#color = Color(0.3, 0.6, 1.0)
			#"bm1": # Forward
				#label = "Forward [ 50 ] cm"
				#type = "forward"
				#color = Color(0.25, 0.55, 0.95)
			#"bm2": # Hover
				#label = "Hover (2s)"
				#type = "hover"
				#color = Color(0.2, 0.5, 0.9)
			#"bl1": # Land
				#label = "Land drone"
				#type = "land"
				#color = Color(0.9, 0.5, 0.1)
#
		#_create_block(type, label, color, get_global_mouse_position() - workspace.global_position + Vector2(10, 0))

#func _setup_blocks():
	## Khởi tạo trạng thái collapse (mặc định: tất cả mở)
	#for cat in BLOCK_CATEGORIES:
		#if not _cat_collapsed.has(cat):
			#_block_cat_collapsed [cat] = false
		#_build_toolbox()
#
#func _on_toolbox_input(event, node):
	#if event is InputEventMouseButton \
	#and event.button_index == MOUSE_BUTTON_LEFT \
	#and event.pressed:
		#if not node.has_meta("block_type"):
			#return
		#var type:  String = node.get_meta("block_type")
		#var label: String = node.get_meta("block_label")
		#var color: Color  = node.get_meta("block_color")
		#_create_block(type, label, color,
			#get_global_mouse_position() - workspace.global_position + Vector2(10, 0))

func _setup_blocks():
	_active_block_cat = "BtnE"
	
	# Wire up từng button đã có sẵn trong scene
	for node_name in BLOCK_CATEGORIES:
		var btn = cat_sidebar.get_node_or_null(node_name)
		if not is_instance_valid(btn):
			continue
		var cat_key = node_name  # capture
		btn.pressed.connect(func():
			_active_block_cat = cat_key
			_refresh_cat_styles()
			_build_block_list()
			)
	
	_refresh_cat_styles()
	_build_block_list()

func _refresh_cat_styles():
	for node_name in BLOCK_CATEGORIES:
		var btn = cat_sidebar.get_node_or_null(node_name)
		if not is_instance_valid(btn): continue
		
		var is_active = (node_name == _active_block_cat)
		var cat_color: Color = BLOCK_CATEGORIES[node_name]["color"]
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = cat_color if is_active else Color(0.15, 0.15, 0.18)
		sb.corner_radius_top_left    = 6
		sb.corner_radius_top_right   = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal",  sb)
		btn.add_theme_stylebox_override("hover",   sb)
		btn.add_theme_stylebox_override("pressed", sb)
		
		var font_color = Color.WHITE if is_active else Color(0.5, 0.5, 0.55)
		btn.add_theme_color_override("font_color", font_color)

func _on_toolbox_input(event, node):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		if not node.has_meta("block_type"): return
	_create_block(
			node.get_meta("block_type"),
			node.get_meta("block_label"),
			node.get_meta("block_color"),
			get_global_mouse_position() - workspace.global_position + Vector2(10, 0)
)

#func _build_block_list():
	## Xóa blocks cũ, giữ trash zone
	#for child in toolbox_v.get_children():
		#if is_instance_valid(child) and child.name != "TrashZone":
			#child.queue_free()
	#
	#var entries = BLOCK_CATEGORIES.get(_active_block_cat, {}).get("blocks", [])
	#
	#if entries.is_empty():
		#var lbl = Label.new()
		#lbl.text = "No blocks yet"
		#lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		#lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		#toolbox_v.add_child(lbl)
		#return
	#for entry in entries:
		#var btn = Button.new()
		#btn.text    = entry["label"]
		#btn.custom_minimum_size = Vector2(0, 40)
		#btn.size_flags_horizontal = Control.SIZE_FILL
		#
		#var bsb = StyleBoxFlat.new()
		#bsb.bg_color = entry["color"]
		#bsb.corner_radius_top_left    = 8
		#bsb.corner_radius_top_right   = 8
		#bsb.corner_radius_bottom_left = 8
		#bsb.corner_radius_bottom_right = 8
		#btn.add_theme_stylebox_override("normal", bsb)
		#btn.add_theme_font_size_override("font_size", 11)
		#
		#btn.set_meta("block_type",  entry["type"])
		#btn.set_meta("block_label", entry["label"])
		#btn.set_meta("block_color", entry["color"])
		#btn.gui_input.connect(_on_toolbox_input.bind(btn))
		#toolbox_v.add_child(btn)
func _build_block_list():
	for child in toolbox_v.get_children():
		if is_instance_valid(child) and child.name != "TrashZone":
			child.queue_free()
	
	var entries = BLOCK_CATEGORIES.get(_active_block_cat, {}).get("blocks", [])
	
	if entries.is_empty():
		var lbl = Label.new()
		lbl.text = "No blocks yet"
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		toolbox_v.add_child(lbl)
		return
	for entry in entries:
		var btn = Button.new()
		btn.text = entry["label"]
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_FILL
		
		var bsb = StyleBoxFlat.new()
		bsb.bg_color = entry["color"]
		bsb.corner_radius_top_left    = 8
		bsb.corner_radius_top_right   = 8
		bsb.corner_radius_bottom_left = 8
		bsb.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", bsb)
		btn.add_theme_font_size_override("font_size", 11)
		
		# ✅ Dùng pressed thay vì gui_input
		var e = entry  # capture
		btn.pressed.connect(func():
			_create_block(
				e["type"],
				e["label"],
				e["color"],
				get_global_mouse_position() - workspace.global_position + Vector2(10, 0)
			)
		)
		toolbox_v.add_child(btn)

func _build_toolbox():
	# Xóa hết children cũ
	for child in toolbox_v.get_children():
		child.queue_free()

	for cat in BLOCK_CATEGORIES:
		# ── Header button ──
		var header = Button.new()
		var is_open = not _cat_collapsed.get(cat, false)
		var arrow = "▾" if is_open else "▸"
		header.text = arrow + " " + cat
		header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		header.flat = false
		header.custom_minimum_size = Vector2(0, 32)
		
		# Style header
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.18, 0.22)
		sb.corner_radius_top_left    = 6
		sb.corner_radius_top_right   = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		header.add_theme_stylebox_override("normal", sb)
		header.add_theme_font_size_override("font_size", 12)
		
		toolbox_v.add_child(header)

		# ── Block buttons trong category này ──
		var blocks_in_cat: Array[Button] = []
		for entry in BLOCK_CATEGORIES[cat]:
			var btn = Button.new()
			btn.text = entry["label"]
			btn.custom_minimum_size = Vector2(0, 36)
			btn.visible = is_open

			var bsb = StyleBoxFlat.new()
			var c: Color = entry["color"]
			bsb.bg_color = c
			bsb.corner_radius_top_left    = 8
			bsb.corner_radius_top_right   = 8
			bsb.corner_radius_bottom_left = 8
			bsb.corner_radius_bottom_right = 8
			btn.add_theme_stylebox_override("normal", bsb)
			btn.add_theme_font_size_override("font_size", 11)

			# Lưu metadata để _on_toolbox_input biết type
			btn.set_meta("block_type",  entry["type"])
			btn.set_meta("block_label", entry["label"])
			btn.set_meta("block_color", entry["color"])

			btn.gui_input.connect(_on_toolbox_input.bind(btn))
			toolbox_v.add_child(btn)
			blocks_in_cat.append(btn)

		# Toggle khi click header — dùng closure capture
		var cat_name = cat  # capture for lambda
		header.pressed.connect(func():
			_cat_collapsed[cat_name] = not _cat_collapsed.get(cat_name, false)
			var now_open = not _cat_collapsed[cat_name]
			header.text = ("▾ " if now_open else "▸ ") + cat_name
			for b in blocks_in_cat:
				if is_instance_valid(b):
					b.visible = now_open)

	# Thêm trash zone sau cùng
	_create_trash_zone()

var _dragging_block: Panel = null

func _create_block(type: String, text: String, color: Color, pos: Vector2):
	var b = Panel.new()
	b.set_script(block_script)
	b.custom_minimum_size = Vector2(190, 48) # Slightly taller for notches
	b.block_type = type
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	b.add_theme_stylebox_override("panel", sb)
	
	# Visual Connector: Top Cutout (Darker overlay)
	if type != "start":
		var cutout = Panel.new()
		cutout.custom_minimum_size = Vector2(24, 8)
		var csb = StyleBoxFlat.new()
		csb.bg_color = Color(0.1, 0.1, 0.1) # Dark like workspace
		csb.corner_radius_bottom_left = 6
		csb.corner_radius_bottom_right = 6
		cutout.add_theme_stylebox_override("panel", csb)
		cutout.position = Vector2(25, -1)
		b.add_child(cutout)
		cutout.z_index = 1


	# Visual Connector: Bottom Notch (Same color)
	var notch = Panel.new()
	notch.custom_minimum_size = Vector2(24, 8)
	var nsb = StyleBoxFlat.new()
	nsb.bg_color = color
	nsb.corner_radius_bottom_left = 6
	nsb.corner_radius_bottom_right = 6
	notch.add_theme_stylebox_override("panel", nsb)
	notch.position = Vector2(25, 47)
	b.add_child(notch)
	notch.z_index = 5
	
	# ================== LABEL ==================
	var block_label = Label.new()
	block_label.name = "L"
	block_label.text = text
	block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	block_label.add_theme_font_size_override("font_size", 11)
	b.add_child(block_label)

	# Editable Input for specific blocks
	
	if type == "forward":
		block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		block_label.position.x = 10
		block_label.text = "Forward                      cm" # More space
		block_label.add_theme_font_size_override("font_size", 12)
		
		# White circular background for input
		var input_bg = Panel.new()
		input_bg.custom_minimum_size = Vector2(50, 24)
		input_bg.position = Vector2(62, 12)
		var ibsb = StyleBoxFlat.new()
		ibsb.bg_color = Color(1, 1, 1)
		ibsb.corner_radius_top_left = 12
		ibsb.corner_radius_top_right = 12
		ibsb.corner_radius_bottom_left = 12
		ibsb.corner_radius_bottom_right = 12
		input_bg.name = "input_bg"
		input_bg.add_theme_stylebox_override("panel", ibsb)
		b.add_child(input_bg)

		var input = LineEdit.new()
		input.name = "Input"
		input.text = "50"
		input.alignment = HORIZONTAL_ALIGNMENT_CENTER
		input.add_theme_font_size_override("font_size", 11)
		input.add_theme_color_override("font_color", Color(0, 0, 0))
		input.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Transparent line edit over the white background
		var empty_sb = StyleBoxEmpty.new()
		input.add_theme_stylebox_override("normal", empty_sb)
		input.add_theme_stylebox_override("focus", empty_sb)
		input_bg.add_child(input)
	block_label.z_index = 3
	# Nếu có input thì cũng đưa lên trên
	if type == "forward":
		var input_bg = b.get_node_or_null("input_bg")
		if input_bg:
			input_bg.z_index = 4

	workspace.add_child(b)
	b.position = pos
	
	b.drag_started.connect(func():
		print("=== DRAG START === ", b.block_type)
		_dragging_block = b 
		if is_instance_valid(trash_panel):
			trash_panel.visible = true
		_apply_lift_effect(b, true)
	)
	b.drag_ended.connect(func():
		_dragging_block = null 
		if is_instance_valid(trash_panel):
			trash_panel.visible = false
		_apply_lift_effect(b, false)
		_check_snapping(b)
	)
	return b
# LIFTING EFFECT WHEN DRAGGING
func _apply_lift_effect(block: Panel, lifting: bool):
	if not is_instance_valid(block):
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if lifting:
		# Khi nhấc lên: to hơn, nghiêng, bóng mạnh hơn
		tween.tween_property(block, "scale", Vector2(1.05, 1.05), 0.12)
		tween.tween_property(block, "rotation_degrees", 3.0, 0.15)
		
		# Tăng shadow
		var style = block.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			style.shadow_size = 8
			style.shadow_offset = Vector2(0, 6)
	else:
		# Khi thả: về bình thường
		tween.tween_property(block, "scale", Vector2(1.0, 1.0), 0.18)
		tween.tween_property(block, "rotation_degrees", 0.0, 0.18)
		
		var style = block.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			style.shadow_size = 4
			style.shadow_offset = Vector2(0, 4)

func _create_trash_zone():
	trash_panel = Panel.new()
	trash_panel.name = "TrashZone"
	trash_panel.visible = false
	var tsb = StyleBoxFlat.new()
	tsb.bg_color = Color(0.8, 0.2, 0.1, 0.4)
	tsb.border_width_left = 2
	tsb.border_width_top = 2
	tsb.border_width_right = 2
	tsb.border_width_bottom = 2
	tsb.border_color = Color(1, 0, 0, 0.8)
	trash_panel.add_theme_stylebox_override("panel", tsb)
	trash_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var label = Label.new()
	label.text = "DROP HERE TO DELETE"
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 14)
	trash_panel.add_child(label)
	
	toolbox.add_child(trash_panel)




var snap_preview: Panel = null
#func _check_snapping(moving_block: Panel):
	#if not is_instance_valid(moving_block): return
	#if trash_panel: trash_panel.visible = false
	#
	## Xóa preview cũ
	#if is_instance_valid(snap_preview):
		#snap_preview.queue_free()
		#snap_preview = null
#
	#var mpos = get_global_mouse_position()
	#
	## 1. DELETE
	#if is_instance_valid(toolbox) and toolbox.get_global_rect().has_point(mpos):
		#moving_block.queue_free()
		#_log("Block deleted", "warning")
		#return
#
	## 2. Preparation
	#var old_pos = moving_block.global_position
	#if moving_block.get_parent() != workspace:
		#moving_block.get_parent().remove_child(moving_block)
		#workspace.add_child(moving_block)
		#moving_block.global_position = old_pos
#
	## 3. TÌM BEST PARENT ĐỂ SNAP
	#var best_parent = null
	#var min_dist = 40.0
	#var best_snap_pos = Vector2.ZERO
	#
	#var all_blocks = _get_all_blocks(workspace)
	#for other in all_blocks:
		#if not is_instance_valid(other): continue
		#if other == moving_block: continue
		#if other.is_ancestor_of(moving_block): continue
		#
		#var other_bottom_global = other.global_position + Vector2(0, other.size.y)
		#var d = moving_block.global_position.distance_to(other_bottom_global)
		#var dx = abs(moving_block.global_position.x - other.global_position.x)
		#
		#if d < min_dist and dx < 50:
			#min_dist = d
			#best_parent = other
			#best_snap_pos = other_bottom_global
#
	## === GHOST PREVIEW (chỉ thêm phần này) ===
	#if best_parent:
		#snap_preview = Panel.new()
		#snap_preview.custom_minimum_size = moving_block.custom_minimum_size
		#snap_preview.modulate = Color(1, 1, 1, 0.3)   # Độ trong của ghost
		#snap_preview.position = best_snap_pos
		#workspace.add_child(snap_preview)
		#
		#var style = moving_block.get_theme_stylebox("panel").duplicate()
		#if style is StyleBoxFlat:
			#style.shadow_size = 0
			#style.bg_color.a = 0.25
		#snap_preview.add_theme_stylebox_override("panel", style)
#
#
	#if best_parent and is_instance_valid(best_parent):
		## Target = ngay bên dưới best_parent, cùng X
		#print("best_parent.position: ", best_parent.position)
		#print("best_parent.custom_minimum_size: ", best_parent.custom_minimum_size)
		#print("moving_block.custom_minimum_size: ", moving_block.custom_minimum_size)
		#var target_pos = best_parent.position + Vector2(0, best_parent.custom_minimum_size.y)
		#print("target_pos: ", target_pos)
		#
		#moving_block.z_index = best_parent.z_index + 1
		#moving_block.position = target_pos + Vector2(0, -20)
		#
		#var tween = create_tween()
		#tween.set_ease(Tween.EASE_OUT)
		#tween.set_trans(Tween.TRANS_ELASTIC)
		#tween.tween_property(moving_block, "position", target_pos, 0.4)
		#
		#_play_snap_sound()
		#_log("Snapped to stack", "success")
#

func _check_snapping(moving_block: Panel):
	if not is_instance_valid(moving_block): return
	if trash_panel: trash_panel.visible = false
	
	if is_instance_valid(snap_preview):
		snap_preview.queue_free()
		snap_preview = null

	var mpos = get_global_mouse_position()
	
	# 1. DELETE
	if is_instance_valid(toolbox) and toolbox.get_global_rect().has_point(mpos):
		moving_block.queue_free()
		_log("Block deleted", "warning")
		return

	# 2. Preparation
	var old_pos = moving_block.global_position
	if moving_block.get_parent() != workspace:
		moving_block.get_parent().remove_child(moving_block)
		workspace.add_child(moving_block)
		moving_block.global_position = old_pos

	# 3. Tìm best parent để snap
	var best_parent = null
	var min_dist = 40.0
	var best_snap_pos = Vector2.ZERO

	var all_blocks = _get_all_blocks(workspace)
	for other in all_blocks:
		if not is_instance_valid(other): continue
		if other == moving_block: continue
		if other.is_ancestor_of(moving_block): continue

		var other_bottom = other.position + Vector2(0, other.custom_minimum_size.y)
		var d = moving_block.position.distance_to(other_bottom)
		var dx = abs(moving_block.position.x - other.position.x)

		if d >= min_dist or dx >= 50:
			continue

		# ✅ Check slot occupied — dùng .position (local) nhất quán
		var slot_occupied = false
		for another in all_blocks:
			if not is_instance_valid(another): continue
			if another == moving_block: continue
			if another == other: continue
			var dy_check = abs(another.position.y - other_bottom.y)
			var dx_check = abs(another.position.x - other.position.x)
			if dy_check < 15.0 and dx_check < 30.0:
				slot_occupied = true
				break  # ← break khỏi for another

		if slot_occupied:
			continue  # ← ✅ continue for other, bỏ qua slot này

		min_dist = d
		best_parent = other
		best_snap_pos = other_bottom

	# Ghost preview
	if best_parent:
		snap_preview = Panel.new()
		snap_preview.custom_minimum_size = moving_block.custom_minimum_size
		snap_preview.modulate = Color(1, 1, 1, 0.3)
		snap_preview.position = best_snap_pos
		workspace.add_child(snap_preview)
		var style = moving_block.get_theme_stylebox("panel").duplicate()
		if style is StyleBoxFlat:
			style.shadow_size = 0
			style.bg_color.a = 0.25
		snap_preview.add_theme_stylebox_override("panel", style)

	if best_parent and is_instance_valid(best_parent):
		var target_pos = best_parent.position + Vector2(0, best_parent.custom_minimum_size.y)
		moving_block.z_index = best_parent.z_index + 1
		moving_block.position = target_pos + Vector2(0, -20)

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(moving_block, "position", target_pos, 0.4)
		_play_snap_sound()
		_log("Snapped to stack", "success")

# Helper to find all blocks regardless of nesting
func _get_all_blocks(parent_node) -> Array:
	var list = []
	if not is_instance_valid(parent_node): return list
	for child in parent_node.get_children():
		if is_instance_valid(child):
			if "block_type" in child:
				list.append(child)
			list.append_array(_get_all_blocks(child))
	return list

# ──────────────────────────── UI BUILD ────────────────────────────
#func _build_comp_list():
	#comp_list.clear()
	#for cat in CATEGORIES:
		#var ci = comp_list.add_item("▸ " + cat)
		#comp_list.set_item_selectable(ci, false)
		#comp_list.set_item_custom_fg_color(ci, Color(0.5, 0.5, 0.5))
		#for cid in CATEGORIES[cat]:
			#if COMPONENTS.has(cid):
				#var ii = comp_list.add_item("   " + cid)
				#comp_list.set_item_metadata(ii, cid)
				#var c = COMPONENTS[cid]
				#match c.type:
					#"Motor": comp_list.set_item_custom_fg_color(ii, Color(0.9, 0.4, 0.4))
					#"Battery": comp_list.set_item_custom_fg_color(ii, Color(0.9, 0.8, 0.2))
					#"Frame": comp_list.set_item_custom_fg_color(ii, Color(0.7, 0.7, 0.7))
					#_: comp_list.set_item_custom_fg_color(ii, Color(0.6, 0.7, 0.8))

func _build_floor():
	var m = MeshInstance3D.new()
	var p = PlaneMesh.new()
	p.size = Vector2(100, 100)
	m.mesh = p
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.14, 0.16) # Darker, more neutral
	mat.metallic = 0.0
	mat.roughness = 1.0 # Pure matte
	mat.specular = 0.0 # No reflections
	m.material_override = mat
	scene_root.add_child(m)

func _build_grid():
	# Professional subtle grid on the floor
	var grid_size := 50
	var grid_mat = StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.25, 0.25, 0.28, 0.3)
	grid_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	grid_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED

	var span = float(grid_size * 2)
	for i in range(-grid_size, grid_size + 1):
		# Standard grid line
		var thickness = 0.015
		var color = grid_mat.albedo_color
		
		# Axis coloring
		if i == 0:
			thickness = 0.04
		
		# Draw X lines
		var lx = MeshInstance3D.new()
		var bx = BoxMesh.new()
		bx.size = Vector3(span, 0.001, thickness)
		lx.mesh = bx
		var lm = grid_mat.duplicate()
		if i == 0: lm.albedo_color = Color(0.8, 0.2, 0.2, 0.6) # Red X axis
		lx.material_override = lm
		lx.position = Vector3(0, 0.005, float(i))
		scene_root.add_child(lx)

		# Draw Z lines
		var lz = MeshInstance3D.new()
		var bz = BoxMesh.new()
		bz.size = Vector3(thickness, 0.001, span)
		lz.mesh = bz
		var lzm = grid_mat.duplicate()
		if i == 0: lzm.albedo_color = Color(0.2, 0.6, 0.8, 0.6) # Blue/Cyan Z axis
		lz.material_override = lzm
		lz.position = Vector3(float(i), 0.005, 0)
		scene_root.add_child(lz)

# ──────────────────────────── INPUT ───────────────────────────────
func _input(event):
	if $Root/TutorialOverlay.visible:
		return
	# CRITICAL: Ignore 3D interactions if we are not ở Canvas tab hoặc đang simulation
	if tabs.current_tab != 0:
		orbiting = false
		panning = false
		return

	# Nếu đang simulation thì chỉ cho phép điều khiển camera (orbit, pan, zoom), KHÔNG cho phép chọn, thêm, xóa, di chuyển, wiring
	var sim_locked = sim_state == "playing"

	if event is InputEventMouseButton:
		var in_canvas = vpc.get_global_rect().has_point(get_global_mouse_position())

		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					if not sim_locked:
						if ghost:
							if in_canvas:
								var snap = _find_snap()
								if snap:
									_place(cur_id, snap.pos, snap.port, snap.parent_uid)
									_re_place_ghost_children(snap.parent_uid)
									_cancel_ghost()
								else:
									var mpos = viewport.get_mouse_position()
									var ro = camera.project_ray_origin(mpos)
									var rd = camera.project_ray_normal(mpos)
									var gp = Plane(Vector3.UP, 0)
									var ghit = gp.intersects_ray(ro, rd)
									if ghit:
										#_place(cur_id, ghit + Vector3(0, 0.3, 0))
										var offset_y = COMPONENTS[cur_id].get("ground_offset", 0.3)
										_place(cur_id, ghit + Vector3(0, offset_y, 0))
										_re_place_ghost_children(-1)
										_cancel_ghost()
						elif in_canvas:
							# Try to pick up existing component
							_pick_existing()
							if not ghost: # If nothing picked, start orbiting
								orbiting = true
					else:
						# Khi đang simulation, chỉ cho phép orbit camera
						if in_canvas:
							orbiting = true
				else:
					orbiting = false
					panning = false
			MOUSE_BUTTON_RIGHT:
				if in_canvas:
					panning = event.pressed
				else:
					panning = false
			MOUSE_BUTTON_MIDDLE:
				if in_canvas:
					panning = event.pressed
				else:
					panning = false
			MOUSE_BUTTON_WHEEL_UP:
				if tabs.current_tab == 0 and in_canvas:
					zoom = max(1.0, zoom - 1.5)
			MOUSE_BUTTON_WHEEL_DOWN:
				if tabs.current_tab == 0 and in_canvas:
					zoom = min(60.0, zoom + 1.5)

	if event is InputEventMouseMotion:
		if orbiting:
			camera_rot.y -= event.relative.x * 0.005
			camera_rot.x = clamp(camera_rot.x - event.relative.y * 0.005, -PI/2.1, PI/2.1)
		elif panning:
			var pan_speed = zoom * 0.001
			var cam_basis = camera.global_transform.basis
			pivot.global_position -= cam_basis.x * event.relative.x * pan_speed
			pivot.global_position += cam_basis.y * event.relative.y * pan_speed

	if event is InputEventKey and event.pressed:
		if not sim_locked:
			if event.keycode == KEY_R and ghost:
				ghost_rot += PI / 2
			if event.keycode == KEY_ESCAPE:
				if wiring_drag_active:  # ← THÊM
					_cancel_wire_drag() # ← THÊM
			if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
				_remove_selected()

func _process(_delta):
	# WASD Movement support
	var move_vec = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): move_vec += -camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S): move_vec += camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_A): move_vec += -camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D): move_vec += camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_Q): move_vec += Vector3.DOWN
	if Input.is_key_pressed(KEY_E): move_vec += Vector3.UP
	
	if move_vec.length() > 0:
		var speed = zoom * 0.8
		if Input.is_key_pressed(KEY_SHIFT): speed *= 3.0
		pivot.global_position += move_vec.normalized() * _delta * speed

	# Update camera transform based on rot/zoom
	#if tabs.current_tab == 0:
		#pivot.rotation.y = camera_rot.y
		#pivot.rotation.x = camera_rot.x
		#camera.position.z = zoom
		#camera.position.y = 0 # Camera is child of pivot, pivot handles X/Y rotation
	# Thay phần update camera trong _process:
	if tabs.current_tab == 0:
		pivot.rotation = Vector3.ZERO
		pivot.rotate(Vector3.UP, camera_rot.y)        # Yaw trước (world UP)
		pivot.rotate(pivot.global_transform.basis.x.normalized(), camera_rot.x)  # Pitch sau (local X)
		camera.position = Vector3(0, 0, zoom)
		camera.position.y = 0

	if is_instance_valid(ghost):
		_move_ghost()
	if sim_state == "playing":
		_simulate(_delta)
	_update_block_snap_preview()
# WIRING TYPING SHIT
	if wiring_mode and wiring_drag_active and is_instance_valid(wire_drag_mesh):
		var mpos = viewport.get_mouse_position()
		var ro = camera.project_ray_origin(mpos)
		var rd = camera.project_ray_normal(mpos)
		var plane = Plane(Vector3.UP, wiring_drag_from.port_pos.y)
		var hit = plane.intersects_ray(ro, rd)

		if hit:
			_clear_children(wire_drag_mesh)
			var to_pos = hit
			var hover = _raycast_port()
			var wire_color = Color(0.8, 0.8, 0.1)
			if hover and hover.uid != wiring_drag_from.uid:
				if hover.port_type == wiring_drag_from.port_type:
					wire_color = Color(0.1, 0.9, 0.3)
					to_pos = hover.port_pos
				else:
					wire_color = Color(0.9, 0.1, 0.1)
			_draw_bezier_wire(wire_drag_mesh, wiring_drag_from.port_pos, to_pos, wire_color)

#ENDING OF WIRING TYPING SHIT

func _update_block_snap_preview():
# Tìm block đang drag bằng cách scan tất cả blocks
	var dragging_block = null
	var all = _get_all_blocks(workspace)
	for b in all:
		if is_instance_valid(b) and "dragging" in b and b.dragging == true:
			dragging_block = b
			break
	
	if dragging_block == null:
		_clear_preview()
		snap_preview = null
		return
	
	# Tìm best snap position
	var best_snap_pos = Vector2.ZERO
	var best_parent = null
	var min_dist = 40.0

	var all_blocks = _get_all_blocks(workspace)
	for other in all_blocks:
		if not is_instance_valid(other): continue
		if other == dragging_block: continue
		if other.is_ancestor_of(dragging_block): continue
		var other_bottom = other.global_position + Vector2(0, other.size.y)
		var d = dragging_block.global_position.distance_to(other_bottom)
		var dx = abs(dragging_block.global_position.x - other.global_position.x)

		if d < min_dist and dx < 50:
			min_dist = d
			best_parent = other
			best_snap_pos = other_bottom

	# Xóa preview cũ trước khi tạo mới
	_clear_preview()

	if best_parent:
		snap_preview = Panel.new()
		snap_preview.custom_minimum_size = dragging_block.custom_minimum_size
		snap_preview.modulate = Color(1, 1, 1, 0.35)
		# Dùng global_position thay vì position để chính xác hơn
		snap_preview.set_position(best_snap_pos - workspace.global_position)
		workspace.add_child(snap_preview)

		var style = dragging_block.get_theme_stylebox("panel").duplicate()
		if style != null:
			var style_copy = style.duplicate()
			if style_copy is StyleBoxFlat:
				style_copy.shadow_size = 0
				style_copy.bg_color.a = 0.25
			snap_preview.add_theme_stylebox_override("panel", style_copy)


func _clear_preview():
	if is_instance_valid(snap_preview):
		snap_preview.queue_free()
		snap_preview = null




# ──────────────────────────── GHOST / PLACEMENT ───────────────────
#func _on_item_selected(idx: int):
	#var id = comp_list.get_item_metadata(idx)
	#if id == null:
		#return
	#if id == "PVC Pipe Frame" or id == "Carbon Fiber Body":
		#for c in placed:
			#if c.type == "Frame":
				#_log("Only one frame allowed!", "error")
				#return
	#cur_id = id
	#_cancel_ghost()
	#ghost = _build_mesh(id, true)
	#components_group.add_child(ghost)
	#_show_snap_hints(id)
	#
	## Deselect so it can be clicked again
	#comp_list.deselect_all()
func _on_item_selected(idx: int):
	var meta = comp_list.get_item_metadata(idx)
	if meta == null:
		return
	
	# Click vào category header → toggle collapse
	if meta.get("is_category", false):
		var cat = meta["cat"]
		_cat_collapsed[cat] = not _cat_collapsed.get(cat, false)
		_build_comp_list()  # rebuild list
		comp_list.deselect_all()
		return
	
	# Click vào component → xử lý như cũ
	var id = meta.get("id", "")
	if id == "":
		return
	if id == "PVC Pipe Frame" or id == "Carbon Fiber Body":
		for c in placed:
			if c.type == "Frame":
				_log("Only one frame allowed!", "error")
				return
	cur_id = id
	_cancel_ghost()
	ghost = _build_mesh(id, true)
	components_group.add_child(ghost)
	_show_snap_hints(id)
	comp_list.deselect_all()

func _move_ghost():
	var mpos = viewport.get_mouse_position()
	var ro = camera.project_ray_origin(mpos)
	var rd = camera.project_ray_normal(mpos)

	var snap = _find_snap()
	if snap:
		ghost.global_position = snap.pos
		_ghost_tint(Color(0, 1, 0.5, 0.6))
	else:
		# Follow cursor on ground plane
		var plane = Plane(Vector3.UP, 0)
		var hit = plane.intersects_ray(ro, rd)
		if hit == null:
			return
		ghost.global_position = hit + Vector3(0, 0.5, 0)
		_ghost_tint(Color(1, 1, 1, 0.25))
	ghost.rotation.y = ghost_rot

func _find_snap() -> Variant:
	var mpos = viewport.get_mouse_position()
	var ro = camera.project_ray_origin(mpos)
	var rd = camera.project_ray_normal(mpos)
	# Cast ray against MULTIPLE planes at different heights to find snap points
	var best_d := 2.5  # Generous snap distance
	var best = null

	for hint in snap_hints.get_children():
		if not is_instance_valid(hint): continue
		# Cast ray on a plane at the SAME Y height as this hint
		var hint_y = hint.global_position.y
		var h_plane = Plane(Vector3.UP, hint_y)
		var hit = h_plane.intersects_ray(ro, rd)
		if hit == null:
			continue
		# Compare XZ distance only (ignore Y — we snap to the hint's exact Y)
		var dx = hit.x - hint.global_position.x
		var dz = hit.z - hint.global_position.z
		var d = sqrt(dx * dx + dz * dz)
		if d < best_d:
			best_d = d
			best = {
				"pos": hint.global_position, 
				"port": hint.name,
				"parent_uid": hint.get_meta("parent_uid", -1)
			}
	return best

func _show_snap_hints(id: String):
	_clear_children(snap_hints)
	var cdata = COMPONENTS[id]
	# Scan ALL placed components for matching ports
	for comp in placed:
		if not is_instance_valid(comp.get("node")): continue
		var ports = COMPONENTS[comp.id].get("ports", [])
		for port in ports:
			if port.get("slot", false) and port.get("allowed", []).has(cdata.type):
				# Check port not already occupied
				var occupied := false
				for other in placed:
					if other.get("port_name", "") == port.name and other.get("parent_id", -1) == comp.uid:
						occupied = true
						break
				if occupied:
					continue

				var hint = MeshInstance3D.new()
				var torus = TorusMesh.new()
				torus.inner_radius = 0.15
				torus.outer_radius = 0.25
				hint.mesh = torus
				hint.name = port.name
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0, 1, 0.8, 0.7)
				mat.emission_enabled = true
				mat.emission = Color(0, 1, 0.8)
				mat.emission_energy_multiplier = 2.0
				mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
				hint.material_override = mat
				snap_hints.add_child(hint)
				hint.global_position = comp.node.global_transform * port.pos
				hint.set_meta("parent_uid", comp.uid)

func _cancel_ghost():
	if ghost:
		ghost.queue_free()
		ghost = null
	_clear_children(snap_hints)
	ghost_rot = 0.0

func _ghost_tint(c: Color):
	if not ghost:
		return
	for ch in ghost.get_children():
		if not is_instance_valid(ch): continue
		if ch is MeshInstance3D and ch.material_override:
			ch.material_override.albedo_color = c
		# Handle nested children from OBJ imports
		for sub in ch.get_children():
			if is_instance_valid(sub) and sub is MeshInstance3D and sub.material_override:
				sub.material_override.albedo_color = c

# ──────────────────────────── PLACE & WIRE ────────────────────────
var drone_root: Node3D = null

func _place(id: String, pos: Vector3, port_name: String = "", parent_uid: int = -1):
	var node = _build_mesh(id, false)
	#node.global_position = pos
	
	var uid = Time.get_ticks_msec() # Unique ID
	var cdata = COMPONENTS[id]
	var entry := {
		"uid": uid, "id": id, "type": cdata.type,
		"node": node, "port_name": port_name,
		"parent_id": parent_uid,
	}

	# Link hierarchy
	if parent_uid != -1:
		for p in placed:
			if p.uid == parent_uid:
				p.node.add_child(node)
				node.position = p.node.global_transform.affine_inverse() * pos
				break
	else:
		#components_group.add_child(node)
		#node.global_position = pos
			   # Nếu là frame thì gắn vào drone_root
		if cdata.type == "Frame":
			if drone_root == null:
				drone_root = Node3D.new()
				drone_root.name = "DroneRoot"
				components_group.add_child(drone_root)
				wires_group.get_parent().remove_child(wires_group)
				drone_root.add_child(wires_group)
			drone_root.add_child(node)
			node.global_position = pos
		else:
			# Component rời — gắn thẳng vào components_group
			components_group.add_child(node)
			node.global_position = pos

	placed.append(entry)
	_rebuild_wires()
	_update_all()
	_log("Assembled: " + id, "success")


var _ghost_children: Array[Dictionary] = [] 


func _rebuild_wires():
	if sim_state == "playing":
		return # Block wiring changes during simulation
	_clear_children(wires_group)
	# Find frame center for wiring hub
	var center = Vector3.ZERO
	var frame_node = null
	for f in placed:
		if is_instance_valid(f.get("node")) and f.type == "Frame":
			frame_node = f.node
			center = f.node.global_position + Vector3(0, 1.2, 0)
			break
	if not is_instance_valid(frame_node): return
	# Draw wires from each motor to the center hub
	for c in placed:
		if is_instance_valid(c.get("node")) and c.type == "Motor" and c.get("port_name", "") != "":
			_add_wire(c.node.global_position, center)

func _add_wire(from: Vector3, to: Vector3):
	if sim_state == "playing":
		return # Block adding wires during simulation
	var dist = from.distance_to(to)
	if dist < 0.1:
		return
	# Build a curved wire using multiple segments
	var wire_root = Node3D.new()
	var segments = 8
	var sag = max(0.1, dist * 0.15)
	var mid = (from + to) / 2.0
	mid.y -= sag
	# Simple 3-point curve
	for i in range(segments):
		var t0 = float(i) / segments
		var t1 = float(i + 1) / segments
		var p0 = _bezier3(from, mid, to, t0)
		var p1 = _bezier3(from, mid, to, t1)
		var seg_dist = p0.distance_to(p1)
		var cyl = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.03
		cm.height = seg_dist
		cyl.mesh = cm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.1, 0.1)
		mat.metallic = 0.3
		cyl.material_override = mat
		wire_root.add_child(cyl)
		cyl.look_at_from_position((p0 + p1) / 2.0, p1, Vector3.UP)
		cyl.rotate_object_local(Vector3.RIGHT, PI / 2)
	wires_group.add_child(wire_root)

func _bezier3(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var ab = a.lerp(b, t)
	var bc = b.lerp(c, t)
	return ab.lerp(bc, t)

# ──────────────────────────── BUILD MESH ──────────────────────────
func _build_mesh(id: String, is_ghost: bool) -> Node3D:
	var cdata = COMPONENTS[id]
	var root = Node3D.new()

	# Check if this component uses an OBJ model file
	if cdata.get("use_obj", false):
		_build_frame_from_obj(root, cdata)
	else:
		match cdata.type:
			"Frame":
				_build_frame_procedural(root)
			"Motor":
				_build_motor(root)
			"Propeller":
				_build_propeller(root)
			"Battery":
				_build_battery(root)
			"FC":
				_build_fc(root)
			"ESC":
				_build_esc(root)
			_:
				var m = MeshInstance3D.new()
				m.mesh = BoxMesh.new()
				root.add_child(m)

	var mat = StandardMaterial3D.new()
	if is_ghost:
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0, 1, 0.8, 0.3)
	else:
		var raw_c = cdata.color
		# Make it pop even more
		mat.albedo_color = Color(min(raw_c.r * 1.3, 1.0), min(raw_c.g * 1.3, 1.0), min(raw_c.b * 1.3, 1.0))
		mat.metallic = 0.0 # No reflections to avoid black artifacts
		mat.roughness = 0.5 # Balanced matte
		mat.specular = 0.3

	_apply_material_recursive(root, mat)
	return root

func _apply_material_recursive(node: Node, mat: Material):
	for ch in node.get_children():
		if ch is MeshInstance3D:
			ch.material_override = mat
		if ch.get_child_count() > 0:
			_apply_material_recursive(ch, mat)

func _build_frame_from_obj(root: Node3D, cdata: Dictionary):
	# Load the real OBJ model
	var obj_path = cdata.get("obj_path", "")
	var mesh_res = load(obj_path)
	if mesh_res == null:
		_log("Failed to load OBJ: " + obj_path + ", using procedural frame", "warning")
		_build_frame_procedural(root)
		return

	var mi = MeshInstance3D.new()
	mi.mesh = mesh_res
	mi.scale = Vector3(OBJ_SCALE, OBJ_SCALE, OBJ_SCALE) 
	root.add_child(mi)

	_log("Loaded PVC Pipe Frame from OBJ model", "info")

func _build_frame_procedural(root: Node3D):
	var arm_mat = StandardMaterial3D.new()
	arm_mat.albedo_color = Color(0.18, 0.18, 0.18)
	arm_mat.metallic = 0.3
	arm_mat.roughness = 0.5

	# 4 diagonal arms
	for i in range(4):
		var arm = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(4.5, 0.4, 0.4) 
		arm.mesh = bm
		arm.material_override = arm_mat
		root.add_child(arm)
		var angle = PI / 4.0 + i * PI / 2.0
		arm.rotation.y = angle
		arm.position = Vector3(cos(angle) * 2, 0.75, -sin(angle) * 2)

		# Motor mount at tip
		var mount = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.45
		cm.bottom_radius = 0.45
		cm.height = 0.2
		mount.mesh = cm
		mount.material_override = arm_mat
		root.add_child(mount)
		mount.position = Vector3(cos(angle) * 4, 0.85, -sin(angle) * 4)

	# Top plate (main chassis)
	var top = MeshInstance3D.new()
	top.mesh = BoxMesh.new()
	top.mesh.size = Vector3(2.6, 0.15, 5.0) 
	top.position.y = 1.0
	root.add_child(top)

	# Bottom plate
	var bot = MeshInstance3D.new()
	bot.mesh = BoxMesh.new()
	bot.mesh.size = Vector3(2.3, 0.15, 4.5)
	bot.position.y = 0.5
	root.add_child(bot)

	# Landing skids
	for side in [-1.0, 1.0]:
		var runner = MeshInstance3D.new()
		var rcyl = CylinderMesh.new()
		rcyl.top_radius = 0.06
		rcyl.bottom_radius = 0.06
		rcyl.height = 3.5
		runner.mesh = rcyl
		runner.rotation.x = PI / 2
		runner.position = Vector3(side * 1.3, -0.5, 0)
		root.add_child(runner)

	# Status LEDs
	var led_r = MeshInstance3D.new()
	led_r.mesh = BoxMesh.new()
	led_r.mesh.size = Vector3(0.1, 0.05, 0.1)
	var led_mat_r = StandardMaterial3D.new()
	led_mat_r.albedo_color = Color(0.2, 0, 0)
	led_mat_r.emission_enabled = true
	led_mat_r.emission = Color.RED
	led_mat_r.emission_energy_multiplier = 3.0
	led_r.material_override = led_mat_r
	led_r.position = Vector3(0.8, 1.06, 2.0)
	root.add_child(led_r)

	var led_g = MeshInstance3D.new()
	led_g.mesh = BoxMesh.new()
	led_g.mesh.size = Vector3(0.1, 0.05, 0.1)
	var led_mat_g = StandardMaterial3D.new()
	led_mat_g.albedo_color = Color(0, 0.2, 0)
	led_mat_g.emission_enabled = true
	led_mat_g.emission = Color.GREEN
	led_mat_g.emission_energy_multiplier = 3.0
	led_g.material_override = led_mat_g
	led_g.position = Vector3(-0.8, 1.06, 2.0)
	root.add_child(led_g)

	root.position.y = 0.7

func _build_motor(root: Node3D):
	# Stator
	var st = MeshInstance3D.new()
	st.mesh = CylinderMesh.new()
	st.mesh.top_radius = 0.4
	st.mesh.bottom_radius = 0.4
	st.mesh.height = 0.5
	root.add_child(st)
	# Bell/Rotor
	var bell = MeshInstance3D.new()
	bell.mesh = CylinderMesh.new()
	bell.mesh.top_radius = 0.45
	bell.mesh.bottom_radius = 0.45
	bell.mesh.height = 0.2
	bell.position.y = 0.25
	root.add_child(bell)
	# Shaft
	var shaft = MeshInstance3D.new()
	shaft.mesh = CylinderMesh.new()
	shaft.mesh.top_radius = 0.1
	shaft.mesh.bottom_radius = 0.1
	shaft.mesh.height = 0.3
	shaft.position.y = 0.5
	root.add_child(shaft)

func _build_propeller(root: Node3D):
	var blade = MeshInstance3D.new()
	blade.mesh = BoxMesh.new()
	blade.mesh.size = Vector3(4.5, 0.04, 0.25)
	blade.name = "prop_blade"
	root.add_child(blade)
	var hub = MeshInstance3D.new()
	hub.mesh = CylinderMesh.new()
	hub.mesh.top_radius = 0.12
	hub.mesh.bottom_radius = 0.12
	hub.mesh.height = 0.08
	root.add_child(hub)

func _build_battery(root: Node3D):
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	# Resized to be more realistic (smaller relative to the frame)
	body.mesh.size = Vector3(1.2, 0.6, 2.8)
	root.add_child(body)

func _build_fc(root: Node3D):
	var pcb = MeshInstance3D.new()
	pcb.mesh = BoxMesh.new()
	pcb.mesh.size = Vector3(1.5, 0.08, 1.5)
	root.add_child(pcb)

func _build_esc(root: Node3D):
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(1.0, 0.25, 1.8)
	root.add_child(body)

# ──────────────────────────── SIMULATION ──────────────────────────
func _on_play():
	# Kiem tra ket noi day trc khi play
	if is_instance_valid(wiring_panel) and wiring_panel.has_method("is_wiring_complete"):
		var wiring_check = wiring_panel.is_wiring_complete()
		if not wiring_check.ok:
			_log("SYSTEM ERROR: " + wiring_check.reason, "error")
			sim_label.text = "ERROR"
			topbar_status.text = "error"
			tabs.current_tab = 2
			return
		# Check motor type trước
	var motor_types := []
	for c in placed:
		if c.type == "Motor" and not motor_types.has(c.id):
			motor_types.append(c.id)
	
	if motor_types.size() > 1:
		_log("SYSTEM ERROR: Mixed motor types — all motors must be identical", "error")
		sim_label.text = "ERROR"
		topbar_status.text = "error"
		return
	var check = _preflight_check()
	# Only block play if basic structure is missing
	
	if check.reason == "No frame" or check.reason == "No battery":
		_log("SYSTEM ERROR: " + check.reason, "error")
		sim_label.text = "ERROR"
		return
	_cancel_ghost()
	# Start simulation state
	sim_state = "playing"
	sim_time = 0.0
	sim_step_idx = 0
	sim_step_timer = 0.0
	sim_target_pos = Vector3.ZERO # Start at floor
	sim_label.text = "Idle/Armed"
	topbar_status.text = "playing"
	
	# Find the 'start' block and build the sequence
	sim_sequence = []
	var start_block = null
	for child in workspace.get_children():
		if is_instance_valid(child) and "block_type" in child and child.block_type == "start":
			start_block = child
			break
	
	if start_block:
		_parse_block_stack(start_block)
	
	if sim_sequence.size() == 0:
		_log("No sequence to execute. Connect blocks to 'When flag clicked'!", "warning")
		return

	_log("Executing Flight Plan: " + str(sim_sequence.size()) + " steps", "info")
	
	sim_state = "playing"
	sim_time = 0.0
	sim_step_idx = 0
	sim_step_timer = 0.0
	sim_target_pos = Vector3.ZERO
	sim_target_rot = Vector3.ZERO
	sim_label.text = "Flying..."
	topbar_status.text = "playing"
	
	# ── PhysicsBridge: Configure and arm ──
	if _bridge_active():
		var tw := 0.0
		var tt := 0.0
		var motor_with_prop_count := 0
		
		# Identify all propellers and find their parent motor IDs
		var prop_parents = []
		for c in placed:
			if c.type == "Propeller":
				prop_parents.append(c.parent_id)
		
		for c in placed:
			var d = COMPONENTS[c.id]
			tw += d.weight
			tt += d.thrust
			if d.type == "Motor":
				if c.uid in prop_parents:
					motor_with_prop_count += 1
		
		# Update UI state to "Locked"
		comp_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hier_tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hier_del_btn.disabled = true
		for btn in toolbox_v.get_children():
			if btn is Button: btn.disabled = true
		
		bridge.cmd_set_drone(tw / 1000.0, motor_with_prop_count, tt / 1000.0 * 9.81)
		bridge.cmd_arm()
		_log("Bridge: Drone configured (%.0fg, %d functional motors) & armed" % [tw, motor_with_prop_count], "info")


func _parse_block_stack(block):
	if not is_instance_valid(block): return
	
	# Tìm block nào đang nằm ngay bên dưới block này (theo position)
	var next_block = _find_block_below(block)
	if next_block == null: return
	
	var val = 0.0
	var input_node = next_block.get_node_or_null("input_bg/Input")
	if is_instance_valid(input_node) and input_node is LineEdit:
		val = input_node.text.to_float()
		if val <= 0.0: val = 50.0
	
	var duration = max(1.0, (val * 0.05) / 2.0)
	sim_sequence.append({
		"type": next_block.block_type,
		"value": val,
		"duration": duration})
	
	# Tiếp tục tìm block tiếp theo bên dưới
	_parse_block_stack(next_block)



func _find_block_below(block: Panel) -> Panel:
	if not is_instance_valid(block): return null
	var threshold = 20.0  # Pixel tolerance
	var expected_y = block.position.y + block.custom_minimum_size.y
	var best: Panel = null
	var best_dist = threshold 
	for child in workspace.get_children():
		if not is_instance_valid(child): continue
		if child == block: continue
		if not "block_type" in child: continue
		if child.block_type == "start": continue        
		var dy = abs(child.position.y - expected_y)
		var dx = abs(child.position.x - block.position.x)      
		if dy < best_dist and dx < 30.0:
			best_dist = dy
			best = child   
	return best

func _on_pause():
	if sim_state == "playing":
		sim_state = "paused"
		sim_label.text = "Paused"
		topbar_status.text = "paused"

func _on_stop():
	sim_state = "stopped"
	sim_label.text = "Ready"
	topbar_status.text = "stopped"
	# Reset positions
	if drone_root:
		drone_root.rotation = Vector3.ZERO
		drone_root.position = Vector3.ZERO
	sim_step_idx = 0
	# CRITICAL: Rebuild wires at home position to prevent "bulging"
	_rebuild_wires()
	# Stop bridge simulation
	if _bridge_active():
		bridge.cmd_stop()
		_log("Bridge: Simulation stopped & reset", "info")
	
	# Unlock UI
	#comp_list.enabled = true
	#hier_tree.enabled = true
	comp_list.mouse_filter = Control.MOUSE_FILTER_STOP
	hier_tree.mouse_filter = Control.MOUSE_FILTER_STOP

	hier_del_btn.disabled = false
	for btn in toolbox_v.get_children():
		if btn is Button: btn.disabled = false

func _simulate(delta: float):
	sim_time += delta
	var check = _preflight_check()

	# 1. Propeller Spin — use bridge RPMs if available
	if sim_state == "playing":
		var bridge_rpms = []
		if _bridge_active():
			bridge_rpms = bridge.get_motor_rpms()
		var prop_idx := 0
		for comp in placed:
			if is_instance_valid(comp.get("node")) and comp.type == "Propeller":
				for ch in comp.node.get_children():
					if is_instance_valid(ch) and ch.name == "prop_blade":
						var spin_speed := 35.0
						if prop_idx < bridge_rpms.size() and bridge_rpms[prop_idx] > 0:
							spin_speed = bridge_rpms[prop_idx] / 150.0  # Increased multiplier for realism
						ch.rotation.y += delta * spin_speed
						prop_idx += 1

	if check.capability == "Cannot fly" and not _bridge_active():
		components_group.position.y = lerp(components_group.position.y, 0.0, 0.08)
		return

	# ── BRIDGE PHYSICS MODE ──
	if _bridge_active() and use_bridge_physics:
		_simulate_bridge(delta)
		return

	# ── KINEMATIC FALLBACK MODE ──
	_simulate_kinematic(delta, check)

func _bridge_active() -> bool:
	"""Check if bridge is available and connected."""
	return bridge != null and bridge_connected and is_instance_valid(bridge)

func _simulate_bridge(delta: float):
	"""Simulation driven by real physics from bridge (Gazebo/standalone)."""
	# Step processing: send commands to bridge based on block sequence
	if sim_state == "playing" and sim_step_idx < sim_sequence.size():
		var step = sim_sequence[sim_step_idx]
		sim_step_timer += delta
		
		# Send bridge commands only when step starts or changes
		if sim_step_timer <= delta * 2:  # First frame of step
			match step.type:
				"take_off":
					bridge.cmd_takeoff(2.5)
					_log("Bridge → Takeoff to 2.5m", "info")
				"forward":
					var speed = step.value * 0.05 / step.duration
					var fwd = -components_group.global_transform.basis.z.normalized()
					fwd.y = 0; fwd = fwd.normalized()
					bridge.cmd_move(fwd.x * speed, 0.0, fwd.z * speed)
					_log("Bridge → Move forward %.1f cm (%.2f m/s)" % [step.value, speed], "info")
				"hover":
					bridge.cmd_hover()
					_log("Bridge → Hover", "info")
				"land":
					bridge.cmd_land()
					_log("Bridge → Land", "info")

		if sim_step_timer >= step.duration:
			sim_step_idx += 1
			sim_step_timer = 0.0
			if sim_step_idx < sim_sequence.size():
				_log("Step " + str(sim_step_idx + 1) + ": Executing " + sim_sequence[sim_step_idx].type, "info")
			else:
				bridge.cmd_hover()  # Hold position after program ends
				_log("Program finished — hovering", "success")
				sim_label.text = "Finished"

	# Position/rotation update happens in _on_bridge_state callback

func _on_bridge_state(state: Dictionary):
	"""Callback: apply physics state from bridge to the 3D drone visual."""
	if sim_state != "playing" and sim_state != "paused":
		return
	
	var pos_arr = state.get("pos", [0, 0, 0])
	var rot_arr = state.get("rot", [0, 0, 0, 1])
	
	# Apply position from physics engine
	var target_pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
	components_group.position = components_group.position.lerp(target_pos, 0.3)
	
	# Apply quaternion rotation from physics engine
	var quat = Quaternion(rot_arr[0], rot_arr[1], rot_arr[2], rot_arr[3])
	var target_euler = quat.get_euler()
	components_group.rotation = components_group.rotation.lerp(target_euler, 0.3)
	
	# Update status display
	var status_text = state.get("status", "unknown")
	if sim_state == "playing":
		sim_label.text = status_text.capitalize()

func _simulate_kinematic(delta: float, check: Dictionary):
	if drone_root == null: return
	"""Original kinematic simulation as fallback when bridge is not connected."""
	# 2. Logic Step Processing
	if sim_state == "playing" and sim_step_idx < sim_sequence.size():
		var step = sim_sequence[sim_step_idx]
		sim_step_timer += delta
		
		match step.type:
			"take_off":
				sim_target_pos.y = 2.5
			"forward":
				# REAL MOVEMENT: Calculate target based on horizontal plane only
				var target_dist = step.value * 0.05
				var forward_dir = -drone_root.global_transform.basis.z
				forward_dir.y = 0 # FORCED HORIZONTAL
				forward_dir = forward_dir.normalized()
				
				# Incremental movement to target
				sim_target_pos += forward_dir * target_dist * (delta / step.duration)
				# Lock Y to prevent altitude bleed during tilt
				if sim_target_pos.y < 2.0: sim_target_pos.y = 2.5
			"hover":
				# Just bob in place (handled by physics below)
				pass
			"land":
				sim_target_pos.y = 0.0
		
		if sim_step_timer >= step.duration:
			sim_step_idx += 1
			sim_step_timer = 0.0
			if sim_step_idx < sim_sequence.size():
				_log("Step " + str(sim_step_idx + 1) + ": Executing " + sim_sequence[sim_step_idx].type, "info")
			else:
				_log("Program finished", "success")
				sim_label.text = "Finished"

	# 3. Physics & Visuals
	var final_target = sim_target_pos
	if check.capability == "Cannot fly":
		final_target.y = 0.0
	
	drone_root.position = drone_root.position.lerp(final_target, 0.05)
	
	# DYNAMIC TILT: Drone must pitch DOWN to go forward
	var displacement = (sim_target_pos - drone_root.position)
	var dynamic_pitch = clamp(displacement.z * 0.3, -0.3, 0.3)
	var dynamic_roll = clamp(-displacement.x * 0.3, -0.3, 0.3)
	
	var tilt_x = check.tilt_x * 0.2 + dynamic_pitch + sin(sim_time*1.5)*0.01
	var tilt_z = check.tilt_z * 0.2 + dynamic_roll + cos(sim_time*1.5)*0.01
	
	drone_root.rotation.x = lerp(drone_root.rotation.x, tilt_x, 0.1)  # ← ĐỔI
	drone_root.rotation.z = lerp(drone_root.rotation.z, tilt_z, 0.1)


func _preflight_check() -> Dictionary:
	var motors_with_props = []
	var motors_total = 0
	var has_frame := false
	var has_battery := false

	for c in placed:
		var c_type = c["type"]
		if c_type == "Frame": has_frame = true
		elif c_type == "Battery": has_battery = true
		elif c_type == "Motor": 
			motors_total += 1
			# Check if has prop
			var has_p = false
			for p in placed:
				if p.parent_id == c.uid and p.type == "Propeller":
					has_p = true
					break
			if has_p:
				motors_with_props.append(c)

	if not has_frame:
		return {"capability": "Cannot fly", "reason": "No frame", "tilt_x": 0, "tilt_z": 0}
	if not has_battery:
		return {"capability": "Cannot fly", "reason": "No battery", "tilt_x": 0, "tilt_z": 0}
	if motors_with_props.size() == 0:
		return {"capability": "Cannot fly", "reason": "No motors with props", "tilt_x": 0, "tilt_z": 0}

	# Real Physics: Each motor provides lift at its position
	# Calculate total net force and torque
	var total_lift := motors_with_props.size()
	var torque_x := 0.0
	var torque_z := 0.0
	
	for m in motors_with_props:
		if is_instance_valid(m.node):
			# Use LOCAL position for torque calculation
			var lpos = m.node.position 
			torque_x += lpos.z * 0.5
			torque_z -= lpos.x * 0.5

	var tilt_x = torque_x / max(total_lift, 1)
	var tilt_z = torque_z / max(total_lift, 1)

	var cap = "Stable"
	if motors_with_props.size() < 4:
		cap = "Unstable"
		if motors_with_props.size() < 2:
			return {"capability": "Cannot fly", "reason": "Asymmetric lift", "tilt_x": tilt_x, "tilt_z": tilt_z}
	
	if abs(tilt_x) > 1.0 or abs(tilt_z) > 1.0:
		cap = "Unstable"

	return {"capability": cap, "reason": "", "tilt_x": tilt_x, "tilt_z": tilt_z}

# ──────────────────────────── UPDATE UI ───────────────────────────
func _update_all():
	var tw := 0.0
	var tt := 0.0
	var bat_cap := 0
	for c in placed:
		var d = COMPONENTS[c.id]
		tw += d.weight
		tt += d.thrust
		bat_cap += d.get("capacity", 0)

	weight_val.text = "%.1f g" % tw
	thrust_val.text = "%.2f kg" % (tt / 1000.0)
	var ratio = (tt / tw) if tw > 0 else 0.0
	twr_val.text = "%.2f:1" % ratio
	# Capability badge
	if ratio >= 2.0:
		cap_val.text = "Good"
		cap_val.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	elif ratio >= 1.5:
		cap_val.text = "Marginal"
		cap_val.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	else:
		cap_val.text = "N/A"
		cap_val.remove_theme_color_override("font_color")

	bat_val.text = str(bat_cap) + " mAh"
	var draw_a = tt * 0.001 * 30 # rough amps estimate
	var ft_min = (bat_cap / 1000.0 * 60.0 / max(draw_a, 1)) if bat_cap > 0 else 0
	ft_val.text = "%.1f min" % ft_min
	comp_count.text = "  Components: " + str(placed.size())
	# Diagnostics
	_update_diagnostics()
	# Hierarchy
	_build_hierarchy_tree()
	


func _on_hier_item_selected():
	var item = hier_tree.get_selected()
	if item:
		var uid = item.get_metadata(0)
		if uid != null:
			_highlight_component(uid)
			_log("Selected: " + item.get_text(0), "info")

func _highlight_component(uid: int):
	if uid == null or uid <= 0:
		_log("Highlight failed: UID invalid", "error")
		return
	
	_log("Trying to highlight UID: " + str(uid), "info")
	
	for c in placed:
		if c.uid == uid:
			if not is_instance_valid(c.node):
				_log("Highlight failed: Node is null", "error")
				return
			
			var node = c.node
			_log("Found component: " + c.id + " | Meshes found:", "info")
			
			var tween = create_tween()
			var mesh_count = 0
			
			for child in node.get_children():
				if child is MeshInstance3D:
					mesh_count += 1
					var mat = child.material_override
					if mat:
						var original_scale = child.scale  # ← lưu scale gốc
						_log("  → Animating mesh: " + child.name, "success")
						tween.tween_property(mat, "emission_enabled", true, 0)
						tween.tween_property(mat, "emission", Color(0, 0.8, 1), 0.2)
						tween.tween_property(mat, "emission_energy_multiplier", 10.0, 0.2)
						tween.tween_property(child, "scale", original_scale * 1.1, 0.2)  # ← nhân với gốc
						tween.tween_property(mat, "emission_energy_multiplier", 0.0, 0.4)
						tween.tween_property(child, "scale", original_scale, 0.4)  # ← về đúng gốc
						tween.tween_property(mat, "emission_enabled", false, 0)
			
			if mesh_count == 0:
				_log("No MeshInstance3D found at root level!", "warning")
			
			# Bỏ tween.finished vì tween đã tự reset về original_scale rồi
			
			return
	
	_log("Highlight failed: UID not found in placed", "error")

func _remove_selected():
	var item = hier_tree.get_selected()
	if item and item.get_parent(): # Don't delete root
		var uid = item.get_metadata(0)
		_remove_component(uid)


func _update_diagnostics():
	var issues := []
	var has_bat := false
	var has_frame := false
	var motor_count := 0
	var prop_count := 0
	var motor_types  : Array = []
	for c in placed:
		var c_type = c["type"]
		if c_type == "Battery": has_bat = true
		elif c_type == "Frame": has_frame = true
		elif c_type == "Motor": 
			motor_count += 1
			if not motor_types.has(c.id):
				motor_types.append(c.id)
		elif c_type == "Propeller": prop_count += 1

	if not has_frame:
		issues.append("[color=#f44336]No frame detetced[/color]")
	if not has_bat:
		issues.append("[color=#f44336]No battery placed[/color]")
	if motor_count == 0:
		issues.append("[color=#f44336]No motors installed[/color]")
	elif motor_count < 4:
		issues.append("[color=#ff9800]Only %d motors (4 recommended)[/color]" % motor_count)
	if prop_count < motor_count:
		issues.append("[color=#ff9800]%d motors missing propellers[/color]" % (motor_count - prop_count))
	if motor_count > 1 and motor_types.size() > 1:
		issues.append("[color=#f44336]✗ Mixed motor types detected — use identical motors[/color]")
	if issues.size() == 0:
		issues.append("[color=#4caf50]All systems nominal[/color]")
		#kiem tra wiring 
	#if is_instance_valid(wiring_panel) and wiring_panel.has_method("is_wiring_complete"):
		#var wc = wiring_panel.is_wiring_complete()
		#if not wc.ok:
			#issues.append("[color=#f44336]✗ %s[/color]" % wc.reason)
	diag_text.text = "\n".join(issues)

# ──────────────────────────── UTILS ───────────────────────────────
func _clear_children(n: Node):
	if not is_instance_valid(n): return
	for c in n.get_children():
		if is_instance_valid(c):
			c.queue_free()

func _log(msg: String, type: String = "info"):
	var c = "#aaa"
	match type:
		"success": c = "#4caf50"
		"error": c = "#f44336"
		"warning": c = "#ff9800"
	var t = Time.get_time_string_from_system()
	log_box.append_text("[color=%s][%s] %s[/color]\n" % [c, t, msg])
	
func _play_snap_sound():
	var player = AudioStreamPlayer.new()
	add_child(player)
	# Tạo click sound bằng code, không cần file
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.1
	player.stream = gen
	player.play()
	var pb = player.get_stream_playback()
	# Generate click sound
	var samples = 44100 * 0.05
	for i in range(samples):
		var t = float(i) / 44100.0
		var amp = exp(-t * 80.0)  # Decay nhanh
		var wave = sign(sin(2 * PI * 800 * t)) * amp * 0.3  # Square wave
		pb.push_frame(Vector2(wave, wave))
	# Tự xóa sau khi phát xong
	await get_tree().create_timer(0.2).timeout
	player.queue_free()


# =================Wiring Mode======================
var wiring_mode := false
var wiring_drag_from: Dictionary = {}   # {uid, port_name, port_pos, port_type}
var wiring_drag_active := false
var wiring_drag_pos := Vector3.ZERO
var manual_wires: Array[Dictionary] = []  # {from_uid, from_port, to_uid, to_port, node}
var wire_drag_mesh: Node3D = null
var wiring_hover_port: Dictionary = {}
var wiring_tooltip: Label = null


func _toggle_wiring_mode():
	wiring_mode = !wiring_mode
	
	if wiring_mode:
		_cancel_ghost()
		_log("Wiring Mode ON — Click a port to start", "info")
		_show_all_ports()
		# Desaturate tất cả components
		_set_components_desaturate(true)
	else:
		_hide_all_ports()
		_set_components_desaturate(false)
		_restore_all_materials()
		_cancel_wire_drag()
		_log("Wiring Mode OFF", "info")
	if is_instance_valid(wiring_overlay):
		wiring_overlay.visible = wiring_mode

func _show_all_ports():
	_clear_children(snap_hints)
	for comp in placed:
		if not is_instance_valid(comp.get("node")): continue
		var ports = COMPONENTS[comp.id].get("ports", [])
		for port in ports:
			var hint = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.18
			sphere.height = 0.36
			hint.mesh = sphere
			hint.name = port.name
			
			# Màu theo loại port
			var mat = StandardMaterial3D.new()
			var port_color = _get_port_color(port)
			mat.albedo_color = port_color
			mat.emission_enabled = true
			mat.emission = port_color
			mat.emission_energy_multiplier = 2.0
			mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
			hint.material_override = mat
			hint.set_meta("parent_uid", comp.uid)
			hint.set_meta("port_data", port)
			hint.set_meta("port_type", _get_port_type(port))
			snap_hints.add_child(hint)
			hint.global_position = comp.node.global_transform * port.pos

func _get_port_color(port: Dictionary) -> Color:
	var allowed = port.get("allowed", [])
	if allowed.has("Motor") or allowed.has("Battery"):
		return Color(0.9, 0.1, 0.1, 0.85)   # Power = Đỏ
	elif allowed.has("FC") or allowed.has("ESC"):
		return Color(0.9, 0.75, 0.1, 0.85)  # Signal = Vàng
	elif allowed.has("Propeller"):
		return Color(0.1, 0.6, 0.9, 0.85)   # Prop = Xanh dương
	return Color(0.5, 0.5, 0.5, 0.85)       # Default = Xám

func _get_port_type(port: Dictionary) -> String:
	var allowed = port.get("allowed", [])
	if allowed.has("Motor") or allowed.has("Battery"): return "power"
	if allowed.has("FC") or allowed.has("ESC"): return "signal"
	if allowed.has("Propeller"): return "prop"
	return "generic"

func _hide_all_ports():
	_clear_children(snap_hints)

func _set_components_desaturate(on: bool):
	for comp in placed:
		if not is_instance_valid(comp.get("node")): continue
		_apply_desaturate_recursive(comp.node, on)


func _apply_desaturate_recursive(node: Node, on: bool):
	for ch in node.get_children():
		if ch is MeshInstance3D and on:
			# Duplicate riêng để tránh shared material bug
			var mat = ch.material_override
			if mat == null and ch.mesh and ch.mesh.surface_get_material(0):
				mat = ch.mesh.surface_get_material(0)
			if mat != null:
				mat = mat.duplicate()
				mat.resource_local_to_scene = true
				ch.material_override = mat
				if mat is StandardMaterial3D:
					if not ch.has_meta("original_albedo"):
						ch.set_meta("original_albedo", mat.albedo_color)
						ch.set_meta("original_transparency", mat.transparency)
					var gray = mat.albedo_color.lerp(Color(0.5, 0.5, 0.5), 0.6)
					gray.a = 0.5
					mat.albedo_color = gray
					mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		_apply_desaturate_recursive(ch, on)

func _cancel_wire_drag():
	wiring_drag_active = false
	wiring_drag_from = {}
	if is_instance_valid(wire_drag_mesh):
		wire_drag_mesh.queue_free()
		wire_drag_mesh = null
		
var wiring_overlay: Panel = null




var ignore_next_tab_change := false
func _on_tab_changed(tab_idx: int):

	if ignore_next_tab_change:
		ignore_next_tab_change = false
		return

	var tab_name = tabs.get_tab_title(tab_idx)

	# ====================== WIRING TAB ======================
	if tab_name == "Wiring":

		ignore_next_tab_change = true
		tabs.current_tab = 0

		wiring_mode = !wiring_mode

		if wiring_mode:
			_cancel_ghost()
			_show_all_ports()
			_set_components_desaturate(true)

			if is_instance_valid(wiring_overlay):
				wiring_overlay.visible = true

			_log("Wiring Mode ON — Click a port to connect", "info")

		else:
			_hide_all_ports()
			_set_components_desaturate(false)
			_restore_all_materials()
			_cancel_wire_drag()

			if is_instance_valid(wiring_overlay):
				wiring_overlay.visible = false

			_log("Wiring Mode OFF", "info")

		return


	# ====================== OTHER TABS ======================
	if wiring_mode:
		wiring_mode = false

		_hide_all_ports()
		_set_components_desaturate(false)
		_restore_all_materials()
		_cancel_wire_drag()

		if is_instance_valid(wiring_overlay):
			wiring_overlay.visible = false

		_log("Wiring Mode OFF", "info")

func _raycast_port() -> Dictionary:
	var mpos = viewport.get_mouse_position()
	var ro = camera.project_ray_origin(mpos)
	var rd = camera.project_ray_normal(mpos)
	var best_d := 0.4
	var best = {}
	for hint in snap_hints.get_children():
		if not is_instance_valid(hint): continue
		var to_hint = hint.global_position - ro
		var proj = to_hint.dot(rd)
		if proj <= 0: continue
		var closest = ro + rd * proj
		var dist = closest.distance_to(hint.global_position)
		if dist < best_d:
			best_d = dist
			best = {
				"uid": hint.get_meta("parent_uid", -1),
				"port_name": hint.name,
				"port_pos": hint.global_position,
				"port_type": hint.get_meta("port_type", "generic"),
				"port_data": hint.get_meta("port_data", {}),
				"hint_node": hint
			}
	return best

func _try_connect_wire(to_port: Dictionary):
	# Validation
	var from_type = wiring_drag_from.get("port_type", "")
	var to_type = to_port.get("port_type", "")
	
	if wiring_drag_from.get("uid", -1) == to_port.get("uid", -1): 
		_show_wire_error("Cannot connect to same component!")
		_cancel_wire_drag()
		return
	
	if from_type != to_type:
		_show_wire_error("Incompatible ports! (" + from_type + " ≠ " + to_type + ")")
		_flash_wire_red()
		await get_tree().create_timer(0.5).timeout
		_cancel_wire_drag()
		return
	
	# Valid — tạo wire thực sự
	_finalize_wire(wiring_drag_from, to_port)
	_cancel_wire_drag()
	_log("Wire connected: " + wiring_drag_from.port_name + " → " + to_port.port_name, "success")


func _finalize_wire(from: Dictionary, to: Dictionary):
	var wire_node = Node3D.new()
	_draw_bezier_wire(wire_node, from.port_pos, to.port_pos, Color(0.1, 0.8, 0.3))
	
	if drone_root:
		drone_root.add_child(wire_node)
	else:
		components_group.add_child(wire_node)  
	manual_wires.append({
		"from_uid": from.uid,
		"from_port": from.port_name,
		"to_uid": to.uid,
		"to_port": to.port_name,
		"node": wire_node
	})  
	# Pulse animation
	_animate_wire_pulse(wire_node)



func _show_wire_error(msg: String):
	_log("WIRE ERROR: " + msg, "error")
	# Tooltip nổi
	if is_instance_valid(wiring_tooltip):
		wiring_tooltip.queue_free()
	wiring_tooltip = Label.new()
	wiring_tooltip.text = "⚠ " + msg
	wiring_tooltip.add_theme_font_size_override("font_size", 13)
	wiring_tooltip.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	add_child(wiring_tooltip)
	wiring_tooltip.global_position = get_global_mouse_position() + Vector2(10, -30)
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(wiring_tooltip):
		wiring_tooltip.queue_free()

func _flash_wire_red():
	if not is_instance_valid(wire_drag_mesh): return
	for ch in wire_drag_mesh.get_children():
		if ch is MeshInstance3D and ch.material_override:
			ch.material_override.albedo_color = Color(1, 0.1, 0.1)

func _draw_bezier_wire(root: Node3D, from: Vector3, to: Vector3, color: Color):
	var dist = from.distance_to(to)
	var segments = 10
	var sag = max(0.15, dist * 0.2)
	var mid = (from + to) / 2.0
	mid.y -= sag
	for i in range(segments):
		var t0 = float(i) / segments
		var t1 = float(i + 1) / segments
		var p0 = _bezier3(from, mid, to, t0)
		var p1 = _bezier3(from, mid, to, t1)
		var seg_dist = p0.distance_to(p1)
		var cyl = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.035
		cm.bottom_radius = 0.035
		cm.height = seg_dist
		cyl.mesh = cm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
		cyl.material_override = mat
		root.add_child(cyl)
		cyl.look_at_from_position((p0 + p1) / 2.0, p1, Vector3.UP)
		cyl.rotate_object_local(Vector3.RIGHT, PI / 2)

func _animate_wire_pulse(wire_node: Node3D):
	# Tween emission để tạo hiệu ứng pulse
	var tween = create_tween().set_loops()
	for ch in wire_node.get_children():
		if ch is MeshInstance3D and ch.material_override:
			tween.tween_property(ch.material_override, 
				"emission_energy_multiplier", 3.0, 0.5)
			tween.tween_property(ch.material_override, 
				"emission_energy_multiplier", 1.0, 0.5)
func _create_drag_wire() -> Node3D:
	var w = Node3D.new()
	w.name = "DragWire"
	scene_root.add_child(w)
	return w

func _restore_all_materials():
	for comp in placed:
		if not is_instance_valid(comp.get("node")): continue
		_restore_materials_recursive(comp.node)


func _restore_materials_recursive(node: Node):
	for ch in node.get_children():
		if ch is MeshInstance3D and ch.has_meta("original_albedo"):
			var mat = ch.material_override
			if mat is StandardMaterial3D:
				mat.albedo_color = ch.get_meta("original_albedo")
				mat.transparency = ch.get_meta("original_transparency")
				mat.albedo_color.a = 1.0
				mat.emission_enabled = false
				ch.remove_meta("original_albedo")
				ch.remove_meta("original_transparency")
		_restore_materials_recursive(ch)

var tree_items: Dictionary = {}   # uid -> TreeItem

# =================Xây dựng lại toàn bộ Hierarchy Tree====================
func _build_hierarchy_tree():
	if not is_instance_valid(hier_tree):
		return
	
	hier_tree.clear()
	tree_items.clear()
	
	var root = hier_tree.create_item()
	root.set_text(0, "Drone")
	
	# 1. Tạo các component cha (root level)
	for comp in placed:
		if comp.get("parent_id", -1) <= 0:
			_create_hier_item(comp, root)
	
	# 2. Tạo các component con
	for comp in placed:
		if comp.get("parent_id", -1) > 0:
			var parent_item = tree_items.get(comp.get("parent_id"), root)
			_create_hier_item(comp, parent_item)
	



# Tạo một item trong Tree
func _create_hier_item(comp: Dictionary, parent_item: TreeItem) -> TreeItem:
	var item = hier_tree.create_item(parent_item)
	
	# Icon theo loại component
	var prefix = ""
	match comp.type:
		"Frame":    prefix = "🔲 "
		"Motor":    prefix = "⚙️ "
		"Propeller": prefix = "🌀 "
		"Battery":  prefix = "🔋 "
		"FC":       prefix = "💻 "
		"ESC":      prefix = "⚡ "
		_:          prefix = "📦 "
	
	item.set_text(0, prefix + comp.id)
	item.set_metadata(0, comp.uid)
	
	# Màu theo loại
	match comp.type:
		"Frame":    item.set_custom_color(0, Color(0.8, 0.8, 0.8))
		"Motor":    item.set_custom_color(0, Color(0.9, 0.5, 0.5))
		"Propeller": item.set_custom_color(0, Color(0.5, 0.7, 1.0))
		"Battery":  item.set_custom_color(0, Color(0.9, 0.8, 0.2))
		"FC":       item.set_custom_color(0, Color(0.3, 0.9, 0.5))
		"ESC":      item.set_custom_color(0, Color(0.5, 0.6, 1.0))
	
	# Tự động expand parent để thấy con
	if parent_item:
		parent_item.set_collapsed(false)
	
	tree_items[comp.uid] = item
	return item

#============COMPONENT LIST===============
var _cat_collapsed: Dictionary = {}  # track trạng thái collapsed của từng category

func _build_comp_list():
	comp_list.clear()
	for cat in CATEGORIES:
		# Lấy trạng thái collapsed, mặc định là false (expanded)
		var collapsed = _cat_collapsed.get(cat, false)
		var arrow = "▾ " if not collapsed else "▸ "
		
		var ci = comp_list.add_item(arrow + cat)
		comp_list.set_item_selectable(ci, true)
		comp_list.set_item_metadata(ci, {"is_category": true, "cat": cat})
		comp_list.set_item_custom_fg_color(ci, Color(0.75, 0.75, 0.75))
		
		# Chỉ hiện items nếu category chưa bị collapse
		if not collapsed:
			for cid in CATEGORIES[cat]:
				if COMPONENTS.has(cid):
					var ii = comp_list.add_item("   " + cid)
					comp_list.set_item_metadata(ii, {"is_category": false, "id": cid})
					var c = COMPONENTS[cid]
					match c.type:
						"Motor":    comp_list.set_item_custom_fg_color(ii, Color(0.9, 0.4, 0.4))
						"Battery":  comp_list.set_item_custom_fg_color(ii, Color(0.9, 0.8, 0.2))
						"Frame":    comp_list.set_item_custom_fg_color(ii, Color(0.7, 0.7, 0.7))
						_:          comp_list.set_item_custom_fg_color(ii, Color(0.6, 0.7, 0.8))


func _pick_existing():
	var mpos = viewport.get_mouse_position()
	var ro = camera.project_ray_origin(mpos)
	var rd = camera.project_ray_normal(mpos)
	
	var best_uid := -1
	var best_d := 1000.0
	
	for c in placed:
		if not is_instance_valid(c.node): continue
		if c.type == "Frame": continue
		var to_node = c.node.global_position - ro
		var projection = to_node.dot(rd)
		if projection > 0:
			var closest_point = ro + rd * projection
			var dist = closest_point.distance_to(c.node.global_position)
			if dist < 1.0 and dist < best_d:
				best_d = dist
				best_uid = c.uid
	
	if best_uid == -1:
		return
	
	# Tìm motor entry
	var motor_entry = null
	var motor_idx = -1
	for i in range(placed.size()):
		if placed[i].uid == best_uid:
			motor_entry = placed[i]
			motor_idx = i
			break
	
	if motor_entry == null:
		return
	
	cur_id = motor_entry.id
	_ghost_children.clear()
	
	# Thu thập children + offset (dùng local position để không phụ thuộc world transform)
	var children_indices: Array[int] = []
	for j in range(placed.size()):
		var candidate = placed[j]
		if candidate.get("parent_id", -1) != best_uid:
			continue
		var local_offset = Vector3.ZERO
		if is_instance_valid(candidate.get("node")) and is_instance_valid(motor_entry.node):
			local_offset = motor_entry.node.global_transform.affine_inverse() * candidate.node.global_position
		_ghost_children.append({
			"id": candidate.id,
			"local_offset": local_offset,
			"port_name": candidate.get("port_name", ""),
		})
		children_indices.append(j)
	
	# Xóa children khỏi placed (không free node — sẽ bị free theo motor)
	children_indices.sort()
	children_indices.reverse()
	for idx in children_indices:
		placed.remove_at(idx)
	
	# Xóa motor khỏi placed
	# Phải điều chỉnh motor_idx vì đã remove children ở trên
	# Tìm lại motor_idx sau khi xóa children
	motor_idx = -1
	for i in range(placed.size()):
		if placed[i].uid == best_uid:
			motor_idx = i
			break
	if motor_idx != -1:
		placed.remove_at(motor_idx)
	
	# Tạo ghost mới
	ghost = _build_mesh(cur_id, true)
	components_group.add_child(ghost)
	
	# Free node motor (children node là con của motor node nên bị free theo — đúng)
	if is_instance_valid(motor_entry.node):
		motor_entry.node.queue_free()
	
	_show_snap_hints(cur_id)
	
	# Tạo ghost visual cho children
	for child_info in _ghost_children:
		var child_ghost = _build_mesh(child_info.id, true)
		ghost.add_child(child_ghost)
		child_ghost.position = child_info.local_offset
	
	_rebuild_wires()
	_update_all()
	


func _remove_component(uid: int):
	var found_idx = -1
	for i in range(placed.size()):
		if placed[i].uid == uid:
			found_idx = i
			break
	
	if found_idx == -1:
		_log("Nothing selected to delete", "info")
		return
	
	var comp = placed[found_idx]
	if comp.type == "Frame":
		_log("Cannot remove the main frame!", "error")
		return
	
	# Detach children khỏi node cha trước khi free
	for other in placed:
		if other.get("parent_id", -1) != uid: continue
		if not is_instance_valid(other.get("node")): continue
		var world_pos = other.node.global_position
		if other.node.get_parent():
			other.node.get_parent().remove_child(other.node)
		components_group.add_child(other.node)
		other.node.global_position = world_pos
		other["parent_id"] = -1
		other["port_name"] = ""
	
	if is_instance_valid(comp.get("node")):
		comp.node.queue_free()
	placed.remove_at(found_idx)
	
	_rebuild_wires()
	_update_all()


func _re_place_ghost_children(parent_uid_hint: int):

	
	if _ghost_children.is_empty():
		
		return
	# Tìm motor vừa place
	var parent_entry = null
	var latest_uid = -1
	for entry in placed:
		if entry.id == cur_id and entry.uid > latest_uid:
			latest_uid = entry.uid
			parent_entry = entry
	
	if parent_entry == null:
		_log("FAILED: parent_entry is null, cur_id=" + cur_id, "error")
		_ghost_children.clear()
		return
	
	if not is_instance_valid(parent_entry.get("node")):
		_log("FAILED: parent node invalid", "error")
		_ghost_children.clear()
		return
		
	
	for child_info in _ghost_children:
		
		var child_type = COMPONENTS[child_info.id].type
		var ports = COMPONENTS[parent_entry.id].get("ports", [])
		
		var target_port = ""
		var target_pos = parent_entry.node.global_position
		
		for port in ports:
			if not port.get("allowed", []).has(child_type):
				continue
			var occupied = false
			for other in placed:
				if other.get("port_name", "") == port.name and other.get("parent_id", -1) == parent_entry.uid:
					occupied = true
					break
			if not occupied:
				target_port = port.name
				target_pos = parent_entry.node.global_transform * port.pos
				break
		
		_place(child_info.id, target_pos, target_port, parent_entry.uid)

	
	_ghost_children.clear()
	
#=============CAMERA ON DRONE ====================
func _focus_camera_on_drone():
	var min_pos = Vector3(INF, INF, INF)
	var max_pos = Vector3(-INF, -INF, -INF)
	
	for c in placed:
		if not is_instance_valid(c.get("node")): continue
		var pos = c.node.global_position
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		min_pos.z = min(min_pos.z, pos.z)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
		max_pos.z = max(max_pos.z, pos.z)
	
	var center = (min_pos + max_pos) / 2.0
	var size = (max_pos - min_pos).length()
	
	# Pivot đúng tại center của drone, không offset
	pivot.global_position = center + Vector3(0, 2, -2)
	
	zoom = max(size * 1, 7.0)
	
	# Nhìn thẳng mặt drone, góc cao hơn để drone ở giữa
	# X = -0.2 : nhìn hơi từ trên xuống (thấp, gần ngang)
	# Y = 0.3  : xoay nhẹ sang phải
	camera_rot = Vector2(-0.6, 0.0) 

#func _create_hier_toggle():
	#var toggle = Button.new()
	#toggle.text = "◀"
	#toggle.custom_minimum_size = Vector2(20, 48)
	#toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	#
	#var sb = StyleBoxFlat.new()
	#sb.bg_color = Color(0.22, 0.22, 0.26)
	#sb.corner_radius_top_right    = 6
	#sb.corner_radius_bottom_right = 6
	#toggle.add_theme_stylebox_override("normal", sb)
	#toggle.add_theme_stylebox_override("hover",  sb)
	#toggle.add_theme_font_size_override("font_size", 10)
	#
	#center_right.add_child(toggle)
	#center_right.move_child(toggle, 0)
	#
	#toggle.pressed.connect(_toggle_hier.bind(toggle))
#func _create_hier_toggle():
	#var toggle = Button.new()
	#toggle.text = "◀"
	#toggle.custom_minimum_size = Vector2(20, 48)
	#
	#var sb = StyleBoxFlat.new()
	#sb.bg_color = Color(0.22, 0.22, 0.26)
	#sb.corner_radius_top_right    = 6
	#sb.corner_radius_bottom_right = 6
	#toggle.add_theme_stylebox_override("normal", sb)
	#toggle.add_theme_stylebox_override("hover",  sb)
	#toggle.add_theme_font_size_override("font_size", 10)
	#
	## Add vào Left panel, anchor về bên phải giữa
	#left_panel.add_child(toggle)
	#toggle.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	#toggle.set_anchor(SIDE_LEFT, 1.0)
	#toggle.set_anchor(SIDE_RIGHT, 1.0)
	#toggle.set_anchor(SIDE_TOP, 0.5)
	#toggle.set_anchor(SIDE_BOTTOM, 0.5)
	#toggle.offset_left   = 0
	#toggle.offset_right  = 20
	#toggle.offset_top    = -24
	#toggle.offset_bottom = 24
	#toggle.z_index = 10  # nổi lên trên CenterRight
	#toggle.pressed.connect(_toggle_hier.bind(toggle))
#
#func _toggle_hier(toggle: Button):
	#left_panel.visible = not left_panel.visible
	#toggle.text = "◀" if left_panel.visible else "▶"
func _create_hier_toggle():
	var toggle = Button.new()
	toggle.text = "⊞"
	toggle.custom_minimum_size = Vector2(32, 28)
	toggle.tooltip_text = "Toggle Hierarchy"
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.22, 0.26)
	sb.corner_radius_top_left     = 4
	sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_left  = 4
	sb.corner_radius_bottom_right = 4
	toggle.add_theme_stylebox_override("normal", sb)
	toggle.add_theme_stylebox_override("hover",  sb)
	toggle.add_theme_font_size_override("font_size", 14)
	
	# Thêm vào đầu TopBar
	$Root/TopBar/H.add_child(toggle)
	$Root/TopBar/H.move_child(toggle, 0)
	
	toggle.pressed.connect(_toggle_hier.bind(toggle))

func _toggle_hier(toggle: Button):
	left_panel.visible = not left_panel.visible
	toggle.text = "⊞" if not left_panel.visible else "⊟"
