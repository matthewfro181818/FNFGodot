extends Control
const KeyInterpolator = preload("res://source/states/Editors/Modchart/Keys/KeyInterpolator.gd")
const ModchartEditor = preload("res://source/states/Editors/Modchart/Editor/ModchartEditor.gd")
const Points: PackedVector2Array = [
	Vector2(0, 0.5), #Left
	Vector2(0.5, 0), #Top
	Vector2(1, 0.5), #Right
	Vector2(0.5, 1) #Down
]

const KEY_SIZE = Vector2(10,10)
const KEY_CENTER = Vector2(5,5)
static var polygon_points: PackedVector2Array = PackedVector2Array()
static var key_length_size: float = 24
var data: KeyInterpolator

var step_crochet: float = 0.0: set = _set_step_crochet #Sets in ModchartEditor
var step: float = 0.0 #Sets and used in Grid
var parent
var length: float = 0.0


func _init(interpolator: KeyInterpolator = KeyInterpolator.new()): 
	data = interpolator
	data.key_node = self
	size = KEY_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	if !polygon_points:
		for i in Points: polygon_points.append(i*KEY_SIZE)
	
func _draw() -> void:
	if data.duration: 
		length = data.duration/step_crochet*key_length_size
		draw_rect(Rect2(
			Vector2(KEY_CENTER.x,KEY_CENTER.y*0.5),
			Vector2(length,KEY_CENTER.y)
		),Color.WHITE)
		size.x = length
	else:
		length = 0.0
		size.x = KEY_SIZE.x
	draw_polygon(polygon_points,PackedColorArray([Color.WHITE]))

func updatePos():
	if parent: position.x = -KEY_CENTER.x+step*key_length_size - parent.position.x

func _set_step_crochet(crochet: float):
	step_crochet = crochet
	queue_redraw()
