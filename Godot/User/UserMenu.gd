extends HBoxContainer
func _make_white_icon(path: String) -> ImageTexture:
	var image = Image.load_from_file(path)
	for x in image.get_width():
		for y in image.get_height():
			var pixel = image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1, 1, 1, pixel.a))
	return ImageTexture.create_from_image(image)
func _ready():
	var menu_btn = MenuButton.new()
	
	var display = AuthManager.user_name if AuthManager.user_name != "" else AuthManager.user_email

	menu_btn.text = " " + display

	menu_btn.icon = _make_white_icon("res://Assets/user.png") 


	menu_btn.flat = false
	var font = load("res://Assets/Fonts/OpenSans-SemiBold.ttf")  # đổi path cho đúng
	menu_btn.add_theme_font_override("font", font)
	menu_btn.add_theme_font_size_override("font_size", 12)
	print(menu_btn.get_theme_font("font"))
	print(menu_btn.get_theme_font_size("font_size"))
	var popup = menu_btn.get_popup()
	popup.add_theme_font_override("font", font)
	popup.add_theme_font_size_override("font_size", 12)
	popup.add_item("Logout", 0)
	popup.id_pressed.connect(_on_user_menu_pressed)
	
	add_child(menu_btn)

func _on_user_menu_pressed(id: int):
	match id:
		0: AuthManager.logout()
