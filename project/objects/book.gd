extends Interactable

const TextDisplayScene = preload("res://gui/text_display.tscn")

@export var popup_size := Vector2(80, 40)
@export var popup_offset := Vector2i(0, 24)
@export_multiline var text: String

@export var text_preprocessor_scripts: Array[Script]

@onready var _open_audio: AudioStreamPlayer2D = $%OpenAudio
@onready var _close_audio: AudioStreamPlayer2D = $%CloseAudio

var _text_display: RichTextLabel
var _text_preprocessors: Array

func _ready() -> void:
	super._ready()
	_instantiate_text_preprocessors()

func _instantiate_text_preprocessors() -> void:
	for text_preprocessor_script in text_preprocessor_scripts:
		var text_preprocessor := text_preprocessor_script.new() as TextPreprocessor
		if not text_preprocessor:
			push_warning("Invalid text preprocessor (%s) supplied to %s"
					% [text_preprocessor, self])
			continue
		_text_preprocessors.push_back(text_preprocessor)

func interact() -> void:
	get_tree().paused = true
	_open_audio.play()
	_show_popup()

func _show_popup() -> void:
	_text_display = TextDisplayScene.instantiate()
	_text_display.text = _preprocess_rich_text(text)
	_text_display.center_vertical()
	var popup := PopupBox.create(popup_size, _text_display)
	popup.offset_from_center = popup_offset
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

func _preprocess_rich_text(p_text: String) -> String:
	var modified_text = p_text
	for text_preprocessor: TextPreprocessor in _text_preprocessors:
		modified_text = text_preprocessor.process(p_text)
	return modified_text
