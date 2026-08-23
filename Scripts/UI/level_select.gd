extends Control
class_name LevelSelect
## Where the player selects which level to play.

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
@onready var _level_scroll_margin_animation = $CanvasLayer/LevelScrollMargin/ScrollMarginModifier
@onready var _plays_button = $CanvasLayer/PlaysPanel/PlaysButton

@onready var _plays_scroll_box = $CanvasLayer/PlaysPanel/MarginContainer/VBoxContainer/ScrollContainer
@onready var _plays_scroll_margin = $CanvasLayer/PlaysPanel/MarginContainer/VBoxContainer/ScrollContainer/ScrollbarMargin

@onready var _mods_panel = $CanvasLayer/ModsPanel
@onready var _mods_animation = $CanvasLayer/ModsPanel/ModsAnimationPlayer
@onready var _mod_button_container = $CanvasLayer/ModsPanel/VBoxContainer/MarginContainer/ScrollContainer/ScrollbarMargin/ModButtonContainer
@onready var _mod_icon_container = $CanvasLayer/ModsPanel/ModIcons/IconContainer
@onready var _mod_bar = $CanvasLayer/ModsPanel/ModBar
@onready var _score_multiplier_label = $CanvasLayer/ModsPanel/ModBar/PanelContainer/MarginContainer/MultiplierLabel

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Emitted when the close button is pressed, or esc is pressed.
signal selection_closed

## Emitted when a level has been focused for long enough that a preview of the
## song should play.
signal preview_level_song(level_info: LevelInfo, offset: float)

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

## The size of mod icons visible at the top of the modifiers panel.
const MOD_ICON_SIZE: int = 40

## Additional level scroll margin when the plays panel is open.
const LEVEL_SCROLL_MARGIN_PLAYS = 300

## How many seconds you aim to take to display all the plays for a level.
## If there are a crazy amount of plays this time will be disregarded.
const TARGET_TIME_TO_DISPLAY_PLAYS: float = 0.25

## The last position the player was on the level selection menu (on the 
## scrollbar).
static var _last_level_select_position: int = 0

## If true, the play panel opens by itself. Otherwise, it only opens when 
## clicked.
static var _auto_open_play_panel := true

## All the buttons to choose a level sorting method from.
var _sort_buttons: Array[Button]

var _level_button_scene = preload("res://Scenes/UI/level_button.tscn")
var _play_display_scene = preload("res://Scenes/UI/play_data_display.tscn")

## An array of all level info
var _levels: Array[LevelInfo]

## Access the array of PlayData for a level given the level filename.
var _level_plays: Dictionary

## When true, any play display data that was gradually being loaded will halt.
var _halt_plays_display_spawns := false

## The level that plays are being displayed for currently. Could be null.
var _current_plays_level: LevelInfo

## True when the mods panel is open. Ensures the plays panel cannot be opened
## while the mods panel already is.
var _mods_panel_open := false


## Load all levels and create buttons for them.
func _ready() -> void:
	_scroll_box.set_deferred("scroll_vertical", _last_level_select_position)
	
	if !SaveLoad.save_data.tutorial_played:
		_plays_panel.hide()
		_sort_button.hide()
		_mods_panel.hide()
	else:
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
	
	# Make level buttons.
	LevelButton.use_primary_colour = true
	for level in _levels:
		if level.is_valid():
			var level_button: LevelButton = _level_button_scene.instantiate()
			level_button.setup(level)
			level_button.button_pressed.connect(_level_button_pressed)
			level_button.button_hovered.connect(_display_plays)
			level_button.button_hovered.connect(
				func(info: LevelInfo) -> void: 
					if (LevelInfo.last_played_in_menu.song_name != info.song_name
						|| LevelInfo.last_played_in_menu.length != info.length):
						var offset: float
						if info.version == "Tutorial":
							# This is because the length value for levels
							# isn't actually the length of the song that is
							# in the level, it's an estimate of how long the
							# tutorial will take.
							offset = info.song.get_length() / 2
						else:
							offset = info.length / 2
						preview_level_song.emit(info, offset)
			)
			_level_button_container.add_child(level_button)
			if (LevelInfo.last_played != null
					and level.file_name == LevelInfo.last_played.file_name 
					and GameLevel.last_offset > 0):
				level_button.enable_practice_mode()
	
	# If this isn't true, then there are no sort buttons yet so we can't try to
	# sort anything (will get an out of bounds error since the buttons are 
	# references in that func).
	if SaveLoad.save_data.tutorial_played:
		_sort_levels_by_comparator(SaveLoad.save_data.sorting_method)
	
	# This triggers a margin to change to make room for a visible scroll bar.
	var v_scroll_bar: VScrollBar = _plays_scroll_box.get_v_scroll_bar()
	v_scroll_bar.visibility_changed.connect(_plays_scroll_bar_visibility_changed)
	
	# Give ModManager mod button references and attach all button signals.
	var mod_buttons: Array[ModButton] = []
	for mod_button: ModButton in _mod_button_container.get_children():
		mod_buttons.push_back(mod_button)
		mod_button.pressed.connect(_mod_button_pressed)
		mod_button.mouse_entered.connect(_mod_button_hovered)
		
		_update_active_mod_icons()
	ModManager.mod_buttons = mod_buttons
	ModManager.set_mod_button_states()
	
	if ModManager.has_active_mods():
		_show_updated_mod_bar()
	
	# Request level plays in the background.
	SaveLoad.request_plays(_levels)


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_close_dialog"):
		if UI_is_visible():
			if _mods_panel_open:
				_menu_click_sound.play()
				_close_mods_panel()
				accept_event()
	if event.is_action_pressed("toggle_mods_panel"):
		_menu_click_sound.play()
		if _mods_panel_open:
			_close_mods_panel()
		else:
			_menu_click_sound.play()
			_open_mods_panel()
		accept_event()
	if event.is_action_pressed("toggle_plays_panel"):
		_menu_click_sound.play()
		if _plays_panel_is_open():
			_close_plays_panel()
			_auto_open_play_panel = false
		else:
			_open_plays_panel()
			_auto_open_play_panel = true
		accept_event()


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
	
	# Recolour levels so they alternate title colours.
	LevelButton.use_primary_colour = true
	for button: LevelButton in _level_button_container.get_children():
		button.update_title_color()
	
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
	_mods_panel.hide()
	
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
	_scroll_box.mouse_filter = _scroll_box.MOUSE_FILTER_STOP
	
	if SaveLoad.save_data.tutorial_played:
		_plays_panel.show()
		_sort_button.show()
		_mods_panel.show()
	
	# Mod panel was in the middle of moving, nah bro put it back in its place.
	if _mods_animation.is_playing():
		_mods_animation.play("RESET")
	
	# In the event that the theme colors changed.
	LevelButton.use_primary_colour = true
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
	_close_mods_panel()
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
	return a.modded_info.speed < b.modded_info.speed


## Compares 2 levels based on their BPM, from low to high.
static func _compare_level_bpm(a: LevelButton, b: LevelButton) -> bool:
	return a.modded_info.bpm < b.modded_info.bpm


## Compares 2 levels based on their difficulty, from low to high.
static func _compare_level_difficulty(a: LevelButton, b: LevelButton) -> bool:
	return a.modded_info.difficulty < b.modded_info.difficulty


## Compares 2 levels based on their damage, from low to high.
static func _compare_level_damage(a: LevelButton, b: LevelButton) -> bool:
	return a.modded_info.damage < b.modded_info.damage


## Compares 2 levels based on their length (in seconds), from low to high.
static func _compare_level_length(a: LevelButton, b: LevelButton) -> bool:
	return a.modded_info.length < b.modded_info.length


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
		
		var plays: Array[PlayData]
		# Check if the plays have already been loaded.
		if _level_plays.has(level_info.file_name):
			plays = _level_plays.get(level_info.file_name)
		# If they haven't, attempt to load them, then save them to the dict.
		else:
			plays = SaveLoad.load_plays(level_info)
			_level_plays.set(level_info.file_name, plays)
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
			
			# Stop the previous spawn_nodes func.
			_halt_plays_display_spawns = true
			await get_tree().process_frame
			_halt_plays_display_spawns = false
			_spawn_plays_nodes_over_time(plays, TARGET_TIME_TO_DISPLAY_PLAYS)


func _spawn_plays_nodes_over_time(plays: Array[PlayData], target_duration: float) -> void:
	# If the framerate is low enough that the target quantity is higher than 5 per frame, still only
	# spawn 5 per frame. It will just spawn them all in slower.
	const MAXIMUM_TARGET_QUANTITY = 5
	
	# Use the target FPS to gauge how many play display nodes can be added to the scene per frame
	# in a timely fashion.
	var fps = Engine.max_fps
	if fps == 0 and DisplayServer.window_get_vsync_mode() != DisplayServer.VSyncMode.VSYNC_DISABLED:
		fps = DisplayServer.screen_get_refresh_rate()
	
	var target_quantity_per_frame = int(ceil(plays.size() / target_duration / fps))
	target_quantity_per_frame = min(target_quantity_per_frame, MAXIMUM_TARGET_QUANTITY)
	
	var play_display: PlayDataDisplay
	for i in range(plays.size()):
		if _halt_plays_display_spawns:
			break
		
		play_display = _play_display_scene.instantiate()
		play_display.setup(plays[i])
		_plays_container.add_child(play_display)
		
		# Wait for the next frame before adding the next child
		if i % target_quantity_per_frame == 0:
			await get_tree().process_frame


## Returns if the plays panel is currently open.
func _plays_panel_is_open() -> bool:
	return _plays_button.text.contains(">")


func _open_plays_panel() -> void:
	if !_plays_panel_is_open():
		_level_scroll_margin_animation.play("slide_left")
	_plays_panel_animation.play("RESET") # So if it was playing, it starts over.
	_plays_panel_animation.play("popout")
	_plays_button.text = " > "


func _close_plays_panel() -> void:
	if _plays_panel_is_open():
		_plays_panel_animation.play_backwards("popout")
		_level_scroll_margin_animation.play_backwards("slide_left")
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
	if !_plays_panel_is_open() && !_plays_panel_animation.is_playing():
		_menu_click_sound.play()
		_open_plays_panel()
		_auto_open_play_panel = true


func _open_mods_panel() -> void:
	_mods_panel_open = true
	_mods_animation.play("popup")


func _close_mods_panel() -> void:
	_mods_panel_open = false
	_mods_animation.play_backwards("popup")
	
	_apply_mods_to_level_buttons()
	# Since tutorial isn't affected by mods we have to sort levels again.
	_sort_levels_by_comparator(SaveLoad.save_data.sorting_method)


## For each level button, update its stats according to current active mods.
func _apply_mods_to_level_buttons() -> void:
	for button: LevelButton in _level_button_container.get_children():
		if button.level_info.version != "Tutorial":
			button.apply_active_mods()
			button.update_labels()


func _on_mods_button_pressed() -> void:
	_menu_click_sound.play()
	if _mods_panel_open:
		_close_mods_panel()
	else:
		_open_mods_panel()


func _on_mods_close_button_pressed() -> void:
	_menu_click_sound.play()
	_close_mods_panel()


## Toggle a mod to active or inactive through the ModManager.
func _mod_button_pressed(mod: ModManager.ModType) -> void:
	_menu_click_sound.play()
	ModManager.toggle_mod_active(mod)
	_update_active_mod_icons()
	if ModManager.has_active_mods():
		_show_updated_mod_bar()
	else:
		_mod_bar.hide()


## For each active mod, show its icon in the top of the modifiers panel.
func _update_active_mod_icons() -> void:
	# Before updating the icons, make sure they're in the right order.
	ModManager.fix_mod_order()
	
	var icons: Array[Texture2D] = ModManager.get_active_mod_icons()
	
	# Clear existing icons.
	for child in _mod_icon_container.get_children():
		_mod_icon_container.remove_child(child)
	
	# Add current active icons as TextureRect nodes.
	for icon in icons:
		var texture_rect = TextureRect.new()
		texture_rect.texture = icon
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		texture_rect.custom_minimum_size.x = MOD_ICON_SIZE
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mod_icon_container.add_child(texture_rect)


func _mod_button_hovered() -> void:
	_menu_focus_sound.play()


func _on_clear_mods_button_pressed() -> void:
	_menu_click_sound.play()
	ModManager.clear_all_mods()
	_update_active_mod_icons()
	_apply_mods_to_level_buttons() # This will reset their values to normal.
	# Gotta resort since the dumb tutorial isn't affected by mods.
	_sort_levels_by_comparator(SaveLoad.save_data.sorting_method) 
	_mod_bar.hide()


## Update the mod bar and then make it visible, displaying the current score
## multiplier and the clear mods button.
func _show_updated_mod_bar() -> void:
	_score_multiplier_label.text = "%.2fx score" % ModManager.get_score_multiplier()
	_mod_bar.show()
