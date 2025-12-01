extends "res://source/objects/Notes/NoteBase.gd"

static var keyCount: int = 4
static var chess_rect_size: Vector2 = Vector2(30,30)

var sustain: ColorRect
var sustain_scale: float = 0.0:
	set(value):
		if sustain: sustain.scale.y = value
		sustain_scale = value

var strumTime: float = 0
var note_color: String = ''

var noteType: StringName: set = setNoteType
var section_data: Array = [strumTime,noteData,sustainLength,''] #[strumTime, direction, sustain length, type]

var mustPress: bool = false

var sustainLength: float = 0.0: set = setNoteLength

func _init(direction: int = 0):
	super._init()
	add_child(image)
	image.region_enabled = true
	image.centered = false
	noteData = direction
	image.item_rect_changed.connect(func():
		var size = image.region_rect.size
		image.scale = (chess_rect_size/size).min(Vector2(1,1))
	)

func reloadNote() -> void: pass

#region Setters:
func setNoteData(data: int) -> void:
	super.setNoteData(data)
	section_data[1] = data
	
func setNoteType(type: StringName) -> void:
	if !type and section_data.size() > 3: section_data.remove_at(3)
	section_data.resize(4)
	section_data[3] = type
	noteType = type

func setNoteLength(length: float):
	length = max(length,0.0)
	if length <= 0.0:
		length = 0.0
		if sustain: sustain.queue_free()
	else:
		if !sustain: _create_sustain()
		sustain.size.y = length/Conductor.stepCrochet * chess_rect_size.y
	sustainLength = length
	section_data[2] = length

func _create_sustain():
	sustain = ColorRect.new()
	sustain.position = Vector2(chess_rect_size.x*0.5 - 5,chess_rect_size.y)
	sustain.size.x = 10
	sustain.scale.y = sustain_scale
	add_child(sustain)
