extends Control
class_name CanvasEditBridge

func _get_main() -> Node:
	var m = get_tree().get_first_node_in_group("main_controller")
	print(">>> CanvasEditBridge._get_main() = ", m)
	return m

func copy_selected() -> void:
	var m = _get_main()
	if m and m.has_method("canvas_copy_selected"):
		print(">>> gọi canvas_copy_selected")
		m.canvas_copy_selected()
	else:
		print(">>> KHÔNG gọi được, m=", m, " has_method=", m.has_method("canvas_copy_selected") if m else "N/A")
func paste() -> void:
	var m = _get_main()
	if m and m.has_method("canvas_paste"):
		m.canvas_paste()

func delete_selected() -> void:
	var m = _get_main()
	if m and m.has_method("canvas_delete_selected"):
		m.canvas_delete_selected()

func select_all() -> void:
	var m = _get_main()
	if m and m.has_method("canvas_select_all"):
		m.canvas_select_all()
