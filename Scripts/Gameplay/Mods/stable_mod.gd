class_name StableMod
extends Node
## Mod that makes failing impossible.

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.STABLE


func mod_damage(_base_damage: int) -> int:
	return 0


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier * 0.5
