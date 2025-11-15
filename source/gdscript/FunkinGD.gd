class_name FunkinGD extends Object

const TweenerObject = preload("uid://b3wombi1g7mtv")
const TweenerMethod = preload("uid://buyyxjslew1n1")
const ModulateAlpha = NodePath('modulate:a') #Used in doTweenAlpha

const Song = preload("uid://cerxbopol4l1g")
const Bar = preload("uid://cesg7bsxvgdcm")

const EventNoteUtils = preload("uid://dqymf0mowy0dt")
const Note = preload("uid://deen57blmmd13")
const NoteHit = preload("uid://dx85xmyb5icvh")
const StrumNote = preload("uid://coipwnceltckt")

const Stage = preload("uid://dh7syegxufdht")

const PlayStateBase = preload("uid://dgnunksqrmpbr")

const Character = preload("uid://gou2lt74gx0i")
const Icon = preload("uid://bgqwitowtypkw")

const Graphic = preload("uid://bgqwitowtypkw")

const source_dirs: PackedStringArray = [
	'res://source/',
	'res://source/backend',
	'res://source/states',
	'res://source/substates'
]


static var debugMode: bool = Engine.is_editor_hint()

#region Public Vars
@export_category('Class Vars')
static var started: bool

static var Function_Continue: int
static var Function_Stop: int = 1


static var isStoryMode: bool
static var game: Object
static var camGame:
	get(): return game.camGame
		
static var camHUD:
	get(): return game.camHUD
		
static var camOther:
	get(): return game.camOther

static var botPlay: bool:
	get(): return game.botplay

##The path of the script.
var scriptPath: StringName

##The Mod Folder of the script.
var scriptMod: String 


@export_category("Files Saved")

static var dictionariesToCheck = [modVars,spritesCreated,shadersCreated,textsCreated,groupsCreated]

##[b]Variables[/b] created using [method setVar] and [method createCamera] methods.
static var modVars: Dictionary[String,Variant]

##Sprites created using [method makeSprite] or [method makeAnimatedSprite] methods.
static var spritesCreated: Dictionary[StringName,Node]

##Sprite groups created using [method createSpriteGroup] method.
static var groupsCreated: Dictionary[String,SpriteGroup]

##[b][Tween][/b] created using [method startTween] function.
static var tweensCreated: Dictionary[StringName,RefCounted]

##[b]Shaders[/b] created using [method initShader] function.
static var shadersCreated: Dictionary[StringName,ShaderMaterial]

##[b]Sounds[/b] created using [method playSound] function.
static var soundsPlaying: Dictionary[String,AudioStreamPlayer]

##[b]Timers[/b] created using [method runTimer] function.
static var timersPlaying: Dictionary[String,Array]

##Scripts created using [method addScript] function.
static var scriptsCreated: Dictionary

##[b]Texts[/b] created using [method makeText] function.
static var textsCreated: Dictionary[String,Label]

##Used to precache the Methods in the script, being more optimized for calling functions in [method callOnScripts]
static var method_list: Dictionary[StringName,Array]

@export_group('Game Data')
static var playAsOpponent:
	get(): return game.playAsOpponent
		
static var lowQuality: bool: ##low quality.
	get(): return ClientPrefs.data.lowQuality

static var screenWidth: float: ##The Width of the Screen.
	get(): return ScreenUtils.screenWidth
		
static var screenHeight: float: ##The Height of the Screen.
	get(): return ScreenUtils.screenHeight

static var screenSize: Vector2i: ##The Size of the Screen.
	get(): return ScreenUtils.screenSize


static var inCutscene: bool:
	get(): return game.inCutscene

static var seenCutscene: bool: ##See [member PlayStateBase.seenCustscene].
	get(): return game.seenCutscene

static var inGameOver: bool = false

@export_category("Song Data")
static var curStage: String

static var songName: String: ##song name.
	get(): return Song.songName

static var songStarted: bool:
	get(): return !!Conductor.songs

static var songLength: float:
	get(): return game._songLength
	
static var difficulty: String: 
	get(): return Song.difficulty

static var mustHitSection: bool ##If the section is bf focus

static var gfSection: bool ##GF Section Focus

static var altAnim: bool ##Alt Section Animation

#region Conductor Properties
static var bpm: float
static var crochet: float
static var stepCrochet: float

static var curBeat: int
static var curStep: int

static var curSection: int
static var keyCount: int = Song.keyCount
#endregion

@export_category("Client Prefs")
#Scroll
static var middlescroll: bool
static var downscroll: bool
static var hideHud: bool

#TimeBar
static var hideTimeBar: bool
static var timeBarType: String

static var shadersEnabled: bool:
	get(): return ClientPrefs.data.shadersEnabled

static var version: String = '1.0' ##Engine Version

static var cameraZoomOnBeat: bool = true

static var flashingLights: bool:
	get(): return ClientPrefs.data.flashingLights

static var framerate: float = 60.0

static var arguments: Dictionary[int,Dictionary] = {}
#endregion



#region Signals
static var Conductor_Signals: Dictionary[String,Callable] = {
	'section_hit': _section_hit,
	'section_hit_once': callOnScripts.bind(&'onSectionHitOnce'),
	'beat_hit': _beat_hit,
	'step_hit': _step_hit,
	'bpm_changes': _bpm_changes
}

static func init_gd():
	if started or !Conductor: return
	started = true
	for i in Conductor_Signals: Conductor[i].connect(Conductor_Signals[i])
	debugMode = OS.is_debug_build()
	_bpm_changes()

static func _bpm_changes() -> void:
	bpm = Conductor.bpm
	stepCrochet = Conductor.stepCrochet
	crochet = Conductor.crochet
	
static func _beat_hit() -> void: curBeat = Conductor.beat; callOnScripts(&'onBeatHit')
static func _step_hit() -> void: curStep = Conductor.step; callOnScripts(&'onStepHit')
static func _section_hit() -> void: curSection = Conductor.section;callOnScripts(&'onSectionHit')
#endregion

static func get_arguments(script: Object) -> Dictionary[StringName,Variant]:
	var functions: Dictionary[StringName,Variant] = {}
	for function in script.get_script().get_script_method_list():
		if function.flags == 33: continue
		
		var funcArgs = function.args
		if !funcArgs: functions[function.name] = null; continue
		
		var index: int
		index = funcArgs.size()-1
		for i in function.default_args: funcArgs[index].default = i; index -= 1
		
		functions[function.name] = funcArgs
	return functions
	
#region File Methods
 ##Similar to [method Paths.file_exists].
static func checkFileExists(path: String) -> bool: return Paths.file_exists(path)
static func precacheImage(path: String) -> Image: return Paths.image(path) ##Precache a image, similar to [method Paths.image]
static func precacheMusic(path: String) -> AudioStreamOggVorbis: return Paths.music(path) ##Precache a music, similar to [method Paths.music]
static func precacheSound(path: String) -> AudioStreamOggVorbis: return Paths.sound(path) ##Precache a sound, similiar to [method Paths.sound]
static func precacheVideo(path: String) -> VideoStreamTheora: return Paths.video(path) ##Precache a video file.
	
static func addCharacterToList(character: String, type: Variant = 'bf') -> void: ##Precache character.
	if not (Paths.character(character) and game): return
	if type is int: game.addCharacterToList(type,character); return
	match type:
		'bf','boyfriend': game.addCharacterToList(0,character)
		'dad':game.addCharacterToList(1,character)
		'gf':game.addCharacterToList(2,character)

static func _clear_scripts(absolute: bool = false):
	if absolute:
		for i in spritesCreated.values(): if i: i.queue_free()
		for i in modVars.values(): if i is Node: i.queue_free()
		for i in timersPlaying.values(): if i: i[0].stop()
		for i in tweensCreated.values(): if i: i.stop()
		for i in groupsCreated.values(): i.queue_free()
		
	soundsPlaying.clear()
	method_list.clear()
	shadersCreated.clear()
	scriptsCreated.clear()
	shadersCreated.clear()
	modVars.clear()
	spritesCreated.clear()
	groupsCreated.clear()
	timersPlaying.clear()
	tweensCreated.clear()
	
	if !started: return
	started = false
	debugMode = false
	for i in Conductor_Signals: Conductor[i].disconnect(Conductor_Signals[i])
	
#endregion


#region Property methods
const alternative_variables: Dictionary = {
	'angle': 'rotation_degrees',
	'color': 'modulate',
	'origin': 'pivot_offset'
}

##Set a property. 
##If [param target] is defined, the function will try to set its [param variable].
const property_replaces: Dictionary = {
	'[': '.',
	']': ''
}

static func _show_property_no_found_error(property: String) -> void:
	var split = property.split('.')
	var obj_name = split[0]
	if split.size() > 1:
		show_funkin_warning('Error on setting property "'+property.right(-obj_name.length()-1)+'": '+obj_name+" not founded")
	else:
		show_funkin_warning('Error on setting property: '+obj_name+" not founded")
	return

##Set a Property. If [param target] set, the function will try to set the property from this object.
static func setProperty(property: String, value: Variant, target: Variant = null) -> void:
	var split: PackedStringArray
	if !target:
		var obj_find = _find_object_with_split(property)
		if !obj_find[0]: _show_property_no_found_error(property); return
		split = obj_find[1]
		target = obj_find[0]
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
			show_funkin_warning('Error on setting property: '+str(_property)+" not founded in "+str(target))
			return
	var type = typeof(target)
	if VectorUtils.is_vector_type(type): _prev_target[_property][value_to_set] = value; return
	if ArrayUtils.is_array_type(type): target.set(int(value_to_set),value); return
	target.set(value_to_set,value)

static func setVar(variable: Variant, value: Variant = null) -> void: modVars[variable] = value ##Set/Add a variable to [member modVars].

static func getVar(variable: Variant) -> Variant: return modVars.get(variable) ##Get a variable from the [member modVars].

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

static func _find_property_owner(property: StringName) -> Variant:
	if game and property in game: return game
	for i in dictionariesToCheck: if i.has(property): return i
	return null
	
static func _find_object(property: Variant) -> Object:
	if property is Object: return property
	var split = get_as_property(property).split('.')
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

static func _find_object_with_split(property: Variant) -> Array:
	if property is Object: return property
	var split = get_as_property(property).split('.')
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
static func get_as_property(property: String) -> String:
	return StringUtils.replace_chars_from_dict(property,property_replaces)


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

static func is_indexable(variable: Variant) -> bool:
	if !variable: return false
	var type = typeof(variable)
	
	if ArrayUtils.is_array_type(type):return true
	match type:
		TYPE_OBJECT,TYPE_DICTIONARY: return true
		_: return false
#endregion


#region Class Methods
static func _find_class(object: String) -> Object:
	if Engine.has_singleton(object): return Engine.get_singleton(object)
	
	var tree = Global.get_tree().root
	if tree.has_node(object): return tree.get_node(object)
	

	object = object.replace('.','/')
	if not object.ends_with('.gd'): object += '.gd'
	
	for i in source_dirs:
		var path = i+object
		if FileAccess.file_exists(path): return load(path)
	return null
	
static func getPropertyFromClass(_class: String, variable: String):
	var class_obj = _find_class(_class)
	if !class_obj:return
	return getProperty(variable,class_obj)
	
static func setPropertyFromClass(_class: String,variable: String,value: Variant) -> void:##Set the variable of the [code]_class[/code]
	var class_obj = _find_class(_class)
	if !class_obj:return
	setProperty(variable,value,class_obj)
#endregion


#region Group Methods
static func _find_group_members(_group_name: String, member_index: int) -> Object:
	var group = getProperty(_group_name)
	if !group: return null
	if group is SpriteGroup: group = group.members
	if !group is Array: return null
	return ArrayUtils.get_array_index(group,member_index)
	
##Add [Sprite] to a [code]group[/code] [SpriteGroup] or [Array].[br][br]
##If [code]at = -1[/code], the sprite will be inserted at the last position.
static func addSpriteToGroup(object: Variant, group: Variant, at: int = -1) -> void:
	object = _find_object(object)
	if !object: return
	
	if group is String: group = _find_object(group)
	if !group: return
	
	if group is SpriteGroup:
		if at != -1: group.insert(at,object)
		else: group.add(object)
		return
	
	if group is Array:
		if at != -1: group.insert(at,object)
		else: group.append(object)
	
static func removeFromGroup(group: Variant, index: int):
	if group is String: group = getProperty(group)
	if !group: return
	if group is SpriteGroup or group is Array: group.remove_at(index)

##Get a Property from a [SpriteGroup] or [Array]
static func getPropertyFromGroup(group: String, index: Variant = 0, variable: String = "") -> Variant: 
	if !variable: return _find_group_members(group,int(index))
	return getProperty(variable,_find_group_members(group,int(index)))

##Set the [code]variable[/code] of the object at the [code]index[/code] from a [SpriteGroup] or [Array]
static func setPropertyFromGroup(group: String, index: Variant, variable: String, value: Variant) -> void:
	var obj = _find_group_members(group,int(index))
	if !obj:
		return
	setProperty(variable,value,obj)
#endregion


#region Timer Methods
##Runs a timer, return the [Timer] created.
static func runTimer(tag: String, time: float, loops: int = 1) -> Timer:
	if !time: 
		while loops >= 1:
			loops -= 1
			callOnScripts(&'onTimerCompleted',[tag,loops])
		return
	
	var timer: Timer
	var data: Array
	if timersPlaying.get(tag):
		data = timersPlaying[tag]
		timer = data[0]
	else:
		timer = Timer.new()
		
		(game if game else Global).add_child(timer)
		
		data = [timer,loops]
		timer.timeout.connect(func():
			if data[1] > 1:
				timer.start(time)
				data[1] -= 1
			else:
				timersPlaying.erase(tag)
				timer.queue_free()
			callOnScripts(&'onTimerCompleted',[tag,data[1]])
		)
		
		timersPlaying[tag] = data
	timer.start(time)
	
	return timer

static func getTimerLoops(tag: String) -> int:
	return timersPlaying[tag][1] if timersPlaying.has(tag) else 0
	
static func cancelTimer(tag: String): ##Cancel Timer. See also [method runTimer].
	if not tag in timersPlaying: return
	var timer: Timer = timersPlaying[tag][0]
	timer.stop()
	timersPlaying.erase(tag)
	timer.free()

#endregion


#region Random Methods
##Return a random [int], replaced by [method @GlobalScope.randi_range].
static func getRandomInt(minimum: int = 0, maximum: int = 1) -> int:
	return randi_range(minimum,maximum)

##Return a random [bool].
static func getRandomBool(chance: int = 50) -> bool:
	return randi_range(0,100) <= chance

##Return a random [float], replaced by [method @GlobalScope.randf_range].
static func getRandomFloat(minimum: float = 0.0,maximum: float = 1.0) -> float:
	return randf_range(minimum,maximum)
#endregion

#region Stage Methods
static func getSpritesFromStageJson() -> PackedStringArray:
	var stages = PackedStringArray()
	for i in Stage.json.get('props',[]): if i.get('name'): stages.append(i.name)
	return stages
#endregion

#region Sprite Methods
static func _insert_sprite(tag: StringName, object: Node) -> void: 
	var sprite = spritesCreated.get(tag)
	if sprite and sprite is Node: sprite.queue_free()
	spritesCreated[tag] = object

static func makeSprite(tag: StringName, path: Variant = null, x: float = 0, y: float = 0) -> FunkinSprite:  ##Creates a [Sprite].
	var sprite = FunkinSprite.new(false,path)
	sprite.set_position_xy(x,y)
	if tag: sprite.name = tag; _insert_sprite(tag,sprite)
	return sprite


static func makeAnimatedSprite(tag: StringName, path: Variant = null, x: float = 0, y: float = 0) -> FunkinSprite: ##Creates a animated [Sprite].
	var sprite = FunkinSprite.new(true,path)
	sprite.set_position_xy(x,y)
	if tag: sprite.name = tag; _insert_sprite(tag,sprite)
	return sprite

static func makeSpriteFromSheet(tag: String,path: Variant, sheet_preffix: String,x: float = 0, y: float = 0):
	var sprite = makeSprite(tag,path,x,y)
	return sprite
	

static func addSprite(object: Variant, front: bool = false) -> void: ##Add [Sprite] to game.
	object = _find_object(object) as Node
	if !object: return
	var cam: CameraCanvas = object.get('camera'); if !cam: cam = game.get('camGame')
	if !cam: return
	cam.add(object,front)

static func addSpriteToCamera(object: Variant, camera: Variant, front: bool = false) -> void: ##Add a [Sprite] to a [param camera].
	object = _find_object(object); if !object: return
	camera = getCamera(camera)
	if camera: camera.add(object,front)

static func insertSpriteToCamera(object: Variant, camera: Variant, at: int): ##Insert a [Sprite] to a [param camera] in a specific position.
	object = _find_object(object); if !object: return
	camera = getCamera(camera)
	if camera: camera.insert(at, object)

##Remove [Sprite] of the game. When [code]delete[/code] is true, the sprite will be remove completely.
static func removeSprite(object: Variant, delete: bool = false) -> void:
	var tag
	if object is Node: tag = object.name
	else: tag = object; object = _find_object(object)

	if !object: return
	
	if object.is_inside_tree(): object.get_parent().remove_child(object)
	if delete: spritesCreated.erase(tag)

static func createSpriteGroup(tag: String) -> SpriteGroup: ##Creates a [SpriteGroup].
	var group = SpriteGroup.new()
	if groupsCreated.has(tag): groupsCreated[tag].queue_free()
	groupsCreated[tag] = group
	return group

static func makeGraphic(object: Variant,width: float = 0.0,height: float = 0.0,color: Variant = 'FFFFFF') -> void:
	if !object: return
	if object is String: var _sprite_name = object; object = _find_object(object); if !object: object = makeSprite(_sprite_name)
	
	if object is FunkinSprite:
		if object.image is Graphic: 
			object.image._make_solid()
			object.image.modulate = _get_color(color)
			object.image.set_graphic_size(Vector2(width,height))
		elif object.image is CanvasItem: object.image.modulate = _get_color(color)
	elif object is SolidSprite:
		object.modulate = _get_color(color)
		object.scale = Vector2(width,height)
	

##Load image in the sprite.
static func loadGraphic(object: Variant, image: String, width: float = -1, height: float = -1) -> Texture:
	object = _find_object(object); if !object: return
	
	if object is FunkinSprite: object = object.image
	var tex = Paths.texture(image)
	object.texture = tex
	if not (object is FunkinSprite or object is NinePatchRect): return tex
	if width != -1: object.region_rect.size.x = width
	if height != -1: object.region_rect.size.y = height
	return tex


##Changes the image size of the sprite.[br]
##[b]Note:[/br] Just works if the sprite is not animated.
static func setGraphicSize(object: Variant, sizeX: float = -1, sizeY: float = -1) -> void:
	object = _find_object(object); if !object: return
	
	if object is FunkinSprite: object.setGraphicSize(sizeX,sizeY)
	elif object is NinePatchRect:
		object.size = Vector2(
			object.image.size.x if sizeX == -1 else sizeX,
			object.image.size.y if sizeY == -1 else sizeY
			)
##Move the [param object] to the center of his camera.[br]
##[param type] can be: [code]""xy,x,y[/code]
static func screenCenter(object: Variant, type: String = 'xy') -> void:
	object = _find_object(object); if !object: return
	
	var center = (object.get_viewport().size/2.0 if object.is_inside_tree() else ScreenUtils.screenCenter)
	if object is FunkinSprite: center -= object.image.pivot_offset
	else:
		var tex = object.get('texture')
		var size = tex.get_size() if tex else object.get('size')
		if size: center += size/2.0
	
	var obj_pos = object.call('get_position'); if !obj_pos: return
	match type:
		'x': object.set_position(center.x,obj_pos.y)
		'y': object.set_position(obj_pos.x,center.y)
		_: object.set_position(center)

##Scale object.
##If not [param centered], the sprite will scale from his top left corner.
static func scaleObject(object: Variant,x: float = 1.0,y: float = 1.0, centered: bool = false) -> void:
	object = _find_object(object); if !object: return
	object.set(&'scale',Vector2(x,y))
	if !centered and object is FunkinSprite: object.offset = object.pivot_offset*(Vector2.ONE - object.scale)

##Set the scroll factor from the sprite.[br]
##This makes the object have a depth effect, [u]the lower the value, the greater the depth[/u].
static func setScrollFactor(object: Variant, x: float = 1, y: float = 1) -> void:
	object = _find_object(object); if object: object.set(&'scrollFactor',Vector2(x,y))

##Set the order of the object in the screen.
static func setObjectOrder(object: Variant, order: int)  -> void:
	object = _find_object(object); if !object: return
	var parent = object.get_parent()
	if parent: parent.move_child(object,clamp(order,0,parent.get_child_count()))


static func getObjectOrder(object: Variant) -> int: ##Returns the object's order.
	object = _find_object(object); if !object: return 0
	return object.get_index() if object is Node else -1

static func updateHitbox(object: Variant) -> void: pass

static func updateHitboxFromGroup(group: String, index) -> void: updateHitbox(_find_group_members(group,int(index)))

##Returns if the sprite, created using [method makeSprite] or [method makeAnimatedSprite] or [method setVar], exists.
static func spriteExists(tag: StringName) -> bool:
	return spritesCreated.get(tag) is FunkinSprite or modVars.get(tag) is FunkinSprite
	

static func getMidpointX(object: Variant) -> float: ##Returns the midpoint.x of the object. See also [method getMidpointY].
	object = _find_object(object)
	if object is FunkinSprite: return object.getMidpoint().x
	if (object is CanvasItem) and object.get('texture'): return object.position.x + (object.texture.get_size().x/2.0)
	return 0.0


static func getMidpointY(object: Variant) -> float: ##Returns the midpoint.y of the object. See also [method getMidpointX].
	object = _find_object(object)
	if object is FunkinSprite: return object.getMidpoint().y
	if (object is CanvasItem) and object.get('texture'): return object.position.y + (object.texture.get_size().y/2.0)
	return 0.0
#endregion


#region Animation Methods
##Add Animation Frames for the [param object], useful if you are creating custom [Icon]s.
static func addAnimation(object: Variant, animName: StringName, frames: Array = [], frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = _find_object(object); if !object or !object.get('animation'): return {}
	return object.animation.addFrameAnim(animName,frames,frameRate,loop)
	
##Add animation to a [Sprite] using the prefix of his image.
static func addAnimationByPrefix(object: Variant, animName: StringName, xmlAnim: StringName, frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = _find_object(object); if !object or !object.get('animation'): return {}
	var frames = object.animation.addAnimByPrefix(animName,xmlAnim,frameRate,loop)
	return frames

##Add [Animation] using the preffix of the sprite, can set the frames that will be played
static func addAnimationByIndices(object: Variant, animName: StringName, xmlAnim: StringName, indices: Variant = [], frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = _find_object(object); if !object or !object.get('animation'): return {}
	return object.animation.addAnimByPrefix(animName,xmlAnim,frameRate,loop,indices)


##Makes the [param object] play a animation, if exists. If [param force] and the current anim as the same name, that anim will be restarted.
static func playAnim(object: Variant, anim: StringName, force: bool = false, reverse: bool = false) -> void:
	object = _find_object(object); if not (object is FunkinSprite and object.animation): return
	if reverse: object.animation.play_reverse(anim,force)
	else: object.animation.play(anim,force)

##Add offset for the animation of the sprite.
static func addOffset(object: Variant, anim: StringName, offsetX: float, offsetY: float)  -> void:
	object = _find_object(object); if object is FunkinSprite: object.addAnimOffset(anim,offsetX,offsetY)

#endregion


#region Text Methods
##Creates a Text
static func makeText(tag: String,text: Variant = '', width: float = 500, x: float = 0, y:float = 0) -> Label:
	var newText = Label.new()
	newText.text = str(text)
	newText.position = Vector2(x,y)
	newText.autowrap_mode = TextServer.AUTOWRAP_WORD
	newText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	newText.size.x = width
	newText.set(&"theme_override_constants/outline_size",7)
	if tag:
		removeText(tag)
		newText.name = tag
		textsCreated[tag] = newText
	return newText


##Set the text string
static func setTextString(tag: Variant, text: Variant = '') -> void:
	tag = _find_object(tag); if tag is Label: tag.text = str(text)

##Set the color from the text
static func setTextColor(text: Variant, color: Variant) -> void:
	text = _find_object(text); if text is Label: text.set(&"theme_override_colors/font_color",_get_color(color))

##Set Text Border
static func setTextBorder(text: Variant, border: float, color: Color = Color.BLACK) -> void:
	text = _find_object(text); if !text is Label: return
	text.set(&"theme_override_colors/font_outline_color",color)
	text.set(&"theme_override_constants/outline_size",border)

##Set the Font of the Text
static func setTextFont(text: Variant, font: Variant = 'vcr.ttf') -> void:
	text = _find_object(text) as Label; if !text: return
	font = _find_font(font); if !font: return
	text.set(&'theme_override_fonts/font',font)
static func getTextFont(text: Variant) -> FontFile:
	text = _find_object(text) as Label; return text.get(&"theme_override_fonts/font") if text else ThemeDB.fallback_font

static func _find_font(font: Variant) -> Font: return font if font is Font else Paths.font(font)

##Set the Text Alignment
static func setTextAlignment(tag: Variant, alignmentHorizontal: StringName = &'left', alignmentVertical: StringName = &'') -> void:
	var obj = _find_object(tag); if !obj is Label: return
	
	match alignmentHorizontal:
		&'left': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		&'center': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		&'right': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		&'fill': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	match alignmentVertical:
		&'left': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		&'center': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		&'right': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		&'fill': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	match alignmentVertical:
		&'top': obj.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		&'center': obj.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		&'bottom': obj.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		&'fill': obj.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		

##Set the font's size of the Text
static func setTextSize(text: Variant, size: float = 15) -> void:
	text = _find_object(text); if text: text.set(&"theme_override_font_sizes/font_size",size)

##Add Text to game
static func addText(text: Variant, front: bool = false) -> void:
	text = _find_object(text); if !text is Label: return
	
	var cam = text.get(&'camera')
	if !cam: cam = camHUD; if !cam: return
	if cam is CameraCanvas: cam.add(text,front)
	else: cam.add_child(text)

##Returns the string of the Text
static func getTextString(tag: String) -> String:
	if tag in textsCreated: return textsCreated[tag].text
	return ''

##Remove Text from the game, if [code]delete[/code] is [code]true[/code], the text will be removed from the memory.
static func removeText(text: Variant,delete: bool = false) -> void:
	text = _find_object(text)
	if !text: return
	if delete: textsCreated.erase(text.name); text.queue_free()
	else: var parent = text.get_parent(); if parent: parent.remove_child(text)

static func textsExits(tag: String) -> bool: return textsCreated.has(tag) ##Check if the Text as created
#endregion


#region Tween Methods
##Start Tween. Similar to [method createTween].[br]
##[b]OBS:[/b] if [param time] is [code]0.0[/code], this will cause the function to set the values, without any tween.
static func startTween(tag: String, object: Variant, what: Dictionary,time = 1.0, easing: StringName = &'') -> TweenerObject:
	if !object is Object:
		var split = _find_object_with_split(object)
		object = split[0]
		if !object: return
		if split[1]: var split_join = ":".join(split[1]); for i in what.keys(): DictionaryUtils.rename_key(what,i,split_join+':'+i)
	
	if !object: return
	
	for property in what:
		if (property is NodePath or property.contains(':'))\
		and object.get_indexed(property) != null or property in object: continue
		var alt = alternative_variables.get(property); if alt: what[alt] = what[property]
		what.erase(property)
	
	if time: return startTweenNoCheck(tag,object,what,float(time),easing)
	for i in what: setProperty(i,what[i],object)
	
	return

static func startTweenNoCheck(tag: String,object: Object, what: Dictionary,time: float = 1.0, easing: StringName = &'') -> TweenerObject:
	var tween = createTween(object,what,time,easing)
	tween.finished.connect(_tween_completed.bind(tag),CONNECT_ONE_SHOT)
	if !tag: return tween
	cancelTween(tag)
	tweensCreated[tag] = tween
	return tween

##Create a Tween Method, similar to [Tween.tween_method]
static func createTweenMethod(from: Variant, to: Variant, time: Variant, ease: String, method: Callable):
	var tween = TweenService.createTweenMethod(method,from,to,time,ease)
	tween.bind_node = game
	return tween

##Create a Tween Interpolation, see more about in [method TweenService.createTween]
static func createTween(object: Variant, what: Dictionary,time: Variant, easing: StringName = &''):
	object = _find_object(object); 
	var tween = TweenService.createTween(object,what,time,easing); 
	tween.bind_node = object
	return tween

##Similar to [method Tween.tween_method].
static func startTweenMethod(tag: String, from: Variant, to: Variant, time: Variant, ease: String, method: Callable) -> TweenerMethod:
	var tween = createTweenMethod(from,to,time,ease,method); if !tag: return tween
	cancelTween(tag)
	tweensCreated[tag] = tween
	return tween

static func _tween_completed(tag: StringName): callOnScripts(&'onTweenCompleted',[tag]); tweensCreated.erase(tag)

##Do Tween for a [ShaderMaterial].[br][br]
##[code]shader[/code] can be a [ShaderMaterial] or a tag([String]) used in [method initShader].
##Example of Code:[codeblock]
##var shader_material: ShaderMaterial = Paths.loadShader('ChromaticAbberration')
##setShaderFloat(shader_material,'strength',0.005)
##doShaderTween(shader_material,'strength',0.0,0.2,&'','chrom_tag')
##
##initShader('ChromaticAbberation','chrom')
##setShaderFloat('chrom','strength',0.01)
##doShaderTween('chrom','strength',0.0,0.2,&'','chrom_tag')[/codeblock]
static func doShaderTween(shader: Variant, parameter: StringName, value: Variant, time: float, ease: StringName = &'', tag: StringName = '') -> TweenerMethod:
	var material = _find_shader_material(shader); if !material: return
	var tween = TweenService.tween_shader(material,parameter,float(value),float(time),ease)
	tween.bind_node = game
	
	if !tag and shader is String: tag = 'shader'+shader+parameter
	if tag: cancelTween(tag); tweensCreated[tag] = tween
	return tween

static func doShadersTween(shaders: Array, parameter: StringName, value: Variant, time: float, ease: StringName = &'') -> Array[TweenerMethod]:
	var tweens: Array[TweenerMethod]; for i in shaders: tweens.append(doShaderTween(i,parameter,value,time,ease))
	return tweens

##Cancel the Tween. See also [method startTween].
static func cancelTween(tag: String) -> void:
	var tween = tweensCreated.get(tag); if !tween: return
	TweenService.tweens_to_update.erase(tween)
	tweensCreated.erase(tag)

##Detect if the a Tween is running by its tag.
static func isTweenRunning(tag: String) -> bool: return tag in tweensCreated

##Creates a TweenZoom for cameras.
static func doTweenZoom(tag: String,object: Variant, toZoom, time = 1.0, easing: StringName = &'') -> TweenerObject: return startTween(tag,object,{&'zoom': float(toZoom)},float(time),easing)

##Create a Tween changing the x value, can be usefull not just for positions, but for anothers variables too, the same for the different tweens.
##Example: [codeblock]
##doTweenX('tween','boyfriend',2) #Make a tween of the boyfriend position.
##doTweenX('tween','boyfriend.offset',2) #Make a tween of the boyfriend offset.
##[/codeblock]
##See also [method doTweenY] and [method doTweenAngle].
static func doTweenX(tag: String,object: Variant, to: Variant, time: float = 1.0, easing: StringName = &'') -> TweenerObject: return startTween(tag,object,{&'x': float(to)},float(time),easing)

##Creates a Tween for the y value. See also [method doTweenX] and [method doTweenAngle].
static func doTweenY(tag: String,object: Variant, to: Variant, time = 1.0, easing: StringName = &'') -> TweenerObject: return startTween(tag,object,{&'y': float(to)},float(time),easing)

##Creates a Tween for the alpha of a [Node]. See also [method doTweenColor].
static func doTweenAlpha(tag: String, object: Variant, to: Variant, time = 1.0, easing: StringName = &'') -> TweenerObject: return startTween(tag,object,{ModulateAlpha: float(to)},float(time),easing)
	
##Creates a Tween for the color of a [Node]. See also [method doTweenAlpha].
static func doTweenColor(tag: String, object: Variant,color: Variant, time = 1.0, easing: StringName = &'') -> TweenerMethod:
	object = _find_object(object); if !object: return null
	return startTweenMethod(tag,object.modulate,_get_color(color),float(time),easing,_modulate_method.bind(object))

static func _modulate_method(col: Variant, obj: CanvasItem) -> void: obj.modulate = Color(col.r,col.b,col.g,obj.modulate.a)

##Creates a Tween for the rotation of a [Node]. See also [method doTweenX] and [method doTweenY].
static func doTweenAngle(tag: String, object: Variant, to: Variant, time = 1.0, easing: StringName = &'') -> TweenerObject: return startTween(tag,object,{&'angle': float(to)},time,easing)
#endregion


#region Note Tween Methods
##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenX(tag: String,noteID: Variant = 0,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: return startNoteTween(tag,noteID,{&'x': float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenX] and [method noteTweenAngle].
static func noteTweenY(tag: String,noteID,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: return startNoteTween(tag,noteID,{&'y': float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenColor].
static func noteTweenAlpha(tag: String,noteID,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: return startNoteTween(tag,noteID,{ModulateAlpha: float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenAngle(tag: String,noteID,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: return startNoteTween(tag,noteID,{&'angle': float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenDirection(tag: String,noteID,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: return startNoteTween(tag,noteID,{&'direction': float(target)},float(time),easing)

##Creates a Tween for the color of a Note. See also [method noteTweenAlpha].
static func noteTweenColor(tag: String,noteID,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: return startNoteTween(tag,noteID,{&'modulate': float(target)},float(time),easing)

static func startNoteTween(tag: String, noteID, values: Dictionary, time, ease: String) -> TweenerObject:
	return startTween(
		tag,
		_find_group_members('strumLineNotes',int(noteID)),
		values,
		float(time),
		ease
	)
#endregion

#region Note Methods
##Returns a new Strum Note. If you want to add the Strum to a group, see also [method addSpriteToGroup].
static func createStrumNote(note_data: int, style: String = 'funkin', tag: StringName = &''):
	var strum: StrumNote = StrumNote.new(note_data)
	strum.loadFromStyle(style)
	if tag: _insert_sprite(tag,strum)
	return strum
#endregion

#region Shader Methods
##Create Shader using tags, making it possible to create several shaders from the same material;[br][br]
##Example: [codeblock]
##initShader('shader1','Chrom');
##initShader('shader2','Chrom');
##setShaderFloat('shader2','strength',1.0);
##[/codeblock][br]
##[b]OBS:[/b] if [code]obrigatory[/code], the shader will be started 
##even [code]shadersEnabled[/code] is false.
static func initShader(shader: String, tag: StringName = &'', obrigatory: bool = false) -> ShaderMaterial:
	if !obrigatory and !shadersEnabled: return
	if !tag: tag = shader
	if tag in shadersCreated and shadersCreated[tag].shader.resource_name == shader: return shadersCreated[tag]
	
	var shader_material: ShaderMaterial = Paths.loadShader(shader)
	if !shader_material: return
	shadersCreated[tag] = shader_material
	callOnScripts(&'onLoadShader',[shader,shader_material,tag])
	return shader_material
	
##Add [Material] to a [code]camera[/code], [code]shader[/code] can be a [String] or a [Array].[br][br]
##[b]OBS:[/b] If the [code]shader[/code] was not started using [method initShader], this function will call automatically.
##[br][br]Example of code:[codeblock]
##var shader_material1 = ShaderMaterial.new()
##var shader_material2 = ShaderMaterial.new()
##addShaderCamera('game',shader_material1)
##addShaderCamera('game',shader_material2)
###or
##addShaderCamera('game',[shader_material1,shader_material2])
###or
##addShaderCamera('game',['ChromaticAberration',shader_material2])
##[/codeblock][br]
##If you want to add the same shader in more cams:
##[codeblock]
##addShaderCamera(['game','hud'],shader_material2)
##[/codeblock]
##[b]Note:[/b] The same works for [method removeShaderCamera].
##[br][br]See also [method setSpriteShader].
static func addShaderCamera(camera: Variant, shader: Variant) -> void:
	if !shader: return
	if shader is String: shader = _find_shader_material(shader); if !shader: return
	
	if shader is ShaderMaterial:
		if camera is Array: 
			for i in camera: var cam = getCamera(i); if cam: cam.addFilter(shader); 
			return
		if camera is String: camera = getCamera(camera)
		if !camera: return
		camera.addFilter(shader)
		return
	
	_check_shaders_array(shader)
	
	if camera is Array: for i in camera: var cam = getCamera(i); if cam: cam.addFilters(shader); return
	if camera is String: camera = getCamera(camera)
	
	
	if camera: camera.addFilters(shader)

static func _check_shaders_array(shaders: Array) -> void:
	var index: int = shaders.size()-1
	while index:
		var s = shaders[index]
		if s is ShaderMaterial: index -= 1; continue
		shaders[index] = _find_shader_material(s)
		index -= 1

##Remove shader from the camera, [code]shader[/code] can be a [String] or a [Array].
##[br]See also [method addShaderCamera].
static func removeShaderCamera(camera: Variant, shader: Variant) -> void:
	var cam = getCamera(camera)
	if !cam: return
	shader = _find_shader_material(shader)
	
	if !shader: return
	cam.removeFilter(shader)

##Set the sprite's shader, [code]shader[/code] can be a [ShaderMaterial] or a [String].
##[br][br]See also [method addShaderCamera].
static func setSpriteShader(object: Variant, shader: Variant) -> void: object = _find_object(object); if object: object.set(&'material',_find_shader_material(shader))

static func removeSpriteShader(object: Variant) -> void: object = _find_object(object); if object: object.set(&'material',null) ##Remove the current shader from the object

#region Shader Values Methods
static func setShaderParameter(shader: Variant, parameter: String, value: Variant): shader = _find_shader_material(shader); if shader: shader.set_shader_parameter(parameter,value)

static func addShaderFloat(shader: Variant, parameter: String, value: float): ##Add [code]value[/code] to a [u][float] parameter[/u] of a [code]shader[/code] created using [method initShader].
	shader = _find_shader_material(shader); if !shader: return
	var vars = shader.get_shader_parameter(parameter); if vars == null: vars = 0.0
	shader.set_shader_parameter(parameter,vars+value)

static func getShaderParameter(shader: Variant, shaderVar: String) -> Variant: shader = _find_shader_material(shader); return shader.get_shader_parameter(shaderVar) if shader else null
#endregion

static func setBlendMode(object: Variant, blend: String) -> void: ##Sets Object Blend mode, can be: [code]add,subtract,mix[/code]
	object = _find_object(object); if !object is CanvasItem: return
	var material = ShaderUtils.get_blend(blend)
	if material: object.set(&'material', material)

static func _find_shader_material(shader: Variant) -> ShaderMaterial:
	if !shader or shader is ShaderMaterial: return shader
	var material = shadersCreated.get(shader); if material: return material
	material = _find_object(shader)
	return material.get(&'material') if material else null
#endregion


#region Camera Methods
static func createCamera(tag: String, order: int = 5) -> CameraCanvas:
	if tag in modVars: return modVars[tag]
	var cam = CameraCanvas.new()
	cam.name = tag
	modVars[tag] = cam
	game.add_child(cam)
	game.move_child(cam,order)
	return cam

##Do Camera Flash
static func cameraFlash(cam: Variant, flashColor: Variant = Color.WHITE, time = 1.0, force: bool = false) -> void:
	cam = getCamera(cam); if cam: cam.flash(_get_color(flashColor),float(time),force)

##Make a camera shake.
static func cameraShake(cam: Variant, intensity: float = 0.0, time: float = 1.0) -> void:
	cam = getCamera(cam); if cam is CameraCanvas: cam.shake(float(intensity),float(time))

##Make a fade in, or out, in the camera.
static func cameraFade(cam: Variant, color: Variant = Color.BLACK, time: Variant = 1.0, force: bool = false, fadeIn: bool = true):
	cam = getCamera(cam); if cam is CameraCanvas: cam.fade(color,float(time),force,fadeIn)

##Move the game camera for the [code]target[/code].
static func cameraSetTarget(target: String = 'boyfriend') -> void: game.moveCamera(target)
	
##Set the object camera.
static func setObjectCamera(object: Variant, camera: Variant = 'game'):
	object = _find_object(object); if !object: return
	var cam: Node = getCamera(camera); if !cam: return
	if object is FunkinSprite: object.set(&'camera',cam)
	else: cam.add(object)

static func getCenterBetween(object1: Variant, object2: Variant) -> Vector2:
	object1 = _find_object(object1); if !object1: return Vector2.ZERO
	object2 = _find_object(object2); if !object2: return Vector2.ZERO
	
	var pos_1 = object1.get_position() if object1.has_method(&'get_position') else null
	var pos_2 = object2.get_position() if object2.has_method(&'get_position') else null
	if !((pos_1 is Vector2 or pos_1 is Vector2i) and (pos_2 is Vector2 or pos_2 is Vector2i)): return Vector2.ZERO
	return pos_1 - (pos_2 - pos_1)/2.0


##Detect the camera name using a String.
static func cameraAsString(string: StringName) -> String:
	match string.to_lower():
		&'hud', &'camhud':return &'camHUD'
		&'other', &'camother':return &'camOther'
		&'game',&'camgame':return &'camGame'
		_: return string

static func getCharacterCamPos(char: Variant): ##Returns the camera position from [param char].
	if char is String: char = getProperty(char)
	if game: return game.getCameraPos(char)
	if char is Character: return char.getCameraPosition()
	if char is FunkinSprite: return char.getMidpoint()
	
	return char.position


##Returns a [CameraCanvas] created using [method createCamera] or the game's camera named with [param camera]
static func getCamera(camera: Variant) -> CameraCanvas: return camera if camera is Node else getProperty(cameraAsString(camera))
#endregion


#region Game Methods
static func startCountdown() -> void: game.startCountdown() ##Starts the song count down.
static func endSong(skip_transition: bool = false) -> void: game.endSound(skip_transition) ##Ends the game song.
static func setHealth(value: float) -> void: game.health = value ##Sets the player health.
static func getHealth() -> float: return game.health ##Returns the player health.

static func setHealthBarColors(left: Variant, right: Variant):
	if !game: return
	var healthBar: Bar = game.get(&'healthBar'); if !healthBar: return
	healthBar.set_colors(_get_color(left),_get_color(right))

static func startVideo(path: Variant, isCutscene: bool = true) -> VideoStreamPlayer: return game.startVideo(path, isCutscene) ##Starts a video.
#endregion


#region Song Methods
static func is_audio(value: Object): return value and value.get_class().begins_with('AudioStreamPlayer')

##Skip the song to [code]time[/code].[br]
##If [code]kill_notes[/code], the notes before that time will be destroyed, avoiding missing them and ending up dying.
static func setSongPosition(time: Variant, kill_notes: bool = false): game.seek_to(float(time),kill_notes)

static func getSongPosition() -> float: return Conductor.songPositionDelayed ##Get Song Position.

static func getSoundTime(sound: Variant) -> float:##Get the Sound Time.
	if sound is String and sound in soundsPlaying: sound = soundsPlaying[sound]
	return sound.get_playback_position() if is_audio(sound) else 0.0

static func setSoundVolume(sound: Variant, volume: float = 1) -> void:
	if sound is String: sound = getProperty(sound)
	if !is_audio(sound): return
	sound.volume_db = -80 + (80*volume)


static func detectSection() -> String: return game.detectSection() ##Returns the current character section name of the song.

##Play a sound. [code]path[/code] can be a [String] or a [AudionStreamOggVorbis].
##[br]Example of code: [codeblock]
##playSound('noise',1.0,'noise_sound')
##
##var audio = Paths.sound('noise2')
##playSound(audio,1.0,'noise_sound2')
##[/codeblock]
static func playSound(path, volume: float = 1.0, tag: String = "",force: bool = false, loop: bool = false) -> AudioStreamPlayer:
	if !path: return null
	var audio: AudioStreamPlayer
	
	if soundsPlaying.get(tag):
		audio = soundsPlaying[tag]
		if audio.playing and !force: return audio
	else:
		audio = _get_sound(path)
		if tag:
			audio.name = tag
			soundsPlaying[tag] = audio
			audio.finished.connect(stopSound.bind(tag),CONNECT_ONE_SHOT)
		(game if game else Global).add_child(audio)
	
	if audio.stream: audio.stream.loop = loop
	
	audio.play(0)
	audio.volume_db = linear_to_db(volume)
	return audio

static func stopSound(tag: StringName):
	if !soundsPlaying.has(tag): return
	soundsPlaying[tag].stop()
	soundsPlaying.erase(tag)
#endregion

static func _get_sound(path: Variant):
	if !path is AudioStream: path = Paths.sound(path); if !path: return
	var audio = AudioStreamPlayer.new()
	audio.stream = path;
	audio.finished.connect(audio.queue_free)
	return audio

#region Keyboard Methods
static func keyboardJustPressed(key: String) -> bool: return InputUtils.isKeyJustPressed(OS.find_keycode_from_string(key)) ##Detect if the keycode is just pressed. See also [method keyboardJustReleased].
static func keyboardJustReleased(key: String) -> bool: return InputUtils.isKeyJustReleased(OS.find_keycode_from_string(key)) ##Detect if the keycode is just pressed. See also [method keyboardJustPressed].

##Detect if the keycode is pressed, similar to [method Input.is_key_label_pressed].
##[br]See also [method keyboardJustPressed].
static func keyboardPressed(key: String) -> bool: return Input.is_key_pressed(OS.find_keycode_from_string(key))
#endregion


#region Script Methods
##Detect if a script[u],created using [method addScript],[/u] is running.
static func scriptIsRunning(path: StringName) -> bool: return getScriptPath(path) in scriptsCreated
static func callMethod(object: Variant, function: String, variables: Array = []) -> Variant:
	object = _find_object(object); if !(object and object.has_method(function)): return
	return object.callv(function,variables)

static func insertScript(script: Object, path: String = '') -> bool:
	if !script: return false
	init_gd()
	var args = get_arguments(script)
	
	scriptsCreated[path] = script
	arguments[script.get_instance_id()] = args
	
	
	for func_name in args:
		if !func_name in method_list: method_list[func_name] = [script]
		else: method_list[func_name].append(script)
	
	
	if args.has(&'onCreate'): script.onCreate()
	if args.has(&'onCreatePost') and game and game.get(&'stateLoaded'):script.onCreatePost(); 
	
	return true

##Get a script created from the [method addScript].
static func getScript(path: String) -> Object:
	if !path: return
	path = getScriptPath(path)
	var script = scriptsCreated.get(path)
	return script if script else _load_script(path)

static func getScriptPath(path: String): return path if path.ends_with('.gd') else path+'.gd'

##Returning a new [Object] with the script created, useful if you want to call a function without using [method callScript] or want to change a variable of the script.
##Example of code:[codeblock]
##var script = addScript('ghosting_trail')
##script.time = 0.5
##script.createTrail()
##[/codeblock]
static func addScript(path: String) -> Object:
	path = getScriptPath(path)
	
	var script = scriptsCreated.get(path)
	if script: return script
	
	script = _load_script(path)
	if !script: return
	
	var resource = script.new()
	resource.set(&'scriptPath',path)
	resource.set(&'scriptMod',Paths.getModFolder(path))
	return resource if insertScript(resource,path) else null

static func removeScript(path: Variant): ##Remove the script.[br] ##[param path] Can be the script inself or his path.
	var script: Object
	if path is Object: 
		script = path
		path = _find_script_path(script)
		if !path: return
	else:
		if path is String: path = getScriptPath(Paths.getPath(path,false))
		script = scriptsCreated.get(path)
		if !script: return
	
	scriptsCreated.erase(path)
	for i in arguments.get(script.get_instance_id()):
		if method_list[i].size() == 1: method_list.erase(i)
		else:  method_list[i].erase(script)
	callOnScripts(&'onScriptRemoved',[script,path])

static func _find_script_path(script: Object) -> String:
	var id = script.get_instance_id()
	for i in scriptsCreated: if scriptsCreated[i].get_instance_id() == id: return i
	return ''

##Disables callbacks, useful if you no longer need to use them. Example:
##[codeblock]
##disableCallback(self,'onUpdate') #This disable the game to call "onUpdate" in this script
##[/codeblock]
static func disableCallback(script: Variant, function: StringName):
	if !script: return
	var func_scripts = method_list.get(function); if !func_scripts: return
	func_scripts.erase(_get_script(script))


static func _load_script(path: String) -> Object:
	var absolutePath: String = Paths.detectFileFolder(path); if !absolutePath: return;
	var GScript: GDScript = GDScript.new()
	GScript.source_code = FileAccess.get_file_as_string(absolutePath)
	GScript.reload()
	return GScript


##Calls a function in the script, returning a [Variant] that the function returns.
static func callScript(script: Variant,function: StringName = &'', parameters: Variant = null) -> Variant:
	script = _get_script(script); if !script: return
	return callScriptNoCheck(script,function,parameters)

##Calls a function for every script created.
static func callOnScripts(function: StringName, parameters: Variant = null) -> Variant:
	var func_args = method_list.get(function); if !func_args: return
	for i in func_args: callScriptNoCheck(i,function,parameters)
	return


##Calls a function for every script created.[br]
##returns a [Array] with the values returned from each call.
static func callOnScriptsWithReturn(function: StringName, parameters: Variant = null) -> Array:
	var func_args = method_list.get(function); if !func_args: return []
	var returns: Array = []
	for i in func_args: returns.append(callScriptNoCheck(i,function,parameters))
	return returns
	
static func callScriptNoCheck(script: Object, function: StringName, parameters: Variant) -> Variant:
	var args = arguments.get(script.get_instance_id()); if !args or !args.has(function): return
	args = args[function]
	if !args: return script.call(function)
	
	if args.size() == 1: return script.call(function,parameters[0] if ArrayUtils.is_array(parameters) else parameters)
	return script.callv(function,_sign_parameters(args,parameters)) 

static func _sign_parameters(args: Array,parameters: Variant) -> Array:
	if !args: return args
	if ArrayUtils.is_array(parameters): return _sign_parameters_array(args,parameters)
	parameters = [_sign_value(parameters,args[0].type)]
	var index: int = 1
	while index < args.size(): 
		var i = args[index]
		if i.has(&'default'): break
		parameters.append(MathUtils.get_new_value(i.type));
		index += 1
	 
	return parameters

static func _sign_parameters_array(args: Array, parameters: Array) -> Array:
	var index: int = -1
	
	var args_length = args.size()-1
	var append: bool = false
	while index < args_length:
		index +=1
		var i = args[index]
		if append:
			if i.has(&'default'): break
			parameters.append(MathUtils.get_new_value(i.type))
		else: 
			append = index == parameters.size()-1
			parameters[index] = _sign_value(parameters[index],i.type)
	return parameters

static func _sign_value(value: Variant, type_to_convert: Variant.Type) -> Variant:
	return value if type_to_convert == TYPE_NIL or typeof(value) == type_to_convert else type_convert(value,type_to_convert)

static func _get_script(script: Variant) -> Object:
	if script is String: return scriptsCreated.get(script if script.ends_with('.gd') else script+'.gd')
	return script

static var class_dirs: PackedStringArray = [
	'',
	'res://',
	'res://source/',
	'res://source/general/',
	'res://source/objects/',
	Paths.exePath+'/assets/'
]
##Get a Class, this can catch every class used in the game, check the file paths here: 
##[url]https://github.com/zlMyt/FNFGodot[/url]
##[br]Example of code:[codeblock]
##const note_class = getClass('objects/Note')
##var Note = note_class.new()
##
##var trail = getClass('effects/Trail')
##[/codeblock]
static func getClass(class_path: String) -> Variant:
	if class_path.ends_with('.tscn'):
		var classInstance: Resource = load(class_path)
		return (classInstance.instantiate() if classInstance else null)
	
	if !class_path.get_extension(): class_path += '.gd'
	var path: String
	for dir in class_dirs:
		var file = dir+class_path
		if FileAccess.file_exists(file): path = file; break
	return load(path) if path else null

##Close this script.
func close() -> void: removeScript(self)
#endregion


#region Event Methods
##Trigger Event, if [code]value2[/code] is setted, [variables] will be considered as a value1;[br]
##Example: [codeblock]
###Similar to the old versions of Psych Engine, more limited.
##triggerEvent('eventName','value1','value2')
##
###Can set multiply variables, useful for complex events
##triggerEvent('eventName',{'x': 0.0,'y': 0.0,'angle': 0.0})
##[/codeblock]
static func triggerEvent(event: StringName,variables: Variant = '', value2: Variant = ''):
	if !variables is StringName: game.triggerEvent(event,variables)
	
	var default: Dictionary = EventNoteUtils.get_event_variables(event)
	var event_keys = default.keys()
	var parameters: Dictionary = {}
	
	for i in default: parameters[i] = default[i].default_value
	
	if variables:
		var first_key = event_keys[0]
		parameters[first_key] = EventNoteUtils._convert_event_value_type(
				variables,
				default[first_key].type
			)
	
	if value2 and event_keys.size() > 1:
		parameters[event_keys[1]] = EventNoteUtils._convert_event_value_type(
			value2,
			default[event_keys[1]].type
		)
	
	game.triggerEvent(event,parameters)
#endregion

#region Color Methods
static func _get_color(color: Variant) -> Color: return color if color is Color else getColorFromHex(color)

static func getColorFromHex(color: String, default: Color = Color.WHITE) -> Color: ##Return [Color] using Hex
	if !color: return default
	if color.begins_with('0x'): color = color.right(-4)
	while color.length() < 6: color += '0'
	return Color.html(color.to_lower())

##Returns a [Color] using a [Array][[color=red]r[/color], [color=green]g[/color], [color=blue]b[/color]]:
##Example:[codeblock]
##getColorFromArray([255,255,255],true)# Returns Color.WHITE (Color(1,1,1))
##getColorFromArray([1,1,1],false) #Also returns Color.WHITE (Color(1,1,1))
##getColorFromArray([255,0,0])# Returns Color(1,0,0)
##[/codeblock]
static func getColorFromArray(array: Array, divided_by_255: bool = true) -> Color:
	return Color(array[0]/255.0,array[1]/255.0,array[2]/255.0) if divided_by_255 else Color(array[0],array[1],array[2])

##Returns a [Color] using his name:
##Example:[codeblock]
##getColorFromName('red')# Returns Color.RED (Color(1,0,0))
##getColorFromName('white') #Returns Color.WHITE (Color(1,1,1))
##getColorFromName('BLACK') #Returns Color.BLACK (Color(0,0,0))
##getColorFromName('invalid color') #Returns Color.WHITE(default)
##getColorFromName([255,0,0])# Returns Color(1,0,0)
##[/codeblock]
static func getColorFromName(color_name: String, default: Color = Color.WHITE) -> Color: return Color.from_string(color_name.to_lower(),default)
#endregion

static func show_funkin_warning(warning: String, color: Color = Color.RED, only_show_when_debugging: bool = true):
	if only_show_when_debugging and !debugMode: return
	var text = Global.show_label_warning(warning,5.0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.modulate = color 
