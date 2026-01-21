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

	# Focus first button for keyboard navigation
	start_button.grab_focus()


func _on_start_pressed() -> void:
	start_game_pressed.emit()


func _on_high_scores_pressed() -> void:
	high_scores_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()


func show_menu() -> void:
	visible = true
	start_button.grab_focus()


func hide_menu() -> void:
	visible = false
