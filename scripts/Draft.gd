extends Control

const CardScene := preload("res://scenes/PlayerCard.tscn")
const ROUNDS := 3   # capitão + 3 contratados = 4 jogadores 

@onready var title_label: Label = %TitleLabel
@onready var coins_label: Label = %CoinsLabel
@onready var cards: HBoxContainer = %Cards

var round_i: int = 0


func _ready() -> void:
	_next_offer()


func _roll_tier() -> int:
	var r := randf()
	if r < 0.45:
		return 0
	if r < 0.75:
		return 1
	if r < 0.93:
		return 2
	return 3


func _next_offer() -> void:
	for c in cards.get_children():
		cards.remove_child(c)
		c.queue_free()
	var pos := "GOL" if round_i == 0 else "LIN"
	title_label.text = "Compra inicial - rodada %d/%d (%s)" % [round_i + 1, ROUNDS, "Goleiro" if pos == "GOL" else "Jogador de linha"]
	coins_label.text = "Futmoedas: %d   (guarde pelo menos %d por rodada restante)" % [GameState.coins, Const.MIN_PRICE]
	var reserve := (ROUNDS - round_i - 1) * Const.MIN_PRICE
	for i in 3:
		var tier := 0 if i == 0 else _roll_tier()
		var p := PlayerFactory.make_player(pos, tier)
		var card = CardScene.instantiate()
		cards.add_child(card)
		var price := p.price()
		card.setup(p, price, price <= GameState.coins - reserve, "Contratar")
		card.chosen.connect(_on_pick)


func _on_pick(p: PlayerData) -> void:
	GameState.coins -= p.price()
	GameState.team.append(p)
	round_i += 1
	if round_i >= ROUNDS:
		GameState.goto("Match")
	else:
		_next_offer()
