extends Resource
class_name SaveDataResource
## Where game data is stored.

## True if the player completed the tutorial.
@export var tutorial_played := false

## Stores the last used sorting method in the level selection scene.
@export var sorting_method: LevelSelect.SortingType = LevelSelect.SortingType.DIFFICULTY
