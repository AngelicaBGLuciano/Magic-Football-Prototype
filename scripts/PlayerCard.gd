extends PanelContainer

signal chosen(player: PlayerData)

var player: PlayerData = null

@onready var name_label: Label = %NameLabel
@onready var info_label: Label = %InfoLabel
@onready var attr_label: Label = %AttrLabel
@onready var skill_label: Label = %SkillLabel
@onready var pick_button: Button = %PickButton


func setup(p: PlayerData, price: int = -1, enabled: bool = true, button_text: String = "Escolher") -> void:
	player = p
	name_label.text = p.pname + (" (CAPITÃO)" if p.is_captain else "")
	var pos := "Goleiro" if p.position == "GOL" else "Linha"
	var tier_txt := "*".repeat(p.tier) if p.tier > 0 else "-"
	var info := "%s  |  Tier %s  |  Manut. %d" % [pos, tier_txt, p.maintenance()]
	if p.six_star:
		info += "  |  6ª ESTRELA"
	if price >= 0:
		info += "  |  Preço %d" % price
	info_label.text = info

	var parts := PackedStringArray()
	for k in Const.ATTRS:
		parts.append("%s %d" % [Const.ATTR_SHORT[k], p.total_attr(k)])
	attr_label.text = "  ".join(parts.slice(0, 3)) + "\n" + "  ".join(parts.slice(3, 6))

	var lines := PackedStringArray()
	for s in p.skills:
		lines.append("- " + SkillDB.describe(s["id"], 6 if p.six_star else int(s["stars"])))
	if lines.is_empty():
		lines.append("(sem dons)")
	if not p.boots.is_empty():
		lines.append("Equip.: %s (%s)" % [p.boots["name"], Const.mods_text(p.boots["mods"])])
	skill_label.text = "\n".join(lines)

	pick_button.text = button_text
	pick_button.disabled = not enabled
	if not pick_button.pressed.is_connected(_on_pressed):
		pick_button.pressed.connect(_on_pressed)


func _on_pressed() -> void:
	chosen.emit(player)
