@icon("res://icons/process_bar_2d.svg")
extends Node2D
var bg: FunkinSprite = FunkinSprite.new()

var x: float:
	set(val): position.x = val
	get(): return position.x

var y: float: 
	set(val): position.y = val
	get(): return position.y

var margin_offset_left: float = 4.0:
	set(val): margin_offset_left = val; _update_bar()
var margin_offset_right: float = 4.0:
	set(val): margin_offset_right = val; _update_bar()
var margin_offset_top: float = 4.0:
	set(val): margin_offset_top = val; _update_bar()
var margin_offset_bottom: float = 4.0:
	set(val): margin_offset_bottom = val; _update_bar()

var leftBar: CanvasItem = _get_fill_bar(null,true)
var rightBar: CanvasItem = _get_fill_bar(null,true)

var progress: float = 0.5: set = set_progress

var progress_position: Vector2

var flip: bool = false: set = set_flip

var bar_size: Vector2:
	set(val):
		if bar_size == val: return
		if bg.image.texture: bg.scale = val/bg.image.texture.get_size()
		bar_size = val
		_update_bar_fill_size()

var fill_bars_size: Vector2 = Vector2.ZERO
var _right_bar_is_color: bool = true: set = set_right_bar_is_color
var _left_bar_is_color: bool = true: set = set_left_bar_is_color

func _init(bgImage: StringName = &""):
	name = &'bar'
	bg.image.texture_changed.connect(func(): bg.pivot_offset = Vector2.ZERO; bar_size = Vector2(bg.width,bg.height))
	
	if bgImage: bg.image.texture = Paths.texture(bgImage)
	bg.name = &'bg'
	add_child(rightBar)
	rightBar.modulate = Color(0.4,0.4,0.4,1)
	add_child(leftBar)
	add_child(bg)

func _ready():
	leftBar.name = &'leftBar'
	rightBar.name = &'rightBar'
	_update_bar_fill_size()

static func _get_fill_bar(old_bar: CanvasItem = null, is_solid_color: bool = true) -> CanvasItem:
	var new_bar
	if is_solid_color:
		new_bar = SolidSprite.new()
		if old_bar: new_bar.size = old_bar.region_rect.size.x
		new_bar.position = Vector2(3,3)
	else:
		new_bar = get_animated_bar()
		if old_bar: new_bar.region_rect.size.x = old_bar.size.x
	
	if old_bar: old_bar.queue_free()
	return new_bar

func flip_colors():
	var leftColor = leftBar.modulate
	leftBar.modulate = rightBar.modulate
	rightBar.modulate = leftColor

##Set Bar Images, if dont want to change, leave blank.
func set_bar_image(base: Variant = null,left: Variant = null,right: Variant = null) -> void:
	if base: bg.image.texture = Paths.texture(base) if base is String else base
	
	if left:
		_left_bar_is_color = false
		leftBar.texture = Paths.texture(left)  if left is String else left
		leftBar.region_rect.size = leftBar.texture.get_size()
		
	if right:
		_right_bar_is_color = false
		rightBar.texture = Paths.texture(right) if right is String else right
		rightBar.region_rect.size = rightBar.texture.get_size()
	_update_bar()
	
func move_bg_to_front() -> void: move_child(bg,get_child_count())
func move_bg_to_behind() -> void:move_child(bg,0)

#region Updaters
func _update_bar_position():
	leftBar.position = Vector2(margin_offset_left,margin_offset_top)
	rightBar.position = leftBar.position

func _update_bar() -> void:
	if !is_node_ready(): return
	_update_bar_position()
	var bar_size = Vector2(fill_bars_size.x*progress,fill_bars_size.y)
	if _left_bar_is_color: leftBar.size = bar_size
	else: leftBar.region_rect.size = bar_size
	
	if _right_bar_is_color: rightBar.size = fill_bars_size
	else: rightBar.region_rect.size = fill_bars_size
	
	progress_position = get_process_position()

func _update_bar_fill_size():
	if !is_node_ready(): return
	fill_bars_size = bar_size - Vector2(
		margin_offset_left + margin_offset_right,
		margin_offset_top + margin_offset_bottom
	)
	_update_bar()
#endregion

##Set the bar colors. [param left] and [param right] can be a [Array] or a [Color].[br]
##If is a [Array], the values inside it will be divided by [code]255[/code].
##To put a color in just one side, set [code]null[/code] for the another:[codeblock]
##var bar = Bar.new()
##bar.set_colors([255,255,255],null) #Set color of the left bar to white.
##bar.set_colors(null,Color.RED) #Set color of the right bar to red.
##[/codeblock]
func set_colors(left: Variant = null, right: Variant = null) -> void:
	if left: leftBar.modulate = left if left is Color else Color(left[0]/255.0,left[1]/255.0,left[2]/255.0)
	if right: rightBar.modulate = right if right is Color else Color(right[0]/255.0,right[1]/255.0,right[2]/255.0)

#region Setters
func set_flip(f: bool) -> void: flip = f; _update_bar()
func set_progress(p: float):
	if progress == p: return
	p = clampf(p,0,1.0)
	progress = p
	_update_bar()

func set_left_bar_is_color(is_c: bool) -> void:
	if _left_bar_is_color == is_c:return
	_left_bar_is_color = is_c
	leftBar = _get_fill_bar(leftBar,is_c)
	add_child(leftBar)
	move_child(leftBar,bg.get_index())
	leftBar.name = &'leftBar'

func set_right_bar_is_color(is_c: bool) -> void:
	if is_c == _right_bar_is_color: return
	_right_bar_is_color = is_c
	rightBar = _get_fill_bar(rightBar,is_c)
	add_child(rightBar)
	move_child(rightBar,0)
	rightBar.name = &'rightBar'


#endregion

#region Getters
func get_process_position(process: float = progress) -> Vector2:
	var _process = Vector2(bar_size.x*process,0.0)*scale
	if rotation: return _process.rotated(rotation)
	return _process

static func get_animated_bar() -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.centered = false
	sprite.region_enabled = true
	return sprite
#endregion

func screenCenter(pos: String = 'xy') -> void:
	if pos.begins_with('x'): position.x = ScreenUtils.screenCenter.x - bg.width*0.5
	if pos.ends_with('y'): position.y = ScreenUtils.screenCenter.y - bg.height*0.5
	
