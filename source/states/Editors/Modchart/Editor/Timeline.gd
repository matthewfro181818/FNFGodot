@tool
extends Node2D
const ModchartEditor = preload("res://source/states/Editors/Modchart/Editor/ModchartEditor.gd")
@export_range(0,100,1.0)  var timeline_space: float = 40.0: set = set_timeline_space
@export var step_init: int = 0: set = set_step_init
@export var steps: int = 0: set = set_steps
@export var line_height: float = 20.0: set = set_line_height
@export var font_size: int = 14: set = set_font_size
@export var draw_limit: int = 32: set = set_draw_limit

var _timeline_space_center: float = timeline_space*0.5
var height_center: float = line_height*0.5

var _real_step_init: int = step_init: set = _set_real_step_init
var _step_offset: int = 0

func _init() -> void: set_notify_local_transform(true)

func _draw() -> void:
	var first_step = step_init - _step_offset
	var first_pos = _timeline_space_center-_step_offset*timeline_space + 1
	
	var step: int = first_step
	var steps_to_be_draw = step + mini(steps-step,draw_limit)
	var lines_to_draw = steps_to_be_draw+1
	var pos_x: float = first_pos - _timeline_space_center
	
	#Draw Lines
	while step <= lines_to_draw:
		draw_line(Vector2(pos_x, height_center),Vector2(pos_x, line_height), Color.WHITE,3)
		pos_x += timeline_space
		step += 1
	
	
	#Draw Steps
	step = first_step
	pos_x = first_pos - 3
	while step <= steps_to_be_draw:
		var str_step = String.num_int64(step)
		var cur_step_length = str_step.length()
		var text_size: int = font_size - cur_step_length if cur_step_length else font_size
		
		draw_string(
			ThemeDB.fallback_font,
			Vector2(pos_x - (cur_step_length-1)*3, line_height),
			str_step,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			text_size
		)
		pos_x += timeline_space
		step += 1

func _notification(what: int) -> void: 
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED: _update_real_step_init()

func _update_real_step_init():
	_step_offset = ceili((position.x+30)/timeline_space)-1
	_real_step_init = step_init + _step_offset

#region Setters
func set_draw_limit(limit: int): draw_limit = limit; queue_redraw()

func _set_real_step_init(init: int):
	if _real_step_init == init: return
	_real_step_init = init
	queue_redraw()

func set_font_size(size: int) -> void: 
	if font_size == size: return
	font_size = size; queue_redraw()

func set_step_init(init: int): 
	init = mini(init,steps)
	if step_init == init: return
	step_init = init;
	_update_real_step_init()

func set_steps(val: int): 
	if steps == val: return
	steps = val; queue_redraw()

func set_timeline_space(space: float): 
	if space == timeline_space: return
	timeline_space = space
	_timeline_space_center = space*0.5; queue_redraw()

func set_line_height(height: float): 
	if line_height == height: return
	line_height = height;height_center = height*0.5; queue_redraw()
#endregion
