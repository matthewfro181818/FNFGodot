extends Node
const Note = preload("uid://deen57blmmd13")
const NoteSplash = preload("uid://cct1klvoc2ebg")

static var splashes_loaded: Dictionary
static func createSplashFromNote(note: Note):
	var splash: NoteSplash = _check_splash_from_note(note)
	if !splash: return _create_splash_from_note(note);
	splash.show_splash(); return splash

static func _create_splash_from_note(note: Note) -> NoteSplash:
	if !note: return
	var splash = NoteSplash.loadSplashFromNote(note); if !splash: return
	splash.strum = note.strumNote
	_get_splash_storage(note.splashStyle,note.splashName,note.splashPrefix).append(splash)
	return splash

static func _get_splash_storage(style: StringName, name: StringName, prefix: StringName) -> Array:
	return splashes_loaded.get_or_add(style,{}).get_or_add(name,{}).get_or_add(prefix,[])

static func _check_splash_from_note(note: Note) -> NoteSplash:
	return _check_splash(note.splashStyle,note.splashName,note.splashPrefix)

static func _check_splash(style: StringName, splash_name: StringName, prefix: StringName) -> NoteSplash:
	var storage = _get_splash_storage(style,splash_name,prefix)
	var length = storage.size()
	var i: int = 0
	while i < length:
		var s = storage[i]
		if !s.visible: return s
		i += 1
	return
