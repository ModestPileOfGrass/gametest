extends Area2D
class_name Pickup

## Base Pickup Class
## All collectible pickups extend this class
## Uses composition pattern with MovementStraight for scrolling

# ============================================================
# CONFIGURATION
# ============================================================

## Type of pickup effect
@export_enum("health", "shield", "invincibility", "fire_rate", "spread") var pickup_type: String = "health"

## Value/amount for this pickup (health amount, shield amount, etc.)
@export var value: int = 30

## Visual colour for this pickup
@export var color: Color = GameConstants.PICKUP_COLOR_HEALTH

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# Add to pickups group for collision detection
	add_to_group("pickups")

	# Set collision layer (Layer 5 = pickups)
	collision_layer = GameConstants.COLLISION_LAYER_PICKUP
	collision_mask = 0  # Pickups don't detect anything, ship detects them

	# Update visual colour
	_update_visual()

	if debug_output:
		print("Pickup spawned: %s (value: %d) at %s" % [pickup_type, value, global_position])


func _update_visual() -> void:
	## Update Polygon2D colour to match pickup type
	var polygon = get_node_or_null("Polygon2D")
	if polygon and polygon is Polygon2D:
		polygon.color = color


# ============================================================
# PICKUP EFFECT
# ============================================================

func apply_effect(ship: CharacterBody2D) -> void:
	## Apply pickup effect to the ship
	## Called by ship.gd when pickup is collected

	if debug_output:
		print("Pickup collected: %s (value: %d)" % [pickup_type, value])

	match pickup_type:
		"health":
			_apply_health(ship)
		"shield":
			_apply_shield(ship)
		"invincibility":
			_apply_invincibility(ship)
		"fire_rate":
			_apply_fire_rate(ship)
		"spread":
			_apply_spread(ship)

	# Remove pickup after collection
	queue_free()


func _apply_health(ship: CharacterBody2D) -> void:
	## Restore health to ship
	if ship.stats:
		ship.stats.heal(value)
		if debug_output:
			print("  → Healed %d health" % value)
					# AUDIO: Play health pickup sound
		AudioManager.play_sfx("pickup_health")


func _apply_shield(ship: CharacterBody2D) -> void:
	## Add shields to ship
	if ship.stats:
		ship.stats.add_shields(value)
		if debug_output:
			print("  → Added %d shields" % value)
					# AUDIO: Play shield pickup sound
		AudioManager.play_sfx("pickup_shield")


func _apply_invincibility(ship: CharacterBody2D) -> void:
	## Activate invincibility via EffectManager (Module 05)
	if ship.effect_manager:
		# Use existing InvincibilityEffect from Module 05
		var effect = InvincibilityEffect.new()
		ship.effect_manager.add_effect(effect)
		if debug_output:
			print("  → Invincibility activated for %.0fs" % effect.duration)
					# AUDIO: Play powerup sound
		AudioManager.play_sfx("pickup_powerup")
	else:
		# Fallback: direct stats manipulation (not recommended)
		if ship.stats:
			ship.stats.powerup_invulnerable = true
			ship.stats.powerup_invulnerability_timer = GameConstants.INVINCIBILITY_DURATION
			push_warning("Pickup: No EffectManager found, using direct stats")


func _apply_fire_rate(ship: CharacterBody2D) -> void:
	## Activate fire rate boost via EffectManager
	if ship.effect_manager:
		var effect = FireRateBoostEffect.new()
		ship.effect_manager.add_effect(effect)
		if debug_output:
			print("  → Fire Rate Boost activated for %.0fs" % effect.duration)
					# AUDIO: Play powerup sound
		AudioManager.play_sfx("pickup_powerup")

	else:
		# Fallback: direct stats manipulation
		if ship.stats:
			ship.stats.fire_rate_effect_multiplier = GameConstants.FIRE_RATE_BOOST_MULTIPLIER
			push_warning("Pickup: No EffectManager found, using direct stats")


func _apply_spread(ship: CharacterBody2D) -> void:
	## Activate spread shot via EffectManager
	if ship.effect_manager:
		var effect = SpreadShotEffect.new()
		ship.effect_manager.add_effect(effect)
		if debug_output:
			print("  → Spread Shot activated for %.0fs" % effect.duration)
					# AUDIO: Play powerup sound
		AudioManager.play_sfx("pickup_powerup")
	else:
		# Fallback: direct stats manipulation
		if ship.stats:
			ship.stats.spread_shot = true
			ship.stats.spread_count = GameConstants.SPREAD_SHOT_COUNT
			ship.stats.spread_angle = GameConstants.SPREAD_SHOT_ANGLE
			push_warning("Pickup: No EffectManager found, using direct stats")
