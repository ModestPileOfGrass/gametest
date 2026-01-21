extends Resource
class_name Effect

## Effect Base Class
## All effects extend this class and implement update(), on_apply(), on_expire()
## Effects are managed by EffectManager component

# ============================================================
# CONFIGURATION
# ============================================================

## Unique name for this effect (used for lookup/removal)
@export var effect_name: String = "unnamed_effect"

## Duration in seconds. Use -1 for permanent effects (never expire)
@export var duration: float = -1.0

## Can multiple instances of this effect stack?
@export var is_stackable: bool = false

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

## Time remaining on this effect (set to duration when applied)
var time_remaining: float = 0.0

## Has this effect been applied?
var is_active: bool = false

# ============================================================
# LIFECYCLE METHODS (Override in subclasses)
# ============================================================

## Called when effect is first applied
## Override to set up initial state
func on_apply(stats: ShipStats) -> void:
	is_active = true
	time_remaining = duration

	if debug_output:
		if duration < 0:
			print("Effect '%s' applied (permanent)" % effect_name)
		else:
			print("Effect '%s' applied (%.1fs)" % [effect_name, duration])


## Called every frame while effect is active
## Override to implement effect behaviour
## @param delta Time since last frame
## @param stats The ShipStats to modify
func update(delta: float, stats: ShipStats) -> void:
	# Update timer for temporary effects
	if duration > 0:
		time_remaining -= delta


## Called when effect expires or is removed
## Override to clean up any state changes
func on_expire(stats: ShipStats) -> void:
	is_active = false

	if debug_output:
		print("Effect '%s' expired" % effect_name)


# ============================================================
# UTILITY METHODS
# ============================================================

## Check if this effect has expired
## Permanent effects (duration = -1) never expire
func is_expired() -> bool:
	if duration < 0:
		return false  # Permanent effects never expire
	return time_remaining <= 0.0


## Get remaining time as a formatted string
func get_time_remaining_string() -> String:
	if duration < 0:
		return "permanent"
	return "%.1fs" % time_remaining
