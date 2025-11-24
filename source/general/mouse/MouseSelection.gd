extends ReferenceRect

var bg = ColorRect.new()

signal started
signal released


var mouse_pos: Vector2 = Vector2.ZERO

var start_pos: Vector2 = Vector2.ZERO
var button_select: int = 1

var can_select: bool = true:
	set(value):
		can_select = value
		if !value: visible = false; return
func _init() -> void:
	add_child(bg)
	resized.connect(func(): bg.size = size)
	visible = false
	border_color = Color.SKY_BLUE
	bg.color = Color.LIGHT_BLUE
	bg.modulate.a = 0.6
	
	editor_only = false


func start_selection():
	if visible: return
	var viewport = get_viewport()
	if !viewport:
		push_error("Error on MouseSelection: start_selection: MouseSelection must be in the tree to be used.")
		return
	start_pos = viewport.get_mouse_position()
	visible = true
	global_position = start_pos
	mouse_pos = start_pos
	update_size()
	started.emit()

func stop_selection(remove_from_parent: bool = false):
	if !visible: return
	released.emit()
	visible = false
	if remove_from_parent and get_parent():
		get_parent().remove_child(self)
		
	
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	name = 'Mouse Selection'
	
func _process(_d) -> void:
	if visible:
		update_size()
	
func update_size():
	var pos = (get_viewport().get_mouse_position() - start_pos)
	global_position = start_pos + Vector2.ZERO.min(pos)
	size = pos.abs()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == button_select:
		if !event.pressed: stop_selection(); return
		check_selection.call_deferred(event)

func check_selection(event: InputEventMouseButton):
	if !can_select: return
	start_selection()
