extends Camera2D
## Camera that automatically becomes active when loaded.

func _ready() -> void:
	# Wait for scene tree to initialize
	call_deferred("_init_camera")

func _init_camera():
	make_current()
