extends CanvasLayer
class_name HighScoresUI

## High Scores UI Controller
## Displays top 10 scores from GameManager

@onready var score_labels: Array[Label] = []
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

signal back_pressed


func _ready() -> void:
	# Collect score labels
	var container = $CenterContainer/VBoxContainer/ScoreListContainer
	for i in range(10):
		var label = container.get_node_or_null("Score%d" % (i + 1))
		if label:
			score_labels.append(label)

	back_button.pressed.connect(_on_back_pressed)


func show_high_scores() -> void:
	## Display high scores from GameManager
	_refresh_scores()
	visible = true
	back_button.grab_focus()


func hide_high_scores() -> void:
	visible = false


func _refresh_scores() -> void:
	## Update score labels from GameManager data
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return

	var scores = gm.high_scores

	for i in range(score_labels.size()):
		if i < scores.size():
			var entry = scores[i]
			score_labels[i].text = "%2d. %s  %05d  W%d" % [
				i + 1,
				entry.get("initials", "---"),
				entry.get("score", 0),
				entry.get("wave", 1)
			]
		else:
			score_labels[i].text = "%2d. ---  -----" % (i + 1)


func _on_back_pressed() -> void:
	back_pressed.emit()
