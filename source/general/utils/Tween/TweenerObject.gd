extends "res://source/general/utils/Tween/Tweener.gd"

##Properties that will be tweened. 
##[br]That contains [code]{"property_name": [init_value,final_value,final_value - init_value]}[/code].
var properties: Dictionary

var object: Object  ##Object that will be tweened. Can be a [Object] or a [ShaderMaterial].


func _init(
	_object: Object, 
	_duration: float, 
	_transition: Tween.TransitionType = Tween.TRANS_LINEAR, 
	_ease: Tween.EaseType = Tween.EASE_OUT
) -> void:
	object = _object
	duration = _duration
	transition = _transition
	ease = _ease

signal updated()
func _update() -> void:
	if !object: stop(); return
	for i in properties:
		if i is NodePath: object.set_indexed(i,_get_cur_value(properties[i]))
		else: object.set(i,_get_cur_value(properties[i]))
	updated.emit()

func _get_cur_value(tween_data: Array) -> Variant:
	if step >= duration: return tween_data[1]
	return Tween.interpolate_value(
		tween_data[0],
		tween_data[2],
		step,
		duration,
		transition,
		ease,
	)

func tween_property(property: Variant, to: Variant) -> void: ##Tween the [member object] property.
	if !object: return
	var init_val: Variant
	if property is NodePath: init_val = object.get_indexed(property)
	elif property.contains(':'): property = NodePath(property); init_val = object.get_indexed(property)
	else: property = StringName(property); init_val = object.get(property);
	
	if init_val != null: properties[property] = [init_val,to,to - init_val]
