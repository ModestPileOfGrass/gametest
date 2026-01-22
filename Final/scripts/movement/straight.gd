extends Node
class_name MovementStraight

## Straight Movement Component
## Moves parent downward in a straight line (classic vertical scroller)
## Add as child to any Node2D entity
##
## Usage:
##   1. Add this as a child node to any Node2D (enemy, pickup, obstacle, etc.)
##   2. Assign the target_node in Inspector (or leave empty to auto-use parent)
##   3. Configure the speed property in the Inspector
##   4. The target node will automatically scroll down and despawn when off-screen

# ============================================================
# CONFIGURATION
# ============================================================

## Target node to scroll (leave empty to use parent automatically)
@export var target_node: Node2D

## Movement speed (pixels per second, scrolls downward)
@export var speed: float = GameConstants.ENEMY_SCROLL_SPEED_NORMAL

## Additional margin beyond viewport before despawning (prevents pop-out)
@export var despawn_margin: float = GameConstants.ENEMY_DESPAWN_MARGIN

## Enable debug output for spawn/despawn events
@export var debug_output: bool = false

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# If no target specified, use parent
	if not target_node:
		target_node = get_parent() as Node2D

	if not target_node:
		push_error("MovementStraight: No target_node specified and parent is not Node2D!")
		return

	if debug_output:
		print("MovementStraight initialized for %s at position: %s" % [target_node.name, target_node.global_position])


func _physics_process(delta: float) -> void:
	if not target_node:
		return

	# Move target downward
	target_node.position.y += speed * delta

	# Check if target has scrolled off bottom of screen
	var viewport_height = get_viewport().get_visible_rect().size.y
	if target_node.global_position.y > viewport_height + despawn_margin:
		if debug_output:
			print("%s left screen at Y: %.1f (despawned)" % [target_node.name, target_node.global_position.y])
		target_node.queue_free()
