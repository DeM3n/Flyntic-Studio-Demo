extends Control
class_name DockDropOverlay

## Overlay vẽ đè lên DockLeaf đang được kéo-thả qua, hiển thị 5 vùng:
## top / bottom / left / right / center. DockManager set_hover_zone() để
## highlight đúng vùng theo vị trí con trỏ.

var hover_zone: String = ""

func set_hover_zone(zone: String) -> void:
	if hover_zone != zone:
		hover_zone = zone
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.2, 0.5, 1.0, 0.07))
	var zones := zone_rects(size)
	for zone_name in zones.keys():
		var a := 0.55 if zone_name == hover_zone else 0.16
		draw_rect(zones[zone_name], Color(0.25, 0.6, 1.0, a))
	draw_rect(r, Color(0.25, 0.6, 1.0, 0.6), false, 2.0)

## Trả về dictionary {zone_name: Rect2} dựa trên kích thước leaf (local space).
static func zone_rects(rect_size: Vector2) -> Dictionary:
	var w := rect_size.x
	var h := rect_size.y
	var cw := w * 0.25
	var ch := h * 0.25
	return {
		"top": Rect2(Vector2(w * 0.25, 0), Vector2(w * 0.5, ch)),
		"bottom": Rect2(Vector2(w * 0.25, h - ch), Vector2(w * 0.5, ch)),
		"left": Rect2(Vector2(0, 0), Vector2(cw, h)),
		"right": Rect2(Vector2(w - cw, 0), Vector2(cw, h)),
		"center": Rect2(Vector2(w * 0.25, h * 0.25), Vector2(w * 0.5, h * 0.5)),
	}

## Xác định vùng nào chứa local_pos (ưu tiên center trước).
static func zone_at(local_pos: Vector2, rect_size: Vector2) -> String:
	var zones := zone_rects(rect_size)
	for zone_name in ["center", "top", "bottom", "left", "right"]:
		if zones[zone_name].has_point(local_pos):
			return zone_name
	return "center"
