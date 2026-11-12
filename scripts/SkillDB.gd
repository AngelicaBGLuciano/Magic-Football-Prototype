class_name SkillDB
extends RefCounted

const DB := {
	"amigo_do_juiz": {
		"name": "Amigo do Juiz",
		"desc": "Ao cometer falta, chance de ser poupado.",
		"a": [0.05, 0.08, 0.11, 0.14, 0.17, 0.20, 0.30], "u": ["%"],
	},
	"aquecido": {
		"name": "Aquecido",
		"desc": "Mais Vigor, mas decai mais rápido.",
		"a": [1, 1, 2, 2, 3, 3, 5], "b": [0.15, 0.14, 0.14, 0.13, 0.13, 0.12, 0.10], "u": ["+", "%"],
	},
	"artilheiro": {
		"name": "Artilheiro",
		"desc": "Mais Potência ao finalizar perto da área.",
		"a": [2, 2, 3, 3, 4, 5, 10], "u": ["+"], "role": "line",
	},
	"as": {
		"name": "Ás",
		"desc": "Gol ou defesa difícil: bônus em tudo até o fim.",
		"a": [1, 2, 3, 3, 4, 5, 6], "u": ["+"],
	},
	"baixa_moral": {
		"name": "Baixa moral",
		"desc": "Adversários provocam mais faltas contra ele.",
		"a": [0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.50], "u": ["%"],
	},
	"bonzinho": {
		"name": "Bonzinho jogando",
		"desc": "Gasta menos Vigor, mas marca/defende menos.",
		"a": [0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20],
		"b": [0.36, 0.34, 0.32, 0.30, 0.28, 0.26, 0.24], "u": ["%", "%"],
	},
	"brigao": {
		"name": "Brigão",
		"desc": "Mais faltas, mas drena Vigor em contatos.",
		"a": [0.25, 0.22, 0.18, 0.16, 0.14, 0.12, 0.10], "b": [1, 1, 1, 1, 1, 1, 2], "u": ["%", "+"],
	},
	"cabeca_fria": {
		"name": "Cabeça fria",
		"desc": "Bônus em tudo no frio e seco (até 10°C).",
		"a": [1, 1, 2, 2, 3, 3, 5], "u": ["+"],
	},
	"cabeca_molhada": {
		"name": "Cabeça molhada",
		"desc": "Bônus em tudo sob chuva (inventado).",
		"a": [1, 1, 2, 2, 3, 3, 5], "u": ["+"],
	},
	"cabeca_quente": {
		"name": "Cabeça quente",
		"desc": "Bônus em tudo no calor seco (30°C+).",
		"a": [1, 1, 2, 2, 3, 3, 5], "u": ["+"],
	},
	"diplomata": {
		"name": "Diplomata",
		"desc": "Menos chance de provocar faltas (inventado).",
		"a": [0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.90], "u": ["%"],
	},
	"equilibrista": {
		"name": "Equilibrista",
		"desc": "Menos chance de cair em contatos (inventado).",
		"a": [0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.60], "u": ["%"],
	},
	"ex_corredor": {
		"name": "Ex-corredor",
		"desc": "Agilidade muito maior; Vigor cai rápido (inventado).",
		"a": [2, 2, 3, 3, 4, 5, 6], "b": [0.50, 0.45, 0.40, 0.40, 0.35, 0.30, 0.30], "u": ["+", "%"],
	},
	"fome_de_bola": {
		"name": "Fome de bola",
		"desc": "Tático extra com a bola por perto (inventado).",
		"a": [1, 1, 2, 2, 3, 3, 5], "u": ["+"], "role": "line",
	},
	"fominha": {
		"name": "Fominha",
		"desc": "Erra mais passes, mas tem mais Agilidade (inventado).",
		"a": [0.20, 0.18, 0.16, 0.14, 0.12, 0.10, 0.08], "b": [1, 1, 2, 2, 3, 3, 4], "u": ["%", "+"],
	},
	"libero": {
		"name": "Líbero",
		"desc": "Resistência e Tático extras na área de defesa (inventado).",
		"a": [1, 1, 2, 2, 3, 3, 5], "u": ["+"],
	},
	"muralha": {
		"name": "Muralha",
		"desc": "Mais chance de desarmar quem vem em sua direção (inventado).",
		"a": [0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.60], "u": ["%"],
	},
	"pe_encantado": {
		"name": "Pé-encantado",
		"desc": "Não erra passes fora da área adversária.",
		"u": [],
	},
	"peso_pena": {
		"name": "Peso-pena",
		"desc": "Cai mais em contatos, mas ganha muita Agilidade (inventado).",
		"a": [0.30, 0.27, 0.24, 0.21, 0.18, 0.15, 0.10], "b": [3, 3, 4, 4, 5, 5, 6], "u": ["%", "+"],
	},
	"jogador_de_uma_so_jogada": {
		"name": "Jogador de uma Só Jogada",
		"desc": "Chance de ganhar UMA Execução Perfeita na partida (inventado).",
		"a": [0.04, 0.06, 0.08, 0.10, 0.12, 0.15, 0.25], "u": ["%"], "role": "line",
	},
}

const WEATHER_IDS := ["cabeca_fria", "cabeca_molhada", "cabeca_quente"]


static func value(id: String, stars: int, key: String = "a") -> float:
	if not DB.has(id) or not DB[id].has(key):
		return 0.0
	var arr: Array = DB[id][key]
	return float(arr[clampi(stars, 0, arr.size() - 1)])


static func skill_name(id: String) -> String:
	return DB[id]["name"] if DB.has(id) else id


static func _fmt(v: float, unit: String) -> String:
	if unit == "%":
		return "%d%%" % roundi(v * 100.0)
	return "+%d" % roundi(v)


static func describe(id: String, stars: int) -> String:
	var d: Dictionary = DB[id]
	var units: Array = d["u"]
	var vals := PackedStringArray()
	var keys := ["a", "b"]
	for i in units.size():
		vals.append(_fmt(value(id, stars, keys[i]), units[i]))
	var head: String = d["name"]
	if vals.size() > 0:
		head += " [" + ", ".join(vals) + "]"
	return "%s: %s" % [head, d["desc"]]


static func pool(position: String) -> Array:
	var out: Array = []
	for id in DB:
		if position == "GOL" and DB[id].get("role", "any") == "line":
			continue
		out.append(id)
	return out


static func random_id(position: String = "ANY", exclude: Array = []) -> String:
	var p := pool(position)
	p = p.filter(func(i): return not exclude.has(i))
	if p.is_empty():
		p = pool(position)
	return p.pick_random()


static func random_ids(position: String, n: int) -> Array:
	var p := pool(position)
	p.shuffle()
	return p.slice(0, n)


static func is_weather(id: String) -> bool:
	return WEATHER_IDS.has(id)


static func weather_ok(id: String, field: Dictionary) -> bool:
	var temp: int = field["temp"]
	var wet: bool = field["wet"]
	match id:
		"cabeca_fria":
			return temp <= 10 and not wet
		"cabeca_quente":
			return temp >= 30 and not wet
		"cabeca_molhada":
			return wet
	return false
