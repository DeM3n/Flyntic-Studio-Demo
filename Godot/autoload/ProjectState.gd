# ProjectState.gd
extends Node
var pending_path: String = ""
var pending_name: String = ""
var user_email: String = ""   
var tier_name: String = "" 
var user_name: String =""
var open_window_count: int = 0

# --- Config persistence ---
const CONFIG_PATH = "user://flyntic_config.cfg"

func is_tutorial_seen() -> bool:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return false
	return config.get_value("prefs", "tutorial_seen", false)

func mark_tutorial_seen():
	var config = ConfigFile.new()
	config.load(CONFIG_PATH)  # load trước để không ghi đè data cũ
	config.set_value("prefs", "tutorial_seen", true)
	config.save(CONFIG_PATH)
