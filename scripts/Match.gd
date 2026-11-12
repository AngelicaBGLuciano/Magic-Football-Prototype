extends Control
##   Definição de área de jogo -> Turno de posicionamento -> Jogo Rolando (com Janelas de Oportunidade,
##   Evento Menor, Evento Maior e Grande Acontecimento) -> Intervalo -> 2º tempo -> Resultados.

enum Phase { AREA, POSICIONAMENTO, ROLANDO, JANELA, EVENTO, INTERVALO, FIM }

const SPEEDS := [0.9, 0.45, 0.18]
const SPEED_LABELS := [1, 2, 5]

@onready var pitch: PitchView = %Pitch
@onready var score_label: Label = %Score
@onready var side_title: Label = %SideTitle
@onready var side_info: Label = %SideInfo
@onready var options: VBoxContainer = %Options
@onready var log_box: RichTextLabel = %Log
@onready var squad_box: RichTextLabel = %Squad
@onready var speed_btn: Button = %SpeedBtn
@onready var tick_timer: Timer = %TickTimer

var engine := MatchEngine.new()
var phase: int = Phase.AREA
var fields_offered: Array = []
var field: Dictionary = {}
var opponent: Array = []
var opp_name: String = ""
var speed_i: int = 0


func _ready() -> void:
	opponent = PlayerFactory.make_opponent_team(GameState.cycle)
	opp_name = PlayerFactory.team_name(GameState.cycle)
	var pool: Array = Const.FIELDS.duplicate()
	pool.shuffle()
	fields_offered = pool.slice(0, 3)
	engine.logged.connect(_on_log)
	tick_timer.timeout.connect(_on_tick)
	speed_btn.pressed.connect(_on_speed)
	pitch.cell_clicked.connect(_on_cell_clicked)
	_refresh_speed_label()
	_show_area_choice()


#  Utilidades de UI

func _clear_options() -> void:
	for c in options.get_children():
		options.remove_child(c)
		c.queue_free()


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.clip_text = true
	b.custom_minimum_size = Vector2(0, 44)
	options.add_child(b)
	return b


func _minute() -> int:
	return (engine.half - 1) * 45 + int(engine.tick_in_half * 45.0 / Const.TICKS_PER_HALF)


func _update_hud() -> void:
	score_label.text = "Você %d x %d %s   |   %d' (%dº tempo)   |   Ciclo %d/%d   |   %s" % [
		engine.score[0], engine.score[1], opp_name, _minute(), engine.half,
		GameState.cycle, Const.MAX_CYCLES, str(field.get("name", "-"))]
	var lines := PackedStringArray()
	for p in engine.teams[0]:
		var tag := "GOL" if p.is_gk else "LIN"
		lines.append("[b]%s[/b] (%s)  VIG %.1f/%.0f  gols %d  defesas %d" % [
			p.display_name(), tag, p.vig, p.vig_max, p.goals, p.saves])
	squad_box.text = ""
	squad_box.append_text("\n".join(lines))


func _on_log(text: String, kind: String) -> void:
	var colors := {"goal": "#ffd54f", "foul": "#ff9e57", "save": "#7fd6ff", "event": "#c79bff", "info": "#d8dee9"}
	var col: String = colors.get(kind, "#d8dee9")
	log_box.append_text("[color=%s]%d' %s[/color]\n" % [col, _minute(), text])


func _on_speed() -> void:
	speed_i = (speed_i + 1) % SPEEDS.size()
	_refresh_speed_label()


func _refresh_speed_label() -> void:
	speed_btn.text = "Velocidade: %dx" % SPEED_LABELS[speed_i]
	tick_timer.wait_time = SPEEDS[speed_i]


#  Etapa: Definição de área de jogo (+ escalação / 6ª estrela)

func _synergy_text(f: Dictionary) -> String:
	var names := PackedStringArray()
	for p in GameState.team:
		for s in p.skills:
			if SkillDB.is_weather(s["id"]) and SkillDB.weather_ok(s["id"], f):
				names.append(p.pname)
	if names.is_empty():
		return "Neutro para o seu time"
	return "Favorece: " + ", ".join(names)


func _six_text() -> String:
	var h := GameState.sixth_star_holder()
	var who := h.pname if h != null else "ninguém"
	return "6ª estrela: %s (clique para trocar; manutenção +%d)" % [who, Const.SIXTH_STAR_EXTRA]


func _show_area_choice() -> void:
	phase = Phase.AREA
	side_title.text = "Definição de área de jogo"
	side_info.text = "Ciclo %d/%d contra %s. Escolha o campo: o clima ativa dons do seu time. Aqui você também define a 6ª estrela (escalação)." % [
		GameState.cycle, Const.MAX_CYCLES, opp_name]
	_clear_options()
	for f in fields_offered:
		var wet_txt := " (chuva)" if f["wet"] else ""
		var b := _make_button("%s - %d°C%s\n%s" % [f["name"], f["temp"], wet_txt, _synergy_text(f)])
		b.pressed.connect(_choose_field.bind(f))
	var six := _make_button(_six_text())
	six.pressed.connect(_on_six_star)


func _on_six_star() -> void:
	GameState.cycle_sixth_star()
	_show_area_choice()


func _choose_field(f: Dictionary) -> void:
	field = f
	var away_cells: Array = Const.FORMATIONS.values().pick_random()
	var kit_mods: Dictionary = GameState.kit.get("mods", {})
	engine.setup(GameState.team, opponent, field, Const.FORMATIONS["Equilibrada"], away_cells, kit_mods)
	for p in GameState.team:
		p.unpaid = false
	pitch.bind(engine)
	_update_hud()
	_on_log("Campo: %s. Adversário: %s." % [f["name"], opp_name], "info")
	_enter_position(false)


#  Turno de posicionamento / Intervalo

func _enter_position(intermission: bool) -> void:
	phase = Phase.INTERVALO if intermission else Phase.POSICIONAMENTO
	side_title.text = "Intervalo" if intermission else "Turno de posicionamento"
	side_info.text = "Clique num jogador azul e depois numa casa azul para movê-lo (ou noutro jogador para trocar). Ou escolha uma formação."
	pitch.mode = "place"
	pitch.selected = null
	pitch.refresh()
	_clear_options()
	for fname in Const.FORMATIONS:
		var b := _make_button("Formação: %s" % fname)
		b.pressed.connect(_apply_formation.bind(fname))
	var go := _make_button("Começar o 2º tempo" if intermission else "Apitar o início!")
	go.pressed.connect(_start_play.bind(intermission))


func _apply_formation(fname: String) -> void:
	engine.apply_formation(0, Const.FORMATIONS[fname])
	pitch.selected = null
	pitch.refresh()


func _on_cell_clicked(cell: Vector2i) -> void:
	if phase != Phase.POSICIONAMENTO and phase != Phase.INTERVALO:
		return
	var occ: MatchPlayer = engine.player_at(cell)
	var sel: MatchPlayer = pitch.selected
	if occ != null:
		if occ.team == 0 and not occ.is_gk:
			if sel != null and sel != occ:
				var tmp := occ.cell
				occ.cell = sel.cell
				occ.anchor = sel.cell
				sel.cell = tmp
				sel.anchor = tmp
				pitch.selected = null
			else:
				pitch.selected = occ
	elif sel != null and cell.x >= 1 and cell.x <= Const.PLACE_MAX_X:
		sel.cell = cell
		sel.anchor = cell
		pitch.selected = null
	pitch.refresh()


func _start_play(intermission: bool) -> void:
	pitch.mode = ""
	pitch.selected = null
	if intermission:
		engine.start_second_half()
		_on_log("Começa o segundo tempo!", "info")
	else:
		_on_log("Apita o árbitro!", "info")
	pitch.refresh()
	_begin_rolling()


#  Jogo Rolando...

func _begin_rolling() -> void:
	phase = Phase.ROLANDO
	side_title.text = "Jogo rolando..."
	side_info.text = "A partida segue no automático, usando atributos e Dons. Prepare-se para as janelas de oportunidade e eventos."
	_clear_options()
	_update_hud()
	tick_timer.start()


func _on_tick() -> void:
	if phase != Phase.ROLANDO:
		return
	var r := engine.tick()
	pitch.refresh()
	_update_hud()
	if r.has("pause"):
		tick_timer.stop()
		_handle_pause(r)


func _handle_pause(r: Dictionary) -> void:
	tick_timer.stop()
	match r["pause"]:
		"window":
			_show_window()
		"minor":
			_show_minor(r["event"])
		"major":
			_show_event(EventDB.random_major(), "Evento Maior")
		"grand":
			_show_event(EventDB.random_grand(), "Grande Acontecimento")


func _resume() -> void:
	_clear_options()
	var q := engine.take_queued()
	if not q.is_empty():
		_handle_pause(q)
		return
	if engine.tick_in_half >= Const.TICKS_PER_HALF:
		_end_half()
		return
	_begin_rolling()


# --- Janela de Oportunidade ---

func _show_window() -> void:
	phase = Phase.JANELA
	side_title.text = "Janela de Oportunidade"
	var c: MatchPlayer = engine.carrier
	if c.team == 0:
		side_info.text = "%s está com a bola. Escolha uma Jogada (custa Vigor) ou deixe o jogo rolar." % c.display_name()
	else:
		side_info.text = "%s (adversário) está com a bola. Tente interrompê-lo!" % c.display_name()
	_clear_options()
	for o in engine.window_options():
		var b := _make_button("%s - %s  (-%d vig)\n%s" % [o["name"], o["who"].display_name(), int(o["cost"]), o["desc"]])
		b.disabled = not o["enabled"]
		b.pressed.connect(_pick_play.bind(o["id"]))
	var skip := _make_button("Deixar o jogo rolar")
	skip.pressed.connect(_pick_play.bind("rolar"))


func _pick_play(id: String) -> void:
	engine.apply_play(id)
	pitch.refresh()
	_update_hud()
	var m := engine.resolve_pending_minor()
	if not m.is_empty():
		_show_minor(m)
		return
	_resume()


# --- Evento Menor (bola parada) ---

func _show_minor(m: Dictionary) -> void:
	phase = Phase.EVENTO
	var taker: MatchPlayer = m["taker"]
	side_title.text = "Evento Menor: bola parada"
	side_info.text = "Falta a favor! %s está com a bola, a %d casas do gol. Como cobrar?" % [taker.display_name(), engine.goal_dist(taker)]
	_clear_options()
	var choices := engine.minor_choices(m)
	for i in choices.size():
		var b := _make_button("%s\n%s" % [choices[i]["label"], choices[i]["desc"]])
		b.pressed.connect(_pick_minor.bind(m, i))


func _pick_minor(m: Dictionary, idx: int) -> void:
	engine.resolve_minor(m, idx)
	pitch.refresh()
	_update_hud()
	_resume()


# --- Evento Maior / Grande Acontecimento ---

func _show_event(ev: Dictionary, header: String) -> void:
	phase = Phase.EVENTO
	side_title.text = "%s: %s" % [header, ev["title"]]
	side_info.text = ev["text"]
	_clear_options()
	var choices: Array = ev["choices"]
	for i in choices.size():
		var b := _make_button("%s\n%s" % [choices[i]["label"], choices[i]["desc"]])
		b.pressed.connect(_pick_event.bind(ev, i))


func _pick_event(ev: Dictionary, idx: int) -> void:
	var ch: Dictionary = ev["choices"][idx]
	_on_log("%s: %s" % [ev["title"], ch["label"]], "event")
	engine.apply_effect(ch["effect"])
	pitch.refresh()
	_update_hud()
	_resume()


#  Fim de tempo / Resultados

func _end_half() -> void:
	var r := engine.finish_half()
	if r == "intermission":
		_on_log("Fim do primeiro tempo! Todos recuperam 3 de Vigor.", "info")
		_update_hud()
		_enter_position(true)
	else:
		_finish_match()


func _finish_match() -> void:
	phase = Phase.FIM
	tick_timer.stop()
	var h: int = engine.score[0]
	var a: int = engine.score[1]
	var won := h > a
	var txt := "Fim de jogo: %d x %d." % [h, a]
	if h == a:
		var res := engine.penalty_shootout()
		won = int(res["winner"]) == 0
		txt += " Empate! Pênaltis: %d x %d." % [res["score"][0], res["score"][1]]
	side_title.text = "Resultados"
	side_info.text = txt + ("\nVitória!" if won else "\nDerrota: a run termina aqui.")
	_on_log(txt, "goal")
	_clear_options()
	var b := _make_button("Continuar")
	b.pressed.connect(_continue.bind(won, h, a, txt))


func _continue(won: bool, h: int, a: int, txt: String) -> void:
	if not won:
		GameState.run_won = false
		GameState.last_result = {"text": txt}
		GameState.goto("EndScreen")
		return
	var gain := 10 + maxi(h - a, 0) * 2
	GameState.coins += gain
	var pay := GameState.pay_maintenance()
	GameState.last_result = {"text": txt, "gain": gain, "pay": pay}
	if GameState.cycle >= Const.MAX_CYCLES:
		GameState.run_won = true
		GameState.goto("EndScreen")
	else:
		GameState.cycle += 1
		GameState.goto("Reward")
