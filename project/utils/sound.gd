class_name DetachableSound
extends AudioStreamPlayer2D

## Detaches this node from its parent and attaches it to the level root instead.
## The sound will be automatically freed when it finishes playing.
func detach() -> void:
	var level_root := get_tree().get_first_node_in_group("level")
	if not level_root:
		push_warning("No active level found")
		return
	get_parent().remove_child(self)
	level_root.add_child(self)
	finished.connect(_on_finished_playing)

func _on_finished_playing() -> void:
	queue_free()
