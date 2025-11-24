extends VideoStreamPlayer

var canSkip: bool = false
var removeWhenFinished: bool = true
func _init(): 
	resized.connect(_on_resized)
	finished.connect(_on_finish)

func load_stream(path: Variant) -> void:
	var _stream = Paths.video(path) if path is String else path
	if !_stream is VideoStreamTheora: stream = null
	stream = _stream
	if is_inside_tree(): play()

func _process(_d: float) -> void:
	if canSkip and Input.is_action_just_pressed('ui_accept'): skipVideo()

func skipVideo() -> void:
	FunkinGD.callOnScripts(&'onSkipCutscene',[stream.resource_name])
	finished.emit()

func _enter_tree() -> void: if stream: play()

func _on_resized() -> void:
	var video_scale = (ScreenUtils.screenSize/size)
	video_scale = video_scale[video_scale.min_axis_index()] #Get minimum value
	scale = Vector2(video_scale,video_scale)

func _on_finish() -> void: if removeWhenFinished: queue_free()
