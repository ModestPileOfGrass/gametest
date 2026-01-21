extends Node2D

## Main Scene Controller
## Orchestrates game flow between menu, gameplay, and game over states
## Connects UI layers to GameManager signals

# ============================================================
# NODE REFERENCES
# ============================================================

@onready var ship: CharacterBody2D = $Ship
@onready var hud: CanvasLayer = $HUD
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var pickup_spawner: PickupSpawner = $PickupSpawner

## UI Layers
@onready var main_menu: MainMenuUI = $MainMenu
@onready var game_over_ui: GameOverUI = $GameOver
@onready var high_scores_ui: HighScoresUI = $HighScores

## Store initial ship position for resets
var ship_start_position: Vector2

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# Store ship starting position
	ship_start_position = ship.position

	# Connect to GameManager
	_connect_game_manager()

	# Connect HUD and spawners
	_connect_hud()
	_connect_spawner()
	_connect_pickup_spawner()

	# Connect UI signals
	_connect_ui_signals()

	# Start in menu state
	_show_menu()

	print("Main ready. Ship at: ", ship.position)


# ============================================================
# GAME MANAGER CONNECTION
# ============================================================

func _connect_game_manager() -> void:
	## Connect to GameManager state changes
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.state_changed.connect(_on_state_changed)
		print("Main: Connected to GameManager")
	else:
		push_error("Main: GameManager not found!")


func _on_state_changed(new_state: String) -> void:
	## Handle game state transitions
	match new_state:
		GameConstants.STATE_MENU:
			_show_menu()
		GameConstants.STATE_PLAYING:
			_start_gameplay()
		GameConstants.STATE_GAME_OVER:
			_show_game_over()
		GameConstants.STATE_HIGH_SCORES:
			_show_high_scores()


# ============================================================
# UI SIGNAL CONNECTIONS
# ============================================================

func _connect_ui_signals() -> void:
	## Connect all UI button signals
	# Main Menu
	if main_menu:
		main_menu.start_game_pressed.connect(_on_start_game)
		main_menu.high_scores_pressed.connect(_on_show_high_scores)
		main_menu.quit_pressed.connect(_on_quit_game)

	# Game Over
	if game_over_ui:
		game_over_ui.play_again_pressed.connect(_on_play_again)
		game_over_ui.main_menu_pressed.connect(_on_return_to_menu)

	# High Scores
	if high_scores_ui:
		high_scores_ui.back_pressed.connect(_on_high_scores_back)


# ============================================================
# STATE HANDLERS
# ============================================================

func _show_menu() -> void:
	## Display main menu, hide everything else
	_hide_all_ui()
	if main_menu:
		main_menu.show_menu()

	# Hide gameplay elements
	ship.visible = false
	ship.set_physics_process(false)
	hud.visible = false

	# Pause spawners
	if enemy_spawner:
		enemy_spawner.set_process(false)
	if pickup_spawner:
		pickup_spawner.set_process(false)


func _start_gameplay() -> void:
	## Begin actual gameplay
	_hide_all_ui()

	# Reset and show ship
	_reset_ship()
	ship.visible = true
	ship.set_physics_process(true)

	# Show HUD
	hud.visible = true

	# Start spawners
	if enemy_spawner:
		enemy_spawner.reset_spawner()
	if pickup_spawner:
		pickup_spawner.reset_spawner()


func _show_game_over() -> void:
	## Display game over screen with score entry
	_hide_all_ui()

	# Get score data from GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm and game_over_ui:
		var data = gm.get_game_data()
		game_over_ui.show_game_over(
			data.get("score", 0),
			data.get("wave", 1)
		)

	# Keep HUD visible to show final stats
	hud.visible = true


func _show_high_scores() -> void:
	## Display high scores screen
	_hide_all_ui()
	if high_scores_ui:
		high_scores_ui.show_high_scores()


func _hide_all_ui() -> void:
	## Hide all UI layers
	if main_menu:
		main_menu.hide_menu()
	if game_over_ui:
		game_over_ui.hide_game_over()
	if high_scores_ui:
		high_scores_ui.hide_high_scores()


# ============================================================
# GAME RESET
# ============================================================

func _reset_ship() -> void:
	## Reset ship to starting state
	ship.position = ship_start_position

	# Reset stats
	if ship.stats:
		ship.stats.reset()

	# Re-enable effect manager
	if ship.effect_manager:
		ship.effect_manager.clear_all_effects()
		ship.effect_manager.set_process(true)

	# Reconnect HUD after reset
	_connect_hud()


func _clear_enemies() -> void:
	## Remove all enemies from scene
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()


func _clear_pickups() -> void:
	## Remove all pickups from scene
	for pickup in get_tree().get_nodes_in_group("pickups"):
		pickup.queue_free()


func _clear_projectiles() -> void:
	## Remove all projectiles from scene
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		projectile.queue_free()


# ============================================================
# UI SIGNAL HANDLERS
# ============================================================

func _on_start_game() -> void:
	## Start button pressed
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.change_state(GameConstants.STATE_PLAYING)


func _on_show_high_scores() -> void:
	## High Scores button pressed from menu
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.change_state(GameConstants.STATE_HIGH_SCORES)


func _on_quit_game() -> void:
	## Quit button pressed
	get_tree().quit()


func _on_play_again() -> void:
	## Play Again button pressed from game over
	_clear_enemies()
	_clear_pickups()
	_clear_projectiles()

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.clear_game_data()
		gm.change_state(GameConstants.STATE_PLAYING)


func _on_return_to_menu() -> void:
	## Main Menu button pressed from game over
	_clear_enemies()
	_clear_pickups()
	_clear_projectiles()

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.clear_game_data()
		gm.change_state(GameConstants.STATE_MENU)


func _on_high_scores_back() -> void:
	## Back button pressed from high scores
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.change_state(GameConstants.STATE_MENU)


# ============================================================
# EXISTING CONNECTIONS
# ============================================================

func _connect_hud() -> void:
	if hud and ship and ship.stats:
		hud.connect_to_ship(ship)
		print("HUD connected to ship")
	else:
		push_error("Main: Could not connect HUD to ship")


func _connect_spawner() -> void:
	if enemy_spawner:
		enemy_spawner.wave_completed.connect(_on_wave_completed)
		enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
		print("Spawner signals connected")
	else:
		push_warning("Main: No EnemySpawner found")


func _connect_pickup_spawner() -> void:
	if pickup_spawner:
		pickup_spawner.pickup_spawned.connect(_on_pickup_spawned)
		print("PickupSpawner signals connected")
	else:
		push_warning("Main: No PickupSpawner found")


func _on_wave_completed(wave_number: int) -> void:
	print("Wave %d completed!" % wave_number)
	# Speed up pickup spawns as difficulty increases
	if pickup_spawner:
		pickup_spawner.on_wave_completed(wave_number)


func _on_enemy_spawned(_enemy: Node2D) -> void:
	pass


func _on_pickup_spawned(_pickup: Node2D) -> void:
	pass
