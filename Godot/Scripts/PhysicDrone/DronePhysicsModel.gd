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
			var prop_def := _find_attached_propeller_def(comp, placed, components)
			var thrust_mult: float = prop_def.get("thrust_mult", 1.0)
			var prop_kv_range: Vector2 = prop_def.get("kv_range", Vector2(-1, -1))
			var spin_dir := 1 if (sign(r.x) * sign(r.z)) >= 0.0 else -1
			motors.append({
				"pos": r,
				"max_thrust_n": thrust_g * thrust_mult * GRAMF_TO_NEWTON,
				"spin_dir": spin_dir,
				"kv": def.get("kv", 1500.0),
				"prop_kv_range": prop_kv_range,
				"max_current": def.get("max_current", 20.0),
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

## Lấy điện áp pin danh nghĩa (3.7V/cell theo chuẩn LiPo)
static func get_battery_voltage(placed: Array, components: Dictionary) -> float:
	for comp in placed:
		var def: Dictionary = components.get(comp.get("id", ""), {})
		if def.get("type", "") == "Battery":
			var cells: int = def.get("cells", 4)
			return cells * 3.7
	return 14.8  # fallback: 4S

## Hệ số khớp KV-cánh quạt: 1.0 = khớp lý tưởng, giảm dần khi lệch dải kv_range
static func _kv_prop_match_factor(motor_kv: float, prop_range: Vector2) -> float:
	if motor_kv >= prop_range.x and motor_kv <= prop_range.y:
		return 1.0
	var dist: float = prop_range.x - motor_kv if motor_kv < prop_range.x else motor_kv - prop_range.y
	var span: float = max(prop_range.y - prop_range.x, 1.0)
	var penalty: float = clamp(dist / span, 0.0, 1.0)
	return clamp(1.0 - penalty * 0.6, 0.4, 1.0)

## Trung bình hệ số khớp trên toàn bộ cánh quạt đang gắn
## Trung bình KV thô của các motor đang gắn -- CHỈ dùng cho kv_factor (responsiveness).
## KHÔNG dùng để tính mismatch penalty -- mismatch phải theo từng cặp, xem hàm dưới.
static func average_motor_kv(motors: Array) -> float:
	if motors.is_empty():
		return 1500.0
	var total := 0.0
	for m in motors:
		total += m.get("kv", 1500.0)
	return total / motors.size()

## Hệ số khớp KV-cánh quạt THEO TỪNG CẶP motor-propeller thực tế, lấy factor TỆ NHẤT
## trong toàn hệ thống -- 1 cặp lắp sai nặng không còn bị pha loãng bởi các cặp đúng khác.
## motors: lấy từ compute_mass_properties() (đã có sẵn prop_kv_range cho từng motor).
static func get_kv_mismatch_factor(motors: Array) -> float:
	if motors.is_empty():
		return 1.0
	var worst := 1.0
	for m in motors:
		var prop_range: Vector2 = m.get("prop_kv_range", Vector2(-1, -1))
		if prop_range.x < 0.0:
			continue  # motor không gắn prop -- case này đã bị preflight check khác chặn
		worst = min(worst, _kv_prop_match_factor(m.get("kv", 1500.0), prop_range))
	return worst
static func get_esc_overload_factor(placed: Array, components: Dictionary) -> float:
	var esc_rating := 0.0
	var max_motor_current := 0.0
	for comp in placed:
		var def: Dictionary = components.get(comp.get("id", ""), {})
		if def.get("type", "") == "ESC":
			esc_rating = def.get("current_rating", 30.0)
		elif def.get("type", "") == "Motor":
			max_motor_current = max(max_motor_current, def.get("max_current", 20.0))
	if esc_rating <= 0.0:
		return 1.0
	if max_motor_current <= esc_rating:
		return 1.0
	var overshoot: float = (max_motor_current - esc_rating) / esc_rating
	return clamp(1.0 - overshoot * 0.7, 0.3, 1.0)


## Tìm propeller (nếu có) đang gắn trực tiếp vào 1 component (thường là Motor).
## Trả về def của propeller đó từ COMPONENTS (rỗng nếu không có prop nào gắn).
static func _find_attached_propeller_def(comp: Dictionary, placed: Array, components: Dictionary) -> Dictionary:
	var comp_uid = comp.get("uid")
	for item in placed:
		if item.get("parent_id") == comp_uid and item.get("type", "") == "Propeller":
			return components.get(item.get("id", ""), {})
	return {}
