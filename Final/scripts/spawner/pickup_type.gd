extends Node
class_name PickupType

## Pickup Type Component
## Lightweight node that holds a reference to a pickup scene
## Used as child of PickupSpawner for composition-based selection

## The pickup scene this type represents
@export var pickup_scene: PackedScene

## Spawn weight for weighted random selection (higher = more common)
@export var spawn_weight: float = 1.0

func _ready() -> void:
	if not pickup_scene:
		push_warning("PickupType '%s' has no pickup_scene assigned!" % name)
