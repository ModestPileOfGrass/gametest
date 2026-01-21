extends Effect
class_name SpreadShotEffect

## Spread Shot Effect
## Temporarily enables spread shot pattern (multiple angled projectiles)
## Applied by spread shot pickup

# ============================================================
# LIFECYCLE
# ============================================================

func _init() -> void:
	effect_name = "spread_shot"
	duration = GameConstants.SPREAD_SHOT_DURATION
	is_stackable = false  # Picking up again refreshes duration


func on_apply(stats: ShipStats) -> void:
	super.on_apply(stats)

	# Enable spread shot mode
	stats.spread_shot = true
	stats.spread_count = GameConstants.SPREAD_SHOT_COUNT
	stats.spread_angle = GameConstants.SPREAD_SHOT_ANGLE

	if debug_output:
		print("SPREAD SHOT ACTIVATED! (%.1fs, %d projectiles at %.0f° spread)" % [
			duration,
			stats.spread_count,
			stats.spread_angle
		])


func update(delta: float, stats: ShipStats) -> void:
	super.update(delta, stats)
	# Effect is passive - just needs to maintain the spread_shot flag


func on_expire(stats: ShipStats) -> void:
	super.on_expire(stats)

	# Disable spread shot
	stats.spread_shot = false

	if debug_output:
		print("SPREAD SHOT EXPIRED!")
