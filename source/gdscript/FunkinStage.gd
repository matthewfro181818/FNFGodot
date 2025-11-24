const DANCE_ANIMATIONS = ['danceLeft','danceRight','idle']

static var charactersGroup: Dictionary = {}
static var dance_sprites: Array = []
static var danced: bool = false

static var _beat_connect: bool = false
static var json: Dictionary = getStageBase()
static var is_vslice_stage: bool = true
##Load Sprites from the stage json.[br]
##[b]OBS:[/b] Is recommended to [u]call this function after the characters group are added in PlayState.[/u][br][codeblock]
##loadSprites(
##{"props":
##	   [
##       {
##         "zIndex": 10,
##         "danceEvery": 0,
##         "position": [-220, -80],
##         "scale": [0.9, 0.9],
##         "name": "limoSunset",
##         "animType": "sparrow",
##         "isPixel": false,
##         "scroll": [0.1, 0.1],
##         "assetPath": "limo/erect/limoSunset",
##         "animations": []
##       }
##    ]
##)[/codeblock]
##[b]Tip:[/b] The sprites created using this function can be acessed by his [param name] from functions like 
##[method FunkinGD.getProperty] and [method FunkinGD.setProperty].


static func loadSprites(stage_json: Dictionary = json) -> void:
	if !stage_json: return
	var sprites: Array = []
	for data in stage_json.get('props',[]):
		var name = data.get('name','')
		var image = data.get('assetPath')
		var position = data.get('position',[0,0])
		var scale = data.get('scale',[1,1])
		var scroll = data.get('scroll',[1,1])
		
		
		var sprite: FunkinSprite
		if image.begins_with("#"):
			sprite = FunkinGD.makeSprite(name,null,position[0],position[1])
			sprite.image.modulate = Color(image)
			
		elif data.get('animations'):
			sprite = FunkinGD.makeAnimatedSprite(name,image,position[0],position[1])
			
			for anim in data.animations:
				var anim_name = anim.get('name','')
				sprite.animation.addAnimByPrefix(
					anim_name,
					anim.get('prefix',''),
					anim.get('frameRate',24),
					anim.get('looped',false),
					anim.get('frameIndices',[])
				)
				
				sprite.addAnimOffset(anim_name,anim.get('offsets',Vector2.ZERO))
			
			var startAnim = data.get('startingAnimation')
			if startAnim: sprite.animation.play(startAnim,true)

			var danceEvery = data.get('danceEvery')
			if danceEvery:
				dance_sprites.append(
					[
						danceEvery,
						sprite,
						sprite.animation.has_any_animations(['danceLeft','danceRight'])
					]
				)
				if !_beat_connect:
					Conductor.beat_hit.connect(onBeatHit)
					_beat_connect = true
		else:
			sprite = FunkinGD.makeSprite(name,image,position[0],position[1])
		
		if sprite is FunkinSprite:
			sprite.setGraphicScale(Vector2(scale[0],scale[1]))
			sprite.scrollFactor = Vector2(scroll[0],scroll[1])
		else: sprite.scale = Vector2(scale[0],scale[1])
		sprite.antialiasing = !data.get('isPixel')
		sprite.modulate.a = data.get('alpha',1.0)
		sprites.append([data.get('zIndex',0),sprite])
	
	var front_index: int = 0
	var got_first_index: bool
	
	for chars in stage_json.get('characters',{}):
		if !charactersGroup.has(chars): continue
		
		var index = stage_json.characters[chars].get('zIndex',1)
		
		if !got_first_index:
			front_index = index
			got_first_index = true
		else:
			front_index = mini(index,front_index)
		sprites.append([index,charactersGroup[chars]])
	
	if !sprites: return
	
	sprites.sort_custom(func(a,b): return a[0] <= b[0])
	
	for i in sprites: FunkinGD.addSprite(i[1],i[0] >= front_index)
	
static func onBeatHit() -> void:
	danced = !danced
	var anim = DANCE_ANIMATIONS[int(danced)]
	for i in dance_sprites:
		var sprite = i[1]
		if sprite and fmod(Conductor.beat,i[0]) == 0:
			sprite.animation.play(anim if i[2] else DANCE_ANIMATIONS[2])

static func loadStage(stage: String) -> Dictionary:
	var stage_path = Paths.stage(stage)
	json = getStageBase()
	json.merge(convert_old_to_new(Paths.loadJson(stage_path)),true)
	
	#Remove ".json" from the end of the string
	stage_path = stage_path.left(-5)
	
	Paths.extraDirectory = json.get('directory','')
	json.path = stage
	return json


static func convert_old_to_new(json: Dictionary):
	var new_json: Dictionary = getStageBase()
	
	for i in json:
		if new_json.has(i):
			new_json[i] = json[i]
	
	
	if json.has('camera_girlfriend'):
		new_json.characters.gf.cameraOffsets = json.camera_girlfriend

	if json.has('camera_boyfriend'):
		new_json.characters.bf.cameraOffsets = json.camera_boyfriend
	else:
		new_json.characters.bf.cameraOffsets[0] += 100
		new_json.characters.bf.cameraOffsets[1] += 100
		
	if json.has('camera_opponent'):
		new_json.characters.dad.cameraOffsets = json.camera_opponent
	else:
		new_json.characters.dad.cameraOffsets[0] -= 150
		new_json.characters.dad.cameraOffsets[1] += 100
	
	
	var chars = new_json.characters
	for i in chars:
		var pos = chars[i].position
		if i == 'gf':
			pos[0] -= 280
			pos[1] -= 700
		else:
			pos[0] -= 180
			pos[1] -= 750
		
	new_json.cameraZoom = json.get('defaultZoom',new_json.cameraZoom)
	new_json.cameraSpeed = json.get('camera_speed',new_json.cameraSpeed)
	new_json.characters.bf.position = json.get('boyfriend',new_json.characters.bf.position)
	new_json.characters.dad.position = json.get('opponent',new_json.characters.dad.position)
	new_json.characters.gf.position = json.get('girlfriend',new_json.characters.gf.position)
	return new_json

static func clear():
	danced = false
	dance_sprites.clear()
	charactersGroup.clear()
	if _beat_connect:
		Conductor.beat_hit.disconnect(onBeatHit)
	
static func getPsychStageBase() -> Dictionary:
	return {
		"directory": "",
		"isPixelStage": false,
		"hide_girlfriend": false,
		"hide_boyfriend": false,
		"hide_opponent": false,
		"defaultZoom": 1.0,
		"camera_speed": 1.0,
		"boyfriend": [770.0,100.0],
		"opponent": [100.0,100.0],
		"girlfriend": [0.0,90.0],
		"camera_boyfriend": [0.0,0.0],
		"camera_opponent": [0.0,0.0],
		"camera_girlfriend": [0.0,0.0],
		'path': ''
	}

static func getStageBase() -> Dictionary:
	return {
		"cameraZoom": 1.0,
		"cameraSpeed": 1.0,
		"props": [],
		"hide_girlfriend": false,
		"isPixelStage": false,
		"characters": {
			"bf": {
				"zIndex": 2,
				"position": [1297.5, 871],
				"cameraOffsets": [-100, -100]
				},
				
			"gf": { 
				"zIndex": 0, 
				"position": [808.5, 854], 
				"cameraOffsets": [0, 0]
				},
				
			"dad": {
				"zIndex": 1,
				"position": [290.5, 869],
				"cameraOffsets": [150, -100]
				}
		},
		"directory": ""
	}
