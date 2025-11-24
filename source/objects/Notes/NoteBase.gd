@abstract
extends FunkinSprite

const NoteStyleData = preload("uid://by78myum2dx8h")
const Note = preload("uid://deen57blmmd13")
const Song = preload("uid://cerxbopol4l1g")

const directions: PackedStringArray = ['left','down','up','right']
const note_colors: PackedStringArray = ['Purple','Blue','Green','Red']

var styleData: Dictionary
var styleName: StringName: set = setStyleName
var stylePrefix: String

var noteData: int = 0: set = setNoteData ##The direction of this Note.
var noteDirection: String = ''

var noteScale: float = NoteStyleData.DEFAULT_NOTES_SCALE
#region Note Styles
var isPixelNote: bool = false: set = setPixelNote ##Is Pixel Note
var texture: String: set = setTexture ##Note Texture
#endregion

func _init(): super._init(true)

func setNoteRect(region: Rect2):
	image.region_rect = region
	image.pivot_offset = region.size/2.0
	pivot_offset = image.pivot_offset

func loadFromStyle(noteStyle: String,prefix: String = stylePrefix):
	stylePrefix = prefix
	styleName = noteStyle
	if !styleData: return
	isPixelNote = styleData.get(&'isPixel',false)
	texture = styleData.assetPath
	
func _update_style_data() -> void: styleData = NoteStyleData.getStyleData(styleName)

##Reload the Note animation and his texture.
@abstract func reloadNote() -> void

#region Setters
func setStyleName(_name: String) -> void: styleName = _name; _update_style_data()

func setNoteData(_data: int) -> void: 
	noteData = _data; 
	noteDirection = directions[_data]
	stylePrefix = noteDirection

func setPixelNote(isPixel: bool) -> void:
	antialiasing = !isPixel 
	isPixelNote = isPixel

func setTexture(_new_texture: String) -> void:
	if texture == _new_texture: return
	texture = _new_texture
	image.texture = Paths.texture(texture)
	reloadNote()

func _on_texture_changed() -> void: super._on_texture_changed(); animation.clearLibrary(); _animOffsets.clear()


#region Static Funcs
static func sameNote(note1: Note, note2: Note) -> bool: ##Detect if [param note1] is the same as [param note2].
	return note1 and note2 and \
	note1.strumTime == note2.strumTime and \
	note1.noteData == note2.noteData and \
	note1.mustPress == note2.mustPress and \
	note1.isSustainNote == note2.isSustainNote and \
	note1.noteType == note2.noteType
