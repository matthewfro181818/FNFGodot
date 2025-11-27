extends "Note.gd" ##Sustain Base Note Class

const NoteHit = preload("uid://dx85xmyb5icvh")
const NoteSustain = preload("uid://bhagylovx7ods")
var isBeingDestroyed: bool
var noteParent: NoteHit ##Sustain's Note Parent

var region: Rect2
var _height: float
var _sus_animated: bool

var hit_time: float = 0.0

var _end_sustain: NoteSustain
func _init(data: int) -> void:
	splashStyle = &'HoldNoteSplashes'
	isSustainNote = true
	resetNote()
	super._init(data)

func _reload_note_without_data() -> void:
	loadSustainFrame(); setGraphicScale(Vector2(noteScale,noteScale))

func _reload_note_from_data(data: Dictionary) -> void:
	noteScale = data.get(&'scale',noteScale)
	var prefix = data.get(&'prefix')
	if prefix:  
		_sus_animated = true
		animation.addAnimByPrefix(_get_animation_name(), prefix, data.get(&'fps',24.0), true)
		return
	_sus_animated = false

	var _region = data.get(&'region')
	if _region: region = Rect2(_region[0],_region[1],_region[2],_region[3]); setNoteRect(region);
	else: loadSustainFrame()

func _get_data_animation_name() -> StringName:
	var _name = directions[noteData]; if isEndSustain: _name += 'End'
	if styleData.data.has(_name): return _name
	_name = &"defaultEnd" if isEndSustain else &'default'
	if styleData.data.has(_name): return _name
	return &''

func _get_animation_name() -> StringName: return &'holdEnd' if isEndSustain else &'hold'

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
	
	if !isEndSustain and hit_time: hit_time -= get_process_delta_time(); if hit_time <= 0.0: hit_time = 0.0
	if isBeingDestroyed or _sus_animated: updateSustain()
	_check_hit()
	followStrum()

func _get_sustain_region() -> Rect2: 
	var rect = animation.curAnim.curFrameData.get(&'region_rect',region) if _sus_animated else region
	if isEndSustain: return rect
	rect.size.y = absf(_height / scale.y)
	return rect

#region Updaters
func updateSustain():
	var rect = _get_sustain_region()
	if distance >= 0.0: image.region_rect = rect; return
	
	var fill = absf(real_distance / scale.y)
	rect.position.y += fill
	rect.size.y = maxf(0.0,rect.size.y - fill)
	if isBeingDestroyed and distance < -sustainLength: kill()
	image.region_rect = rect
	real_distance = 0.0

func _update_note_speed() -> void:
	super._update_note_speed()
	if !isEndSustain: _height = sustainLength * _real_note_speed; updateSustain();
	if strumNote: scale.y = noteScale * signf(_real_note_speed)

func _update_style_data() -> void: styleData = NoteStyleData.getStyleData(styleName, &'holdNote')
#endregion

func resetNote() -> void:
	super.resetNote()
	image.region_rect = _get_sustain_region()
	canBeHit = false
	isBeingDestroyed = false
	splashName = &'holdNoteCover'

func _on_hit() -> void: 
	isBeingDestroyed = true; wasHit = true; if isEndSustain: return
	hit_time = (1.0 - fmod(Conductor.step_float,1.0)) * Conductor.stepCrochetMs;
	
func followStrum(strum: StrumNote = strumNote) -> void: ##Update the Note position from the his [param strumNote].
	super.followStrum(strum)
	if !strum: return
	rotation_degrees = -strumNote.direction
	if copyScale: scale = strum.scale

#region Setters
func set_pivot_offset(value: Vector2) -> void:
	value.y = 0.0
	image.pivot_offset.y = 0.0
	super.set_pivot_offset(value)
#endregion

func _check_hit() -> void: 
	canBeHit = distance <= 15.0 and (!noteParent or noteParent.wasHit)
	if isEndSustain: canBeHit = canBeHit and !isBeingDestroyed;
	else: canBeHit = canBeHit and !hit_time and (!_end_sustain or !_end_sustain.isBeingDestroyed)
