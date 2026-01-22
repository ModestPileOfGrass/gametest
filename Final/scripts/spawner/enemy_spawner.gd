extends Node
class_name EnemySpawner

## Enemy Spawner
## Spawns enemies in waves with increasing difficulty
## Uses EnemyType child nodes to define which enemies can spawn
## Pauses spawning when player dies

# Signals
signal enemy_spawned(enemy: Node2D)
signal wave_completed(wave_number: int)

# Configuration
@export var config: EnemySpawnerConfig
@export var debug_output: bool = false

# State
var enemy_scenes: Array[PackedScene] = []
var viewport_size: Vector2
var spawn_timer: float = 0.0
var current_spawn_interval: float
var current_wave: int = 1
var enemies_spawned_this_wave: int = 0
var enemies_per_wave: int
var player_ship: Node = null


func _ready() -> void:
	viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Load default config if none assigned
	if not config:
		config = EnemySpawnerConfig.new()
		if debug_output:
			print("EnemySpawner: Using default configuration")

	# Initialize from config
	current_spawn_interval = config.spawn_interval
	enemies_per_wave = config.base_enemies_per_wave

	# Collect enemy scenes from EnemyType children
	_collect_enemy_types()

	# Connect to player death signal
	_connect_to_player()

	if debug_output:
		print("EnemySpawner ready: %d enemy types, %d enemies per wave" % [
			enemy_scenes.size(),
			enemies_per_wave
		])


func _collect_enemy_types() -> void:
	for child in get_children():
		if child is EnemyType and child.enemy_scene:
			enemy_scenes.append(child.enemy_scene)
			if debug_output:
				print("  Registered enemy type: %s" % child.name)

	if enemy_scenes.is_empty():
		push_warning("EnemySpawner: No EnemyType children with scenes found!")


func _connect_to_player() -> void:
	# Wait one frame for scene tree to be ready
	await get_tree().process_frame

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ship = players[0]
		if player_ship.get("stats"):
			var stats = player_ship.stats
			if stats and stats.has_signal("died"):
				stats.died.connect(_on_player_died)
				if debug_output:
					print("EnemySpawner: Connected to player death signal")
	else:
		if debug_output:
			print("EnemySpawner: No player found (spawner will run indefinitely)")


func _on_viewport_resized() -> void:
	viewport_size = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	spawn_timer += delta

	if spawn_timer >= current_spawn_interval:
		spawn_enemy()
		spawn_timer = 0.0


func spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return

	var scene_to_spawn: PackedScene = enemy_scenes.pick_random()
	var enemy = scene_to_spawn.instantiate()

	var spawn_x = randf_range(
		config.spawn_x_margin,
		viewport_size.x - config.spawn_x_margin
	)
	var spawn_pos = Vector2(spawn_x, config.spawn_y_offset)

	enemy.position = spawn_pos
	get_parent().add_child(enemy)

	enemies_spawned_this_wave += 1
	enemy_spawned.emit(enemy)

	if debug_output:
		print("Spawned enemy at %s (wave %d: %d/%d)" % [
			spawn_pos,
			current_wave,
			enemies_spawned_this_wave,
			enemies_per_wave
		])

	if enemies_spawned_this_wave >= enemies_per_wave:
		_complete_wave()


func _complete_wave() -> void:
	var completed_wave = current_wave
	current_wave += 1
	enemies_spawned_this_wave = 0

	enemies_per_wave = config.base_enemies_per_wave + (current_wave - 1) * config.wave_enemies_increase

	current_spawn_interval = max(
		current_spawn_interval * config.difficulty_increase_rate,
		config.min_spawn_interval
	)

	if debug_output:
		print("Wave %d completed! Next wave: %d enemies, spawn interval: %.2fs" % [
			completed_wave,
			enemies_per_wave,
			current_spawn_interval
		])

	wave_completed.emit(completed_wave)


func _on_player_died() -> void:
	if debug_output:
		print("EnemySpawner: Player died, pausing spawner")
	pause_spawning()


func pause_spawning() -> void:
	set_process(false)


func resume_spawning() -> void:
	set_process(true)


func reset_spawner() -> void:
	current_wave = 1
	enemies_spawned_this_wave = 0
	enemies_per_wave = config.base_enemies_per_wave
	current_spawn_interval = config.spawn_interval
	spawn_timer = 0.0
	resume_spawning()


func get_wave_info() -> Dictionary:
	return {
		"wave": current_wave,
		"enemies_per_wave": enemies_per_wave,
		"enemies_spawned": enemies_spawned_this_wave,
		"spawn_interval": current_spawn_interval
	}
