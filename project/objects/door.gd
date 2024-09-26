extends Area2D
## Area that transports the player to a new level.

const _RECENT_TELEPORT_THRESHOLD := 60

@export var target_level: String
@export var target_entrance: String

var _awaiting_exit := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if _awaiting_exit:
		return
	var player := body as PlayerCharacter
	if not player:
		return
	if player.has_recently_teleported(_RECENT_TELEPORT_THRESHOLD):
		# If the player teleported onto the door, force them to leave the door
		# before teleportation is permitted again
		_awaiting_exit = true
		return
	if target_level:
		World.request_level(target_level, target_entrance)

func _on_body_exited(body: Node2D):
	if body is PlayerCharacter:
		_awaiting_exit = false
