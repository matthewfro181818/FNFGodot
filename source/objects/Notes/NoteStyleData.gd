static var styles_loaded: Dictionary[StringName,Dictionary]

const default_style_structure: Dictionary[StringName,Dictionary] = {
	&'notes': {},
	&'holdNotes': {},
	&'strums': {}
}
const default_style_type_structure: Dictionary[StringName,Variant] = {
	&'assetPath': '',
	&'fps': 24.0,
	&'scale': 0.7,
	&'offsets': [0,0],
	&'data': {},
	&'isPixel': false
}

const default_splash_style_type_structure: Dictionary[StringName,Variant] = {
	&'assetPath': '',
	&'fps': 24.0,
	&'scale': 1.0,
	&'offsets': [100,100],
	&'data': {},
	&'isPixel': false
}
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
	if !json: return json
	return json.get(prefix,{})

#region Notes Data
static func _load_style(style: StringName) -> Dictionary:
	var json = styles_loaded.get(style)
	if json: return json
	json = Paths.loadJson('data/notestyles/'+style)
	if !json: return {}
	DictionaryUtils.convertKeysToStringNames(json,true)
	for i in json: _fix_animation_data(json[i])
	styles_loaded[style] = json
	return json

static func _fix_animation_data(style_data: Dictionary) -> void:
	style_data.merge(default_style_type_structure,false)
	for i in style_data.data.values(): _check_animation_data(i,style_data)
#endregion

#region Splash Data
static func _load_splash_style(style: StringName):
	var json = styles_loaded.get(style)
	if json: return json
	
	json = Paths.loadJson('data/splashstyles/'+style)
	if !json: return json
	
	DictionaryUtils.convertKeysToStringNames(json,true)
	if json.has(&'noteSplash'): _fix_splash_animation_data(json.noteSplash)
	if json.has(&'holdNoteCover'): _fix_splash_animation_data(json.holdNoteCover,true)
	
	styles_loaded[style] = json
	return json

static func _fix_splash_animation_data(style_data: Dictionary, hold_splash: bool = false) -> void:
	style_data.merge(default_splash_style_type_structure,false)
	if !hold_splash:
		for i in style_data.data.values(): 
			if i is Array: for d in i: _check_animation_data(d,style_data)
			else: _check_animation_data(i,style_data)
		return
	
	for i in style_data.data.values():
		if i.has(&'start'): _check_animation_data(i.start,style_data)
		if i.has(&'hold'): _check_animation_data(i.hold,style_data)
		if i.has(&'end'): _check_animation_data(i.end,style_data)
		
#endregion


static func _check_animation_data(data: Dictionary, style_data: Dictionary) -> void:
	if !data.has(&'scale'): data.scale = style_data.scale
	if !data.has(&'offsets'): data.offsets = style_data.offsets
	if !data.has(&'fps'): data.fps = style_data.fps
	if !data.has(&'assetPath'): data.assetPath = style_data.assetPath
	data.prefix = &'' if !data.has(&'prefix') else StringName(data.prefix)
