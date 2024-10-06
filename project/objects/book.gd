extends Interactable

const TextDisplayScene = preload("res://gui/text_display.tscn")

@export var popup_size := Vector2(80, 40)
@export_multiline var text: String

@onready var _open_audio: AudioStreamPlayer2D = $%OpenAudio
@onready var _close_audio: AudioStreamPlayer2D = $%CloseAudio

var _text_display: RichTextLabel

func interact() -> void:
	get_tree().paused = true
	_open_audio.play()
	_show_popup()

func _show_popup() -> void:
	_text_display = TextDisplayScene.instantiate()
	_text_display.text = text
	_text_display.center_vertical()
	var popup := PopupBox.create(popup_size, _text_display)
	popup.opened.connect(_on_popup_opened)
	popup.close_requested.connect(_on_popup_close_requested)
	get_tree().root.add_child(popup)

func _on_popup_opened() -> void:
	# We wait until the pop-up has reached its full width before enabling text wrapping. If we
	# enable text wrapping straight away then it becomes impossible to vertically center the text,
	# because when the popup is very small the text will be forced into a very long column.
	_text_display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# We have to re-center now that the size may have changed
	_text_display.center_vertical()

func _on_popup_close_requested() -> void:
	_close_audio.play()
	_text_display.autowrap_mode = TextServer.AUTOWRAP_OFF
