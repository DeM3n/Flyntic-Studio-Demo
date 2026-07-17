class_name DroneSimulationRuntime
extends Node

## Toàn bộ logic mô phỏng bay: trạng thái sim, physics bridge lifecycle,
## kinematic fallback, preflight check, và hệ thống ESC burnout (Phase 4).
##
## Được add làm CHILD NODE của Main.gd (ví dụ $SimulationRuntime trong scene).
## Không tự query scene tree ngoài những gì được set qua các biến/setter bên dưới --
## mọi thứ khác (placed, drone_root, sim_label...) đều do Main.gd cấp vào.
##
## QUAN TRỌNG: drone_root có thể bị tạo lại/null hóa ở NHIỀU chỗ trong Main.gd
## (đặt Frame mới, xóa Frame, Clear All, load project...) -- Main.gd PHẢI gọi
## set_drone_root() mỗi khi giá trị đó đổi, không chỉ set 1 lần lúc _ready().

# ──────────────────────── EXTERNAL REFERENCES (Main.gd gán vào) ────────
var placed: Array[Dictionary] = []   # SHARED reference với Main.gd -- Main.gd chỉ được append/erase/clear, KHÔNG reassign toàn bộ mảng
var drone_root: Node3D = null        # đồng bộ qua set_drone_root(), không gán trực tiếp từ ngoài
var sim_label: Label = null
var topbar_status: Label = null
var components_group: Node3D = null

signal ui_lock_requested(locked: bool)
signal log_requested(msg: String, type: String)

# ──────────────────────── SIM STATE ─────────────────────────────────────
var sim_state := "stopped"  # stopped | playing | paused
var sim_time := 0.0
var sim_sequence: Array[Dictionary] = []
var sim_step_idx := 0
var sim_step_timer := 0.0
var sim_target_pos := Vector3.ZERO
var sim_target_rot := Vector3.ZERO
var sim_current_speed_mult := 1.0
var sim_step_distance_traveled := 0.0

# ──────────────────────── BRIDGE STATE ──────────────────────────────────
var bridge: Node = null
var bridge_connected := false
var use_bridge_physics := true  # Set false để ép kinematic fallback

# ──────────────────────── ESC BURNOUT STATE (Phase 4 -- MỚI) ────────────
var esc_heat := 0.0
var esc_burned_out := false
var esc_burnout_tumble := Vector3.ZERO

const ESC_HEAT_MAX := 100.0
const ESC_HEAT_GAIN_RATE := 20.0    # tốc độ nóng lên khi overload_severity = 1.0 (quá tải nặng nhất)
const ESC_HEAT_COOL_RATE := 10.0    # tốc độ nguội khi an toàn -- CHẬM HƠN tốc độ nóng, chủ đích
const ESC_BURNOUT_THRESHOLD := 100.0

signal preflight_result(report: Dictionary)   # cạnh 2 signal có sẵn


# ══════════════════════════ SETUP / SYNC ═══════════════════════════════

## Gọi mỗi khi Main.gd tạo/null drone_root: trong _place() lúc Frame được đặt,
## trong _remove_component() lúc Frame bị xóa, và trong _clear_all().
func set_drone_root(root: Node3D) -> void:
	drone_root = root


## Gọi 1 lần trong Main.gd._ready(). Tự tạo bridge node làm child của chính
## Runtime này (không phải child của Main.gd) -- toàn bộ vòng đời bridge
## giờ nằm gọn trong 1 module.
func init_bridge() -> void:
	var bridge_script = load("res://PhysicsBridge.gd")
	if bridge_script == null:
		log_requested.emit("PhysicsBridge.gd not found — kinematic mode only", "warning")
		return
	bridge = Node.new()
	bridge.set_script(bridge_script)
	bridge.name = "PhysicsBridge"
	add_child(bridge)
	bridge.bridge_connected.connect(_on_bridge_connected)
	bridge.bridge_disconnected.connect(_on_bridge_disconnected)
	bridge.state_received.connect(_on_bridge_state)
	log_requested.emit("Physics bridge initialized — connecting to TCP server...", "info")


func _on_bridge_connected() -> void:
	bridge_connected = true
	log_requested.emit("Bridge: Connected (" + bridge.bridge_mode + " mode)", "success")


func _on_bridge_disconnected() -> void:
	bridge_connected = false
	log_requested.emit("Bridge: Disconnected — using kinematic fallback", "warning")


func _bridge_active() -> bool:
	return bridge != null and bridge_connected and is_instance_valid(bridge)


## Gọi khi build/rebuild drone mới (New/Load project, Clear All) --
## nếu không, esc_heat/esc_burned_out sẽ mang theo từ phiên bay trước
## sang drone mới, dù cấu hình mới có đúng hay không.
func reset_esc_heat() -> void:
	esc_heat = 0.0
	esc_burned_out = false
	esc_burnout_tumble = Vector3.ZERO


# ══════════════════════════ PLAY / PAUSE / STOP ═════════════════════════

## sequence: Array[Dictionary] đã được Main.gd parse sẵn từ Block Editor UI
## (qua _parse_block_stack_into). Runtime CHỈ nhận data thô, không biết gì
## về Panel/workspace của Block Editor -- giữ ranh giới sạch giữa 2 module.
func start(sequence: Array[Dictionary]) -> void:
	var report := PreflightValidator.run(get_in_drone_placed(), ComponentFactory.COMPONENTS, drone_root)
	preflight_result.emit(report)
	for w in report.warnings:
		log_requested.emit(w.message, "error" if w.severity == "critical" else "warning")
	if not report.ok:
		log_requested.emit("Preflight check failed — takeoff aborted.", "error")
		if sim_label: sim_label.text = "Preflight Failed"
		if topbar_status: topbar_status.text = "preflight_failed"
		return
	sim_sequence = sequence
	sim_state = "playing"
	sim_time = 0.0
	sim_step_idx = 0
	sim_step_timer = 0.0
	sim_target_pos = Vector3.ZERO
	sim_target_rot = Vector3.ZERO
	if sim_label: sim_label.text = "Flying..."
	if topbar_status: topbar_status.text = "playing"

	if _bridge_active():
		var tw := 0.0
		var tt := 0.0
		var motor_with_prop_count := 0
		var prop_parents = []
		for c in placed:
			if c.type == "Propeller":
				prop_parents.append(c.parent_id)
		for c in placed:
			var d = ComponentFactory.COMPONENTS[c.id]
			tw += d.weight
			tt += d.thrust
			if d.type == "Motor" and c.uid in prop_parents:
				motor_with_prop_count += 1
		# NOTE: giữ nguyên hành vi gốc -- UI chỉ bị lock khi bridge active,
		# kinematic-only play KHÔNG lock UI. Đây là behavior cũ, giữ nguyên
		# chứ không tự sửa; nếu đây là thiếu sót thì cần bàn riêng.
		ui_lock_requested.emit(true)
		bridge.cmd_set_drone(tw / 1000.0, motor_with_prop_count, tt / 1000.0 * 9.81)
		bridge.cmd_arm()
		log_requested.emit("Bridge: Drone configured (%.0fg, %d functional motors) & armed" % [tw, motor_with_prop_count], "info")


func pause() -> void:
	if sim_state == "playing":
		sim_state = "paused"
		if sim_label: sim_label.text = "Paused"
		if topbar_status: topbar_status.text = "paused"


func stop() -> void:
	sim_state = "stopped"
	if sim_label: sim_label.text = "Ready"
	if topbar_status: topbar_status.text = "stopped"
	if drone_root:
		drone_root.rotation = Vector3.ZERO
		drone_root.position = Vector3.ZERO
	sim_step_idx = 0
	if _bridge_active():
		bridge.cmd_stop()
		log_requested.emit("Bridge: Simulation stopped & reset", "info")
	ui_lock_requested.emit(false)

func _is_in_drone(node: Node) -> bool:
	if drone_root == null:
		return false
	var n = node
	while n != null:
		if n == drone_root:
			return true
		n = n.get_parent()
	return false
# ══════════════════════════ PER-FRAME TICK ══════════════════════════════

## Gọi từ Main.gd._physics_process() khi sim_state == "playing".
## check: kết quả preflight_check() -- Main.gd tự gọi sim_runtime.preflight_check()
## rồi truyền vào, để tick() không phải tính lại hoặc biết thêm gì khác.
func tick(delta: float, check: Dictionary) -> void:
	sim_time += delta

	if sim_state == "playing" and not esc_burned_out:
		var bridge_rpms = []
		if _bridge_active():
			bridge_rpms = bridge.get_motor_rpms()

		var motor_uids := {}
		for comp in placed:
			if comp.get("type", "") == "Motor":
				motor_uids[comp.get("uid", -1)] = true

		var prop_idx := 0
		for comp in placed:
			if comp.get("type", "") != "Propeller":
				continue
			if not motor_uids.has(comp.get("parent_id", -1)):
				continue  # chưa gắn vào motor nào
			if not is_instance_valid(comp.get("node")):
				continue
			if not _is_in_drone(comp.node):
				continue  # MỚI: gắn đúng vào motor, nhưng cả cụm chưa thuộc về drone thật

			var blades: Array = []
			_collect_group_nodes(comp.node, "prop_blade", blades)
			if not blades.is_empty():
				var spin_speed := 35.0
				if prop_idx < bridge_rpms.size() and bridge_rpms[prop_idx] > 0:
					spin_speed = bridge_rpms[prop_idx] / 150.0
				for blade in blades:
					blade.rotation.y += delta * spin_speed
			prop_idx += 1

	if esc_burned_out:
		_simulate_kinematic(delta, check)
		return

	if check.capability == "Cannot fly" and not _bridge_active():
		if components_group:
			components_group.position.y = lerp(components_group.position.y, 0.0, 0.08)
		return

	if _bridge_active() and use_bridge_physics:
		_simulate_bridge(delta)
		return

	_simulate_kinematic(delta, check)

func _collect_group_nodes(node: Node, group_name: String, results: Array) -> void:
	if node.is_in_group(group_name):
		results.append(node)
	for child in node.get_children():
		_collect_group_nodes(child, group_name, results)


func _simulate_bridge(delta: float) -> void:
	if sim_state == "playing" and sim_step_idx < sim_sequence.size():
		var step = sim_sequence[sim_step_idx]
		sim_step_timer += delta
		if sim_step_timer <= delta * 2:
			match step.type:
				"take_off":
					bridge.cmd_takeoff(2.5)
					log_requested.emit("Bridge → Takeoff to 2.5m", "info")
				"forward":
					var speed = step.value * 0.05 / step.duration
					var fwd = -components_group.global_transform.basis.z.normalized()
					fwd.y = 0; fwd = fwd.normalized()
					bridge.cmd_move(fwd.x * speed, 0.0, fwd.z * speed)
					log_requested.emit("Bridge → Move forward %.1f cm (%.2f m/s)" % [step.value, speed], "info")
				"hover":
					bridge.cmd_hover()
					log_requested.emit("Bridge → Hover", "info")
				"land":
					bridge.cmd_land()
					log_requested.emit("Bridge → Land", "info")

		if sim_step_timer >= step.duration:
			sim_step_idx += 1
			sim_step_timer = 0.0
			if sim_step_idx < sim_sequence.size():
				log_requested.emit("Step " + str(sim_step_idx + 1) + ": Executing " + sim_sequence[sim_step_idx].type, "info")
			else:
				bridge.cmd_hover()
				log_requested.emit("Program finished — hovering", "success")
				if sim_label: sim_label.text = "Finished"


## Main.gd nối bridge.state_received tới đây qua init_bridge() -- không cần
## Main.gd làm gì thêm, kết nối tự động lúc bridge được tạo.
func _on_bridge_state(state: Dictionary) -> void:
	if sim_state != "playing" and sim_state != "paused":
		return
	var pos_arr = state.get("pos", [0, 0, 0])
	var rot_arr = state.get("rot", [0, 0, 0, 1])
	var target_pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
	components_group.position = components_group.position.lerp(target_pos, 0.3)
	var quat = Quaternion(rot_arr[0], rot_arr[1], rot_arr[2], rot_arr[3])
	var target_euler = quat.get_euler()
	components_group.rotation = components_group.rotation.lerp(target_euler, 0.3)
	var status_text = state.get("status", "unknown")
	if sim_state == "playing" and sim_label:
		sim_label.text = status_text.capitalize()


func _get_flight_params() -> Dictionary:
	if drone_root == null or placed.is_empty():
		return {"speed": 1.0, "climb": 0.05, "responsiveness": 0.1, "accel_response": 0.1, "esc_factor": 1.0}

	var props = DronePhysicsModel.compute_mass_properties(placed, ComponentFactory.COMPONENTS, drone_root)
	var twr = DronePhysicsModel.thrust_to_weight_ratio(props.motors, props.total_mass_kg)

	# TWR 2.0 = mức chuẩn (baseline), drone vừa đủ bay ổn
	# TWR 4.0+ = motor rất khỏe, bay nhanh
	# TWR < 2.0 = cận giới hạn bay, rất chậm
	var speed_factor := clampf(twr / 2.0, 0.3, 3.0)

	var voltage := DronePhysicsModel.get_battery_voltage(placed, ComponentFactory.COMPONENTS)
	var avg_kv := DronePhysicsModel.average_motor_kv(props.motors)
	var mismatch_factor := DronePhysicsModel.get_kv_mismatch_factor(props.motors)
	var rpm_ref := 1500.0 * 14.8  # baseline: 1500KV @ 4S
	var kv_factor: float = clamp((avg_kv * voltage) / rpm_ref, 0.4, 2.0)
	var esc_factor := DronePhysicsModel.get_esc_overload_factor(placed, ComponentFactory.COMPONENTS)

	return {
		"speed": speed_factor * mismatch_factor * esc_factor,
		"climb": 0.03 * speed_factor * mismatch_factor * esc_factor,
		"responsiveness": clamp(0.05 * kv_factor, 0.02, 0.15),
		"accel_response": clamp(0.08 * kv_factor, 0.03, 0.25),
		"esc_factor": esc_factor,  # MỚI: burnout dùng lại, khỏi tính 2 lần
	}


## Mỗi frame: esc_factor < 1.0 -> nóng dần. An toàn -> nguội dần, CHẬM HƠN
## tốc độ nóng (COOL_RATE < GAIN_RATE) -- quá tải xong không "tha" ngay.
func _update_esc_heat(delta: float, esc_factor: float) -> void:
	if esc_burned_out:
		return
	if esc_factor < 1.0:
		var overload_severity := 1.0 - esc_factor
		esc_heat += overload_severity * ESC_HEAT_GAIN_RATE * delta
	else:
		esc_heat = max(0.0, esc_heat - ESC_HEAT_COOL_RATE * delta)
	esc_heat = min(esc_heat, ESC_HEAT_MAX)
	if esc_heat >= ESC_BURNOUT_THRESHOLD:
		_trigger_esc_burnout()


## Chọn 1 hướng xoay ngẫu nhiên GIỮ NGUYÊN cho tới hết session -- cảm giác
## mất kiểm soát nhất quán, không đổi hướng lung tung mỗi frame.
func _trigger_esc_burnout() -> void:
	esc_burned_out = true
	esc_burnout_tumble = Vector3(
		randf_range(-4.0, 4.0),
		randf_range(-2.0, 2.0),
		randf_range(-4.0, 4.0)
	)
	log_requested.emit("🔥 ESC CHÁY! Quá tải kéo dài vượt ngưỡng chịu đựng — drone mất kiểm soát và rơi.", "error")
	if sim_label:
		sim_label.text = "BURNED OUT"


func _simulate_kinematic(delta: float, check: Dictionary) -> void:
	if drone_root == null: return

	var fp = _get_flight_params()
	_update_esc_heat(delta, fp.esc_factor)

	if esc_burned_out:
		# ESC đã cháy -- rơi tự do + xoay tán loạn, bỏ qua toàn bộ sequence/logic bay bình thường
		var crash_target := drone_root.position
		crash_target.y = 0.0
		drone_root.position = drone_root.position.lerp(crash_target, 0.06)
		drone_root.rotation += esc_burnout_tumble * delta
		return

	if sim_state == "playing" and sim_step_idx < sim_sequence.size():
		var step = sim_sequence[sim_step_idx]
		sim_step_timer += delta

		var step_finished := false

		match step.type:
			"take_off":
				sim_target_pos.y = 2.5
				step_finished = sim_step_timer >= step.duration
			"forward":
				var target_dist = step.value * 0.05  # cm -> Godot units, CỐ ĐỊNH
				if sim_step_timer <= delta:
					sim_step_distance_traveled = 0.0
					sim_current_speed_mult = 0.0
					log_requested.emit("▶ Forward bắt đầu | dist: %.0f cm | speed_factor: %.2f" % [step.value, fp.speed], "info")
				sim_current_speed_mult = lerp(sim_current_speed_mult, 1.0, fp.accel_response)
				var base_speed := 1.0  # units/s ở speed_factor = 1.0 — tune lại theo cảm giác bay
				var move_step: float = base_speed * fp.speed * sim_current_speed_mult * delta
				move_step = min(move_step, target_dist - sim_step_distance_traveled)

				var forward_dir = -drone_root.global_transform.basis.z
				forward_dir.y = 0
				forward_dir = forward_dir.normalized()

				sim_target_pos += forward_dir * move_step
				sim_step_distance_traveled += move_step
				if sim_target_pos.y < 2.0: sim_target_pos.y = 2.5

				step_finished = sim_step_distance_traveled >= target_dist - 0.001
				if step_finished:
					log_requested.emit("✔ Forward xong | dist: %.0f cm | thời gian thực tế: %.2f s" % [step.value, sim_step_timer], "success")
			"hover":
				step_finished = sim_step_timer >= step.duration
			"land":
				if sim_step_timer <= delta:
					sim_current_speed_mult = 0.0
					log_requested.emit("▶ Landing bắt đầu | speed_factor: %.2f" % fp.speed, "info")
				sim_current_speed_mult = lerp(sim_current_speed_mult, 1.0, fp.accel_response)

				var descent_speed: float = 1.5 * float(fp.speed) * sim_current_speed_mult
				sim_target_pos.y = max(0.0, sim_target_pos.y - descent_speed * delta)

				var reached_ground: bool = sim_target_pos.y <= 0.001
				var timed_out: bool = sim_step_timer >= float(step.duration)
				step_finished = reached_ground or timed_out
				if timed_out and not reached_ground:
					sim_target_pos.y = 0.0
				if step_finished:
					log_requested.emit("✔ Landing xong | %.2f s" % sim_step_timer, "success")

		if step_finished:
			sim_step_idx += 1
			sim_step_timer = 0.0
			sim_step_distance_traveled = 0.0
			if sim_step_idx < sim_sequence.size():
				log_requested.emit("Step " + str(sim_step_idx + 1) + ": Executing " + sim_sequence[sim_step_idx].type, "info")
			else:
				log_requested.emit("Program finished", "success")
				if sim_label: sim_label.text = "Finished"

	var final_target = sim_target_pos
	if check.capability == "Cannot fly":
		final_target.y = 0.0
	drone_root.position = drone_root.position.lerp(final_target, fp.climb)

	var displacement = (sim_target_pos - drone_root.position)
	var dynamic_pitch = clamp(displacement.z * 0.3, -0.3, 0.3)
	var dynamic_roll  = clamp(-displacement.x * 0.3, -0.3, 0.3)

	var tilt_x = check.tilt_x * 0.2 + dynamic_pitch + sin(sim_time * 1.5) * 0.01
	var tilt_z = check.tilt_z * 0.2 + dynamic_roll  + cos(sim_time * 1.5) * 0.01

	drone_root.rotation.x = lerp(drone_root.rotation.x, tilt_x, fp.responsiveness)
	drone_root.rotation.z = lerp(drone_root.rotation.z, tilt_z, fp.responsiveness)


func preflight_check() -> Dictionary:
	var motors_with_props = []
	var has_frame := false
	var has_battery := false

	for c in placed:
		var c_type = c["type"]
		if c_type == "Frame": has_frame = true
		elif c_type == "Battery": has_battery = true
		elif c_type == "Motor":
			# MỚI: motor lắp rời (chưa thuộc về drone_root) thì bỏ qua hoàn toàn,
			# không tính dù nó có gắn propeller đúng cách hay không.
			if not is_instance_valid(c.get("node")) or not _is_in_drone(c.node):
				continue
			var has_p := false
			for p in placed:
				if p.parent_id == c.uid and p.type == "Propeller":
					# MỚI: check thêm cả propeller, phòng trường hợp parent_id đúng
					# nhưng node thật sự lại không nằm trong cây con drone (hiếm, nhưng rẻ để chặn).
					if is_instance_valid(p.get("node")) and _is_in_drone(p.node):
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
	var total_lift := motors_with_props.size()
	var torque_x := 0.0
	var torque_z := 0.0

	for m in motors_with_props:
		if is_instance_valid(m.node):
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

## Lọc `placed` chỉ giữ component thực sự thuộc drone_root hiện tại — dùng
## chung cho cả preflight gate (start) lẫn dashboard live-update (Main._update_all).
func get_in_drone_placed() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in placed:
		if is_instance_valid(c.get("node")) and _is_in_drone(c.node):
			result.append(c)
	return result
