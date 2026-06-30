class_name DronePhysicsModel
extends RefCounted
## Các hàm tính toán THUẦN (pure) cho mô hình vật lý drone.
## Không phụ thuộc scene/node ngoài việc đọc comp.node.position để lấy cánh tay mô-men.
## Nhận vào Array[Dictionary] giống đúng cấu trúc `placed` đang dùng trong Main.gd.
## Dùng lại được cho cả simulation core (DronePhysicsBody) và module Validation sau này.

const G := 9.80665              # gia tốc trọng trường, m/s^2
const GRAM_TO_KG := 0.001
const GRAMF_TO_NEWTON := G * GRAM_TO_KG   # 1 gram-force -> Newton

# Đo thực tế: lệnh forward 200cm di chuyển 10 unit trong scene -> 1 unit = 20cm.
# Khớp với hệ số 0.05 (cm -> unit) đang dùng trong _simulate_kinematic/_simulate_bridge.
const UNIT_TO_METER := 0.2


## placed: Array các tham chiếu {id, type, node, ...} — KHÔNG chứa weight/thrust trực tiếp.
## components: Dictionary catalog (biến `COMPONENTS` trong Main.gd) — chứa weight/thrust theo `id`.
## drone_root: node gốc dùng làm mốc quy đổi vị trí (mọi comp.node phải nằm trong scene tree dưới nó).
##
## Trả về:
## {
##   total_mass_kg: float,
##   cg: Vector3,              # trọng tâm, mét, so với drone_root
##   inertia: Vector3,         # (Ixx, Iyy, Izz) kg*m^2 — xấp xỉ point-mass, bỏ qua product of inertia
##   motors: Array[{ pos: Vector3 (so với CG, mét), max_thrust_n: float, spin_dir: int }],
## }
static func compute_mass_properties(placed: Array, components: Dictionary, drone_root: Node3D) -> Dictionary:
	var total_mass := 0.0
	var weighted_pos := Vector3.ZERO
	var root_inverse := drone_root.global_transform.affine_inverse()

	for comp in placed:
		var def: Dictionary = components.get(comp.get("id", ""), {})
		var w_g: float = def.get("weight", 0.0)
		var mass_kg := w_g * GRAM_TO_KG
		var pos := _local_pos_of(comp, root_inverse)
		total_mass += mass_kg
		weighted_pos += pos * mass_kg

	if total_mass <= 0.0:
		return {
			"total_mass_kg": 0.0,
			"cg": Vector3.ZERO,
			"inertia": Vector3.ONE,
			"motors": [],
		}

	var cg := weighted_pos / total_mass

	var ixx := 0.0
	var iyy := 0.0
	var izz := 0.0
	var motors: Array = []

	for comp in placed:
		var def: Dictionary = components.get(comp.get("id", ""), {})
		var w_g: float = def.get("weight", 0.0)
		var mass_kg := w_g * GRAM_TO_KG
		var pos := _local_pos_of(comp, root_inverse)
		var r := pos - cg   # vị trí so với trọng tâm

		ixx += mass_kg * (r.y * r.y + r.z * r.z)
		iyy += mass_kg * (r.x * r.x + r.z * r.z)
		izz += mass_kg * (r.x * r.x + r.y * r.y)

		if def.get("type", "") == "Motor":
			var thrust_g: float = def.get("thrust", 0.0)
			# Quy ước CW/CCW chuẩn cấu hình X: 2 góc chéo nhau quay cùng chiều.
			# (Tạm suy ra từ vị trí vì data hiện chưa có field spin_dir riêng.)
			var spin_dir := 1 if (sign(r.x) * sign(r.z)) >= 0.0 else -1
			motors.append({
				"pos": r,
				"max_thrust_n": thrust_g * GRAMF_TO_NEWTON,
				"spin_dir": spin_dir,
			})

	# Tránh chia 0 khi quay (vd: mới có Frame, chưa gắn Motor nào)
	ixx = max(ixx, 0.0001)
	iyy = max(iyy, 0.0001)
	izz = max(izz, 0.0001)

	return {
		"total_mass_kg": total_mass,
		"cg": cg,
		"inertia": Vector3(ixx, iyy, izz),
		"motors": motors,
	}


## Thrust-to-weight ratio — dùng cho preflight validation.
static func thrust_to_weight_ratio(motors: Array, total_mass_kg: float) -> float:
	if total_mass_kg <= 0.0:
		return 0.0
	var total_thrust_n := 0.0
	for m in motors:
		total_thrust_n += m.max_thrust_n
	var weight_n := total_mass_kg * G
	if weight_n <= 0.0:
		return 0.0
	return total_thrust_n / weight_n


## Trả về vị trí component theo MÉT, quy về hệ quy chiếu của drone_root —
## dùng global_transform nên đúng bất kể comp.node lồng bao nhiêu cấp cha-con
## trong scene tree (an toàn hơn đọc node.position local trực tiếp).
## root_inverse = drone_root.global_transform.affine_inverse(), tính 1 lần ở caller.
static func _local_pos_of(comp: Dictionary, root_inverse: Transform3D) -> Vector3:
	var node = comp.get("node")
	if is_instance_valid(node):
		var local_pos: Vector3 = root_inverse * node.global_transform.origin
		return local_pos * UNIT_TO_METER
	return Vector3.ZERO
