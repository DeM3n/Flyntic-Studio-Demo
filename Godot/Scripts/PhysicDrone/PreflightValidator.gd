class_name PreflightValidator
extends RefCounted
## Kiểm tra an toàn bay — dùng CHUNG cho dashboard live-update (Main._update_all,
## gọi liên tục) và preflight gate lúc bấm Play (DroneSimulationRuntime.start,
## gọi 1 lần) -- 1 nguồn tính duy nhất, khỏi lệch số giữa 2 nơi.

const TWR_MIN_FLY  := 1.2
const TWR_MIN_SAFE := 1.5
const TWR_GOOD     := 2.0

const BATTERY_USABLE_FRACTION := 0.8
const BATTERY_C_SAFETY_MARGIN := 0.8

const ESC_OVERLOAD_WARN_RATIO     := 1.0
const ESC_OVERLOAD_CRITICAL_RATIO := 1.5

const CG_OFFSET_WARN_RATIO     := 0.15
const CG_OFFSET_CRITICAL_RATIO := 0.30

const HOVER_THROTTLE_FLOOR := 0.15


## placed: PHẢI đã lọc chỉ gồm component thuộc drone_root (dùng
## DroneSimulationRuntime.get_in_drone_placed()) -- validator không tự lọc.
static func run(placed: Array, components: Dictionary, drone_root: Node3D) -> Dictionary:
	var warnings: Array[Dictionary] = []

	if drone_root == null or placed.is_empty():
		warnings.append(_w("critical", "no_frame", "No frame detected — cannot fly."))
		return {"ok": false, "warnings": warnings, "stats": _empty_stats()}

	var has_frame := false
	var has_battery := false
	var has_esc := false
	for c in placed:
		var def: Dictionary = components.get(c.get("id", ""), {})
		match def.get("type", ""):
			"Frame": has_frame = true
			"Battery": has_battery = true
			"ESC": has_esc = true

	if not has_frame:
		warnings.append(_w("critical", "no_frame", "No frame detected — cannot fly."))
	if not has_battery:
		warnings.append(_w("critical", "no_battery", "No battery installed — cannot fly."))
	if not has_esc:
		warnings.append(_w("critical", "no_esc", "No ESC installed — motors cannot be driven."))

	# Thiếu frame/battery -> mass properties vô nghĩa, dừng sớm, khỏi sinh
	# thêm warning phái sinh (VD "thrust insufficient" ăn theo twr=0 giả).
	if not has_frame or not has_battery:
		return {"ok": false, "warnings": warnings, "stats": _empty_stats()}

	var props := DronePhysicsModel.compute_mass_properties(placed, components, drone_root)
	var twr := DronePhysicsModel.thrust_to_weight_ratio(props.motors, props.total_mass_kg)
	var weight_g: float = props.total_mass_kg / DronePhysicsModel.GRAM_TO_KG
	var thrust_kg := 0.0
	for m in props.motors:
		thrust_kg += m.max_thrust_n / DronePhysicsModel.G

	if twr < TWR_MIN_FLY:
		warnings.append(_w("critical", "thrust_insufficient", "Estimated thrust is below takeoff requirement."))
	elif twr < TWR_MIN_SAFE:
		warnings.append(_w("warning", "twr_marginal", "Thrust-to-weight ratio is marginal — flight may be unstable."))

	var current := DronePhysicsModel.get_motor_current_draw(placed, components)
	var battery_capacity_mah := DronePhysicsModel.get_battery_capacity_mah(placed, components)
	var battery_max_discharge_a := DronePhysicsModel.get_battery_max_discharge_current(placed, components) * BATTERY_C_SAFETY_MARGIN
	var hover_throttle: float = clamp(1.0 / max(twr, 0.01), HOVER_THROTTLE_FLOOR, 1.0)
	var hover_current_a: float = current.total_a * hover_throttle
	if battery_max_discharge_a > 0.0 and hover_current_a > battery_max_discharge_a:
		warnings.append(_w("critical", "battery_discharge_insufficient", "Battery discharge rate is insufficient."))

	var esc_rating_a := DronePhysicsModel.get_esc_current_rating(placed, components)
	if esc_rating_a > 0.0 and current.max_single_a > 0.0:
		var overload_ratio: float = current.max_single_a / esc_rating_a
		if overload_ratio > ESC_OVERLOAD_CRITICAL_RATIO:
			warnings.append(_w("critical", "esc_overload", "ESC may overload."))
		elif overload_ratio > ESC_OVERLOAD_WARN_RATIO:
			warnings.append(_w("warning", "esc_overload", "ESC may overload."))

	var cg_offset_ratio := _cg_offset_ratio(props.motors)
	if cg_offset_ratio > CG_OFFSET_CRITICAL_RATIO:
		warnings.append(_w("critical", "cg_offset_critical", "Center of Gravity is significantly offset."))
	elif cg_offset_ratio > CG_OFFSET_WARN_RATIO:
		warnings.append(_w("warning", "cg_offset_warning", "Center of Gravity is slightly offset — trim recommended."))

	# Flight time / payload: chỉ là số tham khảo, KHÔNG sinh warning.

	var flight_time_min := 0.0
	if hover_current_a > 0.01 and battery_capacity_mah > 0.0:
		flight_time_min = (battery_capacity_mah / 1000.0) * BATTERY_USABLE_FRACTION / hover_current_a * 60.0

	var recommended_payload_g: float = 0.0
	if thrust_kg > 0.0:
		recommended_payload_g = max(0.0, (thrust_kg * 1000.0 / TWR_GOOD) - weight_g)

	var ok := true
	for w in warnings:
		if w.severity == "critical":
			ok = false
			break

	return {
		"ok": ok,
		"warnings": warnings,
		"stats": {
			"weight_g": weight_g,
			"thrust_kg": thrust_kg,
			"twr": twr,
			"battery_capacity_mah": battery_capacity_mah,
			"flight_time_min": flight_time_min,
			"recommended_max_payload_g": recommended_payload_g,
			"total_motor_current_a": current.total_a,
			"battery_max_discharge_a": battery_max_discharge_a,
			"esc_current_rating_a": esc_rating_a,
			"cg_offset_ratio": cg_offset_ratio,
		},
	}


static func _empty_stats() -> Dictionary:
	return {
		"weight_g": 0.0, "thrust_kg": 0.0, "twr": 0.0,
		"battery_capacity_mah": 0.0, "flight_time_min": 0.0,
		"recommended_max_payload_g": 0.0, "total_motor_current_a": 0.0,
		"battery_max_discharge_a": 0.0, "esc_current_rating_a": 0.0,
		"cg_offset_ratio": 0.0,
	}


static func _w(severity: String, code: String, message: String) -> Dictionary:
	return {"severity": severity, "code": code, "message": message}


static func _cg_offset_ratio(motors: Array) -> float:
	if motors.size() < 2:
		return 0.0
	var avg_r := Vector2.ZERO
	var avg_arm := 0.0
	for m in motors:
		var r: Vector3 = m.pos
		avg_r += Vector2(r.x, r.z)
		avg_arm += Vector2(r.x, r.z).length()
	avg_r /= motors.size()
	avg_arm /= motors.size()
	if avg_arm <= 0.001:
		return 0.0
	return avg_r.length() / avg_arm
