extends "res://source/objects/Notes/Note.gd" ##Sustain Base Note Class

const NoteHit = preload("res://source/objects/Notes/NoteHit.gd")

var isBeingDestroyed: bool = false
var hit_action: StringName: 
	get(): return noteParent.hit_action if noteParent else &''
	
var noteParent: NoteHit ##Sustain's Note Parent

var sus_size: float
var default_sus_height: float
var _sus_animated: bool

func _init(data: int) -> void:
	splashStyle = 'HoldNoteSplashes'
	splashType = 'holdNoteCover'
	
	isSustainNote = true
	super._init(data)

func _check_hit() -> void:
	canBeHit = distance <= 15.0 and (!noteParent or noteParent.wasHit and not isBeingDestroyed)

func reloadNote() -> void: ##Reload Note Texture
	animation.clearLibrary()
	_animOffsets.clear()
	offset = Vector2.ZERO
	
	
	var data = styleData.data.get((noteDirection+'End') if isEndSustain else noteDirection)
	if !data: 
		noteScale = styleData.get(&'scale',0.7)
		loadSustainFrame(); 
		setGraphicScale(Vector2(noteScale,noteScale)); 
		return
	
	var prefix = data.prefix
	_sus_animated = !!prefix
	if _sus_animated: 
		noteScale = data.scale
		animation.addAnimByPrefix(&'holdEnd' if isEndSustain else &'hold', prefix, 24, true)
	else: 
		noteScale = styleData.scale
		var region = data.get(&'region')
		if region: setNoteRect(Rect2(region[0],region[1],region[2],region[3]))
		else: loadSustainFrame()
	
	setGraphicScale(Vector2(noteScale,1.0))

func loadSustainFrame():
	var frame: int = noteData*2
	var cut: int = int(imageSize.x)/(Song.keyCount*2)
	setNoteRect(
		Rect2(
			cut*(frame+1 if isEndSustain else frame),
			0.0,
			cut,
			imageSize.y
		)
	)

func updateNote() -> void:
	distance = (strumTime - Conductor.songPositionDelayed)
	if isBeingDestroyed: updateSustain();
	else: _check_hit()
	followStrum()

func getSustainHeight() -> float:
	if !_sus_animated: return imageSize.y
	var rect = animation.curAnim.curFrameData.get('region_rect'); 
	return rect.size.y if rect else imageSize.y
	

#region Updaters
func _update_sustain_scale() -> void: scale.y = sus_size/getSustainHeight()

func updateSustain():
	if distance > 0.0: return
	var fill = real_distance/scale.y
	var fill_abs = absf(fill)
	
	var _height: float = imageSize.y
	var _y_atlas: float = 0.0
	if _sus_animated:
		var rect = animation.curAnim.curFrameData.get('region_rect')
		if rect: _height = rect.size.y; _y_atlas = rect.position.y
	
	image.region_rect.position.y = _y_atlas + fill_abs
	image.region_rect.size.y = maxf(0.0,_height - fill_abs)
	if distance <= -absf(_height*scale.y): kill(); _is_processing = false
	real_distance = 0.0
	

func _update_note_speed() -> void:
	super._update_note_speed()
	if isEndSustain: 
		if strumNote: scale.y = noteScale * signf(strumNote.multSpeed)
		return
	sus_size = sustainLength * _real_note_speed
	_update_sustain_scale()

func _update_style_data() -> void: 
	styleData = NoteStyleData.getStyleData(
		styleName,
		NoteStyleData.StyleType.HOLD_NOTES
	)
#endregion

func resetNote() -> void:
	super.resetNote()
	var rect = animation.curAnim.curFrameData.get('region_rect')
	if rect: image.region_rect = rect
	else: image.region_rect.position.y = 0.0; image.region_rect.size.y = imageSize.y
	
	canBeHit = false
	isBeingDestroyed = false

func killNote() -> void: 
	canBeHit = false; isBeingDestroyed = true; updateNote()

##Update the Note position from the his [param strumNote].
func followStrum(strum: StrumNote = strumNote) -> void:
	super.followStrum(strum)
	rotation_degrees = -strumNote.direction

#region Setters
func set_pivot_offset(value: Vector2) -> void:
	value.y = 0.0
	image.pivot_offset.y = 0.0
	super.set_pivot_offset(value)
#endregion
