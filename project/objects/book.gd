extends Interactable

@export var popup_size := Vector2(80, 40)
@export var text: String

func interact() -> void:
	get_tree().paused = true
	_show_popup()

func _show_popup() -> void:
	var popup_content := RichTextLabel.new()
	popup_content.bbcode_enabled = true
	popup_content.text = text
	popup_content.autowrap_mode = TextServer.AUTOWRAP_OFF
	# These 2 properties are used to vertically center the text
	popup_content.fit_content = true
	popup_content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var popup := PopupBox.create(popup_size, popup_content)
	get_tree().root.add_child(popup)
