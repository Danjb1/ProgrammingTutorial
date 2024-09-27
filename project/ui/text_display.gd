class_name TextDisplay
extends RichTextLabel

func _ready() -> void:
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

func _refresh_height() -> void:
	if size_flags_vertical == SizeFlags.SIZE_SHRINK_CENTER:
		# Set the height of the RichTextLabel so that all text is visible
		custom_minimum_size.y = get_content_height()
