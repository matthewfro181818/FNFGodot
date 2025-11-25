const Note = preload("uid://deen57blmmd13")
const NoteHit = preload("uid://dx85xmyb5icvh")
const NoteSustain = preload("uid://bhagylovx7ods")
##Load Notes from the Song.[br][br]
##[b]Note:[/b] This function have to be call [u]when [member SONG] and [member keyCount] is already setted.[/u]
static func getNotesFromData(songData: Dictionary = {}) -> Array[Note]:
	var _notes: Array[Note]
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
			
			var susLength = float(noteSection.get('l',0.0))
			if susLength < stepCrochet: continue 
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
	var susCount: int = int_div if div-int_div < stepCrochet/2.0 else int_div+1
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
	note.sustainLength = length
	return susNotes

static func createNoteFromData(data: Dictionary, sectionData: Dictionary, keyCount: int = 4) -> NoteHit:
	var noteData = int(data.d)
	var note = NoteHit.new(noteData%keyCount)
	var mustHitSection = sectionData.mustHitSection
	var gfSection = sectionData.gfSection
	var type = data.get('k','')
	
	note.strumTime = data.t
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
