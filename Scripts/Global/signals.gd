extends Node
## Global signals used in gameplay.

## Score was gained [Bit]. Provides the total amount of score, and the raw amount of 
## score before any bonuses.
signal scored(amount: int, raw_amount: int)

## A bit has been missed. Provides the damage that is dealt as a result.
signal missed(damage: int)

## The level has been failed.
signal failed()
