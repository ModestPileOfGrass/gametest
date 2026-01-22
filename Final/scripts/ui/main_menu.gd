extends CanvasLayer
class_name MainMenuUI

## Main Menu UI Controller
## Handles button presses to start game, show high scores, or quit

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var high_scores_button: Button = $CenterContainer/VBoxContainer/HighScoresButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

signal start_game_pressed
signal high_scores_pressed
signal quit_pressed


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	high_scores_button.pressed.connect(_on_high_scores_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# AUDIO: Add button sounds
	start_button.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover"))
	high_scores_button.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover"))
	quit_button.mouse_entered.connect(func(): AudioManager.play_sfx("button_hover"))
	
	start_button.grab_focus()

func _on_start_pressed() -> void:
	AudioManager.play_sfx("button_click")
	start_game_pressed.emit()

func _on_high_scores_pressed() -> void:
	AudioManager.play_sfx("button_click")
	high_scores_pressed.emit()

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("button_click")
	quit_pressed.emit()


func show_menu() -> void:
	visible = true
	start_button.grab_focus()


func hide_menu() -> void:
	visible = false
