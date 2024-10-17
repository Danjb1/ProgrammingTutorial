class_name Inventory
extends RefCounted

## Map of key type -> number in inventory
var keys := {}

func has_key(lock_id: int) -> bool:
	return keys.get(lock_id, 0)

func add_keys(lock_id: int, num_to_add: int) -> void:
	var num_keys: int = keys.get(lock_id, 0)
	num_keys += num_to_add
	keys[lock_id] = num_keys
