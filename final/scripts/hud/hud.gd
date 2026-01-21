extends CanvasLayer

## HUD (Heads-Up Display)
## Displays health bar, shields bar, score, level/XP, and message notifications.
## Connects to ShipStats signals for reactive updates.
## Uses Godot's ProgressBar control for proper bar displays.

# ============================================================
# UI ELEMENT REFERENCES
# ============================================================

## Health progress bar
@onready var health_bar: ProgressBar = %HealthBar

## Health text label
@onready var health_label: Label = %HealthLabel

## Shields progress bar
@onready var shields_bar: ProgressBar = %ShieldsBar

## Shields text label
@onready var shields_label: Label = %ShieldsLabel

## Score text label
@onready var score_label: Label = %ScoreLabel

## Level text label
@onready var level_label: Label = %LevelLabel

## Message label (for pickups, level ups, etc.)
@onready var message_label: Label = %MessageLabel

# ============================================================
# STATE
# ============================================================

## Reference to ship's stats (set via connect_to_ship)
var ship_stats: ShipStats = null

## Reference to ship's effect manager (for invincibility visual)
var effect_manager: EffectManager = null

## Message timer for auto-hiding messages
var message_timer: float = 0.0

## How long to show messages (seconds)
const MESSAGE_DURATION: float = 3.0

## Tween for shields bar pulsing during invincibility
var shields_pulse_tween: Tween = null

## Original shields bar fill colour (to restore after pulse)
var shields_original_color: Color = Color(0, 0.8, 1, 1)  # Cyan

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# Hide message label initially
	if message_label:
		message_label.text = ""
		message_label.visible = false


func _process(delta: float) -> void:
	# Handle message auto-hide timer
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0 and message_label:
			message_label.visible = false
			message_label.text = ""


# ============================================================
# CONNECTION TO SHIP
# ============================================================

## Connect HUD to ship's stats signals
## Call this from main.gd after ship is ready
func connect_to_ship(ship: CharacterBody2D) -> void:
	if not ship or not ship.stats:
		push_error("HUD: Cannot connect to ship - invalid ship or stats")
		return

	ship_stats = ship.stats

	# Connect to all stat change signals
	ship_stats.health_changed.connect(_on_health_changed)
	ship_stats.shields_changed.connect(_on_shields_changed)
	ship_stats.score_changed.connect(_on_score_changed)
	ship_stats.level_up.connect(_on_level_up)
	ship_stats.experience_changed.connect(_on_experience_changed)

	# Connect to EffectManager for visual effect feedback
	if ship.effect_manager:
		effect_manager = ship.effect_manager
		effect_manager.effect_added.connect(_on_effect_added)
		effect_manager.effect_removed.connect(_on_effect_removed)
		effect_manager.effect_expired.connect(_on_effect_expired)

	# Initialize UI with current values
	_on_health_changed(ship_stats.current_health, ship_stats.max_health)
	_on_shields_changed(ship_stats.current_shields, ship_stats.max_shields)
	_on_score_changed(ship_stats.score)
	_update_level_display()

	print("HUD connected to ship")


# ============================================================
# SIGNAL HANDLERS
# ============================================================

func _on_health_changed(current: int, max_val: int) -> void:
	## Update health bar and label
	if health_label:
		health_label.text = "Health: %d/%d" % [current, max_val]

	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

		# Colour coding: Green > Yellow > Red
		var health_percent = float(current) / float(max_val) if max_val > 0 else 0.0
		var style = health_bar.get_theme_stylebox("fill").duplicate()
		if style is StyleBoxFlat:
			if health_percent > 0.6:
				style.bg_color = Color.GREEN
			elif health_percent > 0.3:
				style.bg_color = Color.YELLOW
			else:
				style.bg_color = Color.RED
			health_bar.add_theme_stylebox_override("fill", style)


func _on_shields_changed(current: int, max_val: int) -> void:
	## Update shields bar and label
	if shields_label:
		shields_label.text = "Shields: %d/%d" % [current, max_val]

	if shields_bar:
		shields_bar.max_value = max_val
		shields_bar.value = current


func _on_score_changed(new_score: int) -> void:
	## Update score label
	if score_label:
		score_label.text = "Score: %d" % new_score


func _on_level_up(new_level: int) -> void:
	## Show level up message and update level display
	show_message("LEVEL UP! Now Level %d" % new_level, 3.0)
	_update_level_display()


func _on_experience_changed(_current: int, _next_level: int) -> void:
	## Update level display with XP progress
	_update_level_display()


# ============================================================
# UI UPDATES
# ============================================================

func _update_level_display() -> void:
	## Update level and XP display
	if ship_stats and level_label:
		level_label.text = "Level: %d | XP: %d/%d" % [
			ship_stats.level,
			ship_stats.experience,
			ship_stats.experience_to_next_level
		]


## Show a message in the message area
## @param text The message to display
## @param duration How long to show it (-1 = until cleared, 0 = use default)
func show_message(text: String, duration: float = 0.0) -> void:
	if not message_label:
		return

	message_label.text = text
	message_label.visible = true

	# Set timer for auto-hide
	if duration < 0:
		message_timer = -1  # Don't auto-hide
	elif duration > 0:
		message_timer = duration
	else:
		message_timer = MESSAGE_DURATION


## Clear the message display
func clear_message() -> void:
	if message_label:
		message_label.visible = false
		message_label.text = ""
		message_timer = 0.0


# ============================================================
# EFFECT SIGNAL HANDLERS
# ============================================================

func _on_effect_added(effect_name: String) -> void:
	## Handle visual feedback when effects are added
	if effect_name == "invincibility":
		_start_invincibility_pulse()


func _on_effect_removed(effect_name: String) -> void:
	## Handle visual feedback when effects are manually removed
	if effect_name == "invincibility":
		_stop_invincibility_pulse()


func _on_effect_expired(effect_name: String) -> void:
	## Handle visual feedback when effects expire naturally
	if effect_name == "invincibility":
		_stop_invincibility_pulse()


# ============================================================
# INVINCIBILITY VISUAL EFFECTS
# ============================================================

func _start_invincibility_pulse() -> void:
	## Start pulsing the shields bar to indicate invincibility
	if not shields_bar:
		return

	# Kill any existing tween
	if shields_pulse_tween:
		shields_pulse_tween.kill()

	# Create looping pulse animation
	# Pulse between cyan (normal) and gold (invincible)
	shields_pulse_tween = create_tween()
	shields_pulse_tween.set_loops()  # Loop forever until stopped

	# Get the fill stylebox and animate its colour
	var style = shields_bar.get_theme_stylebox("fill")
	if style is StyleBoxFlat:
		# Store original colour for restoration
		shields_original_color = style.bg_color

		# Pulse: cyan → gold → cyan (1 second cycle)
		var gold_color = Color(1.0, 0.85, 0.0, 1.0)  # Gold
		shields_pulse_tween.tween_method(
			_set_shields_bar_color,
			shields_original_color,
			gold_color,
			0.5
		)
		shields_pulse_tween.tween_method(
			_set_shields_bar_color,
			gold_color,
			shields_original_color,
			0.5
		)

	print("Shields bar pulse started (invincibility)")


func _stop_invincibility_pulse() -> void:
	## Stop the shields bar pulsing and restore normal colour
	if shields_pulse_tween:
		shields_pulse_tween.kill()
		shields_pulse_tween = null

	# Restore original colour
	if shields_bar:
		_set_shields_bar_color(shields_original_color)

	print("Shields bar pulse stopped")


func _set_shields_bar_color(color: Color) -> void:
	## Helper to set the shields bar fill colour
	if not shields_bar:
		return

	var style = shields_bar.get_theme_stylebox("fill").duplicate()
	if style is StyleBoxFlat:
		style.bg_color = color
		shields_bar.add_theme_stylebox_override("fill", style)
