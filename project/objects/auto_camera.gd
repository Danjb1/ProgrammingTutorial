extends Camera2D
## Camera that automatically becomes active when loaded.

func _ready() -> void:
	_init_zoom()
	# Wait for scene tree to initialize
	call_deferred("_init_camera")

func _init_zoom() -> void:
	# Set the zoom level to fill the viewport
	var viewport_size := get_viewport_rect().size
	zoom = viewport_size / World.SIZE

func _init_camera() -> void:
	make_current()
