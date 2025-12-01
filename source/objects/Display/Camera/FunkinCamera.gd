@icon("res://icons/Camera2D.svg")
class_name FunkinCamera extends Node2D
#region Transform
@export var x: float:
	set(val): position.x = val 
	get(): return position.x
@export var y: float: 
	set(val): position.y = val 
	get(): return position.y

@export var zoom: float = 1.0:
	set(val): zoom = val; _update_zoom()

var color: Color:
	set(value): modulate = value
	get(): return modulate

var angle: float:
	set(val): angle_degrees = deg_to_rad(val)
	get(): return rad_to_deg(angle_degrees)

var angle_degrees: float:
	set(val): angle_degrees = val; _update_angle()

var width: float:
	set(value): width = value; _update_camera_size()
var height: float:
	set(value): height = value; _update_camera_size()

var pivot_offset: Vector2 = Vector2.ZERO: 
	set(val): pivot_offset = val; _update_pivot()
#endregion

#region Camera
var bg: SolidSprite = SolidSprite.new()
var _first_index: int

var scroll_camera: Node2D = Node2D.new()
var scroll: Vector2: 
	set(val): scroll = val; _update_scroll_pos()

var scrollOffset: Vector2: 
	set(val): scrollOffset = val; _update_scroll_pos()

var _scroll_position: Vector2: 
	set(val): _scroll_position = val; _update_pivot();

var _scroll_pivot_offset: Vector2: 
	set(val): _scroll_pivot_offset = val; _update_scroll_transform() 

var _real_scroll_position: Vector2

var flashSprite: SolidSprite = SolidSprite.new()
@export var defaultZoom: float = 1.0 #Used in PlayState

#region Shake
@export_category("Shake")
var shakeIntensity: float: 
	set(val): shakeIntensity = val; _is_shaking = val; if !_is_shaking: _shake_pos = Vector2.ZERO

var shakeTime: float
var _shake_pos: Vector2:
	set(val): _shake_pos = val; _update_scroll_transform()

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
	
	child_entered_tree.connect(func(_n):
		move_child.call_deferred(flashSprite,-1)
	)
	
	
	add_child(flashSprite)

func _ready() -> void: _update_camera_size()

#region Size Methods
func _update_camera_size():
	bg.scale.x = width; bg.scale.y = height
	var size = bg.scale
	flashSprite.size = size
	
	if viewport: viewport.size = size
	pivot_offset = size/2.0
	_update_rect_visible()

func _update_viewport_size():
	for i in _viewports_created: i.size = Vector2.ONE * ScreenUtils.screenWidth/get_viewport().size.xj
#endregion

#region Shaders Methods
func setFilters(shaders: Array) -> void: ##Set Shaders in the Camera
	removeFilters()
	if !shaders: return
	
	shaders = _convertFiltersToMaterial(shaders)
	create_viewport()
	create_shader_image()
	
	var index: int = 0
	var size = shaders.size()
	while index < size: addFilter(shaders[index]); index += 1

func addFilter(shader: ShaderMaterial) -> void:
	if shader in filtersArray: return
	create_viewport()
	
	if filtersArray: _addViewportShader(filtersArray.back())
	filtersArray.append(shader)
	_shader_image.material = shader

func addFilters(shaders: Array) -> void: for i in _convertFiltersToMaterial(shaders): addFilter(i) ##Add shaders to the existing ones.
	

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

func safe_remove_viewport() -> void: if can_remove_viewport(): remove_viewport()

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
	_shake_pos.x = randf_range(-shakeIntensity,shakeIntensity)*1000.0
	_shake_pos.y = randf_range(-shakeIntensity,shakeIntensity)*1000.0

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
			flashSprite,{^"modulate:a": target},
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
	_update_angle(false)
	_update_zoom(false)
	_update_pivot()

func _update_pivot() -> void:
	var _scroll_pivot = pivot_offset - _scroll_position
	var _scroll_pivot_cal = _scroll_pivot
	if angle_degrees: _scroll_pivot = _scroll_pivot.rotated(angle_degrees)
	if zoom != 1.0: _scroll_pivot *= zoom
	_scroll_pivot_offset = (_scroll_pivot - _scroll_pivot_cal)
	_update_scroll_transform()

func _update_angle(update_pivo: bool = true)  -> void:
	if viewport: 
		viewport.canvas_transform.x.y = -angle_degrees
		viewport.canvas_transform.y.x = angle_degrees
	else: scroll_camera.rotation = angle_degrees
	if update_pivo: _update_pivot()

func _update_zoom(update_pivo: bool = true) -> void:
	var new_zoom = Vector2(zoom,zoom)
	if viewport: 
		viewport.canvas_transform.x.x = zoom
		viewport.canvas_transform.y.y = zoom
	else: scroll_camera.scale = new_zoom
	if update_pivo: _update_pivot()

func _update_scroll_pos() -> void: _scroll_position = -scroll + scrollOffset

func _update_scroll_transform():
	_real_scroll_position = _scroll_position - _scroll_pivot_offset + _shake_pos
	if viewport: viewport.canvas_transform.origin = _real_scroll_position
	else: scroll_camera.position = _real_scroll_position
#endregion

#region Setters
#endregion

#region Getters
func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'zoom': return defaultZoom
		&'defaultZoom': return 1.0
		&'scrollOffset': return Vector2.ZERO
		&'angle',&'shakeIntensity',&'x',&'y': return 0.0
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
