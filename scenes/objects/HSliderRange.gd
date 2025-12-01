@tool
extends Label

@export var value: float = 0.0: set = set_value
@export var step: float = 0.1: set = set_step
@export var min_value: float = -99999.0: set = set_minimum_value
@export var max_value: float = 99999.0: set = set_maximum_value

@onready var slider = $HSlider
@onready var line_edit = $LineEdit

var _call_signal: bool = true

var int_value: bool: set = set_int_value
signal value_changed(value: float)
func _ready() -> void:
	slider.set_value_no_signal(value)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.rounded = int_value
	slider.step = step
	
	line_edit.set_value_no_signal(value)
	line_edit.min_value = min_value
	line_edit.max_value = max_value

func set_minimum_value(val: float):
	min_value = val
	if value < val: value = val
	if !is_node_ready(): return
	slider.min_value = val
	line_edit.min_val = val

func set_maximum_value(val: float):
	max_value = val
	if value > val: value = val
	if !is_node_ready(): return
	slider.max_value = val
	line_edit.max_value = val

func set_value(_v: float):
	_v = snappedf(clampf(_v,min_value,max_value),0.001)
	if _v == value: return
	value = _v
	if !is_node_ready(): return
	if _call_signal:
		value_changed.emit(value)
		slider.value = value
		line_edit.value = value
	else:
		slider.set_value_no_signal(value)
		line_edit.set_value_no_signal(value)
func set_value_no_signal(_v: float) -> void:
	_call_signal = false
	set_value(_v)
	_call_signal = true

func _draw() -> void:
	var minimum = get_minimum_size().x
	var center = size.y*0.5 - 10
	line_edit.position = Vector2(minimum,center)
	slider.position = Vector2(minimum+line_edit.size.x + 10,center)

#region Setters
func set_int_value(_int: bool) -> void: int_value = _int; if slider: slider.rounded = _int
func set_step(_s: float) -> void:
	step = _s
	if slider: slider.step = step
#endregion
