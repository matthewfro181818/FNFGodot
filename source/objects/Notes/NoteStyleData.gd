static var styles_loaded: Dictionary[StringName,Dictionary]

const DEFAULT_NOTES_SCALE: float = 0.7


enum StyleType{
	NOTES,
	SPLASH
}

static func getStyleData(style: StringName, splash_name: StringName = &'strums', type: StyleType = StyleType.NOTES) -> Dictionary: 
	var json: Dictionary = _load_style(style,type);
	return json.get(splash_name,{}) if json else {}

#region Notes Data
static func _load_style(style: StringName, type: StyleType = StyleType.NOTES) -> Dictionary[StringName,Dictionary]:
	var json = styles_loaded.get(style)
	if json: return json
	match type:
		StyleType.SPLASH: json = DictUtils.getDictTyped(Paths.loadJson('data/splashstyles/'+style),TYPE_STRING_NAME,TYPE_DICTIONARY)
		_: json = DictUtils.getDictTyped(Paths.loadJson('data/notestyles/'+style),TYPE_STRING_NAME,TYPE_DICTIONARY)
	if !json: return json
	match type:
		StyleType.SPLASH:
				if json.has(&'holdNoteCover'): _fix_data(json.holdNoteCover,StyleType.SPLASH)
				if json.has(&'noteSplash'): _fix_data(json.noteSplash ,StyleType.SPLASH)
		_:
			if json.has(&'strums'): _fix_data(json.strums)
			if json.has(&'notes'): _fix_data(json.notes)
			if json.has(&'holdNote'): _fix_data(json.holdNote)
	styles_loaded[style] = json
	return json
#endregion

static func _fix_animation_data(data: Dictionary) -> void:
	if data.has(&'offsets'): data.offsets = Vector2(data.offsets[0],data.offsets[1])

static func _check_animation_data(data: Variant) -> void:
	if data is Dictionary: _fix_animation_data(data)
	elif data is Array: for i in data: _fix_animation_data(i)

static func _fix_data(data: Dictionary, style: StyleType = StyleType.NOTES) -> void:
	_fix_animation_data(data)
	match style:
		StyleType.SPLASH:
			for i in data.data.values():
				if i.has(&'start'): _check_animation_data(i.start)
				if i.has(&'hold'): _check_animation_data(i.hold)
				if i.has(&'end'): _check_animation_data(i.end)
		_: for i in data.data.values(): _check_animation_data(i)
		
