extends Node2D

var mp: MatchPlayer = null
var has_ball: bool = false
var selected: bool = false


func setup(p: MatchPlayer) -> void:
	mp = p
	queue_redraw()


func update_state(ball: bool, sel: bool) -> void:
	has_ball = ball
	selected = sel
	queue_redraw()


func _draw() -> void:
	if mp == null:
		return
	var col := Color("3a7bd5") if mp.team == 0 else Color("d5493a")
	if mp.is_gk:
		col = Color("e0a21a") if mp.team == 0 else Color("8e44ad")
	draw_circle(Vector2.ZERO, 22.0, col)
	var ring := Color.YELLOW if selected else Color.WHITE
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, ring, 3.0 if selected else 2.0)
	var font := ThemeDB.fallback_font
	var label := mp.data.pname.get_slice(" ", 0).left(3).to_upper()
	draw_string(font, Vector2(-22.0, 5.0), label, HORIZONTAL_ALIGNMENT_CENTER, 44.0, 14, Color.WHITE)
	if mp.data.is_captain:
		draw_string(font, Vector2(-22.0, -26.0), "C", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 12, Color.YELLOW)
	if mp.fallen > 0:
		draw_string(font, Vector2(-22.0, -26.0), "caído", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 11, Color.ORANGE)
	var ratio := clampf(mp.vig / maxf(mp.vig_max, 1.0), 0.0, 1.0)
	draw_rect(Rect2(-22.0, 27.0, 44.0, 5.0), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-22.0, 27.0, 44.0 * ratio, 5.0), Color.RED.lerp(Color.GREEN_YELLOW, ratio))
	if has_ball:
		draw_circle(Vector2(20.0, -18.0), 9.0, Color.WHITE)
		draw_arc(Vector2(20.0, -18.0), 9.0, 0.0, TAU, 20, Color.BLACK, 2.0)
