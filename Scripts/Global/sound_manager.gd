extends Node
## Manages the playing of sounds in the game, excluding music (the Conductor 
## class handles that).

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
	$MenuBus/LaunchWoosh.play()

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
