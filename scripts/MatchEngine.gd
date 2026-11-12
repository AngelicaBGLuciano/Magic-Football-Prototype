class_name MatchEngine
extends RefCounted

signal logged(text: String, kind: String)

var field: Dictionary = {}
var players: Array = []
var teams: Array = [[], []]
var score: Array = [0, 0]
var half: int = 1
var tick_in_half: int = 0
var carrier: MatchPlayer = null
var human: int = 0
var pending_minor: Dictionary = {}
var queued: Dictionary = {}


#  Preparação

func setup(home_data: Array, away_data: Array, field_dict: Dictionary, home_cells: Array, away_cells: Array, kit_mods: Dictionary) -> void:
	field = field_dict
	players = []
	teams = [[], []]
	score = [0, 0]
	half = 1
	tick_in_half = 0
	pending_minor = {}
	queued = {}
	_build_team(0, home_data, kit_mods)
	_build_team(1, away_data, {})
	apply_formation(0, home_cells)
	apply_formation(1, away_cells)
	kickoff(0 if randf() < 0.5 else 1)


func _build_team(t: int, datas: Array, kit_mods: Dictionary) -> void:
	for d in datas:
		var p := MatchPlayer.new(d, t)
		for k in Const.ATTRS:
			p.base[k] = d.total_attr(k) + int(kit_mods.get(k, 0))
		if p.is_gk:
			p.cell = Vector2i(0, 2) if t == 0 else Vector2i(Const.COLS - 1, 2)
			p.anchor = p.cell
		p.base["vig"] = int(p.base["vig"]) + int(sv(p, "aquecido", "a"))
		p.vig_max = float(p.base["vig"]) * 3.0
		p.vig = p.vig_max * (0.75 if d.unpaid else 1.0)
		teams[t].append(p)
		players.append(p)


## Coloca os jogadores de linha do time t nas casas da formação.
func apply_formation(t: int, cells: Array) -> void:
	var i := 0
	for p in teams[t]:
		if p.is_gk:
			continue
		var c: Vector2i = cells[i]
		i += 1
		if t == 1:
			c = Vector2i(Const.COLS - 1 - c.x, c.y)
		p.cell = c
		p.anchor = c


func kickoff(t: int) -> void:
	for p in players:
		p.cell = p.anchor
		p.fallen = 0
	var best: MatchPlayer = null
	for p in teams[t]:
		if p.is_gk:
			continue
		if best == null or _dir(t) * p.cell.x > _dir(t) * best.cell.x:
			best = p
	carrier = best


func start_second_half() -> void:
	kickoff(1)


#  Utilidades

func _log(text: String, kind: String = "info") -> void:
	logged.emit(text, kind)


func sv(p: MatchPlayer, id: String, key: String = "a") -> float:
	if not p.skill_map.has(id):
		return 0.0
	return SkillDB.value(id, p.skill_map[id], key)


func _dir(t: int) -> int:
	return 1 if t == 0 else -1


func _goal_x(t: int) -> int:
	return Const.COLS - 1 if t == 0 else 0


func goal_dist(p: MatchPlayer) -> int:
	return absi(_goal_x(p.team) - p.cell.x)


func _dist(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < Const.COLS and c.y >= 0 and c.y < Const.ROWS


func player_at(c: Vector2i) -> MatchPlayer:
	for p in players:
		if p.cell == c:
			return p
	return null


func _free(c: Vector2i) -> bool:
	return _in_bounds(c) and player_at(c) == null


func _gk(t: int) -> MatchPlayer:
	for p in teams[t]:
		if p.is_gk:
			return p
	return null


func _in_own_area(p: MatchPlayer) -> bool:
	return absi(_goal_x(1 - p.team) - p.cell.x) <= 3


func _nearest_opp_dist(cell: Vector2i, t: int) -> int:
	var best := 99
	for o in teams[1 - t]:
		best = mini(best, _dist(o.cell, cell))
	return best


func _nearest_opponent_to(cell: Vector2i, t: int) -> MatchPlayer:
	var best: MatchPlayer = null
	var bd := 99
	for o in teams[1 - t]:
		var dd := _dist(o.cell, cell)
		if dd < bd:
			bd = dd
			best = o
	return best


func _count_adjacent_opps(p: MatchPlayer) -> int:
	var n := 0
	for o in teams[1 - p.team]:
		if _dist(o.cell, p.cell) <= 1:
			n += 1
	return n


func _adjacent_opponents(c: MatchPlayer) -> Array:
	var out: Array = []
	for o in teams[1 - c.team]:
		if not o.is_gk and _dist(o.cell, c.cell) <= 1:
			out.append(o)
	return out


func _nearest_field_player(t: int, cell: Vector2i) -> MatchPlayer:
	var best: MatchPlayer = null
	var bd := 99
	for p in teams[t]:
		if p.is_gk:
			continue
		var dd := _dist(p.cell, cell)
		if dd < bd:
			bd = dd
			best = p
	return best


func _most_advanced_mate(c: MatchPlayer) -> MatchPlayer:
	var best: MatchPlayer = null
	for m in teams[c.team]:
		if m == c or m.is_gk:
			continue
		if best == null or _dir(c.team) * m.cell.x > _dir(c.team) * best.cell.x:
			best = m
	return best


func _best_shooter(t: int) -> MatchPlayer:
	var best: MatchPlayer = null
	var best_v := -1.0
	for p in teams[t]:
		if p.is_gk:
			continue
		var v := attr(p, "pot") + attr(p, "pre")
		if v > best_v:
			best_v = v
			best = p
	return best


func _spend(p: MatchPlayer, amount: float) -> void:
	p.vig = maxf(0.0, p.vig - amount * (1.0 - sv(p, "bonzinho", "a")))


func _steps_for(p: MatchPlayer) -> int:
	var chance := clampf(attr(p, "agi") * 0.04, 0.0, 0.5)
	return 2 if randf() < chance else 1


## Atributo efetivo: base + bônus + dons, escalado pelo Vigor atual (Vigor baixo = atributos piores).
func attr(p: MatchPlayer, key: String) -> float:
	var v := float(p.base[key]) + float(p.bonus[key])
	for id in p.skill_map:
		if SkillDB.is_weather(id) and SkillDB.weather_ok(id, field):
			v += sv(p, id, "a")
	if key == "agi":
		v += sv(p, "ex_corredor", "a") + sv(p, "fominha", "b") + sv(p, "peso_pena", "b")
	if key == "tat" and carrier != null and absi(carrier.cell.x - p.cell.x) <= 3:
		v += sv(p, "fome_de_bola", "a")
	if (key == "res" or key == "tat") and _in_own_area(p):
		v += sv(p, "libero", "a")
	if key == "vig":
		return v
	var ratio := clampf(p.vig / maxf(p.vig_max, 1.0), 0.0, 1.0)
	return maxf(v * (0.5 + 0.5 * ratio), 0.5)


#  Tick (turno "Jogo Rolando...")

func tick() -> Dictionary:
	tick_in_half += 1
	_passive_decay()
	_move_players()
	_carrier_action()
	var sched: Dictionary = {}
	if tick_in_half in Const.WINDOW_TICKS:
		sched = {"pause": "window"}
	elif tick_in_half == Const.MAJOR_TICK:
		sched = {"pause": "major"}
	elif tick_in_half >= Const.TICKS_PER_HALF:
		sched = {"pause": "grand"}
	var minor := resolve_pending_minor()
	if not minor.is_empty():
		queued = sched
		return {"pause": "minor", "event": minor}
	return sched


func take_queued() -> Dictionary:
	var q := queued
	queued = {}
	return q


func _passive_decay() -> void:
	var env := 1.0
	var temp: int = field["temp"]
	if temp >= 30:
		env = 1.2
	elif temp <= 10:
		env = 0.9
	for p in players:
		var mult := 1.0 + sv(p, "aquecido", "b") + sv(p, "ex_corredor", "b")
		var loss := 0.35 * mult * env * (1.0 - sv(p, "bonzinho", "a"))
		p.vig = maxf(0.0, p.vig - loss)


func _move_players() -> void:
	for t in [0, 1]:
		var has_ball: bool = carrier.team == t
		var presser: MatchPlayer = null
		if not has_ball:
			presser = _nearest_field_player(t, carrier.cell)
		for p in teams[t]:
			if p.fallen > 0:
				p.fallen -= 1
				continue
			if p == carrier:
				continue
			if p.is_gk:
				_step(p, Vector2i(p.cell.x, clampi(carrier.cell.y, 1, Const.ROWS - 2)), 1)
				continue
			var target: Vector2i = p.anchor
			if has_ball:
				target = Vector2i(clampi(p.anchor.x + 3 * _dir(t), 1, Const.COLS - 2), p.anchor.y)
			elif p == presser:
				target = carrier.cell
			_step(p, target, _steps_for(p))


func _step(p: MatchPlayer, target: Vector2i, steps: int) -> void:
	for i in steps:
		if p.cell == target:
			return
		var dx := signi(target.x - p.cell.x)
		var dy := signi(target.y - p.cell.y)
		var cands: Array = []
		if dx != 0 and dy != 0:
			cands.append(Vector2i(p.cell.x + dx, p.cell.y + dy))
		if dx != 0:
			cands.append(Vector2i(p.cell.x + dx, p.cell.y))
		if dy != 0:
			cands.append(Vector2i(p.cell.x, p.cell.y + dy))
		for c in cands:
			if _free(c):
				p.cell = c
				break


#  Ação do portador da bola (decisão automática)

func _carrier_action() -> void:
	var c: MatchPlayer = carrier
	if c == null:
		return
	if c.is_gk:
		var gt := _pick_pass_target(c)
		if gt != null:
			_do_pass(c, gt, 0.0)
		return
	var adj := _adjacent_opponents(c)
	if not adj.is_empty() and randf() < 0.5:
		var dfn: MatchPlayer = adj.pick_random()
		var r := _contact_duel(c, dfn)
		if r == 0:
			carrier = dfn
			_log("%s desarma %s." % [dfn.display_name(), c.display_name()], "info")
			return
		if r == 2:
			return
	var dist := goal_dist(c)
	if dist <= Const.SHOOT_RANGE:
		var p_shoot := 0.90 - dist * 0.15
		if randf() < p_shoot:
			_do_shot(c, 0.0, 0.0)
			return
	if randf() < 0.4:
		var tgt := _pick_pass_target(c)
		if tgt != null:
			_do_pass(c, tgt, 0.0)
			return
	_do_advance(c)


func _pick_pass_target(c: MatchPlayer) -> MatchPlayer:
	var best: MatchPlayer = null
	var best_s := -999.0
	for m in teams[c.team]:
		if m == c or (m.is_gk and not c.is_gk):
			continue
		var progress := float(_dir(c.team) * (m.cell.x - c.cell.x))
		var open := float(_nearest_opp_dist(m.cell, c.team))
		var s := progress + open * 0.8 + randf() * 2.0
		if s > best_s:
			best_s = s
			best = m
	return best


func _roll_perfect(c: MatchPlayer) -> bool:
	if not c.has_skill("jogador_de_uma_so_jogada") or c.perfect_used:
		return false
	if c.perfect_ready:
		c.perfect_ready = false
		c.perfect_used = true
		_log("%s: EXECUÇÃO PERFEITA!" % c.display_name(), "event")
		return true
	if randf() < sv(c, "jogador_de_uma_so_jogada", "a"):
		c.perfect_ready = true
	return false


func _do_pass(c: MatchPlayer, tgt: MatchPlayer, pre_bonus: float) -> void:
	var perfect := _roll_perfect(c)
	var d := _dist(c.cell, tgt.cell)
	var err := sv(c, "fominha", "a")
	if bool(field["wet"]):
		err += 0.08
	var marking := float(_count_adjacent_opps(tgt))
	var p_ok := 0.62 + (attr(c, "pre") + pre_bonus) * 0.04 - d * 0.03 - marking * 0.05 - err
	if c.has_skill("pe_encantado") and goal_dist(c) > Const.SHOOT_RANGE:
		p_ok = 1.0
	if perfect:
		p_ok = 1.0
	p_ok = clampf(p_ok, 0.2, 1.0)
	_spend(c, 0.2)
	if randf() < p_ok:
		carrier = tgt
	else:
		var icpt := _nearest_opponent_to(tgt.cell, c.team)
		carrier = icpt
		_log("Passe de %s é cortado por %s." % [c.display_name(), icpt.display_name()], "info")


func _do_advance(c: MatchPlayer, att_bonus: float = 0.0, force_steps: int = 0) -> void:
	var steps := force_steps if force_steps > 0 else _steps_for(c)
	for i in steps:
		var nxt := Vector2i(c.cell.x + _dir(c.team), c.cell.y)
		if nxt.x < 1 or nxt.x > Const.COLS - 2:
			break
		var blocker := player_at(nxt)
		if blocker == null:
			c.cell = nxt
		elif blocker.team != c.team:
			var r := _contact_duel(c, blocker, att_bonus)
			if r == 1:
				var old := c.cell
				c.cell = nxt
				blocker.cell = old
				_log("%s passa por %s no drible!" % [c.display_name(), blocker.display_name()], "info")
			elif r == 0:
				carrier = blocker
				_log("%s toma a bola de %s!" % [blocker.display_name(), c.display_name()], "info")
				return
			else:
				return
		else:
			var alt := Vector2i(c.cell.x, clampi(c.cell.y + (1 if c.cell.y < 2 else -1), 0, Const.ROWS - 1))
			if _free(alt):
				c.cell = alt
			break
	if goal_dist(c) <= 3 and c.cell.y != 2 and randf() < 0.5:
		var ny := c.cell.y + signi(2 - c.cell.y)
		if _free(Vector2i(c.cell.x, ny)):
			c.cell = Vector2i(c.cell.x, ny)
	_spend(c, 0.25)


# retorna 0 = defensor vence (fica com a bola), 1 = atacante mantém a bola, 2 = falta
func _contact_duel(att: MatchPlayer, dfn: MatchPlayer, att_bonus: float = 0.0, def_bonus: float = 0.0, foul_mult: float = 1.0) -> int:
	var a := attr(att, "agi") * 0.5 + attr(att, "tat") * 0.5 + att_bonus
	var d := attr(dfn, "res") * 0.5 + attr(dfn, "tat") * 0.5 + def_bonus
	var p_att := clampf(0.5 + (a - d) * 0.06 - sv(dfn, "muralha", "a") * 0.6, 0.08, 0.9)
	_spend(att, 0.3)
	_spend(dfn, 0.3)
	_drain(att, dfn)
	_drain(dfn, att)
	# falta
	var foul_p := 0.12 * (1.0 + sv(dfn, "brigao", "a")) * (1.0 - sv(dfn, "diplomata", "a")) * (1.0 + sv(att, "baixa_moral", "a")) * foul_mult
	if randf() < foul_p:
		if randf() < sv(dfn, "amigo_do_juiz", "a"):
			_log("O juiz fecha os olhos para a falta de %s!" % dfn.display_name(), "foul")
		else:
			_foul(dfn, att)
			return 2
	var att_wins := randf() < p_att
	var loser := dfn if att_wins else att
	var fall_p := 0.18 - attr(loser, "res") * 0.012 + sv(loser, "peso_pena", "a") - sv(loser, "equilibrista", "a")
	if bool(field["wet"]):
		fall_p += 0.10
	if randf() < clampf(fall_p, 0.0, 0.7):
		loser.fallen = 2
		_log("%s vai ao chão!" % loser.display_name(), "info")
	return 1 if att_wins else 0


func _drain(source: MatchPlayer, victim: MatchPlayer) -> void:
	var amount := sv(source, "brigao", "b")
	if amount > 0.0:
		victim.vig = maxf(0.0, victim.vig - amount)


func _foul(fouler: MatchPlayer, victim: MatchPlayer) -> void:
	_log("Falta de %s em %s!" % [fouler.display_name(), victim.display_name()], "foul")
	carrier = victim
	pending_minor = {"team": victim.team, "kind": "free_kick", "taker": victim}


func _do_shot(c: MatchPlayer, pot_bonus: float, pre_bonus: float, dist_override: int = -1) -> void:
	var perfect := _roll_perfect(c)
	var gk := _gk(1 - c.team)
	var dist := dist_override if dist_override >= 0 else goal_dist(c)
	var pot := attr(c, "pot") + pot_bonus
	var pre := attr(c, "pre") + pre_bonus
	if dist <= 3:
		pot += sv(c, "artilheiro", "a")
	_spend(c, 0.4)
	var p_on := clampf(0.50 + pre * 0.05 - dist * 0.04, 0.15, 0.92)
	if perfect:
		p_on = 1.0
	if randf() > p_on:
		_log("%s chuta para fora!" % c.display_name(), "info")
		carrier = gk
		return
	var shooter_score := (pot + pre) * 0.5
	var keeper_score := (attr(gk, "agi") + attr(gk, "res") + attr(gk, "tat")) / 3.0
	var p_goal := 0.42 + (shooter_score - keeper_score) * 0.05
	p_goal *= 1.0 - sv(c, "bonzinho", "b")
	p_goal += (1.0 - p_goal) * sv(gk, "bonzinho", "b")
	p_goal = clampf(p_goal, 0.06, 0.85)
	if perfect:
		p_goal = 0.95
	if randf() < p_goal:
		score[c.team] += 1
		c.goals += 1
		if c.team == human:
			_log("GOOOL! %s balança as redes!" % c.display_name(), "goal")
		else:
			_log("Gol do adversário: %s marca." % c.display_name(), "goal")
		_ace(c)
		kickoff(1 - c.team)
	else:
		gk.saves += 1
		_log("%s defende a finalização de %s!" % [gk.display_name(), c.display_name()], "save")
		if p_goal >= 0.55:
			_ace(gk)
		carrier = gk


func _ace(p: MatchPlayer) -> void:
	if p.has_skill("as") and p.ace_stacks < 3:
		p.ace_stacks += 1
		var b := int(sv(p, "as", "a"))
		for k in Const.ATTRS:
			p.bonus[k] = int(p.bonus[k]) + b
		_log("%s cresce de confiança (Ás)!" % p.display_name(), "info")


#  Janela de Oportunidade 

func window_options() -> Array:
	var opts: Array = []
	var c := carrier
	if c.team == human:
		if c.is_gk:
			opts.append({"id": "lancamento", "name": "Lançamento", "who": c, "cost": 2.0,
				"enabled": c.vig >= 2.0, "desc": "Bola longa para o atacante mais avançado."})
		else:
			var in_range := goal_dist(c) <= Const.SHOOT_RANGE
			opts.append({"id": "chute_colocado", "name": "Chute Colocado", "who": c, "cost": 2.0,
				"enabled": in_range and c.vig >= 2.0, "desc": "+3 PRE, -1 POT. Até 4 casas do gol."})
			opts.append({"id": "chute_forte", "name": "Chute Forte", "who": c, "cost": 3.0,
				"enabled": in_range and c.vig >= 3.0, "desc": "+3 POT, -1.5 PRE. Até 4 casas do gol."})
			opts.append({"id": "lancamento", "name": "Lançamento", "who": c, "cost": 2.0,
				"enabled": c.vig >= 2.0, "desc": "Passe longo e preciso ao mais avançado."})
			opts.append({"id": "arrancada", "name": "Arrancada", "who": c, "cost": 2.0,
				"enabled": c.vig >= 2.0, "desc": "Avança 2 casas com bônus no drible."})
	else:
		var who := _nearest_field_player(human, c.cell)
		opts.append({"id": "pressao", "name": "Pressão", "who": who, "cost": 2.0,
			"enabled": who.vig >= 2.0, "desc": "Corre no portador e tenta o desarme."})
		opts.append({"id": "carrinho", "name": "Carrinho", "who": who, "cost": 2.0,
			"enabled": who.vig >= 2.0, "desc": "Desarme forte, mas com risco de falta."})
	return opts


func apply_play(id: String) -> void:
	var c := carrier
	match id:
		"chute_colocado":
			_spend(c, 2.0)
			_log("%s tenta o chute colocado!" % c.display_name(), "event")
			_do_shot(c, -1.0, 3.0)
		"chute_forte":
			_spend(c, 3.0)
			_log("%s arrisca o chute forte!" % c.display_name(), "event")
			_do_shot(c, 3.0, -1.5)
		"lancamento":
			var tgt := _most_advanced_mate(c)
			if tgt != null:
				_spend(c, 2.0)
				_log("%s lança para %s!" % [c.display_name(), tgt.display_name()], "event")
				_do_pass(c, tgt, 3.0)
		"arrancada":
			_spend(c, 2.0)
			_log("%s parte em arrancada!" % c.display_name(), "event")
			_do_advance(c, 3.0, 2)
		"pressao":
			_defend_play(_nearest_field_player(human, c.cell), 2, 2.0, 1.0)
		"carrinho":
			_defend_play(_nearest_field_player(human, c.cell), 2, 4.0, 2.5)
		_:
			pass


func _defend_play(who: MatchPlayer, steps: int, def_bonus: float, foul_mult: float) -> void:
	var att := carrier
	_spend(who, 2.0)
	_step(who, att.cell, steps)
	if _dist(who.cell, att.cell) <= 1:
		var r := _contact_duel(att, who, 0.0, def_bonus, foul_mult)
		if r == 0:
			carrier = who
			_log("%s desarma %s!" % [who.display_name(), att.display_name()], "event")
		elif r == 1:
			_log("%s escapa da marcação de %s." % [att.display_name(), who.display_name()], "info")
	else:
		_log("%s não chega a tempo." % who.display_name(), "info")


#  Evento Menor 

## Se há uma falta pendente: a favor do humano, 65% de chance de abrir escolha; senão resolve sozinho.
func resolve_pending_minor() -> Dictionary:
	if pending_minor.is_empty():
		return {}
	var m := pending_minor
	pending_minor = {}
	if int(m["team"]) == human and randf() < 0.65:
		return m
	_auto_free_kick(m)
	return {}


func minor_choices(_m: Dictionary) -> Array:
	return [
		{"label": "Cobrar direto", "desc": "Chute no gol. Quanto mais perto, melhor."},
		{"label": "Jogada ensaiada (-2 vig)", "desc": "Passe curto e finalização com bônus."},
		{"label": "Bater rápido", "desc": "Mantém a posse, sem riscos."},
	]


func _auto_free_kick(m: Dictionary) -> void:
	var taker: MatchPlayer = m["taker"]
	var idx := 2
	if goal_dist(taker) <= Const.SHOOT_RANGE and randf() < 0.6:
		idx = 0
	elif randf() < 0.3:
		idx = 1
	resolve_minor(m, idx)


func resolve_minor(m: Dictionary, idx: int) -> void:
	var taker: MatchPlayer = m["taker"]
	var t: int = m["team"]
	match idx:
		0:
			var shooter := _best_shooter(t)
			carrier = shooter
			_log("%s cobra a falta direto!" % shooter.display_name(), "event")
			_do_shot(shooter, 1.0, 2.0, maxi(goal_dist(taker), 2))
		1:
			_spend(taker, 2.0)
			var mate := _most_advanced_mate(taker)
			var p_ok := clampf(0.55 + attr(taker, "pre") * 0.04, 0.3, 0.9)
			if mate != null and randf() < p_ok:
				_log("A jogada ensaiada funciona! %s fica livre." % mate.display_name(), "event")
				carrier = mate
				_do_shot(mate, 0.0, 4.0, 3)
			else:
				var o := _nearest_opponent_to(taker.cell, t)
				carrier = o
				_log("A jogada ensaiada falha e %s fica com a bola." % o.display_name(), "info")
		_:
			carrier = taker
			_log("%s bate rápido a falta." % taker.display_name(), "info")


#  Eventos Maior 

func apply_effect(e: Dictionary) -> void:
	var t := human
	if e.has("buff"):
		var buff: Dictionary = e["buff"]
		for p in teams[t]:
			for k in buff:
				p.bonus[k] = int(p.bonus[k]) + int(buff[k])
	if e.has("vigor"):
		for p in teams[t]:
			p.vig = clampf(p.vig + float(e["vigor"]), 0.0, p.vig_max + 3.0)
	if e.has("opp_vigor"):
		for p in teams[1 - t]:
			p.vig = clampf(p.vig + float(e["opp_vigor"]), 0.0, p.vig_max + 3.0)
	if e.has("shot_p"):
		if randf() < float(e["shot_p"]):
			var s := _best_shooter(t)
			carrier = s
			_log("%s cria a chance e finaliza!" % s.display_name(), "event")
			_do_shot(s, 0.0, 2.0, 3)
		else:
			_log("A chance não se concretiza.", "info")
	if e.has("risk_opp_shot"):
		if randf() < float(e["risk_opp_shot"]):
			var s2 := _best_shooter(1 - t)
			carrier = s2
			_log("Contra-ataque! %s finaliza!" % s2.display_name(), "event")
			_do_shot(s2, 0.0, 0.0, 3)


#  Fim de tempo / jogo

func finish_half() -> String:
	if half == 1:
		half = 2
		tick_in_half = 0
		for p in players:
			p.vig = minf(p.vig_max, p.vig + 3.0)
		return "intermission"
	return "fulltime"


## Empate no tempo normal: disputa de pênaltis.
func penalty_shootout() -> Dictionary:
	var s := [0, 0]
	for r in 10:
		for t in [0, 1]:
			var shooters: Array = teams[t].filter(func(p): return not p.is_gk)
			var sh: MatchPlayer = shooters[r % shooters.size()]
			var gk := _gk(1 - t)
			var p_score := clampf(0.62 + (attr(sh, "pre") - attr(gk, "agi")) * 0.04, 0.3, 0.9)
			if randf() < p_score:
				s[t] += 1
		if r >= 2 and s[0] != s[1]:
			break
	var winner := 0 if s[0] > s[1] else 1
	if s[0] == s[1]:
		winner = 0 if randf() < 0.5 else 1
		s[winner] += 1
	return {"winner": winner, "score": s}
