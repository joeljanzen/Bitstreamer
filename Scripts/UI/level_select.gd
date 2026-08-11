extends Control
class_name LevelSelect
## Where the player selects which level to play.

@onready var _level_scroll_margin = $CanvasLayer/LevelScrollMargin
@onready var _level_button_container = $CanvasLayer/LevelScrollMargin/HBoxContainer/ScrollContainer/MarginContainer/LevelButtonContainer
@onready var _back_button = $CanvasLayer/BackButton
@onready var _scroll_box = $CanvasLayer/LevelScrollMargin/HBoxContainer/ScrollContainer
@onready var _sort_button = $CanvasLayer/SortButton
@onready var _sort_panel = $CanvasLayer/SortPanel
@onready var _sort_button_container = $CanvasLayer/SortPanel/MarginContainer/SortButtonContainer

@onready var _plays_panel = $CanvasLayer/PlaysPanel
@onready var _plays_label = $CanvasLayer/PlaysPanel/MarginContainer/VBoxContainer/PlaysLabel
@onready var _level_label = $CanvasLayer/PlaysPanel/MarginContainer/VBoxContainer/LevelLabel
@onready var _plays_container = $CanvasLayer/PlaysPanel/MarginContainer/VBoxContainer/ScrollContainer/ScrollbarMargin/PlaysContainer
@onready var _plays_panel_animation = $CanvasLayer/PlaysPanel/PlaysAnimationPlayer
@onready var _plays_button = $CanvasLayer/PlaysPanel/PlaysButton

@onready var _plays_scroll_box = $CanvasLayer/PlaysPanel/MarginContainer/VBoxContainer/ScrollContainer
@onready var _plays_scroll_margin = $CanvasLayer/PlaysPanel/MarginContainer/VBoxContainer/ScrollContainer/ScrollbarMargin

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Emitted when the close button is pressed, or esc is pressed.
signal selection_closed

## The methods of sorting available for levels.
enum SortingType {
	NAME,
	DIFFICULTY,
	SPEED,
	DAMAGE,
	LENGTH,
	BPM,
	BIT_COUNT,
}

## The filenames of all tutorial levels.
const _tutorial_level_filenames: PackedStringArray = [
	"tutorial1.txt",
]

## Level scroll margin when plays panel is closed.
const LEVEL_SCROLL_MARGIN_DEFAULT = 62

## Level scroll margin when the plays panel is open.
const LEVEL_SCROLL_MARGIN_PLAYS = 500

## The last position the player was on the level selection menu (on the 
## scrollbar).
static var _last_level_select_position: int = 0

## All the buttons to choose a level sorting method from.
var _sort_buttons: Array[Button]

var _level_button_scene = preload("res://Scenes/UI/level_button.tscn")
var _play_display_scene = preload("res://Scenes/UI/play_data_display.tscn")

## An array of all level info
var _levels: Array[LevelInfo]

## The level that plays are being displayed for currently. Could be null.
var _current_plays_level: LevelInfo

## If true, the play panel opens by itself. Otherwise, it only opens when 
## clicked.
var _auto_open_play_panel := true


## Load all levels and create buttons for them.
func _ready() -> void:
	_scroll_box.set_deferred("scroll_vertical", _last_level_select_position)
	
	if SaveLoad.save_data.tutorial_played:
		_sort_button.show()
		# Add sort button children
		for child in _sort_button_container.get_children():
			if child is Button:
				_sort_buttons.push_back(child)
		
		_sort_buttons[SaveLoad.save_data.sorting_method].disabled = true
	
	# Load level info
	var level_filenames: PackedStringArray = _tutorial_level_filenames
	if SaveLoad.save_data.tutorial_played:
		level_filenames = DirAccess.get_files_at("res://Levels")
	
	for file in level_filenames:
		_levels.push_back(LevelInfo.new(file))
	
	# Make level buttons
	for level in _levels:
		if level.is_valid():
			var level_button: LevelButton = _level_button_scene.instantiate()
			level_button.setup(level)
			level_button.button_pressed.connect(_level_button_pressed)
			level_button.button_hovered.connect(_display_plays)
			_level_button_container.add_child(level_button)
	
	# If this isn't true, then there are no sort buttons yet so we can't try to
	# sort anything (will get an out of bounds error since the buttons are 
	# references in that func).
	if SaveLoad.save_data.tutorial_played:
		_sort_levels_by_comparator(SaveLoad.save_data.sorting_method)
	
	# This triggers a margin to change to make room for a visible scroll bar.
	var v_scroll_bar: VScrollBar = _plays_scroll_box.get_v_scroll_bar()
	v_scroll_bar.visibility_changed.connect(_plays_scroll_bar_visibility_changed)

## Return the comparator function for the given sorting method.
func _get_sorting_comparator(sorting_method: SortingType) -> Callable:
	match sorting_method:
		SortingType.NAME:
			return _compare_level_name
		SortingType.DIFFICULTY:
			return _compare_level_difficulty
		SortingType.SPEED:
			return _compare_level_speed
		SortingType.DAMAGE:
			return _compare_level_damage
		SortingType.LENGTH:
			return _compare_level_length
		SortingType.BPM:
			return _compare_level_bpm
		SortingType.BIT_COUNT:
			return _compare_level_bit_count
		_:
			return _compare_level_difficulty


## Rearranges the children of the button container based on the sorting type 
## passed.
func _sort_levels_by_comparator(sorting_method: SortingType) -> void:
	# First disable the new button, and enable the previously disabled one.
	_sort_buttons[SaveLoad.save_data.sorting_method].disabled = false
	_sort_buttons[sorting_method].disabled = true
	
	var comparator = _get_sorting_comparator(sorting_method)
	
	var children: Array[Node] = _level_button_container.get_children()
	
	children.sort_custom(comparator)
	
	# Rearrange children appropriately
	for i in range(children.size()):
		_level_button_container.move_child(children[i], i)
	
	# Save this sorting method to load next time.
	SaveLoad.save_data.sorting_method = sorting_method
	SaveLoad.save_game()


## Start the level that has been selected.
func _level_button_pressed(level_info: LevelInfo) -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	
	level_info.load_level_bits_and_delays()
	
	if level_info.is_valid():
		_last_level_select_position = _scroll_box.scroll_vertical
		
		var level_scene: GameLevel = load("res://Scenes/level.tscn").instantiate()
		Bit.in_main_menu = false
		LevelInfo.last_played = level_info
		
		# Attach tutorial script for the tutorial level.
		if level_info.version == "Tutorial":
			level_scene.set_script(load("res://Scripts/Gameplay/tutorial_level.gd"))
		
		get_tree().change_scene_to_node(level_scene)
	else:
		push_error("Failed to load the level!")


## Hides the level select UI.
func hide_UI():
	_back_button.hide()
	_sort_button.hide()
	_level_button_container.hide()
	_plays_panel.hide()
	
	_scroll_box.mouse_filter = _scroll_box.MOUSE_FILTER_IGNORE
	_last_level_select_position = _scroll_box.scroll_vertical
	
	if _sort_panel.visible:
		# Cannot hide right away as that will trigger filter button to 
		# show itself again (through the mouse_exited signal) instead we
		# do it after frame process idk it works ig.
		await get_tree().process_frame
		_sort_panel.hide()


## Shows the level select UI.
func show_UI():
	_back_button.show()
	_level_button_container.show()
	_plays_panel.show()
	_scroll_box.mouse_filter = _scroll_box.MOUSE_FILTER_STOP
	
	if SaveLoad.save_data.tutorial_played:
		_sort_button.show()
	
	# In the event that the theme colors changed.
	for button: LevelButton in _level_button_container.get_children():
		button.update_title_color()
	
	# For some reason scroll pos isn't set properly unless you wait for this.
	await get_tree().process_frame
	_scroll_box.scroll_vertical = _last_level_select_position


## Returns if the UI is currently visible.
func UI_is_visible() -> bool:
	return _level_button_container.visible


func _on_back_button_pressed() -> void:
	hide_UI()
	selection_closed.emit()


func _on_back_button_mouse_entered() -> void:
	_menu_focus_sound.play()


## Show the sort panel.
func _on_sort_button_mouse_entered() -> void:
	_menu_focus_sound.play()
	_sort_panel.show()
	_sort_button.hide()


## Close the sort panel.
func _on_sort_panel_mouse_exited() -> void:
	_sort_panel.hide()
	if UI_is_visible():
		_sort_button.show()

# Various comparator functions, for sorting levels by various properties.

## Compares 2 levels based on their name, in alphabetical order.
static func _compare_level_name(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.song_name < b.level_info.song_name


## Compares 2 levels based on their speed, from low to high.
static func _compare_level_speed(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.speed < b.level_info.speed


## Compares 2 levels based on their BPM, from low to high.
static func _compare_level_bpm(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.bpm < b.level_info.bpm


## Compares 2 levels based on their difficulty, from low to high.
static func _compare_level_difficulty(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.difficulty < b.level_info.difficulty


## Compares 2 levels based on their damage, from low to high.
static func _compare_level_damage(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.damage < b.level_info.damage


## Compares 2 levels based on their length (in seconds), from low to high.
static func _compare_level_length(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.length < b.level_info.length


## Compares 2 levels based on their bit count, from low to high.
static func _compare_level_bit_count(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.bit_count < b.level_info.bit_count

# Various level sorting buttons.

func _on_name_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(SortingType.NAME)


func _on_difficulty_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(SortingType.DIFFICULTY)


func _on_speed_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(SortingType.SPEED)


func _on_damage_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(SortingType.DAMAGE)


func _on_length_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(SortingType.LENGTH)


func _on_bpm_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(SortingType.BPM)


func _on_bit_count_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(SortingType.BIT_COUNT)


## Display the plays for the given level info in the plays panel.
func _display_plays(level_info: LevelInfo) -> void:
	# Only do stuff if we are loading plays for a different level.
	if _current_plays_level != level_info:
		_current_plays_level = level_info
		
		if _auto_open_play_panel:
			_open_plays_panel()
		
		var plays = SaveLoad.load_plays(level_info)
		var play_count = plays.size()
	
		_level_label.text = level_info.song_name + " (" + level_info.version + ")"
		
		for child in _plays_container.get_children():
			_plays_container.remove_child(child)
		
		if plays.is_empty():
			_plays_label.text = "No Plays"
		else:
			if play_count > 1:
				_plays_label.text = str(play_count) + " Plays"
			else:
				_plays_label.text = "1 Play"
			
			# Start with the primary color
			PlayDataDisplay.use_primary = true
			for play in plays:
				var play_display: PlayDataDisplay = _play_display_scene.instantiate()
				play_display.setup(play)
				_plays_container.add_child(play_display)


## Returns if the plays panel is currently open.
func _plays_panel_is_open() -> bool:
	return _plays_button.text.contains(">")


func _open_plays_panel() -> void:
	_plays_panel_animation.play("popout")
	_plays_button.text = " > "


func _close_plays_panel() -> void:
	if _plays_panel_is_open():
		_plays_panel_animation.play_backwards("popout")
		_plays_button.text = " < "


func _on_plays_button_pressed() -> void:
	_menu_click_sound.play()
	_close_plays_panel()
	_auto_open_play_panel = false


func _plays_scroll_bar_visibility_changed() -> void:
	if _plays_scroll_box.get_v_scroll_bar().visible:
		_plays_scroll_margin.add_theme_constant_override("margin_right", 10)
	else:
		_plays_scroll_margin.remove_theme_constant_override("margin_right")


func _on_plays_button_mouse_entered() -> void:
	if !_plays_panel_is_open():
		_menu_click_sound.play()
		_open_plays_panel()
		_auto_open_play_panel = true
