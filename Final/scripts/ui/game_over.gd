extends CanvasLayer
class_name GameOverUI

## Game Over UI Controller
## Handles score display, arcade-style name entry, and navigation

# ============================================================
# NODE REFERENCES
# ============================================================

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var wave_label: Label = $CenterContainer/VBoxContainer/WaveLabel
@onready var letter_labels: Array[Label] = [
	$CenterContainer/VBoxContainer/NameEntryContainer/Letter1,
	$CenterContainer/VBoxContainer/NameEntryContainer/Letter2,
	$CenterContainer/VBoxContainer/NameEntryContainer/Letter3
]
@onready var play_again_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var main_menu_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/MainMenuButton

# ============================================================
# SIGNALS
# ============================================================

signal play_again_pressed
signal main_menu_pressed
signal name_confirmed(initials: String)

# ============================================================
# STATE
# ============================================================

var current_letters: Array[int] = [0, 0, 0]  # A=0, B=1, ... Z=25
var current_position: int = 0  # 0, 1, or 2
var name_entry_active: bool = true
var final_score: int = 0
var final_wave: int = 1

const ALPHABET: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_update_letter_display()


func _input(event: InputEvent) -> void:
	if not visible or not name_entry_active:
		return

	# Handle name entry with arrow keys
	var handled = false
	if event.is_action_pressed("ui_up"):
		_change_letter(1)
		handled = true
	elif event.is_action_pressed("ui_down"):
		_change_letter(-1)
		handled = true
	elif event.is_action_pressed("ui_left"):
		_move_position(-1)
		handled = true
	elif event.is_action_pressed("ui_right"):
		_move_position(1)
		handled = true
	elif event.is_action_pressed("ui_accept"):
		_confirm_name()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()

# ============================================================
# NAME ENTRY
# ============================================================

func _change_letter(direction: int) -> void:
	## Change current letter up or down
	current_letters[current_position] += direction

	# Wrap around
	if current_letters[current_position] < 0:
		current_letters[current_position] = 25
	elif current_letters[current_position] > 25:
		current_letters[current_position] = 0

	_update_letter_display()


func _move_position(direction: int) -> void:
	## Move cursor left or right
	current_position += direction
	current_position = clamp(current_position, 0, 2)
	_update_letter_display()


func _update_letter_display() -> void:
	## Update the letter labels and highlight current position
	for i in range(3):
		var letter = ALPHABET[current_letters[i]]
		letter_labels[i].text = letter

		# Highlight current position with colour
		if i == current_position and name_entry_active:
			letter_labels[i].add_theme_color_override("font_color", Color.YELLOW)
		else:
			letter_labels[i].remove_theme_color_override("font_color")


func _confirm_name() -> void:
	## Confirm the entered name and save score
	var initials = ""
	for i in range(3):
		initials += ALPHABET[current_letters[i]]

	print("[GameOver] Name confirmed: %s, Score: %d, Wave: %d" % [initials, final_score, final_wave])

	name_entry_active = false
	_update_letter_display()

	# Save to high scores via GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		print("[GameOver] Calling GameManager.add_high_score()")
		gm.add_high_score(initials, final_score, final_wave)
	else:
		print("[GameOver] ERROR: GameManager not found!")

	name_confirmed.emit(initials)

	# Re-enable button focus and move focus to buttons
	play_again_button.focus_mode = Control.FOCUS_ALL
	main_menu_button.focus_mode = Control.FOCUS_ALL
	play_again_button.grab_focus()

# ============================================================
# PUBLIC METHODS
# ============================================================

func show_game_over(score: int, wave: int) -> void:
	## Display game over screen with score and wave
	final_score = score
	final_wave = wave

	score_label.text = "Score: %d" % score
	wave_label.text = "Wave: %d" % wave

	# Reset name entry
	current_letters = [0, 0, 0]
	current_position = 0
	name_entry_active = true
	_update_letter_display()

	# Disable button focus during name entry
	play_again_button.focus_mode = Control.FOCUS_NONE
	main_menu_button.focus_mode = Control.FOCUS_NONE

	visible = true


func hide_game_over() -> void:
	visible = false

# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _on_play_again_pressed() -> void:
	play_again_pressed.emit()


func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()
