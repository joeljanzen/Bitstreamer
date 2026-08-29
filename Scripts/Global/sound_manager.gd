extends Node
## Manages the playing of sounds in the game, excluding music (the Conductor 
## class handles that).

static var count = 0

# Menu Bus Sounds.

## Plays the generic menu click sound.
func play_menu_click() -> void:
	print(count)
	count += 1
	$MenuBus/MenuClick.play()


## Plays the generic menu focus sound.
func play_menu_focus() -> void:
	print(count)
	count += 1
	$MenuBus/MenuFocus.play()


## Plays the color selection sound.
func play_color_select() -> void:
	print(count)
	count += 1
	$MenuBus/ColorClick.play()


## Plays the sound to launch a level.
func play_launch_level() -> void:
	print(count)
	count += 1
	$MenuBus/LaunchWoosh.play()

# Gameplay Bus Sounds.

## Plays the sound to click a zero or one bit.
func play_bit_click() -> void:
	print(count)
	count += 1
	$GameplayBus/BitClick.play()


## Plays the sound to click an enter or back bit.
func play_enter_back_click() -> void:
	print(count)
	count += 1
	$GameplayBus/EnterBackClick.play()


## Plays the sound to miss any bit.
func play_bit_miss() -> void:
	print(count)
	count += 1
	$GameplayBus/BitMiss.play()


## Plays the sound to incorrectly click any bit.
func play_error_bit_click() -> void:
	print(count)
	count += 1
	$GameplayBus/ErrorClick.play()


## Plays the sound when there is no bit to click.
func play_empty_bit_click() -> void:
	print(count)
	count += 1
	$GameplayBus/EmptyClick.play()


## Plays the sound to clear a line.
func play_line_clear() -> void:
	print(count)
	count += 1
	$GameplayBus/LineClear.play()
