extends Effect
class_name InvincibilityEffect

## Invincibility Effect
## Makes ship immune to all damage for a limited time
## Typically applied by invincibility pickups

# ============================================================
# LIFECYCLE
# ============================================================

func _init() -> void:
	effect_name = "invincibility"
	duration = GameConstants.INVINCIBILITY_DURATION  # 30 seconds
	is_stackable = false  # Picking up again refreshes duration


func on_apply(stats: ShipStats) -> void:
	super.on_apply(stats)

	# Set invulnerable flag in stats
	stats.powerup_invulnerable = true
	stats.powerup_invulnerability_timer = duration

	if debug_output:
		print("INVINCIBILITY ACTIVATED! (%.1fs)" % duration)


func update(delta: float, stats: ShipStats) -> void:
	super.update(delta, stats)

	# Keep stats timer in sync (for HUD display)
	stats.powerup_invulnerability_timer = time_remaining


func on_expire(stats: ShipStats) -> void:
	super.on_expire(stats)

	# Clear invulnerable flag
	stats.powerup_invulnerable = false
	stats.powerup_invulnerability_timer = 0.0

	if debug_output:
		print("INVINCIBILITY EXPIRED!")
