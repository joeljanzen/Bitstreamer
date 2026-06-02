extends Node
## Holds game settings for the player. These persist throughout levels.

# UI options
## Toggles the level UI
var level_UI_enabled := true

# Aesthetic variables.
## The strength of bloom.
var bloom_strength := 1

## Toggles Flowerwall CRT shader.
var _crt_effect := true

## The CRT shader singleton.
var _crt_shader: flowerwallCRT


## Connect the Flowerwall CRT script when it is loaded.
func connect_crt_shader(crt_shader: flowerwallCRT):
	_crt_shader = crt_shader
	if !_crt_effect:
		_crt_shader.disable_shader()


## Set the CRT effect on or off.
func set_crt_effect(enabled: bool):
	if enabled and !_crt_shader.is_enabled:
		_crt_shader.enable_shader()
	elif _crt_shader.is_enabled:
		_crt_shader.disable_shader()
