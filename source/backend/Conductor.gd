@tool
extends Node
const BEATS_PER_SECTION: int = 4

const StreamNames = [&"Inst",&"OpponentVoice",&"Voice"]
const Song = preload("res://source/backend/Song.gd")


var songs: Array[AudioStreamPlayer] #[Inst,Opponent,Player]

var jsonDir: String
var songJson: Dictionary
var songDefaultBpm: float
var fixVoicesSync: bool
var hasVoices: bool

var music_pitch: float = 1.0: set = set_music_pitch
var is_playing: bool

var songPosition: float: set = _set_song_position

var songPositionDelayed: float #songPosition - ClientPrefs.data.songOffset
var songPositionSeconds: float ##[param songPosition] in seconds.

var crochet: float
var stepCrochet: float
var stepCrochetMs: float
var sectionCrochet: float

var songLength: float

var step: int: 
	set(val): 
		if step == val: return 
		step = val; 
		_bpm_index = _find_current_change_index(step,_bpm_index,&'step',step > val)
		step_hit.emit();

var step_float: float: 
	set(val): step_float = val; step = int(val)

var beat: int: 
	set(val): 
		if beat == val: return 
		beat = val; beat_hit.emit();

var beat_float: float: 
	set(val): beat_float = val; beat = int(val) 

var section: int: 
	set(val):
		if section == val: return
		var backwards: bool = section > val
		if backwards: while section > val: section -= 1; section_hit.emit()
		else: while section < val: section += 1; section_hit.emit()
		_beats_reduced_index = _find_beats_reduced_index(section,_beats_reduced_index,&'section',backwards)
		section_hit_once.emit()

var section_float: float: 
	set(val): section_float = val; section = int(val) 


var _beats_reduced_array: Array[Dictionary] #Section, Song Position Offset, Beats Reduced
var _cur_beat_reduced: Dictionary
var _beats_reduced_index: int = -1:
	set(val):
		if val == _beats_reduced_index: return
		_beats_reduced_index = val
		if val == -1: _cur_beat_reduced = {}; return
		_cur_beat_reduced = _beats_reduced_array[val]
		
var _bpm_changes: Array[Dictionary]
var _bpm_index: int = -1: 
	set(i):
		if i == _bpm_index: return
		_bpm_index = i
		if i != -1: _update_bpm_changes_index(); return
		bpm = songDefaultBpm
		_cur_bpm_changes = {}

var bpm: float: 
	set(val): bpm = val; _update_bpm()

var _cur_bpm_changes: Dictionary

signal step_hit ##When a step is hitt.

## Emitted every time the section is passed during a change.
## If the section changes from 3 to 6, this signal will be emitted for sections 4, 5, and 6
signal section_hit

## Emitted once after the full section change is completed.
## Use this if you only need a single notification per section change.
signal section_hit_once 

signal beat_hit ##Emitted when the beat changes.
signal bpm_changes ##Emitted when the bpms changes.

signal song_loaded


#region Song methods
func loadSong(json_name: String, suffix: String = '') -> Dictionary:
	songJson = Song.loadJson(json_name, suffix)
	if !songJson: return Song.getChartBase()
	
	songDefaultBpm = songJson.get('bpm',120)
	bpm = songDefaultBpm
	detectBpmChanges()
	
	return songJson

##Load [AudioPlayer]'s from the current song.
func loadSongsStreams(folder: String = Song.audioFolder, suffix: String = Song.audioSuffix) -> void: #Used in StrumState.
	if songs: return

	var player_name = songJson.get('opponentVocals',songJson.get('player1',''))
	var opponent_name = songJson.get('playerVocals',songJson.get('player2',''))
	
	var paths: Array[PackedStringArray] = [
		#Inst Path
		['Inst'+suffix,'Inst'] if suffix else ['Inst'], 
		#Opponent Song Paths
		[
			'Voices-'+opponent_name+suffix,
			'Voices-'+opponent_name.replace(' ','-').get_slice('-',0)+suffix,
			'Voices-Opponent'+suffix
		], 
		#Player Song Paths
		[
			'Voices-'+player_name+suffix,
			'Voices-'+player_name.replace(' ','-').get_slice('-',0)+suffix,
			'Voices-Player',
			'Voices'+suffix
		]
	]
	
	#Look for Inst
	var paths_absolute: PackedStringArray
	for path in paths:
		var song
		for i in path:
			song = Paths.songPath(folder+'/'+i)
			if !song: continue
			paths_absolute.append(song)
			break
		if !song: paths_absolute.append('')
	
	loadSongsStreamsFromArray(paths_absolute)


##Load Song Streams from Array.
##[param paths_absolute] must be in this order: 
##[code][Inst Path, Opponnet Voice Path, Player Voice Path][/code]
func loadSongsStreamsFromArray(paths_absolute: PackedStringArray):
	if !paths_absolute: return

	var stream_id: int = -1
	for i in paths_absolute:
		stream_id += 1
		if !i: continue
		var stream = Paths.audio(i)
		if !stream: continue
		var audio = AudioStreamPlayer.new()
		audio.pitch_scale = music_pitch
		audio.stream = stream
		audio.name = StreamNames[stream_id]
		songs.append(audio)
		add_child(audio)
	
	hasVoices = songs.size() > 1
	
	if songs and songs[0].stream: songLength = songs[0].stream.get_length()*1000.0
	
	
	song_loaded.emit()


func sync_voices() -> void:
	if !hasVoices: return
	var index: int = 1
	while index < songs.size():
		var song = songs[index]
		if absf(song.get_playback_position() - songPositionSeconds) > 0.01: song.seek(songPositionSeconds)
		index += 1

##Set the current position of the song in milliseconds.
func seek(pos: float) -> void:
	songPosition = pos
	songPositionSeconds = pos / 1000.0
	if !songs: return
	
	if songPosition < 0.0:
		for i in songs: if i: i.stop()
		return
	
	for i in songs: if i: i.seek(clampf(songPositionSeconds, 0.0, i.stream.get_length()))


func playSongs(at: float = 0) -> void: for song in songs: song.play(at/1000.0) ##Play songs.[br][b]Note:[/b] [param at] have to be in milliseconds, if set.

func resumeSongs() -> void:
	if songPositionSeconds < 0: return
	for song in songs: if songPositionSeconds < song.stream.get_length(): song.play(songPositionSeconds)

func pauseSongs() -> void: for song in songs: song.stop() ##Pause the streams.

func stopSongs(delete: bool = false) -> void: ##Stop the streams.
	if delete:
		for song in songs: remove_child(song); song.queue_free()
		songs.clear()
	else:
		for song in songs: song.stop()
		songPosition = 0
		
func clearSong(absolute: bool = true) -> void: ##Clear all the songs created
	stopSongs(true)
	seek(0.0)
	_bpm_index = -1
	_beats_reduced_index = -1
	
	if !absolute: return
	clear_changes()
	_bpm_changes.clear()
	bpm = 0
	songJson.clear()
	Song._clear()

func clear_changes() -> void: _bpm_changes = []; _beats_reduced_array = []
	
#endregion

#region Rhythm Methods
#endregion
#region Get methods
func get_step_count() -> int:
	if !_bpm_changes: return int( songLength / get_step_crochet(bpm) )
	var last_change = _bpm_changes.back()
	return int(songLength/get_step_crochet(last_change.bpm) - last_change.step_offset)
#endregion

#region Crochet Methods
static func get_crochet(_bpm: float) -> float: return 60000 / _bpm
static func get_step_crochet(_bpm: float) -> float: return 15000.0/_bpm
static func get_section_crochet(_bpm: float, section_beats: float = 4) -> float:  return (60000 / _bpm) * section_beats
#endregion

#region Section Methods
func get_section_time(_section: int = section, section_crochet: float = sectionCrochet) -> float:
	if !_section: return 0.0
	var section_data = get_section_data(_section)
	if section_data: return section_data.sectionTime
	
	var time: float = _section * section_crochet
	if !_bpm_changes and !_beats_reduced_array: return time
	
	
	if _bpm_changes:
		var size = _bpm_changes.size()
		var max_section: float = _bpm_changes[0].section
		
		time = max_section * get_section_crochet(songDefaultBpm)
		
		var index: int = 1
		while index < size:
			var i = _bpm_changes[index]
			time += (i.section - max_section) * get_section_crochet(_bpm_changes[index-1].bpm)
			max_section = i.section
	
	var _beats_reduced = get_beats_reduced_at(_section,0,&'section')
	if _beats_reduced: time += _beats_reduced.time_offset
	return time

func get_section(
	_position: float, 
	sec_crochet: float = sectionCrochet, 
	bpm_changes: Dictionary = get_bpm_changes_at(_position,0,&'time'), 
	beats_reduced_data: Dictionary = get_beats_reduced_at(_position)
) -> float:
	if beats_reduced_data: _position += beats_reduced_data.time_offset
	if bpm_changes: return bpm_changes.section + ((_position - bpm_changes.time) / sec_crochet)
	return _position / sec_crochet

func get_section_data(section: int = Conductor.section) -> Dictionary: 
	var notes = songJson.get(&'notes'); return notes[section] if notes.size() < section else {}
#endregion

#region Beat Methods
func get_beat(_position: float, _bpm: float = songDefaultBpm) -> float:
	var changes = get_bpm_changes_at(_position,0,&'time')
	if changes: return get_beat_with_changes(_position,changes)
	return _position / get_crochet(_bpm)

func get_beat_with_changes(pos: float, dict: Dictionary) -> float: return dict.beat + ((pos - dict.time) / get_crochet(dict.bpm)) 

func get_beat_section(_section: int) -> float:
	var changes = get_bpm_changes_at(_section)
	if changes: return _section * 4.0 - changes.section_beats_reduced 
	return _section * 4.0

#endregion

#region Step Methods 
func get_step(_position: float, 
	step_crochet: float = stepCrochet,
	bpm_changes: Dictionary = get_bpm_changes_at(_position,0,&'position')
) -> float:
	if bpm_changes: return bpm_changes.step + ((_position - bpm_changes.time) / step_crochet) 
	return _position / step_crochet

func get_step_time(_step: float, step_crochet: float = stepCrochet) -> float:
	if !bpm_changes: return _step * step_crochet
	
	var size = _bpm_changes.size()
	var max_step: float = _bpm_changes[0].step
	var time: float = max_step*step_crochet
	var index: int = 1
	
	while index < size:
		var i = _bpm_changes[index]
		time += (i.step - max_step) * get_step_crochet(i.bpm)
		max_step = i.step
	return time
	
	
func get_step_section(_section: int) -> float:
	var changes = get_bpm_changes_at(_section)
	if changes: return (_section+changes.section_beats_reduced) * 16.0 + changes.step_offset 
	return _section * 16.0
#endregion

#region Setters
func set_music_pitch(pitch: float) -> void: music_pitch = pitch; for i in songs: i.pitch_scale = pitch

func _set_song_position(position: float) -> void:
	songPosition = position
	songPositionDelayed = position - ClientPrefs.data.songOffset
	_update_rhythm()
	if fixVoicesSync: sync_voices()

func _update_rhythm() -> void:
	step_float = get_step(songPosition,stepCrochet,_cur_bpm_changes)
	beat_float = step_float / 4.0
	section_float = get_section(songPosition,sectionCrochet,_cur_bpm_changes,_cur_beat_reduced)
#endregion

#region Bpm Methods
func detectBpmChanges() -> void:
	if _bpm_changes.is_read_only(): _bpm_changes = []
	if _beats_reduced_array.is_read_only(): _beats_reduced_array = []
	
	var sectionBpm: float = bpm
	var bpm_section: int = 0
	
	var notes = songJson.notes
	var length = notes.size()
	while bpm_section < length:
		var i = notes[bpm_section]
		var sectionBeats: int = int(i.sectionBeats)
		if i.changeBPM and i.bpm != sectionBpm: _change_bpm_at(i.sectionTime,i.bpm); sectionBpm = i.bpm
		if sectionBeats < 4: _reduce_section_beats(bpm_section,sectionBeats,sectionBpm)
		bpm_section += 1
	_bpm_changes.make_read_only()
	_beats_reduced_array.make_read_only()

func _update_bpm() -> void:
	crochet = get_crochet(bpm)
	stepCrochet = crochet/4.0
	stepCrochetMs = stepCrochet/1000.0
	sectionCrochet = crochet*4.0
	_update_rhythm()
	bpm_changes.emit()
#endregion

#region Beats Reduced Methods
func _reduce_section_beats(section: int, beats: int, _bpm: float = bpm) -> void:
	if beats == BEATS_PER_SECTION: return
	var beats_reduced: int = 4 - beats
	var data: Dictionary[StringName,float] = {
		&'time': get_section_time(section),
		&'section': section,
		&'time_offset': get_crochet(_bpm)*(beats_reduced),
		&'beats_reduced': beats_reduced,
	}
	
	if _beats_reduced_array: 
		var last = _beats_reduced_array.back()
		data.time_offset += last.time_offset
		data.beats_reduced += last.beats_reduced
	
	data.make_read_only()
	_beats_reduced_array.append(data)

func get_beats_reduced_at(position: float, start_index: int = _beats_reduced_index, key: StringName = &'section', backwards: bool = false) -> Dictionary:
	if !_beats_reduced_array or position < 0: return {}
	start_index = _find_beats_reduced_index(position,start_index,key,backwards)
	return {} if start_index == -1 else _beats_reduced_array[start_index]

func _find_beats_reduced_index(position: float, start_index: int = _beats_reduced_index, key: StringName = &'section', backwards: bool = false):
	if !_beats_reduced_array or position < 0: return -1
	if backwards: while start_index >= 0 and position < _beats_reduced_array[start_index-1][key]: start_index -= 1;
	else: while start_index < _beats_reduced_array.size()-1 and position > _beats_reduced_array[start_index+1][key]: start_index += 1;
	return start_index
	
static func getBeastReducedBaseData() -> Dictionary[StringName,float]:
	return {
		&'time': 0,
		&'section': 0,
		&'time_offset': 0,
		&'beats_reduced': 0,
	}
#endregion

#region BPM Changes
func _change_bpm_at(song_position: float, newBpm: float) -> void:
	var changes = get_bpm_changes_at(song_position,0,&'time')
	var prevBpm: float = changes.bpm if changes else songDefaultBpm
	var data: Dictionary = changes.duplicate() if changes else getChangesBase() 
	
	data.section = get_section(song_position,get_section_crochet(prevBpm),data)
	data.step = get_step(song_position,get_step_crochet(prevBpm),data)
	data.beat = data.step*4.0
	
	data.bpm = songDefaultBpm
	data.time = song_position
	data.bpm = newBpm
	
	data.make_read_only()
	_bpm_changes.append(data)

func get_bpm_changes_at(position: float, start_index: int = _bpm_index, key: StringName = &'step', backwards: bool = false) -> Dictionary:
	if !_bpm_changes: return {}
	var index = _find_current_change_index(position,start_index,key,backwards)
	return {} if index == -1 else _bpm_changes[index]

func removeBpmChange(section: int): for i in _bpm_changes: if i.section == section: _bpm_changes.erase(i); break

func _update_bpm_changes_index() -> void:
	var i = _bpm_changes[_bpm_index]
	_cur_bpm_changes = i
	bpm = i.bpm

func _find_current_change_index(position: float = step,start_index: int = _bpm_index, key: StringName = &'step', backwards: bool = false):
	if !_bpm_changes or position < 0: return -1
	if backwards: while start_index >= 0 and position < _bpm_changes[start_index-1][key]: start_index -= 1;
	else: while start_index < _bpm_changes.size()-1 and position > _bpm_changes[start_index+1][key]: start_index += 1;
	return start_index
	
static func getChangesBase() -> Dictionary[StringName,float]:
	return {
		&'time': 0,
		&'section': 0,
		&'beat': 0,
		&'step': 0,
		&'bpm': 0,
	}
#endregion


#endregion

func _process(_d) -> void:
	if !songs:
		if songPosition > 0: songPosition = 0.0; 
		return
	if songs[0].playing:
		is_playing = true
		songPositionSeconds = songs[0].get_playback_position()
		songPosition = songPositionSeconds*1000.0
	else:
		is_playing = false
