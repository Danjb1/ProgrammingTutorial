class_name Interactable
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	var player := body as PlayerCharacter
	if not player:
		return
	player.set_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	var player := body as PlayerCharacter
	if not player:
		return
	player.set_interactable(null)

func interact() -> void:
	pass
