const FunkinInternal = preload("uid://dvv6d7h41yro4")
const alternative_variables: Dictionary = {
	'angle': 'rotation_degrees',
	'color': 'modulate',
	'origin': 'pivot_offset'
}
const property_replaces: Dictionary = {
	'[': '.',
	']': ''
}

#region Setter Methods
static func setProperty(property: String, value: Variant, target: Variant):
	var split: PackedStringArray
	if !target:
		var obj_find = _find_object_with_split(property)
		target = obj_find[0]
		if !target: FunkinInternal._show_property_no_found_error(property); return
		split = obj_find[1]
	
	else: split = property.split('.')
	
	if !split: return
	
	var value_to_set: String = split[split.size()-1]
	var _property: String
	var _prev_target: Variant
	var size: int = split.size()-1
	
	
	if size:
		var i: int = 0
		while i < size:
			_property = split[i]
			if MathUtils.value_exists(target,_property):
				_prev_target = target
				target = target[_property]
				i += 1
				continue
			FunkinInternal.show_funkin_warning(
				'Error on setting property: '+str(_property)+" not founded in "+str(target)
			)
			return
	var type = typeof(target)
	if VectorUtils.is_vector_type(type): _prev_target[_property][value_to_set] = value; return
	if ArrayUtils.is_array_type(type): target.set(int(value_to_set),value); return
	target.set(value_to_set,value)


#endregion

#region Getter Methods
static func getProperty(property: String, from: Variant = null) -> Variant: ##Get a Property from the game.
	var split: PackedStringArray
	if from == null:
		from = _find_object_with_split(property)
		if !from[0]: return null
		split = from[1]
		from = from[0]
	else: split = property.split('.')
	
	var index: int = 0
	var size = split.size()
	
	while index < size:
		from = _get_variable(from,split[index]); 
		if from == null: return from
		index += 1
	return from
#endregion


const source_dirs: PackedStringArray = [
	'res://source/',
	'res://source/backend',
	'res://source/states',
	'res://source/substates'
]
static func _find_class(object: String) -> Object:
	if Engine.has_singleton(object): return Engine.get_singleton(object)
	
	var tree = Global.get_tree().root
	if tree.has_node(object): return tree.get_node(object)
	object = object.replace('.','/')
	if not object.ends_with('.gd'): object += '.gd'
	
	for i in source_dirs: var path = i+object; if FileAccess.file_exists(path): return load(path)
	return null

static func _find_object(property: Variant) -> Object:
	if property is Object: return property
	var split = _get_as_property(property).split('.')
	var key = split[0]
	var object = _find_property_owner(key)
	
	var index: int = 0
	while index < split.size():
		var variable = _get_variable(object,split[index])
		if variable == null: return null
		elif !is_indexable(variable): break
		object = variable
		index += 1
	return object

static func _get_variable(obj: Variant, variable: String) -> Variant:
	var type = typeof(obj)
	if ArrayUtils.is_array_type(type): return obj.get(int(variable))
	
	if VectorUtils.is_vector_type(type):
		if variable.is_valid_int(): return obj[int(variable)]
		return obj[variable]
	
	match type:
		TYPE_DICTIONARY: return obj.get(variable)
		TYPE_OBJECT: 
			var value = obj.get(variable)
			if value == null and variable.find(':'): value = obj.get_indexed(variable)
			if value == null and variable in alternative_variables: return _get_variable(obj,alternative_variables[variable])
			return value
		TYPE_COLOR: return obj[variable]
		_: return null

static func _find_object_with_split(property: Variant) -> Array:
	if property is Object: return property
	var split = _get_as_property(property).split('.')
	var key = split[0]
	var object = _find_property_owner(key)
	var size: int = split.size()
	var index: int = 0
	while index < size:
		var variable = _get_variable(object,split[index])
		if variable == null: return [null, split]
		elif !is_indexable(variable): break
		object = variable
		index += 1
	return [object,split.slice(index)]

static func _find_property_owner(property: StringName) -> Variant:
	if FunkinInternal.game and property in FunkinInternal.game: return FunkinInternal.game
	for i in FunkinInternal.dictionariesToCheck: if i.has(property): return i
	return null

static func _get_as_property(property: String) -> String:
	return StringUtils.replace_chars_from_dict(property,property_replaces)

static func is_indexable(variable: Variant) -> bool:
	if !variable: return false
	var type = typeof(variable)
	
	if ArrayUtils.is_array_type(type):return true
	match type:
		TYPE_OBJECT,TYPE_DICTIONARY: return true
		_: return false
