@tool
extends Node
const TweenerMethod = preload("uid://buyyxjslew1n1")
const TweenerObject = preload("uid://b3wombi1g7mtv")
const transitions = {
	'sine': Tween.TRANS_SINE,
	'quint': Tween.TRANS_QUINT,
	'quart': Tween.TRANS_QUART,
	'quad': Tween.TRANS_QUAD,
	'expo': Tween.TRANS_EXPO,
	'elastic': Tween.TRANS_ELASTIC,
	'cubic': Tween.TRANS_CUBIC,
	'circ': Tween.TRANS_CIRC,
	'bounce': Tween.TRANS_BOUNCE,
	'cube': Tween.TRANS_CUBIC,
	'back': Tween.TRANS_BACK,
	'spring': Tween.TRANS_SPRING,
	'smoothstep': Tween.TRANS_SINE,
	'linear': Tween.TRANS_LINEAR
}
const easings = {
	'in': Tween.EASE_IN,
	'out': Tween.EASE_OUT,
	'inout': Tween.EASE_IN_OUT,
	'outin': Tween.EASE_OUT_IN
}

static func detect_trans(trans: String, default: Tween.TransitionType = Tween.TRANS_LINEAR) -> Tween.TransitionType:
	trans = trans.to_lower()
	for keys in transitions:
		if trans.begins_with(keys): return transitions[keys]
	return default

static func detect_ease(easing: String, default: Tween.EaseType = Tween.EASE_OUT) -> Tween.EaseType:
	easing = easing.to_lower()
	for tweenEase in easings: if easing.ends_with(tweenEase):return easings[tweenEase]
	return default

var tweens_to_update: Array[RefCounted]
#region Shader Functions
func tween_shader(shader_material: ShaderMaterial, parameter: StringName, value: Variant, time: float, easing: StringName = &'') -> TweenerMethod:
	if !shader_material: return
	
	var init_val = shader_material.get_shader_parameter(parameter)
	var tween: TweenerMethod = TweenerMethod.new(
		func(val): 
			shader_material.set_shader_parameter(parameter,val),
		init_val,value,time,detect_trans(easing),detect_ease(easing)
	)
	tweens_to_update.append(tween)
	return tween
#endregion
	
func createTween(object: Object,properties: Dictionary, time: float = 1.0, easing: String = &'') -> TweenerObject:
	if !object: return null
	var new_tween = TweenerObject.new(object,time,detect_trans(easing),detect_ease(easing))
	for property in properties: new_tween.tween_property(property,properties[property])
	tweens_to_update.append(new_tween)
	return new_tween


func createTweenMethod(method: Callable, from: Variant, to: Variant, time: float = 1.0, ease: String = &'') -> TweenerMethod:
	var tween_method = TweenerMethod.new(method,from,to,time,detect_trans(ease),detect_ease(ease))
	tweens_to_update.append(tween_method)
	return tween_method

func _process(delta: float) -> void:
	if !tweens_to_update: return
	var index = tweens_to_update.size()
	while index:
		index -= 1
		var tween = tweens_to_update[index]
		if !tween.is_playing: tweens_to_update.remove_at(index); continue
		tween._process(delta)
		
		
