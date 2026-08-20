class_name HalfTimeMod
extends Node
## Mod that makes the level playback speed significantly slower.

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.HALF_TIME	


func mod_playback_speed(base_speed: float) -> float:
	return base_speed * 0.75


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier * 0.5
