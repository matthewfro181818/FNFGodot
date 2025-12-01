extends Node

const AlphabetText = preload("res://source/objects/AlphabetText/AlphabetText.gd")
const BarSize = 70
const ModInfoScale = Vector2(0.45,0.45)
const Icon: GDScript = preload('res://source/objects/UI/Icon.gd')

const UNSELECT_COLOR = Color.DIM_GRAY
const SELECT_COLOR = Color.WHITE

const SongsOffset = 180

var PlayState: GDScript = preload("res://source/states/PlayState.gd")
var ModeSelect: GDScript = preload("res://source/states/Menu/ModeSelect.gd")

var score_data: Dictionary

static var curMod: int = 0
static var curSongIndex: int = 0
static var curDifficulty: int = 0

var weekList: Dictionary

var tweenStarted: bool 
var difficulty: String = ''

var menuSong: AudioStreamPlayer = AudioStreamPlayer.new()

@onready var difficultySprite: FunkinSprite = FunkinSprite.new(true)
@onready var difficultyText: AlphabetText = AlphabetText.new()
@onready var diffiSelectLeft: FunkinSprite = FunkinSprite.new(true)
@onready var diffiSelectRight: FunkinSprite = FunkinSprite.new(true)

@onready var modSelectLeft: FunkinSprite = FunkinSprite.new(true)
@onready var modSelectRight: FunkinSprite = FunkinSprite.new(true)

var diffiTween: Tween
var weeks: Array

var cur_song: StringName

static var mods: Array

var bar_top = ColorRect.new()
var bar_bottom = ColorRect.new()

@onready var bar_tween = create_tween()

var cur_week_node: Node2D

@onready var cur_mod_text: AlphabetText = AlphabetText.new()
@onready var cur_mod_image: Sprite2D = Sprite2D.new()

var cur_mod_data: Array
var cur_song_data: Array
var cur_song_difficulties: Array
var cur_song_difficulties_data: Dictionary


var isSettingDifficulty: bool = false

var scroll_index: float = curSongIndex
var click_select_song: bool = false
var is_scrolling: bool = false
signal exiting

func _ready():
	name = 'Freeplay'
	
	add_child(bar_top)
	add_child(bar_bottom)
	
	
	#Difficulty Sprite
	difficultySprite.set_position_xy(ScreenUtils.screenWidth,50)
	difficultySprite.modulate.a = 0.0
	add_child(difficultySprite)
	difficultySprite.add_child(difficultyText)
	
	for i in [diffiSelectLeft,diffiSelectRight,modSelectLeft,modSelectRight]:
		i.image.texture = Paths.texture('freeplay/freeplaySelector')
		i.animation.addAnimByPrefix('anim','arrow pointer loop',24,true)
	
	diffiSelectLeft._position = -Vector2(80,15)
	difficultySprite.add_child(diffiSelectLeft)
	
	diffiSelectRight._position.y = -15
	diffiSelectRight.flipX = true
	difficultySprite.add_child(diffiSelectRight)
	
	
	
	#Mod Sprites
	bar_top.add_child(cur_mod_image)
	cur_mod_image.add_child(cur_mod_text)
	cur_mod_image.add_child(modSelectLeft)
	
	cur_mod_image.centered = false
	cur_mod_image.position.x = 50
	cur_mod_image.scale = ModInfoScale
	
	modSelectLeft.scale = Vector2(1.7,1.7)
	modSelectRight.scale = Vector2(1.7,1.7)
	modSelectRight.flipX = true
	modSelectRight._position.y = 25
	modSelectLeft.set_position_xy(-100,25)
	
	cur_mod_image.add_child(modSelectRight)
	
	cur_mod_text.scale = ModInfoScale + Vector2.ONE
	cur_mod_text.position.y = 20
	
	
	bar_top.size = Vector2(ScreenUtils.screenWidth,BarSize)
	bar_top.position.y = -BarSize
	bar_top.color = Color.BLACK
	
	bar_bottom.size = Vector2(ScreenUtils.screenWidth,BarSize)
	bar_bottom.position.y = ScreenUtils.screenHeight
	bar_bottom.color = Color.BLACK
	
	Paths.clearFiles()
	menuSong = FunkinGD.playSound(Paths.music('freakyMenu'),1.0,'freakyMenu',false,true)
	
	loadWeeks()
	
	var old_selected = curSongIndex
	setModSelected(curMod)
	setSongSelected(old_selected,false)
	exiting.connect(_on_exiting)
	Global.onSwapTree.connect(func(): exiting.emit(); menuSong.queue_free(),CONNECT_ONE_SHOT)
	
	bar_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	bar_tween.parallel().tween_property(bar_top,"position:y",0,1)
	bar_tween.parallel().tween_property(bar_bottom,"position:y",ScreenUtils.screenHeight-BarSize,1)
	
	if cur_week_node:
		cur_week_node.position.x = -ScreenUtils.screenWidth
		bar_tween.parallel().tween_property(cur_week_node,"position:x",0,1)

func _on_exiting() -> void:
	for i in get_children(): remove_child(i);
	queue_free()

func loadWeekFrom(path: String):
	var mod = Paths.getModFolder(path)
	if !mod: mod = Paths.game_name
	for i in mods: if i[0] == mod: return #Check if mod is already loaded

	var weekFolder = Paths.exePath+'/'+path
	var weeksFounded: Array = []
	if Paths.dir_exists(weekFolder):
		if FileAccess.file_exists(weekFolder+'/weekList.txt'):
			for split in FileAccess.get_file_as_string(weekFolder+'/weekList.txt').split('\n'):
				if FileAccess.file_exists(weekFolder+'/'+split+'.json'): weeksFounded.append(split)
			
		for week in DirAccess.get_files_at(weekFolder):
			if not week.replace('.json','') in weeksFounded and week.ends_with(".json"):
				weeksFounded.append(week)
	
	var mod_node = Node2D.new()
	var songs_nodes = []
	Paths.curMod = mod
	
	var mod_array = [mod,mod_node,Paths.texture('pack',false),songs_nodes,{}]
	for week in weeksFounded:
		var songArray: Dictionary = Paths.loadJson(weekFolder+'/'+week)
		
		var data = loadWeekProperties(songArray)
		mod_array[4][week] = data
		songs_nodes.append_array(data.songs)
		
	
	var index: int = 0
	for i in songs_nodes:
		var text = i[0]
		var icon = i[1]
		icon._position.y = SongsOffset * index
		text.position = Vector2(icon.pivot_offset.x*2,icon.pivot_offset.y - 20 + icon.position.y)
		mod_node.add_child(icon)
		mod_node.add_child(text)
		index += 1
	mods.append(mod_array)

func loadWeekProperties(week_data: Dictionary) -> Dictionary:
	var dif: String = week_data.get('difficulties','')
	if !dif: dif = 'easy, normal, hard'
		
	var dif_split: Array = StringUtils.split_no_space(dif,',')
	var data: Dictionary = {'songs': [],'difficulties': dif}
	
	for song in week_data.get('songs',[]):
		var alphabet = AlphabetText.new(song[0])
		var icon = Icon.new(song[1])
		var bg_color = song[2]
		var difficuty_data = {}
		
		for i in dif_split: difficuty_data[i] = []
		
		if song.size() >= 4 and song[3] is Dictionary:
			difficuty_data.merge(song[3],true)
		var song_data = [alphabet, icon, bg_color, difficuty_data]
		data.songs.append(song_data)
	return data

func loadWeeks():
	loadWeekFrom('assets/weeks')
	for i in Paths.getModsEnabled(): loadWeekFrom('mods/'+i+'/weeks')

func setSongSelected(selected: int = 0, play_sound: bool = true):
	var song_list = cur_mod_data[3]
	
	selected = wrapi(selected,0,song_list.size())
	scroll_index = selected
	curSongIndex = selected

	if cur_song_data:
		cur_song_data[0].modulate = UNSELECT_COLOR
		cur_song_data[1].modulate = UNSELECT_COLOR
	
	if song_list:
		cur_song_data = song_list[selected]
		
		cur_song_data[0].modulate = SELECT_COLOR
		cur_song_data[1].modulate = SELECT_COLOR
		
		cur_song_difficulties_data = cur_song_data[3]
		cur_song_difficulties = cur_song_difficulties_data.keys()
	
	if play_sound: FunkinGD.playSound(Paths.sound('scrollMenu'))

func load_game(
	song_name: StringName, 
	difficulty: StringName, 
	songFolder: StringName = &'', 
	json_name: StringName = &'', 
	audio_suffix: StringName = &''
):
	Global.swapTree(PlayState.new(song_name,difficulty),true)
	tweenStarted = true
	if !songFolder: return
	SongData.set_song_directory(song_name,difficulty,songFolder,json_name,audio_suffix)
	
func exit():
	set_process_input(false)
	bar_tween.kill()
	bar_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	bar_tween.parallel().tween_property(cur_week_node,'position:x',-ScreenUtils.screenWidth,0.5)
	bar_tween.parallel().tween_property(bar_top,'position:y',-BarSize,0.5)
	bar_tween.parallel().tween_property(bar_bottom,'position:y',ScreenUtils.screenHeight,0.5)
	bar_tween.finished.connect(func(): exiting.emit())
	

func setModSelected(banner_id: int = 0):
	FunkinGD.playSound(Paths.sound('scrollMenu'))
	if cur_week_node: remove_child(cur_week_node)
	
	banner_id = wrapi(banner_id,0,mods.size())
	cur_mod_data = mods[banner_id]
	
	Paths.curMod = cur_mod_data[0]
	
	cur_mod_text.text = cur_mod_data[0]
	
	cur_week_node = cur_mod_data[1]
	cur_week_node.modulate = Color.WHITE
	cur_week_node.position = Vector2.ZERO
	
	
	for i in cur_mod_data[3]:
		i[0].modulate = UNSELECT_COLOR
		i[1].modulate = UNSELECT_COLOR
	
	add_child(cur_week_node)
	move_child(cur_week_node,bar_top.get_index())
	
	var mod_image = cur_mod_data[2]
	cur_mod_image.texture = mod_image
	
	var image_size = mod_image.get_size().x
	cur_mod_text.position.x = image_size + 100
	modSelectRight.position.x = image_size
	setSongSelected(0,false)
	
	curMod = banner_id
	
	#Paths.curMod = banners[banner_id][1]

func createDifficulty():
	isSettingDifficulty = true
	if diffiTween: diffiTween.kill()
	diffiTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	diffiTween.tween_property(difficultySprite,'modulate:a',1.0,0.5)
	diffiTween.parallel().tween_property(cur_week_node,'modulate',Color.DARK_GRAY,0.5)
	
	
func setDifficulty(id: int = curDifficulty):
	if !cur_song_data: return
	if !isSettingDifficulty: createDifficulty()
	
	id = wrapi(id,0,cur_song_difficulties.size())
	
	difficulty = cur_song_difficulties[id]
	curDifficulty = id
	
	var texture = Paths.texture('menudifficulties/'+difficulty.to_lower())
	if texture: 
		difficultyText.text = ''
		_load_difficulty_image(texture)
	else:
		_set_difficulty_text(difficulty)
	
func _set_difficulty_text(text: String):
	difficultySprite.image.texture = null
	difficultyText.text = difficulty
	
	var offset = -difficultyText.width*difficultyText.scale.x + 180
	difficultyText.position.x = offset
	diffiSelectLeft.position.x = offset - 80
	diffiSelectRight.position.x = offset

func _load_difficulty_image(texture: Texture):
	if FileAccess.file_exists(texture.resource_name+'.xml'):
		difficultySprite._auto_resize_image = false
		difficultySprite.image.texture = texture
		difficultySprite.animation.addAnimByPrefix(&'anim','idle',24,true)
		difficultySprite.animation.play(&'anim')
	else:
		difficultySprite.animation.clearLibrary()
		difficultySprite._auto_resize_image = true
		difficultySprite.image.texture = texture
	
	var difWidth = difficultySprite.pivot_offset.x*2*difficultySprite.scale.x
	difficultySprite.position.x = ScreenUtils.screenWidth - difWidth - 100
	diffiSelectLeft.position.x = -50
	diffiSelectRight.position.x = difWidth + 10
func exitDifficulty():
	if diffiTween: diffiTween.kill()
	diffiTween = create_tween().parallel().set_ease(Tween.EASE_IN)
	diffiTween.tween_property(difficultySprite,'modulate:a',0,0.5)
	diffiTween.parallel().tween_property(cur_week_node,'modulate',Color.WHITE,0.4)
	isSettingDifficulty = false


func _process(_delta):
	if !cur_song_data: return
	var node = cur_song_data[1]
	cur_week_node.position = cur_week_node.position.lerp(Vector2(-node.position.x,-node.position.y + 320),0.1)
	


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.pressed: return
		var jump_index: int = 5 if Input.is_key_pressed(KEY_SHIFT) else 1
		
		if !isSettingDifficulty:
			match event.keycode:
				KEY_LEFT: setModSelected(curMod - 1)
				KEY_DOWN: setSongSelected(curSongIndex + jump_index)
				KEY_UP: setSongSelected(curSongIndex - jump_index)
				KEY_RIGHT: setModSelected(curMod + 1)
				KEY_ENTER: setDifficulty();
				KEY_BACKSPACE: exit()
		else:
			match event.keycode:
				KEY_LEFT: setDifficulty(curDifficulty - 1)
				KEY_RIGHT: setDifficulty(curDifficulty + 1)
				KEY_ENTER: startSong()
				KEY_BACKSPACE: exitDifficulty()
			
	elif event is InputEventMouseButton:
		if event.button_index == 1:
			
			if event.position.y < 120:
				if !event.pressed: return
				if MathUtils.is_pos_in_area(
				event.position, 
				modSelectLeft.global_position,
				modSelectLeft.image.region_rect.size*modSelectLeft.global_scale): 
					setModSelected(curMod-1);
				
				elif MathUtils.is_pos_in_area(
				event.position, 
				modSelectRight.global_position,
				modSelectRight.image.region_rect.size*modSelectRight.global_scale): 
					setModSelected(curMod+1);
			
			elif !isSettingDifficulty:
				is_scrolling = event.pressed
				scroll_index = -1
				
				if not event.pressed and click_select_song: setDifficulty()
				else: click_select_song = true
				return
			
			if !event.pressed: return
			
			if difficultySprite.image.texture and MathUtils.is_pos_in_area(
					event.position, 
					difficultySprite.global_position,
					difficultySprite.image.texture.get_size()): 
						startSong();
						return
			elif difficultyText.text and MathUtils.is_pos_in_area(
					event.position, 
					difficultyText.global_position,
					difficultyText.size): 
						startSong();
						return
			elif MathUtils.is_pos_in_area(
				event.position, 
				diffiSelectLeft.global_position,
				diffiSelectLeft.image.region_rect.size*diffiSelectLeft.global_scale): 
					setDifficulty(curDifficulty-1)
				
			elif MathUtils.is_pos_in_area(
				event.position, 
				diffiSelectRight.global_position,
				diffiSelectRight.image.region_rect.size*diffiSelectRight.global_scale): 
					setDifficulty(curDifficulty+1);
			
			else:
				click_select_song = false 
				exitDifficulty()
			return
		elif !event.pressed: return
		match event.button_index:
			4: setSongSelected(curSongIndex-1)
			5: setSongSelected(curSongIndex+1)
		
	elif event is InputEventMouseMotion:
		if !is_scrolling: return
		if scroll_index == -1: scroll_index = curSongIndex
		else: scroll_index -= event.relative.y/100
		
		var int_scroll = int(scroll_index)
		if int_scroll != curSongIndex:
			click_select_song = false
			setSongSelected(int_scroll)

func startSong():
	var song_name = cur_song_data[0].text
	var songJson = song_name
	var songFolder: String = ''
	var audio_suffix: String = ''
	
	var songData
	if cur_song_difficulties_data.get(difficulty):
		var data = cur_song_difficulties_data[difficulty]
		songJson = data[0]
		songFolder = ArrayUtils.get_array_index(data,1,'')
		audio_suffix = ArrayUtils.get_array_index(data,2,'')
		
		songData = Paths.data(songJson,'',songFolder)
	else: 
		songData = Paths.data(songJson,difficulty,songFolder)
	
	if songData: load_game(song_name,difficulty,songFolder,songJson,audio_suffix)
