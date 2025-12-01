extends Node

const ModchartState = preload("res://source/states/Editors/Modchart/ModchartState.gd")
const Grid = preload("uid://cimlksev0a8qs")
const EditorMaterial = preload("res://source/states/Editors/Modchart/Shaders/EditorShader.gd")

var modchart_keys = ModchartState.keys
var modchart_upating = ModchartState.keys_index

var songPosition: float = 0.0: set = set_song_editor_position

#region PlayState Variables
@onready var playState = $SubViewport/PlayState
static var songToLoad = 'test'
#endregion

#region Nodes
@onready var dialog_bg = $BG
@onready var dialog: FileDialog = $FileDialog

@onready var position_line = $VSplit/Timeline/Position/Steps/Time/PositionLine
@onready var timeline = $VSplit/Timeline/Position/Steps/Time
#endregion


#region Grid Properties
const DropdownBoxScene = preload("uid://chnhbepr464uw")

@onready var grid_explorer = $VSplit/Timeline/Objects/Explorer
@onready var grid_container = $VSplit/Timeline/Position/GridContainer

var grid_real_x: float
var grid_x: float = 0.0
var scroll_pos: float = 0.0
#endregion

#region TimeLine Properties
var is_moving_line: bool = false
var last_position_line: Vector2 = Vector2.ZERO
var position_line_offset: float = 0.0
@onready var objects_container = $VSplit/Timeline/Objects/Explorer/Scroll/VBox
#endregion


@onready var properties: Panel = $VSplit/Interator/HSplit/Properties

#region Keys Area



#endregion

#region Different values
var is_type_different: bool = false
var is_duration_different: bool = false
var is_transition_different: bool = false
var is_ease_different: bool = false
#endregion

signal song_position_changed(value: float, is_backward: bool)
func _ready() -> void:
	_update_song_info.call_deferred()
	
	dialog.current_dir = Paths.exePath+'/'
	dialog.canceled.connect(dialog_bg.hide)
	
	#Set the state of the PlayState
	playState.inModchartEditor = true
	playState.respawnNotes = true
	pausePlaystate.call_deferred(true)
#region Dialog
func show_dialog(show: bool = true, mode: FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE) -> void:
	if show:  dialog.option_count = 0; dialog.clear_filters(); dialog.file_mode = mode
	dialog_bg.visible = show
	dialog.visible = show

func connect_to_dialog(callable: Callable) -> void: 
	for i in dialog.file_selected.get_connections(): dialog.file_selected.disconnect(i.callable)
	
	dialog.file_selected.connect(callable,ConnectFlags.CONNECT_ONE_SHOT)
	dialog.file_selected.connect(func(_f): dialog_bg.hide(),ConnectFlags.CONNECT_ONE_SHOT)
#endregion



#region Song
func _update_song_info():
	if playState.Song.songName: 
		if Paths.curMod: DiscordRPC.details = 'Editing Modchart of: '+playState.Song.songName+' of the '+Paths.curMod+" mod"
		else: DiscordRPC.details = 'Editing Modchart of: '+playState.Song.songName
	else: DiscordRPC.details = 'Editing Modchart'
	DiscordRPC.refresh()
	
	timeline.steps = Conductor.get_step_count()
#endregion

#region Shader Area
#endregion

#region Modchart Area
func _process(_d) -> void:
	if playState.process_mode != playState.PROCESS_MODE_DISABLED: set_song_editor_position(Conductor.songPosition)

func save_modchart(path_absolute: String): Paths.saveFile(ModchartState.get_keys_data(),path_absolute)
#endregion

#region Song Position
func set_song_editor_position(new_pos: float) -> void:
	if new_pos == songPosition: return
	
	if Conductor.step_float < 0:  grid_x = -26
	else:  grid_x = maxf(0,Conductor.step_float - 15)
	grid_real_x = grid_x*grid_container.grid_size.x
	
	scroll_pos = minf(grid_x,timeline.steps-26)*grid_container.grid_size.x
	timeline.position.x = -scroll_pos
	
	var is_processing_back: bool = new_pos < songPosition
	songPosition = new_pos
	
	if is_processing_back: playState.updateRespawnNotes()
	ModchartState.process_keys(is_processing_back)
	
	song_position_changed.emit(new_pos,is_processing_back)
	

func set_song_position(pos: float):
	if pos == songPosition: return
	Conductor.seek(pos)
	playState.updateNotes()
	set_song_editor_position(pos)
#endregion

#region Grid Methods
#endregion

#region Input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_SPACE: pausePlaystate(playState.process_mode != PROCESS_MODE_DISABLED)

#region PlayState
func pausePlaystate(pause: bool) -> void:
	playState.canHitNotes = !pause
	if pause: playState.pauseSong()
	else: playState.resumeSong()

func _set_playstate_value(value: Variant, property: String): playState.set(property,value)
#endregion

#region Signals
func _on_modchart_options_index_selected(index: int):
	match index:
		0:
			show_dialog(true,FileDialog.FILE_MODE_SAVE_FILE)
			connect_to_dialog(save_modchart)
		1: show_dialog(true,FileDialog.FILE_MODE_SAVE_FILE)
			#connect_to_dialog(load_modchart)

#endregion
