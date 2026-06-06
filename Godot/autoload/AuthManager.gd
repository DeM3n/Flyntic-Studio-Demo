extends Node

const SUPABASE_URL  = "https://hnfbtgyaefkagwnlzphu.supabase.co"
const SESSION_PATH  = "user://session.json"
const SUPABASE_ANON_KEY = "sb_publishable_8IAEel8ebTUHXXbR8s7aZw_uCxslzEE"

signal access_granted(tier: String, tier_name: String, days_left: int)
signal access_denied(reason: String)
signal login_failed(reason: String)

var access_token  := ""
var refresh_token := ""
var user_email    := ""
var user_name     := ""

func _ready():
	if not ProjectSettings.get_setting("flyntic/url_scheme_registered", false):
		_register_url_scheme()
		ProjectSettings.set_setting("flyntic/url_scheme_registered", true)
		ProjectSettings.save()
	_load_session()

# ── Session ────────────────────────────────────────────────────────
func _save_session():
	var f = FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"access_token":  access_token,
		"refresh_token": refresh_token,
		"email":         user_email,
		"name":          user_name,
	}))
	f.close()

func _load_session():
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var f = FileAccess.open(SESSION_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data:
		access_token  = data.get("access_token", "")
		refresh_token = data.get("refresh_token", "")
		user_email    = data.get("email", "")
		user_name     = data.get("name", "")

func has_session() -> bool:
	return access_token != ""

func logout():
	access_token  = ""
	refresh_token = ""
	user_email    = ""
	user_name     = ""
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(SESSION_PATH)
	get_tree().change_scene_to_file("res://Auth/Login.tscn")

# ── Login ──────────────────────────────────────────────────────────
func login(email: String, password: String):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_done, CONNECT_ONE_SHOT)
	http.request_completed.connect(func(_r,_c,_h,_b): http.queue_free(), CONNECT_ONE_SHOT)

	http.request(
		SUPABASE_URL + "/functions/v1/login",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": email, "password": password})
	)

func _on_login_done(_result, _code, _headers, body):
	
	#print("HTTP code: ", _code)
	#print("Body: ", body.get_string_from_utf8())
	print("=== _on_login_done called")

	var data = JSON.parse_string(body.get_string_from_utf8())
	print("=== parsed data: ", data)
	print("=== success field: ", data.get("success", "KEY NOT FOUND") if data else "data is NULL")
	if data == null or not data.get("success", false):
		emit_signal("login_failed", data.get("reason", "Login failed"))
		return
	access_token  = data.get("access_token", "")
	refresh_token = data.get("refresh_token", "")
	user_email    = data.get("email", "")
	user_name     = data.get("name", "")
	_save_session()
	check_license()
	#if AuthManager.has_session():
		#AuthManager.check_license_cached()

# ── Check license ──────────────────────────────────────────────────
func check_license():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_license_done, CONNECT_ONE_SHOT)
	http.request_completed.connect(func(_r,_c,_h,_b): http.queue_free(), CONNECT_ONE_SHOT)
	http.request(
		SUPABASE_URL + "/functions/v1/check-license",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + access_token
		],
		HTTPClient.METHOD_POST, "{}"
	)

func _on_license_done(_result, code, _headers, body):
	print("=== _on_license_done called, code: ", code)
	print("=== body: ", body.get_string_from_utf8())
	if code == 429:
		emit_signal("access_denied", "Too many request please try again")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		emit_signal("access_denied", "Error server")
		return
	if data.get("allowed", false):
		# Lưu vào session kèm server_time
		_save_session_with_license(data)
		emit_signal("access_granted",
			data.get("tier", ""),
			data.get("tier_name", ""),
			int(data.get("days_left", 0))
		)
	else:
		match data.get("reason", ""):
			"invalid_token": logout()
			"too_many_requests": emit_signal("access_denied", "Try again")
			_: emit_signal("access_denied", data.get("reason", "expired"))

func _save_session_with_license(license_data: Dictionary):
	var f = FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"access_token":   access_token,
		"refresh_token":  refresh_token,
		"email":          user_email,
		"name":           user_name, 
		"license_type":   license_data.get("tier", ""),
		"license_tier":   license_data.get("tier_name", ""),
		"days_left":      license_data.get("days_left", 0),
		"server_time":    license_data.get("server_time", ""),
		"cached_at":      Time.get_unix_time_from_system(),
	}))
	f.close()

signal trial_offer(already_claimed: bool)

func claim_trial():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_claim_done, CONNECT_ONE_SHOT)
	http.request_completed.connect(func(_r,_c,_h,_b): http.queue_free(), CONNECT_ONE_SHOT)
	http.request(
		SUPABASE_URL + "/functions/v1/claim-trial",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + access_token
		],
		HTTPClient.METHOD_POST, "{}"
	)

func _on_claim_done(_r, _c, _h, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data.get("success", false):
		# Claim xong → check license lại
		check_license()
	else:
		emit_signal("access_denied", data.get("reason", ""))

# Trong AuthManager hoặc Main — chạy 1 lần khi install
func _register_url_scheme():
	var exe_path = OS.get_executable_path().replace("/", "\\")
	var commands = [
		"reg add \"HKCU\\Software\\Classes\\flyntic\" /ve /d \"URL:Flyntic Protocol\" /f",
		"reg add \"HKCU\\Software\\Classes\\flyntic\" /v \"URL Protocol\" /d \"\" /f",
		"reg add \"HKCU\\Software\\Classes\\flyntic\\shell\\open\\command\" /ve /d \"\\\"%s\\\" \\\"%%1\\\"\" /f" % exe_path
	]
	for cmd in commands:
		OS.execute("cmd", ["/c", cmd])

func login_with_token(otp: String):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_redeem_done, CONNECT_ONE_SHOT)
	http.request_completed.connect(func(_r,_c,_h,_b): http.queue_free(), CONNECT_ONE_SHOT)
	http.request(
		SUPABASE_URL + "/rest/v1/rpc/redeem_deep_link_token",
		[
			"Content-Type: application/json",
			"apikey: " + SUPABASE_ANON_KEY
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({"otp": otp})
	)

func _on_redeem_done(_r, _code, _h, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or not data.get("success", false):
		emit_signal("login_failed", "Session expired, please register again")
		return
	access_token  = data.get("access_token", "")
	refresh_token = data.get("refresh_token", "")
	_save_session()
	check_license()
const CACHE_TTL_SECONDS = 3600  # cache 1 tiếng

func check_license_cached():
	print("=== check_license_cached() CALLED ===")
	# Đọc cache từ session
	if not FileAccess.file_exists(SESSION_PATH):
		print("[License] Không có session file → gọi API")
		check_license()
		return
	var f = FileAccess.open(SESSION_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data == null:
		print("[License] Parse session thất bại → gọi API")
		check_license()
		return
	
	var cached_at = data.get("cached_at", 0)
	var now = Time.get_unix_time_from_system()
	var age = now - cached_at
	print("[License] Cache age: %.0f giây / TTL: %d giây" % [age, CACHE_TTL_SECONDS])
	# Cache còn hạn và có license hợp lệ
	if age < CACHE_TTL_SECONDS and data.get("license_type", "") != "":
		print("[License] ✓ Dùng cache — tier: %s, còn %d ngày" % [
			data.get("license_tier", ""),
			int(data.get("days_left", 0))
		])
		emit_signal("access_granted",
			data.get("license_type", ""),
			data.get("license_tier", ""),
			int(data.get("days_left", 0))
		)
		# Background refresh không chặn UI
		_refresh_license_background()
		print("[License] → Background refresh...")
	else:
		# Cache hết hạn → gọi API bình thường
		print("[License] ✗ Cache hết hạn hoặc không có license → gọi API")
		check_license()

func _refresh_license_background():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, code, _h, body):
		http.queue_free()
		if code != 200:
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data and data.get("allowed", false):
			_save_session_with_license(data)
	, CONNECT_ONE_SHOT)
	http.request(
		SUPABASE_URL + "/functions/v1/check-license",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + access_token
		],
		HTTPClient.METHOD_POST, "{}"
	)
