class_name DictUtils

const EmptyDict: Dictionary = {}
static func merge_existing(dic: Dictionary, to: Dictionary) -> Dictionary:
	for i in dic:
		if to.has(i):
			dic[i] = to[i]
	return dic

static func front(dic: Dictionary): ##Retruns the first element from [param dic].
	if !dic:
		return null
	return dic[dic.keys().front()]

static func back(dic: Dictionary) -> Variant: ##Retruns the last element from [param dic].
	if !dic:
		return null
	return dic[dic.keys().back()]

static func rename_key(dic: Dictionary, key: Variant, new_key: Variant):
	if !dic.has(key): return
	dic[new_key] = dic[key]
	dic.erase(key)

static func convertKeysToStringNames(dict: Dictionary, recursive: bool = false) -> void:
	for i in dict.keys():
		var val = dict[i]
		var key = i
		if recursive and val is Dictionary: convertKeysToStringNames(val,true)
		
		if key is String:
			key = StringName(key)
			dict.erase(i)
			dict[key] = val

static func getDictTyped(dict: Dictionary, key_type: Variant.Type = TYPE_NIL, value_type: Variant.Type = TYPE_NIL) -> Dictionary:
	return Dictionary(
		dict,
		key_type,&'',null,
		value_type,&'',null
	)
