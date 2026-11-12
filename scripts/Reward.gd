extends Control

const CardScene := preload("res://scenes/PlayerCard.tscn")

@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var offers_box: HBoxContainer = %Offers
@onready var target_title: Label = %TargetTitle
@onready var target_box: HBoxContainer = %TargetBox

var offers: Array = []
var pending: Dictionary = {}


func _ready() -> void:
	title_label.text = "Escolha por rodada - Ciclo %d/%d" % [GameState.cycle, Const.MAX_CYCLES]
	summary_label.text = _summary()
	target_title.visible = false
	offers = _make_offers()
	for o in offers:
		var b := Button.new()
		b.text = "%s\n\n%s" % [o["title"], o["desc"]]
		b.custom_minimum_size = Vector2(380, 130)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_on_offer.bind(o))
		offers_box.add_child(b)


func _summary() -> String:
	var r := GameState.last_result
	var txt: String = r.get("text", "")
	var pay: Dictionary = r.get("pay", {})
	var s := "%s\nPrêmio da vitória: +%d futmoedas.\n" % [txt, int(r.get("gain", 0))]
	s += "Manutenção do elenco: -%d (sobraram %d futmoedas)." % [int(pay.get("total", 0)), GameState.coins]
	var unpaid: Array = pay.get("unpaid", [])
	if not unpaid.is_empty():
		s += "\nSem dinheiro para pagar: %s (começam a próxima partida cansados)." % ", ".join(PackedStringArray(unpaid))
	return s


#  Geração de ofertas

func _make_offers() -> Array:
	var out: Array = []
	var used := {}
	var tries := 0
	while out.size() < 3 and tries < 50:
		tries += 1
		var o := _random_offer()
		if used.has(o["title"]):
			continue
		used[o["title"]] = true
		out.append(o)
	return out


func _random_offer() -> Dictionary:
	var r := randf()
	if r < 0.30:
		var k: String = Const.ATTRS.pick_random()
		var amt := 2 if randf() < 0.3 else 1
		return {"kind": "attr", "attr": k, "amount": amt,
			"title": "Treino: +%d %s" % [amt, Const.ATTR_NAMES[k]],
			"desc": "Escolha um jogador para treinar (limite %d)." % Const.ATTR_CAP}
	if r < 0.60:
		var id := SkillDB.random_id("ANY")
		var stars := clampi(GameState.cycle - 1 + randi_range(0, 1), 0, 3)
		return {"kind": "skill", "id": id, "stars": stars,
			"title": "Dom: %s (tier %d)" % [SkillDB.skill_name(id), stars],
			"desc": SkillDB.describe(id, stars) + "\n(Máx. 2 dons: substitui o de menor tier.)"}
	if r < 0.80:
		if randf() < 0.65:
			var eq: Dictionary = Const.EQUIPMENT.pick_random()
			return {"kind": "equip", "item": eq,
				"title": "Equipamento: %s" % eq["name"],
				"desc": "%s\nSubstitui o equipamento atual do jogador." % Const.mods_text(eq["mods"])}
		var kit: Dictionary = Const.KITS.pick_random()
		return {"kind": "kit", "item": kit,
			"title": "Uniforme: %s" % kit["name"],
			"desc": "%s para TODO o time (substitui o uniforme atual)." % Const.mods_text(kit["mods"])}
	var coins := 8 + GameState.cycle * 2
	return {"kind": "coins", "amount": coins,
		"title": "Patrocínio: +%d futmoedas" % coins,
		"desc": "Dinheiro para pagar a manutenção do elenco."}


#  Aplicação

func _on_offer(o: Dictionary) -> void:
	match o["kind"]:
		"coins":
			GameState.coins += int(o["amount"])
			_finish()
		"kit":
			GameState.kit = o["item"]
			_finish()
		_:
			pending = o
			_show_targets()


func _show_targets() -> void:
	for b in offers_box.get_children():
		if b is Button:
			b.disabled = true
	target_title.visible = true
	target_title.text = "Escolha o jogador que vai receber: %s" % pending["title"]
	for c in target_box.get_children():
		target_box.remove_child(c)
		c.queue_free()
	for p in GameState.team:
		var card = CardScene.instantiate()
		target_box.add_child(card)
		card.setup(p, -1, true, "Receber")
		card.chosen.connect(_on_target)


func _on_target(p: PlayerData) -> void:
	match pending["kind"]:
		"attr":
			var k: String = pending["attr"]
			p.attrs[k] = mini(int(p.attrs[k]) + int(pending["amount"]), Const.ATTR_CAP)
		"skill":
			p.add_skill(pending["id"], int(pending["stars"]))
		"equip":
			p.boots = pending["item"]
	_finish()


func _finish() -> void:
	GameState.goto("Match")
