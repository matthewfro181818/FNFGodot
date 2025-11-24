class_name ArrayUtils

const EmptyArray: Array = []

const array_types: Dictionary[Variant.Type,bool] = {
	TYPE_ARRAY: true,
	TYPE_PACKED_BYTE_ARRAY: true,
	TYPE_PACKED_FLOAT32_ARRAY: true,
	TYPE_PACKED_FLOAT64_ARRAY: true,
	TYPE_PACKED_INT32_ARRAY: true,
	TYPE_PACKED_STRING_ARRAY: true,
	TYPE_PACKED_VECTOR2_ARRAY: true,
	TYPE_PACKED_VECTOR3_ARRAY: true,
	TYPE_PACKED_VECTOR4_ARRAY: true,
	TYPE_PACKED_COLOR_ARRAY: true
}
static func is_array_type(type: int):return type in array_types
static func is_array(variable: Variant) -> bool: return is_array_type(typeof(variable))
static func array_has_index(array: Array, index: int) -> bool: return index >= 0 and index < array.size()

static func set_array_index(array: Array,index: int,variable: Variant,fill: Variant = null) -> void:
	var arraySize = array.size()
	if arraySize <= index:
		array.resize(index+1)
		if fill != null: for i in range(arraySize,index+1): array[i] = fill
	array[index] = variable

static func get_array_index(array: Array, index: int, default: Variant = null) -> Variant:
	return array[index] if index >= 0 and index < array.size() else default

static func create_array_via_string(elements: StringName, type: int = TYPE_NIL, delimiter: String = ',') -> Array:
	var array = []
	if type == TYPE_NIL: for i in elements.split(delimiter): array.append(i)
	else: for i in elements.split(delimiter): array.append(type_convert(i,type))
	return array

static func sort_array_from_first_index(a,b): return a and b and a[0] < b[0]
