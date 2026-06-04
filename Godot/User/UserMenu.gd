extends HBoxContainer

func _ready():
	var menu_btn = MenuButton.new()
	
	var display = AuthManager.user_name if AuthManager.user_name != "" else AuthManager.user_email
	menu_btn.text = "👤 " + display
	menu_btn.flat = false
	
	var popup = menu_btn.get_popup()
	popup.add_item("Logout", 0)
	popup.id_pressed.connect(_on_user_menu_pressed)
	
	add_child(menu_btn)

func _on_user_menu_pressed(id: int):
	match id:
		0: AuthManager.logout()
