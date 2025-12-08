#@icon("res://icons/splash.png")
extends FunkinSprite

const Note = preload("uid://deen57blmmd13")
const NoteStyleData = preload("uid://by78myum2dx8h")
const NoteSplash = preload("uid://cct1klvoc2ebg")

const HOLD_ANIMATIONS: Array = [&'start',&'hold',&'end']
static var mosaicShader: Material

var texture: StringName ## Splash Texture

var direction: int ##Splash Direction
var isPixelSplash: bool: set = _set_pixel ##If is a [u]pixel[/u] splash.

@warning_ignore("unused_private_class_variable")
var _is_custom_parent: bool #Used in StrumState.

var strum: Node ##The Splash strum.

var holdSplash: bool

var splashName: StringName
var splashStyle: StringName
var splashPrefix: StringName
var splashData: Dictionary

func _init(): 
	super._init(true)
	animation.animation_finished.connect(_on_animation_finished)
	visibility_changed.connect(_on_visibility_changed)

func _ready() -> void:
	if holdSplash: _update_animation_scale()
	followStrum()

func _on_visibility_changed(): 
	process_mode = PROCESS_MODE_INHERIT if visible else PROCESS_MODE_DISABLED; 
	if visible: followStrum()

func show_splash() -> void:
	visible = true
	if holdSplash: animation.play(&'start',false); _update_animation_scale();
	else: animation.play_random()

func _update_animation_scale() -> void: 
	animation.setAnimDataValue(&'hold',&'speed_scale',minf(1.0 / (Conductor.stepCrochetMs*8.0),3.0))

func _set_pixel(isPixel: bool):
	if isPixel == isPixelSplash: return
	isPixelSplash = isPixel
	
	if isPixel:
		if splashData.get(&'isPixel'): return
		if !mosaicShader: mosaicShader = Paths.loadShader('MosaicShader')
		material = mosaicShader
		if material: material.set_shader_parameter(&'strength',6.0)
	else: material = null


func _on_animation_finished(anim_name: StringName) -> void:
	if !holdSplash: visible = false; return  
	match anim_name:
		&'start': animation.play(&'hold',true)
		&'end': visible = false

func _process(_d) -> void:
	super._process(_d)
	if !visible or !holdSplash or !strum: return
	followStrum()

func followStrum() -> void:
	if !strum: return
	modulate.a = strum.modulate.a
	#if holdSplash: rotation = strum.rotation
	_position = strum._position

##Add animation to splash. Returns [code]true[/code] if the animation as added successfully.
static func loadSplash(style: StringName, splash_name: StringName = &'default', prefix: StringName = &'', holdSplash: bool =false) -> NoteSplash:
	var data = NoteStyleData.getStyleData(style,splash_name,NoteStyleData.StyleType.SPLASH)
	if !data: return
	var splash: NoteSplash = NoteSplash.new()
	splash.splashData = data
	splash.splashStyle = style
	splash.splashName = splash_name
	splash.splashPrefix = prefix
	splash.holdSplash = holdSplash
	if !_load_splash_animation(splash,prefix): return null
	return splash

static func loadSplashFromNote(note: Note) -> NoteSplash: 
	return loadSplash(note.splashStyle,note.splashName,note.splashPrefix,note.isSustainNote)

static func _load_splash_animation(splash: NoteSplash,prefix: StringName) -> bool:
	var data = splash.splashData.data.get(prefix)
	if !data: data = splash.splashData.data.get(&'default'); if !data: return false
	
	if data is Array: data = data.pick_random()
	
	var asset = data.get(&'assetPath')
	
	if !asset: asset = splash.splashData.assetPath; if !asset: return false
	
	splash.image.texture = Paths.texture(asset)
	
	if !splash.image.texture: return false
	
	var offsets = splash.splashData.get(&'offsets',Vector2.ZERO)
	var scale = data.get(&'scale',splash.splashData.get(&'scale',1.0))
	
	if !splash.holdSplash:
		var prefix_anim = data.get(&'prefix'); if !prefix_anim: return false
		splash.animation.addAnimByPrefix(&'splash',prefix_anim,24.0,false)
		splash.offset = data.get(&'offsets',offsets)
		splash.scale = Vector2(scale,scale)
		return true

	for i in HOLD_ANIMATIONS:
		var anim_data = data.get(i)
		if !data: continue
		var sprefix = anim_data.get(&'prefix')
		if !sprefix: continue
		splash.animation.addAnimByPrefix(i,sprefix,24.0,i==&'hold')
		splash.animation.auto_loop = true
		splash.addAnimOffset(i,anim_data.get(&'offsets',offsets))
	return true
