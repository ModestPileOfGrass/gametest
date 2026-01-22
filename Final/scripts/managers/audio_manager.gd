extends Node

## Audio Manager Singleton
## Handles music playback and sound effects for the space shooter
## Registered as autoload in Project Settings
## 
## Usage:
##   AudioManager.play_sfx("shoot")
##   AudioManager.play_music("gameplay")
##   AudioManager.set_master_volume(0.8)

# ============================================================
# AUDIO BUSES
# ============================================================

const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"

# ============================================================
# AUDIO PLAYERS
# ============================================================

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 16  # Pool of SFX players for simultaneous sounds

# ============================================================
# AUDIO LIBRARIES
# ============================================================

## Music tracks (key = track name, value = AudioStream resource)
var music_tracks: Dictionary = {}

## Sound effects (key = sfx name, value = AudioStream resource)
var sound_effects: Dictionary = {}

# ============================================================
# STATE
# ============================================================

var current_music_track: String = ""
var music_fade_tween: Tween = null

## Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

## Enable/disable audio
var music_enabled: bool = true
var sfx_enabled: bool = true

## Debug output
var debug_output: bool = true

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = BUS_MUSIC
	add_child(music_player)
	
	# Create SFX player pool
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer%d" % i
		sfx_player.bus = BUS_SFX
		add_child(sfx_player)
		sfx_players.append(sfx_player)
	
	# Load audio resources
	_load_music_tracks()
	_load_sound_effects()
	
	# Apply initial volumes
	_update_bus_volumes()
	
	if debug_output:
		print("AudioManager ready")
		print("  Music tracks: %d" % music_tracks.size())
		print("  Sound effects: %d" % sound_effects.size())


# ============================================================
# AUDIO LOADING
# ============================================================

func _load_music_tracks() -> void:
	## Load all music tracks from res://audio/music/
	## Supports .ogg, .mp3, and .wav files
	var music_files = {
		"menu": "menu_theme",
		"gameplay": "gameplay_theme",
		"boss": "boss_theme",
		"gameover": "gameover_theme"
	}
	
	for track_name in music_files:
		var base_name = music_files[track_name]
		var loaded = false
		
		# Try multiple file formats
		for ext in [".mp3", ".ogg", ".wav"]:
			var path = "res://audio/music/" + base_name + ext
			if ResourceLoader.exists(path):
				music_tracks[track_name] = load(path)
				if debug_output:
					print("  Loaded music: %s (%s)" % [track_name, path])
				loaded = true
				break
		
		if not loaded and debug_output:
			print("  Music not found: %s (tried .mp3, .ogg, .wav)" % track_name)


func _load_sound_effects() -> void:
	## Load all sound effects - procedurally generated if files don't exist
	var sfx_configs = {
		# Shooting
		"shoot": {"type": "laser", "freq": 800.0, "duration": 0.1},
		"shoot_spread": {"type": "laser", "freq": 600.0, "duration": 0.15},
		
		# Impacts
		"hit": {"type": "hit", "freq": 400.0, "duration": 0.08},
		"explosion": {"type": "explosion", "freq": 200.0, "duration": 0.4},
		"player_damage": {"type": "damage", "freq": 300.0, "duration": 0.2},
		"player_death": {"type": "explosion", "freq": 150.0, "duration": 0.6},
		
		# Pickups
		"pickup_health": {"type": "pickup", "freq": 600.0, "duration": 0.2},
		"pickup_shield": {"type": "pickup", "freq": 800.0, "duration": 0.2},
		"pickup_powerup": {"type": "powerup", "freq": 1000.0, "duration": 0.3},
		
		# UI
		"button_click": {"type": "click", "freq": 1200.0, "duration": 0.05},
		"button_hover": {"type": "click", "freq": 900.0, "duration": 0.03},
		"level_up": {"type": "powerup", "freq": 1200.0, "duration": 0.4},
		"wave_complete": {"type": "powerup", "freq": 1400.0, "duration": 0.5}
	}
	
	for sfx_name in sfx_configs:
		# Try to load from file first
		var path = "res://audio/sfx/" + sfx_name + ".wav"
		if ResourceLoader.exists(path):
			sound_effects[sfx_name] = load(path)
			if debug_output:
				print("  Loaded SFX from file: %s" % sfx_name)
		else:
			# Generate procedurally
			var config = sfx_configs[sfx_name]
			sound_effects[sfx_name] = _generate_sfx(
				config["type"],
				config["freq"],
				config["duration"]
			)
			if debug_output:
				print("  Generated SFX: %s" % sfx_name)


# ============================================================
# MUSIC CONTROL
# ============================================================

func play_music(track_name: String, fade_in: bool = true, fade_duration: float = 1.0) -> void:
	## Play a music track with optional fade-in
	if not music_enabled:
		return
	
	# Check if track exists
	if not music_tracks.has(track_name):
		push_warning("AudioManager: Music track '%s' not found" % track_name)
		return
	
	# Don't restart if already playing
	if current_music_track == track_name and music_player.playing:
		return
	
	# Kill any existing fade tween
	if music_fade_tween:
		music_fade_tween.kill()
	
	# Stop current music
	if music_player.playing:
		if fade_in:
			# Fade out current, then fade in new
			music_fade_tween = create_tween()
			music_fade_tween.tween_property(music_player, "volume_db", -80, fade_duration * 0.5)
			music_fade_tween.tween_callback(func():
				_start_music_track(track_name, fade_in, fade_duration)
			)
		else:
			# Immediate switch
			music_player.stop()
			_start_music_track(track_name, false, 0.0)
	else:
		# No music playing, just start
		_start_music_track(track_name, fade_in, fade_duration)


func _start_music_track(track_name: String, fade_in: bool, fade_duration: float) -> void:
	## Internal: Start playing a music track
	music_player.stream = music_tracks[track_name]
	current_music_track = track_name
	
	if fade_in:
		# Start at silent, fade in
		music_player.volume_db = -80
		music_player.play()
		
		music_fade_tween = create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", 0, fade_duration)
	else:
		# Play immediately at full volume
		music_player.volume_db = 0
		music_player.play()
	
	if debug_output:
		print("AudioManager: Playing music '%s'" % track_name)


func stop_music(fade_out: bool = true, fade_duration: float = 1.0) -> void:
	## Stop music playback with optional fade-out
	if not music_player.playing:
		return
	
	if fade_out:
		# Fade out, then stop
		if music_fade_tween:
			music_fade_tween.kill()
		
		music_fade_tween = create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", -80, fade_duration)
		music_fade_tween.tween_callback(func():
			music_player.stop()
			current_music_track = ""
		)
	else:
		# Stop immediately
		music_player.stop()
		current_music_track = ""
	
	if debug_output:
		print("AudioManager: Stopped music")


func pause_music() -> void:
	## Pause music (can be resumed)
	music_player.stream_paused = true


func resume_music() -> void:
	## Resume paused music
	music_player.stream_paused = false


# ============================================================
# SOUND EFFECTS
# ============================================================

func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	## Play a sound effect with optional pitch variation
	## pitch_variation: random pitch shift range (-0.2 to 0.2 is good)
	if not sfx_enabled:
		return
	
	# Check if SFX exists
	if not sound_effects.has(sfx_name):
		push_warning("AudioManager: SFX '%s' not found" % sfx_name)
		return
	
	# Find available SFX player
	var player = _get_available_sfx_player()
	if not player:
		if debug_output:
			print("AudioManager: All SFX players busy, skipping '%s'" % sfx_name)
		return
	
	# Setup and play
	player.stream = sound_effects[sfx_name]
	
	# Apply pitch variation if requested
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()


func _get_available_sfx_player() -> AudioStreamPlayer:
	## Find an SFX player that's not currently playing
	for player in sfx_players:
		if not player.playing:
			return player
	return null


# ============================================================
# VOLUME CONTROL
# ============================================================

func set_master_volume(volume: float) -> void:
	## Set master volume (0.0 to 1.0)
	master_volume = clamp(volume, 0.0, 1.0)
	_update_bus_volumes()


func set_music_volume(volume: float) -> void:
	## Set music volume (0.0 to 1.0)
	music_volume = clamp(volume, 0.0, 1.0)
	_update_bus_volumes()


func set_sfx_volume(volume: float) -> void:
	## Set SFX volume (0.0 to 1.0)
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_bus_volumes()


func _update_bus_volumes() -> void:
	## Update audio bus volumes from settings
	var master_db = linear_to_db(master_volume)
	var music_db = linear_to_db(music_volume)
	var sfx_db = linear_to_db(sfx_volume)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), master_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), music_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), sfx_db)


# ============================================================
# ENABLE/DISABLE
# ============================================================

func set_music_enabled(enabled: bool) -> void:
	## Enable/disable music
	music_enabled = enabled
	if not enabled:
		stop_music(false)


func set_sfx_enabled(enabled: bool) -> void:
	## Enable/disable sound effects
	sfx_enabled = enabled


# ============================================================
# UTILITY
# ============================================================

func is_music_playing() -> bool:
	return music_player.playing


func get_current_music_track() -> String:
	return current_music_track


# ============================================================
# PROCEDURAL SOUND GENERATION
# ============================================================

func _generate_sfx(type: String, base_freq: float, duration: float) -> AudioStreamWAV:
	## Generate procedural sound effects using AudioStreamGenerator
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	
	match type:
		"laser":
			_generate_laser(samples, base_freq, sample_rate)
		"hit":
			_generate_hit(samples, base_freq, sample_rate)
		"explosion":
			_generate_explosion(samples, base_freq, sample_rate)
		"damage":
			_generate_damage(samples, base_freq, sample_rate)
		"pickup":
			_generate_pickup(samples, base_freq, sample_rate)
		"powerup":
			_generate_powerup(samples, base_freq, sample_rate)
		"click":
			_generate_click(samples, base_freq, sample_rate)
	
	# Create AudioStreamWAV from samples
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	# Convert float samples to 16-bit PCM
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)  # 2 bytes per sample for 16-bit
	
	for i in range(num_samples):
		var sample_value = clamp(samples[i], -1.0, 1.0)
		var int_value = int(sample_value * 32767.0)
		# Little-endian 16-bit
		byte_data[i * 2] = int_value & 0xFF
		byte_data[i * 2 + 1] = (int_value >> 8) & 0xFF
	
	stream.data = byte_data
	return stream


func _generate_laser(samples: PackedFloat32Array, freq: float, sample_rate: int) -> void:
	## Laser/shoot sound - descending frequency sweep
	var num_samples = samples.size()
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Frequency sweep from high to low
		var current_freq = freq * (1.0 - progress * 0.5)
		
		# Square wave for classic laser sound
		var phase = fmod(current_freq * t * TAU, TAU)
		var value = 1.0 if phase < PI else -1.0
		
		# Envelope: quick attack, exponential decay
		var envelope = exp(-progress * 8.0)
		
		samples[i] = value * envelope * 0.3


func _generate_hit(samples: PackedFloat32Array, freq: float, sample_rate: int) -> void:
	## Hit sound - short noise burst
	var num_samples = samples.size()
	for i in range(num_samples):
		var progress = float(i) / num_samples
		
		# Noise
		var noise = randf_range(-1.0, 1.0)
		
		# Mix with low frequency tone
		var t = float(i) / sample_rate
		var tone = sin(freq * t * TAU)
		
		var value = lerp(tone, noise, 0.7)
		
		# Sharp envelope
		var envelope = exp(-progress * 15.0)
		
		samples[i] = value * envelope * 0.4


func _generate_explosion(samples: PackedFloat32Array, freq: float, sample_rate: int) -> void:
	## Explosion sound - long noise with bass rumble
	var num_samples = samples.size()
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# White noise
		var noise = randf_range(-1.0, 1.0)
		
		# Low frequency rumble
		var rumble = sin(freq * t * TAU) * 0.5
		rumble += sin(freq * 0.5 * t * TAU) * 0.3
		
		var value = lerp(rumble, noise, 0.6)
		
		# Longer envelope with sustain
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress / 0.1  # Attack
		else:
			envelope = exp(-(progress - 0.1) * 3.0)  # Decay
		
		samples[i] = value * envelope * 0.5


func _generate_damage(samples: PackedFloat32Array, freq: float, sample_rate: int) -> void:
	## Damage sound - harsh noise with frequency modulation
	var num_samples = samples.size()
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Harsh noise
		var noise = randf_range(-1.0, 1.0)
		
		# Frequency modulated tone
		var mod = sin(freq * 3.0 * t * TAU) * 0.3
		var tone = sin((freq + mod * freq) * t * TAU)
		
		var value = lerp(tone, noise, 0.5)
		
		# Envelope
		var envelope = exp(-progress * 6.0)
		
		samples[i] = value * envelope * 0.4


func _generate_pickup(samples: PackedFloat32Array, freq: float, sample_rate: int) -> void:
	## Pickup sound - ascending arpeggio
	var num_samples = samples.size()
	var note_duration = num_samples / 3.0
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Three note arpeggio
		var note_index = int(float(i) / note_duration)
		var freq_mult = [1.0, 1.25, 1.5][note_index] if note_index < 3 else 1.5
		
		var current_freq = freq * freq_mult
		var value = sin(current_freq * t * TAU)
		
		# Envelope
		var envelope = exp(-progress * 4.0)
		
		samples[i] = value * envelope * 0.3


func _generate_powerup(samples: PackedFloat32Array, freq: float, sample_rate: int) -> void:
	## Powerup sound - rising arpeggio with harmonics
	var num_samples = samples.size()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		# Rising frequency sweep
		var current_freq = freq * (1.0 + progress * 0.5)
		
		# Multiple harmonics for rich sound
		var value = 0.0
		value += sin(current_freq * t * TAU) * 0.5
		value += sin(current_freq * 2.0 * t * TAU) * 0.25
		value += sin(current_freq * 3.0 * t * TAU) * 0.125
		
		# Envelope with sustain
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress / 0.1
		elif progress > 0.7:
			envelope = 1.0 - (progress - 0.7) / 0.3
		
		samples[i] = value * envelope * 0.25


func _generate_click(samples: PackedFloat32Array, freq: float, sample_rate: int) -> void:
	## Click sound - very short sine wave
	var num_samples = samples.size()
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var progress = float(i) / num_samples
		
		var value = sin(freq * t * TAU)
		
		# Very sharp envelope
		var envelope = exp(-progress * 40.0)
		
		samples[i] = value * envelope * 0.2
