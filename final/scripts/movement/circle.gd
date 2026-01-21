extends Node
class_name MovementCircle

## Circular Movement Component
## Moves parent downward while orbiting in a circle
## Add as child to any Node2D entity

# ============================================================
# CONFIGURATION
# ============================================================

## Target entity to move (leave empty to use parent)
@export var target_node: Node2D

## Base vertical scroll speed (pixels per second)
@export var scroll_speed: float = 80.0

## Circle radius (pixels)
@export var circle_radius: float = 40.0

## Rotation speed (full circles per second)
@export var rotation_speed: float = 1.5

## Despawn margin (pixels beyond viewport before despawn)
@export var despawn_margin: float = GameConstants.ENEMY_DESPAWN_MARGIN

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

## Time elapsed since spawn
var time_elapsed: float = 0.0

## Starting position (center of circle path)
var start_position: Vector2

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
		push_error("MovementCircle: No target_node and parent is not Node2D!")
		return

	# Store starting position
	start_position = target_node.position

	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	if debug_output:
		print("MovementCircle initialized for %s (radius: %.1f, speed: %.1f)" % [target_node.name, circle_radius, rotation_speed])


func _on_viewport_resized() -> void:
	viewport_size = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	if not target_node:
		return

	time_elapsed += delta

	# Accumulate scroll distance
	scroll_distance += scroll_speed * delta

	# Calculate circular motion offset
	var angle = time_elapsed * rotation_speed * TAU
	var circle_offset = Vector2(
		cos(angle) * circle_radius,
		sin(angle) * circle_radius
	)

	# Position = start + scroll + circle
	target_node.position = Vector2(
		start_position.x + circle_offset.x,
		start_position.y + scroll_distance + circle_offset.y
	)

	# Despawn when off-screen
	if target_node.position.y > viewport_size.y + despawn_margin:
		if debug_output:
			print("MovementCircle: %s despawned (off-screen)" % target_node.name)
		target_node.queue_free()
