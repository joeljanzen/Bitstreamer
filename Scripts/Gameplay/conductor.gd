class_name Conductor
extends AudioStreamPlayer
## Controls the timing 

@onready var _volume_fade_animation: AnimationPlayer = $VolumeFade
@onready var _pitch_speed_fade_animation: AnimationPlayer = $PitchSpeedFade

## A precisely timed event trigger, set to be emitted after a given delay by the
## set_timed_event function. The index, starting at 0, indicates a specific
## timed event in the song, allowing the ability to send timed events for any
## point in the song, not just in order from the start.
signal timed_event(event_index: int)

## Active only after set_beat_signal has been called, it is a timed event sent 
## regularly every beat of the song. This signal is distinct and unaffected by 
## the timed_event signal and set_timed_event function.
signal beat

## Emitted after fade_to_new_song is called, when the new song starts.
signal start_new_song

## The seconds per beat (the time between beat signal emissions).
## If this value is zero, no beat signals are being sent.
var seconds_per_beat: float = 0

## The time in the song being played that the next beat occurs, if 
## seconds_per_beat has been set.
var _time_of_next_beat: float = 0

## The current time in the song being played.
var _time: float

## The time in the song being played that a timed_event should be triggered.
var _time_delay_ends: float = 0

## Signifies that there is actually a delay that needs to emit a timed_event.
var _waiting_for_delay := false

## No more timing events are to be sent, so we can stop checking.
var _done_timings = false

## The index of the timing event to be sent out next.
var _timing_event_index: int = 0


## Set the song to play.
func set_song(song: AudioStream) -> void:
	stream = song


## Adjusts playback speed based on active mods.
func apply_tempo_scaling() -> void:
	pitch_scale = ModManager.get_playback_speed_factor()


## Sets up the beat signal given a bpm and returns the seconds per beat (how 
## much time will pass between each beat signal emission). The beat frequency is 
## multiplied by the beat coefficient. If you want the beat signal to occur 
## twice as often as the actual beat does, set the coefficient to 2. If you want
## beats to send at half of their normal speed, set the coefficient to 0.5.
func set_beat_signal(bpm: float,  beat_coefficient: float = 1) -> float:
	seconds_per_beat = 60 / bpm / beat_coefficient
	return seconds_per_beat


## Play the song with a given offset value in seconds, and the index of the
## next event that should be played.
## Use this function to play the conductor with no offset by passing no 
## arguments, instead of calling the inherited play() function.
func play_with_offset(offset: float = 0, event_index: int = 0) -> void:
	_time_delay_ends = 0
	_time_of_next_beat = offset
	_timing_event_index = event_index
	play(offset)


## Fade out the current song if it is playing, then fade into the song with the
## given offset. This all occurs over the time of transition speed in seconds.
func fade_to_new_song(new_song: AudioStream, offset: float = 0, transition_speed: float = 1) -> void:
	# Since we have to fade out and back in, we need the speed of each animation
	# to be twice as fast as the total transition time.
	var fade_speed_factor: float = 1 / transition_speed
	_volume_fade_animation.play("fade_out", -1, fade_speed_factor * 4 / 3)
	await _volume_fade_animation.animation_finished
	
	start_new_song.emit()
	set_song(new_song)
	_time_delay_ends = 0
	_time_of_next_beat = offset
	_timing_event_index = 0
	play(offset)
	_volume_fade_animation.play("fade_in", -1, fade_speed_factor * 4)


## Pause or unpause the song.
func toggle_paused() -> void:
	if stream_paused:
		stream_paused = false
	else:
		stream_paused = true


## Returns the current position in the song.
func get_time() -> float:
	return _time


## Given a delay, sends out the delay_end signal once after the delay has 
## passed. WARNING: You must first call play_with_offset before setting any 
## timed events!
func set_timed_event(delay: float) -> void:
	_waiting_for_delay = true
	_time_delay_ends += delay
	#print("set timed event to occur at %f" % _time_delay_ends)


## Tell the conductor it doesn't need to time any more events. This does not 
## affect the beat signal, which continues to the end of the song.
func done_timings() -> void:
	_done_timings = true


## Fade out the music over the time given.
func fade_out(time: float) -> void:
	#if _volume_fade_animation.is_playing()
	var fade_speed_factor: float = 1 / time
	_volume_fade_animation.play("fade_out", 1, fade_speed_factor)


## Fade in the music over the time given.
func fade_in(time: float) -> void:
	var fade_speed_factor: float = 1 / time
	_volume_fade_animation.play("fade_in", 1, fade_speed_factor)


## Slow down and decrease the pitch of the music drastically over the time given.
func speed_and_pitch_down(time: float) -> void:
	var fade_factor: float = 1 / time
	_pitch_speed_fade_animation.play("speed_pitch_down", 1, fade_factor)


## Most accurately measures the current song time and sends timed events based
## on that time.
func _physics_process(delta: float) -> void:
	_time = get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	_time -= AudioServer.get_output_latency()
	if _time < 0:
		_time = 0
	
	if playing and _time > 0:
		if !_done_timings:
			# If the difference between current time and time of delay end is within
			# the length of time since the last time _process was called (which is the
			# value of delta), we treat it as reaching the delay end.
			var difference = abs(_time - _time_delay_ends)
			if (difference <= delta || _time > _time_delay_ends) and _waiting_for_delay:
				_waiting_for_delay = false
				timed_event.emit(_timing_event_index)
				#print("sending timed event at %f" % _time)
				_timing_event_index += 1
		
		# Beat signal, which is only active if seconds_per_beat has been set.
		if seconds_per_beat > 0:
			var difference = abs(_time - _time_of_next_beat)
			if difference <= delta || _time > _time_of_next_beat:
				beat.emit()
				_time_of_next_beat += seconds_per_beat
