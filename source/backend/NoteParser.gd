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
		for noteSection in section.sectionNotes:
			var note: NoteHit = createNoteFromData(noteSection,section,keyCount)
			if !_insert_note_to_array(note,_notes): continue
			if note.noteType: types_founded.append(note.noteType)
			
			var susLength = float(noteSection.get('l',0.0))
			if susLength < stepCrochet: continue 
			for i in _create_note_sustains(note,susLength): _insert_note_to_array(i,_notes)
	var type_unique: PackedStringArray
	for i in types_founded: if not i in type_unique: type_unique.append(i)
	songData.noteTypes = type_unique
	_remove_duplicate_notes(_notes)
	return _notes

static func _insert_note_to_array(note: Note, array: Array) -> bool:
	var index = array.size()
	while index:
		var prev_note: Note = array[index-1]
		if note.strumTime <= prev_note.strumTime: index -= 1; continue
		array.insert(index,note); return true
	array.push_front(note)
	return true

static func _remove_duplicate_notes(_notes_array: Array):
	var index: int = _notes_array.size()
	while index:
		index -= 1
		var note: Note = _notes_array[index]
		if note.isSustainNote: continue
		
		var prev_note: Note
		var prev_index = index
		while prev_index:
			prev_index -= 1
			prev_note = _notes_array[prev_index]
			if !prev_note.isSustainNote: break
			prev_note = null
		
		if !prev_note: continue
		if prev_note and prev_note.strumTime < note.strumTime: continue
		if sameNote(prev_note,note):
			var note_to_remove: Note
			var index_to_remove: int
			if note.sustainLength > prev_note.sustainLength: note_to_remove = prev_note; index_to_remove = prev_index
			else: note_to_remove = note; index_to_remove = index
			
			index = index_to_remove
			
			_notes_array.remove_at(index_to_remove)
			for i in note_to_remove.sustainParents: _notes_array.erase(i); i.queue_free()
			
			note_to_remove.queue_free()
		else:
			index = prev_index

static func _create_note_sustains(note: Note, length: float) -> Array[NoteSustain]:
	var sustainFill: NoteSustain = createSustainFromNote(note,false)
	var sustainEnd: NoteSustain = createSustainFromNote(note,true)
	sustainFill.sustainLength = length
	sustainFill._end_sustain = sustainEnd
	sustainEnd.strumTime += length
	
	var susNotes: Array[NoteSustain] =  note.sustainParents
	susNotes.append(sustainFill)
	susNotes.append(sustainEnd)
	return susNotes

static func _create_note_sustains_old_version(note: Note, length: float, stepCrochet: float) -> Array[NoteSustain]:
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
	sus.splashDisabled = isEnd
	sus.hitHealth /= 2.0
	
	sus.strumTime = note.strumTime
	sus.noteType = note.noteType
	sus.gfNote = note.gfNote
	sus.mustPress = note.mustPress
	sus.animSuffix = note.animSuffix
	sus.noAnimation = note.noAnimation
	sus.isPixelNote = note.isPixelNote
	return sus

static func sameNote(note1: Note,note2: Note):
	return note1 and note2 and \
		note1.strumTime == note2.strumTime and\
		note1.noteData == note2.noteData and\
		note1.mustPress == note2.mustPress and\
		note1.isSustainNote == note2.isSustainNote
