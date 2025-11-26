extends Node
const Sparrow = preload("res://source/general/animation/Sparrow.gd")
const Atlas = preload("res://source/general/animation/Atlas.gd")
const Map = preload("res://source/general/animation/Map.gd")

const AnimationController = preload("res://source/general/animation/AnimationController.gd")
const formats: PackedStringArray = ['xml','json','txt']

##Will store the created animations, containing the name and an array with its frames
static var animations_loaded: Dictionary[StringName,Array] = {}
static var _anims_created: Dictionary = {}
static var _anims_file_founded: Dictionary[String,String] = {}

const animation_formats: PackedStringArray = ['.xml','.txt','.json']

static func getPrefixList(file: String) -> Dictionary[StringName,Array]:
	match file.get_extension():
		'xml': return Sparrow.loadSparrow(file)
		'txt': return Atlas.loadAtlas(file)
		'json': return Map.loadMap(file)
		_: return {}

##Get the Animation data using the prefix. [br][br]
##It will return the data and the [Animation] in [[Array][[Rect2]],[Animation]]
static func getAnimFrames(prefix: StringName,file: String = '') -> Array[Dictionary]:
	if !file or !prefix: return []
	
	var data = _anims_created.get_or_add(file,{}).get(prefix)
	if data: return data
	
	data = Array([],TYPE_DICTIONARY,'',null)
	var fileFounded: Dictionary[StringName,Array] = getPrefixList(file)
	if !fileFounded: return []
	
	if fileFounded.has(prefix): return fileFounded[prefix]
	
	var prefix_str = String(prefix)
	for anims in fileFounded: 
		if (anims+'0000').begins_with(prefix_str): data.append_array(fileFounded[anims])
	_anims_created[file][prefix] = data
	return data


static func getAnimFramesIndices(prefix: String, file: String, indices: PackedInt32Array = []) -> Array:
	var tracks: Array = getAnimFrames(prefix,file)
	if !tracks: return tracks
	
	var frames: Array
	var max_frames = tracks.size()
	var indices_length = indices.size()
	var i = 0
	while i < indices_length:
		var ind = indices[i];
		if ind >= 0 and ind < max_frames: frames.append(tracks[ind])
		i += 1
	return frames

static func findAnimFile(tex: String):
	if _anims_file_founded.has(tex): return _anims_file_founded[tex]
	
	for formats in animation_formats:
		if tex.ends_with(formats): return tex
		var file = tex+formats
		if FileAccess.file_exists(file): 
			_anims_file_founded[tex] = file
			return file
	return ''

static func _clearAnims() -> void:
	Sparrow.sparrows_loaded.clear()
	Atlas.atlas_loaded.clear()
	Map.maps_created.clear()
	_anims_file_founded.clear()
	_anims_created.clear()
