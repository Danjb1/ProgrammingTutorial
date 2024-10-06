extends Control
## Autoload class that allows debug drawing to a screen overlay.

class Line:
	var start: Vector2
	var end: Vector2
	var color: Color
	var width: float
	
	func _init(p_start, p_end, p_color, p_width):
		start = p_start
		end = p_end
		color = p_color
		width = p_width

var _lines = []
var _canvas: CanvasLayer

func _ready():
	# Ignore mouse events
	set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	# Render on top
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	if _is_drawing_enabled():
		# We need to use call_deferred as the scene isn't fully initialized yet
		call_deferred("_init_canvas")
	else:
		set_process(false)

func _init_canvas():
	# Wrap this Control in a CanvasLayer
	_canvas = CanvasLayer.new()
	replace_by(_canvas)
	_canvas.add_child(self)

func _is_drawing_enabled():
	# Only draw when running from editor
	return OS.has_feature("editor")

func _process(_delta):
	# Redraw every tick
	queue_redraw()

func add_line(start: Vector2, end: Vector2, color: Color, width := 3.0):
	_lines.append(Line.new(start, end, color, width))

func _draw():
	if not _canvas:
		return
	_draw_lines()
	_clear_data()

func _draw_lines():
	for line in _lines:
		var start = _world_to_canvas(line.start)
		var end = _world_to_canvas(line.end)
		draw_line(start, end, line.color, line.width)

func _world_to_canvas(global_point: Vector2):
	# There is probably a better way of doing this, but this seems fine for now
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return global_point
	var origin = get_viewport_rect().size / 2.0
	return origin + camera.to_local(global_point) * camera.zoom - camera.offset * camera.zoom

func _clear_data():
	# For now, clear all lines after each draw call.
	# Later, we could give lines a lifespan.
	_lines.clear()
