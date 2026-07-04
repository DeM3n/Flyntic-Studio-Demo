# res://Scripts/Components/ComponentFactort.gd
class_name ComponentFactory

# ===== DATA =====
# Thêm field "model_path" (nếu có model .tscn/.glb) và "fallback_size" (dùng khi load model fail)
static var COMPONENTS: Dictionary = {
		"PVC Pipe Frame": {
		"type": "Frame", "weight": 250, "thrust": 0, "capacity": 0,
		"color": Color(0.9, 0.9, 0.85),
		"use_obj": true, "obj_path": "res://Components/quad_pvc_frame.obj",
		"ports": [
			{"name": "fl", "pos": Vector3(2.28, 2.2, 2.28), "slot": true, "allowed": ["Motor"]},
			{"name": "fr", "pos": Vector3(2.28, 2.2, -2.28), "slot": true, "allowed": ["Motor"]},
			{"name": "bl", "pos": Vector3(-2.28, 2.2, 2.28), "slot": true, "allowed": ["Motor"]},
			{"name": "br", "pos": Vector3(-2.28, 2.2, -2.28), "slot": true, "allowed": ["Motor"]},
			{"name": "fc_slot", "pos": Vector3(0, 1.8, 0), "slot": true, "allowed": ["FC"]},
			{"name": "esc_slot", "pos": Vector3(0, 1.2, 0), "slot": true, "allowed": ["ESC"]},
			{"name": "center_bot", "pos": Vector3(0, 0.5, 0), "slot": true, "allowed": ["Battery"]},
		],
		"ground_offset": 0.0
	},
	"Carbon Fiber Body": {
		"type": "Frame", "weight": 180, "thrust": 0, "capacity": 0,
		"color": Color(0.4, 0.4, 0.42),
		"use_obj": false,
		"ports": [
			{"name": "fl", "pos": Vector3(2, 1.9, 2), "slot": true, "allowed": ["Motor"]},
			{"name": "fr", "pos": Vector3(2, 1.9, -2), "slot": true, "allowed": ["Motor"]},
			{"name": "bl", "pos": Vector3(-2, 1.9, 2), "slot": true, "allowed": ["Motor"]},
			{"name": "br", "pos": Vector3(-2, 1.9, -2), "slot": true, "allowed": ["Motor"]},
			{"name": "center", "pos": Vector3(0, 1.0, 0), "slot": true, "allowed": ["FC", "Battery", "ESC"]},
		],
		"ground_offset": 0.0
	},
	"Motor 2205 2300KV": {
		"type": "Motor", "weight": 35, "thrust": 850, "capacity": 0, "kv": 2300,
		"max_current": 28,
		"color": Color(0.6, 0.25, 0.25),
		"ground_offset": 0.4,
		"model_path": "res://Components/models/Motor/Motor2205/motor.tscn",
		"ports": [{"name": "prop", "pos": Vector3(0, 0.3, 0), "slot": true, "allowed": ["Propeller"]}]
	},
	"Motor 2207 2400KV": {
		"type": "Motor", "weight": 42, "thrust": 1100, "capacity": 0, "kv": 2400,
		"max_current": 33,
		"color": Color(0.25, 0.45, 0.8),
		"ground_offset": 0.3,
		"model_path": "res://Components/models/Motor/Motor2207/Motor_2207.tscn",
		"ports": [{"name": "prop", "pos": Vector3(0, 0.3, 0), "slot": true, "allowed": ["Propeller"]}]
	},
	"Motor 2212 920KV": {
		"type": "Motor", "weight": 56, "thrust": 980, "capacity": 0, "kv": 920,
		"max_current": 18,
		"color": Color(0.8, 0.55, 0.1),
		"ground_offset": 0.3,
		"model_path": "res://Components/models/Motor/Motor2205/motor.tscn",
		"ports": [{"name": "prop", "pos": Vector3(0, 0.3, 0), "slot": true, "allowed": ["Propeller"]}]
	},
	"Propeller 5045": {
		"type": "Propeller", "weight": 8, "thrust": 0, "capacity": 0,
		"thrust_mult": 1.0,
		"kv_range": Vector2(1900, 2600),
		"ground_offset": 0.07,
		"model_path": "res://Components/models/Propeller_5045/Propeller_5045.tscn",
		"color": Color(0.8, 0.1, 0.1), "ports": []
	},
	"Propeller 6045": {
		"type": "Propeller", "weight": 12, "thrust": 0, "capacity": 0,
		"thrust_mult": 1.18,
		"kv_range": Vector2(1400, 2100),
		"ground_offset": 0.07,
		"model_path": "res://Components/models/Propeller_5045/Propeller_5045.tscn", # chưa có model -> dùng fallback procedural
		"color": Color(0.1, 0.1, 0.8), "ports": []
	},
	"Lipo 4S 1500mAh": {
		"type": "Battery", "weight": 185, "thrust": 0, "capacity": 1500,
		"cells": 4,
		"current_rating": 45,
		"ground_offset": 0.1,
		"model_path": "",
		"fallback_size": Vector3(0.5, 0.5, 1.8),
		"color": Color(0.85, 0.7, 0.15), "ports": []
	},
	"F4 Flight Controller": {
		"type": "FC", "weight": 7, "thrust": 0, "capacity": 0,
		"ground_offset": 0.2,
		"model_path": "",
		"fallback_size": Vector3(1.5, 0.08, 1.5),
		"color": Color(0.0, 0.35, 0.0), "ports": []
	},
	"4-in-1 ESC": {
		"type": "ESC", "weight": 15, "thrust": 0, "capacity": 0,
		"ground_offset": 0.1,
		"model_path": "",
		"fallback_size": Vector3(1.0, 0.25, 1.8),
		"color": Color(0.0, 0.0, 0.5), "ports": []
	},
}

# ===== PUBLIC API =====
# Gọi duy nhất chỗ này từ bên ngoài
static func build(root: Node3D, comp_name: String) -> void:
	if not COMPONENTS.has(comp_name):
		push_error("ComponentFactory: unknown component '%s'" % comp_name)
		return
	_build_from_data(root, COMPONENTS[comp_name])

# ===== INTERNAL: dispatch model vs fallback =====
static func _build_from_data(root: Node3D, data: Dictionary) -> void:
	var path: String = data.get("model_path", "")
	if path != "":
		var scene := load(path)
		if scene:
			var inst = scene.instantiate()
			root.add_child(inst)
			return
		push_warning("ComponentFactory: failed to load model '%s', using fallback" % path)
	_build_fallback(root, data)

static func _build_fallback(root: Node3D, data: Dictionary) -> void:
	match data.get("type", ""):
		"Motor":
			_build_motor_procedural(root)
		"Propeller":
			_build_propeller_procedural(root)
		"Battery":
			_build_battery_procedural(root, data)
		"FC":
			_build_fc_procedural(root, data)
		"ESC":
			_build_esc_procedural(root, data)
		_:
			_build_generic_box(root, data.get("fallback_size", Vector3(1, 1, 1)), data.get("color", Color.WHITE))

# ===== PROCEDURAL FALLBACKS =====
static func _build_motor_procedural(root: Node3D) -> void:
	var st = MeshInstance3D.new()
	st.mesh = CylinderMesh.new()
	st.mesh.top_radius = 0.4
	st.mesh.bottom_radius = 0.4
	st.mesh.height = 0.5
	root.add_child(st)

	var bell = MeshInstance3D.new()
	bell.mesh = CylinderMesh.new()
	bell.mesh.top_radius = 0.45
	bell.mesh.bottom_radius = 0.45
	bell.mesh.height = 0.2
	bell.position.y = 0.25
	root.add_child(bell)

	var shaft = MeshInstance3D.new()
	shaft.mesh = CylinderMesh.new()
	shaft.mesh.top_radius = 0.1
	shaft.mesh.bottom_radius = 0.1
	shaft.mesh.height = 0.3
	shaft.position.y = 0.5
	root.add_child(shaft)

static func _build_propeller_procedural(root: Node3D) -> void:
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

static func _build_generic_box(root: Node3D, size: Vector3, color: Color) -> void:
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = size
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	body.set_surface_override_material(0, mat)
	root.add_child(body)
static func _build_battery_procedural(root: Node3D, data: Dictionary) -> void:
	# LiPo 4S 1500mAh thực tế: ~105 x 34 x 34mm
	# 1 Godot unit = 0.2m => chia mm cho 200
	var size: Vector3 = data.get("fallback_size", Vector3(0.17, 0.17, 0.525))
	var body = MeshInstance3D.new()
	body.name = "BatteryBody"
	body.mesh = BoxMesh.new()
	body.mesh.size = size
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = data.get("color", Color(0.85, 0.7, 0.15))
	body_mat.roughness = 0.35
	body_mat.metallic = 0.05
	body.set_surface_override_material(0, body_mat)
	root.add_child(body)

# ===== FLIGHT CONTROLLER =====
static func _build_fc_procedural(root: Node3D, data: Dictionary) -> void:
	var size: Vector3 = data.get("fallback_size", Vector3(1.5, 0.08, 1.5))

	# --- PCB chính ---
	var pcb = MeshInstance3D.new()
	pcb.mesh = BoxMesh.new()
	pcb.mesh.size = size
	var mat = StandardMaterial3D.new()
	# Nếu vẫn ra xanh lá -> kiểm tra data["color"] có tồn tại và đúng key không
	mat.albedo_color = data.get("color", Color(0.05, 0.05, 0.05)) # đổi default sang đen cho giống ảnh
	pcb.set_surface_override_material(0, mat)
	root.add_child(pcb)

	# --- Chip ở giữa, lồi lên trên mặt board ---
	var chip = MeshInstance3D.new()
	chip.mesh = BoxMesh.new()
	var chip_size = Vector3(size.x * 0.35, size.y * 1.0, size.z * 0.35)
	chip.mesh.size = chip_size
	var chip_mat = StandardMaterial3D.new()
	chip_mat.albedo_color = Color(0.1, 0.1, 0.1)
	chip.set_surface_override_material(0, chip_mat)
	chip.position = Vector3(0, size.y * 0.5 + chip_size.y * 0.5, 0)
	root.add_child(chip)

	# --- 4 trụ đế: board nằm CHÍNH GIỮA trụ (trụ xuyên qua,ló cả 2 phía) ---
	var standoff_radius = size.x * 0.07
	var protrusion = size.y * 2.0          # phần nhô ra mỗi bên so với mặt board
	var standoff_height = size.y + protrusion * 2.0
	var offset_x = size.x * 0.42
	var offset_z = size.z * 0.42

	var standoff_mat = StandardMaterial3D.new()
	standoff_mat.albedo_color = Color(0.8, 0.05, 0.05)

	var offsets = [
		Vector3( offset_x, 0,  offset_z),
		Vector3(-offset_x, 0,  offset_z),
		Vector3( offset_x, 0, -offset_z),
		Vector3(-offset_x, 0, -offset_z),
	]

	for off in offsets:
		var standoff = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = standoff_radius
		cyl.bottom_radius = standoff_radius
		cyl.height = standoff_height
		cyl.radial_segments = 8
		standoff.mesh = cyl
		standoff.set_surface_override_material(0, standoff_mat)
		# y = 0 => tâm trụ trùng tâm board => board nằm giữa trụ, trụ ló ra cả trên lẫn dưới
		standoff.position = Vector3(off.x, 0, off.z)
		root.add_child(standoff)
# ===== ESC =====
static func _build_esc_procedural(root: Node3D, data: Dictionary) -> void:
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = data.get("fallback_size", Vector3(1.0, 0.25, 1.8))
	var mat = StandardMaterial3D.new()
	mat.albedo_color = data.get("color", Color(0.0, 0.0, 0.5))
	body.set_surface_override_material(0, mat)
	root.add_child(body)
