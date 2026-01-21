extends Resource
class_name EnemySpawnerConfig

## Enemy Spawner Configuration Resource
## Stores all spawner settings in a data-driven format

## Initial time between enemy spawns (seconds)
@export var spawn_interval: float = 1.0

## Minimum spawn interval (difficulty cap)
@export var min_spawn_interval: float = 0.3

## Number of enemies in the first wave
@export var base_enemies_per_wave: int = 8

## Additional enemies added each wave
@export var wave_enemies_increase: int = 3

## Spawn interval multiplier each wave (0.92 = 8% faster each wave)
@export_range(0.5, 1.0, 0.01) var difficulty_increase_rate: float = 0.92

## Y offset for spawning (negative = above screen)
@export var spawn_y_offset: float = -50.0

## Margin from screen edges for X position
@export var spawn_x_margin: float = 50.0
