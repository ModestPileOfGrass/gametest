extends Node2D

## Base Projectile
## Moves upward (or in set direction) and destroys itself when leaving the screen.
## Uses HitBox component for damage dealing (composition pattern).

## Damage this projectile deals (set by ship when spawning)
var damage: int = GameConstants.PLAYER_PROJECTILE_DAMAGE

## Movement speed (pixels per second)
var speed: float = GameConstants.PROJECTILE_SPEED

## Movement direction (normalized). Default is straight up.
var direction: Vector2 = Vector2.UP

## Reference to VisibleOnScreenNotifier2D for auto-cleanup
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	# Add to player projectiles group
	add_to_group("player_projectiles")

	# Connect visibility notifier for auto-cleanup
	if visibility_notifier:
		visibility_notifier.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	# Move in set direction
	position += direction * speed * delta


## Set the movement direction (for spread shots)
func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()


func _on_screen_exited() -> void:
	## Destroy projectile when it leaves the screen
	queue_free()


## Public method for HitBox to get damage value
func get_damage() -> int:
	return damage
