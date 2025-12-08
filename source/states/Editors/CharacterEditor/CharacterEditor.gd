extends Node
const Bar = preload("res://source/objects/UI/Bar.gd")
const Icon = preload("res://source/objects/UI/Icon.gd")
const AnimClass = preload("res://source/general/animation/AnimationService.gd")

static var back_to: Variant

var charactersFound: PackedStringArray
var characterData: Dictionary = Character.getCharacterBaseData()
var animData: Dictionary[StringName,Variant] = Character.getAnimBaseData()

var isMovingCamera: bool

static var curCharacter: StringName

@onready var character_node: Character = Character.create_from_name(curCharacter)

var character_ghost: Character

var cur_anim: StringName: set = selectAnim
var cur_offset: Vector2:
	set(value):
		cur_offset = value
		animation_offset[0].set_value_no_signal(value.x)
		animation_offset[1].set_value_no_signal(value.y)
		character_node.set_offset_from_anim(cur_anim)

var cur_indices: String
var cur_scale: float = 1.0:
	set(value):
		cur_scale = value
		json_scale.value = value
		if character_node:
			character_node.scale = Vector2(value,value)
			charJson.scale = value

var cur_frame_rate: float = 24.0
var cur_looped: bool

var charJson: Dictionary


var cur_image: StringName: set = setCharacterImage
const singAnimations = [&'singLEFT',&'singDOWN',&'singUP',&'singRIGHT']
const keys: PackedInt32Array = [KEY_D,KEY_F,KEY_J,KEY_K]
var _character_path: String = Paths.exePath+'/'

@onready var bar = Bar.new('healthBar')
@onready var icon = Icon.new()

@onready var characterList := $CharacterData/CharacterList
@onready var animationList := $"TabContainer/Animation Data/Container/Current Animation/Data/AnimationList"
@onready var animationGhost := $"CharacterData/AnimationGhost"
@onready var prefixList := $"TabContainer/Animation Data/Container/Current Animation/Data/PrefixList"
@onready var prefixListPop: PopupMenu = prefixList.get_popup()

#Animation Data
@onready var animation_asset := $"TabContainer/Animation Data/Container/Current Animation/Data/AssetPath"

@onready var animation_offset = [
	$"TabContainer/Animation Data/Container/Current Animation/Data/anim_offset_x",
	$"TabContainer/Animation Data/Container/Current Animation/Data/anim_offset_y"
]
@onready var new_character_tab = $"CharacterData/New Character Tab"
@onready var new_character_image := $"CharacterData/New Character Tab/Panel/Image"
@onready var new_character_animation_type := $"CharacterData/New Character Tab/Panel/AnimationType"
@onready var new_character_name = $"CharacterData/New Character Tab/Panel/CharacterName"

@onready var animation_prefix := $"TabContainer/Animation Data/Container/Current Animation/Data/Prefix"
@onready var animation_indices := $"TabContainer/Animation Data/Container/Current Animation/Data/Indices"
@onready var animation_loop := $"TabContainer/Animation Data/Container/Current Animation/Data/Looped"
@onready var animation_fps := $"TabContainer/Animation Data/Container/Current Animation/Data/FrameRate"
@onready var animation_insert_name := $"TabContainer/Animation Data/Container/Current Animation/Data/Insert Animation Name"

@onready var animation_follow_flip := $"TabContainer/Animation Data/Container/Offsets/Data/Offset Follow Flip"
@onready var animation_follow_scale := $"TabContainer/Animation Data/Container/Offsets/Data/Offset Follow Scale"
@onready var animation_sing_follow_flip := $"TabContainer/Animation Data/Container/Sing_Dance/Data/Sing Animation Follow Flip"

@onready var animationGhostPop: PopupMenu = animationGhost.get_popup()
@onready var animationListPop: PopupMenu = animationList.get_popup()
@onready var characterPop: PopupMenu = characterList.get_popup()
@onready var camera := $BG
var camera_zoom: float = 1.0
var camera_y_limit = -300

#Json Data
@onready var json_scale := $"TabContainer/Json Data/Container/Image/Data/scale"
@onready var playable_character := $"CharacterData/Playable Character"
@onready var gf_character := $"CharacterData/GF Character"
@onready var json_flip := $"TabContainer/Json Data/Container/Image/Data/FlipX"
@onready var json_antialiasing := $"TabContainer/Json Data/Container/Image/Data/antialiasing"
@onready var json_image_file := $"TabContainer/Json Data/Container/Image/Data/image_file"

@onready var json_position = [
	$"TabContainer/Json Data/Container/Offstes/Data/position_x",
	$"TabContainer/Json Data/Container/Offstes/Data/position_y"
]
@onready var json_origin_offset = [
	$"TabContainer/Json Data/Container/Offstes/Data/Origin X",
	$"TabContainer/Json Data/Container/Offstes/Data/Origin Y"
]

#Gameplay Options
@onready var gameplay_healtbar_color := $"TabContainer/Json Data/Container/HealthBar/HealthBar/HealthColor"

@onready var gameplay_camera = [
	$"TabContainer/Json Data/Container/Offstes/Data/Camera X", 
	$"TabContainer/Json Data/Container/Offstes/Data/Camera Y"
]
@onready var gameplay_icon := $"TabContainer/Json Data/Container/HealthBar/HealthBar/HealthIcon"
@onready var gameplay_is_pixel_icon := $"TabContainer/Json Data/Container/HealthBar/HealthBar/isPixelIcon"
@onready var gameplay_can_scale_icon := $"TabContainer/Json Data/Container/HealthBar/HealthBar/scaleIcon"

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	character_node.loadCharacter(curCharacter)
	charJson = character_node.json
	camera.add_child(character_node)
	updateCharacterData()
	
	add_child(bar)
	add_child(icon)
	
	bar.position = Vector2(50,670)
	bar.progress = 1
	icon._position = Vector2(20,600)
	
	
	characterPop.index_pressed.connect(func(i):
		var character = characterPop.get_item_text(i)
		if character == curCharacter: return
		character_node.loadCharacter(character)
		updateCharacterData()
	)
	
	animationListPop.index_pressed.connect(func(i): cur_anim = animationListPop.get_item_text(i))
	
	animationGhostPop.index_pressed.connect(func(i): 
		var anim = animationGhostPop.get_item_text(i)
		createGhost(anim)
		animationGhost.text = anim
	)
	
	#Character List
	characterPop.min_size = Vector2(250,0)
	
	prefixListPop.index_pressed.connect(
		func(i): 
			animation_prefix.text = prefixListPop.get_item_text(i); animation_prefix.text_submitted.emit(animation_prefix.text)
	)
	$BG/Ground.texture =  Paths.texture('editors/character_editor/ground')
	camera_y_limit = $BG/Ground.texture.get_size().y*$BG/Ground.scale.y + 300


func exit():
	if !back_to: return
	Global.doTransition().finished.connect(Global.swapTree.bind(back_to,false))
	

func createGhost(animation: StringName):
	if character_ghost: character_ghost.queue_free()
	if !animation: return
	
	character_ghost = Character.new()
	character_ghost.loadCharacterFromJson(charJson)
	character_ghost.danceAfterHold = false
	character_ghost.danceOnAnimEnd = false
	character_ghost._position = character_node._position
	camera.add_child(character_ghost)
	camera.move_child(character_ghost,character_node.get_index())
	character_ghost.modulate.a = 0.5
	character_ghost.animation.play(animation,true)
	
	
func loadCharacter(json: StringName, isPlayer: bool = json.begins_with('bf')) -> Character:
	character_node.loadCharacter(json)
	character_node.danceAfterHold = false
	character_node.danceOnAnimEnd = false
	character_node.isPlayer = isPlayer
	return character_node

	
#region Animatiom Methods
func selectAnim(anim_name: String):
	cur_anim = anim_name
	character_node.animation.play(cur_anim)
	for i in charJson.animations: if i.name == anim_name: animData = i; break
	animationList.text = cur_anim
	
	animation_insert_name.placeholder_text = cur_anim
	animation_asset.text = animData.get('assetPath','')
	updateAnimData()
	
func addCharacterAnimation(anim):
	if character_node.animationsArray.has(anim): return
	var newAnimData = Character.getAnimBaseData()
	newAnimData.anim = anim
	charJson.animations.append(newAnimData)
	animationListPop.add_item(anim)
	animationGhostPop.add_item(anim)
	cur_anim = anim

func set_anim_data_value(value: Variant, property: StringName): animData[property] = value
func set_character_animation_value(value: Variant, property: StringName): character_node.animation.curAnim[property] = value; 
func set_json_value(value: Variant, property: StringName): charJson[property] = value
func set_character_value(value: Variant, property: StringName): character_node[property] = value;

func add_anim_offset():
	character_node.addAnimOffset(cur_anim,cur_offset.x,cur_offset.y)
	replayCharAnim()

func get_animation_indices_str(indices = animData.get('frameIndices',[])):
	var string = ''
	for i in indices: string += String.num_int64(i)+', '
	return string.left(-2)

func updateAnimData():
	animationList.text = cur_anim
	cur_offset = character_node._animOffsets.get(cur_anim,Vector2.ZERO)
	cur_indices = get_animation_indices_str()
	cur_looped = animData.get('loop',false)
	animation_prefix.text = animData.get('prefix','')
	animation_indices.text = cur_indices
	animation_indices.placeholder_text = get_animation_indices_str(range(character_node.animation.curAnim.maxFrames))
	animation_fps.set_value_no_signal(animData.get(&'fps',24.0))
	animation_loop.button_pressed = cur_looped

func updatePrefixList():
	prefixListPop.clear()
	if !character_node._images: return
	
	if character_node._images.size() == 1:
		for i in AnimClass.getPrefixList(character_node.animation._animFile): prefixListPop.add_item(i)
	else:
		for i in character_node._images.values():
			var prefix_list = AnimClass.getPrefixList(AnimClass.findAnimFile(i.resource_name))
			if !prefix_list: continue
			prefixListPop.add_separator(i.resource_name.get_file())
			for p in prefix_list: prefixListPop.add_item(p)
	
func updateCharacterData():
	character_node._position = Vector2(640,0) + character_node.positionArray
	curCharacter = character_node.curCharacter
	character_node.isPlayer = curCharacter.begins_with('bf')
	character_node.isGF = curCharacter.begins_with('gf')
	characterList.text = curCharacter
	animation_asset.placeholder_text = charJson.assetPath
	playable_character.set_pressed_no_signal(character_node.isPlayer)
	gf_character.set_pressed_no_signal(character_node.isGF)
	updatePrefixList()
	updateDataInfo()
	updateAnimationList()
	cur_anim = character_node.animation.current_animation
	_character_path = Paths.characterPath(curCharacter).get_base_dir()
	
func updateDataInfo():
	icon.reloadIconFromCharacterJson(charJson)
	
	cur_scale = charJson.scale
	updateAnimationList()
	updateCameraPosition()
	
	animation_follow_flip.set_pressed_no_signal(character_node.offset_follow_flip)
	animation_follow_scale.set_pressed_no_signal(character_node.offset_follow_scale)
	animation_sing_follow_flip.set_pressed_no_signal(charJson.sing_follow_flip)
	
	json_flip.set_pressed_no_signal(charJson.flipX)
	
	json_antialiasing.set_pressed_no_signal(character_node.antialiasing)
	json_image_file.text = charJson.assetPath
	
	json_position[0].set_value_no_signal(charJson.offsets[0])
	json_position[1].set_value_no_signal(charJson.offsets[1])
	
	json_origin_offset[0].value = 0
	json_origin_offset[1].value = 0
	
	gameplay_healtbar_color.color = character_node.healthBarColors
	updateBarColor()
	
	gameplay_camera[0].value = character_node.cameraPosition[0]
	gameplay_camera[1].value = character_node.cameraPosition[1]
	
	var iconData = charJson.get('healthIcon',{})
	gameplay_icon.text = character_node.healthIcon
	gameplay_is_pixel_icon.set_pressed_no_signal(iconData.get('isPixel',false))

	gameplay_can_scale_icon.set_pressed_no_signal(iconData.get('canScale',false))

func updateBarColor(): bar.set_colors(character_node.healthBarColors)
	
func updateCameraPosition():
	$BG/Marker_Camera.position = character_node.getCameraPosition()
	$BG/Marker_Origin.position = character_node.getMidpoint()

func zoomBg(add: float):
	camera_zoom = clamp(camera_zoom+add,0.45,2)
	camera.scale = Vector2(camera_zoom,camera_zoom)
	updateBgPosition()
	
func updateBgPosition():
	camera.scale = camera.scale.clamp(Vector2(0.45,0.45),Vector2(2,2))
	camera.position.y = clampf(camera.position.y,-700,700)

func reloadCharacterAnim():
	character_node.addCharacterAnimation(
		cur_anim,
		{
			&'prefix': animation_prefix.text,
			&'fps': cur_frame_rate,
			&'looped': character_node.animation.curAnim.looped,
			&'indices': cur_indices
		}
	)

func replayCharAnim(): character_node.animation.play(cur_anim,true)

func _input(event):
	if isMovingCamera and event is InputEventMouseMotion and event.button_mask == 1:
		camera.position += event.relative
		updateBgPosition()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			for i in range(keys.size()):
				if event.keycode == keys[i]:
					character_node.animation.play(singAnimations[i],true)
					return
			
			match event.keycode:
				KEY_ESCAPE: exit()
				KEY_SPACE: replayCharAnim()
				KEY_LEFT: animation_offset[0].addValue()
				KEY_UP: animation_offset[1].addValue()
				KEY_DOWN: animation_offset[1].subValue()
				KEY_RIGHT: animation_offset[0].subValue()

func _unhandled_input(event):
	if !event is InputEventMouseButton: return
	if event.button_index == 1: isMovingCamera = event.pressed;
	if !event.pressed: return

	match event.button_index:
		5: zoomBg(-0.05)
		4: zoomBg(0.05)

func updateAnimationList():
	animationListPop.clear()
	animationGhostPop.clear()
	animationGhostPop.add_item('')
	for i in charJson.animations:
		animationListPop.add_item(i.name)
		animationGhostPop.add_item(i.name)

#region Animation Signals
func _on_anim_offset_x_value_changed(value: float) -> void:
	cur_offset.x = value
	animData.offsets[0] = value
	add_anim_offset()
	
func _on_anim_offset_y_value_changed(value: float) -> void:
	cur_offset.y = value
	animData.offsets[1] = value
	add_anim_offset()


func _on_reload_character_button_up() -> void: character_node.loadCharacterFromJson(Paths.character(curCharacter))

func _on_flip_sing_direction_toggled(toggled_on: bool) -> void:
	charJson.sing_follow_flip = toggled_on
	character_node.reloadAnims()
	character_node.animation.play(cur_anim)

func _on_save_character_button_up() -> void:
	var folders = Paths.get_dialog(_character_path)
	folders.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	folders.current_file = character_node.curCharacter+'.json'
	folders.add_filter('*.json')
	folders.visible = true
	add_child(folders)
	folders.file_selected.connect(func(dir):
		if not dir in charactersFound: charactersFound.append(dir)
		Paths.saveFile(charJson,dir)
		folders.queue_free()
	)


func _on_load_character_from_file_button_up() -> void:
	var dialog = Paths.get_dialog(_character_path)
	dialog.add_filter('*.json')
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.visible = true
	dialog.title = 'Load Character'
	add_child(dialog)
	dialog.file_selected.connect(func(file):
		Paths.curMod = Paths.getModFolder(file)
		character_node.loadCharacter(file.get_file().get_basename())
		updateCharacterData()
	)



func _on_indices_text_submitted(new_text: String) -> void:
	cur_indices = new_text
	animData.frameIndices = character_node.animation.get_indices_by_str(new_text)
	reloadCharacterAnim()

func _on_loop_from_value_changed(value: int) -> void:
	animData.loop_frame = value
	character_node.animation.getAnimData(cur_anim).loop_frame = value
	character_node.animation.curAnim.loop_frame = value

func _on_offset_follow_flip_toggled(toggled_on: bool) -> void:
	charJson.offset_follow_flip = toggled_on
	character_node.offset_follow_flip = toggled_on
	replayCharAnim()


func _on_offset_follow_scale_toggled(toggled_on: bool) -> void:
	charJson.offset_follow_scale = toggled_on
	character_node.offset_follow_scale = toggled_on
	replayCharAnim()


func _on_health_color_color_changed(color: Color) -> void:
	character_node.healthBarColors = color
	charJson.healthbar_colors = [color.r*255.0,color.g*255.0,color.b*255.0]
	updateBarColor()
	
func _on_health_icon_text_submitted(new_text: String) -> void:
	gameplay_icon.release_focus()
	if charJson.healthIcon.id == new_text: return
	
	charJson.healthIcon.id = new_text
	charJson.healthIcon.isPixel = new_text.ends_with('-pixel')
	character_node.healthIcon = new_text
	icon.changeIcon(new_text)

func _on_is_pixel_icon_toggled(toggled_on: bool) -> void:
	icon.set_pixel(toggled_on, charJson.healthIcon.get(&'canScale',false))
	if !toggled_on: charJson.healthIcon.erase(&'isPixel')
	else: charJson.healthIcon.isPixel = true

func _on_scale_icon_toggled(toggled_on: bool) -> void:
	icon.set_pixel(charJson.healthIcon.get(&'isPixel',false),toggled_on)
	if !toggled_on: charJson.healthIcon.erase(&'canScale')
	else: charJson.healthIcon.canScale = true
	

func _on_asset_path_text_submitted(new_text: String) -> void:
	animation_asset.release_focus()
	if new_text == animData.get('assetPath',''): return
	animData.assetPath = new_text
	reloadCharacterAnim()
	
func _on_add_animation_button_up() -> void:
	addCharacterAnimation(animation_insert_name.text)

func _on_remove_animation_button_up() -> void:
	character_node.animation.removeAnimation(cur_anim)
	for i in charJson.animations:
		if i.name == cur_anim: charJson.animations.erase(i); break
	if !animationGhostPop.item_count: cur_anim = ''
	else: cur_anim = animationGhostPop.get_item_text(1)
	updateAnimationList()

#endregion


#region Character Signals

#endregion
#region Json Data Signals
func _on_scale_value_changed(value) -> void:
	character_node.scale = Vector2(value,value)
	charJson.scale = value
	updateCameraPosition()

func _on_antialiasing_toggled(toggled_on: bool) -> void:
	charJson.isPixel = !toggled_on
	character_node.antialiasing = toggled_on

func setCharacterImage(new_image: String):
	character_node.setCharacterImage(new_image)
	cur_image = charJson.assetPath
	json_image_file.release_focus()
	updatePrefixList()
	updateDataInfo()
	
func _on_load_image_button_down() -> void:
	var folder = Paths.get_dialog()
	folder.add_filter("*.png")
	folder.add_filter("*.jpg")
	folder.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	add_child(folder)
	folder.visible = true
	folder.file_selected.connect(func(dir): cur_image = dir)
	folder.files_selected.connect(func(dir: PackedStringArray):
		var image = dir[0]
		dir.remove_at(0)
		for i in dir: image += '/'+i
		cur_image = image
	)
func _on_position_x_value_changed(value: float) -> void:
	character_node._position.x += value - charJson.offsets[0]
	charJson.offsets[0] = value
	updateCameraPosition()
	
func _on_position_y_value_changed(value: float) -> void:
	character_node._position.y += value - charJson.offsets[1]
	charJson.offsets[1] = value
	updateCameraPosition()

func _on_camera_x_value_changed(value: float) -> void:
	charJson.camera_position[0] = value
	character_node.cameraPosition[0] = value
	updateCameraPosition()

func _on_camera_y_value_changed(value: float) -> void:
	charJson.camera_position[1] = value
	character_node.cameraPosition[1] = value
	updateCameraPosition()
	
func _on_flip_x_toggled(toggled_on: bool) -> void:
	character_node.flipX = toggled_on != character_node.isPlayer
	charJson.flipX = toggled_on
	
	if animation_sing_follow_flip.button_pressed: character_node.reloadAnims()
	else: replayCharAnim()
	
func _on_origin_x_value_changed(value: float) -> void:
	character_node.pivot_offset.x += value - charJson.origin_offset[0]
	charJson.origin_offset[0] = value
	updateCameraPosition()

func _on_origin_y_value_changed(value: float) -> void:
	character_node.pivot_offset.y += value - charJson.origin_offset[1]
	charJson.origin_offset[1] = value
	updateCameraPosition()
#endregion


func _on_create_new_character_button_down() -> void:
	#Check if the character name already exists
	var char_name = new_character_name.text
	for i in charactersFound:
		if i.get_file() == char_name and Paths.getModFolder(i,'') == Paths.curMod:
			Global.show_label_warning('Error: Character Name already exists!')
			return
	
	var json = Character.getCharacterBaseData()
	
	
	json.assetPath = new_character_image.text
	characterList.text = char_name
	
	Paths.curMod = Paths.getModFolder(new_character_image.text)
	character_node.loadCharacterFromJson(json)
	character_node.curCharacter = char_name
	charJson = json
	updateCharacterData()
	
	new_character_tab.visible = false

func _on_select_new_character_image_from_file_button_down() -> void:
	var dialog = Paths.get_dialog()
	match new_character_animation_type.text:
		'Sprite Map': dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		_:
			dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE 
			dialog.add_filter('*.png')
			dialog.add_filter('*.jpg')
	dialog.file_selected.connect(func(file): new_character_image.text = Paths.getPath(file))
	dialog.dir_selected.connect(func(dir): new_character_image.text = Paths.getPath(dir))
	add_child(dialog)


func _on_new_character_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed: new_character_tab.hide()
