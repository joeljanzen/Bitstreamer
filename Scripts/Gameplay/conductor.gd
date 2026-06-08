class_name Conductor
extends AudioStreamPlayer
## Controls the timing 

## A precisely timed event trigger, set to be emitted after a given delay by the
## set_timed_event function.
signal timed_event

## The current time in the song being played.
var time: float

## The time in the song being played that a timed_event should be triggered.
var time_delay_ends := 0.0

## Signifies that there is actually a delay that needs to emit a timed_event.
var waiting_for_delay := false

## No more timing events are to be sent, so we can stop checking.
var _done_timings = false


## Set the song to play.
func set_song(song: AudioStream) -> void:
	stream = song


## Pause or unpause the song.
func toggle_paused() -> void:
	if stream_paused:
		stream_paused = false
	else:
		stream_paused = true


## Returns the current position in the song.
func get_time() -> float:
	return time


## Given a delay, sends out the delay_end signal once after the delay has 
## passed.
func set_timed_event(delay: float) -> void:
	waiting_for_delay = true
	time_delay_ends += delay


## Tell the conductor it doesn't need to time any more events.
func done_timings() -> void:
	_done_timings = true


## Most accurately measures the current song time and sends timed events based
## on that time.
func _physics_process(delta: float) -> void:
	if !_done_timings:
		time = get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		time -= AudioServer.get_output_latency()

		# If the difference between current time and time of delay end is within
		# the length of time since the last time _process was called (which is the
		# value of delta), we treat it as reaching the delay end.
		var difference = abs(time - time_delay_ends)
		if difference <= delta and waiting_for_delay:
			waiting_for_delay = false
			timed_event.emit()
