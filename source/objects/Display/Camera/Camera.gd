@icon("res://icons/Camera2D.svg")
class_name CameraCanvas extends Node2D
#region Transform
@export var x: float: set = set_x, get = get_x
@export var y: float: set = set_y, get = get_y
@export var zoom: float = 1.0: set = set_zoom


var color: Color: set = set_color,get = get_color
var angle: float: set = set_angle, get = get_angle
var angle_degrees: float: set = set_angle_degress
var width: int: set = set_width
var height: int: set = set_height
var pivot_offset: Vector2 = Vector2.ZERO: set = set_pivot_offset
#endregion

#region Camera
var bg: SolidSprite = SolidSprite.new()
var _first_index: int

var scroll_camera: Node2D = Node2D.new()
var scroll: Vector2: set = set_scroll
var scrollOffset: Vector2: set = set_scroll_offset
var _scroll_position: Vector2: set = _set_scroll_position
var _scroll_pivot_offset: Vector2: set = _set_scroll_pivot_offset
var _real_scroll_position: Vector2

var flashSprite: FlashSprite = FlashSprite.new()
@export var defaultZoom: float = 1.0 #Used in PlayState

#region Shake
@export_category("Shake")
var shakeIntensity: float = 0.0: set = _set_shake_intensity
var shakeTime: float = 0.0
var _shake_pos: Vector2: set = _set_shake_pos
var _is_shaking: bool = false
#endregion

#endregion

#region Shaders
var filtersArray: Array[Material]
var viewport: SubViewport
var _viewports_created: Array[SubViewport]
var _last_viewport_added: SubViewport
var _shader_image: Sprite2D
#endregion

#region Shotcuts
var remove: Callable = scroll_camera.remove_child
#endregion

func _init() -> void:
	bg.modulate = Color.TRANSPARENT
	bg.name = &'bg'
	width = ScreenUtils.screenWidth
	height = ScreenUtils.screenHeight
	
	scroll_camera.name = &'Scroll'
	add_child(scroll_camera)
	
	flashSprite.name = &'flashSprite'
	flashSprite.modulate.a = 0.0
	scroll_camera.child_exiting_tree.connect(func(node):
		if node.get_index() < _first_index: _first_index -= 1
	)
	
	
	add_child(flashSprite)

func _ready() -> void: _update_camera_size()

#region Size Methods
func _update_camera_size():
	var size = Vector2(width,height)
	flashSprite.scale = size
	bg.scale = size
	if viewport: viewport.size = size
	pivot_offset = size/2.0
	_update_rect_visible()

func _update_viewport_size():
	for i in _viewports_created: i.size = Vector2.ONE * ScreenUtils.screenWidth/get_viewport().size.xj
#endregion

#region Shaders Methods
func setFilters(shaders: Array = []) -> void: ##Set Shaders in the Camera
	removeFilters()
	filtersArray.append_array(_convertFiltersToMaterial(shaders))
	if !filtersArray: return
	
	create_viewport()
	create_shader_image()
	
	_shader_image.material = filtersArray.back()
	
	if filtersArray.size() == 1: _shader_image.texture = viewport.get_texture(); return
	
	var index: int = 0
	var size = filtersArray.size()-1
	while index < size: _addViewportShader(filtersArray[index]); index += 1


func addFilter(shader: ShaderMaterial):
	if shader in filtersArray: return
	create_viewport()
	_addViewportShader(shader)
	filtersArray.append(shader)
	_shader_image.material = shader

func addFilters(shaders: Array) -> void: ##Add shaders to the existing ones.
	for i in _convertFiltersToMaterial(shaders): addFilter(i)

func _addViewportShader(filter: ShaderMaterial) -> Sprite2D:
	if !_last_viewport_added: return
	create_viewport()
	
	var shader_view = _get_new_viewport()
	add_child(shader_view)
	
	if filter.shader.resource_name: shader_view.name = filter.shader.resource_name
	
	var tex = Sprite2D.new()
	tex.name = &'Sprite2D'
	tex.centered = false
	tex.texture = _last_viewport_added.get_texture()
	tex.material = filter
	
	shader_view.add_child(tex)
	_viewports_created.append(shader_view)
	
	_shader_image.texture = shader_view.get_texture()
	_last_viewport_added = shader_view
	return tex

func removeFilter(shader: ShaderMaterial) -> void: ##Remove shaders.
	var filter_id = filtersArray.find(shader)
	if filter_id == -1: return
	
	if filtersArray.size() == 1: removeFilters(); return
	
	filtersArray.remove_at(filter_id)
	var prev_image: Sprite2D
	var shader_viewport = _viewports_created[filter_id]
	var view_image = shader_viewport.get_node('Sprite2D')
	
	if filter_id == filtersArray.size():  prev_image = _shader_image
	else:  prev_image = _viewports_created[filter_id+1].get_node('Sprite2D')
	prev_image.texture = view_image.texture
	_viewports_created.remove_at(filter_id)
	shader_viewport.queue_free()
	

func removeFilters(): ##Remove every shader created in this camera.
	if !filtersArray: return
	filtersArray.clear()
	if _shader_image: _shader_image.queue_free(); _shader_image = null
	
	if can_remove_viewport(): remove_viewport()
	
	if _viewports_created:
		for i in _viewports_created: i.queue_free()
		_viewports_created.clear()
	
func create_viewport() -> void:
	if viewport: return
	viewport = _get_new_viewport()
	viewport.own_world_3d = true
	add_child(viewport)
	_update_transform()
	queue_redraw()
	
	_last_viewport_added = viewport
	
	scroll_camera.transform = Transform2D(Vector2.RIGHT,Vector2.DOWN,Vector2.ZERO)
	scroll_camera.reparent(viewport,false)
	
	create_shader_image()
	
func create_shader_image():
	if _shader_image: return
	
	_shader_image = Sprite2D.new()
	_shader_image.name = &'ViewportTexture'
	_shader_image.centered = false
	_shader_image.texture = viewport.get_texture()
	
	add_child(_shader_image)
	move_child(_shader_image,0)

func remove_viewport() -> void:
	if !viewport: return
	scroll_camera.reparent(self,false)
	move_child(scroll_camera,0)
	
	viewport.queue_free()
	viewport = null
	queue_redraw()
	_update_transform()

func can_remove_viewport() -> bool: return !filtersArray and not (viewport and viewport.world_3d)
#endregion

#region Effects Methods

#region Shake
##Shake the Camera
func shake(intensity: float, time: float) -> void: shakeIntensity = intensity; shakeTime = time

func _update_shake_time(delta: float):
	if !shakeTime: return
	shakeTime -= delta
	if shakeTime <= 0.0: shakeIntensity = 0; shakeTime = 0; _shake_pos = Vector2.ZERO

func _updateShake(delta: float):
	_update_shake_time(delta)
	_shake_pos = Vector2(
		randf_range(-shakeIntensity,shakeIntensity),
		randf_range(-shakeIntensity,shakeIntensity)
	)*1000.0
#endregion
func fade(color: Variant = Color.BLACK,time: float = 1.0, _force: bool = true, _fadeIn: bool = true) -> void: ##Fade the camera.
	var tag = 'fade'+name
	if !_force and FunkinGD.isTweenRunning(tag): return
	
	flashSprite.modulate = FunkinGD._get_color(color)
	var target = 0.0 if _fadeIn else 1.0
	if !time: FunkinGD.cancelTween(tag); flashSprite.modulate.a = target
	else: 
		FunkinGD.startTweenNoCheck(
			tag,
			flashSprite,{FunkinGD.ModulateAlpha: target},
			time
		)

func flash(color: Color = Color.WHITE, time: float = 1.0, force: bool = false) -> void: ##Flash bang
	if time <= 0.0: return
	var tag = 'flash'+name
	if !force and FunkinGD.isTweenRunning(tag): return
	flashSprite.modulate = color
	FunkinGD.doTweenAlpha(tag,flashSprite,0.0,time).bind_node = self

#endregion

#region Insert/Remove Nodes Methods
func add(node: Node,front: bool = true) -> void: ##Add a node to the camera, if [code]front = false[/code], the node will be added behind of the first node added.
	if !node: return
	_insert_object_to_camera(node)
	if not front: move_to_order(node,_first_index)

func move_to_order(node: Node, order: int):
	if !node: return
	var old_index = node.get_index()
	order = mini(order,scroll_camera.get_child_count())
	scroll_camera.move_child(node,order)
	if old_index >= _first_index and order <= _first_index: _first_index += 1 #If the node was ahead of _first_index and moved before or to _first_index, add to _first_index
	elif old_index < _first_index and order > _first_index: _first_index -= 1 #If the node was before or at _first_index and moved past it, subadd to _first_index

func insert(index: int = 0,node: Object = null) -> void: ##Insert the node at [param index].
	if !node: return
	_insert_object_to_camera(node)
	move_to_order(node,index)

func _insert_object_to_camera(node: Node):
	var parent = node.get_parent()
	if parent: parent.remove_child(node)
	scroll_camera.add_child(node)
	node.set("camera",self)
#endregion

#region Transform
func _process(delta: float) -> void: if _is_shaking: _updateShake(delta)

func _update_rect_visible():
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(),true,Rect2(0,0,width,height))
	
func _update_transform() -> void:
	_update_angle()
	_update_zoom()
	_update_pivot()

func _update_pivot() -> void:
	var _scroll_pivot = pivot_offset - _scroll_position
	var _scroll_pivot_cal = _scroll_pivot
	if angle_degrees: _scroll_pivot = _scroll_pivot.rotated(angle_degrees)
	_scroll_pivot_offset = (_scroll_pivot*zoom - _scroll_pivot_cal)
	_update_scroll_transform()

func _update_angle()  -> void:
	if viewport: 
		viewport.canvas_transform.x.y = -angle_degrees
		viewport.canvas_transform.y.x = angle_degrees
	else: scroll_camera.rotation = angle_degrees
	_update_pivot()

func _update_zoom() -> void:
	if viewport: 
		viewport.canvas_transform.x.x = zoom
		viewport.canvas_transform.y.y = zoom
	else: scroll_camera.scale = Vector2(zoom,zoom)
	_update_pivot()

func _update_scroll_pos() -> void: _set_scroll_position(-scroll + scrollOffset)

func _update_scroll_transform():
	_real_scroll_position = _scroll_position - _scroll_pivot_offset + _shake_pos
	if viewport: viewport.canvas_transform.origin = _real_scroll_position
	else: scroll_camera.position = _real_scroll_position
#endregion

#region Setters
func set_x(_x: float) -> void: position.x = _x
func set_y(_y: float) -> void: position.y = _y
func set_width(value: int) -> void: width = value; _update_camera_size()
func set_height(value: int) -> void: height = value; _update_camera_size()
func set_zoom(value: float) -> void: zoom = value; _update_zoom()
func set_angle(value: float) -> void: angle_degrees = deg_to_rad(value)
func set_angle_degress(value: float): angle_degrees = value; _update_angle()
func set_pivot_offset(value: Vector2) -> void: pivot_offset = value; _update_pivot()
func set_scroll(val: Vector2) -> void: scroll = val; _update_scroll_pos()
func set_scroll_offset(val: Vector2): scrollOffset = val; _update_scroll_pos()
func _set_scroll_position(val: Vector2) -> void: _scroll_position = val; _update_pivot();
func _set_scroll_pivot_offset(val: Vector2) -> void: _scroll_pivot_offset = val; _update_scroll_transform()
func _set_shake_pos(val: Vector2): _shake_pos = val; _update_scroll_transform()
func _set_shake_intensity(intensity: float): 
	shakeIntensity = intensity
	_is_shaking = intensity
	if !_is_shaking: _shake_pos = Vector2.ZERO
func set_color(_color: Variant): 
	scroll_camera.modulate.r = _color.r; 
	scroll_camera.modulate.g = _color.g; 
	scroll_camera.modulate.b = _color.b
#endregion

#region Getters
func get_x() -> float: return position.x
func get_y() -> float: return position.y
func get_angle() -> float: return rad_to_deg(angle_degrees)
func get_color() -> Color: return scroll_camera.modulate
func _property_get_revert(property: StringName) -> Variant:
	match property:
		'zoom': return defaultZoom
		'defaultZoom': return 1.0
		'scrollOffset': return Vector2.ZERO
		'angle','shakeIntensity','x','y': return 0.0
	return null

#endregion

static func _convertFiltersToMaterial(shaders: Array) -> Array[Material]:
	var array: Array[Material] = []
	for i in shaders:
		var shader: Material = (Paths.loadShader(i) if i is String else i)
		if !shader or shader in array: continue
		array.append(shader)
	return array

static func _get_new_viewport() -> SubViewport:
	var view = SubViewport.new()
	view.transparent_bg = true
	view.disable_3d = true
	view.gui_snap_controls_to_pixels = false
	view.size = ScreenUtils.screenSize
	view.own_world_3d = true
	return view

func _draw() -> void: RenderingServer.canvas_item_set_clip(get_canvas_item(),true)

@warning_ignore("missing_tool")
class FlashSprite:
	extends SolidSprite
	var window: Viewport:
		set(value):
			if window == value: return
			elif window: window.size_changed.disconnect(_update_size)
			window = value
			if !value: return
			window.size_changed.connect(_update_size)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PARENTED: window = get_viewport()
	func _update_size(): scale = window.size
