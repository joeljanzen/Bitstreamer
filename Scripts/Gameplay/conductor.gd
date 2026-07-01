class_name Conductor
extends AudioStreamPlayer
## Controls the timing 

## A precisely timed event trigger, set to be emitted after a given delay by the
## set_timed_event function. The index, starting at 0, indicates a specific
## timed event in the song, allowing the ability to send timed events for any
## point in the song, not just in order from the start.
signal timed_event(event_index: int)

## The current time in the song being played.
var _time: float

## The time in the song being played that a timed_event should be triggered.
var _time_delay_ends := 0.0

## Signifies that there is actually a delay that needs to emit a timed_event.
var _waiting_for_delay := false

## No more timing events are to be sent, so we can stop checking.
var _done_timings = false

## The index of the timing event to be sent out next.
var _timing_event_index: int = 0

var TEST = 0


## Set the song to play.
func set_song(song: AudioStream) -> void:
	stream = song


## Play the song with a given offset value in seconds, and the index of the
## next event that should be played.
## Use this function to play the conductor with no offset by passing no 
## arguments, instead of calling the inherited play() function.
func play_with_offset(offset: float = 0, event_index: int = 0) -> void:
	_time_delay_ends = 0
	_timing_event_index = event_index
	play(offset)


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


## Tell the conductor it doesn't need to time any more events.
func done_timings() -> void:
	_done_timings = true


## Most accurately measures the current song time and sends timed events based
## on that time.
func _physics_process(delta: float) -> void:
	if !_done_timings and playing:
		_time = get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		_time -= AudioServer.get_output_latency()
		
		if _time > 0:
			# If the difference between current time and time of delay end is within
			# the length of time since the last time _process was called (which is the
			# value of delta), we treat it as reaching the delay end.
			var difference = abs(_time - _time_delay_ends)
			if (difference <= delta || _time > _time_delay_ends) and _waiting_for_delay:
				_waiting_for_delay = false
				timed_event.emit(_timing_event_index)
				#print("sending timed event at %f" % _time)
				_timing_event_index += 1
