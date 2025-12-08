@abstract
##PlayState Base.
extends "res://source/states/StrumState.gd"

const PauseSubstate = preload("uid://yw07oc1elhfb")

const Bar = preload("uid://cesg7bsxvgdcm")
const Stage = preload("uid://dh7syegxufdht")

const CharacterEditor = preload("uid://droixhbemd0xd")
const ChartEditorScene = preload("uid://eonsf5cks44n")

const FunkinVideo = preload("uid://w8ju6w7jofop")


static var back_state = preload("uid://dbcawd2so03ht")

enum IconState{NORMAL,LOSING,WINNING}

@export_group('Camera')
var camHUD: FunkinCamera = FunkinCamera.new()
var camOther: FunkinCamera = FunkinCamera.new()

var cameraSpeed: float = 1.0
var zoomSpeed: float = 1.0

var isCameraOnForcedPos: bool = false
var defaultCamZoom: float = 1.0: set = set_default_zoom

@export_group('Play Options')
var altSection: bool = false

var health: float: set = set_health

@export var singAnimations: Array = [&"singLEFT",&"singDOWN",&"singUP",&"singRIGHT"]

@export var bumpStrumBeat: float = 4.0 ##The amount of beats for the camera to give a "beat" effect.
@export var canExitSong: bool = true
@export var canPause: bool = true
@export var createPauseMenu: bool = true
@export var canGameOver: bool = true
var onPause: bool

var inGameOver: bool
var camZooming: bool ##If [code]true[/code], the camera make a beat effect every [member bumpStrumBeat] beats and the zoom will back automatically.

#region Scripts
var curStage: StringName
var stageJson: Dictionary = Stage.getStageBase()

@export_subgroup('Scripts')
@export var loadScripts: bool = true
@export var loadStageScript: bool = true
@export var loadSongScript: bool = true

@export_subgroup('Events')
@export var loadEvents: bool = true
@export var generateEvents: bool = true
static var eventNotes: Array[Dictionary]
var eventIndex: int = 0
static var _is_first_event_load: bool = true
#endregion

@export_group("Countdown Options")
@export var countDownEnabled: bool = true
@export var countSounds = ['introTHREE','introTWO','introONE','introGO']
@export var countDownImages = ['','ready','set','go']
var _countdown_started: bool
var skipCountdown: bool

#region Gui
@export_group("Hud Elements")
@export var hideHud: bool = ClientPrefs.data.hideHud: set = _set_hide_hud

var _healthBar_State: IconState = IconState.NORMAL
var healthBar: Bar = Bar.new('healthBar')

#region Icons
const Icon := preload("res://source/objects/UI/Icon.gd")
var iconP1: Icon = Icon.new()
var iconP2: Icon = Icon.new()
var icons: Array[Icon] = [iconP1,iconP2]
var _icons_cos_sin: Vector2 = Vector2(1,0)
#endregion

#endregion


@export_group('Objects')
var pauseState: PauseSubstate

#region Game Options
@export_category('Story Mode')
var story_song_notes: Dictionary
var story_songs: PackedStringArray
var isStoryMode: bool
#endregion

@export_category("Song Data")
var songName: StringName

@export_category("Cutscene")
var seenCutscene: bool
var skipCutscene: bool = true
var inCutscene: bool
var videoPlayer: VideoStreamPlayer

var introSoundsSuffix: StringName

var stateLoaded: bool #Used in FunkinGD
func _ready():
	Global.onSwapTree.connect(destroy,CONNECT_ONE_SHOT)
	name = 'PlayState'
	FunkinGD.game = self
	camHUD.name = &'camHUD'
	camHUD.bg.modulate.a = 0.0
	
	camOther.name = &'camOther'
	camOther.bg.modulate.a = 0.0
	add_child(camHUD)
	add_child(camOther)
	
	
	super._ready()
	health = 1.0
	
	if !isCameraOnForcedPos: moveCamera(detectSection())
	#Set Signals
	Conductor.beat_hit.connect(onBeatHit)
	Conductor.section_hit.connect(onSectionHit)
	Conductor.section_hit_once.connect(onSectionHitOnce)
	FunkinGD.callOnScripts(&'onCreatePost')
	stateLoaded = true
	startCountdown()

func _process(delta: float) -> void:
	if camZooming: camHUD.zoom = lerpf(camHUD.zoom,camHUD.defaultZoom,delta*3*zoomSpeed)
	
	_check_count_down_pos(delta)
	FunkinGD.callOnScripts(&'onUpdate',[delta])
	
	super._process(delta)
	
	for icon in icons: updateIconPos(icon)

	FunkinGD.callOnScripts(&'onUpdatePost',[delta])

#region Gui
func _setup_hud() -> void:
	super._setup_hud()
	camHUD.add(uiGroup,true); 
	if hideHud: return

	healthBar.position.x = ScreenUtils.screenWidth*0.5 - healthBar.bg.width*0.5
	healthBar.position.y = ScreenUtils.screenHeight - 100.0 if not ClientPrefs.data.downscroll else 50.0
	uiGroup.add(healthBar)
	
	healthBar.draw.connect(updateIconsPivot)
	
	iconP1.name = &'iconP1'
	iconP1.scale_lerp = true
	
	iconP2.name = &'iconP2'
	iconP2.scale_lerp = true
	
	iconP1.flipX = true
	
	updateIconPos(iconP1)
	updateIconPos(iconP2)
	updateIconsPivot()
	
	uiGroup.add(iconP1)
	uiGroup.add(iconP2)
	
	healthBar.flip = true
	
	healthBar.name = &'healthBar'
	FunkinGD.callOnScripts(&"onSetupHud")


func createMobileGUI():
	super.createMobileGUI()
	var button = TextureButton.new()
	button.texture_normal = Paths.texture('mobile/pause_menu')
	button.scale = Vector2(1.2,1.2)
	button.position.x = ScreenUtils.screenCenter.x
	button.pressed.connect(pauseSong)
	add_child(button)

#region Icon Methods
func updateIconsImage(state: IconState = _healthBar_State):
	var player_icon = iconP1
	var opponent_icon = iconP2
	if playAsOpponent:
		player_icon = iconP2
		opponent_icon = iconP1
	match state:
		IconState.NORMAL:
			player_icon.animation.play(&'normal')
			opponent_icon.animation.play(&'normal')
		IconState.LOSING:
			if opponent_icon.hasWinningIcon: opponent_icon.animation.play(&'winning')
			else: opponent_icon.animation.play(&'normal')
			player_icon.animation.play(&'losing')
		IconState.WINNING:
			if player_icon.hasWinningIcon: player_icon.animation.play(&'winning')
			else: player_icon.animation.play(&'normal')
			opponent_icon.animation.play(&'losing')


func updateIconPos(icon: Icon) -> void:
	var icon_pos: Vector2 
	if icon.flipX: icon_pos = healthBar.get_process_position(healthBar.progress - 0.03)
	else: icon_pos = healthBar.get_process_position(healthBar.progress)
	icon._position = icon_pos + healthBar.position - icon.pivot_offset

func updateIconsPivot() -> void: for i in icons: _update_icon_pivot(i,healthBar.rotation)

func _update_icon_pivot(icon: Icon,angle: float):
	var pivot = icon.image.pivot_offset
	if !angle:
		icon.pivot_offset = Vector2(0,pivot.y) if icon.flipX else Vector2(pivot.x*2.0,pivot.y); return
	
	if icon.flipX: 
		icon.pivot_offset = Vector2(
			lerpf(pivot.x,pivot.x*2.0,_icons_cos_sin.x),
			lerpf(pivot.y,0,_icons_cos_sin.y)
		)
	else: 
		icon.pivot_offset = Vector2(
			lerpf(pivot.x,0.0,_icons_cos_sin.x),
			lerpf(pivot.y,pivot.y*2.0,_icons_cos_sin.y)
		)
#endregion

#endregion

#region Beat Methods
func iconBeat() -> void:
	if !can_process(): return #Do not beat if the game is not being processed.
	for i in icons: i.scale += i.beat_value

##Do screen beat effect. Also used in PlayState.
func screenBeat(multi: float = 1.0) -> void: camHUD.zoom += 0.03 * multi 


func onBeatHit(beat: int = Conductor.beat) -> void:
	if !can_process(): return
	if camZooming and !fmod(beat,bumpStrumBeat): screenBeat()
	if beat < 0: countDownTick(beat)
	iconBeat()
#endregion

#region Note Methods
func createSplash(note) -> NoteSplash:
	var splash = super.createSplash(note)
	FunkinGD.callOnScripts(&'onSplashCreate',[splash])
	return splash

func createStrum(i: int, pos: Vector2 = Vector2.ZERO) -> StrumNote:
	var strum = super.createStrum(i)
	strum.mustPress = i >= keyCount and !botplay
	strum._position = pos
	FunkinGD.callOnScripts(&'onLoadStrum',[strum])
	return strum

func spawnNote(note): super.spawnNote(note); FunkinGD.callOnScripts(&'onSpawnNote',[note])

func reloadNotes():
	var types = SONG.get('noteTypes')
	if types: for i in types: 
		FunkinGD.addScript('assets/custom_notetypes/'+i); 
		FunkinGD.addScript('custom_notetypes/'+i)
	super.reloadNotes()

func reloadNote(note: Note):
	super.reloadNote(note)
	FunkinGD.callOnScripts(&'onLoadNote',note)
	if !note.noteType: return
	var path = 'custom_notetypes/'+note.noteType+'.gd'
	FunkinGD.callScript('assets/'+path,&'onLoadThisNote',note)
	FunkinGD.callScript(path,&'onLoadThisNote',note)
func loadNotes():
	super.loadNotes()
	if !loadEvents: return
	if eventNotes: _is_first_event_load = false; return
	
	var events_to_load = SONG.get('events',[])
	var events_json = Paths.loadJson(SongData.folder+'/events.json')
	
	if events_json:
		if events_json.get('song') is Dictionary: events_json = events_json.song
		events_to_load.append_array(events_json.get('events',[]))
	eventNotes = EventNoteUtils.loadEvents(events_to_load)
	_is_first_event_load = true

func updateNote(note: Note) -> bool:
	FunkinGD.callOnScripts(&'onPreUpdateNote', note)
	var _return = super.updateNote(note)
	FunkinGD.callOnScripts(&'onUpdateNote', note)
	return _return

func updateNotes() -> void: #Function from StrumState
	super.updateNotes()
	if !generateEvents: return
	while eventIndex < eventNotes.size():
		var event = eventNotes[eventIndex]
		if event.t > _songPos: break
		eventIndex += 1
		if event.trigger_when_opponent and playAsOpponent or event.trigger_when_player and !playAsOpponent: 
			triggerEvent(event.e,event.v)


func preHitNote(note: Note, character: Variant = null):
	if !note: return
	if !note.mustPress: camZooming = true
	
	if note.noteType:
		FunkinGD.callScript(
			'custom_notetypes/'+note.noteType+'.gd',
			&'onPreHitThisNote',
			[note,character]
		)
	if isPlayerNote(note): FunkinGD.callOnScripts(&'onPlayerPreHitNote',[note,character])
	FunkinGD.callOnScripts(&'goodNoteHitPre' if note.mustPress else &'opponentNoteHitPre',[note])
	FunkinGD.callOnScripts(&'onPreHitNote',[note,character])
	super.preHitNote(note)
	
func hitNote(note: Note, character: Variant = null) -> void:
	if !note: return
	if note.mustPress != playAsOpponent: health += note.hitHealth
	
	if character and !note.noAnimation: signCharacter(character,note)
	
	var audio: AudioStreamPlayer = Conductor.get_node_or_null("PlayerVoice" if note.mustPress else "OpponentVoice")
	if !audio: audio = Conductor.get_node_or_null("Voice")
	if audio: audio.volume_db = 0
	
	if note.noteType:
		FunkinGD.callScript(
			'custom_notetypes/'+note.noteType+'.gd',
			&'onHitThisNote',
			[note,character]
		)
	if isPlayerNote(note): FunkinGD.callOnScripts(&'onPlayerHitNote',[note,character])
	FunkinGD.callOnScripts(&'goodNoteHit' if note.mustPress else &'opponentNoteHit',[note])
	FunkinGD.callOnScripts(&'onHitNote',[note,character])
	super.hitNote(note)

func signCharacter(_character: Character, _note: Note): pass

func noteMiss(note, character: Variant = null) -> void:
	health -= note.missHealth
	var audio: AudioStreamPlayer = Conductor.get_node_or_null("Voice" if note.mustPress else "OpponentVoice")
	if audio: audio.volume_db = -80
	super.noteMiss(note)
	FunkinGD.callOnScripts(&'onNoteMiss',[note, character])
#endregion

#region Script Methods
func _load_song_scripts():
	if loadStageScript:
		#print('Loading Stage Script')
		FunkinGD.addScript('stages/'+curStage+'.gd')
	
	if loadSongScript and SongData.folder:
		#print('Loading Song Folder Script')
		for i in Paths.getFilesAt(SongData.folder,false,'gd'):FunkinGD.addScript(SongData.folder+'/'+i)
	
	if loadScripts:
		#print('Loading Scripts from Scripts Folder')
		for i in Paths.getFilesAt('scripts',false,'.gd'):
			FunkinGD.addScript('scripts/'+i)


func triggerEvent(event: StringName,variables: Variant) -> void:
	if !variables is Dictionary: return
	FunkinGD.callOnScripts(&'onEvent',[event,variables])
	FunkinGD.callScript('custom_events/'+event,&'onLocalEvent',[variables])
#endregion

#region Song Methods
func startCountdown():
	if _countdown_started: return
	_countdown_started = true
	
	Conductor.songPosition = -Conductor.stepCrochet*24.0
	var results = FunkinGD.callOnScriptsWithReturn("onStartCountdown")
	if FunkinGD.Function_Stop in results: return
	
	if skipCountdown: startSong()

func loadSong(data: String = song_json_file, songDifficulty: String = difficulty):
	super.loadSong(data,songDifficulty)
	loadStage(SONG.get('stage',''),false)
	
func loadSongObjects() -> void:
	camHUD.removeFilters()
	camOther.removeFilters()
	
	Stage.loadSprites(); #print('Loading Stage')
	
	_load_song_scripts(); #print('Loading Scripts')
	
	
	super.loadSongObjects() #print('Loading Song Objects')
	
	loadEventsScripts() #print('Loading Events')
	
	loadCharactersFromData() #print('Loading Characters')
	
	if !inModchartEditor:
		DiscordRPC.state = 'Now Playing: '+SongData.songName
		DiscordRPC.refresh()
	
func loadEventsScripts():
	for i in Paths.getFilesAtAbsolute(Paths.exePath+'/assets/custom_events',false,['gd'],true): FunkinGD.addScript('custom_events/'+i)
	
	var length = eventNotes.size()
	var i: int = 0
	while i < length:
		var event = eventNotes[i]
		i += 1
		var event_path ='custom_events/'+event.e
		FunkinGD.addScript(event_path)
		
		FunkinGD.callOnScripts(&'onLoadEvent',[event.e,event.v,event.t])
		FunkinGD.callScript(event_path,&'onLoadThisEvent',[event.v,event.t])
		if _is_first_event_load:
			FunkinGD.callOnScripts(&'onInitEvent',[event.e,event.v,event.t])
			FunkinGD.callScript(event_path,&'onInitLocalEvent',[event.v,event.t])
	
func startSong():
	super.startSong()
	if Conductor.songs: Conductor.songs[0].finished.connect(endSound)
	FunkinGD.callOnScripts(&'onSongStart')

func loadNextSong():
	var newSong = story_songs[0]
	story_songs.remove_at(0)
	if !story_song_notes.has(newSong): newSong = loadSong()

func seek_to(time: float, kill_notes: bool = true):
	skipCountdown = true
	super.seek_to(time,kill_notes)

#region Resume/Pause/End Song Methods
func resumeSong() -> void:
	if _isSongStarted: Conductor.resumeSongs()
	generateMusic = true
	process_mode = PROCESS_MODE_INHERIT
	onPause = false

func pauseSong(menu: bool = createPauseMenu) -> void:
	if !canPause: return
	if menu:
		if pauseState: return 
		create_pause_menu()
	generateMusic = false
	if _isSongStarted: Conductor.pauseSongs()
	process_mode = Node.PROCESS_MODE_DISABLED
	onPause = true
	

func create_pause_menu() -> PauseSubstate:
	if pauseState: return pauseState
	pauseState = PauseSubstate.new()
	pauseState.resume_song.connect(resumeSong.call_deferred)
	pauseState.restart_song.connect(restartSong.call_deferred)
	pauseState.exit_song.connect(endSound.call_deferred)
	add_sibling.call_deferred(pauseState)
	return pauseState

func restartSong(absolute: bool = true):
	Conductor.pauseSongs()
	if absolute: reloadPlayState(); return
	
	generateMusic = false
	TweenService.createTween(self,{&'songPosition': -Conductor.stepCrochet*24.0},1.0,'sineIn').finished.connect(
		func():
			for note in notes.members: note.kill()
			notes.members.clear()
			generateMusic = true
			onPause = false
	)

func endSound(skip_transition: bool = false) -> void:
	Conductor.pauseSongs()
	var results = FunkinGD.callOnScriptsWithReturn('onEndSong')
	if FunkinGD.Function_Stop in results or !canExitSong: return
	exitingSong = true
	canPause = false
	if isStoryMode and story_song_notes: loadNextSong()
	elif back_state: Global.swapTree(back_state.new(),!skip_transition)
#endregion

#endregion


#region Countdown Methods
func countDownTick(beat: int) -> void:
	if beat > 0: return
	elif !beat: startSong(); return
	
	var tick: int = countSounds.size() - absi(beat)
	if tick < 0 or tick >= countSounds.size(): return
	
	var folder: String = 'gameplay/countdown/'+('pixel/' if isPixelStage else 'funkin/')
	FunkinGD.playSound(folder+countSounds[tick]+introSoundsSuffix)
	FunkinGD.callOnScripts(&'onCountdownTick',[tick])
	
	if !countDownEnabled or !countDownImages[tick]: return
	
	var sprite = _create_countdown_sprite(countDownImages[tick])
	if !sprite.texture: return
	
	camHUD.add(sprite)

func _check_count_down_pos(delta: float) -> void:
	if Conductor.songPosition >= 0: return
	Conductor.songPosition += delta * 1000.0 * Conductor.music_pitch
	if Conductor.songPosition >= 0: startSong()

func _create_countdown_sprite(sprite_name: String, is_pixel: bool = isPixelStage) -> Sprite2D:
	var sprite = Sprite2D.new()
	if is_pixel:
		sprite.texture = Paths.texture('ui/countdown/pixel/'+sprite_name)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(6,6)
	else:
		sprite.texture = Paths.texture('ui/countdown/funkin/'+sprite_name)
		sprite.scale = Vector2(0.7,0.7)
	
	sprite.position = ScreenUtils.screenSize*0.5
	var tween = sprite.create_tween()
	tween.tween_property(sprite,'modulate:a',0.0,Conductor.stepCrochet*0.004)
	tween.tween_callback(sprite.queue_free)
	return sprite
#endregion

##Called when the game gonna restart the song
func reloadPlayState():
	for n in notes.members: n.kill()
	var state = get_script().duplicate().new(song_json_file,difficulty)
	Global.swapTree(state,true)
	
	Global.onSwapTree.disconnect(destroy)
	Global.onSwapTree.connect(func():
		for vars in [&'seenCutscene',&'playAsOpponent']: state[vars] = get(vars)
		destroy(false),CONNECT_ONE_SHOT
	)

#region Modding Methods
func chartEditor() -> void: 
	Global.doTransition().finished.connect(func():
		var chartEditor = ChartEditorScene.instantiate()
		Global.swapTree(chartEditor,false); 
		chartEditor.prev_scene = get_script()
		,CONNECT_ONE_SHOT
	)
	pauseSong(false)

func characterEditor():
	Global.doTransition().finished.connect(func():
		var editor = CharacterEditor.instantiate()
		editor.back_to = get_script()
		Global.swapTree(editor,false),CONNECT_ONE_SHOT
	)
	pauseSong(false)
#endregion

#region Video Methods
func startVideo(path: Variant, isCutscene: bool = true) -> FunkinVideo:
	var video_player = FunkinVideo.new()
	video_player.load_stream(path)
	
	if !video_player.stream: return video_player
	
	camOther.add(video_player)
	if !isCutscene: return video_player
	if videoPlayer: videoPlayer.queue_free()
	
	videoPlayer = video_player
	canPause = false
	inCutscene = true
	
	videoPlayer.finished.connect(_on_cutscene_ends)
	return videoPlayer

func _on_cutscene_ends() -> void:
	startCountdown()
	inCutscene = false
	canPause = true
	seenCutscene = true
	FunkinGD.callOnScripts(&'onEndCutscene',[videoPlayer.stream.resource_name])
	videoPlayer.queue_free()
#endregion



#region Section Methods
func onSectionHit(sec: int = Conductor.section) -> void:
	if sec < 0: return
	
	var sectionData = ArrayUtils.get_array_index(SONG.get('notes',[]),sec)
	if !sectionData: return
	
	mustHitSection = !!sectionData.get('mustHitSection')
	gfSection = !!sectionData.get('gfSection')
	altSection = !!sectionData.get('altAnim')
	FunkinGD.mustHitSection = mustHitSection
	FunkinGD.gfSection = gfSection
	FunkinGD.altAnim = altSection
	
func detectSection() -> String: return 'gf' if gfSection else ('boyfriend' if mustHitSection else 'dad')
#endregion

#region Character Methods
@abstract func addCharacterToList(_type,_character)
#Replaced in PlayState and PlayState3D
@abstract func changeCharacter(_t: int = 0, _character: StringName = 'bf')

func onSectionHitOnce(): if !isCameraOnForcedPos: moveCamera(detectSection())

func loadCharactersFromData(json: Dictionary = SONG) -> void:
	changeCharacter(2,json.get('gfVersion','gf'))
	changeCharacter(0,json.get('player1','bf'))
	changeCharacter(1,json.get('player2','bf'))

static func get_character_type_name(type: int) -> StringName:
	match type:
		1: return 'dad'
		2: return 'gf'
		_: return 'boyfriend'
#endregion

#region Stage Methods
func loadStage(stage: StringName, loadScript: bool = loadStageScript):
	if curStage == stage: return
	FunkinGD.removeScript('stages/'+curStage)
	FunkinGD.callOnScripts(&"onPreloadStage",stage)
	FunkinGD.curStage = stage
	curStage = stage
	
	stageJson = Stage.loadStage(stage)
	isPixelStage = stageJson.isPixelStage
	
	if loadScript: FunkinGD.addScript('stages/'+stage); Stage.loadSprites()
	FunkinGD.callOnScripts(&"onLoadStage",stage)
#endregion

#region Game Over Methods
func gameOver() -> void: FunkinGD.inGameOver = true; inGameOver = true; pauseSong(false)

func isGameOverEnabled() -> bool:
	return canGameOver and health < 0.0 and not inGameOver and\
		not FunkinGD.Function_Stop in FunkinGD.callOnScriptsWithReturn('onGameOver')

func clear() -> void: 
	super.clear(); 
	_isSongStarted = false; camZooming = false;
	
	_is_first_event_load = true
	eventNotes.clear()
	EventNoteUtils.event_variables.clear()
	
	camHUD.removeFilters(); camOther.removeFilters()
#endregion

#region Health Methods
func set_health(value: float) -> void:
	value = clampf(value,-1.0,2.0)
	if health == value: return
	health = value
	
	if isGameOverEnabled(): gameOver(); return
	
	var progress_h = value*0.5
	healthBar.progress = progress_h if playAsOpponent else 1.0 - progress_h
	
	var bar_state = 0.0
	if progress_h >= 0.7: bar_state = IconState.WINNING
	elif progress_h <= 0.3: bar_state = IconState.LOSING
	else: bar_state = IconState.NORMAL
	
	if bar_state == _healthBar_State: return
	_healthBar_State = bar_state
	updateIconsImage(bar_state)

##Set HealthBar angle(in degrees). See also [method @GlobalScope.rad_to_deg]
func setHealthBarAngle(angle: float):
	healthBar.rotation_degrees = angle
	_update_icons_cos_sin()
	updateIconsPivot()

func _update_icons_cos_sin() -> void: _icons_cos_sin = Vector2(cos(healthBar.rotation),sin(healthBar.rotation))
#endregion

#region Setters
func set_default_zoom(value: float) -> void: defaultCamZoom = value;

func _set_hide_hud(hide: bool) -> void:
	hideHud = hide
	FunkinGD.callOnScripts(&"onHideHud",hide)

func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void:
	healthBar.flip = !isOpponent
	updateIconsImage()
	super._set_play_opponent(isOpponent)
#endregion

#region Camera methods
func moveCamera(target: StringName = 'boyfriend') -> void: FunkinGD.callOnScripts(&'onMoveCamera',[target])
#endregion


func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		FunkinGD.callOnScripts(&'onKeyEvent',[event])
		if !event.pressed or event.echo: return
		match event.keycode:
			KEY_ENTER: if canPause and not onPause: pauseSong.call_deferred()
			KEY_7: if isModding: chartEditor()
			KEY_8: if isModding: characterEditor()

func destroy(absolute: bool = true):
	FunkinGD.callOnScripts(&'onDestroy',[absolute])
	FunkinGD._clear_scripts()
	FunkinGD.game = null
	stageJson.clear()
	
	Paths.extraDirectory = ''
	
	camHUD.removeFilters()
	camOther.removeFilters()
	Paths.clearLocalFiles()
	Paths._clear_paths_cache()
	super.destroy(absolute)

func _property_get_revert(property: StringName) -> Variant:
	match property:
		'defaultCamZoom': return Stage.json.get('cameraZoom',1.0)
		'cameraSpeed': return Stage.json.get('cameraSpeed',1.0)
		'health': return 1.0
	return null
