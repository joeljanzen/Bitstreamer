class_name ZeroedOutMod
extends Node
## Mod that makes all 0 and 1 bits the same.

## Used to identify this mod in the array of active mods.
var type = ModManager.ModType.ZEROED_OUT


func mod_bits(base_bit: Bit.Type, _last_bit: Bit.Type) -> Bit.Type:
	match base_bit:
		Bit.Type.ONE:
			return Bit.Type.ZERO
		_:
			return base_bit


func mod_score_multiplier(base_multiplier: float) -> float:
	return base_multiplier * 0.75
