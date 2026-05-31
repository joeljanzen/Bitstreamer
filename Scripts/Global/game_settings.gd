extends Node

## Toggles Flowerwall CRT shader.
var _crt_effect = true

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
