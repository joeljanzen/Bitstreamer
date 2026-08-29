extends Node
## Manages the playing of sounds in the game, excluding music (the Conductor 
## class handles that).

@onready var _score_hit: AudioStreamPlayer = $GameplayBus/ScoreHit

# Menu Bus Sounds.

## Plays the generic menu click sound.
func play_menu_click() -> void:
	$MenuBus/MenuClick.play()


## Plays the generic menu focus sound.
func play_menu_focus() -> void:
	$MenuBus/MenuFocus.play()


## Plays the color selection sound.
func play_color_select() -> void:
	$MenuBus/ColorClick.play()


## Plays the sound to launch a level.
func play_launch_level() -> void:
	$MenuBus/Launch.play()


## Plays the woosh sound for transitions.
func play_woosh() -> void:
	$MenuBus/Woosh.play()


## Plays the mod activation sound.
func play_mod_activate() -> void:
	$MenuBus/ModActivate.play()


## Plays the mod deactivation sound.
func play_mod_deactivate() -> void:
	$MenuBus/ModDeactivate.play()

# Gameplay Bus Sounds.

## Plays the sound to click a zero or one bit.
func play_bit_click() -> void:
	$GameplayBus/BitClick.play()


## Plays the sound to click an enter or back bit.
func play_enter_back_click() -> void:
	$GameplayBus/EnterBackClick.play()


## Plays the sound to miss any bit.
func play_bit_miss() -> void:
	$GameplayBus/BitMiss.play()


## Plays the sound to incorrectly click any bit.
func play_error_bit_click() -> void:
	$GameplayBus/ErrorClick.play()


## Plays the sound when there is no bit to click.
func play_empty_bit_click() -> void:
	$GameplayBus/EmptyClick.play()


## Plays the sound to clear a line.
func play_line_clear() -> void:
	$GameplayBus/LineClear.play()


## Plays the score increase sound when a level is completed.
func play_score_increase() -> void:
	$GameplayBus/ScoreIncrease.play()


## Plays the score hit sound when the final score is revealed. Pass true to get
## the sound that plays for a perfect score (100% accuracy).
func play_score_hit(full_combo: bool = false, perfect: bool = false) -> void:
	if full_combo and perfect:
		_score_hit.stream = load("res://Resources/Audio/SFX/ScoreHitPerfect.wav")
	elif full_combo:
		_score_hit.stream = load("res://Resources/Audio/SFX/ScoreHitFC.wav")
	else:
		_score_hit.stream = load("res://Resources/Audio/SFX/ScoreHit.wav")
	_score_hit.play()
