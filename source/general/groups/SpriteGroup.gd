@icon("res://icons/node2d_group.svg")
extends Node2D
class_name SpriteGroup
##A Sprite Group
##based in [url=https://api.haxeflixel.com/flixel/group/FlxGroup.html]FlxGroup[/url] 
##to be more accurate with 
##[url=https://gamebanana.com/mods/309789]Psych Engine[/url], 
##being easing to understand the code.

@export var members: Array ##The members that this group contains.

var x: float: ##position x
	set(value):
		if x == value: return
		var sub = value-x
		for member in members: _add_member_position(member,sub,0)
		x = value


var y: float: ##position y
	set(value):
		if value == y:return
		var sub = value-y
		for member in members:_add_member_position(member,0,sub)
		y = value

##The [Node] that this group will inherit.
var camera: Node:
	set(cam):
		if camera == cam: return
		if camera: camera.remove_child(self)
		camera = cam
		if !cam: return
		if cam is FunkinCamera: cam.add(self)
		else: cam.add_child(self)
		_parent_camera = cam
	
var _parent_camera: Node:
	set(cam):
		_parent_camera = cam
		for i in members:
			if i and i.get_parent():
				i.set('camera',_parent_camera)
				i.reparent(self,false)
##Scroll factor of this group, just works if the member is a [Sprite].
var scrollFactor: Vector2 = Vector2.ONE


##Add a [Node] to this group. 
##If [code]insertOnGame[/code], the node will be added to tree if the group is added.
func add(node: Node,insertOnGame: bool = true) -> void:
	if !node: return
	if not node in members: members.append(node);# _add_member_position(node,x,y)
	if not insertOnGame: return
	_add_obj_to_camera(node)

func _add_obj_to_camera(node: Node) -> void:
	if !node: return
	if _parent_camera: node.set("camera",_parent_camera)
	if node.get_parent(): node.reparent(self,false)
	else: add_child(node)

##Insert a [Node] in a specific order. 
func insert(at: int, node: Node) -> void:
	if !node: return
	_add_obj_to_camera(node)
	at = clamp(at,0,members.size())
	members.insert(at,node)
	move_child(node,min(at,get_child_count()-1))
	
func replace_at(at: int, node: Node):
	if ArrayUtils.array_has_index(members,at):
		remove_at(at)
	insert(at,node)

##Remove [Node] from the group.
func remove(node: Object) -> void:
	if !node or not node in members: return
	members.erase(node)
	if node is FunkinSprite: node.groups.erase(self)
	if node is Node and node.is_inside_tree(): node.reparent(get_parent(),false)

##Remove a [Node] using his [code]index[/code] in the group.
func remove_at(index: int) -> void:
	var node = members.get(index)
	members.remove_at(index)
	if !node: return
	if node is Node and node.is_inside_tree(): node.reparent(get_parent(),false)

##Queues all members of this group. See also [method Node.queue_free].
func queue_free_members() -> void:
	for i in members: i.queue_free()
	members.clear()

func _add_member_position(member: Node,_x: float = x, _y: float = y) -> void:
	if member is Node2D or member is Control: member.set_position(member.get_position() + Vector2(_x,_y))
