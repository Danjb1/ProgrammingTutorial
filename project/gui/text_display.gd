class_name TextDisplay
extends RichTextLabel

var _parent_control: Control

func _enter_tree() -> void:
	_parent_control = get_parent() as Control
	if _parent_control:
		_parent_control.resized.connect(_on_parent_resized)
	_refresh_height()

func center_vertical() -> void:
	# The text within a RichTextLabel is always top-aligned. Therefore, to center the text
	# vertically, we have to shrink the RichTextLabel itself, and rely on it being vertically
	# centered within the parent container.
	size_flags_vertical = SizeFlags.SIZE_SHRINK_CENTER
	if is_node_ready():
		_refresh_height()

func uncenter_vertical() -> void:
	size_flags_vertical = SizeFlags.SIZE_EXPAND

func _on_parent_resized() -> void:
	_refresh_height()

func _refresh_height() -> void:
	if size_flags_vertical == SizeFlags.SIZE_SHRINK_CENTER:
		# Set the height of the RichTextLabel so that all text is visible,
		# but don't exceed the height of the parent Control
		var required_height := get_content_height()
		var max_height = required_height
		if _parent_control:
			max_height = _parent_control.custom_minimum_size.y
		custom_minimum_size.y = min(required_height, max_height)
