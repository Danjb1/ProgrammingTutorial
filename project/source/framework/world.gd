extends Node
## Autoload class that handles level transitions.

var _player: PlayerCharacter

var _loaded_level: Node
var _level_to_load: String
var _target_entrance: String

func _ready() -> void:
	# The initially-loaded level is the last child of the root, since autoload singletons are
	# always loaded first.
	# See: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html#creating-the-script
	var root := get_tree().root
	_loaded_level = root.get_child(root.get_child_count() - 1)
	set_process(false)

func register_player(player: PlayerCharacter):
	_player = player

func request_level(level_path: String, entrance: String) -> void:
	_level_to_load = level_path
	_target_entrance = entrance
	set_process(true)

func _process(_delta: float) -> void:
	if _try_load_pending_level():
		_teleport_to_entrance()
	set_process(false)

func _try_load_pending_level() -> bool:
	if not _level_to_load:
		return false;
	_unload_current_level()
	# This is currently synchronous, we may want to show a loading screen instead
	var level_resource = load(_level_to_load)
	if not level_resource:
		push_warning("Failed to load level: %s" % _level_to_load)
		_level_to_load = ""
		return false
	_loaded_level = level_resource.instantiate()
	get_tree().root.add_child(_loaded_level)
	_level_to_load = ""
	return true

func _unload_current_level() -> void:
	if _loaded_level:
		_loaded_level.free()

func _teleport_to_entrance():
	if not _player and _target_entrance:
		return
	var entrance_node: Node2D = _loaded_level.get_node_or_null(_target_entrance)
	if entrance_node:
		_player.teleport(entrance_node.global_position)
	else:
		push_warning("Target entrance not found: %s" % _target_entrance)
