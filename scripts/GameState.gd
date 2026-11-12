extends Node
## autoload

const START_COINS := 24

var team: Array = []                # PlayerData (capitão + goleiro + jogadores de linha)
var coins: int = 0                  # Futmoedas
var cycle: int = 1
var kit: Dictionary = {}            # uniforme da equipe (compartilhado)
var last_result: Dictionary = {}
var run_won: bool = false


func new_run() -> void:
	team = []
	coins = START_COINS
	cycle = 1
	kit = {}
	last_result = {}
	run_won = false


func goto(scene_name: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name)


func maintenance_total() -> int:
	var total := 0
	for p in team:
		total += p.maintenance()
	return total


## Cobra a manutenção de cada jogador. Quem não puder ser pago começa a próxima partida cansado.
func pay_maintenance() -> Dictionary:
	var total := 0
	var unpaid: Array = []
	var sorted := team.duplicate()
	sorted.sort_custom(func(a, b): return a.maintenance() < b.maintenance())
	for p in sorted:
		var m: int = p.maintenance()
		total += m
		if coins >= m:
			coins -= m
		else:
			p.unpaid = true
			unpaid.append(p.pname)
	return {"total": total, "unpaid": unpaid, "left": coins}


## Gira a 6ª estrela: ninguém -> jogador 1 -> ... -> último -> ninguém
func cycle_sixth_star() -> void:
	var idx := -1
	for i in team.size():
		if team[i].six_star:
			idx = i
	for p in team:
		p.six_star = false
	idx += 1
	if idx < team.size():
		team[idx].six_star = true


func sixth_star_holder() -> PlayerData:
	for p in team:
		if p.six_star:
			return p
	return null
