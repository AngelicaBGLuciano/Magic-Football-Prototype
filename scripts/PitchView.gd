class_name PitchView
extends Control
## Desenha o gramado, cria as peças e emite cliques de casa.

signal cell_clicked(cell: Vector2i)

const TokenScene := preload("res://scenes/PlayerToken.tscn")

var engine: MatchEngine = null
var tokens: Dictionary = {}
var selected: MatchPlayer = null
var mode: String = ""       


func bind(e: MatchEngine) -> void:
	engine = e
	for t in tokens.values():
		t.queue_free()
	tokens.clear()
	for p in engine.players:
		var t = TokenScene.instantiate()
		add_child(t)
		t.setup(p)
		t.position = _center(p.cell)
		tokens[p] = t
	refresh()


func _center(c: Vector2i) -> Vector2:
	return Vector2((c.x + 0.5) * size.x / Const.COLS, (c.y + 0.5) * size.y / Const.ROWS)


func refresh() -> void:
	if engine == null:
		return
	for p in tokens:
		var t = tokens[p]
		var target := _center(p.cell)
		if t.position.distance_to(target) > 1.0:
			if t.has_meta("tw"):
				var old = t.get_meta("tw")
				if old != null and old.is_valid():
					old.kill()
			var tw := create_tween()
			tw.tween_property(t, "position", target, 0.22)
			t.set_meta("tw", tw)
		t.update_state(p == engine.carrier, p == selected)
	queue_redraw()


func _draw() -> void:
	var cw := size.x / Const.COLS
	var ch := size.y / Const.ROWS
	for x in Const.COLS:
		var col := Color("2e7d32") if x % 2 == 0 else Color("388e3c")
		draw_rect(Rect2(x * cw, 0.0, cw, size.y), col)
	var line := Color(1, 1, 1, 0.8)
	draw_rect(Rect2(Vector2.ZERO, size), line, false, 3.0)
	draw_line(Vector2(size.x * 0.5, 0.0), Vector2(size.x * 0.5, size.y), line, 2.0)
	draw_arc(size * 0.5, ch * 0.8, 0.0, TAU, 40, line, 2.0)
	draw_rect(Rect2(0.0, ch, cw, ch * 3.0), line, false, 2.0)
	draw_rect(Rect2(size.x - cw, ch, cw, ch * 3.0), line, false, 2.0)
	if mode == "place":
		for x in range(1, Const.PLACE_MAX_X + 1):
			for y in Const.ROWS:
				draw_rect(Rect2(x * cw + 2.0, y * ch + 2.0, cw - 4.0, ch - 4.0), Color(0.2, 0.5, 1.0, 0.20))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := Vector2i(int(event.position.x / (size.x / Const.COLS)), int(event.position.y / (size.y / Const.ROWS)))
		if c.x >= 0 and c.x < Const.COLS and c.y >= 0 and c.y < Const.ROWS:
			cell_clicked.emit(c)
