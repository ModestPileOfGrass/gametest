extends Resource
class_name PickupSpawnerConfig

## Pickup Spawner Configuration Resource
## Stores all pickup spawner settings in a data-driven format

## Time between pickup spawns (seconds)
@export var spawn_interval: float = 5.0

## Minimum spawn interval (faster spawns over time)
@export var min_spawn_interval: float = 2.0

## Spawn interval reduction per wave (0.95 = 5% faster each wave)
@export_range(0.8, 1.0, 0.01) var difficulty_multiplier: float = 0.95

## Y offset for spawning (negative = above screen)
@export var spawn_y_offset: float = -30.0

## Margin from screen edges for X position
@export var spawn_x_margin: float = 60.0
