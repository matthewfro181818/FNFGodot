extends Node
const Song = preload("uid://cerxbopol4l1g")

var prev_scene: Variant
@onready var chess_manager = $ChessControl
@export var songName: String
@export var difficulty: String
@export var songFolder: String
@export var audioFolder: String
@export var audio_suffix: String
@export var songJson: String


var player1Data: Dictionary
var player2Data: Dictionary
var gfData: Dictionary

var keyCount: int = 4

#region Popups
@onready var bf_characters: MenuButton = $TabContainer/Song/bfCharacters
@onready var dad_characters: MenuButton = $TabContainer/Song/dadCharacters
@onready var gf_characters: MenuButton = $TabContainer/Song/gfCharacters

@onready var bf_characters_popup: PopupMenu = bf_characters.get_popup()
@onready var dad_characters_popup: PopupMenu = dad_characters.get_popup()
@onready var gf_characters_popup: PopupMenu = gf_characters.get_popup()
#endregion


var section_data: Dictionary

func set_opponent(json: String): player1Data = Paths.character(json); chess_manager._load_icon_opponent()
func set_player(json: String): player2Data = Paths.character(json); chess_manager._load_icon_player()
func set_gf(json: String): gfData = Paths.character(json);

func _ready() -> void:
	_connect_popups()
	Conductor.section_hit_once.connect(_on_section_beat)
	
	_on_section_beat()
	
	if Conductor.songJson: return
	_load_song_json()


func _on_section_beat(): section_data = Conductor.get_section_data()

func _load_song_json():
	Song.set_song_directory(songName,difficulty,audioFolder,songJson,audio_suffix)
	Conductor.loadSong(songName,difficulty)
	Conductor.loadSongsStreams()
	if !Conductor.songJson: return
	_load_song_data()
	
func _load_song_data():
	set_opponent(Conductor.songJson.player1)
	set_player(Conductor.songJson.player2)
	keyCount = Conductor.songJson.get('keyCount',4)

func _connect_popups():
	bf_characters_popup.index_pressed.connect(func(i): var t = bf_characters_popup.get_item_text(i); set_player(t))
	dad_characters_popup.index_pressed.connect(func(i): var t = dad_characters_popup.get_item_text(i); set_opponent(t))
	gf_characters_popup.index_pressed.connect(func(i): var t = gf_characters_popup.get_item_text(i); set_gf(t))
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.pressed: return
		match event.keycode:
			KEY_SPACE:
				if Conductor.is_playing: Conductor.pauseSongs()
				else: Conductor.resumeSongs()
			KEY_BACKSPACE:
				if prev_scene: Global.swapTree(prev_scene); set_process_input(false)
static func reset_values():
	pass
