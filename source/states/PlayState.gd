extends "res://source/states/PlayStateBase.gd"

@export var boyfriend: Character
@export var dad: Character
@export var gf: Character

static var boyfriendCameraOffset: Vector2 = Vector2.ZERO
static var girlfriendCameraOffset: Vector2 = Vector2.ZERO
static var opponentCameraOffset: Vector2 = Vector2.ZERO


var camFollow: Vector2
var camFollowPosition: bool = true
var camGame: FunkinCamera = FunkinCamera.new()
var cameras: Array[FunkinCamera] = [camGame,camHUD,camOther]
@export_category('Groups')
var boyfriendGroup: SpriteGroup = SpriteGroup.new() #Added in Stage.loadSprites()
var dadGroup: SpriteGroup = SpriteGroup.new()# Added in Stage.loadSprites()
var gfGroup: SpriteGroup = SpriteGroup.new()# Also added in Stage.loadSprites()

@export_category('Game Over')
const GameOverSubstate = preload("uid://clemxsqclutjh")

func _ready():
	add_child(camGame)
	camGame.name = &'camGame'
	
	boyfriendGroup.name = &'boyfriendGroup'
	dadGroup.name = &'dadGroup'
	gfGroup.name = &'gfGroup'
	
	Stage.charactersGroup = {
		&'bf': boyfriendGroup,
		&'dad': dadGroup,
		&'gf': gfGroup
	}
	super._ready()

#Set GameOverState
func loadSongObjects():
	if isPixelStage:
		GameOverSubstate.characterName = 'bf-pixel'
		GameOverSubstate.opponentName = 'bf-pixel'
		GameOverSubstate.deathSoundName = 'gameplay/gameover/fnf_loss_sfx-pixel'
		GameOverSubstate.loopSoundName = 'gameplay/gameover/gameOver-pixel'
		GameOverSubstate.endSoundName = 'gameplay/gameover/gameOverEnd-pixel'
	else:
		GameOverSubstate.characterName = 'bf'
		GameOverSubstate.opponentName = 'bf'
		GameOverSubstate.deathSoundName = 'gameplay/gameover/fnf_loss_sfx'
		GameOverSubstate.loopSoundName = 'gameplay/gameover/gameOver'
		GameOverSubstate.endSoundName = 'gameplay/gameover/gameOverEnd'
	super.loadSongObjects()

func destroy(absolute: bool = true): super.destroy(absolute); camGame.removeFilters()

func gameOver():
	var state = GameOverSubstate.new()
	state.scale = Vector2(camGame.zoom,camGame.zoom)
	state.transform = camGame.scroll_camera.transform
	state.isOpponent = playAsOpponent
	state.character = dad if playAsOpponent else boyfriend
	Global.scene.add_child(state)
	for cams in cameras: cams.visible = false
	super.gameOver()

func loadStage(stage: StringName,loadScript: bool = true):
	super.loadStage(stage,loadScript)
	
	boyfriendCameraOffset = VectorUtils.array_to_vec(stageJson.characters.bf.cameraOffsets)
	girlfriendCameraOffset = VectorUtils.array_to_vec(stageJson.characters.gf.cameraOffsets)
	opponentCameraOffset = VectorUtils.array_to_vec(stageJson.characters.dad.cameraOffsets)
	
	defaultCamZoom = stageJson.cameraZoom
	cameraSpeed = stageJson.cameraSpeed
	camGame.zoom = defaultCamZoom
	
	boyfriendGroup.x = stageJson.characters.bf.position[0]
	boyfriendGroup.y = stageJson.characters.bf.position[1]
	dadGroup.x = stageJson.characters.dad.position[0]
	dadGroup.y = stageJson.characters.dad.position[1]
	gfGroup.x = stageJson.characters.gf.position[0]
	gfGroup.y = stageJson.characters.gf.position[1]
	
	if stageJson.get('hide_girlfriend'): gfGroup.visible = false
	else: gfGroup.visible = true
	
	
	if stageJson.get('hide_boyfriend'): boyfriendGroup.visible = false
	else:  boyfriendGroup.visible = true
	moveCamera(detectSection())
	
func _process(delta: float) -> void:
	if camZooming: camGame.zoom = lerpf(camGame.zoom,camGame.defaultZoom,delta*3*zoomSpeed)
	super._process(delta)
	if camFollowPosition: camGame.scroll = camGame.scroll.lerp(camFollow-ScreenUtils.screenCenter, cameraSpeed*delta*3.5)

func onBeatHit(beat: int = Conductor.beat) -> void:
	for character in [dad,boyfriend,gf]:
		if !character or character.specialAnim or character.holdTimer > 0 or character.heyTimer > 0: continue
		if fmod(beat,character.danceEveryNumBeats) == 0.0: character.dance()
	super.onBeatHit(beat)

func insertCharacterInGroup(character: Character,group: SpriteGroup) -> void:
	if !character or !group: return
	character._position = Vector2(group.x,group.y) + character.positionArray
	group.add(character,true)

func addCharacterToList(charFile: String, type: Character.Type = Character.Type.BOYFRIEND) -> Character:
	var group
	var charType: StringName = &'boyfriend'
	match type:
		1: group = dadGroup; charType = &'dad'
		2: group = gfGroup; charType = &'gf'
		_: group = boyfriendGroup
		
	if !Paths.file_exists('characters/'+charFile+'.json'): charFile = 'bf'
	
	#Check if the character is already created.
	for chars in group.members: if chars and chars.curCharacter == charFile: return chars
	
	var newCharacter: Character = Character.create_from_name(charFile,type)
	newCharacter.set_position(newCharacter.get_position() + newCharacter.positionArray)
	newCharacter.name = charType
	
	if group: group.add(newCharacter,false)
	
	Paths.image(newCharacter.healthIcon)
	FunkinGD.callOnScripts(&'onLoadCharacter',[newCharacter,charType])
	insertCharacterInGroup(newCharacter,group)
	newCharacter.visible = false
	newCharacter.process_mode = Node.PROCESS_MODE_DISABLED
	return newCharacter


func preHitNote(note: Note, character: Variant = getCharacterNote(note)):  super.preHitNote(note,character)

func hitNote(note: Note, character: Variant = getCharacterNote(note)): super.hitNote(note,character)

func signCharacter(character: Character, note: Note):
	if !character or character.stunned: return
	var mustPress: bool = note.mustPress
	var target = boyfriend if mustPress else dad
	var gfNote = note.gfNote or (gfSection and mustPress == mustHitSection)
	var character_auto_dance: bool = not (mustPress != playAsOpponent and not botplay)
	
	if gfNote:
		if target: target.autoDance = true
		if gf: gf.autoDance = character_auto_dance
	else:
		if target: target.autoDance = character_auto_dance
		if gf: gf.autoDance = character_auto_dance
	
	var animNote = singAnimations[note.noteData]
	var realAnim = animNote
	var anim_player = character.animation
	var suffix = note.animSuffix
	if altSection and !suffix.ends_with('-alt'): suffix += '-alt'
	if suffix: realAnim += suffix; if !anim_player.has_animation(realAnim): realAnim = animNote
	character.holdTimer = 0.0
	character.heyTimer = 0.0
	character.specialAnim = false
	anim_player.play(realAnim,true)
func noteMiss(note: Note, character: Variant = getCharacterNote(note)):
	if character: character.animation.play(singAnimations[note.noteData]+'miss',true)
	super.noteMiss(note,character)

func moveCamera(target: StringName = 'boyfriend') -> void:
	camFollow = getCameraPos(get(target))
	super.moveCamera(target)

func screenBeat(multi: float = 1.0) -> void:
	camGame.zoom += 0.015 * multi
	super.screenBeat(multi)

func changeCharacter(type: int = 0, character: StringName = 'bf') -> Object:
	var char_name: StringName = get_character_type_name(type)
	var character_obj = get(char_name)
	if character_obj and character_obj.curCharacter == character: return
	
	var group: SpriteGroup = get(char_name+'Group')
	if !group: return
	
	var newCharacter = addCharacterToList(character,type)
	if not newCharacter: return
	
	newCharacter.name = char_name
	newCharacter.holdTimer = 0.0
	newCharacter.visible = true
	newCharacter.process_mode = Node.PROCESS_MODE_INHERIT
	set(char_name,newCharacter)
	
	if character_obj:
		var char_anim = character_obj.animation
		var new_char_anim = newCharacter.animation
		if new_char_anim.has_animation(char_anim.current_animation): 
			new_char_anim.play(char_anim.current_animation)
			new_char_anim.curAnim.curFrame = char_anim.curAnim.curFrame
		else: newCharacter.dance()
		
		newCharacter.material = character_obj.material
		character_obj.material = null
		
		character_obj.visible = false
		character_obj.process_mode = PROCESS_MODE_DISABLED
	else: newCharacter.dance()

	match type:
		0:
			iconP1.reloadIconFromCharacterJson(newCharacter.json)
			healthBar.set_colors(null,newCharacter.healthBarColors)
		1:
			healthBar.set_colors(newCharacter.healthBarColors)
			iconP2.reloadIconFromCharacterJson(newCharacter.json)
	
	updateIconsImage(_healthBar_State)
	FunkinGD.callOnScripts(&'onChangeCharacter',[type,newCharacter,character_obj])
	updateIconsPivot()
	if !isCameraOnForcedPos and detectSection() == char_name: moveCamera(char_name)
	return newCharacter

func clear():
	super.clear()
	camGame.removeFilters()
	
	boyfriendGroup.queue_free_members()
	boyfriend = null
	dadGroup.queue_free_members()
	dad = null
	gfGroup.queue_free_members()
	gf = null

#region Setters
func set_default_zoom(value: float) -> void: super.set_default_zoom(value); camGame.defaultZoom = value;
#endregion

func getCharacterNote(note: Note) -> Character: return gf if note.gfNote else (boyfriend if note.mustPress else dad)

static func getCameraPos(obj: Node) -> Vector2:
	if !obj: return Vector2.ZERO
	var pos: Vector2
	if obj is Character: pos = obj.getCameraPosition() + getCameraOffset(obj)
	elif obj is FunkinSprite: pos = obj.getMidpoint()
	else: pos = obj.position
	return pos

static func getCameraOffset(obj: Character) -> Vector2:
	if obj.isGF: return girlfriendCameraOffset
	if obj.isPlayer: return boyfriendCameraOffset
	else: return opponentCameraOffset
