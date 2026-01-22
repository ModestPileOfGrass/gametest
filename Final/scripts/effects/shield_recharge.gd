extends Effect
class_name ShieldRechargeEffect

## Shield Recharge Effect
## Passively recharges shields when not taking damage
## This is a PERMANENT effect (duration = -1)

# ============================================================
# CONFIGURATION
# ============================================================

## Shield points recharged per second
@export var recharge_rate: float = 5.0

## Delay before shields start recharging (seconds after last damage)
@export var recharge_delay: float = 3.0

# ============================================================
# STATE
# ============================================================

## Time since ship last took damage
var time_since_damage: float = 0.0

## Is recharge currently paused (after taking damage)?
var recharge_paused: bool = false

## Track previous shield value to detect damage (not recharge)
var previous_shields: float = 0.0

## Track previous health to detect damage (not healing)
var previous_health: int = 0

## Are we currently recharging? (to ignore our own shield changes)
var is_recharging: bool = false

## Accumulated recharge (accumulates until >= 1.0 to add whole shield points)
var recharge_accumulator: float = 0.0

# ============================================================
# LIFECYCLE
# ============================================================

func _init() -> void:
	effect_name = "shield_recharge"
	duration = -1.0  # Permanent effect
	is_stackable = false


func on_apply(stats: ShipStats) -> void:
	super.on_apply(stats)
	time_since_damage = recharge_delay  # Start ready to recharge
	recharge_paused = false
	previous_shields = stats.current_shields
	previous_health = stats.current_health
	is_recharging = false

	# Connect to damage signals to pause recharge
	if not stats.shields_changed.is_connected(_on_shields_changed):
		stats.shields_changed.connect(_on_shields_changed)
	if not stats.health_changed.is_connected(_on_health_changed):
		stats.health_changed.connect(_on_health_changed)


func update(delta: float, stats: ShipStats) -> void:
	super.update(delta, stats)

	# Update damage timer
	time_since_damage += delta

	# Check if we can recharge
	if time_since_damage >= recharge_delay:
		recharge_paused = false

		# Recharge shields if not full
		if stats.current_shields < stats.max_shields:
			# Accumulate recharge (current_shields is int, so we need to accumulate
			# fractional amounts until we have at least 1 whole shield point)
			recharge_accumulator += recharge_rate * delta

			# Only add shields when we have at least 1 whole point
			if recharge_accumulator >= 1.0:
				var whole_points = int(recharge_accumulator)
				var new_shields = min(
					stats.current_shields + whole_points,
					stats.max_shields
				)

				# Set flag so signal handler knows this is recharge, not damage
				is_recharging = true
				stats.current_shields = new_shields
				previous_shields = new_shields
				recharge_accumulator -= whole_points  # Keep the fractional remainder
				stats.shields_changed.emit(stats.current_shields, stats.max_shields)
				is_recharging = false

				if debug_output:
					print("Shields recharging: %d/%d" % [stats.current_shields, stats.max_shields])


func on_expire(stats: ShipStats) -> void:
	super.on_expire(stats)

	# Disconnect signals
	if stats.shields_changed.is_connected(_on_shields_changed):
		stats.shields_changed.disconnect(_on_shields_changed)
	if stats.health_changed.is_connected(_on_health_changed):
		stats.health_changed.disconnect(_on_health_changed)


# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _on_shields_changed(current: int, _max_val: int) -> void:
	## Reset recharge timer when shields take damage (not when recharging)
	# Ignore if we caused this change (recharging)
	if is_recharging:
		return

	# Only reset if shields decreased (took damage)
	if current < previous_shields:
		time_since_damage = 0.0
		recharge_paused = true
		if debug_output:
			print("Shield recharge paused (shields damaged)")

	previous_shields = current


func _on_health_changed(current: int, _max_val: int) -> void:
	## Reset recharge timer when health takes damage (not when healing)
	# Only reset if health decreased (took damage)
	if current < previous_health:
		time_since_damage = 0.0
		recharge_paused = true
		if debug_output:
			print("Shield recharge paused (health damaged)")

	previous_health = current
