extends Node
#region Consts
const SolidSprite = preload("res://source/objects/Sprite/SolidSprite.gd")
const BLOCK_SIZE = Vector2(16,16)
const CHESS_SCALE = Vector2(3,3)
const CHESS_REAL_SIZE = BLOCK_SIZE*CHESS_SCALE
const ICON_SCALE = Vector2(0.6,0.6)
const CHESS_OFFSET: Vector2 = Vector2(40,100)

const Song = preload("res://source/backend/Song.gd")
const ChessNotes = preload("uid://qtqqk5lrhuyp")

const MouseSelection = preload("uid://o58vhxjknfoe")

const Note = preload("uid://deen57blmmd13")
const Note_Chart = preload("uid://dxl7cofy02rr5")

const StrumNote = preload("uid://coipwnceltckt")

const EventNoteUtils = preload("uid://dqymf0mowy0dt")
const EventChart = preload("uid://bx6pdllgm02et")

const Waveform = preload("res://source/states/Editors/ChartEditor/Waveform.gd")

const ButtonRangeScene = preload("uid://b1a3jlb7iu130")
const ButtonRange = preload("uid://bscbt2dibch22")

const EVENT_VARIABLES_OFFSET: Vector2 = Vector2(180,50)
const EVENT_VARIABLES_LIMIT_Y: float = 100

const STEP_LENGTH: int = 16

const Icon = preload("res://source/objects/UI/Icon.gd")
const PlayState = preload("uid://cg2ig10imhwri")

static var back_to: Variant
#endregion

#region Mouse Properties
@export_group('Mouse Properties')
var mouse_selection = MouseSelection.new()
var mouse_erase_notes: bool
var mouse_sustain_note: bool
var mouse_create_note: bool

var mouse_pos: Vector2
var mouse_song_position: float

@onready var line_rect: SolidSprite = SolidSprite.new()
@onready var mouse_rect_follow: SolidSprite = $ChessControl/MouseRect

var is_shift_pressed: bool
#endregion

#region Chess
@onready var chess_control: Node2D = $ChessControl
@onready var chess_opponent: Chess = ChessNotes.new()
@onready var chess_player: Chess = ChessNotes.new()
@onready var chess_events: Chess = Chess.new()

@onready var chess_array: Array[Chess] = [chess_opponent,chess_player,chess_events]
@onready var note_chess: Array[Chess] = [chess_player,chess_opponent]
#endregion

var start_song_from_current_position: bool = true
var update_notes: bool
var update_events: bool

#region Section Data
static var curSection: int
var curSectionData: Dictionary 
var _song_notes: Array
var curSectionNotes: Array 

var curSectionTime: float
var curSectionEndTime: float

var autoSwapSection: bool = true

@onready var hit_section := $"TabContainer/Section/HitSection"
@onready var gf_section := $"TabContainer/Section/GFSection"

@onready var new_bpm_value := $"TabContainer/Section/NewBPM"
@onready var new_bpm_change := $"TabContainer/Section/ChangeBPM"

@onready var section_copy_offset := $TabContainer/Section/SectionCopyOffset
#endregion

#region Notes Data
@export_category('Note Properties')
var strums_created: Array[StrumNote]
var hit_times: Array

var notes_selected: Array

var _notes_unspawned: Array[Array]
var _notes_created: Array[Note_Chart]

var cur_note_index: int

@onready var note_current_strum_time := $"TabContainer/Note/StrumTime"
@onready var note_current_sustain_length :=$"TabContainer/Note/SustainLength"
@onready var note_current_type := $"TabContainer/Note/NoteType"

@onready var note_type_menu := $TabContainer/Note/NoteType
@onready var note_type_popup: PopupMenu = note_type_menu.get_popup()
@onready var note_skin := $"TabContainer/Note/NoteStyle"


@onready var arrowSkin: StringName:
	set(value):
		SONG.arrowSkin = value
		arrowSkin = value if value else StringName('noteSkins/NOTE_assets')
	get(): return SONG.get('arrowSkin','noteSkins/NOTE_assets')
#endregion

#region Song Data
@export_group('SONG Data')
@onready var song_info := $"Editor Info/Song Info/SongInfo"
@export var song_json: StringName
@export var difficulty: StringName
@export var song_folder: StringName

var SONG: Dictionary:
	get(): return Conductor.songJson

static var songPosition: float
var keyCount: int = 4

var stepCrochet: float:
	get(): return Conductor.stepCrochet

var bpm: float:
	set(value): SONG.bpm = value
	get(): return SONG.get('bpm',0)

@onready var song_name := $"TabContainer/Song/Song"
@onready var song_bpm :=$"TabContainer/Song/BPM"
@onready var song_speed :=$"TabContainer/Song/Speed"

@onready var bfCharacters := $"TabContainer/Song/bfCharacters"
@onready var dadCharacters :=$"TabContainer/Song/dadCharacters"
@onready var gfCharacters :=$"TabContainer/Song/gfCharacters"

@onready var bfCharactersPop: PopupMenu = bfCharacters.get_popup()
@onready var dadCharactersPop: PopupMenu = dadCharacters.get_popup()
@onready var gfCharactersPop: PopupMenu = gfCharacters.get_popup()

@onready var stage := $"TabContainer/Song/Stage"
@onready var stagePop: PopupMenu = stage.get_popup()

var song_playing: bool:
	set(play):
		if play: Conductor.resumeSongs()
		else: Conductor.pauseSongs()
		song_playing = play

#endregion

#region Event Data
var _events_created: Array[EventChart]
var event_variables: Array
var event_selected: EventChart

@onready var current_event_section_index: int
@onready var events_data: Array
@onready var events_panel := $"TabContainer/Event"
@onready var events_menu := $"TabContainer/Event/Events"
@onready var events_popup: PopupMenu = events_menu.get_popup()
@onready var event_description := $"TabContainer/Event/EventDescription"
@onready var event_variable_container := $"TabContainer/Event/VariablesContainer/Grid"
@onready var event_index := $"TabContainer/Event/EventIndex"
#endregion

#region Characters Data
var characters_data: Dictionary
var iconP1: Icon = Icon.new()
var iconP2: Icon = Icon.new()

var icons: Array[Icon] = [iconP1,iconP2]

var player1: StringName:
	set(c):
		if player1 == c: return
		player1 = c
		if bfCharacters: bfCharacters.text = c
		
		SONG.set('player1',player1)
		
		getCharData(c)
		updateIcons()

var player2: StringName:
	set(c):
		if player2 == c: return
		player2 = c
		if dadCharacters: dadCharacters.text = c
		
		SONG.player2 = player2
		
		getCharData(c)
		updateIcons()

var gf: StringName:
	set(g):
		if g == gf: return
		gf = g
		if gfCharacters:gfCharacters.text = g
		SONG.gfVersion = gf
#endregion

#region Editor Data
@export_group('Chart Data')
var cur_zoom: float = 1.0: set = set_zoom

@onready var chart_waveform = Waveform.new()

@onready var chart_set_waveform := $"TabContainer/Editor/WaveformMenu"
@onready var chart_waveform_pop: PopupMenu = chart_set_waveform.get_popup()

#region Create Chart
@onready var new_chart_song_name := $"CreateChart/SongChart"
@onready var new_chart_bpm := $"CreateChart/NewBpm"
#endregion

#endregion



func _init(json: StringName = song_json,_difficulty: StringName = difficulty,folder: StringName = song_folder) -> void:
	song_json = json
	difficulty = _difficulty
	song_folder = folder
	
func _ready():
	mouse_selection.can_select = false
	name = 'Chart Editor'
	Note_Chart.chess_rect_size = CHESS_REAL_SIZE
	
	Conductor.section_hit_once.connect(func():
		if autoSwapSection: set_section(Conductor.section)
	)
	Conductor.beat_hit.connect(icon_beat)
	Conductor.bpm_changes.connect(updateBpm)
	
	mouse_rect_follow.scale = CHESS_REAL_SIZE
	add_child(mouse_selection)
	var bg = Sprite2D.new()
	bg.texture = Paths.texture('menuDesat')
	bg.centered = false
	bg.modulate = Color(0.1,0.1,0.1)
	#add_child(bg)
	
	
	for i in chess_array:
		i.scale = CHESS_SCALE
		i.rect_size = BLOCK_SIZE
		chess_control.add_child(i)
		
	#region Events
	chess_events.steps = 1
	chess_events.length = 16
	
	chess_events.modulate = Color.DARK_GRAY
	chess_events.name = &'ChessEvents'
	
	var eventIcon = Sprite2D.new()
	eventIcon.texture = Paths.texture('eventArrow')
	eventIcon.position = Vector2(chess_events.global_position.x,20)
	eventIcon.scale = ICON_SCALE - Vector2(0.2,0.2)
	eventIcon.centered = false
	add_child(eventIcon)
	#endregion
	
	for i in note_chess:
		i.steps = keyCount
		i.length = 16
		for beat in keyCount:
			var color_rect: ColorRect = ColorRect.new()
			color_rect.size = Vector2(BLOCK_SIZE.x*keyCount,1.0)
			updateBeatLinePosition(color_rect,beat)
			color_rect.color = Color(0.8,0,0)
			color_rect.name = &'Beat'+String.num_int64(beat)
			i.add_child(color_rect)
	
	chess_opponent.gui_input.connect(_on_chess_input.bind(chess_opponent))
	chess_opponent.name = &'ChessOpponent'
	chess_opponent.position.x += CHESS_REAL_SIZE.x*2
	
	iconP2._position = Vector2(chess_opponent.position.x + CHESS_REAL_SIZE.x*(keyCount/3.0),-10)
	iconP2.scale_lerp = true

	#Player Chess
	chess_player.gui_input.connect(_on_chess_input.bind(chess_player))
	chess_player.name = &'ChessPlayer'
	chess_player.position.x = CHESS_REAL_SIZE.x*(keyCount+5)
	
	iconP1._position = Vector2(chess_player.position.x + CHESS_REAL_SIZE.x*(keyCount/3.0),-10)
	iconP1.scale_lerp = true
	
	line_rect.position.x = chess_events.position.x
	line_rect.z_index = 1
	line_rect.name = &'Line Note'
	
	chess_control.add_child(line_rect)
	
	add_child(iconP1)
	add_child(iconP2)
	
	update_line_rect()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	note_type_popup.index_pressed.connect(_on_note_type_index_pressed)
	events_popup.index_pressed.connect(_on_event_index_pressed)
	
	#Load Characters
	dadCharactersPop.index_pressed.connect(func(i):
		player2 = dadCharactersPop.get_item_text(i)
		changeCharacter(player2,'player2')
	)
	
	bfCharactersPop.index_pressed.connect(func(i):
		player1 = bfCharactersPop.get_item_text(i)
		changeCharacter(player1,'player1')
	)
	gfCharactersPop.index_pressed.connect(func(i):
		gf = gfCharactersPop.get_item_text(i)
		changeCharacter(player1,'gfVersion')
	)
	
	stagePop.index_pressed.connect(_on_stage_index_pressed)
	
	if !SONG: _load_song_data()
	
	_update_song_data()
	
	set_song_position(songPosition)
	set_section(curSection)
	
#region Chart Methods
func createChart() -> void:
	Conductor.clearSong(true)
	var new_song_name = new_chart_song_name.text
	
	var mod_founded = Paths.getModFolder(new_song_name)
	if mod_founded:
		new_song_name = new_song_name.right(-mod_founded.length()-1)
		Paths.curMod = mod_founded
	
	if new_song_name.begins_with('songs/'): new_song_name = new_song_name.right(-6)
	
	var new_json = Song.getChartBase()
	new_json.song = new_song_name
	Song.folder = new_song_name
	Song.songName = new_song_name
	
	Conductor.songJson = new_json
	
	Conductor.loadedSong()
	
	_update_song_data()
	eraseNotes()
	
	for i in _events_created: i.queue_free()
	_events_created.clear()
	
	set_section(0)

func loadChart(file: String):
	song_folder = ''
	eraseNotes()
	Conductor.clearSong(true)
	Paths.curMod = Paths.getModFolder(file)
	_load_song_data(file,'')
	set_section(0)

func updateBpm():
	note_current_sustain_length.step = Conductor.stepCrochet/2.0
	_update_chart_positions()
	
func changeBpm(to: float = new_bpm_value.value) -> void:
	if curSectionData:
		curSectionData.changeBPM = true
		curSectionData.bpm = to
	updateBpm()
#endregion

#region Editor Methods
func set_zoom(new_zoom: float):
	cur_zoom = new_zoom
	var steps: int = 16*int(new_zoom)
	for i in chess_array:
		i.steps = steps
		i.draw_chess()
		for beat in range(1,4): updateBeatLinePosition(i.get_node_or_null('Beat'+str(beat)),beat)
	
	#Update Sustain
	for i in _notes_created: i.sustain_scale = new_zoom
	
	updateNotesPositions()
	_update_chart_positions()
	_update_chess_notes_position()
	
func updateBeatLinePosition(line: ColorRect, beat: int = 0):
	if line: line.position = Vector2(0,4*beat*BLOCK_SIZE.y*cur_zoom)

func load_game():
	song_playing = false
	autoSwapSection = false
	set_process_input(false)
	Conductor.stopSongs()
	
	var playstate = PlayState.new()
	if update_notes: playstate._notes_preload.clear()
	if update_events: playstate._events_preload.clear()
	

	Global.swapTree(playstate)

func leave_editor():
	if !back_to: return
	Global.swapTree(back_to)

func setWaveform(audio: String):
	chart_set_waveform.text = audio
	#var audio_node = Conductor.get_node_or_null(audio)
	#if chart_waveform.waveform_audio:
		#chart_waveform.waveform_audio.bus = 'Master'
		
	#if audio_node:
		#audio_node.bus = 'Waveform'
	#chart_waveform.waveform_audio = audio_node
	#chart_waveform.draw_waveform()

func _update_chart_positions():
	var cal = ((-songPosition/stepCrochet) + Conductor.step_offset) * cur_zoom * CHESS_REAL_SIZE.y + 50
	chess_control.position.y = cal
	line_rect.position.y = -cal + 50

func _update_chess_notes_position():
	var chess_position = curSection*16.0*CHESS_REAL_SIZE.y*cur_zoom
	for i in chess_array: i.position.y = chess_position
	
func update_line_rect():
	line_rect.scale = Vector2(
		chess_player.position.x - line_rect.position.x + CHESS_REAL_SIZE.x*keyCount, 
		6.0
	)
	
#endregion

#region Character methods
func getCharData(character: StringName) -> Dictionary:
	if characters_data.has(character): return characters_data[character]
	
	var file = Paths.character(character+'.json')
	if !file: file = Character.getCharacterBaseData()
	characters_data[character] = file
	return file

func changeCharacter(new_character: String, player_to_change: String = 'player1'):
	SONG.set(player_to_change,new_character)
	updateIcons()
#endregion

#region Song methods
func _load_song_data(json_name: StringName = song_json,_difficulty: StringName = difficulty):
	Conductor.loadSong(json_name,_difficulty)
	song_json = json_name.get_file()

func loadAudioStreams():
	Conductor.stopSongs(true)
	Conductor.loadSongsStreams()
	chart_waveform_pop.clear()
	for i in Conductor.songs:
		if !i: continue
		i.bus = 'Waveform'
		chart_waveform_pop.add_item(i.name)

func set_song_position(pos: float, conductor_position: bool = true):
	pos = clampf(pos,0,Conductor.songLength)
	songPosition = pos
	
	if conductor_position: Conductor.seek(pos)
	
	_update_chart_positions()
	_update_song_info()
	cur_note_index = minf(cur_note_index,hit_times.size()-1)
	
	if !hit_times:
		return
	
	while cur_note_index >= 0 and hit_times[cur_note_index][0] >= pos-20:
		var note = hit_times[cur_note_index][3]
		if note:
			note.modulate = Color.WHITE
		cur_note_index -= 1
	
	for i in range(cur_note_index+1,hit_times.size()):
		var note = hit_times[i]
		if note[0] >= pos:
			break
		
		if cur_note_index == i:
			continue
		
		var isSustain = note[3] == null
		if !isSustain:
			note[3].modulate = Color.DARK_GRAY
			
		
		cur_note_index = i
		if strums_created and song_playing:
			var note_direction = note[1]%keyCount
			var strum = strums_created[(note_direction + keyCount) if note[2] else note_direction]
			strum.strumConfirm()
#endregion

#region Section Methods
func set_section(section: int = curSection):
	if !section:
		new_bpm_change.disabled = true
	else:
		new_bpm_change.disabled = false
	curSection = section
	
	while section >= _song_notes.size():
		_notes_unspawned.append(Array([],TYPE_OBJECT,"Node2D",Note_Chart))
		_song_notes.append(Song.getSectionBase())
		
	curSectionData = _song_notes[section]
	curSectionData.merge(Song.getSectionBase())
	curSectionNotes = curSectionData.get('sectionNotes',[])
	
	curSectionTime = Conductor.get_section_time(section)
	curSectionEndTime = curSectionTime + Conductor.crochet*curSectionData.sectionBeats
	_create_notes_section()
	_create_events_section()
	_update_section_data()
	_update_chess_notes_position()
	
func get_section_data(from: int) -> Dictionary:
	if !_song_notes: return {}
	if curSection == from: return curSectionData
	
	var dic = ArrayUtils.get_array_index(_song_notes,from,{})
	dic.merge(Song.getSectionBase())
	return dic

func get_section_note_data(from: int):
	if curSection == from: return curSectionNotes
	return ArrayUtils.get_array_index(_song_notes,from,{}).get('sectionNotes',[])

func copyLastSection(add: bool = true):
	var section_to_copy = curSection-section_copy_offset.value
	if section_to_copy == curSection or !ArrayUtils.array_has_index(_song_notes,section_to_copy):
		return
	
	var section_time = curSectionTime - Conductor.get_section_time(section_to_copy)
	
	var notes = _song_notes[section_to_copy]
	var notes_added: Array = curSectionNotes if add else []
	for i in notes.get('sectionNotes',[]):
		var note_data = i.duplicate()
		note_data[0] += section_time
		notes_added.append(note_data)
	if add:
		notes_added.sort_custom(ArrayUtils.sort_array_from_first_index)
	else:
		killNotes()
		_song_notes[curSection].sectionNotes = notes_added
	_create_notes_section()
	
func swapNoteSection():
	for i in _notes_created:
		var noteData = (i.noteData + keyCount)%(keyCount*2)
		i.mustPress = not i.mustPress
		i.noteData = noteData
		updateNotePosition(i)
	detectNotesToHit()

func flipPlayerNotesDir():
	flipNotes(true)

func flipAllNotes():
	flipNotes()
	flipNotes(true)
	
func flipNotes(player: bool = false):
	for i in _notes_created:
		if i.mustPress == player:
			i.noteData = absi(keyCount - 1 - i.noteData)
			i.reloadNote()
			updateNotePosition(i)
func eraseSection():
	eraseNotes()
	eraseEvents()

#endregion

#region Song Information Methods
func _update_song_info():
	song_info.text = 'Song Position: '+String.num_int64(int(songPosition))+'\nBeat: '+String.num_int64(Conductor.beat)+\
	'\nStep: '+String.num_int64(Conductor.step)+'\nSection: '+String.num_int64(Conductor.section)


func _update_icon_in_section():
	iconP1.modulate = Color.WHITE if curSectionData.mustHitSection else Color.DARK_GRAY
	iconP2.modulate = Color.DARK_GRAY if curSectionData.mustHitSection else Color.WHITE
	
func _update_section_data():
	hit_section.set_pressed_no_signal(curSectionData.mustHitSection)
	gf_section.set_pressed_no_signal(curSectionData.gfSection)
	
	_update_icon_in_section()
	
	
	new_bpm_change.set_pressed_no_signal(curSectionData.get('changeBPM',false))
	new_bpm_value.value = curSectionData.get('bpm',bpm) if new_bpm_change.button_pressed else bpm
	
	
func _update_song_data():
	updateBpm()
	
	_song_notes = SONG.get('notes',[])
	events_data = SONG.get('events',[])
	player1 = SONG.get('player1','bf')
	player2 = SONG.get('player2','bf')
	gf = SONG.get('gfVersion','bf')
	arrowSkin = SONG.get('arrowSkin','')
	
	song_speed.value = float(SONG.get('speed',1.0))
	
	song_name.text = Song.songName
	song_bpm.value = Conductor.bpm
	
	stage.text = SONG.get('stage','stage')
	_notes_unspawned.clear()
	for i in SONG.get('notes'):
		_notes_unspawned.append(Array([],TYPE_OBJECT,"Node2D",Note_Chart))
	loadAudioStreams()
#endregion

#region Note methods
func createChessNote(time: float,data: int, chess: Chess) -> Variant:
	var founded: bool = false
	var mustPress: bool = !curSectionData.get('mustHitSection',false)
	if !founded: return null
	
	var songPos = getStepFromY(time)
	
	var note = addNote(songPos,(data + keyCount) if mustPress else data)
	detectNotesToHit()
	return note

func createEvent(time: float):
	var songPos = getStepFromY(time)
	addEventToJson(addEvent(getEventData(songPos)))
	
func addNote(strumTime: float, noteData: int, section: int = curSection) -> Note_Chart:
	var note = Note_Chart.new(noteData%keyCount)
	note.strumTime = strumTime
	note.loadFromStyle('funkin')
	note.mustPress = detectNoteMustPress(noteData,section)
	
	note.sustain_scale = cur_zoom
	updateNoteData(note)
	note.section_data = getNoteData(note)
	var index: int = 0
	for i in _notes_created:
		if i.strumTime == note.strumTime and i.noteData == note.noteData: removeNoteFromJson(index); break
		if i.strumTime >= note.strumTime: break
		index += 1
	_notes_created.insert(index,note)
	addNoteToScene(note)
	return note

func updateNotePosition(note: Note_Chart) -> void:
	note.position = Vector2(
		CHESS_REAL_SIZE.x * (note.noteData % keyCount) + (chess_player if note.mustPress else chess_opponent).position.x, 
		getNotePositionY(note.strumTime)
	)

func updateNotesPositions() -> void: for i in _notes_created: updateNotePosition(i)

func updateEventsPositions() -> void: for i in _events_created: i.position.y = getNotePositionY(i.strumTime)

func updateNoteData(note: Note_Chart, section: int = curSection):
	var section_data = curSectionData
	if section != curSection: section_data = get_section_data(section)
	note.noteData %= keyCount
	if section_data.mustHitSection and !note.mustPress or note.mustPress and !section_data.mustHitSection: note.noteData += 4
	
func addNoteToJson(note: Note_Chart, section: int = -1):
	if !note:return
	if section == -1: section = Conductor.get_section(note.strumTime)
	
	var section_notes = get_section_note_data(section)
	var at: int = section_notes.size()
	for i in range(section_notes.size()): if section_notes[i][0] >= note.strumTime:at = i; break
	
	update_notes = true
	section_notes.insert(at,note.section_data)

func addNoteToScene(note: Note_Chart): chess_control.add_child(note); updateNotePosition(note)
	
static func getNoteData(note: Note_Chart):
	var data = [0.0,0,0.0] #[strumTime,noteData,sustainLength,noteType]
	if !note: return data
	
	if note.noteType: return [note.strumTime,note.noteData,note.sustainLength,note.noteType]
	return [note.strumTime,note.noteData,note.sustainLength]

func getNotePositionY(strum_time: Variant) -> float: return getNoteStep(strum_time) * CHESS_REAL_SIZE.y * cur_zoom

func getNoteStep(strum_time: float) -> float: return (strum_time / stepCrochet - Conductor.step_offset)

func getNoteAtMouse() -> Note_Chart:
	for i in _notes_created: if MathUtils.is_pos_in_area(mouse_pos,i.global_position,CHESS_REAL_SIZE): return i
	return null
	
func removeNote(note):
	if !note: return
	var index = _notes_created.find(note)
	if index == -1: return
	notes_selected.erase(note)
	_notes_created.remove_at(index)
	
	removeNoteFromJson(index-1)
	
	detectNotesToHit()
	note.queue_free()

func killNotes():
	for i in _notes_created: i.queue_free()
	_notes_created.clear()

func eraseNotes(): killNotes(); curSectionNotes.clear()

func removeNoteFromJson(index: int, section: int = curSection):
	if index == -1: return
	var data = get_section_note_data(section)
	if !data: return
	update_notes = true
	data.remove_at(index)

func selectNote(note: Note_Chart, append: bool = false):
	unselectEvent()
	if !note or note in notes_selected: return
	if !append: unselectNotes()
	
	notes_selected.append(note)
	_update_note_data()

func toggleNote(note: Note_Chart, append: bool = false):
	if !note: return
	if !append: if note in notes_selected: unselectNote(note); return
	selectNote(note,append)
	_update_note_data()

func unselectNote(note: Note_Chart): note.modulate = Color.WHITE; notes_selected.erase(note); _update_note_data()
	
func unselectNotes():
	for i in notes_selected: i.modulate = Color.WHITE
	notes_selected.clear()
	_update_note_data()


func _update_note_data():
	if !notes_selected:
		note_current_strum_time.text = '0.0'
		note_current_sustain_length.line_edit.text = ''
		note_current_type.text = ''
		return
	
	
	var strum_equal: bool = true
	var sustain_equal: bool = true
	var type_equal: bool = true
	
	var first_note = notes_selected[0]
	
	for i in notes_selected.slice(1):
		if strum_equal and first_note.strumTime != i.strumTime:
			strum_equal = false
			
		if sustain_equal and first_note.sustainLength != i.sustainLength:
			sustain_equal = false
			
		if type_equal and first_note.noteType != i.noteType:
			type_equal = false
		
		if not (strum_equal or sustain_equal or type_equal):
			break
	
	note_current_strum_time.text = str(first_note.strumTime) if strum_equal else '...'
	note_current_type.text = first_note.noteType if type_equal else '...'
	
	if sustain_equal: note_current_sustain_length.set_value_no_signal(first_note.sustainLength)
	else: note_current_sustain_length.value_text.text = '...'
	
func detectNoteMustPress(noteData: int,section: int = curSection) -> bool:
	var mustHitSection = get_section_data(section).mustHitSection
	return noteData >= keyCount and not mustHitSection or noteData < keyCount and mustHitSection
	
func _create_notes_section(from: int = curSection):
	for i in _notes_created: i.get_parent().remove_child(i); unselectNote(i)
	chess_opponent.notes.clear()
	chess_player.notes.clear()
	
	_notes_created = _notes_unspawned[from]
	if _notes_created:
		for i in _notes_created: addNoteToScene(i)
		detectNotesToHit()
		return
	
	var section = get_section_data(from)
	if !section: return
	
	for i in section.get('sectionNotes',[]):
		var data = ArrayUtils.get_array_index(i,1,0)
		var note = addNote(i[0],data)
		var noteType = ArrayUtils.get_array_index(i,3,'')
		note.section_data = i
		note.sustainLength = ArrayUtils.get_array_index(i,2,0)
		if noteType: note.noteType = noteType
	detectNotesToHit()

#endregion

#region Event methods
func _create_events_section():
	if _events_created: for i in _events_created: i.queue_free(); _events_created.clear()
	
	if !events_data: return
	
	var start_index: int = current_event_section_index
	while start_index > 0 and curSectionTime < events_data[start_index-1].t: start_index -= 1
	
	var events_length = events_data.size()
	if start_index == -1 or start_index == events_length: current_event_section_index = 0; return
		
	var end_index: int = start_index
	while end_index < events_length and events_data[end_index].t < curSectionEndTime: end_index += 1
	
	
	current_event_section_index = end_index
	
	while start_index < end_index:
		var event = events_data[start_index]
		addEvent(event)
		start_index += 1

func addEvent(event_data: Dictionary) -> EventChart:
	var event: EventChart
	var strumTime = event_data.t
	for i in _events_created:
		if i.t > strumTime: break
		if i.t == strumTime: event = i; break
	
	if !event:
		event = EventChart.new()
		event.t = strumTime
		event.position.y = getNotePositionY(event.t)
		
		chess_control.add_child(event)
		event.name = &'Event'
	
	event.events.append(event_data)
	_events_created.append(event)
	return event

func addEventToJson(event: EventChart):
	var index: int = 0
	for i in events_data:
		if event.t <= i.t: break
		index += 1
	
	update_events = true
	events_data.insert(index,event.events)
	
	if index <= current_event_section_index: current_event_section_index += 1

func removeEvent(event: EventChart, index: int = 0):
	if !event: return
	update_events = true
	event.removeEvent(index)
	if !event.events: removeEventFromSong(event)

func removeEventFromSong(event: EventChart, from_json: bool = true):
	if !event: return
	if from_json: removeEventFromJson(event)
	_events_created.erase(event)
	event.queue_free()
	
func removeEventFromJson(event: EventChart):
	var index = events_data.find(event.json_data)
	if index == -1: return
	events_data.remove_at(index)
	if index <= current_event_section_index: current_event_section_index -= 1
	
func eraseEvents(remove_from_json: bool = true):
	if !remove_from_json: for i in _events_created: i.queue_free(); return
	for i in _events_created: events_data.erase(i.json_data); i.queue_free()
	_events_created.clear()
	
func createEventVariables(event_name: String, variables: Dictionary = {}):
	var default_values = EventNoteUtils.get_event_variables(event_name)
	var pos: Vector2
	for i in event_variable_container.get_children(): event_variable_container.remove_child(i); i.queue_free()
	
	
	var limit_offset_x: float = EVENT_VARIABLES_OFFSET.x
	for i in default_values:
		var data = default_values[i]
		var type = data.type
		var default = data.default_value
		
		var value
		
		var variable_node: Control
		var needs_text: bool = true
		
		if variables.has(i) and typeof(variables[i]) == type: value = variables[i]
		else: value = default

		if data.get('options'):
			variable_node = MenuButton.new()
			variable_node.size = Vector2(150,25)
			variable_node.flat = false
			var variable_pop = variable_node.get_popup()
			
			variable_pop.size.x = variable_node.size.x
			if type:
				for v in data.options:
					if v.begins_with('#'): variable_pop.add_separator(v.right(-1)); continue
					variable_pop.add_item(str(v))
				
			variable_pop.index_pressed.connect(func(index):
				var val = variable_pop.get_item_text(index)
				variable_node.text = val
				if event_selected: event_selected.set_variable(i,val)
			)
		else:
			match type:
				TYPE_BOOL:
					variable_node = CheckBox.new()
					variable_node.set_pressed_no_signal(value)
					variable_node.toggled.connect(func(on):
						if event_selected: event_selected.set_variable(i,on)
					)
				TYPE_FLOAT:
					needs_text = false
					variable_node = ButtonRangeScene.instantiate()
					variable_node.value = float(value)
					variable_node.step = 0.1
					variable_node.value_changed.connect(func(v):
						if event_selected: event_selected.set_variable(i,v)
					)
					variable_node.text = i+': '
				TYPE_INT:
					needs_text = false
					variable_node = ButtonRangeScene.instantiate()
					variable_node.update_min_size_y = true
					variable_node.int_value = true
					variable_node.value = int(value)
					variable_node.value_changed.connect(func(v):
						if event_selected: event_selected.set_variable(i,int(v))
					)
					variable_node.text = i+': '
					
				TYPE_COLOR:
					variable_node = ColorPickerButton.new()
					variable_node.text = 'Select Color'
					variable_node.focus_mode = Control.FOCUS_NONE
					variable_node.color = Color.html(str(value))
					variable_node.color_changed.connect(
						func(color):
							if event_selected: event_selected.set_variable(i,color.to_html())
					)
				_:
					variable_node = LineEdit.new()
					variable_node.size.x = 110
					variable_node.placeholder_text = str(default)
					variable_node.text = str(value)
					variable_node.text_submitted.connect(func(_t):variable_node.release_focus())
					variable_node.text_changed.connect(func(t):if event_selected: event_selected.set_variable(i,t))
					type = TYPE_STRING
				
		
		if !variable_node: continue
		
		#Add Node to Scene
		event_variable_container.add_child(variable_node)
		if needs_text:
			var variable_name = Label.new()
			variable_name.text = i+': '
			variable_name.position = pos
			event_variable_container.add_child(variable_name)
			
			variable_node.position = Vector2(pos.x + variable_name.size.x,pos.y)
			if variable_node is Control:
				limit_offset_x = maxf(limit_offset_x,variable_node.size.x + variable_name.get_combined_minimum_size().x)
		else:
			variable_node.position = pos
			limit_offset_x = maxf(limit_offset_x,variable_node.size.x)
			
		variable_node.name = i
		
		pos.y += EVENT_VARIABLES_OFFSET.y
		if pos.y > EVENT_VARIABLES_LIMIT_Y:
			pos.y = 0
			pos.x += limit_offset_x + 15
			limit_offset_x = EVENT_VARIABLES_OFFSET.x

func setEvent(event_name: StringName):
	if event_selected and event_selected.event_selected_name != event_name: event_selected.replaceEvent(event_name)
	if event_name == events_menu.text: return
	events_menu.text = event_name
	event_description.text = EventNoteUtils.get_event_description(event_name)
	createEventVariables(event_name)
	
func selectEvent(event: EventChart = event_selected) -> void:
	if event_selected: event_selected.modulate = Color.WHITE
	unselectNotes()
	event_selected = event
	event_index.max = event.events.size()-1
	if !event.events: return
	var cur_event = event.events[event.event_index]
	setEvent(cur_event[0])
	for i in event.event_selected_variables: set_event_chart_value(i,event.event_selected_variables[i])
	
func toggleEvent(event_node: EventChart):
	if event_selected and event_node == event_selected: unselectEvent(); return
	selectEvent(event_node)
	
func set_event_chart_value(variable: String, value: Variant):
	var node = event_variable_container.get_node_or_null(variable)
	if !node: return
	if node is ButtonRange: node.value = value
	elif node is Label or node is LineEdit: node.text = str(value)
	elif node is ColorPickerButton: node.color = Color.html(str(value))
		
func unselectEvent():
	if !event_selected: return
	event_selected.modulate = Color.WHITE
	event_selected = null
	
func getEventChartVariables():
	var variables: Dictionary = {}
	for i in event_variable_container.get_children():
		if i is LineEdit: variables[i.name] = i.text; continue
		if i is ButtonRange: variables[i.name] = i.value; continue
	return variables

func getEventAtMouse() -> EventChart:
	for i in _events_created:
		if MathUtils.is_pos_in_area(mouse_pos,i.global_position,CHESS_REAL_SIZE): return i
	return null

func getEventData(strumTime: float) -> Dictionary[StringName,Variant]:
	return {&'t': strumTime, &'e': events_menu.text, &'v': getEventChartVariables()}
#endregion

#region Strum Notes Methods
func enableStrums(enable: bool):
	if !enable:
		for i in strums_created: i.queue_free()
		strums_created.clear()
		return
	for i in range(keyCount*2):
		var strum = StrumNote.new(i%keyCount)
		var group = chess_opponent if i < keyCount else chess_player
		updateStrumScale(strum)
		strum.texture = arrowSkin
		strum.offset_follow_scale = true
		
		line_rect.add_child(strum)
		strum._position.x = -line_rect.global_position.x + group.global_position.x + CHESS_REAL_SIZE.x*strum.data
		strums_created.append(strum)
	#detectNotesToHit()

func updateStrumScale(strum: StrumNote):
	strum.setGraphicScale(CHESS_REAL_SIZE/(strum.pivot_offset*2))
	
func detectNotesToHit():
	var need_to_sort = false
	hit_times.clear()
	for i in _notes_created:
		var note_data = [i.strumTime,i.noteData,i.mustPress,i]
		var isSustain = i.sustainLength > 0.0
		hit_times.append(note_data)
		
		if isSustain:
			note_data[3] = null
			need_to_sort = true
			
			var sustain_data
			for sustain in range(ceili(i.sustainLength/Conductor.stepCrochet)):
				sustain_data = [i.strumTime+(Conductor.stepCrochet*(sustain+1)),i.noteData,i.mustPress,null]
				hit_times.append(sustain_data)
			sustain_data[3] = i
			
	if need_to_sort: hit_times.sort_custom(ArrayUtils.sort_array_from_first_index)
#endregion

func _process(_d) -> void:
	if song_playing: set_song_position(Conductor.songPosition,false)

	var selected_color = Color.WHITE * (1.0 - abs(cos(Time.get_ticks_msec()/400.0))/2.0)
	
	if event_selected: event_selected.modulate = selected_color
	else: for i in notes_selected: i.modulate = selected_color
	
	if mouse_erase_notes:
		removeEventFromSong(getEventAtMouse())
		removeNote(getNoteAtMouse())

func getStepFromY(mouse_y: float) -> float:
	return mouse_y/ cur_zoom / CHESS_REAL_SIZE.y * stepCrochet + (stepCrochet * Conductor.step_offset)

#region Icons
func updateIcons():
	iconP1.reloadIconFromCharacterJson(characters_data.get(player1,{}))
	iconP1.scale *= ICON_SCALE
	iconP1.default_scale = iconP1.scale
	
	iconP2.reloadIconFromCharacterJson(characters_data.get(player2,{}))
	iconP2.scale *= ICON_SCALE
	iconP2.default_scale = iconP2.scale

func icon_beat(): for i in icons: i.scale += i.beat_value
#endregion

#region Keys Methods
func enable_mouse_rect(enable: bool):
	if enable: mouse_rect_follow.modulate.a = 1
	else: mouse_rect_follow.create_tween().tween_property(mouse_rect_follow,'modulate:a',0,0.1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SHIFT: is_shift_pressed = event.pressed; enable_mouse_rect(is_shift_pressed)
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: song_playing = !song_playing
			KEY_ENTER: load_game()
			KEY_BACKSPACE: leave_editor()
			KEY_A: set_song_position(Conductor.get_section_time(curSection-(4 if is_shift_pressed else 1)))
			KEY_D: set_song_position(Conductor.get_section_time(curSection+(4 if is_shift_pressed else 1)))
			KEY_X: if not event.echo: cur_zoom += 0.5
			KEY_Z: if not event.echo: cur_zoom -= 0.5
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			2: mouse_erase_notes = event.pressed
			4: set_song_position(songPosition - stepCrochet * (3 if Input.is_key_pressed(KEY_SHIFT) else 1))
			5: set_song_position(songPosition + stepCrochet * (3 if Input.is_key_pressed(KEY_SHIFT) else 1))
		
#endregion

#region Signals
#region Popups
func _on_stage_index_pressed(i: int) -> void: SONG.set('stage',stagePop.get_item_text(i))
func _on_event_index_pressed(i: int) -> void:
	var event_name = events_popup.get_item_text(i)
	setEvent(event_name)
	if event_selected:
		var index = event_selected.event_index
		event_selected.removeEvent(index)
		event_selected.addEvent(event_name,{},index)
func _on_note_type_index_pressed(i: int) -> void:
	var type = note_type_popup.get_item_text(i)
	note_type_menu.text = type
	for n in notes_selected: n.noteType = type
#endregion

func getMouseRoundedY(mouse_pos: Vector2) -> Vector2:
	return ((mouse_pos-chess_control.position-CHESS_REAL_SIZE/2.0)/CHESS_REAL_SIZE).round() * CHESS_REAL_SIZE

func _on_chess_input(event: InputEvent,chess: Chess):
	if event is InputEventMouseButton:
		match event.button_index:
			1:
				mouse_sustain_note = event.pressed
				mouse_create_note = event.pressed
				if event.pressed:
					unselectNotes()
					if event.double_click: mouse_selection.start_selection(); return
				else: _update_note_data()
				
				for i in _notes_created:
					if Rect2(i.position,CHESS_REAL_SIZE).intersects(Rect2(event.position,mouse_selection.size)):
						selectNote(i,true)
				
				if !mouse_create_note or notes_selected: return
				
				var note = getNoteAtMouse()
				var data: int = event.position.x/chess.rect_size.x
				if !note: note = createChessNote(
					event.position.y,
					data,
					chess
				)
				selectNote(note)
				addNoteToJson(note)
	elif event is InputEventMouseMotion:
		mouse_pos = chess.position + event.position
		var mouse_div = getMouseRoundedY(mouse_pos)
		
		mouse_rect_follow.position.x = mouse_div.x
		if is_shift_pressed:
			mouse_rect_follow.position.y = mouse_pos.y - chess_control.position.y - CHESS_REAL_SIZE.y/2.0
		else: mouse_rect_follow.position.y = mouse_div.y
			
		if notes_selected and mouse_sustain_note:
			var block_div = CHESS_REAL_SIZE.y
			for i in notes_selected:
				var sustain = (mouse_rect_follow.position.y - i.position.y - block_div)/block_div * stepCrochet
				if sustain > 0: i.sustainLength = sustain/cur_zoom

func _on_chess_event_input(event: InputEvent):
	if event is InputEventMouseButton:
		var note = getEventAtMouse()
		if !note: 
			createEvent((event.position if is_shift_pressed else getMouseRoundedY(event.position)).y)
			return
		selectEvent(note)
		
func _on_hit_section_toggled(toggled_on: bool) -> void:
	curSectionData.mustHitSection = toggled_on
	updateNotesPositions()
	_update_icon_in_section()
	for i in _notes_created: i.noteData = (i.noteData + keyCount) % (keyCount*2)
	
func _on_auto_change_section_toggled(toggled_on: bool) -> void:
	autoSwapSection = toggled_on
	if autoSwapSection and curSection != Conductor.section: set_section(Conductor.section)

func _on_add_event_button_down() -> void: if event_selected: event_selected.addEvent()
func _on_save_chart_button_down() -> void: Paths.saveFile({'song' : SONG},Conductor.jsonDir)


func _on_save_to_chart_button_down() -> void:
	var dialog = Paths.get_dialog(song_folder)
	dialog.add_filter('*.json')
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.dialog_text = 'Save Chart As'
	add_child(dialog)
	dialog.file_selected.connect(func(file):
		Paths.saveFile({'song': SONG},file)
	)

func _on_load_chart_button_down() -> void:
	var dialog = Paths.get_dialog(Conductor.jsonDir)
	dialog.title = 'Open Chart'
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter('*.json')
	add_child(dialog)
	dialog.file_selected.connect(loadChart)

func _on_load_song_chart_button_down() -> void:
	var dialog = Paths.get_dialog()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = "Open Song folder"
	add_child(dialog)
	dialog.dir_selected.connect(func(dir):
		new_chart_song_name.text = Paths.getPath(dir)
	)

func _on_event_index_value_changed(value: int) -> void:
	if !event_selected: return
	event_selected.selectEvent(value)
	selectEvent()
		
func _on_show_strums_toggled(toggled_on: bool) -> void: enableStrums(toggled_on)
	
func _on_arrow_skin_text_submitted(new_text: String) -> void:
	SONG.arrowSkin = new_text
	for i in strums_created:
		i.texture = new_text
	for i in _notes_created:
		i.loadFromStyle('funkin')
	note_skin.release_focus()
func _on_change_bpm_toggled(toggled_on: bool) -> void:
	if toggled_on:
		changeBpm()
		return
	curSectionData.changeBPM = false
	Conductor.removeBpmChange(curSection)


func _on_remove_event_button_up() -> void:
	removeEvent(event_selected,event_index.value)


func _on_sustain_length_value_added(value: float) -> void:
	for i in notes_selected:
		i.sustainLength += value
	_update_note_data()
	detectNotesToHit()
#endregion

#region Static Methods
static func reset_values():
	songPosition = 0.0
#endregion
