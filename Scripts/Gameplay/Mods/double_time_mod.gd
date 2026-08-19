class_name DoubleTimeMod
extends Node
## Mod that makes the level playback speed significantly faster.

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.DOUBLE_TIME


func mod_playback_speed(base_speed: float) -> float:
	return base_speed * 1.5
