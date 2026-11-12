extends Control

const BASE := 3
const POINTS := 8
const CAP := 8

@onready var name_edit: LineEdit = %NameEdit
@onready var chaos_check: CheckButton = %ChaosCheck
@onready var points_label: Label = %PointsLabel
@onready var attr_grid: GridContainer = %AttrGrid
@onready var dom_option: OptionButton = %DomOption
@onready var dom_desc: Label = %DomDesc
@onready var confirm_button: Button = %ConfirmButton

var alloc: Dictionary = {}
var points_left: int = POINTS
var value_labels: Dictionary = {}
var minus_buttons: Dictionary = {}
var plus_buttons: Dictionary = {}
var dom_choices: Array = []


func _ready() -> void:
	for k in Const.ATTRS:
		alloc[k] = 0
	_build_rows()
	dom_choices = SkillDB.random_ids("LIN", 3)
	for id in dom_choices:
		dom_option.add_item(SkillDB.skill_name(id))
	dom_option.item_selected.connect(_on_dom_selected)
	chaos_check.toggled.connect(_on_chaos_toggled)
	confirm_button.pressed.connect(_confirm)
	name_edit.text = PlayerFactory.random_name()
	_refresh()


func _build_rows() -> void:
	for k in Const.ATTRS:
		var lbl := Label.new()
		lbl.text = Const.ATTR_NAMES[k]
		lbl.custom_minimum_size = Vector2(140, 0)
		attr_grid.add_child(lbl)
		var minus := Button.new()
		minus.text = "-"
		minus.custom_minimum_size = Vector2(40, 0)
		minus.pressed.connect(_change.bind(k, -1))
		attr_grid.add_child(minus)
		var val := Label.new()
		val.custom_minimum_size = Vector2(40, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		attr_grid.add_child(val)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(40, 0)
		plus.pressed.connect(_change.bind(k, 1))
		attr_grid.add_child(plus)
		value_labels[k] = val
		minus_buttons[k] = minus
		plus_buttons[k] = plus


func _change(k: String, d: int) -> void:
	if chaos_check.button_pressed:
		return
	if d > 0 and points_left > 0 and BASE + int(alloc[k]) < CAP:
		alloc[k] = int(alloc[k]) + 1
		points_left -= 1
	elif d < 0 and int(alloc[k]) > 0:
		alloc[k] = int(alloc[k]) - 1
		points_left += 1
	_refresh()


func _on_dom_selected(_i: int) -> void:
	_refresh()


func _on_chaos_toggled(_on: bool) -> void:
	_refresh()


func _refresh() -> void:
	var chaos := chaos_check.button_pressed
	for k in Const.ATTRS:
		var lbl: Label = value_labels[k]
		lbl.text = "?" if chaos else str(BASE + int(alloc[k]))
		var minus: Button = minus_buttons[k]
		var plus: Button = plus_buttons[k]
		minus.disabled = chaos or int(alloc[k]) <= 0
		plus.disabled = chaos or points_left <= 0 or BASE + int(alloc[k]) >= CAP
	dom_option.disabled = chaos
	if chaos:
		points_label.text = "Modo Caos: atributos sorteados e DOIS Dons aleatórios!"
		dom_desc.text = "Os dons serão revelados ao confirmar."
		confirm_button.disabled = false
	else:
		points_label.text = "Pontos restantes: %d" % points_left
		var id: String = dom_choices[dom_option.selected]
		dom_desc.text = SkillDB.describe(id, 1)
		confirm_button.disabled = points_left > 0


func _confirm() -> void:
	var cap := PlayerData.new()
	cap.pname = name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else "Capitão"
	cap.position = "LIN"
	cap.tier = 1
	cap.is_captain = true
	if chaos_check.button_pressed:
		for k in Const.ATTRS:
			cap.attrs[k] = 2
		var left := 14
		while left > 0:
			var k: String = Const.ATTRS.pick_random()
			if int(cap.attrs[k]) < 9:
				cap.attrs[k] = int(cap.attrs[k]) + 1
				left -= 1
		var ids := SkillDB.random_ids("LIN", 2)
		for id in ids:
			cap.add_skill(id, 1)
	else:
		for k in Const.ATTRS:
			cap.attrs[k] = BASE + int(alloc[k])
		cap.add_skill(dom_choices[dom_option.selected], 1)
	GameState.new_run()
	GameState.team.append(cap)
	GameState.goto("Draft")
