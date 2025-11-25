extends "Note.gd" ##Sustain Base Note Class

const NoteHit = preload("res://source/objects/Notes/NoteHit.gd")

var isBeingDestroyed: bool
var noteParent: NoteHit ##Sustain's Note Parent

var region: Rect2
var _height: float
var _height_scale: float
var _sus_animated: bool

func _init(data: int) -> void:
	splashStyle = &'HoldNoteSplashes'
	splashName = &'holdNoteCover'
	isSustainNote = true
	super._init(data)



func reloadNote() -> void: ##Reload Note Texture
	animation.clearLibrary()
	_animOffsets.clear()
	offset = Vector2.ZERO
	
	noteScale = styleData.get(&'scale',NoteStyleData.DEFAULT_NOTES_SCALE)
	var data = styleData.data.get((noteDirection+'End') if isEndSustain else noteDirection)
	if !data: 
		data = styleData.data.get(&'defaultEnd' if isEndSustain else &'default');
		if !data: _reload_note_without_data(); return
	_reload_note_from_data(data)

func _reload_note_without_data():
	loadSustainFrame(); setGraphicScale(Vector2(noteScale,1.0))

func _reload_note_from_data(data: Dictionary) -> void:
	noteScale = data.get(&'scale',noteScale)
	var prefix = data.get(&'prefix')
	_sus_animated = !!prefix
	if _sus_animated:  animation.addAnimByPrefix(&'holdEnd' if isEndSustain else &'hold', prefix, data.get(&'fps',24.0), true)
	else:
		var _region = data.get(&'region')
		if _region: region = Rect2(_region[0],_region[1],_region[2],_region[3]); setNoteRect(region);
		else: loadSustainFrame()
	setGraphicScale(Vector2(noteScale,1.0))
	
	
func loadSustainFrame():
	var frame: int = noteData*2
	var cut: int = int(imageSize.x)/(Song.keyCount*2)
	region = Rect2(
		cut*(frame+1 if isEndSustain else frame),
		0.0,
		cut,
		imageSize.y
	)
	setNoteRect(region)

func updateNote() -> void:
	distance = (strumTime - Conductor.songPositionDelayed)
	if isBeingDestroyed: updateSustain();
	else: _check_hit()
	followStrum()

func _get_sustain_region() -> Rect2: 
	return animation.curAnim.curFrameData.get(&'region_rect',region) if _sus_animated else region

#region Updaters
func _update_sustain_scale() -> void: _height_scale = _height/_get_sustain_region().size.y; scale.y = _height_scale

func updateSustain():
	if distance >= 0.0: return
	var fill = real_distance/scale.y
	
	var fill_abs = absf(fill)
	var _y_atlas: float = 0.0
	var rect = _get_sustain_region()
	
	image.region_rect.position.y = rect.position.y + fill_abs
	image.region_rect.size.y = maxf(0.0,rect.size.y - fill_abs)
	if distance <= -absf(rect.size.y*scale.y): kill(); _is_processing = false
	real_distance = 0.0

func _update_note_speed() -> void:
	super._update_note_speed()
	if isEndSustain: 
		if strumNote: scale.y = noteScale * signf(_real_note_speed)
		return
	_height = sustainLength * _real_note_speed
	_update_sustain_scale()

func _update_style_data() -> void: 
	styleData = NoteStyleData.getStyleData(
		styleName,
		NoteStyleData.StyleType.HOLD_NOTES
	)

#endregion

func resetNote() -> void:
	super.resetNote()
	image.region_rect = _get_sustain_region()
	canBeHit = false
	isBeingDestroyed = false

func killNote() -> void: canBeHit = false; isBeingDestroyed = true; updateNote()


func followStrum(strum: StrumNote = strumNote) -> void: ##Update the Note position from the his [param strumNote].
	super.followStrum(strum)
	rotation_degrees = -strumNote.direction
	if copyScale: scale = Vector2(strum.scale.x,_height_scale)

#region Setters
func set_pivot_offset(value: Vector2) -> void:
	value.y = 0.0
	image.pivot_offset.y = 0.0
	super.set_pivot_offset(value)
#endregion

func _check_hit() -> void: canBeHit = distance <= 15.0 and not isBeingDestroyed and (!noteParent or noteParent.wasHit)
