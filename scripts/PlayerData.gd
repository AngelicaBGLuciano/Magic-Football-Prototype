class_name PlayerData
extends Resource

var pname: String = "Jogador"
var position: String = "LIN"        # "GOL" (goleiro) ou "LIN" (linha)
var tier: int = 0                   # 0 a 5 estrelas
var attrs: Dictionary = {"pot": 3, "pre": 3, "vig": 3, "tat": 3, "res": 3, "agi": 3}
var skills: Array = []              # [{"id": String, "stars": int}] (máximo 2)
var is_captain: bool = false
var six_star: bool = false          # 6ª estrela: só um jogador por vez
var unpaid: bool = false            # manutenção não paga -> começa a partida cansado
var boots: Dictionary = {}          # equipamento principal (chuteira/luvas)


func total_attr(key: String) -> int:
	var v: int = attrs.get(key, 0)
	var mods: Dictionary = boots.get("mods", {})
	v += int(mods.get(key, 0))
	if six_star:
		v += 1
	return v


func add_skill(id: String, stars: int) -> void:
	for s in skills:
		if s["id"] == id:
			return
	if skills.size() >= 2:
		# substitui o dom de menor estrela
		var worst := 0
		for i in skills.size():
			if int(skills[i]["stars"]) < int(skills[worst]["stars"]):
				worst = i
		skills.remove_at(worst)
	skills.append({"id": id, "stars": stars})


func maintenance() -> int:
	var m: int = Const.MAINTENANCE[clampi(tier, 0, 5)]
	if six_star:
		m += Const.SIXTH_STAR_EXTRA
	return m


func price() -> int:
	return Const.MIN_PRICE + 3 * tier
