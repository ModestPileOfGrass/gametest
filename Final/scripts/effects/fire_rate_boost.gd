extends Effect
class_name FireRateBoostEffect

## Fire Rate Boost Effect
## Temporarily increases fire rate (reduces delay between shots)
## Applied by fire rate pickup

# ============================================================
# LIFECYCLE
# ============================================================

func _init() -> void:
	effect_name = "fire_rate_boost"
	duration = GameConstants.FIRE_RATE_BOOST_DURATION
	is_stackable = false  # Picking up again refreshes duration


func on_apply(stats: ShipStats) -> void:
	super.on_apply(stats)

	# Apply fire rate multiplier (0.5 = 2x faster)
	stats.fire_rate_effect_multiplier = GameConstants.FIRE_RATE_BOOST_MULTIPLIER

	if debug_output:
		print("FIRE RATE BOOST ACTIVATED! (%.1fs, %.0f%% faster)" % [
			duration,
			(1.0 - GameConstants.FIRE_RATE_BOOST_MULTIPLIER) * 100
		])


func update(delta: float, stats: ShipStats) -> void:
	super.update(delta, stats)
	# Effect is passive - just needs to maintain the multiplier


func on_expire(stats: ShipStats) -> void:
	super.on_expire(stats)

	# Reset fire rate to normal
	stats.fire_rate_effect_multiplier = 1.0

	if debug_output:
		print("FIRE RATE BOOST EXPIRED!")
