extends Node
class_name EffectManager

## Effect Manager Component
## Add as child node to any entity that needs timed effects
## Uses composition pattern - works with any entity that has ShipStats

# ============================================================
# CONFIGURATION
# ============================================================

## Reference to the entity's stats (set in _ready or via Inspector)
@export var stats: ShipStats

## Enable debug output
@export var debug_output: bool = false

# ============================================================
# STATE
# ============================================================

## Array of currently active effects
var active_effects: Array[Effect] = []

# ============================================================
# SIGNALS
# ============================================================

## Emitted when an effect is added
signal effect_added(effect_name: String)

## Emitted when an effect is removed (manually or expired)
signal effect_removed(effect_name: String)

## Emitted when an effect expires naturally
signal effect_expired(effect_name: String)

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# Try to get stats from parent if not set
	if not stats:
		var parent = get_parent()
		if parent and parent.has_method("get") and parent.get("stats"):
			stats = parent.stats
		elif parent and "stats" in parent:
			stats = parent.stats

	if debug_output:
		print("EffectManager ready, stats: ", stats != null)


func _process(delta: float) -> void:
	if not stats:
		return

	# Update all active effects
	var expired_effects: Array[Effect] = []

	for effect in active_effects:
		effect.update(delta, stats)

		if effect.is_expired():
			expired_effects.append(effect)

	# Remove expired effects
	for effect in expired_effects:
		_remove_effect_internal(effect, true)


# ============================================================
# PUBLIC METHODS
# ============================================================

## Add an effect to this entity
## If effect is not stackable and already exists, refreshes duration instead
func add_effect(effect: Effect) -> void:
	if not stats:
		push_error("EffectManager: Cannot add effect - no stats assigned")
		return

	# Check for existing non-stackable effect
	if not effect.is_stackable:
		var existing = get_effect(effect.effect_name)
		if existing:
			# Refresh duration instead of adding duplicate
			existing.time_remaining = effect.duration
			if debug_output:
				print("Effect '%s' refreshed (%.1fs)" % [effect.effect_name, effect.duration])
			return

	# Apply and add the effect
	effect.on_apply(stats)
	active_effects.append(effect)
	effect_added.emit(effect.effect_name)

	if debug_output:
		print("Effect '%s' added (total active: %d)" % [effect.effect_name, active_effects.size()])


## Remove an effect by name
## Returns true if effect was found and removed
func remove_effect(effect_name: String) -> bool:
	var effect = get_effect(effect_name)
	if effect:
		_remove_effect_internal(effect, false)
		return true
	return false


## Check if an effect is currently active
func has_effect(effect_name: String) -> bool:
	return get_effect(effect_name) != null


## Get an active effect by name (returns null if not found)
func get_effect(effect_name: String) -> Effect:
	for effect in active_effects:
		if effect.effect_name == effect_name:
			return effect
	return null


## Get all active effect names
func get_active_effect_names() -> Array[String]:
	var names: Array[String] = []
	for effect in active_effects:
		names.append(effect.effect_name)
	return names


## Remove all active effects
func clear_all_effects() -> void:
	var effects_to_remove = active_effects.duplicate()
	for effect in effects_to_remove:
		_remove_effect_internal(effect, false)


# ============================================================
# INTERNAL METHODS
# ============================================================

func _remove_effect_internal(effect: Effect, expired: bool) -> void:
	## Remove effect and emit appropriate signal
	effect.on_expire(stats)
	active_effects.erase(effect)

	if expired:
		effect_expired.emit(effect.effect_name)
	else:
		effect_removed.emit(effect.effect_name)

	if debug_output:
		var reason = "expired" if expired else "removed"
		print("Effect '%s' %s (remaining: %d)" % [effect.effect_name, reason, active_effects.size()])
