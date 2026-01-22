## Global constants for the space shooter game
class_name GameConstants
extends Node

## Collision Layers (powers of 2)
const COLLISION_LAYER_PLAYER: int = 1              # Layer 1: Player ship
const COLLISION_LAYER_ENEMY: int = 2               # Layer 2: Enemies
const COLLISION_LAYER_PROJECTILE: int = 4          # Layer 3: Player projectiles
const COLLISION_LAYER_ENEMY_PROJECTILE: int = 8    # Layer 4: Enemy projectiles
const COLLISION_LAYER_PICKUP: int = 16             # Layer 5: Pickups
const COLLISION_LAYER_WALL: int = 32               # Layer 6: Walls/obstacles

## ===== SCROLLING =====
const BASE_SCROLL_SPEED: float = 100.0             # Pixels/second scroll speed

## ===== PARALLAX LAYERS =====
const FAR_LAYER_SCROLL_SCALE: float = 0.2          # Slowest (background)
const MID_LAYER_SCROLL_SCALE: float = 0.5          # Medium (midground)
const NEAR_LAYER_SCROLL_SCALE: float = 0.8         # Fastest (foreground)

## ===== BACKGROUND COLOURS =====
# Far layer (deep space)
const BG_FAR_COLOR_1: Color = Color("#1a1a2e")
const BG_FAR_COLOR_2: Color = Color("#16213e")

# Mid layer (mid-depth)
const BG_MID_COLOR_1: Color = Color("#0f3460")
const BG_MID_COLOR_2: Color = Color("#1e3a5f")

# Near layer (foreground)
const BG_NEAR_COLOR_1: Color = Color("#2e5077")
const BG_NEAR_COLOR_2: Color = Color("#4a7ba7")

## ===== SHIP MOVEMENT =====
const SHIP_SPEED: float = 400.0                    # Pixels/second movement speed
const VIEWPORT_MARGIN: float = 20.0                # Distance from screen edge

## ===== SHOOTING =====
const SHOOT_DELAY: float = 0.2                     # Seconds between shots
const MAX_PROJECTILES: int = 10                    # Maximum projectiles on screen
const PROJECTILE_SPEED: float = 600.0              # Pixels/second projectile speed
const PROJECTILE_SPAWN_OFFSET: float = -35.0       # Y offset from ship (negative = above)

## ===== DAMAGE VALUES =====
const WALL_COLLISION_DAMAGE: int = 15              # Damage from hitting walls
const ENEMY_COLLISION_DAMAGE: int = 30             # Damage from enemy contact
const ENEMY_PROJECTILE_DAMAGE: int = 20            # Damage from enemy bullets
const PLAYER_PROJECTILE_DAMAGE: int = 10           # Default player projectile damage

## ===== ENEMY STATS =====
const ENEMY_HEALTH: int = 30                       # Default enemy health
const ENEMY_SCORE_VALUE: int = 10                  # Score awarded when enemy destroyed
const ENEMY_EXPERIENCE_VALUE: int = 25             # XP awarded when enemy destroyed

## ===== ENEMY COLOURS (for health gradient) =====
const ENEMY_COLOR_FULL_HEALTH: Color = Color("#8b5cf6")  # Purple at full health
const ENEMY_COLOR_ZERO_HEALTH: Color = Color("#ef4444")  # Red at zero health

## ===== POWERUP DURATIONS =====
const INVINCIBILITY_DURATION: float = 30.0              # Seconds of invulnerability from pickup

## ===== ENEMY MOVEMENT =====
const ENEMY_SCROLL_SPEED_NORMAL: float = 100.0          # Standard downward speed
const ENEMY_SCROLL_SPEED_FAST: float = 300.0            # Fast/dive bomber speed
const ENEMY_DESPAWN_MARGIN: float = 100.0               # Pixels beyond viewport before despawn

## Sine wave movement
const ENEMY_SINE_AMPLITUDE: float = 100.0               # Wave width in pixels
const ENEMY_SINE_FREQUENCY: float = 1.0                 # Waves per second

## ZigZag movement
const ENEMY_ZIGZAG_SPEED: float = 150.0                 # Horizontal pixels/second
const ENEMY_ZIGZAG_AMPLITUDE: float = 100.0             # Max distance from center

## ===== ENEMY SPAWNING =====
const ENEMY_SPAWN_INTERVAL: float = 1.0                 # Initial seconds between spawns
const MIN_ENEMY_SPAWN_INTERVAL: float = 0.3             # Fastest spawn rate (difficulty cap)
const ENEMY_DIFFICULTY_INCREASE: float = 0.92           # Multiply interval by this each wave
const BASE_ENEMIES_PER_WAVE: int = 8                    # Starting enemies per wave
const WAVE_ENEMIES_INCREASE: int = 3                    # Additional enemies per wave
const ENEMY_SPAWN_Y_OFFSET: float = -50.0               # Spawn above viewport (negative Y)
const ENEMY_SPAWN_X_MARGIN: float = 50.0                # Margin from screen edges

## ===== PICKUP SPAWNING =====
const PICKUP_SPAWN_INTERVAL: float = 5.0              # Seconds between pickup spawns
const MIN_PICKUP_SPAWN_INTERVAL: float = 2.0          # Fastest pickup spawn rate
const PICKUP_SPAWN_Y_OFFSET: float = -30.0            # Spawn above viewport
const PICKUP_SPAWN_X_MARGIN: float = 60.0             # Margin from screen edges
const PICKUP_SCROLL_SPEED: float = 80.0               # Slower than enemies

## ===== PICKUP VALUES =====
const HEALTH_PICKUP_VALUE: int = 30                   # Health restored
const SHIELD_PICKUP_VALUE: int = 25                   # Shields added

## ===== PICKUP COLOURS =====
const PICKUP_COLOR_HEALTH: Color = Color("#22c55e")   # Green
const PICKUP_COLOR_SHIELD: Color = Color("#3b82f6")   # Blue
const PICKUP_COLOR_INVINCIBILITY: Color = Color("#fbbf24")  # Gold
const PICKUP_COLOR_FIRE_RATE: Color = Color("#f97316")  # Orange
const PICKUP_COLOR_SPREAD: Color = Color("#a855f7")   # Purple

## ===== FIRE RATE BOOST =====
const FIRE_RATE_BOOST_DURATION: float = 10.0          # Seconds of boosted fire rate
const FIRE_RATE_BOOST_MULTIPLIER: float = 0.5         # Multiply fire delay by this (0.5 = 2x faster)

## ===== SPREAD SHOT =====
const SPREAD_SHOT_DURATION: float = 15.0              # Seconds of spread shot
const SPREAD_SHOT_COUNT: int = 3                      # Number of projectiles per shot
const SPREAD_SHOT_ANGLE: float = 15.0                 # Degrees between each projectile

## ===== GAME STATES =====
const STATE_MENU: String = "menu"
const STATE_PLAYING: String = "playing"
const STATE_GAME_OVER: String = "game_over"
const STATE_HIGH_SCORES: String = "high_scores"

## ===== HIGH SCORES =====
const HIGH_SCORES_FILE: String = "user://highscores.json"
const MAX_HIGH_SCORES: int = 10
const DEFAULT_INITIALS: String = "AAA"

## ===== EXPLOSION =====
const EXPLOSION_PARTICLES: int = 30
const EXPLOSION_LIFETIME: float = 0.8
const EXPLOSION_SPEED: float = 150.0
const EXPLOSION_COLOR_START: Color = Color("#fbbf24")  # Gold/yellow
const EXPLOSION_COLOR_END: Color = Color("#ef4444")    # Red
