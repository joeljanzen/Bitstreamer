extends Node
## global signals

## score was gained.
## provides the amount of score (can be negative)
signal score(amount: int)
## a bit has been missed.
## provides the damage that is dealt as a result
signal miss(damage: int)
