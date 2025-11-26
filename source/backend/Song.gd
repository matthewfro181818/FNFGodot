extends Object
##A Chart Song Class.

const EventNoteUtils = preload("uid://dqymf0mowy0dt")
##Contains the location of the json files.[br]
##[code]{"song name": 
##{"difficulty": {"folder": "folder_name","json": "json name", "audio_suffix": "suffix tag"}}
##}[/code][br][br]
##Example:[codeblock]
##songs_dir["Dad Battle"] = {
##    "Erect": {
##      "folder": "dad-battle",
##      "json": "dad-battle-erect-chart",
##      "audio_suffix": "-erect"
##    }, 
##    "Nightmare": {
##      "folder": "dad-battle",
##      "json": "dad-battle-erect-chart",
##      "audio_suffix": "-erect"
##    },
##}
##[/codeblock]
static var songs_dir: Dictionary[StringName,Dictionary]

static var songName: String = &''
static var songJsonName: String = &''
static var audioSuffix: String = &''
static var audioFolder: String = &''
static var folder: String = &''
static var difficulty: String = &''
static var keyCount: int = 4: 
	set(val): keyCount = val; FunkinGD.keyCount = val

static func loadJson(json_name: String, _difficulty: String = '') -> Dictionary:
	var json: Dictionary
	var json_path: String
	
	var song_dir = songs_dir.get(json_name)
	if song_dir: song_dir = song_dir.get(_difficulty)
	
	if song_dir:
		var custom_folder = song_dir.get(&'folder',folder)
		json_name = song_dir.get(&'json',json_name)
		audioSuffix = song_dir.get(&'audio_suffix','')
		json_path = Paths.data(json_name,'',custom_folder)
	else:
		audioSuffix = ''
		json_path = Paths.data(json_name,_difficulty)
	
	folder = Paths.getPath(json_path,false).get_base_dir()
	audioFolder = folder.get_slice('/',folder.get_slice_count('/')-1)
	
	json = _load_data(json_path,_difficulty)
	
	difficulty = _difficulty
	songJsonName = json_name
	
	if !json: return json
	
	if !json.get(&'audioSuffix'): json.audioSuffix = audioSuffix
	if !json.get(&'audioFolder'): json.audioFolder = audioFolder
	
	songName = json.get(&'song','')
	if !songName: songName = songJsonName.get_basename()
	
	return json

static func _load_data(json_path: String, difficulty: String = '') -> Dictionary:
	var data = Paths.loadJson(json_path)
	if !data: return data
	if data.get('song') is Dictionary: data = data.song
	
	#Check if the chart is from the original fnf
	if data.get('notes') is Dictionary:
		var meta_data_path = json_path.replace('-chart','-metadata')
		var meta_data = Paths.loadJson(meta_data_path)
		data = _convert_new_to_old(data,meta_data,difficulty)
	else:
		fixChart(data)
		sort_song_notes(data.notes)
		_insertSectionTimes(data)
		if data.notes: _convert_notes_to_new(data.notes)
	return data

static func _insertSectionTimes(json: Dictionary):
	var section_time: float = 0.0
	var cur_bpm: float = json.bpm
	var beat_crochet: float = Conductor.get_crochet(cur_bpm)
	for i in json.notes:
		if !i: break
		if i.changeBPM:
			cur_bpm = i.get('bpm',json.bpm)
			beat_crochet = Conductor.get_crochet(cur_bpm)
		i.sectionTime = section_time
		i.bpm = cur_bpm
		section_time += beat_crochet * i.sectionBeats

static func fixChart(json: Dictionary):
	json.merge(getChartBase(),false)
	for section: Dictionary in json.notes: section.merge(getSectionBase(),false)
	return json

static func _convert_new_to_old(chart: Dictionary, songData: Dictionary = {}, difficulty: String = '') -> Dictionary:
	var newJson = getChartBase()
	var json_bpm = 0.0
	var bpms = []
	
	if songData.has('timeChanges'):
		for changes in songData.timeChanges:
			bpms.append([changes.get('t',0),changes.get('bpm',0)])
		json_bpm = bpms[0][1]
	
	var bpms_size = bpms.size()
	
	var bpmIndex: int = 0
	var subSections: int = 0
	var sectionStep: float = Conductor.get_section_crochet(json_bpm)
	
	var curSectionTime: float = 0
	
	var characters: Dictionary = {
		'player': 'bf',
		'girlfriend': 'bf',
		'opponent': 'bf'
	}
	
	var playData = songData.get('playData',{})
	if playData.has('characters'): characters.merge(playData.get('characters',{}),true)
	newJson.stage = playData.get('stage','mainStage')
	
	newJson.player1 = characters.player
	newJson.gfVersion = characters.girlfriend
	newJson.player2 = characters.opponent
	newJson.songSuffix = characters.get('instrumental','')
	
	var vocal = characters.get('playerVocals')
	if vocal: newJson.playerVocals = vocal[0]
	
	vocal = characters.get('opponentVocals')
	if vocal: newJson.opponentVocals = vocal[0]
	
	newJson.opponentVoice = characters.get('opponentVocals',newJson.player1)
	newJson.speed = chart.get('scrollSpeed',{}).get(difficulty.to_lower(),2.0)
	
	newJson.song = songData.get('songName','')
	newJson.bpm = json_bpm
	
	newJson.notes = []
	for notes in chart.notes.get(difficulty.to_lower(),[]):
		var strumTime = notes.get('t',0)
		var section = int(strumTime/sectionStep) - subSections
		
		#Detect Bpm Changes
		if bpmIndex < bpms_size and bpms[bpmIndex][0] <= strumTime:
			json_bpm = bpms[bpmIndex][1]
			sectionStep = Conductor.get_section_crochet(json_bpm)
			var newSection = strumTime/sectionStep - subSections
			subSections -= newSection - section
			section = newSection - subSections
			bpmIndex += 1
	
		while newJson.notes.size() <= section: #Create Sections
			var new_section = getSectionBase()
			new_section.mustHitSection = true
			new_section.sectionTime = curSectionTime
			
			curSectionTime += sectionStep
			newJson.notes.append(new_section)
		
		newJson.notes[section].sectionNotes.append(notes)
	
	if chart.get(&'events'): newJson.events = EventNoteUtils.loadEvents(chart.events)
	return newJson

static func _convert_notes_to_new(notes_data: Array):
	var index: int = 0
	var note_size = notes_data.size()
	while index < note_size:
		var section_data = notes_data[index].get('sectionNotes')
		index += 1
		if !section_data is Array: continue
		
		var new_notes: Array
		var size = section_data.size()
		var note_index: int = 0
		while note_index < size:
			var data = section_data[note_index]
			var data_size = data.size()
			var new_data: Dictionary = {'t': data[0],'d': data[1]}
			if data_size >= 3: new_data.l = data[2] #Note Length
			if data_size >= 4: new_data.k = data[3] #Note Type
			new_notes.append(new_data)
			note_index += 1
		
		section_data.clear()
		section_data.assign(new_notes)

static func sort_song_notes(song_notes: Array) -> void:
	for i in song_notes:
		if i.sectionNotes: i.sectionNotes.sort_custom(ArrayUtils.sort_array_from_first_index)

static func getSectionBase() -> Dictionary:
	return {
		&'sectionNotes': [],
		&'mustHitSection': false,
		&'gfSection': false,
		&'sectionBeats': 4,
		&'sectionTime': 0,
		&'changeBPM': false,
		&'bpm': 0
	}

static func getChartBase() -> Dictionary: ##Returns a base [Dictionary] of the Song.
	return {
		'notes': [],
		'events': [],
		'bpm': 0.0,
		'song': '',
		'songSuffix': '',
		'player1': 'bf',
		'player2': 'dad',
		'gfVersion': 'gf',
		'speed': 1,
		'stage': 'stage',
		'arrowSkin': '',
		'splashSkin': '',
		'disableNoteRGB': false,
		'needsVoices': true,
		'keyCount': 4,
	}

static func _clear():
	songs_dir.clear()
	audioSuffix = &''
	folder = &''


static func set_song_directory(songName: StringName, difficulty: StringName, folder: StringName, json: StringName, audio_suffix: StringName):
	if !songName or !difficulty: return
	if !songs_dir.has(songName): songs_dir[songName] = DictUtils.getDictTyped({},TYPE_STRING_NAME)
	var data: Dictionary[StringName, Variant] = songs_dir[songName]
	data[difficulty] = {
		&'folder': folder,
		&'json': json,
		&'audio_suffix': audio_suffix
	}
#region Setters
