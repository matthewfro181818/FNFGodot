@abstract
extends RefCounted
var duration: float  ##Tween duration.
var step: float: set = set_step ##Tween step.
var transition: Tween.TransitionType ##[enum Tween.TransitionType].
var ease: Tween.EaseType ##[enum Tween.EaseType].

var is_playing: bool = true ##If this tween is playing.

##When set and this node is not processing, this tween will also not progress until the node is processed again.
var bind_node: Node: set = set_bind_node
var _is_binded: bool = false
var running: bool

signal finished ##Called when the tween finishes.
func set_step(s: float) -> void:
	step = s
	if !is_playing: return
	_update()
	if step < duration: return
	step = duration
	is_playing = false
	finished.emit()

@abstract func _update() #Used in another Tweeners
func stop() -> void: is_playing = false; step = 0.0
func pause() -> void: is_playing = false
func set_bind_node(node: Node): 
	bind_node = node
	_is_binded = !!node

func _process(delta: float) -> void:
	if _is_binded and !bind_node: stop(); return
	if is_playing and (!_is_binded or bind_node.is_inside_tree() and bind_node.can_process()): 
		step += delta
