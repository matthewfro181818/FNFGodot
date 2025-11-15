@icon("res://icons/icon.svg")
extends FunkinSprite

var animated: bool
var hasWinningIcon: bool

var default_scale: Vector2 = Vector2.ONE
var scale_lerp: bool = true
	
var beat_value: Vector2 = Vector2(0.2,0.2)
var scale_lerp_time: float = 10.0

var health_offset: float

var icon_pivot_rotation: float 
var isPixel: bool

func _init(texture: String = &''):super._init(true); if texture: changeIcon(texture); name = 'Icon'

func changeIcon(icon: String = "icon-face"):
	if animated: animation.clearLibrary()
	
	image.texture = Paths.icon(icon)
	if !image.texture: image.texture = Paths.icon('icon-face'); if !image.texture: return
	
	
	hasWinningIcon = imageFile.get_base_dir().ends_with("winning_icons")


	animated = FileAccess.file_exists(image.texture.resource_name+'.xml')
	
	if animated:
		animation.addAnimByPrefix(&'normal',&'Default',24,true)
		animation.addAnimByPrefix(&'losing',&'Losing',24,true)
		animation.addAnimByPrefix(&"winning",&'Winning',24,true)
		
	elif hasWinningIcon:
		setGraphicSize(imageSize.x/3.0,imageSize.y)
		animation.addFrameAnim(&'normal',[0])
		animation.addFrameAnim(&'losing',[1])
		animation.addFrameAnim(&'winning',[2])
		
	else:
		setGraphicSize(imageSize.x/2.0,imageSize.y)
		animation.addFrameAnim(&'normal',[0])
		animation.addFrameAnim(&'losing',[1])
	

func reloadIconFromCharacterJson(json: Dictionary): 
	json = json.get('healthIcon',{})
	changeIcon(json.get('id','icon-face')); set_pixel(json.get('isPixel',false),json.get('canScale',false))
	
func _process(delta: float) -> void:
	if scale_lerp: scale = scale.lerp(default_scale,delta*scale_lerp_time)
	super._process(delta)
	

func set_pixel(is_pixel: bool = false, scale_if_pixel: bool = false):
	if is_pixel == isPixel: return
	antialiasing = !is_pixel
	if scale_if_pixel and is_pixel: scale = Vector2(4.5,4.5); beat_value = Vector2(0.8,0.8)
	else: scale = Vector2.ONE; beat_value = Vector2(0.2,0.2)
	isPixel = is_pixel
	default_scale = scale
	
func set_pivot_offset(pivot: Vector2) -> void:
	super.set_pivot_offset(pivot) 
	health_offset = pivot_offset.x/1000.0
