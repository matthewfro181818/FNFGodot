@tool
extends Node3D
class_name FunkinSprite3D
##A expensive [Node2D] class
##based in [url=https://api.haxeflixel.com/flixel/FlxSprite.html]FlxSprite[/url] 
##to be more accurate with 
##[url=https://gamebanana.com/mods/309789]Psych Engine[/url], 
##being easing to understand the code.
@onready var animation: AnimationPlayer = $AnimationPlayer

@export var x: float:
	set(value):
		#position.x += value - x
		_position.x = value
	get():
		return _position.x
##Position Y
@export var y: float: 
	set(value):
		#position.y += value - y
		_position.y = value
	get():
		return _position.y

##Position Y
@export var z: float: 
	set(value):
		#position.y += value - y
		_position.z = value
	get():
		return _position.z

@export var _position: Vector3 = Vector3.ZERO:
	set(value):
		position += value - _position
		_position = value

@export var offset: Vector3 = Vector3.ZERO: 
	set(value):
		position -= value - offset
		offset = value

var scaling_offset: bool = false

##Similar to [member Control.rotation_degrees].
@export var angle: float: 
	set(value):
		rotate_z(deg_to_rad(value))
	get():
		return rad_to_deg(rotation.z)


##A "parallax" effect
@export var scrollFactor: Vector2 = Vector2.ONE


@export_category("Velocity")
##This will accelerate the velocity from the value setted.
@export var acceleration: Vector2 = Vector2.ZERO

##Will add velocity from the position, making the sprite move.
@export var velocity: Vector2 = Vector2.ZERO
		
##The limit of the velocity, set [Vector2](-1,-1) to unlimited.
@export var maxVelocity: Vector2 = Vector2(999,999)


var groups: Array[SpriteGroup] = []


var parent: Node
var _lastParent: Node = null


var _animOffsets: Dictionary = {}
func _ready():
	animation.animation_started.connect(func(i):
			if _animOffsets.has(i):
				offset = _animOffsets[i] * scale if scaling_offset else _animOffsets[i]
	)

func _process(delta: float) -> void:
	#Add velocity
	if acceleration != Vector2.ZERO:
		velocity += acceleration * delta
	
	if velocity != Vector2.ZERO:
		_position += clamp(velocity,-maxVelocity,maxVelocity) * delta
		return
	_updatePos()

##[codeblock]
##Sprite.set_pos(Vector2(1.0,1.0)) #Move Sprite to (1.0,1.0).
##Sprite.set_pos(1.0,1.0)#The same, but separated.
##[/codeblock]
func set_pos(pos_x: Variant, pos_y: float = 0.0,pos_z: float = 0.0) -> void:
	if pos_x is Vector3:
		_position = pos_x
		return
	_position = Vector3(pos_x,pos_y,pos_z)


func _updatePos() -> void:
	position = _position

func join(front: bool = false):
	if groups:
		groups.back().add(self,true)
		return
	
	if _lastParent:
		_lastParent.add_child(self)
		return
	
	
##Remove the Sprite from the game, still can be accesed.
func kill() -> void:
	if parent:
		parent.remove_child(self)
	
	
func removeFromGroups() -> void:
	for group in groups:
		group.remove(self)


##When the [code]animName[/code] plays, the offset placed in [code]offsetX,offsetY[/code] will be set.
func addAnimOffset(animName: StringName, offsetX: float = 0.0, offsetY: float = 0.0, offsetZ: float = 0.0) -> void:
	_animOffsets[animName] = Vector3(offsetX,offsetY,offsetZ)
	if animation and animation.current_animation == animName: offset = Vector3(offsetX,offsetY,offsetZ)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_lastParent = parent
			parent = get_parent()
		NOTIFICATION_UNPARENTED:
			parent = null
	
	
