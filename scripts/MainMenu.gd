extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(get_tree().quit)


func _on_start() -> void:
	GameState.new_run()
	GameState.goto("CaptainCreation")
