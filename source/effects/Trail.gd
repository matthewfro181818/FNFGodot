var trailTime: float = 0.3

static var process_frame_signal: Signal
var object: CanvasItem: 
	set(node):
		if object == node:
			return
		object = node
		_trail_image = node
		
		if !node: return
	
		trailType = 0
		if object is FunkinSprite:
			_trail_image = node.image
		if _trail_image is Sprite2D:
			trailType = 1
		
		if frequency > 0:
			start_process()


var _trail_image: CanvasItem

var frequency: float = 0.1: set = set_frequency
var _cur_time: float = 0.0

var enabled: bool = false

var trailColor: Color = Color.WHITE
var trailVelocity: Vector2 = Vector2.ZERO

var trails: Array = []
var trailParent: Node

var trailType: int = 0

var trailLimit: int = 15
var trailLength: int = 0

var trailBlend: set = set_blend
func _init(obj: Node = null, timeFrequency: float = 0.1, color: Color = Color.WHITE):
	object = obj
	frequency = timeFrequency
	trailColor = color
	_cur_time = frequency
	trailBlend = 'add'
	
func set_blend(blend):
	if blend is String:
		trailBlend = CanvasItemMaterial.new()
		match blend.to_lower():
			'add':
				trailBlend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			'mix':
				trailBlend.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			'subtract':
				trailBlend.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			'multiply':
				trailBlend.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
			_:
				trailBlend = null
		return
	trailBlend = blend
			
func set_frequency(time: float):
	frequency = time
	if time > 0:
		start_process()
	
func start_process():
	if enabled or !object:return
	enabled = true
	if !process_frame_signal: process_frame_signal = Engine.get_main_loop().process_frame
	var delta = Global.get_process_delta_time()
	while true:
		_cur_time -= delta
		if _cur_time <= 0:
			_cur_time = frequency
			createTrail()
		var i = trails.size()
		while i > 0:
			i -= 1
			var trail = trails[i]
			if trail == null:
				trails.remove_at(i)
				continue
			trail.modulate.a -= delta/trailTime
			trail.position += trailVelocity * delta
			if trail.modulate.a <= 0.0:
				trail.queue_free()
				trails.remove_at(i)
				continue
			
		
		if not trails and (not is_instance_valid(object) or frequency <= 0.0):
			enabled = false
			break
		await process_frame_signal
		
static func getObjectCopy(object) -> Node:
	if !object:return
	if !object is FunkinSprite: return object.duplicate()
	
	if !object.image or !object.animation or !object.animation.curAnim.node_to_animate: return
	var trail = (object.animation.curAnim.node_to_animate if object.animation else object.image).duplicate()
	trail._frame_offset += object.position
	trail.scale += object.scale - Vector2.ONE
	trail.pivot_offset = object.pivot_offset
	trail.rotation += object.rotation
	return trail


func createTrail() -> Node:
	if !is_instance_valid(object) or !object.visible: return
	var trail = getObjectCopy(object)
	if !trail:
		return
	trail.modulate = trailColor
	trail.modulate.a *= 0.8
	trail.material = trailBlend
	
	trails.push_front(trail)
	if trailLength >= trailLimit and trails:
		trails[0].queue_free()
		trailLength -= 1
	trailLength += 1
	
	object.add_sibling(trail)
	object.get_parent().move_child(trail,object.get_index())
	return trail

func eraseTrails():
	for trail in trails:
		trail.queue_free()
