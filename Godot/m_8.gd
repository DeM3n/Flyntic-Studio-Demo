extends Button

@onready var popup: PopupMenu = $HelpPopup

var is_busy := false

func _ready():
	popup.popup_hide.connect(_on_popup_hide)
	
	if popup.get_item_count() == 0:
		popup.add_item("Welcome")
		popup.add_item("Show All Commands")
		popup.add_item("Editor Playground")
		popup.add_item("Open Walkthrough...")
		popup.add_item("Provide Feedback")
		popup.add_separator()
		popup.add_item("View License")
		popup.add_item("Toggle Developer Tools")
		popup.add_item("Open Process Explorer")
		popup.add_item("Download Update")
		popup.add_separator()
		popup.add_item("About")
	
	popup.id_pressed.connect(_on_item_selected)
	pressed.connect(_on_button_pressed)

func _on_button_pressed():
	if is_busy:
		print("→ Bỏ qua click thừa")
		return
	
	is_busy = true
	print("Button pressed - Visible:", popup.visible)
	
	if popup.visible:
		print("→ Đang đóng popup")
		popup.hide()
	else:
		print("→ Đang mở popup")
		popup.position = global_position + Vector2(0, size.y + 4)
		popup.popup()
	
	# Chặn click trong 0.3 giây
	await get_tree().create_timer(0.3).timeout
	is_busy = false

func _on_item_selected(id: int):
	var item_text = popup.get_item_text(id)
	print("Bạn đã chọn: ", item_text)
	popup.hide()

func _on_popup_hide():
	print("Popup đã đóng")
