
@icon("res://icons/note.svg")
extends "NoteBase.gd" ##The Note Base Class
#region Constants
const NoteSplash = preload("uid://cct1klvoc2ebg")
const StrumNote = preload("uid://coipwnceltckt")

const _rating_string: Array = [&'marvellous',&'sick',&'good',&'bad',&'shit']
const _ratings_length: int = 4 #_rating_string.size()

const key_actions: Array = [
	[&""],
	[&"note_left"],
	[&"note_left",&"note_right"],
	[&"note_left",&"note_center",&"note_right"],
	[&"note_left",&"note_down",&"note_up",&"note_right"],
	[&"note_left",&"note_down",&"note_center",&"note_up",&"note_right"],
]

#endregion

#region Static Vars
static var _rating_offset: PackedFloat32Array = [-1.0,45.0,130.0,150.0]
static var noteStylesLoaded: Dictionary
static var miraculousRating: bool
#endregion

#region Copy Strum Vars
var copyX: bool = true  ##If [code]true[/code], the note will follow the x position from his [member strum].
var copyY: bool = true ##If [code]true[/code], the note will follow the y position from his [member strum].
var copyAlpha: bool = true ##If [code]true[/code], the note will follow the alpha from his [member strum].
var copyScale: bool ##If [code]true[/code], the note will follow the scale from his [member strum].
#endregion

var _is_processing: bool

#region Sustain Vars
var isSustainNote: bool ##If the note is a Sustain. See also ["source/objects/NoteSustain.gd"]
var isEndSustain: bool
var sustainLength: float  ##The Sustain time
#endregion

#region Health Vars
var hitHealth: float = 0.023 ##the amount of life will gain by hitting the note
var missHealth: float = 0.0475##the amount of life will lose by missing the note
#endregion

#region Strum Vars
var strumConfirm: bool = true ##If [code]true[/code], the strum will play animation when hit the note
var strumTime: float ##Position of the note in the song
var strumNote: StrumNote: set = setStrum ##Strum Parent that note will follow
#endregion


#region Note Style Variables
var noteSpeed: float = 1.0: set = setNoteSpeed ##Note Speed
var _real_note_speed: float = 1.0

var animSuffix: String
#endregion

#region Note Type Variables
var gfNote: bool ##Is GF Note
var ignoreNote: bool ##if is opponent note or a bot playing, they will ignore this note
var noteType: StringName ##Note Type

var autoHit: bool ##If [code]true[/code], the note will be hit automatically, independent if is a player note.
var noAnimation: bool ##When hit the note and this variable is [code]true[/code], the character will dont play animation
var mustPress: bool ##player note

var blockHit: bool ##Unable to hit the note

var lowPriority: bool ##if two notes are close to the strum and this variable is true, the game will prioritize the another one
#endregion

#region Mult Variables
var multSpeed: float = 1.0: set = setMultSpeed##Note Speed multiplier
var multAlpha: float = 1.0 ##Note Alpha multiplier
var multScale: Vector2 = Vector2.ONE
#endregion

#region General Variables
##The group the note will be added when spawned,
##see [method "source/states/StrumState.gd".spawnNote] in his script for more information.[br][br]
##[b]Tip:[/b] Is recommend to set this value as a [SpriteGroup]!! 
var noteGroup: Node

var missOffset: float = -150.0 ##The time distance to miss the note

var missed: bool ##Detect if the note is missed

var offsetX: float ##Distance on x axis
var offsetY: float ##Distance on y axis

var distance: float: set = setDistance  ##The distance between the note and the strum
var real_distance: float

var canBeHit: bool  ##If the note can be hit
var hitAnim: StringName ##Strum animation when hit this note, this property is set in StrumState.

var wasHit: bool
var judgementTime: float = INF ##Used in ModchartEditor


#region Splash
var splashStyle: StringName = &'NoteSplashes' ##Splash Json
var splashName: StringName = &'noteSplash' ##Splash Type
var splashPrefix: StringName ##Splash Prefix
var splashDisabled: bool ##If [code]true[/code], when hits this note, the splash will not be created.
var splashParent: Node
#endregion

#endregion

#region Rating Variables
var ratingMod: int ## The Rating of the note in [int]. [param 0 = nothing, 1 = sick, 2 = good, 3 = bad, 4 = shit]
var rating: StringName ## The Rating ot the note in [String]. [param sick, good, bad, shit]
var ratingDisabled: bool ##Disable Rating. If [code]true[/code], the rating will always be "sick".
#endregion





func _init(data: int = 0) -> void: noteData = data; super._init()

func updateNote() -> void:
	distance = (strumTime - Conductor.songPositionDelayed)
	_check_hit()
	followStrum()

func _check_hit() -> void:
	if blockHit: canBeHit = false; return
	if autoHit: canBeHit = distance <= 0.0; return
	var limit = _rating_offset[3]
	canBeHit = distance >= -limit and distance <= limit

func followStrum(strum: StrumNote = strumNote) -> void:
	if !strum: return
	
	var posX: float = strumNote.x + offsetX
	var posY: float = strumNote.y + offsetY
	
	if strumNote._direction_radius: 
		var lerp_dir = strumNote._direction_lerp; posX += real_distance*lerp_dir.y; posY += real_distance*lerp_dir.x
	else: posY += real_distance
	
	if copyX: x = posX
	if copyY: y = posY
	if copyAlpha: modulate.a = strumNote.modulate.a * multAlpha

func reloadNote() -> void:
	noteScale = styleData.get(&'scale',NoteStyleData.DEFAULT_NOTES_SCALE)
	var data = styleData.data.get(_get_data_animation_name())
	if data: _reload_note_from_data(data)
	else: _reload_note_without_data()
	setGraphicScale(Vector2(noteScale,noteScale))

func _reload_note_from_data(data: Dictionary) -> void:
	noteScale = data.get(&'scale',noteScale)
	var prefix = data.get(&'prefix')
	if prefix: animation.addAnimByPrefix(&'static', prefix, data.get(&'fps',24.0), true)

func _reload_note_without_data() -> void:
	var cut = imageSize/Vector2(Song.keyCount,5)
	setNoteRect(
		Rect2(
			Vector2(cut.x*noteData,cut.y),
			cut
		)
	)

func _get_data_animation_name() -> StringName:
	var _name = directions[noteData]
	if styleData.data.has(_name): return _name
	return &'default'

func resetNote() -> void: ##Reset Note values when spawned.
	distance = 5000.0
	judgementTime = INF
	wasHit = false
	_is_processing = true
	missed = false
	offset = Vector2.ZERO
	material = null
	ignoreNote = false
	splashName = &"noteSplash"

#region Updaters
func _update_distance() -> void: real_distance = distance*_real_note_speed

func _update_note_speed() -> void: 
	_real_note_speed = noteSpeed * 0.45 * multSpeed
	if strumNote: _real_note_speed *= (-strumNote.multSpeed) if strumNote.downscroll else strumNote.multSpeed

#endregion

#region Setters
func loadFromStyle(noteStyle: String, prefix: String = stylePrefix) -> void:
	super.loadFromStyle(noteStyle,prefix)
	var offsets = styleData.get(&'offsets',Vector2.ZERO)
	offsetX = offsets.x; offsetY = offsets.y

func setNoteSpeed(_speed: float) -> void:
	if noteSpeed == _speed: return
	noteSpeed = _speed
	_update_note_speed()

func setNoteData(data: int): super.setNoteData(data); splashPrefix = directions[data]

func setDistance(dist: float) -> void: distance = dist; _update_distance()

func setMultSpeed(_speed: float):
	if multSpeed == _speed: return
	multSpeed = _speed
	_update_note_speed() 

func setStrum(strum: StrumNote) -> void:
	var in_tree = is_inside_tree()
	if strumNote and in_tree: strumNote.mult_speed_changed.disconnect(_update_note_speed)
	strumNote = strum
	if in_tree: strum.mult_speed_changed.connect(_update_note_speed); _update_note_speed()
#endregion

func _on_hit() -> void: kill(); wasHit = true;

func _enter_tree() -> void: 
	_is_processing = true
	if !strumNote: return
	strumNote.mult_speed_changed.connect(_update_note_speed)
	_update_note_speed()

func _exit_tree() -> void: 
	_is_processing = false
	if strumNote: strumNote.mult_speed_changed.disconnect(_update_note_speed)
