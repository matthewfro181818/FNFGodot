extends "Tweener.gd"
var init_val: Variant
var value: Variant
var callable: Callable

var _sub: Variant
func _init(
	_callable: Callable,
	_init_val: Variant, 
	to: Variant, 
	_duration: float, 
	_transition: Tween.TransitionType = Tween.TRANS_LINEAR, 
	_ease: Tween.EaseType = Tween.EASE_OUT
):
	callable = _callable
	init_val = _init_val
	value = to
	_sub = value-init_val
	duration = _duration
	transition = _transition
	ease = _ease


func _update() -> void:
	if !callable.get_object(): stop(); return
	if step >= duration: callable.call(value); return
	callable.call(Tween.interpolate_value(init_val,_sub,step,duration,transition,ease))
