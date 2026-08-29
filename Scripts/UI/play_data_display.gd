class_name PlayDataDisplay
extends Control
## Displays the values of a PlayData resource in a panel.

@onready var panel = $Panel
@onready var score_label = $Panel/MarginContainer/VBoxContainer/MainStats/ScoreLabel
@onready var mod_container = $Panel/MarginContainer/VBoxContainer/MainStats/ModContainer
@onready var accuracy_label = $Panel/MarginContainer/VBoxContainer/SecondaryStats/AccuracyLabel
@onready var max_combo_label = $Panel/MarginContainer/VBoxContainer/SecondaryStats/MaxComboLabel
@onready var perfects_label = $Panel/MarginContainer/VBoxContainer/ExtraStats/PerfectsLabel
@onready var goods_label = $Panel/MarginContainer/VBoxContainer/ExtraStats/GoodsLabel
@onready var okays_label = $Panel/MarginContainer/VBoxContainer/ExtraStats/OkaysLabel
@onready var misses_label = $Panel/MarginContainer/VBoxContainer/ExtraStats2/MissesLabel
@onready var errors_label = $Panel/MarginContainer/VBoxContainer/ExtraStats2/ErrorsLabel

@onready var extra_stats = $Panel/MarginContainer/VBoxContainer/ExtraStats
@onready var extra_stats_2 = $Panel/MarginContainer/VBoxContainer/ExtraStats2
@onready var see_more_button = $SeeMoreButton

## How much to darken the pinkified panel displayed for perfect scores.
const PANEL_DARKEN_AMOUNT: float = 0.85

# Some constants to ensure correct sizing, pretty bad implementation
const MINIMUM_Y_SIZE_DEFAULT = 85
const MINIMUM_Y_SIZE_EXPANDED = 135

## The size of mod icons.
const MOD_ICON_SIZE: int = 32

## How many pixels of vertical mouse drag should be ignored.
## NOTE: It is useful to have the Scroll Deadzone property of the scroll
## container this button is in to be the same value. Otherwise you might be able
## to drag buttons around and also click one at the same time.
const _MOUSE_DRAG_DEADZONE = 35

var play_data: PlayData

## True if you can see all of the stats for the play.
var can_see_more := false

## The initial y position a mouse drag is started from.
## Used to detect if a mouse click is for dragging vertically or just a click.
var _initial_drag_y_pos := 0


## Setup the play data display. Call this after instantiation of the scene but 
## before adding as a child to the current scene tree.
func setup(data: PlayData) -> void:
	play_data = data


## Dynamic stylebox colouring.
## Set all label values.
func _ready() -> void:
	custom_minimum_size.y = MINIMUM_Y_SIZE_DEFAULT
	
	score_label.text = str(play_data.score)
	
	# Dynamic colouring depending on the play data.
	var color: Color = GameSettings.zero_bit_colour
	
	# Use white for normal plays if the player is using the perfect color
	# already as their primary theme colour.
	if color == Color(GameSettings.perfect_click_colour):
		color = Color.WHITE
	
	if play_data.accuracy == 100:
		color = Color(GameSettings.perfect_click_colour)
		_recolor_panel(color)
	# Colour the panel with the darkened primary if the play was a full combo.
	elif (play_data.missed_clicks + play_data.error_clicks) == 0:
		if color != Color.WHITE:
			_recolor_panel(color)
		else:
			# The darkened white looks bad so substitute it for this gray.
			_recolor_panel(Color.DIM_GRAY)
	score_label.modulate = color
	
	accuracy_label.text = _trim_decimals(play_data.accuracy) + "% Accuracy"
	max_combo_label.text = "%dx Max Combo" % play_data.max_combo
	perfects_label.text = ("[color=%s]%d Perfect[/color]" % 
	[GameSettings.perfect_click_colour, play_data.perfect_clicks])
	goods_label.text = ("[color=%s]%d Good[/color]" % 
	[GameSettings.good_click_colour, play_data.good_clicks])
	okays_label.text = ("[color=%s]%d Okay[/color]" % 
	[GameSettings.okay_click_colour, play_data.okay_clicks])
	misses_label.text = ("[color=%s]%d Miss[/color]" % 
	[GameSettings.missed_click_colour, play_data.missed_clicks])
	errors_label.text = ("[color=%s]%d Error[/color]" % 
	[GameSettings.incorrect_click_colour, play_data.error_clicks])
	
	_add_mod_icons()


## Ignore a mouse click if it's the start of a drag. If it is a proper click,
## focus the button.
## NOTE: The SeeMoreButton in this scene does not actually trigger anything when
## it is clicked (its signals are not attached to anything), it is only there
## for the visual affects of lightening and darkening the panel to behave like
## a button. This function is what actually catches the mouse click and decides
## whether it is a click on the button or dragging motion to ignore.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_initial_drag_y_pos = event.global_position.y
		elif event.is_released():
			var vertical_distance = abs(_initial_drag_y_pos - event.global_position.y)
			if vertical_distance < _MOUSE_DRAG_DEADZONE:
				_on_display_pressed()


## Show all stats for the play, or hide those extra stats.
func toggle_see_more() -> void:
	if can_see_more:
		see_less()
	else:
		see_more()


## Show all stats for the play.
func see_more() -> void:
	can_see_more = true
	custom_minimum_size.y = MINIMUM_Y_SIZE_EXPANDED
	
	extra_stats.show()
	extra_stats_2.show()


## Hide extra stats for the play.
func see_less() -> void:
	can_see_more = false
	custom_minimum_size.y = MINIMUM_Y_SIZE_DEFAULT
	
	extra_stats.hide()
	extra_stats_2.hide()


## Show all stats for the play, or hide those extra stats.
func _on_display_pressed() -> void:
	SoundManager.play_menu_click()
	toggle_see_more()
	# For the one in the pause screen.
	if get_parent().name == "CurrentPlayContainer":
		PauseUI.expanded_play_display = !PauseUI.expanded_play_display


## Add icons for the active mods from the play.
func _add_mod_icons() -> void:
	if !play_data.mods.is_empty():
		for mod in play_data.mods:
			var texture_rect = TextureRect.new()
			texture_rect.texture = ModManager.get_icon(mod)
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			texture_rect.custom_minimum_size.x = MOD_ICON_SIZE
			mod_container.add_child(texture_rect)


## Recolour the display panel.
func _recolor_panel(color: Color) -> void:
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color.darkened(PANEL_DARKEN_AMOUNT)
	panel.add_theme_stylebox_override("panel", style_box)


## If the float has decimal places, it rounds up to 2 places. Otherwise, it 
## includes no decimal places.
func _trim_decimals(value: float) -> String:
	return str(snappedf(value, 0.01)).rstrip("0").rstrip(".")
