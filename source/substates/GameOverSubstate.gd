extends Node2D

#const Character = preload("res://source/objects/Sprite/Character.gd")

static var back_state
static var characterName: StringName = 'bf-dead'
static var opponentName: StringName = 'bf-dead'
static var deathSoundName: StringName = 'fnf_loss_sfx'
static var loopSoundName: StringName = 'gameOver'
static var endSoundName: StringName = 'gameOverEnd'

static var gameOverTime: float = 2

var isOpponent: bool = false
var character: Character
var bg = ColorRect.new()

var state: int = 0
var sound: AudioStreamPlayer

var cameraTween: Tween
func _init():
	bg.color = Color.BLACK
	add_child(bg)
	
func _ready():
	var char_name = opponentName if isOpponent else characterName
	if !character: character = Character.new(char_name,!isOpponent)
	else:
		if character.curCharacter != char_name:
			var old_pos = character._position
			character = Character.new(char_name,character.isPlayer)
			character._position = old_pos
		else: character.reparent(self)
	
	character.material = null
	character.animation.animation_finished.connect(func(anim):
		if anim == &'firstDeath':
			sound.stream = Paths.music(loopSoundName)
			sound.stream.loop = true
			sound.play()
			FunkinGD.callOnScripts(&'onGameOverStart')
			character.animation.play(&'deathLoop')
			
	)
	
	get_tree().create_timer(0.5).timeout.connect(func():
		cameraTween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		cameraTween.tween_property(self,'position',
		-character.getCameraPosition() + ScreenUtils.screenCenter*scale,
		4)
	)
	add_child(character)
	character.animation.play(&'firstDeath')
	sound = FunkinGD.playSound(deathSoundName)
	sound.reparent(self)


func confirm() -> void:
	if state >= 3: return
	character.animation.play(&'deathConfirm')
	sound.stream = Paths.music(endSoundName)
	sound.play()
	state = 3
	get_tree().create_timer(gameOverTime).timeout.connect(_on_confirm_time_completed)

func _on_confirm_time_completed():
	create_tween().tween_property(self,^'modulate:a',0,2.0).finished.connect(func():
		if FunkinGD.game: FunkinGD.game.restartSong(true)
	)

func back() -> void:
	if !back_state: return
	Global.swapTree(back_state,true)
	Global.onSwapTree.connect(queue_free,CONNECT_ONE_SHOT)
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ENTER and not state == 2: confirm()
		elif event.keycode == KEY_BACKSPACE: back()
	elif event is InputEventMouseButton:
		if !event.pressed: return
		if event.button_index == 1: confirm()
