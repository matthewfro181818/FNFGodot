extends Node

@export_category('Notes')
const NoteStyleData = preload("uid://by78myum2dx8h")
const NoteSplash = preload("uid://cct1klvoc2ebg")
const Note = preload("uid://deen57blmmd13")

const EventNoteUtils = preload("uid://dqymf0mowy0dt")
const NoteParser = preload("uid://h8nnpmoaoq70")
const NoteSustain = preload("uid://bhagylovx7ods")

const NoteHit = preload("uid://dx85xmyb5icvh")
const StrumNote = preload("uid://coipwnceltckt")

const StrumOffset: float = 112.0
const NOTE_SPAWN_TIME: float = 1000

static var isModding: bool = true
static var inModchartEditor: bool
static var week_data: Dictionary

@export_group("Song Data")
@export var song_folder: String
@export var song_json_file: String 
@export var difficulty: String

var autoStartSong: bool  ##Start the Song when the Song json is loaded. Used in PlayState

##If this is [code]false[/code], will disable the notes, 
##making them stretched and not being created
var generateMusic: bool = true
var exitingSong: bool
var clear_song_after_exiting: bool = true

var songSpeed: float: set = set_song_speed 
var _songLength: float
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
var defaultStrumPos: PackedVector2Array
var defaultStrumAlpha: PackedFloat32Array

var strumLineNotes: SpriteGroup = SpriteGroup.new()#Strum's Group.

var opponentStrums: SpriteGroup = SpriteGroup.new() ##Strum's Oponnent Group.
var playerStrums: SpriteGroup = SpriteGroup.new() ##Strum's Player Group.
var extraStrums: Array[StrumNote]

 ##Returns the player strum. 
##If [member playAsOpponent] = true, returns [member opponentStrums], else, returns [member playerStrums]
var current_player_strum: Array = playerStrums.members

var uiGroup: SpriteGroup = SpriteGroup.new() ##Hud Group.

static var unspawnNotes: Array[Note] ##Unspawn notes.
var _unspawnNotesLength: int
var _unspawnIndex: int
var _respawnIndex: int
var respawnNotes: bool
var notes: SpriteGroup = SpriteGroup.new()
var noteSpawnTime: float = NOTE_SPAWN_TIME

var hitNotes: Array[Note]

var canHitNotes: bool = true

var _splashes_loaded: Dictionary

var splashesEnabled: bool = ClientPrefs.data.splashesEnabled
var opponentSplashes: bool = splashesEnabled and ClientPrefs.data.opponentSplashes
var grpNoteSplashes: SpriteGroup = SpriteGroup.new() ##Note Splashes Group.
var grpNoteHoldSplashes: Dictionary[int,NoteSplash] ##Note Hold Splashes Group.

static var isPixelStage: bool
@export var arrowStyle: StringName = &'funkin'
@export var splashStyle: StringName = &'NoteSplashes'
@export var splashHoldStyle: StringName = &'HoldNoteSplashes'



@export_group("Play Options")


##Play as Opponent, reversing the sides.
@export var playAsOpponent: bool = ClientPrefs.data.playAsOpponent: set = _set_play_opponent

##When activate, the notes will be hitted automatically.
@export var botplay: bool = ClientPrefs.data.botplay: set = _set_botplay

@export var downScroll: bool = ClientPrefs.data.downscroll: set = _set_downscroll
@export var middleScroll: bool = ClientPrefs.data.middlescroll: set = _set_middlescroll
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

func _ready() -> void:
	loadSong()
	loadSongObjects()
	if autoStartSong: startSong()

func _setup_hud() -> void:
	_create_strums()
	if Paths.is_on_mobile: createMobileGUI()

func createMobileGUI() -> void:
	##HitBox
	touch_state = load("uid://caqru406gega1").new()
	add_child(touch_state)
	touch_state.z_index = 1



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


func loadSongObjects(): ##Load song data. Used in PlayState
	var arrow_s = SONG.get('arrowStyle')
	var splash_s = SONG.get('splashStyle')
	var hold_s = SONG.get('holdSplashStyle')
	
	if arrow_s: arrowStyle = arrow_s
	else: arrowStyle = &'pixel' if isPixelStage else &'funkin'
	
	if splash_s: splashStyle = splash_s
	if hold_s: splashHoldStyle = hold_s
	
	_setup_hud()
	
	_respawnIndex = 0
	_unspawnIndex = 0
	if !SONG: return
	loadNotes()

func loadNotes():
	if !unspawnNotes:  unspawnNotes = NoteParser.getNotesFromData(SONG)
	_unspawnNotesLength = unspawnNotes.size()
	reloadNotes()

func clearSongNotes():
	for i in notes.members: i.queue_free()
	notes.members.clear()
	_respawnIndex = 0
	_unspawnIndex = 0
	unspawnNotes.clear()

func startSong() -> void: ##Begins the song. See also [method loadSong].
	if !Conductor.songs: return
	Conductor.resumeSongs()
	_isSongStarted = true
	_songLength = Conductor.songs[0].stream.get_length()*1000.0

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

#region Strums
func updateStrumsPosition():
	var screen_center = ScreenUtils.screenCenter
	var key_div = keyCount*0.5
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
	var index = defaultStrumPos.size()
	while index: index -= 1; defaultStrumPos[index].y = strumY; 

func _create_strums() -> void:
	StrumNote.keyCount = keyCount
	for i in strumLineNotes.members: i.queue_free()
	
	strumLineNotes.members.clear()
	playerStrums.members.clear()
	opponentStrums.members.clear()
	
	updateStrumsPosition()
	var i: int = keyCount
	i = keyCount*2
	while i > keyCount: #Player Strums
		i -= 1
		var strum = createStrum(i)
		strum.mustPress = !botplay
		playerStrums.insert(0,strum)
		strumLineNotes.insert(0,strum)
		strum._position = defaultStrumPos[i]
		strum.mustPress = !playAsOpponent and !botplay
		strum.modulate.a = defaultStrumAlpha[i]
	while i: #Opponent Strums
		i -= 1
		var strum = createStrum(i)
		opponentStrums.insert(0,strum)
		strumLineNotes.insert(0,strum)
		strum._position = defaultStrumPos[i]
		strum.mustPress = playAsOpponent and !botplay
		strum.modulate.a = defaultStrumAlpha[i]
	
	
func createStrum(i: int) -> StrumNote:
	var strum = StrumNote.new(i)
	strum.loadFromStyle(arrowStyle)
	strum.downscroll = downScroll
	strum.name = &"StrumNote"
	return strum

func _update_strum_must_press() -> void:
	var strums = strumLineNotes.members
	if !strums: return
	
	var index: int = strums.size()
	while index:
		index -= 1
		if botplay: strums[index].mustPress = false; continue
		if index < keyCount: strums[index].mustPress = playAsOpponent
		else: strums[index].mustPress = !playAsOpponent

func _strum_confirm_from_note(note: Note) -> void:
	var strum: StrumNote = note.strumNote; if !strum: return
	if !strum.mustPress and (!note.isSustainNote or note.isEndSustain): strum.strumConfirm(note.hitAnim); return
	strum.hitTime = 0.0; strum.animation.play(note.hitAnim,true); strum.return_to_static_on_finish = false
#endregion

func _process(_d) -> void:  if generateMusic: _songPos = Conductor.songPositionDelayed; updateNotes()

#region Note Methods
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
			elif !updateNote(note): continue
			members.remove_at(note_index)
	else: while note_index: note_index -= 1; if !updateNote(members[note_index]): members.remove_at(note_index)
	if !botplay and canHitNotes: _check_hit_notes()

func _check_unspawn_notes() -> void:
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
	var index: int = hitNotes.size()
	while index: 
		index -= 1
		var i = hitNotes[index]
		if i: hitNotes[index] = null; if Input.is_action_just_pressed(i.hit_action): preHitNote(i)

##Spawns the note
func spawnNote(note: Note) -> void: if note: addNoteToGroup(note,note.noteGroup if note.noteGroup else notes)

func addNoteToGroup(note: Note, group: Node) -> void:
	if group != notes: notes.members.append(note)
	if group is SpriteGroup:
		if note.isSustainNote: group.insert(0,note)
		else: group.add(note)
		return
	
	group.add_child(note)
	if note.isSustainNote: group.move_child(note,0)

func updateNote(n: Note) -> bool:
	if !n or !n._is_processing: return false
	
	var isSus: bool = n.isSustainNote
	var opponentNote: bool = n.autoHit or botplay or !isPlayerNote(n)
	n.noteSpeed = songSpeed
	n.updateNote()
	
	if !(isSus and n.isBeingDestroyed) and n.distance <= n.missOffset:
		if not n.missed and !opponentNote and not n.ignoreNote: noteMiss(n) 
		return true
	
	if !n.canBeHit or !canHitNotes: return true
	
	if opponentNote:
		if not n.ignoreNote and (isSus or n.distance <= 0.0): preHitNote(n)
		return true
	
	if isSus:
		var hit_action = n.noteParent.hit_action
		if Input.is_action_pressed(hit_action): preHitNote(n)
		elif !n.isEndSustain and Input.is_action_just_released(hit_action): noteMiss(n,false)
		return true
	
	var l = hitNotes[n.noteData]
	if !l or absf(n.distance) < absf(l.distance): hitNotes[n.noteData] = n
	return true

func preHitNote(note: Note):
	if !note: return
	if !note.isSustainNote: note.updateRating()
	note.wasHit = true
	note.judgementTime = _songPos
	note.hitAnim = &'press' if note.isEndSustain and isPlayerNote(note) else &'confirm'
	hitNote(note)

func hitNote(note: Note) -> void: ##Called when the hits a [NoteBase] 
	if !note: return
	var playerNote = isPlayerNote(note)
	var strum: StrumNote = note.strumNote
	if note.isEndSustain: 
		if !playerNote: _hide_hold_splash_from_note(note)
		else: 
			var holdSplash: NoteSplash = grpNoteHoldSplashes.get(strum.get_instance_id()); 
			if holdSplash: holdSplash.animation.play(&'end')
	if splashAllowed(note): createSplash(note);
	note._on_hit()
	_strum_confirm_from_note(note)

func isPlayerNote(note: Note) -> bool: return note.mustPress != playAsOpponent

func noteMiss(note: Note, kill_note: bool = true) -> void: ##Called when the player miss a [Note]
	if !note:return
	note.missed = true
	note.judgementTime = _songPos
	if note.isSustainNote: _disable_note_sustains(note.noteParent); _hide_hold_splash_from_note(note)
	if kill_note: note.kill()

func reloadNotes() -> void: 
	var index: int = unspawnNotes.size()
	while index: index -= 1; reloadNote(unspawnNotes[index]);

func reloadNote(note: Note):
	note.loadFromStyle(arrowStyle)
	var noteStrum: StrumNote = strumLineNotes.members.get((note.noteData + keyCount) if note.mustPress else note.noteData)
	note.strumNote = noteStrum
	note.isPixelNote = isPixelStage
	note.noteGroup = notes
	note.resetNote()
	if note.isSustainNote: note.splashStyle = splashHoldStyle
	else: note.splashStyle = note.splashStyle

func _disable_note_sustains(note: Note) -> void:
	if note: for sus in note.sustainParents: sus.blockHit = true; sus.ignoreNote = true; sus.modulate.a = 0.3
#endregion

#region Splash Methods
func createSplash(note) -> NoteSplash: ##Create Splash
	var strum: StrumNote = note.strumNote
	if !strum or !strum.visible: return
	
	var splashParent = note.splashParent
	var splash: NoteSplash = _check_splash_from_note(note)
	if !splash:
		splash = _create_splash_from_note(note); if !splash: return
		if splashParent: grpNoteSplashes.members.append(splash); splashParent.add_child(splash)
		else: grpNoteSplashes.add(splash)
	else: 
		splash.strum = strum
		splash.show_splash()
		if splashParent: splash.reparent(splashParent,false)
		elif splash._is_custom_parent: splash.reparent(grpNoteSplashes,false)
	
	if splash.holdSplash: grpNoteHoldSplashes[strum.get_instance_id()] = splash
	splash._is_custom_parent = !!splashParent
	splash.isPixelSplash = isPixelStage
	return splash

func _create_splash_from_note(note: Note) -> NoteSplash:
	if !note: return
	var splash = NoteSplash.loadSplashFromNote(note); if !splash: return
	splash.strum = note.strumNote
	_get_splash_storage(note.splashStyle,note.splashName,note.splashPrefix).append(splash)
	return splash

func _get_splash_storage(style: StringName, name: StringName, prefix: StringName) -> Array:
	return _splashes_loaded.get_or_add(style,{}).get_or_add(name,{}).get_or_add(prefix,[])

func _check_splash_from_note(note: Note) -> NoteSplash:
	if !note.isSustainNote: return _check_splash(note.splashStyle,note.splashName,note.splashPrefix)
	if !note.strumNote: return
	
	var splash: NoteSplash = grpNoteHoldSplashes.get(note.strumNote.get_instance_id())
	if splash and\
		splash.splashStyle == note.splashStyle and \
		splash.splashPrefix == note.splashPrefix and \
		splash.splashName == note.splashName: return splash
	return _check_splash(note.splashStyle,note.splashName,note.splashPrefix)


func _check_splash(style: StringName, splash_name: StringName, prefix: StringName) -> NoteSplash:
	for s in _get_splash_storage(style,splash_name,prefix): if !s.visible: return s
	return

func splashAllowed(n: Note) -> bool:
	if n.isSustainNote: return !n.splashDisabled and splashesEnabled and n.ratingMod <= 1 and !n.isBeingDestroyed
	return !n.splashDisabled and splashesEnabled and n.ratingMod <= 1 and (isPlayerNote(n) or opponentSplashes)

func _hide_hold_splash_from_note(note: Note):
	if !note or !note.strumNote: return
	var id = note.strumNote.get_instance_id()
	var splash = grpNoteHoldSplashes.get(id)
	if splash: splash.visible = false; grpNoteHoldSplashes[id] = null
#endregion

func destroy(absolute: bool = true): ##Remove the state
	Conductor.clearSong(exitingSong)
	
	if absolute: clear(); queue_free(); return
	
	Paths.clearLocalFiles()
	if isModding: NoteStyleData.styles_loaded.clear()
	for note in notes.members: note.kill()


#region Setters
func _set_botplay(is_botplay: bool) -> void: botplay = is_botplay; _update_strum_must_press()

func set_song_speed(value): songSpeed = value; noteSpawnTime = NOTE_SPAWN_TIME/(value*0.5)

func _set_play_opponent(isOpponent: bool = playAsOpponent) -> void:
	if playAsOpponent == isOpponent: return
	playAsOpponent = isOpponent
	_update_strum_must_press()
	current_player_strum = (opponentStrums if isOpponent else playerStrums).members
	if middleScroll: updateStrumsPosition()
	
func _set_downscroll(value):
	if downScroll == value: return
	downScroll = value
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
	
	Paths.clearLocalFiles()
	inModchartEditor = false
	isPixelStage = false
	
func clear_splashes():
	for file in _splashes_loaded.values(): for style in file.values(): for prefix in style.values(): for splashes in prefix: splashes.queue_free()
	grpNoteHoldSplashes.clear()
	grpNoteSplashes.members.clear()
	_splashes_loaded.clear()
