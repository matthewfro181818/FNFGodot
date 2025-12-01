@icon("res://icons/alphabet.svg")
extends Node2D

const AnimatedLetter = preload("res://source/objects/AlphabetText/AnimatedLetter.gd")

@export var text: String = '': set = set_text

@export var x: float = 0.0: set = set_x
@export var y: float = 0.0: set = set_y
@export var imageFile: String = 'alphabet'

var text_width: float = -1

var lines_space: float = 1.0
var letters_space: float = 5.0

var pivot_offset: Vector2 = Vector2.ZERO
var width: float = 0.0
var height: float = 0.0

var size: Vector2 = Vector2.ZERO
var letters_in_lines: Array = []

var horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
var vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_TOP

@export var antialiasing: bool = true:
	set(value):
		antialiasing = value
		texture_filter = TextureFilter.TEXTURE_FILTER_PARENT_NODE if value else TextureFilter.TEXTURE_FILTER_NEAREST

var lettersPrefix: Dictionary = {}

signal text_changed(new_text: String)


func _init(curText: String = '', textWidth: float = -1.0):
	Paths.image(imageFile)
	if curText: text = curText
	text_width = textWidth
	
func set_text(newText: String):
	if newText == text: return
	text = newText

	for letters in letters_in_lines:
		for i in letters: if i: remove_child(i)
	
	letters_in_lines.clear()
	letters_in_lines.append([])
	
	width = 0
	height = 0
	_insert_letters(text)
	
	size = Vector2(width,height)
	pivot_offset = size*0.5
	text_changed.emit(text)

func _insert_letters(_text: String):
	var cur_line: int = 0
	for letter in _text:
		var new_line = letter == '\n'
		if text_width != -1 and width >= text_width or new_line:
			letters_in_lines.append([])
			cur_line += 1
			if new_line: continue
		
		var newLetter = _add_letter(letter)
		letters_in_lines[cur_line].append(newLetter)
		if newLetter: width += newLetter.pivot_offset.x*2.0
	update_letters_position()
	
func _add_letter(_letter: StringName) -> AnimatedLetter:
	if _letter == " ": return 
	var newLetter = AnimatedLetter.new(imageFile)
	var suffix = lettersPrefix.get(_letter)
	if suffix: newLetter.suffix = suffix
	add_child(newLetter)
	newLetter.letter = _letter
	return newLetter

func update_letters_position(h_aligment: HorizontalAlignment = horizontal_alignment):
	width = 0
	height = 0
	
	var lines_sizes: PackedFloat32Array = []
	var line: int = 0
	for i in letters_in_lines:
		var curTextPos: float = 0.0
		var cur_width: float
		
		var offset_y = height
		for letter: AnimatedLetter in i: 
			if !letter: 
				curTextPos += 15 + letters_space
				continue
			
			
			
			letter._position = Vector2(
				curTextPos,
				offset_y
			)
			
			var letter_size = letter.pivot_offset*2.0
			curTextPos += letter_size.x + letters_space
			
			cur_width = curTextPos
			if cur_width > width: width = cur_width
			
			height = maxf(height,letter_size.y*(line+1))
		line += 1
		lines_sizes.append(cur_width)
		
	match h_aligment:
		HORIZONTAL_ALIGNMENT_CENTER: 
			var _line: int = 0
			for letters in letters_in_lines:
				var center = lines_sizes[_line]*0.5
				for i in letters: if i: i._position.x -= center
				_line += 1
			
		HORIZONTAL_ALIGNMENT_RIGHT:
			var _line: int = 0
			for letters in letters_in_lines:
				var center = lines_sizes[_line]
				for i in letters: if i: i._position.x -= center
				_line += 1
	match vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			var center = height*0.5
			for l in letters_in_lines: for i in l: if i: i._position.y -= center
			
		VERTICAL_ALIGNMENT_BOTTOM:
			for l in letters_in_lines: for i in l: if i: i._position.y -= height
			


func set_x(newX):
	x = newX
	position.x = x
	
func set_y(newY):
	y = newY
	position.y = y
