extends Node

## Game Manager Singleton
## Handles game state, high scores, and data passing between screens
## Registered as autoload in Project Settings

# ============================================================
# SIGNALS
# ============================================================

signal state_changed(new_state: String)
signal high_scores_updated

# ============================================================
# STATE
# ============================================================

var current_state: String = GameConstants.STATE_MENU

## Game data for current session (set on game over)
var _game_data: Dictionary = {}

## High scores array (loaded from file)
var high_scores: Array = []

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	load_high_scores()
	print("GameManager ready. High scores loaded: %d entries" % high_scores.size())


# ============================================================
# STATE MANAGEMENT
# ============================================================

func change_state(new_state: String) -> void:
	## Change game state and emit signal
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)
		print("GameManager: State changed to '%s'" % new_state)


func is_playing() -> bool:
	return current_state == GameConstants.STATE_PLAYING


# ============================================================
# GAME DATA
# ============================================================

func set_game_data(score: int, wave: int) -> void:
	## Store game data when game ends (for game over screen)
	_game_data = {
		"score": score,
		"wave": wave
	}
	print("GameManager: Game data set - Score: %d, Wave: %d" % [score, wave])


func get_game_data() -> Dictionary:
	## Retrieve stored game data
	return _game_data


func clear_game_data() -> void:
	_game_data = {}


# ============================================================
# HIGH SCORES
# ============================================================

func add_high_score(initials: String, score: int, wave: int) -> int:
	## Add a new high score entry
	## Returns the rank (1-10) or -1 if not in top 10
	var entry = {
		"initials": initials.to_upper().substr(0, 3),
		"score": score,
		"wave": wave,
		"date": Time.get_date_string_from_system()
	}

	# Insert in sorted position
	var rank = -1
	for i in range(high_scores.size()):
		if score > high_scores[i]["score"]:
			high_scores.insert(i, entry)
			rank = i + 1
			break

	# If not inserted and list isn't full, append
	if rank == -1 and high_scores.size() < GameConstants.MAX_HIGH_SCORES:
		high_scores.append(entry)
		rank = high_scores.size()

	# Trim to max entries
	while high_scores.size() > GameConstants.MAX_HIGH_SCORES:
		high_scores.pop_back()

	# Save to file
	save_high_scores()
	high_scores_updated.emit()

	print("GameManager: High score added - %s: %d (rank %d)" % [initials, score, rank])
	return rank


func is_high_score(score: int) -> bool:
	## Check if score qualifies for high score list
	if high_scores.size() < GameConstants.MAX_HIGH_SCORES:
		return true
	return score > high_scores[-1]["score"]


func save_high_scores() -> void:
	## Save high scores to JSON file
	var file = FileAccess.open(GameConstants.HIGH_SCORES_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify({"scores": high_scores}, "\t")
		file.store_string(json_string)
		file.close()
		print("GameManager: High scores saved to %s" % GameConstants.HIGH_SCORES_FILE)
	else:
		push_error("GameManager: Failed to save high scores")


func load_high_scores() -> void:
	## Load high scores from JSON file
	if not FileAccess.file_exists(GameConstants.HIGH_SCORES_FILE):
		high_scores = []
		print("GameManager: No high scores file found, starting fresh")
		return

	var file = FileAccess.open(GameConstants.HIGH_SCORES_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			if data.has("scores"):
				high_scores = data["scores"]
				print("GameManager: Loaded %d high scores" % high_scores.size())
			else:
				high_scores = []
		else:
			push_error("GameManager: Failed to parse high scores JSON")
			high_scores = []
	else:
		push_error("GameManager: Failed to open high scores file")
		high_scores = []
