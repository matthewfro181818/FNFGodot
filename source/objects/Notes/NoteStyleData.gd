static var styles_loaded: Dictionary[StringName,Dictionary]

const DEFAULT_NOTES_SCALE: float = 0.7


enum StyleType{
	NOTES,
	HOLD_NOTES,
	STRUM,
	HOLD_SPLASH,
	SPLASH
}

static func getStyleData(style: StringName, type: StyleType = StyleType.NOTES) -> Dictionary: 
	var prefix: StringName
	var json: Dictionary
	match type:
		StyleType.HOLD_NOTES: json = _load_style(style); prefix = &'holdNote'
		StyleType.STRUM: json = _load_style(style); prefix = &'strums'
		StyleType.SPLASH: json = _load_splash_style(style); prefix = &'noteSplash'
		StyleType.HOLD_SPLASH: json = _load_splash_style(style); prefix = &'holdNoteCover'
		_: json = _load_style(style); prefix = &'notes'
	return json.get(prefix,{}) if json else {}

#region Notes Data
static func _load_style(style: StringName) -> Dictionary:
	var json = styles_loaded.get(style)
	if json: return json
	json = Paths.loadJson('data/notestyles/'+style)
	if !json: return {}
	DictionaryUtils.convertKeysToStringNames(json,true)
	if json.has(&'strums'): _fix_data(json.strums,StyleType.STRUM)
	if json.has(&'notes'): _fix_data(json.notes,StyleType.NOTES)
	if json.has(&'holdNote'): _fix_data(json.holdNote,StyleType.HOLD_NOTES)
	styles_loaded[style] = json
	return json
#endregion

#region Splash Data
static func _load_splash_style(style: StringName):
	var json = styles_loaded.get(style)
	if json: return json
	
	json = Paths.loadJson('data/splashstyles/'+style)
	if !json: return json
	
	DictionaryUtils.convertKeysToStringNames(json,true)
	
	if json.has(&'holdNoteCover'): _fix_data(json.holdNoteCover,StyleType.HOLD_SPLASH)
	if json.has(&'noteSplash'): _fix_data(json.noteSplash ,StyleType.SPLASH)
	styles_loaded[style] = json
	return json
#endregion

static func _fix_animation_data(data: Dictionary):
	if data.has(&'offsets'): data.offsets = Vector2(data.offsets[0],data.offsets[1])
static func _check_animation_data(data: Variant):
	if data is Dictionary: _fix_animation_data(data)
	elif data is Array: for i in data: _fix_animation_data(i)

static func _fix_data(data: Dictionary, style: StyleType = StyleType.HOLD_SPLASH):
	_fix_animation_data(data)
	match style:
		StyleType.HOLD_SPLASH:
			for i in data.data.values():
				if i.has(&'start'): _check_animation_data(i.start)
				if i.has(&'hold'): _check_animation_data(i.hold)
				if i.has(&'end'): _check_animation_data(i.end)
		_: for i in data.data.values(): _check_animation_data(i)
		
