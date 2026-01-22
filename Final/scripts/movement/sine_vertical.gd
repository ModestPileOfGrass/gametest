extends Node
class_name MovementSineVertical

## Vertical Sine Wave Movement Component
## Moves parent downward while oscillating UP and DOWN (vertical bobbing)
## Add as child to any Node2D entity

# ============================================================
# CONFIGURATION
# ============================================================

## Target entity to move (leave empty to use parent)
@export var target_node: Node2D

## Base vertical scroll speed (pixels per second)
@export var scroll_speed: float = GameConstants.ENEMY_SCROLL_SPEED_NORMAL

## Vertical oscillation amplitude (how far up/down it bobs)
@export var wave_amplitude: float = 30.0

## Vertical oscillation frequency (bobs per second)
@export var wave_frequency: float = 2.0

## Despawn margin (pixels beyond viewport before despawn)
@export var despawn_margin: float = GameConstants.ENEMY_DESPAWN_MARGIN

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

## Time elapsed since spawn (for sine calculation)
var time_elapsed: float = 0.0

## Base Y position (center of vertical oscillation)
var base_y: float = 0.0

## Accumulated scroll distance
var scroll_distance: float = 0.0

## Cached viewport size
var viewport_size: Vector2

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# Use parent if no target specified
	if not target_node:
		target_node = get_parent() as Node2D

	if not target_node:
		push_error("MovementSineVertical: No target_node and parent is not Node2D!")
		return

	# Store initial Y position
	base_y = target_node.position.y

	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	if debug_output:
		print("MovementSineVertical initialized for %s (speed: %.1f, amplitude: %.1f)" % [target_node.name, scroll_speed, wave_amplitude])


func _on_viewport_resized() -> void:
	viewport_size = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	if not target_node:
		return

	time_elapsed += delta

	# Accumulate base scroll distance
	scroll_distance += scroll_speed * delta

	# Calculate vertical sine oscillation
	var sine_offset = sin(time_elapsed * wave_frequency * TAU) * wave_amplitude

	# Position = base + scroll + oscillation
	target_node.position.y = base_y + scroll_distance + sine_offset

	# Despawn when off-screen
	if target_node.position.y > viewport_size.y + despawn_margin:
		if debug_output:
			print("MovementSineVertical: %s despawned (off-screen)" % target_node.name)
		target_node.queue_free()
