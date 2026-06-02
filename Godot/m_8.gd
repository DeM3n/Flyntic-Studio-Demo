extends Button

@onready var popup: PopupMenu = $HelpPopup
var _popup_open := false
var _just_closed := false

func _ready():
	popup.popup_hide.connect(_on_popup_hide)
	pressed.connect(_on_button_pressed)
	
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

func _on_button_pressed():
	print("=== Button pressed, _just_closed=", _just_closed, " _popup_open=", _popup_open)
	if _just_closed:
		print("→ Bỏ qua vì vừa tự đóng")
		return
	
	popup.position = global_position + Vector2(0, size.y + 4)
	popup.popup()
	_popup_open = true

func _on_popup_hide():
	print("Popup đã đóng")
	_popup_open = false
	_just_closed = true
	await get_tree().create_timer(0.15).timeout
	_just_closed = false

func _on_item_selected(id: int):
	var item_text = popup.get_item_text(id)
	print("Bạn đã chọn: ", item_text)
	popup.hide()
