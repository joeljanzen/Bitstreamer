class_name UnstableMod
extends Node
## Mod that makes failing immediate after a single error or miss.

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.UNSTABLE

func mod_damage(_base_damage: int) -> int:
	return 100


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier


## A mod simply having this method will enable the damage.
func enable_enters_and_backs_damage() -> void:
	pass
