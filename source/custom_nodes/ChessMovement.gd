@tool
class_name ChessScroll
extends Chess

@export var scroll_speed: Vector2 = Vector2(20,20)
var scroll: Vector2 = Vector2.ZERO
func set_rect_size(size: Vector2) -> void:
	super.set_rect_size(size)
	scroll = Vector2.ZERO
	
func _process(delta: float) -> void:
	scroll += scroll_speed*delta
	scroll.x = fmod(scroll.x,rect_size.x*2.0)
	scroll.y = fmod(scroll.y,rect_size.y*2.0)
	RenderingServer.canvas_item_set_transform(node.get_canvas_item(),Transform2D(0.0,scroll - rect_size))
