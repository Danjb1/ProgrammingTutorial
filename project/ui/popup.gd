class_name PopupBox
extends CanvasLayer
## Pop-up that pauses the game while active.

const _POPUP_RESOURCE := preload("res://ui/popup.tscn")
const _SIZE_ANIM_TRACK_ID := 0
const _SIZE_ANIM_LAST_KEY_ID := 1
const _PIXEL_SCALE := 8.0
const _PADDING := Vector2(8.0, 8.0)

## Size of the pop-up, in scaled pixels.
@export var desired_size := Vector2(80, 40)

## Offset from the center of the screen, in scaled pixels.
@export var offset_from_center := Vector2i(0, 24)

## Control to display inside the pop-up
@export var content: Control

@onready var _scaled_margin_container: MarginContainer = $%ScaledPixelMarginContainer
@onready var _screen_px_margin_container: MarginContainer = $%ScreenPixelMarginContainer
@onready var _nine_patch: NinePatchRect = $%NinePatchRect
@onready var _content_container: Container = $%ContentContainer
@onready var _anim_player: AnimationPlayer = $%AnimationPlayer

static func create(p_desired_size: Vector2, p_content: Control) -> PopupBox:
	var popup := _POPUP_RESOURCE.instantiate()
	popup.desired_size = p_desired_size
	popup.content = p_content
	return popup

func _ready() -> void:
	_init_offset()
	_init_anim()

func _init_offset() -> void:
	var left: int = min(-offset_from_center.x, 0)
	var right: int = max(offset_from_center.x, 0)
	var top: int = min(-offset_from_center.y, 0)
	var bottom: int = max(offset_from_center.y, 0)
	var px_scale := int(_PIXEL_SCALE)
	_scaled_margin_container.add_theme_constant_override("margin_left", left)
	_scaled_margin_container.add_theme_constant_override("margin_right", right)
	_scaled_margin_container.add_theme_constant_override("margin_top", top)
	_scaled_margin_container.add_theme_constant_override("margin_bottom", bottom)
	_screen_px_margin_container.add_theme_constant_override("margin_left", left * px_scale)
	_screen_px_margin_container.add_theme_constant_override("margin_right", right * px_scale)
	_screen_px_margin_container.add_theme_constant_override("margin_top", top * px_scale)
	_screen_px_margin_container.add_theme_constant_override("margin_bottom", bottom * px_scale)

func _init_anim() -> void:
	# Customize the "in" animation based on the desired pop-up size
	var in_anim = _anim_player.get_animation("in")
	var sanitized_size = _get_sanitized_size(desired_size)
	in_anim.track_set_key_value(_SIZE_ANIM_TRACK_ID, _SIZE_ANIM_LAST_KEY_ID, sanitized_size)

## Gets the pop-up size closest to the given size that avoids cut-off textures.
func _get_sanitized_size(in_size: Vector2) -> Vector2:
	var nine_patch_margins := _get_nine_patch_margins()
	var repeating_tex_size := _nine_patch.texture.get_size() - nine_patch_margins
	var area_to_fill := in_size - nine_patch_margins
	var num_repetitions: Vector2i = area_to_fill / repeating_tex_size
	return nine_patch_margins + Vector2(num_repetitions) * repeating_tex_size

func _get_nine_patch_margins() -> Vector2:
	return Vector2(
		_nine_patch.patch_margin_left + _nine_patch.patch_margin_right,
		_nine_patch.patch_margin_top + _nine_patch.patch_margin_bottom
	)

func _process(_delta: float):
	if Input.is_action_just_pressed("jump"):
		_close_popup()
		return
	if _anim_player.is_playing():
		_refresh_content_size()

func _refresh_content_size():
	# Unfortunately, GUI elements do not play nicely with scaling; the scale can only be set by the
	# topmost container. Therefore, we use 2 containers at the top level: one to house our scaled-up
	# pixellated elements, and another to house our text elements, which we keep at a regular scale
	# for readability. We only animate the first container, and this method keeps the size of the
	# second container in-sync.
	var nine_patch_margins := _get_nine_patch_margins()
	var nine_patch_size := _nine_patch.custom_minimum_size - nine_patch_margins
	var nine_patch_size_px := nine_patch_size * _PIXEL_SCALE
	_content_container.custom_minimum_size = nine_patch_size_px - _PADDING

func _close_popup() -> void:
	if _anim_player.is_playing():
		return
	_anim_player.play_backwards("in")
	_anim_player.animation_finished.connect(_on_close_anim_finished)

func _on_close_anim_finished(_anim_name: StringName) -> void:
	get_tree().paused = false
	queue_free()

func _show_content() -> void:
	# Called from "in" animation to add the pop-up content after a short delay
	# (or remove it if the pop-up is being closed).
	if _anim_player.get_playing_speed() < 0.0:
		#  Pop-up is being closed
		content.queue_free()
	else:
		_content_container.add_child(content)
