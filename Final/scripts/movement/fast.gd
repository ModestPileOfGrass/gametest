extends Node
class_name MovementFast

## Fast Movement Component
## Moves parent downward at high speed (dive bomber style)
## Add as child to any Node2D entity

# ============================================================
# CONFIGURATION
# ============================================================

## Target entity to move (leave empty to use parent)
@export var target_node: Node2D

## Vertical scroll speed (pixels per second) - faster than normal
@export var scroll_speed: float = GameConstants.ENEMY_SCROLL_SPEED_FAST

## Despawn margin (pixels beyond viewport before despawn)
@export var despawn_margin: float = GameConstants.ENEMY_DESPAWN_MARGIN

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

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
		push_error("MovementFast: No target_node and parent is not Node2D!")
		return

	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_resized)

	if debug_output:
		print("MovementFast initialized for %s (speed: %.1f)" % [target_node.name, scroll_speed])


func _on_viewport_resized() -> void:
	viewport_size = get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	if not target_node:
		return

	# Move downward at high speed
	target_node.position.y += scroll_speed * delta

	# Despawn when off-screen
	if target_node.position.y > viewport_size.y + despawn_margin:
		if debug_output:
			print("MovementFast: %s despawned (off-screen)" % target_node.name)
		target_node.queue_free()
