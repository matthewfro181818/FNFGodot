@icon("res://icons/icon.png")
##A Character 2D Class
class_name Character extends FunkinSprite

const NoteHit = preload("uid://dx85xmyb5icvh")
const Song = preload("uid://cerxbopol4l1g")
enum Type{
	BOYFRIEND,
	OPPONENT,
	GF
}
@export var curCharacter: StringName: set = loadCharacter ##The name of the character json.

##how many beats should pass before the character dances again.[br][br]For example: 
##If it's [code]2[/code], 
##the character will dance every second beat. If it's [code]1[/code], they dance on every beat.

#region Dance Variables
var danceEveryNumBeats: int = 2

var danceAfterHold: bool = true ##If [code]false[/code], the character will not return to the idle anim.
var forceDance: bool ##If [code]true[/code], the dance animation will be reset every beat hit, making character dance even though the animation hasn't finished.
var danceOnAnimEnd: bool ##If [code]true[/code],the character will dance when a "sing" animation ends.
var autoDance: bool = true ##If [code]false[/code], the character will not return to dance while pressing the sing keys.
var hasDanceAnim: bool: set = set_has_dance_anim ##If character have "danceLeft" or "danceRight" animation.
var danced: bool ##Used to make the "danceLeft/danceRight" animation.

var holdLimit: float = 1.0: set = set_hold_limit ##The time limit to return to idle animation.
var singDuration: float = 4.1: set = set_sing_duration ##The duration of the sing animations.
var _real_hold_limit: float = singDuration
var holdTimer: float ##The time the character is in singing animation.
var heyTimer: float ##The time the character is in the "Hey" animation.
#endregion
var _images: Dictionary[StringName,Texture2D]

var stunned: bool = false

#region Animation Variables
var animationsArray:
	get(): return animation.animationsArray

var specialAnim: bool ##If [code]true[/code], the character will not return to dance while the current animation ends.
var hasMissAnimations: bool ##If the character have any miss animation, used to play a miss animation when miss a note.

##If is not blank, it will be added to the "idle" animation name, for example:[codeblock]
##var character = Character.new()
##character.dance() #Will play "idle" animation(if not has "danceLeft" or "danceRight" anim).
##
##character.idleSuffix = '-alt'
##character.dance() #Will play "idle-alt" animation
##
##character.idleSuffix = '-alt2'
##character.dance() #Will play "idle-alt2"
##[/codeblock]
var idleSuffix: String

var _flipped_sing_anims: bool
#endregion

#region Data Variables
var healthIcon: String ##The Character Icon
var healthBarColors: Color = Color.WHITE ##The color of the character bar.

var isPlayer: bool: set = set_is_player ##If is a player character.
var isGF: bool ##If this is a "[u]GF[/u]" character.

var positionArray: Vector2 ##The character position offset.
var cameraPosition: Vector2 ##The camera position offset.

var json: Dictionary = getCharacterBaseData() ##The character json. See also [method loadCharacter]
var jsonScale: float = 1. ##The Character Scale from his json.
#endregion

var origin_offset: Vector2
func _init():
	super._init(true)
	animation.auto_loop = true
	animation.animation_finished.connect(
		func(_anim): if specialAnim or danceOnAnimEnd and _anim.begins_with('sing'): dance();
	)

func _ready() -> void: Conductor.bpm_changes.connect(updateBPM)

func _enter_tree() -> void: updateBPM()

func updateBPM(): ##Update the character frequency.
	holdLimit = (Conductor.stepCrochet * (0.0011 / Conductor.music_pitch))
	_update_dance_animation_speed()
	
const dance_anim: Array = [&'danceLeft',&'danceRight']
func _update_dance_animation_speed():
	if !hasDanceAnim: return
	for i in dance_anim:
		var animData = animation.getAnimData(i)
		if !animData: continue
		var anim_length = 1.0/animData.fps * animData.frames.size()
		animData.speed_scale = clamp(anim_length/(Conductor.crochet*0.007),1.0,3.0)
#region Character Data

func loadCharacter(char_name: StringName) -> Dictionary: ##Load Character. Returns a [Dictionary] with the json found data.
	if char_name and char_name == curCharacter: return json
	var new_json: Dictionary = Paths.character(char_name); 
	if not new_json: char_name = &'bf'; new_json = Paths.character('bf')
	
	if !new_json:
		_clear()
		curCharacter = &''
		return new_json
	
	loadCharacterFromJson(new_json)

	curCharacter = char_name
	return json

func loadCharacterFromJson(new_json: Dictionary[StringName,Variant]):
	_clear()
	json.merge(new_json,true)
	
	image.texture = Paths.texture(json.assetPath)
	if image.texture: _images[json.assetPath] = image.texture
	
	loadData()
	reloadAnims()
	
	return json

func loadData():
	var health_color = json.healthbar_colors
	healthBarColors = Color(
		health_color[0]/255.0,
		health_color[1]/255.0,
		health_color[2]/255.0
	)
	healthIcon = json.healthIcon.id
	imageFile = json.assetPath
	antialiasing = !json.isPixel
	positionArray = VectorUtils.array_to_vec(json.offsets)
	cameraPosition = VectorUtils.array_to_vec(json.camera_position)
	jsonScale = json.scale
	offset_follow_flip = json.offset_follow_flip
	offset_follow_scale = json.offset_follow_scale
	origin_offset = VectorUtils.array_to_vec(json.origin_offset)

	scale = Vector2(jsonScale,jsonScale)
	danceAfterHold = json.danceAfterHold
	danceOnAnimEnd = json.danceOnAnimEnd
	_update_character_flip()
	
func getCameraPosition() -> Vector2: 
	var pos = getMidpoint()
	if isGF: return getMidpoint() + cameraPosition 
	if isPlayer:  
		pos.x += -100 - cameraPosition.x
		pos.y += -100 + cameraPosition.y
		return pos
	pos.x += 150 + cameraPosition.x
	pos.y += -100 + cameraPosition.y
	return getMidpoint() + Vector2(150,-100) + cameraPosition
#endregion

func _process(delta) -> void:
	super._process(delta)
	if specialAnim or !animation.current_animation.begins_with('sing'): return
	
	if holdTimer < _real_hold_limit: holdTimer += delta
	elif danceAfterHold and (autoDance or !InputUtils.is_any_actions_pressed(NoteHit.getInputActions())):
		dance()

#region Character Animation
##Reload the character animations, used also in Character Editor.
func reloadAnims():
	var has_dance_anim: bool = false
	animation.clearLibrary()
	
	danceEveryNumBeats = 2
	hasMissAnimations = false
	animation.animations_use_textures = false
	
	for anims in json.animations:
		var animName: StringName = anims.name
		if _flipped_sing_anims:
			if animName.begins_with('singLEFT'): animName = 'singRIGHT'+animName.right(-8)
			elif animName.begins_with('singRIGHT'): animName = 'singLEFT'+animName.right(-9)
		
		if !has_dance_anim: has_dance_anim = (animName == &'danceLeft' or animName == &'danceRight')
		
		if !hasMissAnimations: hasMissAnimations = animName.ends_with('miss')
		
		
		addCharacterAnimation(
			animName,
			{
				&'prefix': anims.prefix,
				&'fps': anims.get('fps',24.0),
				&'looped': anims.get('looped',false),
				&'indices': anims.get('frameIndices',[]),
				&'asset': anims.get('assetPath',json.assetPath)
			}
		)
		addAnimOffset(animName,anims.offsets)
		animation.setLoopFrame(animName,anims.get('loop_frame',0))
	hasDanceAnim = has_dance_anim

func flip_sing_animations() -> void:
	for i in animationsArray.keys():
		if !i.begins_with('singLEFT'): continue
		var left_data = animation.animationsArray[i]
		var right_name = 'singRIGHT'+i.right(-8)
		var right_data = animation.animationsArray.get(right_name)
		if right_data: addCharacterAnimation(i,right_data)
		else: animation.animationsArray.erase(i)
		addCharacterAnimation(right_name,left_data)
	_flipped_sing_anims = !_flipped_sing_anims
	animation.update_anim()

func addCharacterAnimation(animName: StringName,anim_data: Dictionary[StringName,Variant]):
	var tex = anim_data.get(&'asset',&'')
	if tex is String: tex = addCharacterImage(tex); anim_data.asset = tex
	
	if tex: _add_animation_from_data(animName,anim_data,tex)
	else: for i in _images.values(): if _add_animation_from_data(animName,anim_data,i): break
	return anim_data

func _add_animation_from_data(animName: String,animData: Dictionary[StringName,Variant], asset: Texture) -> Dictionary:
	var prefix = animData.get(&'prefix')
	if !prefix: return {}
	
	var indices = animData.get(&'indices')
	var asset_file = AnimationService.findAnimFile(asset.resource_name)
	var anim_frames: Array = animation.getFramesFromPrefix(animData.prefix,indices,asset_file)
	
	if !anim_frames: return {}
	animData.frames = anim_frames
	return animation.insertAnim(animName,animData)

func addCharacterImage(path) -> Texture2D:
	if path is Texture2D: return
	if !path: path = json.assetPath
	if _images.has(path): return _images[path]
	var asset = Paths.texture(path)
	if !asset: return null
	_images[path] = asset
	animation.setup_animation_textures()
	return asset
#endregion

#region Dance Methods
func dance() -> void: ##Make character returns to his dance animation.
	if not hasDanceAnim: animation.play('idle'+idleSuffix,forceDance)
	else: animation.play(&'danceRight' if danced else &'danceLeft',forceDance); danced = !danced
	holdTimer = 0.0
	specialAnim = false

func _check_dance_anim(anim_name: StringName) -> void:
	if anim_name.begins_with('singLEFT'): danced = false
	elif anim_name.begins_with('singRIGHT'): danced = true
#endregion


func _update_hold_limit() -> void: _real_hold_limit = holdLimit*singDuration

#region Setters
func set_hold_limit(limit: float) -> void: holdLimit = limit; _update_hold_limit()
func set_sing_duration(duration: float) -> void: singDuration = duration; _update_hold_limit()
func set_is_player(isP: bool): 
	isPlayer = isP; 
	_update_character_flip()

func _update_character_flip(): flipX = !json.flipX if isPlayer else json.flipX

func set_pivot_offset(pivot: Vector2): pivot += origin_offset; super.set_pivot_offset(pivot)

func set_has_dance_anim(has: bool):
	if hasDanceAnim == has: return
	hasDanceAnim = has
	
	var anim_signal = animation.animation_started
	if has: 
		danceEveryNumBeats = 1
		if !anim_signal.is_connected(_check_dance_anim): anim_signal.connect(_check_dance_anim)
	else:
		danceEveryNumBeats = 2
		if anim_signal.is_connected(_check_dance_anim): anim_signal.disconnect(_check_dance_anim)
	
func flip_h(flip: bool = flipX) -> void:
	if flipX == flip: return
	super.flip_h(flip)
	if json.sing_follow_flip: flip_sing_animations()
#endregion

func _clear() -> void:
	animation.clearLibrary()
	_animOffsets.clear()
	_images.clear()
	json.clear()
	json.assign(getCharacterBaseData())

#region Static Methods
static func create_from_name(json_name: String, type: Type = Type.OPPONENT) -> Character:
	var script = FunkinGD.loadScript('characters/'+json_name+'.gd')
	var char: Character = script.new() if script else Character.new()
	prints(json_name,type,Type.BOYFRIEND)
	char.loadCharacter(json_name)
	char.isPlayer = type == Type.BOYFRIEND
	char.isGF = type == Type.GF
	return char

static func _convert_psych_to_original(json: Dictionary) -> Dictionary[StringName,Variant]:
	var new_json: Dictionary[StringName,Variant] = getCharacterBaseData()
	
	var anims: Array = json.get(&'animations')
	json.erase(&'animations')
	for i in anims:
		var anim = getAnimBaseData()
		
		DictUtils.convertKeysToStringNames(i)
		DictUtils.merge_existing(anim,i)
		if i.has(&'indices'): anim.frameIndices = i.indices
		if i.has(&'loop'): anim.looped = i.loop
		if i.has(&'anim'):  anim.name = i.anim; if i.has(&'name'): anim.prefix = i.name
		
		anim.offsets = PackedFloat32Array(i.get(&'offsets',[0,0]))
		anim.fps = i.get(&'fps',24.0)
		new_json.animations.append(anim)
	
	new_json.offsets = json.get(&'position',[0,0])
	new_json.flipX = json.get(&'flip_x',false)
	new_json.healthbar_colors = json.get(&"healthbar_colors",PackedByteArray([255,255,255]))
	new_json.assetPath = json.get(&'image','')
	new_json.singTime = json.get(&'sing_duration',4.0)*2.0
	new_json.isPixel = json.get(&'no_antialiasing',false)
	
	var icon = json.get(&'healthicon',&'icon-face')
	new_json.healthIcon.id = StringName(icon)
	new_json.healthIcon.isPixel = icon.ends_with('-pixel')
	new_json.camera_position = json.get(&'camera_position',[0,0])
	new_json.scale = json.get(&'scale',1.0)
	
	DictUtils.merge_existing(new_json,json)
	return new_json


func _property_get_revert(property: StringName) -> Variant: #Used in ModchartEditor
	match property:
		&'scale': return Vector2(jsonScale,jsonScale)
	return super._property_get_revert(property)
	
	
static func getCharacterBaseData() -> Dictionary[StringName,Variant]: ##Returns a base to character data.
	return {
		&"animations": [],
		&"isPixel": false,
		&"offsets": [0,0],
		&"camera_position": [0,0],
		&"assetPath": "",
		&"healthbar_colors": [255,255,255],
		&"healthIcon": {
			&"id": "icon-face",
			&"isPixel": false,
			&'canScale': false
		},
		&"flipX": false,
		&"singTime": 4.0,
		&"scale": 1,
		&"origin_offset": [0,0],
		&"offset_follow_flip": false,
		&'offset_follow_scale': false,
		&'sing_follow_flip': false,
		&'danceAfterHold': true,
		&'danceOnAnimEnd': false,
	}

static func getCharactersList(return_jsons: bool = false) -> Variant:
	if !return_jsons: return Paths.getFilesAt('characters',false,'.json')
	var directory = {}
	for i in Paths.getFilesAt('characters',true,'.json'): 
		directory[i.get_file().left(-5)] = Paths.loadJson(i)
	return directory
	
static func getAnimBaseData() -> Dictionary[StringName,Variant]: ##Returns a base for the character animation data.
	return {
		&'name': &'',
		&'prefix': &'',
		&'fps': 24,
		&'loop_frame': 0,
		&'looped': false,
		&'frameIndices': PackedFloat32Array(),
		&'offsets': [0,0],
		&'assetPath': ''
	}
#endregion
