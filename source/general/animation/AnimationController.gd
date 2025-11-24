extends Resource
##A Animation Class
##based in [url=https://api.haxeflixel.com/flixel/animation/FlxAnimation.html]FlxAnimation[/url], 
##avoiding the use of AnimationPlayer, improving performance.[br][br]
##
##How to insert a animation, using a [NinePatchRect](or a [Sprite2D] with [member Sprite2D.region_rect] enabled):
##[codeblock]
##var nine_patch: NinePatchRect = NinePatchRect.new()
##var animation: AnimationController = AnimationController.new()
##func _ready():
##   add_child(nine_patch) #Add object to scene.
##   animation.node_to_animate = nine_patch #Insert the animation that will be animated.
##   animation.frames = [
##      {'region_rect': Rect2(0,0,100,100}, #First frame will set the "region_rect" to [Rect2](0,0,100,100)
##      {'size': Vector2(10,10)} #Second frame will set the "size" to [Vector2](10,10)
##   ]
##   animation.frameRate = 10 #The animation velocity by frame.
##   animation.looped = true #Animation
##   animation.play() #Play Animation
##   animation.play_reverse() #Play in reverse.
##func _process(delta):
##   process_frame(delta)
##[/codeblock][br]


##Frames that will be played. 
##This stores an [Array] that contains a [Dictionary]:[code]
##{
##'property': 'name',
##'value': Variant
##}[/code][br]
##Example: [codeblock]
##var animation = AnimationController.new()
##var node = Node2D.new()
##animation.node_to_animate = node
##animation.frames = [
##   [
##    {'property': 'position:x','value': -50}
##   ],
##   [
##     {'property': 'position:x',value: 50}
##   ]
##]
##animation.frameRate = 10
##animation.play()
##[/codeblock]
##In that example, in the first frame, the node will be move to -50 in x position,[br]
##and in the second frame will be moved to 50.
@export var frames: Array

var node_to_animate: Node: set = set_node_animate ##The Node to animate, [u][b]essential to make the animation work.[/u/][/b]

@export var reverse: bool = false

@export var loop_frame: int = 0

@export var frameRate: float = 24.: set = set_frame_rate ##The velocity of the animation.
@export var maxFrames: int = 0 ##The number of frames in the animation.


@export var curFrame: int = 0: set = set_cur_frame, get = get_cur_frame ##The current frame of the animation. Can also be changed outside of the script.

var curFrameData: Dictionary

@export var _real_cur_frame: int = 0: set = _set_real_cur_frame

@export var finished: bool = false: set = _set_finished ##If the animation is finished.
var paused: bool = false: set = pause

@export var speed_scale: float = 1.0: set = set_speed_scale  ##A multiplier for the speed of the animation.

##If [code]true[/code], the animation will restarts when it finishes.
@export var looped: bool = false
var _float_frame: float = 0.0


##If the animation is playing.
##Setting to [code]false[/code], the animation will be stop playing, 
##useful if you want to stop it for a pause menu or something similar.
var playing: bool

var _animation_speed: float = frameRate

signal animation_finished
signal animation_started
signal animation_resumed
signal animation_stopped

func process_frame(delta: float) -> void: ##Process animation
	if !playing: return
	if reverse: _float_frame -= delta*_animation_speed
	else: _float_frame += delta*_animation_speed
	
	if _float_frame >= 0 and _float_frame < maxFrames: 
		_real_cur_frame = _float_frame; return
	
	#Loop Animation
	if looped: _float_frame = loop_frame; return
	
	#Finish Animation
	finished = true

func play() -> void: ##Start the animation.
	reverse = false
	_float_frame = 0
	loop_frame = 0
	start_anim()

func play_reverse() -> void: ##Play the animation in reverse.
	reverse = true
	_float_frame = maxFrames-1
	loop_frame = int(_float_frame)
	start_anim()
	
func start_anim():
	finished = false
	paused = false
	
	if !frames: maxFrames = 0; return
	maxFrames = frames.size()
	
	if _real_cur_frame != _float_frame: _real_cur_frame = _float_frame
	else: set_frame(_float_frame)
	
	animation_started.emit()
	
func resume() -> void:  ##Resume progress
	paused = false
	animation_resumed.emit()

func pause(p: bool = true) -> void: paused = p; playing = !p ##Pause animation

func stop() -> void: ##Stop the animation, making it not process frames.
	paused = false
	playing = false
	_float_frame = 0
	animation_stopped.emit()

func set_frame(frame: int) -> void:
	curFrameData = frames[frame]
	for i in curFrameData:
		if i is NodePath: node_to_animate.set_indexed(i,curFrameData[i])
		else: node_to_animate.set(i,curFrameData[i])


#region Setters
func set_cur_frame(f: int):
	f = clampi(f,0,maxi(0,maxFrames-1))
	if curFrame == f: return
	_float_frame = f
	_real_cur_frame = f

func _set_real_cur_frame(f: int):
	if _real_cur_frame == f: return
	_real_cur_frame = f
	set_frame(f)

func _set_finished(f: bool):
	if f == finished: return
	finished = f
	if !finished: return
	playing = false
	animation_finished.emit()

func set_node_animate(node) -> void:
	node_to_animate = node
	if !node: stop();

func set_frame_rate(value: float) -> void:
	if value == frameRate: return
	frameRate = value
	_update_animation_speed()

func set_speed_scale(value: float) -> void:
	if value == speed_scale: return
	speed_scale = value
	_update_animation_speed()
#endregion

#region Getters
func get_cur_frame() -> int: return _real_cur_frame
#endregion

func _update_animation_speed() -> void: _animation_speed = frameRate*speed_scale
