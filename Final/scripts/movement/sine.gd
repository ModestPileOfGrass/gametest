extends Node
class_name MovementSine

## Sine Wave Movement Component
## Moves parent downward while following a sine wave pattern
## Add as child to any Node2D entity

# ============================================================
# CONFIGURATION
# ============================================================

## Target entity to move (leave empty to use parent)
@export var target_node: Node2D

## Vertical scroll speed (pixels per second)
@export var scroll_speed: float = GameConstants.ENEMY_SCROLL_SPEED_NORMAL

## Sine wave amplitude (how wide the wave is, pixels)
@export var wave_amplitude: float = GameConstants.ENEMY_SINE_AMPLITUDE

## Sine wave frequency (how many waves per second)
@export var wave_frequency: float = GameConstants.ENEMY_SINE_FREQUENCY

## Despawn margin (pixels beyond viewport before despawn)
@export var despawn_margin: float = GameConstants.ENEMY_DESPAWN_MARGIN

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

## Time elapsed since spawn (for sine calculation)
var time_elapsed: float = 0.0

## Initial X position (center of sine wave)
var initial_x: float = 0.0

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
		push_error("MovementSine: No target_node and parent is not Node2D!")
		return

	# Store initial X position as the center of the sine wave
	initial_x = target_node.position.x

	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	if debug_output:
		print("MovementSine initialized for %s (speed: %.1f, amplitude: %.1f)" % [target_node.name, scroll_speed, wave_amplitude])


func _on_viewport_resized() -> void:
	viewport_size = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	if not target_node:
		return

	time_elapsed += delta

	# Move downward
	target_node.position.y += scroll_speed * delta

	# Calculate sine wave horizontal position
	var sine_offset = sin(time_elapsed * wave_frequency * TAU) * wave_amplitude
	target_node.position.x = initial_x + sine_offset

	# Despawn when off-screen
	if target_node.position.y > viewport_size.y + despawn_margin:
		if debug_output:
			print("MovementSine: %s despawned (off-screen)" % target_node.name)
		target_node.queue_free()
