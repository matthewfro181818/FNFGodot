@icon("res://icons/Chess.svg")
@tool
class_name Chess
extends Control

@export var primary_color: Color = Color.GRAY: set = set_primary_color
@export var primary_fill: bool = true: set = set_primary_fill
@export var primary_border_width: float = 5.0: set = set_primary_border_width
@export var secondary_color: Color = Color.DIM_GRAY: set = set_secondary_color
@export var secondary_fill: bool = true: set = set_secondary_fill
@export var secondary_border_width: float = 5.0: set = set_secondary_border_width

@export var rect_size: Vector2 = Vector2(30,30): set = set_rect_size
@export var steps: int = 4: set = set_steps
@export var length: int = 2: set = set_length

var width: float
var height: float

var _node_offset: Vector2 = Vector2.ZERO
var node: Node2D: get = _get_node
func _init() -> void: resized.connect(_update_size)

func _ready() -> void: 
	_update_size()

func _get_node() -> Node2D:
	if node: return node
	var node_find = get_node_or_null('Chess')
	if node_find: node = node_find; return node_find
	
	node = Node2D.new()
	node.name = 'Chess'
	node.show_behind_parent = true
	add_child(node)
	return node

func _update_size(): size = rect_size*Vector2(steps,length)

func set_steps(step: int) -> void:
	steps = step
	if is_inside_tree(): queue_redraw()

func set_length(_length: int) -> void:
	length = _length
	if is_inside_tree(): queue_redraw()

func set_rect_size(size: Vector2) -> void:
	rect_size = size
	if is_inside_tree(): queue_redraw()

func set_primary_color(color: Color) -> void:
	primary_color = color
	if is_inside_tree(): queue_redraw()

func set_primary_fill(fill: bool) -> void:
	primary_fill = fill
	if is_inside_tree(): queue_redraw()

func set_primary_border_width(width: float) -> void:
	primary_border_width = width
	if !primary_fill and is_inside_tree(): queue_redraw()

func set_secondary_fill(fill: bool) -> void:
	secondary_fill = fill
	if is_inside_tree(): queue_redraw()

func set_secondary_border_width(width: float) -> void:
	secondary_border_width = width
	if !secondary_fill and is_inside_tree(): queue_redraw()
	
func set_secondary_color(color: Color) -> void:
	secondary_color = color
	if is_inside_tree(): queue_redraw()

func _draw_chess() -> void:
	var nrid = node.get_canvas_item()
	if primary_fill:
		RenderingServer.canvas_item_add_rect(nrid,Rect2(Vector2.ZERO,rect_size),primary_color)
		RenderingServer.canvas_item_add_rect(nrid,Rect2(rect_size,rect_size),primary_color)
	else:
		var center = primary_border_width/2.0
		#region Left Top
		#Left
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(center,0.0),
			Vector2(center,rect_size.y),
			primary_color,primary_border_width
		)
		#Right
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(rect_size.x-center,0.0),
			Vector2(rect_size.x-center,rect_size.y),
			primary_color,primary_border_width
		)
		#Top
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(0.0,center),
			Vector2(rect_size.x,center),
			primary_color,primary_border_width
		)
		#Bottom
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(0.0,rect_size.y-center),
			Vector2(rect_size.x,rect_size.y-center),
			primary_color,primary_border_width
		)
		#endregion
		
		#region Right Bottom
		#Left
		RenderingServer.canvas_item_add_line(nrid,
			rect_size + Vector2(center,0.0),
			rect_size + Vector2(center,rect_size.y),
			primary_color,primary_border_width
		)
		#Right
		RenderingServer.canvas_item_add_line(nrid,
			rect_size + Vector2(rect_size.x-center,0.0),
			rect_size + Vector2(rect_size.x-center,rect_size.y),
			primary_color,primary_border_width
		)
		#Top
		RenderingServer.canvas_item_add_line(nrid,
			rect_size + Vector2(0.0,center),
			rect_size + Vector2(rect_size.x,center),
			primary_color,primary_border_width
		)
		#Down
		RenderingServer.canvas_item_add_line(nrid,
			rect_size + Vector2(0.0,rect_size.y-center),
			rect_size + Vector2(rect_size.x,rect_size.y-center),
			primary_color,primary_border_width
		)
		#endregion
	if secondary_fill:
		RenderingServer.canvas_item_add_rect(nrid,Rect2(Vector2(rect_size.x,0),rect_size),secondary_color)
		RenderingServer.canvas_item_add_rect(nrid,Rect2(Vector2(0,rect_size.y),rect_size),secondary_color)
	else:
		var center = secondary_border_width/2.0
		var pos_end = rect_size*2.0
		#region Right Top
		#Left
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(rect_size.x + center,0.0),
			Vector2(rect_size.x + center,rect_size.y),
			secondary_color,secondary_border_width
		)
		#Right
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(pos_end.x-center,0.0),
			Vector2(pos_end.x-center,rect_size.y),
			secondary_color,secondary_border_width
		)
		#Top
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(rect_size.x,center),
			Vector2(pos_end.x,center),
			secondary_color,secondary_border_width
		)
		#Down
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(rect_size.x,rect_size.y-center),
			Vector2(pos_end.x,rect_size.y-center),
			secondary_color,secondary_border_width
		)
		#endregion
		
		#region Left Bottom
		#Left
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(center,rect_size.y),
			Vector2(center,pos_end.y),
			secondary_color,secondary_border_width
		)
		#Right
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(rect_size.x-center,rect_size.y),
			Vector2(rect_size.x-center,pos_end.y),
			secondary_color,secondary_border_width
		)
		
		#Top
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(0.0,rect_size.y + center),
			Vector2(rect_size.x,rect_size.y + center),
			secondary_color,secondary_border_width
		)
		#Down
		RenderingServer.canvas_item_add_line(nrid,
			Vector2(0.0,pos_end.y-center),
			Vector2(rect_size.x,pos_end.y-center),
			secondary_color,secondary_border_width
		)
		#endregion

	
	var repeat_count = maxf(steps,length)
	var repeat_size = rect_size*2.0
	
	_node_offset = repeat_size*floorf(repeat_count/2)
	RenderingServer.canvas_set_item_repeat(nrid,rect_size*2.0,maxi(steps,length))
	RenderingServer.canvas_item_set_transform(nrid,Transform2D(0.0,_node_offset))
	
	
	var rid = get_canvas_item()
	_update_size()
	RenderingServer.canvas_item_set_custom_rect(
		rid,true,
		Rect2(Vector2.ZERO,size)
	)
	RenderingServer.canvas_item_set_clip(rid,true)
	#RenderingServer.canvas_item_set_default_texture_repeat(rid,RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_ENABLED)

func _draw() -> void:
	node.queue_redraw()
	width = rect_size.x*steps
	height = rect_size.y*length
	_draw_chess.call_deferred()
