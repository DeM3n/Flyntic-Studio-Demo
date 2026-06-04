extends Node

const SUPABASE_URL  = "https://hnfbtgyaefkagwnlzphu.supabase.co"
const SESSION_PATH  = "user://session.json"

signal access_granted(tier: String, tier_name: String, days_left: int)
signal access_denied(reason: String)
signal login_failed(reason: String)

var access_token  := ""
var refresh_token := ""
var user_email    := ""
var user_name     := ""

func _ready():
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
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")

# ── Login ──────────────────────────────────────────────────────────
func login(email: String, password: String):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_done)
	http.request(
		SUPABASE_URL + "/functions/v1/login",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": email, "password": password})
	)

func _on_login_done(_result, _code, _headers, body):
	print("HTTP code: ", _code)
	print("Body: ", body.get_string_from_utf8())

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or not data.get("success", false):
		emit_signal("login_failed", data.get("reason", "Login failed"))
		return
	access_token  = data.get("access_token", "")
	refresh_token = data.get("refresh_token", "")
	user_email    = data.get("email", "")
	user_name     = data.get("name", "")
	_save_session()
	check_license()

# ── Check license ──────────────────────────────────────────────────
func check_license():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_license_done)
	http.request(
		SUPABASE_URL + "/functions/v1/check-license",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + access_token
		],
		HTTPClient.METHOD_POST, "{}"
	)

func _on_license_done(_result, code, _headers, body):
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
		"license_type":   license_data.get("type", ""),
		"license_tier":   license_data.get("tier", ""),
		"days_left":      license_data.get("days_left", 0),
		"server_time":    license_data.get("server_time", ""),
		"cached_at":      Time.get_unix_time_from_system(),
	}))
	f.close()

signal trial_offer(already_claimed: bool)

func claim_trial():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_claim_done)
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
