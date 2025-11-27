extends Label
enum Styles{
	DISABLED = 0,
	TIME_LEFT = 1,
	POSITION = 2,
	SONG_NAME = 3,
}
var style: Styles = ClientPrefs.data.timeBarType
func _init() -> void: 
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name = 'TimeTxt'
	set("theme_override_constants/outline_size",7)

func update() -> void:
	var pos: float = Conductor.songPosition
	match style:
		Styles.TIME_LEFT: text = get_time_text(int(Conductor.songLength-pos)/1000)
		Styles.POSITION: text = get_time_text(int(Conductor.songPositionSeconds)); return
		Styles.SONG_NAME: text = Conductor.songJson.song; return
		Styles.DISABLED: return
	

static func get_time_text(song_position: int) -> String:
	var songSeconds = song_position/1000
	var songMinutes = songSeconds/60
	songSeconds %= 60
	
	songMinutes = String.num_int64(songMinutes)
	songSeconds = String.num_int64(songSeconds)
	if songMinutes.length() <= 1: songMinutes = '0'+songMinutes
	if songSeconds.length() <= 1: songSeconds = '0'+songSeconds
	return songMinutes+':'+songSeconds
