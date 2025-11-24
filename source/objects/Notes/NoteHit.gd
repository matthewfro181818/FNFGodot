extends "Note.gd"
const NoteSustain = preload("uid://bhagylovx7ods")
var sustainParents: Array[NoteSustain]
var hit_action: StringName ##The Key that have to be press to hit the note, this auto changes when [member noteData] is setted.

var copyAngle: bool = true ## Follow strum angle
var offsetAngle: float = 0.0 ##Additive Angle offset 
func updateRating() -> void:
	var timeAbs = absf(distance)
	ratingMod = 0
	while ratingMod < _ratings_length: 
		if timeAbs < _rating_offset[ratingMod]: break
		ratingMod += 1
	rating = _rating_string[ratingMod]
	
	if !sustainParents: return
	sustainParents[0].ratingMod = ratingMod
	sustainParents.back().ratingMod = ratingMod

func followStrum(strum: StrumNote = strumNote) -> void:
	if !strum: return
	super.followStrum(strum)
	if copyAngle: rotation_degrees = strum.rotation_degrees + offsetAngle
	if copyScale: setGraphicScale(strumNote.scale * multScale)

func setNoteData(_data: int) -> void: super.setNoteData(_data); hit_action = getInputActions()[_data]

static func getInputActions(key_count: int = Song.keyCount) -> Array: return key_actions[key_count]
