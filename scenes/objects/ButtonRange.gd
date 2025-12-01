@tool extends Label
#region Text Variables
@export_category("Text")
@export var prefix: String = '': set = set_prefix
@export var suffix: String = '': set = set_suffix
var _value_str: String = ''
#endregion

#region Value Variables
@export_category("Value")
@export var min: float = 0: set = set_min ##Minimum value. only has effect if [param limit_min] is enabled.
@export var max: float: set = set_max##Max value, only has effect if [param limit_max] is enabled.
@export var limit_min: bool = false
@export var limit_max: bool = false
@export var value: float = 0.0: set = set_value
@export var step: float = 1.0##The value that will be added when the arrows are been pressed.
@export var shift_step_mult: float = 2.0##When pressing [param KEY_SHIFT], the [param value] will be multiplicated for this value.
@export var int_value: bool = false: set = set_int_val
var _call_emit: bool = true
#endregion

#region Nodes
@export var update_min_size_x: bool = false: set = set_update_min_size_x
@export var update_min_size_y: bool = false: set = set_update_min_size_y
var _last_size: Vector2 = Vector2.ZERO

@onready var line_edit := $Value
@onready var button_up = $ButtonUp
@onready var button_down = $ButtonDown
@onready var _value_nodes: Array = [line_edit,button_up,button_down]

#endregion

signal value_changed(value: float) ##Called when the value changes.
signal value_added(value: float) ##Called when the value changes, returns the value added
func _ready(): 
	update_value_text()
	resized.connect(_on_minimum_size_change)
	_update_minimums_sizes()

#region Value Methods
func addValue() -> void: value += step*shift_step_mult if Input.is_action_pressed("shift") else step

func subValue() -> void: value -= step*shift_step_mult if Input.is_action_pressed("shift") else step

func set_value_no_signal(_value: float):
	_call_emit = false
	value = _value
	_call_emit = true
	
func set_value(_value: float):
	if limit_min: _value = max(_value,min)
	if limit_max: _value = min(_value,max)
	
	var emit: bool = _call_emit and value != _value
	var difference: float = _value - value
	value = snappedf(_value,0.0001)
	update_value_text()
	if !emit: return
	value_changed.emit(_value)
	value_added.emit(difference)

func _on_value_text_submitted(new_text: String) -> void:
	value = float(new_text)
	line_edit.release_focus()
#endregion

func _on_minimum_size_change() -> void:
	var min_size = get_minimum_size()
	if _last_size == min_size: return
	_last_size = min_size
	_update_minimums_sizes()
	_update_nodes_position.call_deferred()
	
func _update_nodes_position():
	var width: float = _last_size.x + 8
	var min_center = size.y*0.5
	for i in _value_nodes:
		i.position.x = width
		width += i.size.x + 2
		i.position.y = min_center - 20
	line_edit.position.x -= 4

func _update_minimums_sizes() -> void:
	if update_min_size_x: update_minimum_size_x()
	if update_min_size_y: update_minimum_size_y()
func update_minimum_size_x() -> void:  custom_minimum_size.x = _last_size.x + button_down.position.x+button_down.size.x
func update_minimum_size_y()  -> void: custom_minimum_size.y = maxf(line_edit.size.y,get_minimum_size().y)

func _draw() -> void: _on_minimum_size_change()

func update_value_text()  -> void:
	if !line_edit: return
	var value_int = int(value)
	if int_value or value_int == value: _value_str = String.num_int64(value_int)
	else: _value_str = String.num(value)
	_set_value_text()

func _set_value_text() -> void: if line_edit: line_edit.text = prefix+_value_str+suffix

#region Setters
func set_min(_v: float) -> void: min = _v; value = value
func set_max(_v: float) -> void: max = _v; value = value
func set_prefix(_v: String): prefix = _v; _set_value_text()
func set_suffix(_v: String): suffix = _v; _set_value_text()
func set_int_val(_int: bool): int_value = _int; update_value_text()
func set_step(_s: float): step = _s
func set_update_min_size_x(upd: bool) -> void: 
	update_min_size_x = upd
	if !upd: custom_minimum_size.x = 0
	elif is_node_ready(): update_minimum_size_x()
func set_update_min_size_y(upd: bool) -> void: 
	update_min_size_y = upd
	if !upd: custom_minimum_size.y = 0
	elif is_node_ready(): update_minimum_size_y()
#endregion
