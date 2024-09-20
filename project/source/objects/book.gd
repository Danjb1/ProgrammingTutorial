extends Interactable

func interact() -> void:
	get_tree().paused = true
	_show_popup()

func _show_popup() -> void:
	var popup_resource := preload("res://source/gui/popup.tscn")
	var popup := popup_resource.instantiate()
	get_tree().root.add_child(popup)
