extends Node
class_name EnemyType

## Enemy Type Component
## Lightweight node that holds a reference to an enemy scene
## Used as child of EnemySpawner for composition-based enemy selection

## The enemy scene this type represents
@export var enemy_scene: PackedScene

## Optional: spawn weight for weighted random selection (higher = more common)
@export var spawn_weight: float = 1.0

func _ready() -> void:
	if not enemy_scene:
		push_warning("EnemyType '%s' has no enemy_scene assigned!" % name)
