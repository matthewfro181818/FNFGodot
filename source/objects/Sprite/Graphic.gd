@tool
##A base [Sprite2D] to be compatible with [Anim].
extends Sprite2D

var _frame_offset: Vector2: set = set_frame_offset
var _frame_angle: float:
	set(value): _frame_angle = value; rotation = _frame_angle*scale.x

var pivot_offset: Vector2: 
	set(val): pivot_offset = val; _update_pivot_offset()

var _real_pivot_offset: Vector2:
	set(val):
		if val == _real_pivot_offset: return
		_real_pivot_offset = val
		_update_offset()

var _last_scale: Vector2 = Vector2.ONE
var is_solid: bool: set = set_solid

func _init() -> void: 
	process_mode = Node.PROCESS_MODE_DISABLED
	set_notify_local_transform(true)
	region_enabled = true; centered = false; use_parent_material = true; 
	texture_changed.connect(_texture_changed)

func _enter_tree() -> void: _update_offset()

func _update_offset() -> void: position = _frame_offset - _real_pivot_offset

func _update_pivot_offset(): _real_pivot_offset = (pivot_offset*scale - pivot_offset)

func set_graphic_size(size: Vector2) -> void: if is_solid: scale = size; return
func set_frame_offset(off: Vector2) -> void: _frame_offset = off*scale; _update_offset();
func _texture_changed() -> void: _frame_offset = Vector2.ZERO; rotation = 0;

@warning_ignore("native_method_override")
func set_flip_h(flip: bool): scale.x = -1 if flip else 1; _update_offset()
@warning_ignore("native_method_override")
func set_flip_v(flip: bool): scale.y = -1 if flip else 1; _update_offset()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			if _last_scale == scale: return 
			_update_pivot_offset()
			_last_scale = scale



func set_solid(solid: bool = true):
	if is_solid == solid: return
	is_solid = solid
	set_notify_local_transform(!solid)
	if !solid:
		item_rect_changed.disconnect(queue_redraw)
		queue_redraw()
		return
	pivot_offset = Vector2.ZERO
	texture = null
	is_solid = true
	centered = true
	scale = Vector2.ONE
	item_rect_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:  if is_solid: draw_rect(Rect2(Vector2.ZERO,region_rect.size),Color.WHITE)
