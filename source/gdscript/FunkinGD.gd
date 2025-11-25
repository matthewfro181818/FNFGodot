extends "FunkinInternal.gd"
class_name FunkinGD

#region Variables
const TweenerObject = preload("uid://b3wombi1g7mtv")
const TweenerMethod = preload("uid://buyyxjslew1n1")

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

const Graphic = preload("uid://c4kmei8jjkf3n")


#region Public Vars
@export_category('Class Vars')

static var Function_Continue: int
static var Function_Stop: int = 1


static var isStoryMode: bool

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
var modFolder: StringName


@export_category("Files Saved")


##Used to precache the Methods in the script, being more optimized for calling functions in [method callOnScripts]


@export_group('Game Data')
static var isPixelStage: bool:
	get(): return game.isPixelStage

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

#region Song Data Properties
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
#endregion

#region Conductor Properties
static var bpm: float
static var stepCrochet: float
static var crochet: float

static var curBeat: int
static var curStep: int

static var curSection: int
static var keyCount: int = Song.keyCount
#endregion

#region Client Prefs Properties
@export_category("Client Prefs")
#Scroll
static var middlescroll: bool:
	get(): return game.middleScroll
static var downscroll: bool:
	get(): return game.downScroll
static var hideHud: bool

#TimeBar
static var hideTimeBar: bool
static var timeBarType: String

static var shadersEnabled: bool:
	get(): return ClientPrefs.data.shadersEnabled

static var version: StringName = &'1.0' ##Engine Version

static var cameraZoomOnBeat: bool = true

static var flashingLights: bool:
	get(): return ClientPrefs.data.flashingLights

static var framerate: float:
	get(): return Engine.max_fps
#endregion

#endregion

static var Conductor_Signals: Dictionary[String,Callable] = {
	&'section_hit': _section_hit,
	&'section_hit_once': FunkinGD.callOnScripts.bind(&'onSectionHitOnce'),
	&'beat_hit': _beat_hit,
	&'step_hit': _step_hit,
	&'bpm_changes': _bpm_changes
}
static var started: bool
static func init_gd():
	if started or !Conductor: return
	started = true
	for i in Conductor_Signals: Conductor[i].connect(Conductor_Signals[i])
	_bpm_changes()

static func _bpm_changes() -> void:
	bpm = Conductor.bpm
	stepCrochet = Conductor.stepCrochet
	crochet = Conductor.crochet


#region File Methods
 ##Similar to [method Paths.file_exists].
static func checkFileExists(path: String) -> bool: return Paths.file_exists(path)
static func precacheImage(path: String) -> Image: return Paths.image(path) ##Precache a image, similar to [method Paths.image]
static func precacheMusic(path: String) -> AudioStreamOggVorbis: return Paths.music(path) ##Precache a music, similar to [method Paths.music]
static func precacheSound(path: String) -> AudioStreamOggVorbis: return Paths.sound(path) ##Precache a sound, similiar to [method Paths.sound]
static func precacheVideo(path: String) -> VideoStreamTheora: return Paths.video(path) ##Precache a video file.
	
static func addCharacterToList(character: StringName, type: Variant = 'bf') -> void: ##Precache character.
	if not (Paths.character(character) and game): return
	if type is int: game.addCharacterToList(type,character); return
	match type:
		'bf','boyfriend': game.addCharacterToList(0,character)
		'dad':game.addCharacterToList(1,character)
		'gf':game.addCharacterToList(2,character)
#endregion


#region Property methods


##Set a Property. If [param target] set, the function will try to set the property from this object.
static func setProperty(property: String, value: Variant, target: Variant = null) -> void:
	Reflect.setProperty(property,value,target)

static func getProperty(property: String, from: Variant = null): 
	return Reflect.getProperty(property,from)

static func setVar(variable: Variant, value: Variant = null) -> void: modVars[variable] = value ##Set/Add a variable to [member modVars].

static func getVar(variable: Variant) -> Variant: return modVars.get(variable) ##Get a variable from the [member modVars].

#endregion


#region Class Methods
static func getPropertyFromClass(_class: Variant, variable: String) -> Variant:
	_class = Reflect._find_class(_class); if _class: return Reflect.getProperty(variable,_class)
	return
static func setPropertyFromClass(_class: Variant,variable: String,value: Variant) -> void:##Set the variable of the [code]_class[/code]
	_class = Reflect._find_class(_class); if _class: setProperty(variable,value,_class)
#endregion

#region Group Methods
##Add [Sprite] to a [code]group[/code] [SpriteGroup] or [Array].[br][br]
##If [code]at = -1[/code], the sprite will be inserted at the last position.
static func addSpriteToGroup(object: Variant, group: Variant, at: int = -1) -> void:
	object = Reflect._find_object(object)
	if !object: return
	
	if group is String: group = Reflect._find_object(group)
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
#endregion


#region Timer Methods
static func runTimer(tag: StringName, time: float, loops: int = 1) -> Timer: ##Runs a timer, return the [Timer] created.
	loops = maxi(loops,0)
	if !time: 
		while loops: loops -= 1; callOnScripts(&'onTimerCompleted',[tag,loops]); 
		return
	var data = timersPlaying.get(tag)
	if !data: return _create_timer(tag,time,loops)[0]
	data[1] = loops
	var timer: Timer
	timer = data[0]
	timer.start(time)
	return timer

static func getTimerLoops(tag: String) -> int:
	var data = timersPlaying.get(tag); return data[1] if data else 0

static func cancelTimer(tag: String): ##Cancel Timer. See also [method runTimer].
	var timer = timersPlaying.get(tag); if !timer: return
	timer = timer[0]; timer.stop(); timersPlaying.erase(tag); timer.queue_free()
#endregion


#region Random Methods
##Return a random [bool].
static func getRandomBool(chance: int = 50) -> bool: return randi_range(0,100) <= chance
#endregion


#region Sprite Methods
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
	object = Reflect._find_object(object)
	if !object: return
	var cam: FunkinCamera = object.get('camera'); if !cam: cam = game.get('camGame')
	if !cam: return
	cam.add(object,front)

static func addSpriteToCamera(object: Variant, camera: Variant, front: bool = false) -> void: ##Add a [Sprite] to a [param camera].
	object = Reflect._find_object(object); if !object: return
	camera = getCamera(camera)
	if camera: camera.add(object,front)

static func insertSpriteToCamera(object: Variant, camera: Variant, at: int): ##Insert a [Sprite] to a [param camera] in a specific position.
	object = Reflect._find_object(object); if !object: return
	camera = getCamera(camera)
	if camera: camera.insert(at, object)

##Remove [Sprite] of the game. When [code]delete[/code] is true, the sprite will be remove completely.
static func removeSprite(object: Variant, delete: bool = false) -> void:
	var tag
	if object is Node: tag = object.name
	else: tag = object; object = Reflect._find_object(object)

	if !object: return
	
	if object.is_inside_tree(): object.get_parent().remove_child(object)
	if delete: spritesCreated.erase(tag)

static func createSpriteGroup(tag: String) -> SpriteGroup: ##Creates a [SpriteGroup].
	var group = SpriteGroup.new()
	if groupsCreated.has(tag): groupsCreated[tag].queue_free()
	groupsCreated[tag] = group
	return group

static func makeGraphic(object: Variant,width: float = 0.0,height: float = 0.0,color: Variant = Color.BLACK) -> FunkinSprite:
	if !object: return
	color = _get_color(color)
	if object is Object: _make_graphic_no_check(object,width,height,color); return object
	
	var _tag = object; object = Reflect._find_object(_tag); 
	if !object: object = makeSprite(_tag)
	_make_graphic_no_check(object,width,height,color)
	return object

static func _make_graphic_no_check(object: Node, width: float = 0.0, height: float = 0.0, color: Color = Color.WHITE):
	if !object is Node: return
	object.image.set_solid()
	object.image.modulate = _get_color(color)
	object.image.region_rect.size = Vector2(width,height)
##Load image in the sprite.
static func loadGraphic(object: Variant, image: String, width: float = -1, height: float = -1) -> Texture:
	object = Reflect._find_object(object); if !object: return
	
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
	object = Reflect._find_object(object); if !object: return
	
	if object is FunkinSprite: object.setGraphicSize(sizeX,sizeY)
	elif object is NinePatchRect:
		object.size = Vector2(
			object.image.size.x if sizeX == -1 else sizeX,
			object.image.size.y if sizeY == -1 else sizeY
		)
##Move the [param object] to the center of his camera.[br]
##[param type] can be: [code]""xy,x,y[/code]
static func screenCenter(object: Variant, type: String = &'xy') -> void:
	object = Reflect._find_object(object); if !object: return
	var center = (object.get_viewport().size/2.0 if object.is_inside_tree() else ScreenUtils.screenCenter)
	if object is FunkinSprite: center -= object.image.pivot_offset
	else:
		var tex = object.get('texture')
		var size = tex.get_size() if tex else object.get('size')
		if size: center += size/2.0
	
	var obj_pos = object.call('get_position'); if !obj_pos: return
	match type:
		&'x': object.set_position(center.x,obj_pos.y)
		&'y': object.set_position(obj_pos.x,center.y)
		_: object.set_position(center)

##Scale object.
##If not [param centered], the sprite will scale from his top left corner.
static func scaleObject(object: Variant,x: float = 1.0,y: float = 1.0, centered: bool = false) -> void:
	object = Reflect._find_object(object); if !object: return
	object.set(&'scale',Vector2(x,y))
	if !centered and object is FunkinSprite: object.offset = object.pivot_offset * (Vector2.ONE - object.scale)

##Set the scroll factor from the sprite.[br]
##This makes the object have a depth effect, [u]the lower the value, the greater the depth[/u].
static func setScrollFactor(object: Variant, x: float = 1, y: float = 1) -> void:
	object = Reflect._find_object(object); if object: object.set(&'scrollFactor',Vector2(x,y))

##Set the order of the object in the screen.
static func setObjectOrder(object: Variant, order: int)  -> void:
	object = Reflect._find_object(object); if !object: return
	var parent = object.get_parent(); if parent: parent.move_child(object,clampi(order,0,parent.get_child_count()))


static func getObjectOrder(object: Variant) -> int: ##Returns the object's order.
	object = Reflect._find_object(object); if !object: return 0
	return object.get_index() if object is Node else -1

##Returns if the sprite, created using [method makeSprite] or [method makeAnimatedSprite] or [method setVar], exists.
static func spriteExists(tag: StringName) -> bool: return tag in spritesCreated or modVars.get(tag) is FunkinSprite

static func getMidpointX(object: Variant) -> float: ##Returns the midpoint.x of the object. See also [method getMidpointY].
	object = Reflect._find_object(object)
	if object is FunkinSprite: return object.getMidpoint().x
	if (object is CanvasItem) and object.get('texture'): return object.position.x + (object.texture.get_size().x/2.0)
	return 0.0


static func getMidpointY(object: Variant) -> float: ##Returns the midpoint.y of the object. See also [method getMidpointX].
	object = Reflect._find_object(object)
	if object is FunkinSprite: return object.getMidpoint().y
	if (object is CanvasItem) and object.get('texture'): return object.position.y + (object.texture.get_size().y/2.0)
	return 0.0
#endregion


#region Animation Methods
##Add Animation Frames for the [param object], useful if you are creating custom [Icon]s.
static func addAnimation(object: Variant, animName: StringName, frames: Array = [], frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = Reflect._find_object(object); if !object or !object.get('animation'): return {}
	return object.animation.addFrameAnim(animName,frames,frameRate,loop)
	
##Add animation to a [Sprite] using the prefix of his image.
static func addAnimationByPrefix(object: Variant, animName: StringName, xmlAnim: StringName, frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = Reflect._find_object(object); if !object or !object.get('animation'): return {}
	var frames = object.animation.addAnimByPrefix(animName,xmlAnim,frameRate,loop)
	return frames

##Add [Animation] using the preffix of the sprite, can set the frames that will be played
static func addAnimationByIndices(object: Variant, animName: StringName, xmlAnim: StringName, indices: Variant = [], frameRate: float = 24, loop: bool = false) -> Dictionary:
	object = Reflect._find_object(object); if !object or !object.get('animation'): return {}
	return object.animation.addAnimByPrefix(animName,xmlAnim,frameRate,loop,indices)


##Makes the [param object] play a animation, if exists. If [param force] and the current anim as the same name, that anim will be restarted.
static func playAnim(object: Variant, anim: StringName, force: bool = false, reverse: bool = false) -> void:
	object = Reflect._find_object(object); if not (object is FunkinSprite and object.animation): return
	if reverse: object.animation.play_reverse(anim,force)
	else: object.animation.play(anim,force)

##Add offset for the animation of the sprite.
static func addOffset(object: Variant, anim: StringName, offsetX: float, offsetY: float)  -> void:
	object = Reflect._find_object(object); if object is FunkinSprite: object.addAnimOffset(anim,offsetX,offsetY)

#endregion


#region Text Methods
##Creates a Text
static func makeText(tag: StringName,text: Variant = '', width: float = 500, x: float = 0, y:float = 0) -> FunkinText:
	var newText = FunkinText.new(str(text),width)
	newText.set_position(Vector2(x,y))
	if !tag: return newText
	removeText(tag)
	newText.name = tag
	textsCreated[tag] = newText
	return newText


##Set the text string
static func setTextString(tag: Variant, text: Variant = '') -> void:
	tag = Reflect._find_object(tag); if tag is Label: tag.text = str(text)

##Set the color from the text
static func setTextColor(text: Variant, color: Variant) -> void:
	text = Reflect._find_object(text); if text is Label: text.set(&"theme_override_colors/font_color",_get_color(color))

##Set Text Border
static func setTextBorder(text: Variant, border: float, color: Color = Color.BLACK) -> void:
	text = Reflect._find_object(text); if !text is Label: return
	text.set(&"theme_override_colors/font_outline_color",color)
	text.set(&"theme_override_constants/outline_size",border)

##Set the Font of the Text
static func setTextFont(text: Variant, font: Variant = 'vcr.ttf') -> void:
	text = Reflect._find_object(text) as Label; if !text: return
	font = _find_font(font); if !font: return
	text.set(&'theme_override_fonts/font',font)

static func getTextFont(text: Variant) -> FontFile:
	text = Reflect._find_object(text) as Label; return text.get(&"theme_override_fonts/font") if text else ThemeDB.fallback_font

static func _find_font(font: Variant) -> Font: return font if font is Font else Paths.font(font)

##Set the Text Alignment
static func setTextAlignment(tag: Variant, alignmentHorizontal: StringName = &'left', alignmentVertical: StringName = &'') -> void:
	var obj = Reflect._find_object(tag); if !obj is Label: return
	
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
	text = Reflect._find_object(text); if text: text.set(&"theme_override_font_sizes/font_size",size)

##Add Text to game
static func addText(text: Variant, front: bool = false) -> void:
	text = Reflect._find_object(text); if !text is Label: return
	
	var cam = text.get(&'camera')
	if !cam: cam = camHUD; if !cam: return
	if cam is FunkinCamera: cam.add(text,front)
	else: cam.add_child(text)

static func getTextString(tag: String) -> String: ##Returns the string of the Text
	return textsCreated[tag].text if tag in textsCreated else ''

##Remove Text from the game, if [code]delete[/code] is [code]true[/code], the text will be removed from the memory.
static func removeText(text: Variant,delete: bool = false) -> void:
	text = Reflect._find_object(text)
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
		var split = Reflect._find_object_with_split(object)
		object = split[0]
		if !object: return
		if split[1]: var split_join = ":".join(split[1]); for i in what.keys(): DictionaryUtils.rename_key(what,i,split_join+':'+i)
	
	if !object: return
	
	for property in what:
		if (property is NodePath or property.contains(':'))\
		and object.get_indexed(property) != null or property in object: continue
		var alt = Reflect.alternative_variables.get(property); 
		if alt: what[alt] = what[property]
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
	object = Reflect._find_object(object); 
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

static func cancelTween(tag: String) -> void: ##Cancel the Tween. See also [method startTween].
	var tween = tweensCreated.get(tag); if !tween: return
	TweenService.tweens_to_update.erase(tween)
	tweensCreated.erase(tag)

static func isTweenRunning(tag: String) -> bool: return tag in tweensCreated ##Detect if the a Tween is running by its tag.

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
static func doTweenAlpha(tag: String, object: Variant, to: Variant, time: Variant = 1.0, easing: StringName = &'') -> TweenerObject: return startTween(tag,object,{^"modulate:a": float(to)},float(time),easing)
	
##Creates a Tween for the color of a [Node]. See also [method doTweenAlpha].
static func doTweenColor(tag: String, object: Variant,color: Variant, time = 1.0, easing: StringName = &'') -> TweenerMethod:
	object = Reflect._find_object(object); if !object: return null
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
static func noteTweenAlpha(tag: String,noteID,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: 
	return startNoteTween(tag,noteID,{^"modulate:a": float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenAngle(tag: String,noteID,target = 0.0,time = 1.0,easing: StringName = &'') -> TweenerObject: 
	return startNoteTween(tag,noteID,{&'rotation_degrees': float(target)},float(time),easing)

##Creates a Tween for the rotation of a Note. See also [method noteTweenY] and [method noteTweenAngle].
static func noteTweenDirection(tag: String,noteID: Variant,target: Variant = 0.0,time: Variant = 1.0,easing: StringName = &'') -> TweenerObject: return startNoteTween(tag,noteID,{&'direction': float(target)},float(time),easing)

##Creates a Tween for the color of a Note. See also [method noteTweenAlpha].
static func noteTweenColor(tag: String,noteID: Variant,color: Variant = 0.0,time: Variant = 1.0,easing: StringName = &'') -> TweenerMethod: 
	noteID = getProperty('strumLineNotes.members['+str(noteID)+']'); 
	return startTweenMethod(tag,noteID.modulate,_get_color(color),float(time),easing,_modulate_method.bind(noteID))

static func startNoteTween(tag: String, noteID: Variant, values: Dictionary, time, ease: String) -> TweenerObject:
	noteID = getProperty('strumLineNotes.members['+str(noteID)+']'); 
	return startTween(tag,noteID,values,float(time),ease)
#endregion

#region Note Methods
static func createStrumNote(note_data: int, style: String = 'funkin', tag: StringName = &''): ##Returns a new Strum Note. If you want to add the Strum to a group, see also [method addSpriteToGroup].
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
	
	if shader is String: 
		shader = _find_shader_material(shader); 
		if !shader: return
	elif shader is Array or shader is PackedStringArray: addShadersCamera(camera,shader); return
	elif !shader is ShaderMaterial: return
	if camera is Array: 
		for i in camera: var cam = getCamera(i); if cam: cam.addFilter(shader); 
		return
	
	if camera is String: camera = getCamera(camera)
	if camera: camera.addFilter(shader)

static func addShadersCamera(camera: Variant, shaders: Array):
	_check_shaders_array(shaders)
	if camera is Array: 
		for i in camera: var cam = getCamera(i); if cam: cam.addFilters(shaders);
		return
	
	if camera is String: camera = getCamera(camera)
	if camera: camera.addFilters(shaders)



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
static func setSpriteShader(object: Variant, shader: Variant) -> void: object = Reflect._find_object(object); if object: object.set(&'material',_find_shader_material(shader))

static func removeSpriteShader(object: Variant) -> void: object = Reflect._find_object(object); if object: object.set(&'material',null) ##Remove the current shader from the object

#region Shader Values Methods
static func setShaderParameter(shader: Variant, parameter: String, value: Variant): shader = _find_shader_material(shader); if shader: shader.set_shader_parameter(parameter,value)

static func addShaderFloat(shader: Variant, parameter: String, value: float): ##Add [code]value[/code] to a [u][float] parameter[/u] of a [code]shader[/code] created using [method initShader].
	shader = _find_shader_material(shader); if !shader: return
	var vars = shader.get_shader_parameter(parameter); if vars == null: vars = 0.0
	shader.set_shader_parameter(parameter,vars+value)

static func getShaderParameter(shader: Variant, shaderVar: String) -> Variant: shader = _find_shader_material(shader); return shader.get_shader_parameter(shaderVar) if shader else null
#endregion

static func setBlendMode(object: Variant, blend: String) -> void: ##Sets Object Blend mode, can be: [code]add,subtract,mix[/code]
	object = Reflect._find_object(object); if !object is CanvasItem: return
	var material = ShaderUtils.get_blend(blend)
	if material: object.set(&'material', material)
#endregion


#region Camera Methods
static func createCamera(tag: String, order: int = 5) -> FunkinCamera:
	if tag in modVars: return modVars[tag]
	var cam = FunkinCamera.new()
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
	cam = getCamera(cam); if cam is FunkinCamera: cam.shake(float(intensity),float(time))

##Make a fade in, or out, in the camera.
static func cameraFade(cam: Variant, color: Variant = Color.BLACK, time: Variant = 1.0, force: bool = false, fadeIn: bool = true):
	cam = getCamera(cam); if cam is FunkinCamera: cam.fade(color,float(time),force,fadeIn)

##Move the game camera for the [code]target[/code].
static func cameraSetTarget(target: String = 'boyfriend') -> void: game.moveCamera(target)
	
##Set the object camera.
static func setObjectCamera(object: Variant, camera: Variant = 'game'):
	object = Reflect._find_object(object); if !object: return
	var cam: Node = getCamera(camera); if !cam: return
	if object is FunkinSprite: object.set(&'camera',cam)
	else: cam.add(object)

static func getCenterBetween(object1: Variant, object2: Variant) -> Vector2:
	object1 = Reflect._find_object(object1); if !object1: return Vector2.ZERO
	object2 = Reflect._find_object(object2); if !object2: return Vector2.ZERO
	
	var pos_1 = object1.get_position() if object1.has_method(&'get_position') else null
	var pos_2 = object2.get_position() if object2.has_method(&'get_position') else null
	if !((pos_1 is Vector2 or pos_1 is Vector2i) and (pos_2 is Vector2 or pos_2 is Vector2i)): return Vector2.ZERO
	return pos_1 - (pos_2 - pos_1)/2.0


##Detect the camera name using a String.
static func cameraAsString(string: StringName) -> StringName:
	match StringName(string.to_lower()):
		&'hud', &'camhud': return &'camHUD'
		&'other', &'camother': return &'camOther'
		&'game',&'camgame': return &'camGame'
		_: return string

static func getCharacterCamPos(char: Variant): ##Returns the camera position from [param char].
	if char is String: char = getProperty(char)
	if game: return game.getCameraPos(char)
	if char is Character: return char.getCameraPosition()
	if char is FunkinSprite: return char.getMidpoint()
	
	return char.position


static func getCamera(camera: Variant) -> FunkinCamera: ##Returns a [FunkinCamera] created using [method createCamera] or the game's camera named with [param camera]
	return camera if camera is Node else getProperty(cameraAsString(camera))
#endregion


#region Game Methods
static func startCountdown() -> void: game.startCountdown() ##Starts the song count down.
static func endSong(skip_transition: bool = false) -> void: game.endSound(skip_transition) ##Ends the game song.
static func setHealth(value: float) -> void: game.health = value ##Sets the player health.
static func getHealth() -> float: return game.health ##Returns the player health.

static func setHealthBarColors(left: Variant = null, right: Variant = null):
	if !game: return
	var healthBar: Bar = game.get(&'healthBar'); if !healthBar: return
	if left: left = _get_color(left)
	if right: right = _get_color(right)
	
	healthBar.set_colors(left,right)

static func startVideo(path: Variant, isCutscene: bool = true) -> VideoStreamPlayer: return game.startVideo(path, isCutscene) ##Starts a video.
#endregion


#region Sound Methods
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
static func playSound(path, volume: float = 1.0, tag: String = "", force: bool = false, loop: bool = false) -> AudioStreamPlayer:
	if !path: return null
	var audio: AudioStreamPlayer = soundsPlaying.get(tag)
	
	if !audio: audio = _create_audio(path,tag)
	elif audio.playing and !force: return audio
	
	if audio.stream: audio.stream.loop = loop
	
	audio.play(0)
	audio.volume_db = linear_to_db(volume)
	return audio
#endregion

#region Keyboard Methods
static func keyboardJustPressed(key: String) -> bool: return InputUtils.isKeyJustPressed(OS.find_keycode_from_string(key)) ##Detect if the keycode is just pressed. See also [method keyboardJustReleased].
static func keyboardJustReleased(key: String) -> bool: return InputUtils.isKeyJustReleased(OS.find_keycode_from_string(key)) ##Detect if the keycode is just pressed. See also [method keyboardJustPressed].
#endregion


#region Script Methods
##Detect if a script[u],created using [method addScript],[/u] is running.
static func scriptIsRunning(path: StringName) -> bool: return _script_path(path) in scriptsCreated

static func callMethod(object: Variant, function: String, variables: Array = []) -> Variant:
	object = Reflect._find_object(object); if !(object and object.has_method(function)): return
	return object.callv(function,variables)


static func getScript(path: String) -> Object: ##Get a script created from the [method addScript].
	if !path: return
	path = _script_path(path)
	var script = scriptsCreated.get(path)
	return script if script else addScript(path)


##Returning a new [Object] with the script created, useful if you want to call a function without using [method callScript] or want to change a variable of the script.
##Example of code:[codeblock]
##var script = addScript('scenes/effects/particles/Particles')
##script.lifetime = 1.0
##[/codeblock]
static func addScript(path: String) -> Object:
	path = _script_path(path)
	
	var script = scriptsCreated.get(path)
	if script: return script
	
	var absl_path = Paths.detectFileFolder(path)
	if !absl_path: return
	
	script = _load_script_no_check(absl_path)
	
	var resource = script.new()
	resource.set(&'scriptPath',path)
	resource.set(&'modFolder',Paths.getModFolder(path))
	return resource if _insert_script(resource,path) else null




##Disables callbacks, useful if you no longer need to use them. Example:
##[codeblock]
##disableCallback(self,'onUpdate') #This disable the game to call "onUpdate" in this script
##[/codeblock]
static func disableCallback(script: Variant, function: StringName):
	if !script: return
	var func_scripts = method_list.get(function); if !func_scripts: return
	func_scripts.erase(_get_script(script))


static func loadScript(path: String) -> GDScript:
	path = Paths.detectFileFolder(_script_path(path))
	return _load_script_no_check(path) if path else null


static func _load_script_no_check(path_absolute: String) -> GDScript:
	var script: GDScript = GDScript.new()
	script.source_code = FileAccess.get_file_as_string(path_absolute)
	script.take_over_path(path_absolute)
	script.reload()
	return script
	#return ResourceLoader.load(path_absolute,"",ResourceLoader.CACHE_MODE_REPLACE)

##Calls a function in the script, returning a [Variant] that the function returns.
static func callScript(script: Variant,function: StringName = &'', parameters: Variant = null) -> Variant:
	script = _get_script(script); if !script: return
	return _call_script_no_check(script,function,parameters)

##Calls a function for every script created.
static func callOnScripts(function: StringName, parameters: Variant = null) -> Variant:
	var func_args = method_list.get(function); if !func_args: return
	for i in func_args: _call_script_no_check(i,function,parameters)
	return


##Calls a function for every script created.[br]
##returns a [Array] with the values returned from each call.
static func callOnScriptsWithReturn(function: StringName, parameters: Variant = null) -> Array:
	var func_args = method_list.get(function); if !func_args: return []
	var returns: Array = []
	for i in func_args: returns.append(_call_script_no_check(i,function,parameters))
	return returns


static func _get_script(script: Variant) -> Object:
	if script is Object: return script 
	return scriptsCreated.get(_script_path(script))

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
##Returns a [Color] using a [Array][[color=red]r[/color], [color=green]g[/color], [color=blue]b[/color]]:
##Example:[codeblock]
##getColorFromArray([255,255,255], true)# Returns Color.WHITE (Color(1,1,1))
##getColorFromArray([1,1,1], false) #Also returns Color.WHITE (Color(1,1,1))
##getColorFromArray([255,0,0])# Returns Color(1,0,0)
##[/codeblock]
static func getColorFromArray(array: Array, divided_by_255: bool = true) -> Color:
	return Color(array[0]/255.0,array[1]/255.0,array[2]/255.0) if divided_by_255 else Color(array[0],array[1],array[2])

##Returns a [Color] using his name:
##[codeblock]
##getColorFromName('BLACK') #Returns Color.BLACK (Color(0,0,0))
##[/codeblock]
static func getColorFromName(color_name: String, default: Color = Color.WHITE) -> Color: return Color.from_string(color_name.to_lower(),default)
#endregion



#region Internal Methods
#region Signals
static func _beat_hit() -> void: curBeat = Conductor.beat; callOnScripts(&'onBeatHit')
static func _step_hit() -> void: curStep = Conductor.step; callOnScripts(&'onStepHit')
static func _section_hit() -> void: curSection = Conductor.section;callOnScripts(&'onSectionHit')
#endregion

static func _insert_script(script: Object, path: String = '') -> bool:
	var inserted = super._insert_script(script,path)
	if inserted: init_gd()
	return inserted

static func _clear_scripts(absolute: bool = false):
	super._clear_scripts(absolute)
	if !started: return
	started = false
	debugMode = false
	for i in Conductor_Signals: Conductor[i].disconnect(Conductor_Signals[i])
#endregion
