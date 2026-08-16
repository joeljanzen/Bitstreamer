class_name OverclockedMod
extends Node
## Mod that makes the level harder (in most cases).

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.OVERCLOCKED


func mod_difficulty(base_difficulty: float) -> float:
	var new_difficulty = base_difficulty + 2
	return min(new_difficulty, LevelInfo.DIFFICULTY_MAX)


func mod_speed(base_speed: float) -> float:
	var new_speed = base_speed + 2
	return min(new_speed, LevelInfo.SPEED_MAX)


func mod_damage(base_damage: int) -> int:
	var new_damage = base_damage * 1.5
	return min(new_damage, LevelInfo.DAMAGE_MAX)
