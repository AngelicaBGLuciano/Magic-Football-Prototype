extends Control

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var again_button: Button = %AgainButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	if GameState.run_won:
		title_label.text = "VITÓRIA NA RUN!"
		body_label.text = "Você venceu os %d ciclos do protótipo.\n" % Const.MAX_CYCLES
	else:
		title_label.text = "FIM DA RUN"
		body_label.text = "Perder significa perder o jogo.\n%s\nCiclo alcançado: %d/%d\n" % [
			str(GameState.last_result.get("text", "")), GameState.cycle, Const.MAX_CYCLES]
	body_label.text += "\nSeu elenco:\n"
	for p in GameState.team:
		var dons := PackedStringArray()
		for s in p.skills:
			dons.append(SkillDB.skill_name(s["id"]))
		body_label.text += "- %s (%s, tier %d) %s\n" % [p.pname, p.position, p.tier, ", ".join(dons)]
	body_label.text += "\nFutmoedas finais: %d" % GameState.coins
	again_button.pressed.connect(_on_again)
	menu_button.pressed.connect(_on_menu)


func _on_again() -> void:
	GameState.new_run()
	GameState.goto("CaptainCreation")


func _on_menu() -> void:
	GameState.goto("MainMenu")
