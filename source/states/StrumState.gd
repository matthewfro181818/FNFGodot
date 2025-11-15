extends Node

@export_category('Notes')
const Song = preload("res://source/backend/Song.gd")

const NoteStyleData = preload("uid://by78myum2dx8h")
const NoteSplash = preload("uid://cct1klvoc2ebg")
const Note = preload("uid://deen57blmmd13")
const EventNoteUtils = preload("uid://dqymf0mowy0dt")
const NoteSustain = preload("uid://bhagylovx7ods")

const NoteHit = preload("uid://dx85xmyb5icvh")
const StrumNote = preload("uid://coipwnceltckt")

const Combo = preload("uid://dmvm4us4t2iqg")
const ComboStrings: PackedStringArray = ['sick','good','bad','shit']
const StrumOffset: float = 112.0

static var COMBO_PIXEL_SCALE: Vector2 = Vector2(6,6)
static var COMBO_SCALE: Vector2 = Vector2(0.8,0.8)

static var isModding: bool = true
static var inModchartEditor: bool = false
static var week_data: Dictionary = {}

const ChartEditor = preload("res://source/states/Editors/ChartEditor/ChartEditor.gd")

@export_group("Song Data")

@export var song_folder: String = ''
@export var song_json_file: String = ''
@export var difficulty: String = ''

var autoStartSong: bool  ##Start the Song when the Song json is loaded. Used in PlayState

##If this is [code]false[/code], will disable the notes, 
##making them stretched and not being created
var generateMusic: bool = true
var exitingSong: bool
var clear_song_after_exiting: bool = true

var songSpeed: float: set = set_song_speed 
var _songLength: float = 0.0
var _isSongStarted: bool

static var SONG: Dictionary:
	set(dir): Conductor.songJson = dir
	get(): return Conductor.songJson ##The data of the Song.

var keyCount: int = 4: ##The amount of notes that will be used, default is [b]4[/b].
	set(value): 
		keyCount = value
		var length = keyCount*2
		hitNotes.resize(value)
		defaultStrumPos.resize(length)
		defaultStrumAlpha.resize(length)
		
var mustHitSection: bool ##When the focus is on the opponent.
var gfSection: bool ##When the focus is on the girlfriend.


var _songPos: float
@export_group("Notes")
var strumLineNotes: SpriteGroup = SpriteGroup.new()#Strum's Group.
var opponentStrums: SpriteGroup = SpriteGroup.new() ##Strum's Oponnent Group.
var playerStrums: SpriteGroup = SpriteGroup.new() ##Strum's Player Group.
var extraStrums: Array[StrumNote] = []

 ##Returns the player strum. 
##If [member playAsOpponent] = true, returns [member opponentStrums], else, returns [member playerStrums]
var current_player_strum: Array = playerStrums.members

var uiGroup: SpriteGroup = SpriteGroup.new() ##Hud Group.

static var unspawnNotes: Array[Note] = [] ##Unspawn notes, the array is reversed for more performace.
var _unspawnNotesLength: int
var _unspawnIndex: int
var _respawnIndex: int
var respawnNotes: bool
var notes: SpriteGroup = SpriteGroup.new()


const NOTE_SPAWN_TIME: float = 1000

var noteSpawnTime: float = NOTE_SPAWN_TIME

var hitNotes: Array[Note]
var canHitNotes: bool = true

var _splashes_loaded: Dictionary = {}

var splashesEnabled: bool = ClientPrefs.data.splashesEnabled and ClientPrefs.data.splashAlpha > 0
var opponentSplashes: bool = splashesEnabled and ClientPrefs.data.opponentSplashes
var grpNoteSplashes: SpriteGroup = SpriteGroup.new() ##Note Splashes Group.
var grpNoteHoldSplashes: Dictionary[int,NoteSplash] ##Note Hold Splashes Group.

static var isPixelStage: bool
@export var arrowStyle: String = 'funkin'
@export var splashStyle: String = 'NoteSplashes'
@export var splashHoldStyle: String = 'HoldNoteSplashes'

#region Rating Data
var songScore: int ##Score
var combo: int ##Combo
var sicks: int ##Sick's count
var goods: int ##Good's count
var bads: int ##Bad's count
var shits: int ##Shit's count
var songMisses: int ##Misses count

var defaultStrumPos: PackedVector2Array
var defaultStrumAlpha: PackedFloat32Array

##Rating String, 
##can be "SFC" (just [b]SICK[/b] hits), "GFC"(Just hitting "Sick" and Good "combos") and "FC"(Sick,Good and Bad)
var ratingFC: String 

var ratingPercent: float ##Percent of the Rating.

var noteHits: int ##Total Note hits.
var totalNotes: int ##Total Notes.
var noteScore: int = 350 ##Hit's Score.
#endregion

@export_group("Play Options")


##Play as Opponent, reversing the sides.
@export var playAsOpponent: bool = ClientPrefs.data.playAsOpponent: set = _set_play_opponent

##When activate, the notes will be hitted automatically.
@export var botplay: bool = ClientPrefs.data.botplay: set = _set_botplay

@export var downScroll: bool = ClientPrefs.data.downscroll: set = _set_downscroll
@export var middleScroll: bool = ClientPrefs.data.middlescroll: set = _set_middlescroll

@export_category("Combo Options")
@export var showCombo: bool = true ##If false, the Combo count will not be showed when the player hits the note.
@export var showRating: bool = true ##If false, the Combo Sprites(Sick,Good,Bad,Shit) will not be showed when the player hits the note.
@export var showComboNum: bool = true##If false, the combo will not be showed.

var _comboPreloads: Dictionary
var _comboPixelsPreload: Dictionary

##Android System
var touch_state

var Inst: AudioStreamPlayer:
	get(): return ArrayUtils.get_array_index(Conductor.songs,0)

var vocals: AudioStreamPlayer:
	get(): return ArrayUtils.get_array_index(Conductor.songs,1)

signal hit_note
func _init(json_file: StringName = &'', song_difficulty: StringName = &''):
	add_child(uiGroup)
	uiGroup.name = &'uiGroup'
	
	
	song_json_file = json_file.get_file()
	difficulty = song_difficulty
	
	uiGroup.add(strumLineNotes)
	uiGroup.add(playerStrums)
	uiGroup.add(opponentStrums)
	uiGroup.add(notes)
	uiGroup.add(grpNoteSplashes)
	
	grpNoteSplashes.name = &'grpNoteSplashes'
	
	opponentStrums.name = &'opponentStrums'
	playerStrums.name = &'playerStrums'
	strumLineNotes.name = &'strumLineNotes'
	
	notes.name = &'notes'

func _ready():
	loadSong()
	loadSongObjects()
	if Paths.is_on_mobile: createMobileGUI()
	_precache_combo()
	if autoStartSong: startSong()

func createMobileGUI():
	##HitBox
	touch_state = load("res://source/objects/Mobile/Hitbox.gd").new()
	add_child(touch_state)
	touch_state.z_index = 1
	
func precache_images():
	if ClientPrefs.data.comboStacking: _precache_combo()

func _precache_combo():
	var range_nums = range(10)
	for i in ComboStrings:
		var comboTex: Texture2D = Paths.texture(i)
		if !comboTex: continue
		var combo = Combo.new()
		combo.texture = comboTex
		#combo.size = comboTex.get_size()
		combo.scale = COMBO_SCALE
		_comboPreloads[i] = combo
	
	for i in range_nums:
		var number_tex = Paths.texture('num'+String.num_int64(i))
		if !number_tex: continue
		var number = Combo.new()
		number.scale = COMBO_SCALE
		number.texture = number_tex
		_comboPreloads[i] = number
	
	#Pixel Combos
	for i in ComboStrings:
		var pixel_tex = Paths.texture('pixelUI/'+i+'-pixel')
		if !pixel_tex: continue
		var combo_pixel = Combo.new()
		combo_pixel.texture = pixel_tex
		#combo_pixel.size = pixel_tex.get_size()
		combo_pixel.scale = COMBO_PIXEL_SCALE
		combo_pixel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_comboPixelsPreload[i] = combo_pixel
		
	#Pixel Numbers
	for i in range_nums:
		var pixel_tex = Paths.texture('pixelUI/num'+str(i)+'-pixel')
		if !pixel_tex: continue
		
		var number_pixel = Combo.new()
		number_pixel.texture = pixel_tex
		number_pixel.scale = COMBO_PIXEL_SCALE
		number_pixel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_comboPixelsPreload[i] = number_pixel
	
#region Song Methods
func loadSong(data: String = song_json_file, songDifficulty: String = difficulty):
	if !SONG: Conductor.loadSong(data,songDifficulty)
	keyCount = SONG.get('keyCount',4)
	FunkinGD.keyCount = keyCount
	
	if !SONG: return
	Conductor.loadSongsStreams()
	
	set_song_speed(SONG.speed)
	
	if !SONG.notes: return
	mustHitSection = SONG.notes[0].mustHitSection
	gfSection = SONG.notes[0].get('gfSection',false)

##Load song data. Used in PlayState
func loadSongObjects():
	var arrow_s = SONG.get('arrowStyle')
	var splash_s = SONG.get('splashType')
	var hold_s = SONG.get('holdSplashType')
	
	if arrow_s: arrowStyle = arrow_s
	else: arrowStyle = 'pixel' if isPixelStage else 'funkin'
	
	if splash_s: splashStyle = splash_s
	if hold_s: splashHoldStyle = hold_s
	_create_strums()
	_respawnIndex = 0
	_unspawnIndex = 0
	if !SONG: return
	loadNotes()

func loadNotes():
	if !unspawnNotes:  unspawnNotes = getNotesFromData(SONG)
	_unspawnNotesLength = unspawnNotes.size()
	reloadNotes()
	
func clearSongNotes():
	for i in notes.members: i.queue_free()
	notes.members.clear()
	_respawnIndex = 0
	_unspawnIndex = 0
	unspawnNotes.clear()

##Begins the song. See also [method loadSong].
func startSong() -> void: 
	if !Conductor.songs: return
	var length = Conductor.songs.size()
	length -= 1
	var songsArray: Array[AudioStreamPlayer] = Conductor.songs
	var songs = ['Inst','voices','voices_opponent']
	var songId: int = 0
	
	for i in songs:
		if songId > length: break
		var audio = songsArray[songId]
		set(i,audio)
		audio.seek(0.0)
		audio.play(0.0)
		songId += 1
		pass
	_isSongStarted = true
	_songLength = songsArray[0].stream.get_length()*1000.0

##Seek the Song Position to [param time] in miliseconds.[br]
##If [param kill_notes] is [code]true[/code], the notes above the [param time] will be removed.
func seek_to(time: float, kill_notes: bool = true):
	Conductor.seek(time)
	if !kill_notes: return
	
	var time_offset: float = time + 1000
	for i in notes.members: if i.strumTime < time_offset: i.kill()
	
	while _unspawnIndex < unspawnNotes.size():
		if unspawnNotes[_unspawnIndex].strumTime > time_offset: break
		_unspawnIndex += 1
	
#endregion

func updateStrumsPosition():
	var screen_center = ScreenUtils.screenCenter
	var key_div = keyCount/2.0
	var strum_off = StrumOffset
	
	var strumsSpace = (StrumOffset*keyCount)
	var margin_scale: float = minf(
		ScreenUtils.screenWidth/strumsSpace - 2.0,
		1.0
	)
	var margin_offset: float = strum_off*margin_scale
	defaultStrumAlpha.fill(1.0)
	
	var first_op_pos = screen_center.x
	var strum_first_pos = screen_center.x
	
	
	if middleScroll:  strum_first_pos -= strum_off*(key_div)
	else: 
		strum_first_pos += margin_offset
		first_op_pos -= margin_offset + strum_off*(keyCount)
	
	#Opponent Position
	var op_middle_offset = strum_off*(key_div-1)*margin_scale
	for i in keyCount:
		var strumPos: float = first_op_pos
		var strumIndex: int = i
		
		if middleScroll:
			if i < key_div: strumPos += strum_off*(i-keyCount) - op_middle_offset
			else: strumPos += strum_off*i + op_middle_offset
			if playAsOpponent: strumIndex += keyCount
			defaultStrumAlpha[strumIndex] = 0.35
		else: strumPos += strum_off*i
		defaultStrumPos[strumIndex].x = strumPos
	
	#Player Position
	for i in keyCount:
		var strumIndex: int = (i+keyCount) if not (middleScroll and playAsOpponent) else i 
		var strumPos: float = strum_first_pos
		strumPos += strum_off*i
		defaultStrumPos[strumIndex].x = strumPos
	updateStrumsY()

func getDefaultStrumY(downscroll: bool = downScroll) -> float: return ScreenUtils.screenHeight - 150.0 if downscroll else 50.0

func updateStrumsY() -> void:
	var strumY = getDefaultStrumY()
	var index = 0
	while index < defaultStrumPos.size(): defaultStrumPos[index].y = strumY; index += 1
	
func reset_strums_state():
	for i in (keyCount*2):
		var strum = strumLineNotes.members[i]
		strum._position = defaultStrumPos[i]
		strum.modulate.a = defaultStrumAlpha[i]

func _create_strums() -> void:
	for i in strumLineNotes.members: 
		if i.get_parent(): i.get_parent().remove_child(i)
		i.queue_free()
	
	strumLineNotes.members.clear()
	playerStrums.members.clear()
	opponentStrums.members.clear()
	
	updateStrumsPosition()
	var i = 0
	#Opponent Notes
	while i < keyCount:
		var strum = createStrum(i,true,defaultStrumPos[i])
		strum.mustPress = playAsOpponent and !botplay
		strum.modulate.a = defaultStrumAlpha[i]
		i += 1
	i = keyCount
	var key_count = keyCount*2.0
	#Player Notes
	while i < key_count:
		var strum = createStrum(i-keyCount,false,defaultStrumPos[i])
		strum.mustPress = !playAsOpponent and !botplay
		strum.modulate.a = defaultStrumAlpha[i]
		i += 1
func createStrum(i: int, opponent_strum: bool = true, pos: Vector2 = Vector2.ZERO) -> StrumNote:
	var strum = StrumNote.new(i)
	strum.loadFromStyle(arrowStyle)
	
	
	strum.mustPress = !opponent_strum and !botplay
	if opponent_strum: opponentStrums.add(strum)
	else: playerStrums.add(strum)
	
	strum.downscroll = downScroll
	strum._position = pos
	
	strumLineNotes.add(strum)
	strum.name = "StrumNote"
	return strum

func _process(_d) -> void:  if generateMusic: _songPos = Conductor.songPositionDelayed; updateNotes()

#region Note Functions
func updateRespawnNotes():
	while _respawnIndex:
		var note = unspawnNotes[_respawnIndex-1]
		if !note: _respawnIndex -= 1; continue
		var time = note.strumTime - _songPos
		
		if time > 0 and time < noteSpawnTime: 
			note.resetNote()
			spawnNote(note)
			updateNote(note)
			_respawnIndex -= 1
			continue
		break

func updateNotes():
	_check_unspawn_notes()
	_check_respawn_notes()
	
	hitNotes.fill(null) #Detect notes that can hit
	if !notes.members: return
	
	var members = notes.members
	var note_index: int = members.size()
	if respawnNotes:
		while note_index:
			note_index -= 1
			var note = members[note_index]
			if note.strumTime - _songPos > noteSpawnTime: note.kill(); _unspawnIndex -= 1
			elif updateNote(note): continue
			members.remove_at(note_index)
	else:
		while note_index:
			note_index -= 1
			if !updateNote(members[note_index]): members.remove_at(note_index)
	
	if !botplay and canHitNotes: _check_hit_notes()
func _check_unspawn_notes():
	if !unspawnNotes: return
	while _unspawnIndex < _unspawnNotesLength:
		var unspawn: Note = unspawnNotes[_unspawnIndex]
		if unspawn and unspawn.strumTime - _songPos > noteSpawnTime: break
		_unspawnIndex += 1
		spawnNote(unspawn)

func _check_respawn_notes() -> void:
	if !respawnNotes or !unspawnNotes: return
	while _respawnIndex < _unspawnIndex:
		var note = unspawnNotes[_respawnIndex]
		if !note.wasHit and !note.missed: break
		_respawnIndex += 1

func _check_hit_notes() -> void:
	for i: Note in hitNotes:
		if !i: continue
		if Input.is_action_just_pressed(i.hit_action): hitNote(i)
		hitNotes[i.noteData] = null

func spawnNote(note: Note) -> void: ##Spawns the note
	if !note: return
	if note.strumTime < note.missOffset: noteMiss(note); return
	if !note.noteGroup: addNoteToGroup(note,notes); return
	notes.members.append(note)
	note.groups.append(notes)
	addNoteToGroup(note,note.noteGroup)
	
func addNoteToGroup(note: Note, group: Node) -> void:
	if group is SpriteGroup:
		if note.isSustainNote: group.insert(0,note)
		else: group.add(note)
		return
	
	group.add_child(note)
	if note.isSustainNote and note.noteGroup == note.noteParent.noteGroup: group.move_child(note,note.noteParent.get_index())

func updateNote(note: Note):
	if !note or !note._is_processing: return false
	
	var strum = note.strumNote
	var playerNote: bool
	playerNote = note.autoHit or !botplay and (strum.mustPress if strum else false)
	note.noteSpeed = songSpeed
	note.updateNote()
	
	if not (note.isSustainNote and note.isBeingDestroyed) and note.strumTime - _songPos <= note.missOffset:
		if not note.missed and playerNote and not note.ignoreNote: noteMiss(note) 
		return true
	
	if !note.canBeHit: return true
	if !canHitNotes: return true
	
	if !playerNote:
		if not note.ignoreNote and (note.isSustainNote or note.distance <= 0.0): hitNote(note)
		return true
	
	if note.isSustainNote:
		if Input.is_action_pressed(note.hit_action): hitNote(note)
		return true
	
	var lastN = hitNotes[note.noteData]
	if !lastN or absf(note.distance) < absf(lastN.distance): hitNotes[note.noteData] = note
	elif note.distance == lastN.distance and Input.is_action_just_pressed(note.hit_action): hitNote(note)
	return true

func preHitNote(note: Note):
	if !note: return
	if !note.isSustainNote: note.updateRating()
	note.wasHit = true
	note.judgementTime = _songPos

func hitNote(note: Note) -> void: ##Called when the hits a [NoteBase] 
	if !note: return
	preHitNote(note)
	var mustPress: bool = note.mustPress
	var playerNote: bool = mustPress != playAsOpponent
	var strumAnim: StringName = &'confirm'
	var strum: StrumNote = note.strumNote
	if playerNote:
		if !note.isSustainNote: addScoreFromNote(note)
		else: 
			sicks += 1; 
			songScore += 10
			if note.isEndSustain: strumAnim = &'press'
	else:  
		if note.isEndSustain: _disableHoldSplash(strum.get_instance_id())
	
	if note.strumConfirm: _strum_confirm(strum,note,strumAnim)
	_on_hit_note(note)
	
	if splashAllowed(note): createSplash(note)
	note.killNote()

func _strum_confirm(strum: StrumNote,note: Note, confirmAnim: StringName = &"confirm"):
	if !strum: return
	
	if strum.mustPress: strum.animation.play(confirmAnim,true); return
	if !note.isSustainNote or note.isEndSustain: 
		strum.strumConfirm(confirmAnim); strum.return_to_static_on_finish = true; return
	
	strum.return_to_static_on_finish = note.isEndSustain
	strum.hitTime = 0.0
	strum.animation.play(confirmAnim,true)
	
		
	
func _on_hit_note(note: Note): pass

func reloadNotes() -> void: for i in unspawnNotes: reloadNote(i)

func reloadNote(note: Note):
	note.loadFromStyle(arrowStyle)
	var noteStrum: StrumNote = strumLineNotes.members.get((note.noteData + keyCount) if note.mustPress else note.noteData)
	note.strumNote = noteStrum
	note.isPixelNote = isPixelStage
	note.resetNote()
	if note.isSustainNote: 
		note.flipY = noteStrum.downscroll
		if splashHoldStyle: note.splashStyle = splashHoldStyle
	else: if splashStyle: note.splashStyle = splashStyle


##Called when the player miss a [Note]
func noteMiss(note, kill_note: bool = true) -> void:
	if !note:return
	
	note.missed = true
	note.judgementTime = _songPos
	
	combo = 0
	songMisses += 1
	if !note.ratingDisabled: songScore -= 10
	totalNotes += 1
	updateScore()
	if ClientPrefs.data.notHitSustainWhenMiss: _disable_note_sustains(note)
	if kill_note: note.kill()

func _disable_note_sustains(note: Note) -> void:
	for sus in note.sustainParents: sus.blockHit = true; sus.ignoreNote = true; sus.modulate.a = 0.3
#endregion

#region Splash Methods
func createSplash(note) -> NoteSplash: ##Create Splash
	var strum: StrumNote = note.strumNote
	if !strum or !strum.visible: return
	
	var style = note.splashStyle
	var type = note.splashType
	
	var prefix = note.splashPrefix
	
	var splashParent = note.splashParent
	var splash_type = NoteSplash.SplashType.NORMAL
	
	if note.isSustainNote:
		if note.isEndSustain: splash_type = NoteSplash.SplashType.HOLD_COVER_END
		else: splash_type = NoteSplash.SplashType.HOLD_COVER
	
	var splash: NoteSplash = _getSplashAvaliable(style,type,prefix,splash_type)
	if !splash:
		splash = _createNewSplash(style,type,prefix,splash_type)
		if !splash: return
		
		if splashParent: grpNoteSplashes.members.append(splash); splashParent.add_child(splash)
		else: grpNoteSplashes.add(splash)
	else: 
		splash.visible = true
		if splashParent: splash.reparent(splashParent,false)
		elif splash._is_custom_parent: splash.reparent(grpNoteSplashes,false)
	
	splash._is_custom_parent = !!splashParent
	splash.strum = strum
	splash.isPixelSplash = isPixelStage
	splash.followStrum()
	match splash_type:
		NoteSplash.SplashType.HOLD_COVER:
			_disableHoldSplash(strum.get_instance_id())
			grpNoteHoldSplashes[strum.get_instance_id()] = splash
			
			splash.animation.setAnimDataValue(
				'splash-hold',
				'speed_scale',
				minf(100.0/Conductor.stepCrochet,1.5)
			)
			
			splash.animation.play(&'splash',true)
			return splash
		NoteSplash.SplashType.HOLD_COVER_END: _disableHoldSplash(strum.get_instance_id())
	splash.animation.play_random(true)
	return splash


func _disableHoldSplash(id: int = 0) -> void:
	var splash = grpNoteHoldSplashes.get(id)
	if !splash: return
	splash.visible = false
	grpNoteHoldSplashes[id] = null

func _createNewSplash(style: StringName, type: StringName, prefix: StringName, splash_type: NoteSplash.SplashType) -> NoteSplash:
	var splash = NoteSplash.new()
	if !splash.loadSplash(style,splash_type,prefix): return
	
	_saveSplashType(style,type,prefix)
	_splashes_loaded[style][type][prefix].append(splash)
	
	if splash_type != NoteSplash.SplashType.HOLD_COVER:
		splash.animation.animation_finished.connect(
			func(_anim): splash.visible = false
		)
	return splash

func _saveSplashType(style: StringName, type: String, prefix: String = '') -> bool:
	var added: bool = false 
	if !_splashes_loaded.has(style): _splashes_loaded[style] = {}; added = true
	
	if type and !_splashes_loaded[style].has(type):_splashes_loaded[style][type] = {}; added = true
	if prefix and !_splashes_loaded[style][type].has(prefix):
		_splashes_loaded[style][type][prefix] = Array([],TYPE_OBJECT,'Node2D',NoteSplash)
		added = true
	return added
	
func _getSplashAvaliable(style: StringName, type: String, prefix: String, splash_type: NoteSplash.SplashType) -> NoteSplash:
	if _saveSplashType(style,type,prefix): return
	for s in _splashes_loaded[style][type][prefix]: if !s.visible and s.splashType == splash_type: return s
	return
	
func splashAllowed(n: Note) -> bool:
	return !n.splashDisabled and splashesEnabled and n.ratingMod <= 1 and\
			(n.isSustainNote and !n.isEndSustain or (n.mustPress != playAsOpponent or opponentSplashes))

#endregion

#region Score Methods
func addScoreFromNote(note: Note):
	noteHits += 1
	totalNotes += 1
	if note.ratingDisabled: return
	match note.ratingMod:
		1: sicks += 1
		2: goods += 1
		3: bads += 1
		_: shits += 1
	songScore += noteScore * note.ratingMod
	combo += 1
	
	if showRating: createCombo(note.rating)
	if showCombo and combo >= 10: createNumbers()
	updateScore()
##Update the score data.
func updateScore() -> void:
	if noteHits:
		if !totalNotes: ratingPercent = 0.0
		else:
			var realNoteHits = noteHits
			realNoteHits -= 0.25 * goods
			realNoteHits -= 0.5 * bads
			realNoteHits -= 0.75 * shits
			ratingPercent = (realNoteHits/totalNotes)*100.0
	
	else: ratingPercent = 0.0
	
	if songMisses: ratingFC = ''
	elif bads:ratingFC = '(FC)'
	elif goods: ratingFC = '(GFC)'
	elif sicks: ratingFC = '(SFC)'
	else: ratingFC = '(N/A)'

func createCombo(rating: StringName) -> Combo: ##Create the Combo Image
	var dict = _comboPixelsPreload if isPixelStage else _comboPreloads
	var comboSprite = dict.get(rating)
	if !comboSprite: return
	comboSprite = comboSprite.duplicate()
	uiGroup.add(comboSprite)
	comboSprite.name = &'Combo'
	comboSprite.position = ScreenUtils.screenSize/2.0 - Vector2(ClientPrefs.data.comboOffset[0],ClientPrefs.data.comboOffset[1])
	return comboSprite

func createNumbers(number: int = combo): ##Create the Numbers combo
	var digits: PackedInt32Array
	var digit: int = 1
	while digit < number:
		digits.append(int(number / digit) % 10)
		digit *= 10
	
	while digits.size() < 3: digits.append(0)
	var index: int = 0
	var dict = _comboPixelsPreload if isPixelStage else _comboPreloads
	for i in digits:
		if !i in dict: continue
		
		var comboNumber = _comboPreloads[i].duplicate()
		comboNumber.position = ScreenUtils.screenSize/2.0 - Vector2(
			ClientPrefs.data.comboOffset[2]+ 60.0*index,
			ClientPrefs.data.comboOffset[3]
		)
		uiGroup.add(comboNumber)
		index += 1
#endregion

func destroy(absolute: bool = true): ##Remove the state
	Conductor.clearSong(exitingSong)
	
	if absolute: clear(); queue_free(); return
	
	Paths.clearLocalFiles()
	if isModding: 
		NoteSplash.splash_datas.clear()
		NoteStyleData.styles_loaded.clear()
	for note in notes.members: note.kill()
	

func _set_botplay(is_botplay: bool) -> void:
	botplay = is_botplay
	if !is_botplay: updateStrumsMustPress()
	for i in strumLineNotes.members: i.mustPress = false

func updateStrumsMustPress() -> void:
	var strums = strumLineNotes.members
	if !strums: return
	
	var index: int = 0
	while index < strums.size():
		if botplay: strums[index].mustPress = false; continue
		if index < keyCount: strums[index].mustPress = playAsOpponent
		else: strums[index].mustPress = !playAsOpponent
		index += 1


#region Setters
func set_song_speed(value):
	songSpeed = value
	noteSpawnTime = NOTE_SPAWN_TIME/(value/2.0)

func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void:
	if playAsOpponent == isOpponent: return
	playAsOpponent = isOpponent
	updateStrumsMustPress()
	current_player_strum = (opponentStrums if isOpponent else playerStrums).members
	if middleScroll: updateStrumsPosition()
	
func _set_downscroll(value):
	if downScroll == value: return
	downScroll = value
	FunkinGD.downscroll = value
	updateStrumsY()

func _set_middlescroll(value):
	if middleScroll == value: return
	middleScroll = value
	FunkinGD.middlescroll = value
	updateStrumsPosition()
#endregion


func clear() -> void: 
	clearSongNotes() #Replaced in PlayStateBase
	clear_splashes()
	unspawnNotes.clear()
	
	NoteStyleData.styles_loaded.clear()
	NoteSplash.splash_datas.clear()
	
	Paths.clearLocalFiles()
	inModchartEditor = false
	isPixelStage = false
	
func clear_splashes():
	for file in _splashes_loaded.values(): for style in file.values(): for prefix in style.values(): for splashes in prefix: splashes.queue_free()
	grpNoteHoldSplashes.clear()
	grpNoteSplashes.members.clear()
	_splashes_loaded.clear()
	
##Load Notes from the Song.[br][br]
##[b]Note:[/b] This function have to be call [u]when [member SONG] and [member keyCount] is already setted.[/u]
static func getNotesFromData(songData: Dictionary = {}) -> Array[Note]:
	var _notes: Array[Note] = []
	var notesData = songData.get('notes')
	if !notesData: return _notes
	
	var _bpm: int = songData.get('bpm',0.0)
	var keyCount: int = songData.get('keyCount',4)
	
	var stepCrochet: float = Conductor.get_step_crochet(_bpm)
	
	var types_founded: PackedStringArray = PackedStringArray()
	for section: Dictionary in notesData:
		if section.changeBPM and section.bpm != _bpm:
			_bpm = section.bpm
			stepCrochet = Conductor.get_step_crochet(_bpm)
			
		var isAltSection: bool = section.get("altAnim",false)
		
		for noteSection in section.sectionNotes:
			var note: NoteHit = createNoteFromData(noteSection,section,keyCount)
			if !_insert_note_to_array(note,_notes): continue
			
			if isAltSection: note.animSuffix = '-alt'
			if note.noteType: types_founded.append(note.noteType)
			
			var susLength = float(noteSection[2]) if noteSection.size() >= 3 else 0.0
			if !susLength: continue 
			for i in _create_note_sustains(note,susLength,stepCrochet): _insert_note_to_array(i,_notes)
	
	var type_unique: PackedStringArray
	for i in types_founded: if not i in type_unique: type_unique.append(i)
	songData.noteTypes = type_unique
	return _notes

static func _insert_note_to_array(note: Note, array: Array) -> bool:
	if !note: return false
	if !array: array.append(note); return true
	var index = array.size()
	while index > 0:
		var prev_note = array[index-1]
		if note.strumTime <= prev_note.strumTime: index -= 1; continue
		array.insert(index,note)
		return true
	array.push_front(note)
	return true

static func _create_note_sustains(note: Note, length: float, stepCrochet: float) -> Array[NoteSustain]:
	var susNotes: Array[NoteSustain] = note.sustainParents
	var time: float = note.strumTime
	var index: int = 0
	var div: float = length/stepCrochet
	var int_div = int(div)
	var susCount: int = int_div  if div-int_div < stepCrochet/2.0 else int_div+1
	while index <= susCount:
		var step = stepCrochet*index
		var sus_length = minf(stepCrochet, length - step)
		var sus: NoteSustain = createSustainFromNote(note,index == susCount)
		sus.sustainLength = sus_length
		sus.strumTime = time
		time += sus_length
		susNotes.append(sus)
		index += 1

		
	susNotes[0].splashDisabled = false
	
	susNotes.back().splashDisabled = false
	note.sustainLength = length
	return susNotes

static func createNoteFromData(data: Array, sectionData: Dictionary, keyCount: int = 4) -> NoteHit:
	var noteData = int(data[1])
	if noteData < 0: return
	
	var note = NoteHit.new(noteData%keyCount)
	var mustHitSection = sectionData.mustHitSection
	var gfSection = sectionData.gfSection
	var type = data[3] if data.size() >= 4 else null
	
	note.strumTime = data[0]
	note.mustPress = mustHitSection and noteData < keyCount or not mustHitSection and noteData >= keyCount
	if type and type is String: 
		note.noteType = type
		note.gfNote = gfSection and note.mustPress == mustHitSection or type == 'GF Sing'
	else: note.gfNote = gfSection and note.mustPress == mustHitSection
	return note


static func createSustainFromNote(note: Note,isEnd: bool = false) -> NoteSustain:
	var sus: NoteSustain = NoteSustain.new(note.noteData)
	sus.splashStyle = &''
	sus.noteParent = note
	sus.isEndSustain = isEnd
	sus.splashDisabled = true
	sus.hitHealth /= 2.0
	
	sus.noteType = note.noteType
	sus.gfNote = note.gfNote
	sus.mustPress = note.mustPress
	sus.animSuffix = note.animSuffix
	sus.noAnimation = note.noAnimation
	sus.isPixelNote = note.isPixelNote
	return sus
