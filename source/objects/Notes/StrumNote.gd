@icon("res://icons/StrumNote.png")
extends FunkinSprite ##Strum Note

const NoteStyleData = preload("uid://by78myum2dx8h")
const Song = preload("uid://cerxbopol4l1g")
const NoteHit = preload("uid://dx85xmyb5icvh")
const default_offset: Vector2 = Vector2.ZERO

##Strum Direction
##[br][param 0: left, 1: down, 2: up, 3: right]
@export var data: int;

##Direction of the note in radius. [br]
##Example: [code]deg_to_rad(90)[/code] makes the notes come from the left,
##while [code]deg_to_rag(180)[/code] makes come from the top.[br]
##[b]Obs:[/b] If [param downscroll] is [code]true[/code], the direction is inverted.
var direction: float:
	set(value): direction = value; _direction_radius = deg_to_rad(value)
var _direction_radius: float:
	set(value): _direction_radius = value; _direction_lerp = Vector2(cos(value),sin(value))

var _direction_lerp: Vector2 = Vector2(0,1) #Used in Notes.gd

var mustPress: bool ##Player Strum
var hit_action: StringName ##Hit Key

var return_to_static_on_finish: bool = true

@export var default_scale: float = 0.7

@export var isPixelNote: bool ##Pixel Note
##The [Input].action_key of the note, see [method Input.is_action_just_pressed]


var styleName: String: set = setStrumStyleName
var styleData: Dictionary

var texture: String: set = setTexture ##Strum Texture
var specialAnim: bool ##If [code]true[/code], make the strum don't make to Static anim when finish's animation

var downscroll: bool: set = setDownscroll ##Invert the note direction.

var multSpeed: float = 1.0: set = setMultSpeed ##The note speed multiplier.

## Time used to determine when the strum should return to the 'static' animation after being hit.
## When this reaches 0, the 'static' animation is played.
var hitTime: float = 0.0

signal mult_speed_changed
func _init(dir: int = 0):
	"""
	shader = rgbShader
	rgbShader.r = ClientPrefs.arrowRGB[dir][0]
	rgbShader.g = ClientPrefs.arrowRGB[dir][1]
	rgbShader.b = ClientPrefs.arrowRGB[dir][2]
	rgbShader.next_pass = testShader
	"""
	super._init(true)
	data = dir
	hit_action = NoteHit.getInputActions()[dir]
	
	offset_follow_scale = true
	offset_follow_rotation = true
	animation.animation_finished.connect(_on_animation_finished)
const _anim_direction: PackedStringArray = ['left','down','up','right']

func reloadStrumNote() -> void: ##Reload Strum Texture Data
	_animOffsets.clear()
	offset = Vector2.ZERO
	image.texture = Paths.texture(texture)
	antialiasing = !isPixelNote
	
	if styleData and styleData.data: _load_anims_from_prefix()
	else: _load_graphic_anims()
	setGraphicScale(Vector2(default_scale,default_scale))

func _load_anims_from_prefix() -> void:
	var type = _anim_direction[data]
	
	var static_anim = styleData.data[type+'Static']
	var press_anim = styleData.data[type+'Press']
	var confirm_anim = styleData.data[type+'Confirm']
	animation.addAnimByPrefix(&'static',static_anim.prefix,24,true)
	animation.addAnimByPrefix(&'press',press_anim.prefix,24,false)
	animation.addAnimByPrefix(&'confirm',confirm_anim.prefix,24,false)
	
	var confirm_offset = confirm_anim.get(&'offsets',default_offset)
	addAnimOffset(&'confirm',confirm_offset)
	
	var press_offset = press_anim.get(&'offsets',default_offset)
	addAnimOffset(&'press',press_offset)
	
	var static_offset = static_anim.get(&'offsets',default_offset)
	addAnimOffset(&'static',static_offset)

func _load_graphic_anims() -> void:
	var keyCount: int = Song.keyCount
	image.region_rect.size = imageSize/Vector2(keyCount,5)
	animation.addFrameAnim(&'static',[data])
	animation.addFrameAnim(&'confirm',[data + (keyCount*3),data + (keyCount*4),data + keyCount])
	animation.addFrameAnim(&'press',[data + (keyCount*3),data + (keyCount*2)])

func loadFromStyle(noteStyle: String):
	styleName = noteStyle
	if !styleData: return
	
	isPixelNote = styleData.get('isPixel',false)
	default_scale = styleData.get('scale',0.7)
	texture = styleData.assetPath

func _on_texture_changed() -> void: super._on_texture_changed(); animation.clearLibrary()

#region Setters
func setTexture(_texture: String) -> void: texture = _texture;reloadStrumNote()

func setStrumStyleName(_name: String) -> void:
	styleName = _name
	styleData = NoteStyleData.getStyleData(_name,&'strums')

func setMultSpeed(speed: float) -> void:
	if speed == multSpeed: return
	multSpeed = speed
	mult_speed_changed.emit()

func setDownscroll(down: bool) -> void:
	downscroll = down
	mult_speed_changed.emit()
#endregion


func strumConfirm(anim: StringName = &'confirm'):
	animation.play(anim,true)
	hitTime = Conductor.stepCrochet/1000.0
	return_to_static_on_finish = true

func _process(delta: float) -> void:
	super._process(delta)
	if mustPress:
		if animation.current_animation == &'static' and Input.is_action_just_pressed(hit_action): animation.play(&'press',true)
		elif Input.is_action_just_released(hit_action): animation.play(&'static')
		return
	if hitTime:
		hitTime -= delta
		if hitTime <= 0.0: hitTime = 0.0; animation.play(&'static')

func _on_animation_finished(anim: StringName):
	if anim != &'static' and return_to_static_on_finish and !mustPress: animation.play(&'static')
func _property_can_revert(property: StringName) -> bool:
	match property:
		&'data',&'styleData': return false
	return true

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&'direction': return 0.0
		&'multSpeed': return 1.0
		&'mustPress': return false
		&'scale': return Vector2(default_scale,default_scale)
	return null
