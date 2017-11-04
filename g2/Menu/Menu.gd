extends CanvasLayer

onready var game = get_tree().get_root().get_node("game")
var pause_menu = false

func _ready():
	if pause_menu:
		get_node("StartButton").set_text("Continue")
	set_process_input(true)

func _input(event):
	if pause_menu and event.is_action_pressed("ui_cancel"):
		game.unpause(self)

func _on_Start_Button_pressed():
	if pause_menu:
		game.unpause(self)
	else:
		get_tree().change_scene("res:///Level1.tscn")
