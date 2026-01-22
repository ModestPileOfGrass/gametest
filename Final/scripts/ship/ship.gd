extends CharacterBody2D

## Player Ship - Simple Version
## Handles movement (arrow keys) and shooting (spacebar)
## Uses composition pattern with HurtBox for damage detection
##
## This is a simplified ship script. A state machine version
## will be added in a later module for more complex behaviours.

## Ship statistics resource (assign fighter.tres in Inspector)
@export var stats: ShipStats

## Projectile scene to spawn when shooting (assign projectile.tscn in Inspector)
@export var projectile_scene: PackedScene

## Reference to HurtBox component
@export var hurtbox: HurtBox

## Reference to EffectManager component
@export var effect_manager: EffectManager

## Reference to explosion particles
@export var explosion_particles: GPUParticles2D

## Cooldown tracking for shooting
var fire_cooldown: float = 0.0

## Track active projectiles (to limit max on screen)
var active_projectiles: Array[Node] = []


func _ready() -> void:
	# Add to player group for collision detection
	add_to_group("player")

	# Load default stats if not assigned in Inspector
	if not stats:
		stats = load("res://config/fighter.tres").duplicate()

	# Connect to stats signals
	if stats:
		stats.died.connect(_on_died)
		stats.health_changed.connect(_on_health_changed)

	# Connect to HurtBox component
	_setup_hurtbox()

	# Setup EffectManager component
	_setup_effect_manager()

	print("Ship ready at position: ", position)
	print("  Health: %d/%d" % [stats.current_health, stats.max_health])


func _setup_hurtbox() -> void:
	## Setup HurtBox component connections
	# Try exported reference first
	if hurtbox:
		hurtbox.damage_received.connect(_on_damage_received)
		hurtbox.hit_detected.connect(_on_hit_detected)
		return

	# Try to find HurtBox by name
	var hurtbox_node = get_node_or_null("HurtBox")
	if hurtbox_node and hurtbox_node is HurtBox:
		hurtbox = hurtbox_node
		hurtbox.damage_received.connect(_on_damage_received)
		hurtbox.hit_detected.connect(_on_hit_detected)


func _setup_effect_manager() -> void:
	## Setup EffectManager component and add default effects
	# Try exported reference first
	if effect_manager:
		effect_manager.stats = stats
	else:
		# Try to find EffectManager by name
		var em_node = get_node_or_null("EffectManager")
		if em_node and em_node is EffectManager:
			effect_manager = em_node
			effect_manager.stats = stats

	if effect_manager:
		# Add permanent shield recharge effect
		var shield_effect = ShieldRechargeEffect.new()
		shield_effect.recharge_rate = stats.shield_recharge_rate
		shield_effect.recharge_delay = stats.shield_recharge_delay
		shield_effect.debug_output = true  # Enable for testing
		effect_manager.add_effect(shield_effect)

		print("EffectManager setup complete")
		print("  Shield recharge: %.1f/sec after %.1fs delay" % [
			shield_effect.recharge_rate, shield_effect.recharge_delay
		])
	else:
		push_warning("Ship: No EffectManager found - effects disabled")


func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_clamp_to_viewport()


func _handle_movement() -> void:
	## Handle arrow key movement
	# Get input direction as Vector2 (-1 to 1 on each axis)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Calculate velocity from input and speed
	var speed = stats.get_effective_speed() if stats else GameConstants.SHIP_SPEED
	velocity = input_dir * speed

	# Apply movement
	move_and_slide()


func _handle_shooting(delta: float) -> void:
	## Handle spacebar shooting
	# Clean up destroyed projectiles
	active_projectiles = active_projectiles.filter(func(p): return is_instance_valid(p))

	# Update cooldown
	fire_cooldown -= delta

	# Check for shoot input (spacebar or Enter)
	if Input.is_action_pressed("shoot") or Input.is_action_pressed("ui_accept"):
		if fire_cooldown <= 0.0:
			_spawn_projectile()
			fire_cooldown = stats.get_effective_fire_rate() if stats else GameConstants.SHOOT_DELAY


func _spawn_projectile() -> void:
	## Spawn projectile(s) above the ship
	## Handles both normal and spread shot modes
	# Check projectile scene is assigned
	if not projectile_scene:
		push_error("Ship: No projectile_scene assigned!")
		return

	# Check projectile limit
	var max_proj = stats.get_effective_max_projectiles() if stats else GameConstants.MAX_PROJECTILES
	if active_projectiles.size() >= max_proj:
		return

	# Check for spread shot mode
	if stats and stats.spread_shot:
		_spawn_spread_projectiles()
	else:
		_spawn_single_projectile(0.0)


func _spawn_single_projectile(angle_degrees: float) -> void:
	## Spawn a single projectile at the given angle (0 = straight up)
	var projectile = projectile_scene.instantiate()

	# Position above ship
	projectile.position = global_position + Vector2(0, GameConstants.PROJECTILE_SPAWN_OFFSET)

	# Set damage from stats
	if stats:
		projectile.damage = stats.projectile_damage

	# Apply rotation for angled shots
	if angle_degrees != 0.0:
		projectile.rotation_degrees = angle_degrees
		# Rotate the velocity direction
		if projectile.has_method("set_direction"):
			var direction = Vector2.UP.rotated(deg_to_rad(angle_degrees))
			projectile.set_direction(direction)

	# Add to scene tree
	get_parent().add_child(projectile)

	# Track projectile
	active_projectiles.append(projectile)

	# Play shoot sound
	if stats and stats.spread_shot:
		AudioManager.play_sfx("shoot_spread", 0.1)
	else:
		AudioManager.play_sfx("shoot", 0.1)

func _spawn_spread_projectiles() -> void:
	## Spawn multiple projectiles in a spread pattern
	var count = stats.spread_count
	var angle_step = stats.spread_angle

	# Calculate starting angle (centered around 0)
	# For 3 projectiles at 15° spread: -15°, 0°, +15°
	var start_angle = -angle_step * (count - 1) / 2.0

	for i in range(count):
		var angle = start_angle + (angle_step * i)
		_spawn_single_projectile(angle)


func _clamp_to_viewport() -> void:
	## Keep ship within screen bounds
	var viewport_size = get_viewport_rect().size
	var margin = GameConstants.VIEWPORT_MARGIN

	position.x = clamp(position.x, margin, viewport_size.x - margin)
	position.y = clamp(position.y, margin, viewport_size.y - margin)


## ===== SIGNAL HANDLERS =====

func _on_died() -> void:
	## Called when health reaches zero
	print("Ship destroyed!")
	_play_explosion()
	visible = false
	set_physics_process(false)

	# Stop effect manager (prevents shield regen during game over)
	if effect_manager:
		effect_manager.set_process(false)

	# Notify GameManager of death
	var gm = get_node_or_null("/root/GameManager")
	if gm and stats:
		gm.set_game_data(stats.score, 1)  # Wave hardcoded for now
		gm.change_state(GameConstants.STATE_GAME_OVER)


func _play_explosion() -> void:
	## Trigger explosion particles and reparent so they persist
	if explosion_particles:
		# Move to ship's position
		explosion_particles.global_position = global_position
		# Reparent so particles survive ship hiding
		explosion_particles.reparent(get_parent())
		# Start emitting
		explosion_particles.emitting = true
		print("Explosion triggered at: ", global_position)


func _on_health_changed(current: int, max_val: int) -> void:
	## Called when health changes
	print("Health: %d/%d" % [current, max_val])


func _on_damage_received(amount: int, source: Node) -> void:
	## Called by HurtBox when damage is received
	# Check if source is a pickup (pickups don't damage)
	if source.is_in_group("pickups"):
		_handle_pickup(source)
		return

	# Apply damage through stats
	if stats:
		stats.take_damage(amount)


func _on_hit_detected(collider: Node) -> void:
	## Called by HurtBox on any collision
	# Handle pickups
	if collider.is_in_group("pickups"):
		_handle_pickup(collider)


func _handle_pickup(pickup: Node) -> void:
	## Apply pickup effect
	if pickup.has_method("apply_effect"):
		pickup.apply_effect(self)


# ============================================================
# DEBUG / TEST CODE - REMOVE BEFORE PRODUCTION
# ============================================================
# These debug keys test HUD signal updates and effects:
#   D = Take 20 damage
#   H = Heal 30 health
#   S = Add 25 shields
#   X = Add 50 XP
#   P = Add 100 score
#   I = Toggle invincibility (30s)
# ============================================================

func _input(event: InputEvent) -> void:
	if not stats:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_D:  # DEBUG: Take damage
				print("[DEBUG] Taking 20 damage")
				stats.take_damage(20)
			KEY_H:  # DEBUG: Heal
				print("[DEBUG] Healing 30 health")
				stats.heal(30)
			KEY_S:  # DEBUG: Add shields
				print("[DEBUG] Adding 25 shields")
				stats.add_shields(25)
			KEY_X:  # DEBUG: Add XP
				print("[DEBUG] Adding 50 XP")
				stats.add_experience(50)
			KEY_P:  # DEBUG: Add score
				print("[DEBUG] Adding 100 score")
				stats.add_score(100)
			KEY_I:  # DEBUG: Toggle invincibility
				if effect_manager:
					if effect_manager.has_effect("invincibility"):
						print("[DEBUG] Removing invincibility")
						effect_manager.remove_effect("invincibility")
					else:
						print("[DEBUG] Adding invincibility (30s)")
						effect_manager.add_effect(InvincibilityEffect.new())
