extends Node2D
const AlphabetText = preload("res://source/objects/AlphabetText/AlphabetText.gd")

var allTexts: Array = []
signal resume_song
signal restart_song
signal exit_song

var curSection: String = ''

var curText: int:
	set(index):
		var textSize = allTexts.size()-1

		var audio = FunkinGD.playSound(Paths.sound('scrollMenu'))
		audio.reparent(self)
		if index < 0:
			index += textSize+1
		elif index > textSize:
			index -= textSize+1
		
		if index+1 <= textSize:
			allTexts[index+1].modulate = Color.GRAY
		if index-1 >= 0:
			allTexts[index-1].modulate = Color.GRAY
		
		allTexts[index].modulate = Color.WHITE
		curText = index
var curTextFloat: float = 0.0
var is_scrolling: bool = false
var scrolled: bool = false

var rect = ColorRect.new()

@onready var lettersGroup: Node2D = Node2D.new()
func _init():
	rect.color = Color.BLACK
	rect.size = Vector2(ScreenUtils.screenWidth,ScreenUtils.screenHeight)
	rect.color.a = 0.5

func _ready():
	name = 'PauseSubstate'
	add_child(rect)
	add_child(lettersGroup)
	var textPause: PackedStringArray = [
		'Resume',
		'Restart Song',
		'Skip Song: 0:00/0:00',
		'Exit Song'
	]
	for texts in textPause:
		createText(texts)
	curText = 0
	
func createText(text: String):
	var newAlphabet = AlphabetText.new(text)
	newAlphabet.x = 100
	newAlphabet.y = 250
	newAlphabet.name = text
	var tween = create_tween().set_parallel(true)
	tween.tween_property(newAlphabet,'x',newAlphabet.x + (50*allTexts.size()),0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(newAlphabet,'y',newAlphabet.y + (150*allTexts.size()),0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	newAlphabet.modulate = Color.GRAY
	lettersGroup.add_child(newAlphabet)
	allTexts.append(newAlphabet)
	
func _process(_delta):
	if curText != -1:
		var textSprite = allTexts[curText]
		lettersGroup.position = lettersGroup.position.lerp(-textSprite.position + Vector2(100,300),_delta*20)


func _remove_pause():
	#free()
	set_process_input(false)
	create_tween().tween_property(self,"modulate:a",0,0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC).finished.connect(free)
	
func swapSection(section: String):
	for texts in allTexts:
		texts.queue_free()
	allTexts.clear()
	if section == 'Change Difficulty':
		pass

func selectCurrentOption():
	var textSprite = allTexts[curText].name
	if textSprite == "Resume": resume_song.emit()
	elif textSprite == "Restart Song": restart_song.emit()
	elif textSprite == "Exit Song": exit_song.emit()
	else: return
	_remove_pause()
	
func _input(event: InputEvent) -> void:
	if !is_inside_tree(): return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP: curText -= 1
			KEY_DOWN: curText += 1
			KEY_ENTER:
				if curSection: return
				selectCurrentOption()
	elif event is InputEventScreenTouch:
		if !is_scrolling and event.pressed:
			scrolled = false
			is_scrolling = true
			curTextFloat = curText
		else:
			if not scrolled:
				selectCurrentOption()
			is_scrolling = false
			
	elif event is InputEventScreenDrag:
		if !is_scrolling: return
		curTextFloat += -event.relative.y/100
		if curTextFloat <= -1:
			curTextFloat = allTexts.size()-1
		elif curTextFloat >= allTexts.size():
			curTextFloat = 0
		
		if int(curTextFloat) != curText:
			curText = int(curTextFloat)
			scrolled = true
