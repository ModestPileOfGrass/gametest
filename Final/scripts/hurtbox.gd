extends Area2D
class_name HurtBox

## HurtBox Component - Composition Pattern
## A reusable component that detects incoming damage for any entity.
## Add as a child of any entity (ship, enemy) that needs to receive damage.
##
## Usage:
##   1. Add HurtBox (Area2D) as a child of your entity
##   2. Add a CollisionShape2D child to the HurtBox
##   3. Configure collision layers/masks in Inspector
##   4. Connect to signals or let HurtBox call parent's take_damage()
##
## The parent entity should implement:
##   - take_damage(amount: int) -> void
##   - Or have a 'stats' property with take_damage(amount: int)

## Target entity to apply damage to (leave empty to use parent automatically)
@export var target_entity: Node

## Fixed damage amount (0 = calculate from collision source)
@export var damage_override: int = 0

## Enable debug output for collision events
@export var debug_output: bool = false

## Signals for flexible integration
signal damage_received(amount: int, source: Node)
signal hit_detected(collider: Node)


func _ready() -> void:
	# If no target specified, use parent
	if not target_entity:
		target_entity = get_parent()

	if not target_entity:
		push_error("HurtBox: No target_entity and no parent found!")
		return

	# Connect collision signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if debug_output:
		print("HurtBox ready for: %s" % target_entity.name)


func _on_area_entered(area: Area2D) -> void:
	## Handle collision with Area2D (projectiles, hazards)
	if debug_output:
		print("%s HurtBox hit by Area2D: %s" % [target_entity.name, area.name])

	hit_detected.emit(area)

	var damage = _calculate_damage(area)
	if damage > 0:
		damage_received.emit(damage, area)
		_apply_damage(damage, area)


func _on_body_entered(body: Node2D) -> void:
	## Handle collision with physics body (CharacterBody2D enemies)
	if debug_output:
		print("%s HurtBox hit by Body: %s" % [target_entity.name, body.name])

	hit_detected.emit(body)

	var damage = _calculate_damage(body)
	if damage > 0:
		damage_received.emit(damage, body)
		_apply_damage(damage, body)


func _calculate_damage(source: Node) -> int:
	## Calculate damage amount from collision source
	# Use override if set
	if damage_override > 0:
		return damage_override

	# Try to get damage from source's get_damage() method
	if source.has_method("get_damage"):
		return source.get_damage()

	# Check for damage property on source
	if "damage" in source:
		return source.damage

	# Fall back to group-based damage values
	if source.is_in_group("enemy_projectiles"):
		return GameConstants.ENEMY_PROJECTILE_DAMAGE
	elif source.is_in_group("enemies"):
		return GameConstants.ENEMY_COLLISION_DAMAGE
	elif source.is_in_group("walls"):
		return GameConstants.WALL_COLLISION_DAMAGE
	elif source.is_in_group("pickups"):
		return 0  # Pickups don't deal damage

	return 0


func _apply_damage(damage: int, _source: Node) -> void:
	## Apply damage to target entity
	if not target_entity:
		return

	# Method 1: Direct take_damage() call
	if target_entity.has_method("take_damage"):
		target_entity.take_damage(damage)
		return

	# Method 2: Stats-based damage (for entities with stats resource)
	if "stats" in target_entity and target_entity.stats:
		if target_entity.stats.has_method("take_damage"):
			target_entity.stats.take_damage(damage)
			return

	if debug_output:
		push_warning("HurtBox: target %s has no damage handling" % target_entity.name)
