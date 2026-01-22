extends CharacterBody2D

## Basic Enemy
## - Uses movement components for downward movement
## - Uses HurtBox component to receive damage from player projectiles
## - Uses HitBox component to deal contact damage to player
## - Colour transitions from purple (full health) to red (near death)

# ============================================================
# CONFIGURATION
# ============================================================

## Enemy health
@export var health: int = GameConstants.ENEMY_HEALTH

## Score value when destroyed
@export var score_value: int = GameConstants.ENEMY_SCORE_VALUE

## Experience value when destroyed
@export var experience_value: int = GameConstants.ENEMY_EXPERIENCE_VALUE

## Reference to Polygon2D for visual updates
@export var polygon: Polygon2D

# ============================================================
# STATE
# ============================================================

## Maximum health (tracked for colour gradient calculation)
var max_health: int

## Base colour of this enemy (stored on spawn for gradient calculation)
var base_color: Color

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# Add to enemies group for collision detection
	add_to_group("enemies")

	# Store initial max health
	max_health = health

	# Store base colour from polygon (each enemy type has its own colour)
	if polygon:
		base_color = polygon.color

	print("Enemy spawned at position: %s with %d health" % [global_position, health])


# ============================================================
# DAMAGE SYSTEM
# ============================================================

func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy took %d damage, health now: %d" % [amount, health])
	
	# AUDIO: Play hit sound
	AudioManager.play_sfx("hit", 0.15)
	
	_update_color()
	
	if health <= 0:
		_die()


func _die() -> void:
	print("Enemy destroyed! Awarded %d score, %d XP" % [score_value, experience_value])
	
	# AUDIO: Play explosion sound
	AudioManager.play_sfx("explosion", 0.2)
	
	var player_ships = get_tree().get_nodes_in_group("player")
	if player_ships.size() > 0:
		var ship = player_ships[0]
		if ship.stats:
			ship.stats.add_score(score_value)
			ship.stats.add_experience(experience_value)
	
	queue_free()

# ============================================================
# VISUAL UPDATES
# ============================================================

func _update_color() -> void:
	## Update enemy colour based on current health (base colour → red gradient)
	if not polygon:
		return

	# Calculate health percentage (0.0 = dead, 1.0 = full health)
	var health_percent: float = clamp(float(health) / float(max_health), 0.0, 1.0)

	# Lerp between red (0 health) and base colour (full health)
	var new_color: Color = GameConstants.ENEMY_COLOR_ZERO_HEALTH.lerp(
		base_color,
		health_percent
	)

	# Apply the colour to the visual
	polygon.color = new_color
