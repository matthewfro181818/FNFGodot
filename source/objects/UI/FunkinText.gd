extends Label 
class_name FunkinText

var _position: Vector2
@export var x: float:
	set(value): _position.x = value
	get(): return _position.x
@export var y: float:
	set(value): _position.y = value
	get(): return _position.y

var scrollFactor: Vector2

var camera: FunkinCamera
var _real_scroll_factor: Vector2:
	set(val): _real_scroll_factor = val; _need_to_update_scroll = val != Vector2.ZERO

var _real_scroll_offset: Vector2:
	set(val): position -= val - _real_scroll_offset; _real_scroll_factor = val
	
var _need_to_update_scroll: bool

var parent: Node

func _init(_text: String = '', width: float = ScreenUtils.screenWidth):
	autowrap_mode = TextServer.AUTOWRAP_WORD
	text = _text
	size.x = width
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set(&"theme_override_constants/outline_size",7)

func _enter_tree() -> void: 
	_update_position()
	parent = get_parent()

func _process(_d: float) -> void:
	if _need_to_update_scroll: _update_scroll()

func _update_scroll():
	var pos = camera.scroll if camera else parent.get(&'position')
	if !pos: _real_scroll_factor = Vector2.ZERO; return
	_real_scroll_offset = pos * _real_scroll_factor
	
func _update_position():
	position = _position - _real_scroll_factor

@warning_ignore("native_method_override")
func set_position(_pos: Vector2, _keep_offsets: bool = false):
	_position = _pos
