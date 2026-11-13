extends Node
## Am thanh cua game. Dang ky Autoload ten "Audio" trong project.godot.
##   Audio.play_music("shop")  -> doi nhac nen (chuyen em 1,5 giay)
##   Audio.sfx("coin")         -> phat tieng dong
## File nam o res://assets/audio/: music_<ten>.ogg va <ten>.wav

const DIR := "res://assets/audio/"
const MUSIC_DB := -6.0   # nhac nen nho hon tieng dong mot chut
const FADE := 1.5
const VOLUME_STEPS := [0.0, 0.25, 0.5, 0.75, 1.0]  # Tat / 25% / 50% / 75% / 100%

var _music: Array = []    # 2 dau phat de chuyen bai em ai
var _active := 0
var _current := ""
var _sfx: Array = []
var _sfx_next := 0
var _cache := {}
var _amb: AudioStreamPlayer   # tieng nen (mua...)
var _amb_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # van chay khi game tam dung
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_music.append(p)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = -80.0
	add_child(_amb)
	for i in 6:
		var s := AudioStreamPlayer.new()
		add_child(s)
		_sfx.append(s)


func _music_linear() -> float:
	return VOLUME_STEPS[GameState.music_volume]


func _sfx_linear() -> float:
	return VOLUME_STEPS[GameState.sfx_volume]


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var st := load(path) as AudioStream
	_cache[path] = st
	return st


func play_music(track: String) -> void:
	if track == _current:
		return
	_current = track
	var st := _load(DIR + "music_%s.ogg" % track)
	var old: AudioStreamPlayer = _music[_active]
	_active = 1 - _active
	var nw: AudioStreamPlayer = _music[_active]
	var tw := create_tween().set_parallel()
	tw.tween_property(old, "volume_db", -80.0, FADE)
	if st == null:
		return
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	nw.stream = st
	nw.volume_db = -80.0
	nw.play()
	tw.tween_property(nw, "volume_db", _target_db(), FADE)


func _target_db() -> float:
	var v := _music_linear()
	if v <= 0.0:
		return -80.0
	return linear_to_db(v) + MUSIC_DB


## Goi sau khi doi am luong trong Cai dat.
func apply_volume() -> void:
	var p: AudioStreamPlayer = _music[_active]
	p.volume_db = _target_db()


func sfx(sound: String, volume: float = 1.0, pitch_jitter: float = 0.05) -> void:
	var v := _sfx_linear() * volume
	if v <= 0.0:
		return
	var st := _load(DIR + sound + ".wav")
	if st == null:
		return
	var p: AudioStreamPlayer = _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	p.stream = st
	p.volume_db = linear_to_db(v)
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)  # moi lan nghe hoi khac, bot nham chan
	p.play()


## Tieng nen lap lai (vd. "rain" -> amb_rain.ogg). Chuoi rong = tat.
func play_ambience(track: String) -> void:
	if track == _amb_name:
		return
	_amb_name = track
	var tw := create_tween()
	if track == "":
		tw.tween_property(_amb, "volume_db", -80.0, FADE)
		tw.tween_callback(_amb.stop)
		return
	var st := _load(DIR + "amb_%s.ogg" % track)
	if st == null:
		return
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	_amb.stream = st
	_amb.volume_db = -80.0
	_amb.play()
	var v := _sfx_linear() * 0.5
	tw.tween_property(_amb, "volume_db", linear_to_db(v) if v > 0.0 else -80.0, FADE)
