#@icon("res://icons/splash.png")
extends FunkinSprite

const Note = preload("uid://deen57blmmd13")
const NoteStyleData = preload("uid://by78myum2dx8h")
const NoteSplash = preload("res://source/objects/Notes/NoteSplash.gd")

const SplashOffset = Vector2(100,100)
static var splash_datas: Dictionary[StringName,Dictionary]
static var mosaicShader: Material

enum SplashType{
	NORMAL,
	HOLD_COVER,
	HOLD_COVER_END
}
var texture: StringName ## Splash Texture

var direction: int ##Splash Direction
var isPixelSplash: bool: set = _set_pixel ##If is a [u]pixel[/u] splash.

@warning_ignore("unused_private_class_variable")
var _is_custom_parent: bool #Used in StrumState.


var strum: Node ##The Splash strum.

var splash_scale: Vector2 = Vector2.ZERO ##Splash scale.

var splashType: SplashType = SplashType.NORMAL
var splashData: Dictionary

func _init():
	super._init(true)
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed(): set_process(visible); if visible: _update_position()

func _set_pixel(isPixel: bool):
	if isPixel == isPixelSplash: return
	isPixelSplash = isPixel
	
	if isPixel:
		if !mosaicShader: mosaicShader = Paths.loadShader('MosaicShader')
		material = mosaicShader
		if material: material.set_shader_parameter(&'strength',6.0)
	else: material = null

##Add animation to splash. Returns [code]true[/code] if the animation as added successfully.
func loadSplash(style: StringName,type: SplashType, prefix: StringName = &'default') -> bool:
	splashType = type
	match type:
		SplashType.HOLD_COVER,SplashType.HOLD_COVER_END: 
			splashData = NoteStyleData.getStyleData(style,NoteStyleData.StyleType.HOLD_SPLASH)
		_: splashData = NoteStyleData.getStyleData(style,NoteStyleData.StyleType.SPLASH)

	if !splashData: return false
	addSplashAnimation(self,prefix)
	var _splash_scale = splashData.get(&'scale',1.0)
	scale = Vector2(_splash_scale,_splash_scale)
	return true

func _process(_d) -> void:
	super._process(_d)
	if !visible or splashType != SplashType.HOLD_COVER or !strum: return
	followStrum()
	if strum.mustPress: visible = Input.is_action_pressed(strum.hit_action)

func followStrum() -> void:
	modulate.a = strum.modulate.a
	if splashType == SplashType.HOLD_COVER: rotation = strum.rotation
	_position = strum._position


static func getSplashTypeFromNote(note: Note) -> SplashType:
	if !note.isSustainNote: return SplashType.NORMAL
	return SplashType.HOLD_COVER_END if note.isEndSustain else SplashType.HOLD_COVER

static func addSplashAnimation(splash: NoteSplash,prefix: StringName):
	var data = splash.splashData.data.get(prefix)
	if !data: data = splash.splashData.data.get(&'default'); if !data: return
	if data is Array: data = data.pick_random()
	
	var asset = data.get(&'assetPath')
	if !asset: asset = splash.splashData.assetPath; if !asset: return false
	
	splash.image.texture = Paths.texture(asset)
	
	if !splash.image.texture: return false
	
	var offsets = splash.splashData.get(&'offsets',Vector2.ZERO)
	match splash.splashType:
		SplashType.NORMAL:
			var prefix_anim = data.prefix
			if !prefix_anim: return false
			splash.animation.addAnimByPrefix(&'splash',prefix_anim,24.0,false)
			splash.addAnimOffset(&'splash',data.get(&'offsets',offsets)+SplashOffset)
		
		SplashType.HOLD_COVER:
			var start_data = data.get(&'start')
			if start_data:
				var sprefix = start_data.get(&'prefix')
				if sprefix:
					splash.animation.addAnimByPrefix(&'splash',sprefix,24.0,false)
					splash.animation.auto_loop = true
					splash.addAnimOffset(&'splash',start_data.get(&'offsets',offsets))
			
			var hold_data = data.get(&'hold')
			if hold_data:
				var hprefix = hold_data.get(&'prefix')
				if !hprefix: return
				splash.animation.addAnimByPrefix(&'splash-hold',hprefix,24.0,true)
				splash.addAnimOffset(&'splash-hold',hold_data.get(&'offsets',offsets))
		SplashType.HOLD_COVER_END:
			var end_data = data.get(&'end')
			if !end_data: return false
			splash.animation.addAnimByPrefix(&'splash',end_data.prefix,24.0,false)
			splash.addAnimOffset(&'splash',end_data.get(&'offsets',offsets))
	return true
