extends Object

const Reflect = preload("uid://btume6yjt6ubo")
#region Variables
static var debugMode: bool = OS.is_debug_build()

#region Storage
static var game: Node
static var modVars: Dictionary ##[b]Variables[/b] created using [method setVar] and [method createCamera] methods.
static var spritesCreated: Dictionary[StringName,Node] ##Sprites created using [method makeSprite] or [method makeAnimatedSprite] methods.
static var groupsCreated: Dictionary[StringName,SpriteGroup]##Sprite groups created using [method createSpriteGroup] method.
static var tweensCreated: Dictionary[StringName,RefCounted] ##[b][Tween][/b] created using [method startTween] function.
static var shadersCreated: Dictionary[StringName,ShaderMaterial] ##[b]Shaders[/b] created using [method initShader] function.
static var soundsPlaying: Dictionary[StringName,AudioStreamPlayer] = {} ##[b]Sounds[/b] created using [method playSound] function.
static var timersPlaying: Dictionary[StringName,Array] ##[b]Timers[/b] created using [method runTimer] function.
static var scriptsCreated: Dictionary ##Scripts created using [method addScript] function.
static var scriptsUID: Dictionary[int,Object]
static var textsCreated: Dictionary[StringName,Label] ##[b]Texts[/b] created using [method makeText] function.
static var dictionariesToCheck: Array[Dictionary] = [modVars,spritesCreated,shadersCreated,textsCreated,groupsCreated]
#endregion

#region Script Arguments
static var arguments: Dictionary[int,Dictionary]
static var method_list: Dictionary[StringName,Array]
#endregion

#endregion

#region Audio Methods
static func _create_audio(stream: Variant, tag: String = '') -> AudioStreamPlayer:
	var audio = _get_sound(stream)
	if !audio: return
	(game if game else Global).add_child(audio)
	if !tag: return audio
	audio.name = tag
	soundsPlaying[tag] = audio
	audio.finished.connect(stopSound.bind(tag),CONNECT_ONE_SHOT)
	return audio

static func stopSound(tag: StringName):
	if !soundsPlaying.has(tag): return
	soundsPlaying[tag].stop()
	soundsPlaying.erase(tag)

static func _get_sound(stream: Variant):
	if !stream is AudioStream: stream = Paths.sound(stream); if !stream: return
	var audio = AudioStreamPlayer.new()
	audio.stream = stream;
	audio.finished.connect(audio.queue_free)
	return audio
#endregion

#region Object Methods

#endregion

#region Sprite Methods
static func _insert_sprite(tag: StringName, object: Node) -> void: 
	var sprite = spritesCreated.get(tag)
	if sprite and sprite is Node: sprite.queue_free()
	spritesCreated[tag] = object
#endregion


#region Shader Methods
static func _find_shader_material(shader: Variant) -> ShaderMaterial:
	if !shader or shader is ShaderMaterial: return shader
	var material = shadersCreated.get(shader); if material: return material
	material = Reflect._find_object(shader)
	return material.get(&'material') if material else null

static func _check_shaders_array(shaders: Array) -> void:
	var index: int = shaders.size()
	while index:
		index -= 1
		var s = shaders[index]
		if s is String: shaders[index] = _find_shader_material(s)
#endregion

#region Property Methods

#endregion

#region Classes Methods
static var class_dirs: PackedStringArray = [
	'',
	'res://',
	'res://source/',
	'res://source/general/',
	'res://source/objects/',
	Paths.exePath+'/assets/'
]


#endregion

#region Color Methods
static func _get_color(color: Variant) -> Color: return color if color is Color else Color.html(color)
#endregion

#region Script Methods
static func _find_script_path(script: Object) -> String:
	var id = script.get_instance_id()
	for i in scriptsCreated: if scriptsCreated[i].get_instance_id() == id: return i
	return ''

static func _script_path(path: String): return path if path.ends_with('.gd') else path+'.gd'

static func get_arguments(script: Object) -> Dictionary[StringName,Variant]:
	var functions: Dictionary[StringName,Variant] = {}
	for f in script.get_script().get_script_method_list():
		if f.flags == 33: continue
		
		var args = f.args
		if !args: functions[f.name] = null; continue
		
		var index: int = f.default_args.size()
		while index: index -= 1; args[index].default = f.default_args[index];
		functions[f.name] = args
		
	return functions

static func _insert_script(script: Object, path: String = '') -> bool:
	if !script: return false
	var args = get_arguments(script)
	scriptsCreated[path] = script
	arguments[script.get_instance_id()] = args
	
	
	for func_name in args:
		if !func_name in method_list: method_list[func_name] = [script]
		else: method_list[func_name].append(script)
	
	
	if args.has(&'onCreate'): script.onCreate()
	if args.has(&'onCreatePost') and game and game.get(&'stateLoaded'): script.onCreatePost(); 
	return true

static func removeScript(path: Variant):
	var script: Resource
	if path is Resource: 
		script = path
		path = _find_script_path(script)
		if !path: return
	else:
		if path is String: path = _script_path(Paths.getPath(path,false))
		script = scriptsCreated.get(path)
		if !script: return
		
	scriptsCreated.erase(path)
	var script_args = arguments.get(script.get_instance_id())
	for i in script_args:
		if method_list[i].size() == 1: method_list.erase(i)
		else:  method_list[i].erase(script)
	FunkinGD.callOnScripts(&'onScriptRemoved',[script,path])

static func _clear_scripts(absolute: bool = false):
	if absolute:
		for i in spritesCreated.values(): if i: i.queue_free()
		for i in modVars.values(): if i is Node: i.queue_free()
		for i in timersPlaying.values(): if i: i[0].stop()
		for i in tweensCreated.values(): if i: i.stop()
		for i in groupsCreated.values(): i.queue_free()
	soundsPlaying.clear()
	method_list.clear()
	shadersCreated.clear()
	scriptsCreated.clear()
	shadersCreated.clear()
	modVars.clear()
	spritesCreated.clear()
	groupsCreated.clear()
	timersPlaying.clear()
	tweensCreated.clear()


static func _call_script_no_check(script: Object, function: StringName, parameters: Variant) -> Variant:
	var args = arguments.get(script.get_instance_id()); if !args or !args.has(function): return
	args = args[function]
	
	if !args: return script.call(function)
	
	if args.size() == 1: return script.call(function,parameters[0] if ArrayUtils.is_array(parameters) else parameters)
	return script.callv(function,_sign_parameters(args,parameters)) 

static func _sign_parameters(args: Array,parameters: Variant) -> Array:
	if !args: return args
	
	if ArrayUtils.is_array(parameters): return _sign_parameters_array(args,parameters)
	parameters = [_sign_value(parameters,args[0].type)]
	var index: int = 1
	while index < args.size(): 
		var i = args[index]
		if i.has(&'default'): break
		parameters.append(MathUtils.get_new_value(i.type));
		index += 1
	return parameters

static func _sign_parameters_array(args: Array, parameters: Array) -> Array:
	var index: int = -1
	
	var args_length = args.size()-1
	var append: bool = false
	while index < args_length:
		index +=1
		var i = args[index]
		if append:
			if i.has(&'default'): break
			parameters.append(MathUtils.get_new_value(i.type))
		else: 
			append = index == parameters.size()-1
			parameters[index] = _sign_value(parameters[index],i.type)
	return parameters

static func _sign_value(value: Variant, type_to_convert: Variant.Type) -> Variant:
	return value if type_to_convert == TYPE_NIL or typeof(value) == type_to_convert else type_convert(value,type_to_convert)

#endregion

#region Warning Methods
static func show_funkin_warning(warning: String, color: Color = Color.RED, only_show_when_debugging: bool = true):
	if only_show_when_debugging and !debugMode: return
	var text = Global.show_label_warning(warning,5.0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.modulate = color 
#endregion

#region Timer Methods
static func _create_timer(tag: StringName, time: float, loops: int) -> Array:
	var timer = Timer.new()
	var data = [timer,loops]
	timer.timeout.connect(func():
		if data[1] > 1: timer.start(time); data[1] -= 1
		else: timersPlaying.erase(tag); timer.queue_free()
		FunkinGD.callOnScripts(&'onTimerCompleted',[tag,data[1]])
	)
	get_game().add_child(timer)
	timersPlaying[tag] = data
	timer.start(time)
	return data

#endregion

#region Getters
static func get_game() -> Node:
	return game if game else Global
#endregion

#endregion

static func _show_property_no_found_error(property: String) -> void:
	var split = property.split('.')
	var obj_name = split[0]
	if split.size() > 1:
		show_funkin_warning('Error on setting property "'+property.right(-obj_name.length()-1)+'": '+obj_name+" not founded")
	else:
		show_funkin_warning('Error on setting property: '+obj_name+" not founded")
	return
