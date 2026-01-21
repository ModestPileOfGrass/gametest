extends Node
class_name PickupSpawner

## Pickup Spawner
## Spawns pickups at intervals during gameplay
## Uses PickupType child nodes to define which pickups can spawn
## Spawns alongside enemies (during waves)

# ============================================================
# SIGNALS
# ============================================================

signal pickup_spawned(pickup: Node2D)

# ============================================================
# CONFIGURATION
# ============================================================

@export var config: PickupSpawnerConfig
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

var pickup_scenes: Array[PackedScene] = []
var pickup_weights: Array[float] = []
var total_weight: float = 0.0
var viewport_size: Vector2
var spawn_timer: float = 0.0
var current_spawn_interval: float
var player_ship: Node = null

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Load default config if none assigned
	if not config:
		config = PickupSpawnerConfig.new()
		if debug_output:
			print("PickupSpawner: Using default configuration")

	# Initialize from config
	current_spawn_interval = config.spawn_interval

	# Collect pickup scenes from PickupType children
	_collect_pickup_types()

	# Connect to player death signal
	_connect_to_player()

	if debug_output:
		print("PickupSpawner ready: %d pickup types" % pickup_scenes.size())


func _collect_pickup_types() -> void:
	## Gather all PickupType children and their scenes
	for child in get_children():
		if child is PickupType and child.pickup_scene:
			pickup_scenes.append(child.pickup_scene)
			pickup_weights.append(child.spawn_weight)
			total_weight += child.spawn_weight
			if debug_output:
				print("  Registered pickup: %s (weight: %.1f)" % [child.name, child.spawn_weight])

	if pickup_scenes.is_empty():
		push_warning("PickupSpawner: No PickupType children with scenes found!")


func _connect_to_player() -> void:
	## Connect to player death signal to pause spawning
	await get_tree().process_frame

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ship = players[0]
		if player_ship.get("stats"):
			var stats = player_ship.stats
			if stats and stats.has_signal("died"):
				stats.died.connect(_on_player_died)
				if debug_output:
					print("PickupSpawner: Connected to player death signal")


func _on_viewport_resized() -> void:
	viewport_size = get_viewport().get_visible_rect().size


# ============================================================
# SPAWNING
# ============================================================

func _process(delta: float) -> void:
	spawn_timer += delta

	if spawn_timer >= current_spawn_interval:
		spawn_pickup()
		spawn_timer = 0.0


func spawn_pickup() -> void:
	## Spawn a random pickup at top of screen
	if pickup_scenes.is_empty():
		return

	# Weighted random selection
	var scene_to_spawn = _select_weighted_pickup()
	var pickup = scene_to_spawn.instantiate()

	# Random X position within margins
	var spawn_x = randf_range(
		config.spawn_x_margin,
		viewport_size.x - config.spawn_x_margin
	)
	var spawn_pos = Vector2(spawn_x, config.spawn_y_offset)

	pickup.position = spawn_pos
	get_parent().add_child(pickup)

	pickup_spawned.emit(pickup)

	if debug_output:
		print("Spawned pickup at %s" % spawn_pos)


func _select_weighted_pickup() -> PackedScene:
	## Select a pickup scene using weighted random
	var roll = randf() * total_weight
	var cumulative: float = 0.0

	for i in range(pickup_scenes.size()):
		cumulative += pickup_weights[i]
		if roll <= cumulative:
			return pickup_scenes[i]

	# Fallback to last pickup
	return pickup_scenes[-1]


# ============================================================
# DIFFICULTY SCALING
# ============================================================

func on_wave_completed(_wave_number: int) -> void:
	## Called when enemy wave completes - speed up pickup spawns
	current_spawn_interval = max(
		current_spawn_interval * config.difficulty_multiplier,
		config.min_spawn_interval
	)

	if debug_output:
		print("PickupSpawner: Spawn interval now %.2fs" % current_spawn_interval)


# ============================================================
# CONTROL
# ============================================================

func _on_player_died() -> void:
	if debug_output:
		print("PickupSpawner: Player died, pausing spawner")
	pause_spawning()


func pause_spawning() -> void:
	set_process(false)


func resume_spawning() -> void:
	set_process(true)


func reset_spawner() -> void:
	current_spawn_interval = config.spawn_interval
	spawn_timer = 0.0
	resume_spawning()
