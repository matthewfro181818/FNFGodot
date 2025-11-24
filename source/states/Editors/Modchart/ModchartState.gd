const KeyInterpolator = preload("res://source/states/Editors/Modchart/Keys/KeyInterpolator.gd")
const EditorShader = preload("res://source/states/Editors/Modchart/Shaders/EditorShader.gd")
##Keys to Update:
##Must be like that:
##[codeblock]{"camGame":{
##"x": [
##      [time,value,time,Tween.TransType,Tween.EasingType]
##],
##"y": [
##   [50000,5,time,Tween.TRANS_CUBIC,Tween.Ease_OUT],
##   [55000,0,time,Tween.TRANS_CUBIC,Tween.Ease_OUT]
##}
##[/codeblock]
enum KEY_TYPE{
	SHADER,
	OBJECT,
	MEDIA
}
const BaseData = {
	'keys': [[0.0,1.0,1.0,&'','out']], #[time,final_val,duration,transition,easing,init_val]
	'type': TYPE_NIL,
	'index': 0
}
static var keys: Dictionary[String,Dictionary] = {
	'shaders': {},
	'objects': {},
	'media': {},
	'audios': {}
}

static var keys_index: Dictionary[String,Dictionary] = {
	'shaders': {}
}

static func process_keys(back: bool = false):
	_process_media_keys(back)
	_process_shader_keys(back)
	_process_object_keys(back)
static func _process_object_keys(back: bool) -> void:
	var obj_keys = keys.objects
	if !obj_keys: return
	for i in obj_keys.values(): for prop in i.properties: _update_keys_data(prop,back)

static func _process_media_keys(back: bool) -> void:
	var media = keys.media
	if !media: return
	for i in keys.media.values(): for prop in i.properties: _update_keys_data(prop,back)

static func _process_shader_keys(back: bool = false) -> void:
	var shaders = keys.shaders
	if !shaders: return
	for i in shaders.values(): for prop in i.properties: _update_keys_data(prop,back)

static func _update_keys_data(key_data: Dictionary, backward: bool) -> int:
	var _keys: Array = key_data.keys
	if !_keys: return 0
	var key_index: int = key_data.index
	var keys_size = _keys.size()
	var keys_length = keys_size-1
	if backward:
		while true:
			if key_index >= keys_size: key_index = keys_length
			var key = _keys[key_index]
			update_key(key)
			if !key_index or Conductor.songPosition > key.time: break
			key_index -= 1
		
	else:
		while key_index < keys_size:
			var key = _keys[key_index]
			update_key(key)
			if Conductor.songPosition < key.length: break
			key_index += 1
	key_data.index = key_index
	return key_index

##Data = [time,init_val,value,duration,transition,easing]
static func _get_key_value(key: KeyInterpolator):
	if Conductor.songPosition >= key.length: return key.value
	elif Conductor.songPosition < key.time: return key.prev_val
	return Tween.interpolate_value(
		key.init_val,
		key.value - key.init_val,
		Conductor.songPosition - key.time,
		key.duration,
		key.transition,
		key.ease
	)

static func update_key(key: KeyInterpolator):
	var value: Variant = _get_key_value(key)
	var obj: Object = key.object
	if !obj: obj = FunkinGD.Reflect._find_object(key.object_name); if !obj: return
	obj.set(key.property,value)
	
static func update_key_material(key: KeyInterpolator):
	var value: Variant = _get_key_value(key)
	var obj: ShaderMaterial = key.object
	if !obj: obj = FunkinGD.Reflect._find_object(key.object_name); if !obj: return
	obj.set_shader_parameter(key.property,value)

static func setObjectValue(obj: Variant, prop: String, value: Variant):
	if !obj: return
	if obj is ShaderMaterial: obj.set_shader_parameter(prop,value)
	else: obj.set(prop,value)

static func getObjectValue(obj: Variant, prop: String) -> Variant:
	if obj is String: obj = FunkinGD.Reflect._find_object(obj)
	if !obj: return
	if obj is ShaderMaterial: return obj.get_shader_parameter(prop)
	return obj.get(prop)
	
static func loadFromData(data: Dictionary):pass

static func get_keys_data() -> Dictionary:
	#var new_data = {}
	return keys

static func addMedia(obj: Object, tag: String):
	keys.media[tag] = {
		'object': obj,
		'properties': {},
	}

static func addObject(obj: Object, tag: String):
	keys.object[tag] = {
		'object': obj,
		'properties': {},
	}

static func addMaterial(material: ShaderMaterial, tag: String):
	keys.shader[tag] = {
		'object': material,
		'properties': {}
	}

static func createProperty(obj_data: Dictionary, property: String, property_data: Dictionary):
	obj_data[property] = {
		'keys': [],
		'index': 0,
		'default': property_data.default,
		'type': property_data.type
	}
static func removeObject(obj_name: String):
	keys.erase(obj_name)
	keys_index.erase(obj_name)
	
static func removeProperty(obj_name: String, prop: String): pass
static func clear():
	for i in keys.values(): i.clear()
	keys_index.clear()
