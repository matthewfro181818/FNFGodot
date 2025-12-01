@tool
class_name Paths extends Object
const AnimationService = preload("res://source/general/animation/AnimationService.gd")
const game_name: String = "Friday Night Funkin'"

#region Device
static var curDevice: StringName = OS.get_name()
static var is_on_mobile: bool = curDevice == &'Android' or curDevice == &'iOs'
static var is_system_case_sensitive: bool = curDevice in [&'macOS',&'Linux',&"FreeBSD", &"NetBSD", &"OpenBSD", &"BSD"]
#endregion

#region Paths
static var exePath: StringName = get_exe_path()
static var _exe_length: int = exePath.length()
#endregion

#region Formats
const model_formats: PackedStringArray = ['.tres','.glb']
const audio_formats: PackedStringArray = ['.ogg','.wav']
#endregion

#region Mods
static var searchAllMods: bool: 
	set(value): searchAllMods = value; updateDirectories()

static var modsFounded: Dictionary[String,Dictionary] 
static var modsEnabled: PackedStringArray

static var enableMods: bool = true:
	set(value):
		enableMods = value
		updateDirectories()
		
static var curMod: String: 
	set(mod):
		if mod == curMod: return
		curMod = mod
		updateDirectories() 
static var mods_enabled: Dictionary = ClientPrefs.data.modsEnabled
static var extraDirectory: String: 
	set(dir):
		if extraDirectory == dir: return
		extraDirectory = dir
		updateDirectories()
#endregion

#region Dirs
const commomFolders: PackedStringArray = [
	"characters",
	"custom_events",
	"custom_notetypes",
	"data",
	"fonts",
	"images",
	"scripts",
	"shaders",
	"shared",
	"songs",
	"sounds",
	"stages",
	"weeks"
]

const icons_dirs: PackedStringArray = ['icons/','icons/icon-','winning_icons/','winning_icons/icon-']
const data_dirs: PackedStringArray = ['data/','data/songs/']
#endregion

#region Paths Cache
static var _files_directories_cache: Dictionary[StringName,String]
static var _dir_exists_cache: Dictionary[StringName,DirAccess]

static var _images_paths_cache: Dictionary[StringName,String]
static var _icons_paths_cache: Dictionary[StringName, String]
#endregion
#region Caches

static var textFiles: Dictionary
static var fontFiles: Dictionary

static var imagesCreated: Dictionary[String,Image]
static var imagesTextures: Dictionary[String,ImageTexture]

static var songsCreated: Dictionary[String,AudioStream]
static var soundsCreated: Dictionary[String,AudioStream]

static var musicCreated: Dictionary[String,AudioStream]
static var fontsCreated: Dictionary[String,FontFile] 
static var shadersCreated: Dictionary[String,Material]
static var shadersCodes: Dictionary[String,Shader]

static var jsonsLoaded: Dictionary[String,Dictionary]

static var modelsCreated: Dictionary[String,Object]

static var videosCreated: Dictionary[String,VideoStream]
#endregion

static var dirsToSearch: PackedStringArray 

static func get_exe_path() -> String:
	match curDevice:
		"Android": return '/storage/emulated/0/.FunkinGD'
		_: return OS.get_executable_path().get_base_dir()

static func _init() -> void:
	if is_on_mobile: OS.request_permissions()
	_detect_mods()
	modsEnabled = getRunningMods()
	updateDirectories()

static func detectFileFolder(path: StringName, case_sensive: bool = false) -> String:
	var path_cache = _files_directories_cache.get(path)
	if path_cache: return path_cache
	
	var path_string: String = String(path)
	if case_sensive: return _detect_file_folder_case_sensive(path)
	
	if FileAccess.file_exists(path_string): 
		_files_directories_cache[path] = path
		return path
	
	for d in dirsToSearch:
		var curPath: String = _get_file_path(d+path_string)
		if !curPath: continue
		_files_directories_cache[path] = curPath
		return curPath
	return ''

static func _get_file_path(path: String) -> String: return path if FileAccess.file_exists(path) else ''

static func _detect_file_folder_case_sensive(path: String) -> String:
	var file = path.get_file()
	var folder = path.get_base_dir()
	for d in dirsToSearch:
		var dir_path = d+folder
		var dir: DirAccess = get_dir(dir_path)
		if !dir: continue
		for i in dir.get_files():
			if not i == file: continue
			var full_path: String = dir_path+'/'+file
			_files_directories_cache[path] = full_path
			return full_path
	return ''

#region Path File Methods
static func loadFile(path: StringName) -> Resource:
	path = detectFileFolder(path)
	if !path: return null
	match path.get_extension():
		'png','jpg': return ImageTexture.create_from_image(Image.load_from_file(path))
		'svg': 
			var _image = Image.new()
			if _image.load_svg_from_string(path,2.0):return ImageTexture.create_from_image(_image)
			return null
	return ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)

static func font(path: StringName) -> Font:
	var font_file = fontFiles.get(path)
	if font_file: return font_file
	var fontPath = fontPath(path)
	if !fontPath: return ThemeDB.fallback_font
	font_file = FontFile.new()
	font_file.load_dynamic_font(fontPath)
	return font_file

static func image(path: StringName,imagesDirectory: bool = true, format: String = '.png') -> Image:
	path = imagePath(path,imagesDirectory,format)
	return _image_no_path_check(path) if path else null

static func _image_no_path_check(path_absolute: StringName) -> Image:
	if imagesCreated.has(path_absolute): return imagesCreated[path_absolute]
	var imageFile: Image = Image.load_from_file(path_absolute)
	imageFile.resource_name = path_absolute.get_basename()
	imagesCreated[path_absolute] = imageFile
	return imageFile

static func texture(path: StringName, imagesDirectory: bool = true, format: String = '.png') -> ImageTexture:
	path = imagePath(path,imagesDirectory,format)
	return _texture_no_check(path) if path else null

static func _texture_no_check(path_absolute: StringName) -> Texture:
	if imagesTextures.has(path_absolute): return imagesTextures[path_absolute]
	var image = _image_no_path_check(path_absolute)
	if !image: return null
	var texture = ImageTexture.create_from_image(image)
	texture.resource_name = image.resource_name
	imagesTextures[path_absolute] = texture
	return texture
	
static func icon(icon_name: String) -> Texture:
	var _icon_path = iconPath(icon_name)
	return _texture_no_check(_icon_path) if _icon_path else null

static func video(path: String) -> VideoStreamTheora: ##Get the [param video] path
	if !path.ends_with('.ogv'): path += '.ogv'
	if videosCreated.has(path): return videosCreated[path]
	
	var video_path = 'videos/'+path
	var path_absolute = detectFileFolder(video_path)
	if !path_absolute: return null
	
	var video = load(path_absolute)
	video.resource_name = getPath(video_path)
	videosCreated[path] = video
	return video

#region Audio File Methods
static func audio(path) -> AudioStream:
	if !path: return null
	if songsCreated.has(path): return songsCreated[path].duplicate()
	var stream_path = detectFileFolder(path)
	if !stream_path: return null
	
	var audio
	match stream_path.get_extension():
		'ogg': audio = AudioStreamOggVorbis.load_from_file(stream_path)
		'mp3': audio = AudioStreamMP3.load_from_file(stream_path)
		'wav': audio = AudioStreamWAV.load_from_file(stream_path)
		_: return null
	
	songsCreated[path] = audio
	return audio.duplicate()

static func sound(path: String) -> AudioStreamOggVorbis:
	if !path.ends_with('.ogg'): path += '.ogg'
	if songsCreated.has(path): return soundsCreated[path].duplicate()
	
	var songPath = detectFileFolder('sounds/'+path)
	if !songPath: return null
	var audio = AudioStreamOggVorbis.load_from_file(songPath)
	if !audio: return
	audio.resource_name = path
	soundsCreated[path] = audio
	return audio

static func music(path: String) -> AudioStreamOggVorbis:
	var _music = musicCreated.get(path)
	if _music: return _music
	
	_music = detectFileFolder('music/'+path+'.ogg')
	if !_music: return null
	_music = AudioStreamOggVorbis.load_from_file(_music)
	musicCreated[path] = _music
	return _music
#endregion
#endregion

#region Path Methods
static func imagePath(path: StringName, imagesDirectory: bool = true, format: String = '.png') -> String:
	var p = _images_paths_cache.get(path)
	if p: return p
	p = getPath(path,false)
	
	if !format.begins_with('.'): format = '.'+format
	
	if !p.ends_with(format): p += format
	if imagesDirectory and !p.begins_with('images/'): p = 'images/'+p
	p = detectFileFolder(p)
	_images_paths_cache[path] = p
	return p

static func text(path: String) -> String:
	if not path.ends_with('.txt'): path += '.txt'
	path = getPath(path,false)
	if textFiles.has(path): return textFiles[path]
	
	var textFile = detectFileFolder(path)
	if !textFile: return ''
	var file = FileAccess.get_file_as_string(textFile)
	textFiles[path] = file
	return file

static func fontPath(path: String) -> String:
	var fontPath = detectFileFolder('fonts/'+path)
	if !fontPath:
		fontPath = 'res://assets/fonts/'+path
		if not FileAccess.file_exists(fontPath): return ''
	return fontPath
	
static func stage(path: String)-> String: return detectFileFolder('stages/'+path+'.json')
static func event(path: String) -> String: return detectFileFolder('custom_events/'+path+'.gd')

static func characterPath(path: String) -> String:
	if !path.ends_with('.json'): path += '.json'
	return detectFileFolder('characters/'+path)

static func songPath(path: String):
	path = getPath(path)
	if !path.begins_with('songs/'): path = 'songs/'+path
	if !path.get_extension(): path += '.ogg'
	
	var paths: PackedStringArray = [path,path.to_lower()]
	
	for i in paths:
		var songPath = detectFileFolder(i)
		if songPath: return songPath
		
		songPath = detectFileFolder(i.replace(' ','-'))
		if songPath: return songPath
	return ''

static func data(json: String = '',prefix: String = '',folder: String = '') -> String:
	if file_exists(json): return json
	
	if json.ends_with(".json"): json = json.left(-5)
	
	if !folder: folder = json
	else: 
		folder = getPath(folder,false)
		if folder.begins_with('data/'): folder = folder.right(-5)
	
	var json_path = folder+'/'+json
	var paths_to_lock: PackedStringArray
	
	if prefix:
		if prefix.to_lower() == 'normal':  paths_to_lock.append(json_path+'.json')
		paths_to_lock.append_array([json_path+'-'+prefix+'.json',json_path+'-chart-'+prefix+'.json'])
	else: paths_to_lock.append(json_path+'.json')
	
	paths_to_lock.append(json_path+'-chart.json')
	
	var contain_space = json_path.contains(' ')
	
	for i in paths_to_lock:
		var path_found: String
		for d in data_dirs: path_found = detectFileFolder(d+i,!is_system_case_sensitive); if path_found: return path_found
		if contain_space:
			i = i.replace(' ','-')
			for d in data_dirs: path_found = detectFileFolder(d+i,!is_system_case_sensitive); if path_found: return path_found
		
		i = i.to_lower()
		for d in data_dirs: path_found = detectFileFolder(d+i); if path_found: return path_found
	return ''

static func iconPath(icon_name: StringName) -> StringName:
	var path = _icons_paths_cache.get(icon_name)
	if path: return path
	
	var icon_string = String(icon_name)
	for iconPath in icons_dirs: path = imagePath(iconPath+icon_string); if path: _icons_paths_cache[icon_name] = path; return path
	return ''

const replace_relative_path: PackedStringArray = ['assets/','mods/']
static func getRelativePath(path: String) -> String:
	path = getPath(path)
	for i in replace_relative_path: path = path.trim_prefix(i)
	return path

static func getPath(path: String, withMod: bool = true) -> String:
	if !path: return path
	if path.begins_with(exePath): path = path.right(-_exe_length-1)
	
	if withMod: return path.strip_edges()
	
	var find = path.find('/')
	var path_mod = path.left(find)
	if path_mod in modsFounded: path = path.right(-find-1)
	
	return path.strip_edges()
#endregion

#region File metods
static func file_exists(path: StringName) -> bool: return !!detectFileFolder(path)


static func get_dialog(dir: String = '') -> FileDialog:
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	if not dir.ends_with('/'): dir = dir+'/'
	
	dialog.current_path = (dir if dir_exists(dir) else exePath+'/')
	dialog.size = ScreenUtils.screenSize/1.5
	dialog.visible = true
	dialog.visibility_changed.connect(func():if !dialog.visible: dialog.queue_free())
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	return dialog


##Save a File. If [param external] is [code]true[/code], the file will be saved in the game's folder.
static func saveFile(json: Variant, path: String, extension: String = '.json') -> void:
	if json is Dictionary: json = JSON.stringify(json,'\t')
	else: json = str(json)
	if not path.ends_with(extension): path += extension
	var folder_acess = FileAccess.open(path, FileAccess.WRITE)
	if folder_acess: folder_acess.store_string(json)

static func clearFiles() -> void:
	soundsCreated.clear()
	imagesTextures.clear()
	imagesCreated.clear()
	clearLocalFiles()
	AnimationService._clearAnims()

static func clearLocalFiles() -> void:
	shadersCreated.clear()
	shadersCodes.clear()
	textFiles.clear()
	jsonsLoaded.clear()
#endregion

#region Shader Methods
const shader_formats: PackedStringArray = ['.frag','.gdshader']
static func shaderPath(path: String) -> String:
	if FileAccess.file_exists(path): return path
	if !path.begins_with('shaders/'): path = 'shaders/'+path
	
	for i in shader_formats:
		var path_to_share = path
		if !path.ends_with(i): path_to_share += i
		
		var shader_path = detectFileFolder(path_to_share)
		if shader_path: return shader_path
	return ''

static func loadShader(path: String) -> ShaderMaterial:
	var absolute_path = shaderPath(path)
	
	if !absolute_path: return null
	
	var material: ShaderMaterial = shadersCreated.get(absolute_path)
	if material: return material.duplicate()
	
	material = ShaderMaterial.new()
	material.shader = loadShaderCodeAbsolute(absolute_path)
	_set_shader_parameters_to_default(material) # When you try to get a parameter, it returns "null" until the parameter is set.
	shadersCreated[absolute_path] = material
	return material

static func _set_shader_parameters_to_default(material: ShaderMaterial):
	for i in material.shader.get_shader_uniform_list():
		material.set_shader_parameter(i.name,RenderingServer.shader_get_parameter_default(material.shader.get_rid(),i.name))
static func loadShaderCode(path: String) -> Shader: return loadShaderCodeAbsolute(shaderPath(path))

static func loadShaderCodeAbsolute(absolute_path: String) -> Shader:
	if !absolute_path: return
	
	var shader = shadersCodes.get(absolute_path)
	if shader: return shader
	
	shader = Shader.new()
	var shader_code = FileAccess.get_file_as_string(absolute_path) 
	shader.resource_name = absolute_path.get_file().get_basename()
	shader.code = ShaderUtils.fragToGd(shader_code) if absolute_path.ends_with('.frag') else shader_code
	shadersCodes[absolute_path] = shader
	return shader
#endregion

#region Dirs Methods
static func updateDirectories(): ##Update the folders that the [method detectFileFolder] will search the files.
	_clear_paths_cache()
	dirsToSearch.clear()
	
	var new_dirs: PackedStringArray
	
	var exe_dir = exePath+'/'
	if enableMods:
		var searchIn = modsFounded
		if !searchAllMods: searchIn = getRunningMods()
		
		for i in searchIn: new_dirs.append(exe_dir+'mods/'+i+'/')
		new_dirs.append(exe_dir+'mods/')
	
	new_dirs.append(exe_dir+'assets/')
	new_dirs.append(exe_dir)
	new_dirs.append('res://assets/')
	
	if extraDirectory: for i in new_dirs: dirsToSearch.append(i+extraDirectory+'/'); dirsToSearch.append(i)
	else: dirsToSearch.append_array(new_dirs)
	clearLocalFiles()

static func dir_exists(dir: String): return !!get_dir(dir)

static func get_dir(dir: String) -> DirAccess:
	if _dir_exists_cache.has(dir): return _dir_exists_cache[dir]
	var _dir = DirAccess.open(dir)
	_dir_exists_cache[dir] = _dir
	return _dir

static func _clear_paths_cache(): 
	_files_directories_cache.clear(); 
	_dir_exists_cache.clear()
	_images_paths_cache.clear()
	_icons_paths_cache.clear()
#endregion

#region get Files At Methods
static func getFilesAt(folder: String, return_folder: bool = false, filters: Variant = '', with_extension: bool = false) -> PackedStringArray:
	var f: PackedStringArray = PackedStringArray()
	if filters and filters is String: 
		if filters.begins_with('.'): filters = filters.right(-1)
		filters = PackedStringArray([filters])
	else: _check_filters(filters)
	
	if return_folder: for i in dirsToSearch: 
		f.append_array(_getFilesNoCheck(i+folder,return_folder,filters,with_extension))
	else: 
		for i in dirsToSearch: for s in _getFilesNoCheck(i+folder,return_folder,filters,with_extension): 
			if !s in f: f.append(s)
	return f

static func _check_filters(filters: PackedStringArray) -> PackedStringArray:
	if !filters: return filters
	var index: int = filters.size()
	while index: index -= 1; var s = filters[index]; if s.begins_with('.'): filters[index] = s.right(-1)
	return filters

static func getFilesAtAbsolute(
	folder: String, 
	return_folder: bool = false, 
	filters: PackedStringArray = PackedStringArray(), 
	with_extension: bool = false
) -> PackedStringArray:
	return _getFilesNoCheck(folder,return_folder,_check_filters(filters),with_extension)

static func _getFilesNoCheck(
	folder: String, 
	return_folder: bool = false, 
	filters: Variant = PackedStringArray(), 
	with_extension: bool = false
) -> PackedStringArray:
	var dir = get_dir(folder)
	if !dir: return PackedStringArray()
	
	var files: PackedStringArray = dir.get_files()
	if !filters and !return_folder and with_extension: return files
	
	var index = 0
	while index < files.size():
		var s = files[index]
		if filters and !(s.get_extension() in filters): 
			files.remove_at(index); 
			continue
		if !with_extension: s = s.get_basename();
		if return_folder: s = folder+'/'+s
		files[index] = s
		index += 1
	return files
#endregion

#region Mod Methods
static func _detect_mods() -> void:
	modsFounded.clear()
	for mods in DirAccess.get_directories_at(exePath+'/mods'):
		if commomFolders.has(mods): continue
		var modpack = {
			&"runsGlobally": false,
			&"name": mods,
			&"restart": false,
			&"description": "nothing"
		}
		
		#Check if the mod have "pack.json" data
		var _real_path = exePath+'/mods/'+mods+'/pack.json'
		if file_exists(_real_path): modpack.merge(_load_json_absolute(_real_path),true)
		if !modpack.get('name'): modpack.name = mods
		
		if !mods_enabled.has(mods): mods_enabled[mods] = true
		modsFounded[mods] = modpack

##Returns the mod folder in [param path]. [br]
##[b]Note:[/b] If don't found, will return [param default].
static func getModFolder(path: String, default: String = game_name) -> String:
	path = getPath(path)
	path = path.trim_prefix("assets/")
	path = path.trim_prefix("mods/")
	
	var bar_find = path.find('/')
	if bar_find != -1: path = path.left(bar_find)
	
	if !path or path in commomFolders: return default
	return path

static func getRunningMods(location: bool = false) -> PackedStringArray:
	var mods: PackedStringArray = []
	if location: 
		for mod in modsFounded: 
			if isModRunning(mod): mods.append(exePath+'/mods/'+mod+'/')
	else: for mod in modsFounded: if isModRunning(mod): mods.append(mod)
	return mods

static func isModRunning(mod_name: String) -> bool: 
	return mod_name == curMod or mods_enabled.get(mod_name,false) and modsFounded[mod_name].runsGlobally

static func isModEnabled(mod_name) -> bool: return mod_name == curMod or mods_enabled.get(mod_name,false)

static func getModsEnabled(location: bool = false) -> PackedStringArray:
	var mods: PackedStringArray = []
	for mod in modsFounded: if isModEnabled(mod): mods.append(mod if not location else exePath+'/mods/'+mod+'/')
	return mods
#endregion

#region Json Methods
##Returns the json file from [param path].[br]
##Obs: If [param duplicate], this will returns a duplicated json, 
##making it possible to modify without damaging the original json
static func loadJson(path: String) -> Dictionary:
	if not path.ends_with('.json'): path += '.json'
	var json = jsonsLoaded.get(path)
	if !json: json = loadJsonNoCache(path); jsonsLoaded[path] = json
	return json

static func loadJsonNoCache(path: String) -> Dictionary: return _load_json_absolute(detectFileFolder(path))

static func _load_json_absolute(absolute_path: String) -> Dictionary:
	if !absolute_path: return {}
	var json = JSON.parse_string(FileAccess.get_file_as_string(absolute_path))
	return {} if json == null else json
#endregion

#region Data Methods
static func character(path: String) -> Dictionary[StringName,Variant]:
	var file = characterPath(path)
	if !file: return {}
	
	var json = DictUtils.getDictTyped(loadJsonNoCache(file),TYPE_STRING_NAME)
	json.merge(Character._convert_psych_to_original(json),true)
	return json
#endregion
