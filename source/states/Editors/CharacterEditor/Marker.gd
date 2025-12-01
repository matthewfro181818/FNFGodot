@tool
extends Node2D
@export var marker_size: Vector2 = Vector2(36,5):
	set(value):
		marker_size = value
		queue_redraw()
@export var v_color: Color = Color.WHITE:
	set(value):
		v_color = value
		queue_redraw()
@export var h_color: Color = Color.WHITE:
	set(value):
		h_color = value
		queue_redraw()

func _draw() -> void:
	var center = marker_size.x*0.5 - marker_size.y*0.5
	draw_rect(Rect2(
		center,
		0,
		marker_size.y,
		marker_size.x
		),v_color)
	draw_rect(Rect2(
		Vector2(0,center),marker_size),
		h_color
	)
