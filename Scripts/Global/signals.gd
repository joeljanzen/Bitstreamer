extends Node
## global signals

## score was gained.
## provides the total amount of score, and the raw amount of score before any bonuses
signal score(amount: int, raw_amount: int)
## a bit has been missed.
## provides the damage that is dealt as a result
signal miss(damage: int)
