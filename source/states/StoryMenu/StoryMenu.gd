extends Node

var back_to: Object

var characters: Dictionary[String,FunkinSprite] = {}

var weeks_data: Dictionary = {}
var weeks_data_keys: PackedStringArray = []

var cur_week_data: Dictionary = {}

var cur_week_selected: int = 0

var bg = ColorRect.new()
var weeks_bg = ColorRect.new()
var weeks_node = Node2D.new()

var tracks_text = Label.new()
func _ready():
	
	bg.color = Color.YELLOW
	bg.size = ScreenUtils.screenSize
	add_child(bg)
	
	var border_up = ColorRect.new()
	border_up.color = Color.BLACK
	border_up.size = Vector2(ScreenUtils.screenWidth,60)
	add_child(border_up)


	weeks_bg.color = Color.BLACK
	weeks_bg.size = ScreenUtils.screenSize
	weeks_bg.position.y = 450
	weeks_bg.clip_contents = true
	add_child(weeks_bg)
	
	var tracks = Sprite2D.new()
	tracks.texture = Paths.texture('storymenu/ui/tracks')
	tracks.position = Vector2(50,500)
	tracks.centered = false
	add_child(tracks)
	
	tracks_text.label_settings = LabelSettings.new()
	tracks_text.label_settings.font_color = Color(0.89,0.34,0.45)
	tracks_text.label_settings.font_size = 25
	tracks_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tracks_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tracks_text.clip_text = true
	tracks_text.size = Vector2(300,ScreenUtils.screenHeight)
	tracks_text.position = Vector2(-tracks_text.size.x*0.5 + 100,50)
	tracks_text.text = 'cuzinho'
	tracks.add_child(tracks_text)
	
	weeks_bg.add_child(weeks_node)
	loadWeeks()
	createWeeks()

func loadWeeks():
	var folders_to_look: PackedStringArray = ['/assets/weeks']
	for i in Paths.modsEnabled: folders_to_look.append('/mods/'+i+'/weeks')
	
	for i in folders_to_look:
		for json_s in Paths.getFilesAtAbsolute(Paths.exePath+i,true,['.json'],true):
			var json = Paths.loadJsonNoCache(json_s)
			json.mod = Paths.getModFolder(json_s)
			
			var json_name = json_s.get_file().get_basename()
			weeks_data[json_name] = json
			weeks_data_keys.append(json_name)

func _process(delta: float) -> void: weeks_node.position.y = lerpf(weeks_node.position.y,-150*cur_week_selected,10*delta)
	
func createWeeks():
	var offset: float = 70
	for i in weeks_data:
		var title = 'images/storymenu/titles/'+i+'.png'
		if Paths.file_exists(title):
			var sprite = Sprite2D.new()
			sprite.position = Vector2(ScreenUtils.screenCenter.x,offset)
			sprite.texture = Paths.texture(title)
			weeks_node.add_child(sprite)
		offset += 150

func setWeekIndex(index: int):
	if !weeks_data: return
	if index < 0: index = weeks_data.size()-1
	elif index >= weeks_data.size(): index = 0
	cur_week_data = weeks_data[weeks_data_keys[index]]
	var text_weeks: String = ''
	for i in cur_week_data.get('songs',[]): text_weeks += i[0]+'\n'
	tracks_text.text = text_weeks
	FunkinGD.playSound('scrollMenu')
	cur_week_selected = index
	
	bg.color = Color(cur_week_data.get('background',Color.YELLOW))
	#Load Props
	var props = cur_week_data.get('props')
	if props:
		var new_props: PackedStringArray
		
		var prop_index: int = 0
		for i in props:
			var sprite = createProp(i,prop_index)
			if sprite: new_props.append(sprite.image.texture.resource_name+'.png')
			prop_index += 1
		for i in characters.keys():
			if i in new_props: continue
			characters[i].queue_free()
			characters.erase(i)
	else:
		for i in characters.keys():
			characters[i].queue_free()
			characters.erase(i)
	
func createProp(data, prop_index:int =0):
	var tex_path = Paths.imagePath(data.get('assetPath',''))
	var sprite: FunkinSprite
	if characters.has(tex_path):
		sprite = characters[tex_path]
		sprite.animation.clearLibrary()
	else:
		sprite = FunkinSprite.new()
		sprite.image.texture = Paths.texture(tex_path)
		characters[tex_path] = sprite
		add_child(sprite)
		if !sprite.image.texture: return
	
	var prop_scale = data.get('scale',1.0)
	sprite.scale = Vector2(prop_scale,prop_scale)

	
	
	var animations = data.get('animations')
	if animations:
		for i in data.animations: 
			sprite.animation.addAnimByPrefix(i.name,i.prefix,i.get('frameRate',24.0),true)
		sprite.animation.play(&'idle')
	
	sprite.position = VectorUtils.array_to_vec(data.get('offsets',[0,0]))
	sprite.position += Vector2(
		ScreenUtils.screenCenter.x - 650 + (300*prop_index),
		10
	)
	
	return sprite
	

func exit():
	if !back_to: return
	set_process_input(false)
	Global.swapTree(back_to,true)
	
func selectWeek(week: int = cur_week_selected):
	pass
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed: return
		match event.keycode:
			KEY_UP: setWeekIndex(cur_week_selected-1)
			KEY_DOWN: setWeekIndex(cur_week_selected+1)
			KEY_ENTER: selectWeek()
			KEY_BACKSPACE: exit()
