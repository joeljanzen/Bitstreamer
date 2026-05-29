extends Node
## global signals

## score was gained.
## provides the amount of score (can be negative)
signal score(amount: int)
## a bit has been missed.
## provides the damage that is dealt as a result
signal miss(damage: int)

# this may not be used idk
## a bit has been incorrectly clicked.
## provides the base damage that is dealt as a result 
## (this will be multiplied by some value depending on level difficulty)
signal incorrect_click(damage: int)
