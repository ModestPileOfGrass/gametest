extends Area2D
class_name HitBox

## HitBox Component - Composition Pattern
## A reusable component that deals damage to targets on collision.
## Add as a child of projectiles or other damage-dealing entities.
##
## Usage:
##   1. Add HitBox (Area2D) as a child of your projectile/weapon
##   2. Add a CollisionShape2D child to the HitBox
##   3. Configure collision layers/masks in Inspector
##   4. Set target_groups to filter which entities can be hit
##   5. Set destroy_on_hit if the owner should be destroyed after hitting

## Entity that owns this HitBox (for destruction)
@export var owner_entity: Node

## Damage to deal on hit (0 = get from owner's damage property)
@export var damage: int = 0

## Destroy owner entity after hitting a target
@export var destroy_on_hit: bool = true

## Only hit entities in these groups (empty = hit anything)
@export var target_groups: Array[String] = []

## Enable debug output
@export var debug_output: bool = false

## Signals
signal target_hit(target: Node, damage_dealt: int)
signal hit_completed


func _ready() -> void:
	# If no owner specified, use parent
	if not owner_entity:
		owner_entity = get_parent()

	# Connect collision signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if debug_output:
		print("HitBox ready for: %s" % (owner_entity.name if owner_entity else "unknown"))


func _on_area_entered(area: Area2D) -> void:
	## Handle collision with Area2D
	_try_apply_damage(area)


func _on_body_entered(body: Node2D) -> void:
	## Handle collision with physics body
	_try_apply_damage(body)


func _try_apply_damage(target: Node) -> void:
	## Attempt to apply damage to target
	# Check if target is in allowed groups
	if not _is_valid_target(target):
		return

	# Calculate damage to deal
	var damage_amount = _get_damage()

	if debug_output:
		print("HitBox dealing %d damage to %s" % [damage_amount, target.name])

	# Try to apply damage to target
	if target.has_method("take_damage"):
		target.take_damage(damage_amount)
		target_hit.emit(target, damage_amount)
	elif "stats" in target and target.stats and target.stats.has_method("take_damage"):
		target.stats.take_damage(damage_amount)
		target_hit.emit(target, damage_amount)

	hit_completed.emit()

	# Destroy owner if configured
	if destroy_on_hit and owner_entity:
		owner_entity.queue_free()


func _is_valid_target(target: Node) -> bool:
	## Check if target is in allowed groups
	# If no groups specified, accept all targets
	if target_groups.is_empty():
		return true

	# Check each allowed group
	for group in target_groups:
		if target.is_in_group(group):
			return true

	return false


func _get_damage() -> int:
	## Get damage amount to deal
	# Use configured damage if set
	if damage > 0:
		return damage

	# Try to get damage from owner
	if owner_entity:
		if owner_entity.has_method("get_damage"):
			return owner_entity.get_damage()
		if "damage" in owner_entity:
			return owner_entity.damage

	# Default damage
	return GameConstants.PLAYER_PROJECTILE_DAMAGE


## Public method to get this HitBox's damage
func get_damage() -> int:
	return _get_damage()
