extends Node
class_name MovementZigZag

## ZigZag Movement Component
## Moves parent downward while oscillating left and right
## Add as child to any Node2D entity

# ============================================================
# CONFIGURATION
# ============================================================

## Target entity to move (leave empty to use parent)
@export var target_node: Node2D

## Vertical scroll speed (pixels per second)
@export var scroll_speed: float = GameConstants.ENEMY_SCROLL_SPEED_NORMAL

## Horizontal zigzag speed (pixels per second)
@export var zigzag_speed: float = GameConstants.ENEMY_ZIGZAG_SPEED

## How wide the zigzag pattern is (pixels)
@export var zigzag_amplitude: float = GameConstants.ENEMY_ZIGZAG_AMPLITUDE

## Despawn margin (pixels beyond viewport before despawn)
@export var despawn_margin: float = GameConstants.ENEMY_DESPAWN_MARGIN

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

## Current direction: 1 = right, -1 = left
var zigzag_direction: int = 1

## Distance from starting position
var distance_from_center: float = 0.0

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
		push_error("MovementZigZag: No target_node and parent is not Node2D!")
		return

	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	if debug_output:
		print("MovementZigZag initialized for %s (speed: %.1f, zigzag: %.1f)" % [target_node.name, scroll_speed, zigzag_speed])


func _on_viewport_resized() -> void:
	viewport_size = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	if not target_node:
		return

	# Move downward
	target_node.position.y += scroll_speed * delta

	# Zigzag left/right
	var horizontal_movement = zigzag_speed * delta * zigzag_direction
	target_node.position.x += horizontal_movement
	distance_from_center += horizontal_movement

	# Reverse direction when reaching zigzag amplitude
	if abs(distance_from_center) >= zigzag_amplitude:
		zigzag_direction *= -1

	# Despawn when off-screen
	if target_node.position.y > viewport_size.y + despawn_margin:
		if debug_output:
			print("MovementZigZag: %s despawned (off-screen)" % target_node.name)
		target_node.queue_free()
