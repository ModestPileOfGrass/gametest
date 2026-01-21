extends Resource
class_name ShipStats

## Ship Statistics Resource
## Stores all configurable stats for a ship type (Fighter, Tank, Speedster, etc.)
## Create .tres files in config/ folder to define different ship configurations

# ============================================================
# HEALTH
# ============================================================

## Maximum health points
@export var max_health: int = 100

## Current health points (set to max_health on init)
var current_health: int

# ============================================================
# SHIELDS
# ============================================================

## Maximum shield points (shields absorb damage before health)
@export var max_shields: int = 50

## Current shield points
var current_shields: int = 0

# ============================================================
# SHIELD RECHARGE (configured via ShieldRechargeEffect)
# ============================================================

## Shield recharge rate in points per second
@export var shield_recharge_rate: float = 5.0

## Delay before shields start recharging after damage (seconds)
@export var shield_recharge_delay: float = 3.0

# ============================================================
# MOVEMENT
# ============================================================

## Speed multiplier (multiplied with SHIP_SPEED constant)
@export var speed_multiplier: float = 1.0

# ============================================================
# WEAPONS
# ============================================================

## Fire rate multiplier (lower = faster firing)
@export var fire_rate_multiplier: float = 1.0

## Base damage per projectile
@export var projectile_damage: int = 10

## Max projectiles on screen
@export var max_projectiles: int = 10

# ============================================================
# BONUSES (modified by upgrades)
# ============================================================

## Added to speed_multiplier
var speed_bonus: float = 0.0

## Reduces fire delay
var fire_rate_bonus: float = 0.0

## Added to max_projectiles
var max_projectiles_bonus: int = 0

# ============================================================
# SCORE & PROGRESSION
# ============================================================

var score: int = 0
var level: int = 1
var experience: int = 0
var experience_to_next_level: int = 100

# ============================================================
# POWERUP STATE (infrastructure for EffectManager)
# ============================================================

## Is ship invulnerable from pickup powerup?
var powerup_invulnerable: bool = false

## Time remaining on powerup invulnerability (managed by EffectManager)
var powerup_invulnerability_timer: float = 0.0

## Fire rate boost multiplier (1.0 = normal, 0.5 = 2x faster)
var fire_rate_effect_multiplier: float = 1.0

## Spread shot enabled?
var spread_shot: bool = false

## Number of projectiles when spread shot is active
var spread_count: int = 3

## Angle between spread shot projectiles (degrees)
var spread_angle: float = 15.0

# ============================================================
# SIGNALS
# ============================================================

## Emitted when health changes
signal health_changed(current: int, max_val: int)

## Emitted when shields change
signal shields_changed(current: int, max_val: int)

## Emitted when ship dies (health reaches 0)
signal died

## Emitted when score changes
signal score_changed(new_score: int)

## Emitted when experience changes (for real-time XP display)
signal experience_changed(current: int, next_level: int)

## Emitted when ship levels up
signal level_up(new_level: int)

# ============================================================
# DEBUG
# ============================================================

@export var debug_output: bool = false

# ============================================================
# LIFECYCLE
# ============================================================

func _init() -> void:
	current_health = max_health
	current_shields = max_shields


# ============================================================
# CALCULATED STATS
# ============================================================

## Calculate effective speed (base * multiplier + bonus)
func get_effective_speed() -> float:
	return GameConstants.SHIP_SPEED * (speed_multiplier + speed_bonus)


## Calculate effective fire rate (delay between shots)
func get_effective_fire_rate() -> float:
	var base_delay = GameConstants.SHOOT_DELAY * fire_rate_multiplier
	var adjusted_delay = (base_delay - fire_rate_bonus) * fire_rate_effect_multiplier
	return max(0.05, adjusted_delay)  # Minimum 0.05s delay


## Calculate effective max projectiles
func get_effective_max_projectiles() -> int:
	return max_projectiles + max_projectiles_bonus


# ============================================================
# DAMAGE & HEALING
# ============================================================

## Apply damage to ship. Shields absorb damage first, then health.
## Returns true if ship died (health <= 0), false if survived.
func take_damage(amount: int) -> bool:
	# Ignore damage if invulnerable from powerup
	if powerup_invulnerable:
		if debug_output:
			print("Invincible! Damage blocked.")
		return false

	var remaining_damage = amount

	# Shields absorb damage first
	if current_shields > 0:
		var shield_damage = min(remaining_damage, current_shields)
		current_shields -= shield_damage
		remaining_damage -= shield_damage
		shields_changed.emit(current_shields, max_shields)

		if debug_output:
			print("Shields absorbed %d damage, shields: %d/%d" % [shield_damage, current_shields, max_shields])

	# Remaining damage goes to health
	if remaining_damage > 0:
		current_health -= remaining_damage
		current_health = max(0, current_health)

		if debug_output:
			print("Ship took %d damage, health: %d/%d" % [remaining_damage, current_health, max_health])

		health_changed.emit(current_health, max_health)

	# Check for death
	if current_health <= 0:
		died.emit()
		return true

	return false


## Heal the ship
func heal(amount: int) -> void:
	current_health += amount
	current_health = min(current_health, max_health)

	if debug_output:
		print("Ship healed %d, health: %d/%d" % [amount, current_health, max_health])

	health_changed.emit(current_health, max_health)


## Add shields (capped at max_shields)
func add_shields(amount: int) -> void:
	current_shields += amount
	current_shields = min(current_shields, max_shields)

	if debug_output:
		print("Shields added %d, shields: %d/%d" % [amount, current_shields, max_shields])

	shields_changed.emit(current_shields, max_shields)


# ============================================================
# SCORE & PROGRESSION
# ============================================================

## Add score
func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

	if debug_output:
		print("Score: %d (+%d)" % [score, amount])


## Add experience and check for level up
func add_experience(amount: int) -> void:
	experience += amount

	if debug_output:
		print("XP: %d/%d (+%d)" % [experience, experience_to_next_level, amount])

	# Emit experience changed for real-time HUD updates
	experience_changed.emit(experience, experience_to_next_level)

	# Check for level up(s)
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = int(experience_to_next_level * 1.5)
		level_up.emit(level)

		# Emit updated XP after level up
		experience_changed.emit(experience, experience_to_next_level)

		if debug_output:
			print("Level Up! Now level %d" % level)


# ============================================================
# RESET
# ============================================================

## Reset stats to initial values (for new game)
func reset() -> void:
	# Reset health and shields
	current_health = max_health
	current_shields = max_shields

	# Reset bonuses
	speed_bonus = 0.0
	fire_rate_bonus = 0.0
	max_projectiles_bonus = 0

	# Reset powerup state
	powerup_invulnerable = false
	powerup_invulnerability_timer = 0.0
	fire_rate_effect_multiplier = 1.0
	spread_shot = false

	# Reset progression
	score = 0
	level = 1
	experience = 0
	experience_to_next_level = 100

	# Emit signals for UI updates
	health_changed.emit(current_health, max_health)
	shields_changed.emit(current_shields, max_shields)
	score_changed.emit(score)
	experience_changed.emit(experience, experience_to_next_level)
