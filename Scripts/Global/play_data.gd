class_name PlayData
extends Resource
## Stores all data for an individual play of a level, including score, combo, 
## accuracy, etc.

## The score for this play, including all bonuses.
@export var score: int = 0

## The number of bits that have been correctly clicked since the last miss.
@export var combo: int = 0

## The highest combo achieved in this play.
@export var max_combo: int = 0

## The total accuracy of all clicks in this play.
@export var accuracy: float = 100

# Tracking the amount of each click quality.
## The number of perfect clicks made in this play.
@export var perfect_clicks: int = 0
## The number of good clicks made in this play.
@export var good_clicks: int = 0
## The number of okay clicks made in this play.
@export var okay_clicks: int = 0
## The number of missed bits in this play.
@export var missed_clicks: int = 0
## The number of error clicks made in this play.
@export var error_clicks: int = 0
