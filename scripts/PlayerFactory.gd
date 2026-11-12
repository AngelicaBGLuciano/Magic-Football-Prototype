class_name PlayerFactory
extends RefCounted
## Geração aleatória de jogadores

const FIRST := ["Léo", "Caio", "Davi", "Rafa", "Tito", "Nando", "Gui", "Beto", "Juca", "Zeca", "Maicon", "Dudu", "Lucas", "Iago"]
const NICK := ["Mago", "Foguete", "Bruxo", "Canhão", "Fantasma", "Trovão", "Cometa", "Sombra", "Relâmpago", "Feitiço", "Pirata", "Cobra", "Cajado", "Duende"]
const TEAM_NAMES := ["Arcanos FC", "Sombras United", "Real Feitiço", "Grêmio dos Bruxos", "Esquadrão Rúnico"]


static func random_name() -> String:
	return "%s %s" % [FIRST.pick_random(), NICK.pick_random()]


static func team_name(cycle: int) -> String:
	return TEAM_NAMES[(cycle - 1) % TEAM_NAMES.size()]


static func make_player(position: String, tier: int) -> PlayerData:
	var p := PlayerData.new()
	p.pname = random_name()
	p.position = position
	p.tier = tier
	for k in Const.ATTRS:
		p.attrs[k] = clampi(2 + tier + randi_range(0, 2), 1, Const.ATTR_CAP)
	# uma especialidade e uma fraqueza
	var strong: String = Const.ATTRS.pick_random()
	p.attrs[strong] = mini(int(p.attrs[strong]) + 2, Const.ATTR_CAP)
	var weak: String = Const.ATTRS.pick_random()
	p.attrs[weak] = maxi(int(p.attrs[weak]) - 1, 1)
	if position == "GOL":
		for k in ["res", "agi", "tat"]:
			p.attrs[k] = mini(int(p.attrs[k]) + 1, Const.ATTR_CAP)
	# dons
	var n_skills := 0
	if tier == 0:
		n_skills = 1 if randf() < 0.5 else 0
	elif tier < 3:
		n_skills = 1
	else:
		n_skills = 2 if randf() < 0.5 else 1
	var taken: Array = []
	for i in n_skills:
		var id := SkillDB.random_id(position, taken)
		taken.append(id)
		p.add_skill(id, clampi(tier - randi_range(0, 1), 0, 5))
	return p


static func make_opponent_team(cycle: int) -> Array:
	var out: Array = []
	var base_tier := (cycle - 1) >> 1
	var boss_bonus := 1 if cycle >= Const.MAX_CYCLES else 0
	out.append(_scaled(make_player("GOL", clampi(base_tier + randi_range(0, 1) + boss_bonus, 0, 5)), cycle))
	for i in 3:
		out.append(_scaled(make_player("LIN", clampi(base_tier + randi_range(0, 1) + boss_bonus, 0, 5)), cycle))
	return out


static func _scaled(p: PlayerData, cycle: int) -> PlayerData:
	for i in cycle - 1:
		var k: String = Const.ATTRS.pick_random()
		p.attrs[k] = mini(int(p.attrs[k]) + 1, Const.ATTR_CAP)
	return p
