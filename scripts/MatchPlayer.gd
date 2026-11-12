class_name MatchPlayer
extends RefCounted
## Estado de um jogador dentro de uma partida (posição no tabuleiro, Vigor, bônus temporários).

var data: PlayerData
var team: int = 0                   # 0 = você (ataca para a direita), 1 = adversário
var is_gk: bool = false
var cell: Vector2i = Vector2i.ZERO
var anchor: Vector2i = Vector2i.ZERO    # posição tática definida no turno de posicionamento
var base: Dictionary = {}           # atributos base da partida (já com itens)
var bonus: Dictionary = {}          # bônus temporários (Ás, eventos)
var vig: float = 0.0
var vig_max: float = 1.0
var fallen: int = 0                 # ticks restantes caído no chão
var skill_map: Dictionary = {}      # id -> índice de estrela (0..6)
var ace_stacks: int = 0
var perfect_ready: bool = false
var perfect_used: bool = false
var goals: int = 0
var saves: int = 0


func _init(d: PlayerData, t: int) -> void:
	data = d
	team = t
	is_gk = d.position == "GOL"
	for s in d.skills:
		skill_map[s["id"]] = 6 if d.six_star else int(s["stars"])
	for k in Const.ATTRS:
		bonus[k] = 0


func has_skill(id: String) -> bool:
	return skill_map.has(id)


func display_name() -> String:
	return data.pname
