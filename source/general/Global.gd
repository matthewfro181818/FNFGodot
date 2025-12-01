extends Node
const TRANSITION = preload("res://source/objects/Display/Transition.gd")
signal onSwapTree

static var scene: Node

var scripts_running = FunkinGD.scriptsCreated
var sprites_created = FunkinGD.spritesCreated
var arguments = FunkinGD.arguments
var method_list = FunkinGD.method_list
var is_transiting: bool = false

var current_transition: TRANSITION

var error_prints: Array[Label]

var f11_to_fullscreeen: bool = true

func _init(): _start_clients()
	
func _start_clients():
	Paths._init()
	ClientPrefs._init()
	ScreenUtils._init()

func _ready() -> void: scene = get_parent()

##Swap the Tree for a new [Node]. [br][br]
##[param newTree] can be a [Node], [PackedScene] or [GDScript].
func swapTree(newTree: Variant, transition: bool = true, remove_current_scene: bool = true) -> void:
	if !newTree:
		push_error('swapTree(): Paramter "newTree" is null.')
		return
	
	if transition:
		if is_transiting: return
		is_transiting = true
		doTransition().finished.connect(
			func():
				current_transition.removeTrans()
				swapTree(newTree,false)
				scene.move_child(current_transition,-1),
				CONNECT_ONE_SHOT
		)
		return
	is_transiting = false
	if newTree is GDScript: newTree = newTree.new()
	elif newTree is PackedScene: newTree = newTree.instantiate()
	
	onSwapTree.emit()
	if !newTree.is_inside_tree():scene.add_child(newTree)
	var tree = get_tree()
	
	if remove_current_scene and tree.current_scene: tree.current_scene.queue_free()
	tree.current_scene = newTree
	
func doTransition() -> TRANSITION:
	current_transition = TRANSITION.new()
	scene.add_child(current_transition)
	current_transition.startTrans()
	return current_transition
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_MINUS:
			AudioServer.set_bus_volume_db(0,maxf(-80.0,AudioServer.get_bus_volume_db(0) - 2.0))
		elif event.keycode == KEY_EQUAL:
			AudioServer.set_bus_volume_db(0,AudioServer.get_bus_volume_db(0) + 2.0)
		elif event.keycode == KEY_0:
			AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0))
		elif event.keycode == KEY_F11:
			if !f11_to_fullscreeen or !ScreenUtils.main_window or ScreenUtils.main_window.unresizable: return
			var mode = ScreenUtils.main_window.mode
			if mode == Window.MODE_EXCLUSIVE_FULLSCREEN:ScreenUtils.main_window.mode = Window.MODE_WINDOWED
			else: ScreenUtils.main_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		
func show_label_warning(text: Variant, time: float = 2.0, width: float = ScreenUtils.screenWidth) -> Label:
	text = str(text)
	for i in error_prints: i.position.y += 20
	var label = Label.new()
	label.size.x = width
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.text = text
	var timer = Timer.new()
	label.add_child(timer)
	add_child(label)
	timer.start(time)
	timer.timeout.connect(_label_timer_finished.bind(label))
	label.set('theme_override_constants/outline_size',10)
	label.position.x = ScreenUtils.screenCenter.x - label.size.x*0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	label.z_index = 1
	error_prints.append(label)
	return label

func _label_timer_finished(label: Label):
	var tween = label.create_tween().tween_property(label,'modulate:a',0,2)
	tween.finished.connect(label.queue_free)
	tween.finished.connect(func(): error_prints.erase(label))
