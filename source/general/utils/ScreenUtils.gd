class_name ScreenUtils

static var screenWidth: float:
	get(): return screenSize.x
static var screenHeight: float:
	get(): return screenSize.y

static var screenSize: Vector2 = DisplayServer.window_get_size()

static var screenCenter: Vector2 = Vector2.ZERO

static var screenOffset: Vector2 = Vector2.ZERO

static var defaultSize: Vector2 = Vector2.ZERO
static var defaultSizeCenter: Vector2 = Vector2.ZERO
static var defaultAspect: Window.ContentScaleAspect = getScreenAspectViaString(
	ProjectSettings.get_setting("display/window/stretch/aspect")
)

static var defaultScaleMode: Window.ContentScaleMode = getScreenScaleModeViaString(
	ProjectSettings.get_setting("display/window/stretch/scale_mode")
)
static var main_window: Window

static func _init() -> void:
	defaultSize.x = ProjectSettings.get_setting('display/window/size/viewport_width')
	defaultSize.y = ProjectSettings.get_setting('display/window/size/viewport_height')
	defaultSizeCenter = defaultSize/2.0
	_set_window.call_deferred()
	updateScreenData()

static func _set_window():
	main_window = Engine.get_main_loop().root.get_window()
	main_window.size_changed.connect(updateScreenSize)
	updateScreenSize()
	
static func updateScreenData():
	screenSize = defaultSize - screenOffset
	screenCenter = screenSize/2.0
	
static func updateScreenSize() -> void:
	var new_size = main_window.size
	var offset: Vector2 = Vector2.ONE
	match main_window.content_scale_aspect:
		Window.CONTENT_SCALE_ASPECT_EXPAND: offset = Vector2(new_size.x/defaultSize.x,new_size.y/defaultSize.y)
		Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH: offset.y = new_size.y/defaultSize.y
		Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT: offset.x = new_size.x/defaultSize.x
		_: offset = Vector2(main_window.content_scale_size)/defaultSize
	
	screenOffset = defaultSize*(Vector2.ONE - offset)
	updateScreenData()

static func getScreenAspectViaString(aspect: String) -> Window.ContentScaleAspect:
	match aspect:
		'keep': return Window.CONTENT_SCALE_ASPECT_KEEP
		'keep_width': return Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH
		'keep_height': return Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
		'expand': return Window.CONTENT_SCALE_ASPECT_EXPAND
		_: return Window.CONTENT_SCALE_ASPECT_IGNORE

static func getScreenScaleModeViaString(scale_mode:String) -> Window.ContentScaleMode:
	match scale_mode:
		'canvas_items': return Window.ContentScaleMode.CONTENT_SCALE_MODE_CANVAS_ITEMS
		'viewport': return Window.ContentScaleMode.CONTENT_SCALE_MODE_VIEWPORT
		_: return Window.ContentScaleMode.CONTENT_SCALE_MODE_DISABLED
