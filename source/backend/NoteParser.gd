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
	
	var types_founded: PackedStringArray
	
	var i: int = 0
	var length = notesData.size()
	while i < length:
		var section = notesData[i]
		if section.changeBPM and section.bpm != _bpm:
			_bpm = section.bpm
			stepCrochet = Conductor.get_step_crochet(_bpm)
		
		var note_index: int = 0
		var notes_length = section.sectionNotes.size()
		while note_index < notes_length:
			var note_data = section.sectionNotes[note_index]
			note_index += 1
			
			var note: NoteHit = createNoteFromData(note_data,section,keyCount)
			if !_insert_note_to_array(note,_notes): continue
			if note.noteType: types_founded.append(note.noteType)
			
			var susLength = note_data.get('l',0.0)
			if susLength < stepCrochet: continue 
			for s in _create_note_sustains(note,susLength): _insert_note_to_array(s,_notes,false)
			
		i += 1
	var type_unique: PackedStringArray
	for t in types_founded: if not t in type_unique: type_unique.append(t)
	songData.noteTypes = type_unique
	return _notes

static func _insert_note_to_array(note: Note, array: Array, check_duplicated_note: bool = true) -> bool:
	var index = array.size()
	while index:
		index -= 1
		var prev_note: Note = array[index]
		if prev_note.strumTime > note.strumTime: continue; 
		if !check_duplicated_note or prev_note.strumTime < note.strumTime: array.insert(index + 1, note); return true
		
		#Remove duplicated note
		if !sameNote(note,prev_note): continue
		if note.sustainLength < prev_note.sustainLength: return false
		array.insert(index + 1,note);
		for i in array.pop_at(index).sustainParents: array.erase(i);
	array.push_front(note)
	return true
		

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
	var susCount: int = int_div if div-int_div < stepCrochet*0.5 else int_div+1
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
		note1.isSustainNote == note2.isSustainNote and\
		note1.strumTime == note2.strumTime and\
		note1.noteData == note2.noteData and\
		note1.mustPress == note2.mustPress\
