extends Node

# Makes all the game sounds out of pure maths! No sound files needed.
# A speaker moves in and out very fast to make sound. These functions
# write down the numbers that tell the speaker how to move.

const RATE := 22050  # how many numbers we make per second
const VOICES := 10   # how many sounds can play at the same time

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_BASE_DB := -9.0    # music sits quietly under the sound effects

# 0.0 = silent, 1.0 = full blast. Changed from the Settings screen.
var music_volume := 0.7
var sfx_volume := 0.8

# Which of the four teams you picked on the TEAM screen
var team := "green"

# Your name, your friends list, and which friend you're playing versus
var username := ""
var friends: Array = []
var requests: Array = []   # friend requests waiting to be accepted
var playing_with := ""

func set_username(name: String) -> void:
	username = name.strip_edges().substr(0, 12).to_upper()
	save_settings()

# Sending a friend request. They aren't your friend until it's ACCEPTED.
func send_request(name: String) -> String:
	var clean := name.strip_edges().substr(0, 12).to_upper()
	if clean == "":
		return "empty"
	if clean == username:
		return "self"
	if friends.has(clean):
		return "already"
	if requests.has(clean):
		return "pending"
	if friends.size() >= 6:
		return "full"
	requests.append(clean)
	save_settings()
	return "sent"

func accept_request(name: String) -> void:
	requests.erase(name)
	if not friends.has(name):
		friends.append(name)
	if playing_with == "":
		playing_with = name
	save_settings()

func decline_request(name: String) -> void:
	requests.erase(name)
	save_settings()

func remove_friend(name: String) -> void:
	friends.erase(name)
	if playing_with == name:
		playing_with = friends[0] if friends.size() > 0 else ""
	save_settings()

func set_playing_with(name: String) -> void:
	playing_with = name
	save_settings()

# Who Player 2 is in versus mode
func opponent_name() -> String:
	return playing_with if playing_with != "" else "PLAYER 2"

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music_player: AudioStreamPlayer
var _sounds := {}

func _ready() -> void:
	# keep the music and menu bleeps working while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)

	load_settings()
	_build_sounds()
	_music_player.stream = _make_music()
	_apply_music_volume()
	_music_player.play()

# Play a sound by name. pitch 1.0 = normal, 2.0 = twice as squeaky!
func play(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not _sounds.has(name) or sfx_volume <= 0.0:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _sounds[name]
	p.pitch_scale = pitch
	# turn the requested loudness down by however loud the player wants sounds
	p.volume_db = volume_db + linear_to_db(sfx_volume)
	p.play()

# ---------- Volume settings ----------

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_music_volume()
	save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	save_settings()

func _apply_music_volume() -> void:
	if music_volume <= 0.0:
		_music_player.volume_db = -80.0   # basically off
	else:
		_music_player.volume_db = MUSIC_BASE_DB + linear_to_db(music_volume)

func set_team(id: String) -> void:
	team = id
	save_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", _is_fullscreen())
	cfg.set_value("game", "team", team)
	cfg.set_value("game", "username", username)
	cfg.set_value("game", "friends", friends)
	cfg.set_value("game", "requests", requests)
	cfg.set_value("game", "playing_with", playing_with)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return   # no settings saved yet, keep the defaults
	music_volume = clampf(cfg.get_value("audio", "music", music_volume), 0.0, 1.0)
	sfx_volume = clampf(cfg.get_value("audio", "sfx", sfx_volume), 0.0, 1.0)
	team = str(cfg.get_value("game", "team", team))
	username = str(cfg.get_value("game", "username", ""))
	friends = cfg.get_value("game", "friends", [])
	requests = cfg.get_value("game", "requests", [])
	playing_with = str(cfg.get_value("game", "playing_with", ""))
	set_fullscreen(cfg.get_value("video", "fullscreen", false))

func _is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func stop_music() -> void:
	_music_player.stop()

func start_music() -> void:
	if not _music_player.playing:
		_music_player.play()

# ---------- The sound recipes ----------

func _build_sounds() -> void:
	# Shooting: a quick high blip that drops down
	var b := _new_buf(0.09)
	_add_tone(b, 0.0, 0.09, 900.0, 260.0, 0.35, "square")
	_sounds["shoot"] = _to_stream(b)

	# Jumping: a quick blip that goes UP
	b = _new_buf(0.12)
	_add_tone(b, 0.0, 0.12, 300.0, 720.0, 0.30, "square")
	_sounds["jump"] = _to_stream(b)

	# Double jump: higher and sparklier
	b = _new_buf(0.14)
	_add_tone(b, 0.0, 0.14, 500.0, 1100.0, 0.28, "square")
	_add_tone(b, 0.02, 0.10, 1000.0, 1600.0, 0.14, "sine")
	_sounds["double_jump"] = _to_stream(b)

	# Dash: a whoosh (noise sliding down)
	b = _new_buf(0.22)
	_add_tone(b, 0.0, 0.22, 1.0, 1.0, 0.22, "noise")
	_add_tone(b, 0.0, 0.18, 700.0, 180.0, 0.15, "saw")
	_sounds["dash"] = _to_stream(b)

	# Enemy popping: a splat then a downward zap
	b = _new_buf(0.28)
	_add_tone(b, 0.0, 0.10, 1.0, 1.0, 0.30, "noise")
	_add_tone(b, 0.0, 0.26, 420.0, 70.0, 0.32, "square")
	_sounds["pop"] = _to_stream(b)

	# Ouch! Low and nasty
	b = _new_buf(0.35)
	_add_tone(b, 0.0, 0.35, 220.0, 60.0, 0.40, "saw")
	_add_tone(b, 0.0, 0.12, 1.0, 1.0, 0.20, "noise")
	_sounds["hurt"] = _to_stream(b)

	# Power-up: a happy little ladder going up
	b = _new_buf(0.42)
	var ladder := [523.25, 659.25, 783.99, 1046.5]
	for i in ladder.size():
		_add_tone(b, i * 0.08, 0.16, ladder[i], ladder[i], 0.26, "square")
	_sounds["powerup"] = _to_stream(b)

	# Boss getting hit: a heavy thud
	b = _new_buf(0.18)
	_add_tone(b, 0.0, 0.18, 180.0, 50.0, 0.45, "square")
	_sounds["boss_hurt"] = _to_stream(b)

	# BOSS APPEARS: scary low rumble
	b = _new_buf(1.1)
	_add_tone(b, 0.0, 1.1, 90.0, 55.0, 0.42, "saw", false)
	_add_tone(b, 0.0, 1.1, 91.5, 56.5, 0.30, "square", false)
	_sounds["boss_warn"] = _to_stream(b)

	# BOSS DIES: big long explosion
	b = _new_buf(1.4)
	_add_tone(b, 0.0, 1.4, 1.0, 1.0, 0.50, "noise")
	_add_tone(b, 0.0, 1.0, 260.0, 30.0, 0.35, "square")
	_add_tone(b, 0.15, 0.9, 180.0, 25.0, 0.25, "saw")
	_sounds["boss_die"] = _to_stream(b)

	# Exit unlocked: a magic shimmer
	b = _new_buf(0.6)
	var shimmer := [659.25, 880.0, 1108.7, 1318.5, 1760.0]
	for i in shimmer.size():
		_add_tone(b, i * 0.07, 0.28, shimmer[i], shimmer[i] * 1.02, 0.20, "sine")
	_sounds["unlock"] = _to_stream(b)

	# Level complete: a victory tune!
	b = _new_buf(1.2)
	var win := [523.25, 659.25, 783.99, 1046.5, 1046.5]
	for i in win.size():
		var start: float = i * 0.13
		var length := 0.5 if i == win.size() - 1 else 0.16
		_add_tone(b, start, length, win[i], win[i], 0.30, "square")
	_sounds["win"] = _to_stream(b)

	# Menu click: a short friendly bleep
	b = _new_buf(0.10)
	_add_tone(b, 0.0, 0.05, 700.0, 700.0, 0.28, "square")
	_add_tone(b, 0.05, 0.05, 1050.0, 1050.0, 0.28, "square")
	_sounds["click"] = _to_stream(b)

	# Game over: a sad slide down
	b = _new_buf(1.3)
	var sad := [523.25, 440.0, 349.23, 261.63]
	for i in sad.size():
		_add_tone(b, i * 0.22, 0.45, sad[i], sad[i] * 0.98, 0.30, "square")
	_sounds["lose"] = _to_stream(b)

# ---------- The maths bits ----------

func _new_buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(RATE * seconds))
	return b

# Draws one wobbly sound wave into the buffer.
# f0 = starting note, f1 = ending note (so notes can slide!)
func _add_tone(buf: PackedFloat32Array, at: float, dur: float, f0: float, f1: float,
		vol: float, wave: String, fade_out := true) -> void:
	var start := int(at * RATE)
	var count := int(dur * RATE)
	var phase := 0.0
	for i in count:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / float(count)
		phase += TAU * lerpf(f0, f1, t) / float(RATE)
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if sin(phase) > 0.0 else -1.0
			"saw":
				s = fposmod(phase, TAU) / PI - 1.0
			"sine":
				s = sin(phase)
			"noise":
				s = randf() * 2.0 - 1.0
		var envelope := (1.0 - t) if fade_out else 1.0
		# tiny fade-in stops nasty clicks at the start
		envelope *= minf(1.0, float(i) / 80.0)
		buf[idx] += s * vol * envelope

# Turns our numbers into a sound Godot can actually play.
func _to_stream(buf: PackedFloat32Array, looping := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v := int(clampf(buf[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = buf.size()
	return stream

# ---------- Background music ----------

func _make_music() -> AudioStreamWAV:
	# A driving adventure tune in D minor - faster and punchier than the
	# old one, with a rolling bass line underneath and a proper drum beat.
	var step := 0.1875        # one music step (160 beats per minute)
	var steps := 64           # 64 steps = 12 seconds before it loops
	var buf := _new_buf(step * steps)

	# The main tune on top. 0.0 means "rest" (stay quiet for a step).
	var melody := [
		587.33, 0.0, 698.46, 587.33, 880.0, 0.0, 783.99, 698.46,
		587.33, 0.0, 523.25, 587.33, 0.0, 440.0, 0.0, 0.0,
		523.25, 0.0, 659.25, 523.25, 783.99, 0.0, 698.46, 659.25,
		523.25, 0.0, 466.16, 523.25, 0.0, 392.0, 0.0, 0.0,
		698.46, 0.0, 880.0, 698.46, 1046.5, 0.0, 987.77, 880.0,
		783.99, 0.0, 698.46, 659.25, 0.0, 587.33, 0.0, 0.0,
		880.0, 987.77, 1046.5, 987.77, 880.0, 783.99, 698.46, 659.25,
		587.33, 0.0, 0.0, 587.33, 0.0, 0.0, 0.0, 0.0,
	]
	for i in melody.size():
		if melody[i] > 0.0:
			_add_tone(buf, i * step, step * 0.85, melody[i], melody[i], 0.15, "square")
			# a quiet echo an octave up makes it sparkle
			_add_tone(buf, i * step, step * 0.5, melody[i] * 2.0, melody[i] * 2.0,
				0.045, "square")

	# Rolling bass - two notes per bar so it bounces along
	var bass := [
		146.83, 220.0, 146.83, 174.61,   # D  A  D  F
		130.81, 196.0, 130.81, 164.81,   # C  G  C  E
		174.61, 261.63, 174.61, 220.0,   # F  C  F  A
		196.0, 146.83, 196.0, 220.0,     # G  D  G  A
	]
	for i in bass.size():
		_add_tone(buf, i * step * 4.0, step * 3.5, bass[i], bass[i], 0.19, "saw", false)

	# Drums: a kick on every beat, a snare-ish crack on the off-beats
	for i in range(0, steps, 4):
		_add_tone(buf, i * step, 0.11, 170.0, 40.0, 0.30, "square")
	for i in range(2, steps, 4):
		_add_tone(buf, i * step, 0.07, 1.0, 1.0, 0.13, "noise")
	# hi-hat ticking away on every step
	for i in steps:
		_add_tone(buf, i * step, 0.03, 1.0, 1.0, 0.05, "noise")

	return _to_stream(buf, true)
