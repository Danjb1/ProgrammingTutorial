extends Area2D

@export var lock_id := 1

@onready var _pickup_sound: DetachableSound = $%PickupAudio

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var player := body as PlayerCharacter
	if not player:
		return
	on_pickup(player)

func on_pickup(player: PlayerCharacter) -> void:
	player.get_inventory().add_keys(lock_id, 1)
	_pickup_sound.play()
	_pickup_sound.detach()
	queue_free()
