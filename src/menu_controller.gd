extends Control

# Config file
# Move it into a singleton
var settings_file = ConfigFile.new()

var vsync: int = 0
# Audio settings stored in a Vector3
# - x : General , y : Music , z : SFX
var audio: Vector3 = Vector3(70.0, 70.0, 70.0)
var display_resolution: Vector2i = DisplayServer.screen_get_size()

@onready var resolution_option_button = get_node("%Resolution_Optionbutton")
@onready var option_container = get_node("%OptionContainer")
@onready var main_container = get_node("%MainContainer")


func _get_resolution(index) -> Vector2i:
	if index < 0 or index >= resolution_option_button.get_item_count():
		return Vector2i(1920, 1080)  # Default resolution fallback
	var resolution_arr = resolution_option_button.get_item_text(index).split("x")
	if resolution_arr.size() == 2:
		return Vector2i(int(resolution_arr[0]), int(resolution_arr[1]))
	return Vector2i(1920, 1080)  # Default resolution fallback


func _check_resolution(resolution: Vector2i) -> int:
	for i in range(resolution_option_button.get_item_count()):
		if _get_resolution(i) == resolution:
			return i
	return -1


func _first_time() -> void:
	DisplayServer.window_set_size(DisplayServer.screen_get_size())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_vsync_mode(vsync)

	resolution_option_button.select(_check_resolution(DisplayServer.screen_get_size()))
	
	# Save default settings
	settings_file.set_value("VIDEO", "Resolution", display_resolution)
	settings_file.set_value("VIDEO", "vsync", vsync)
	settings_file.set_value("VIDEO", "Window Mode", "Maximized")
	settings_file.set_value("VIDEO", "Graphics", "Medium")
	settings_file.set_value("VIDEO", "Color blind", "None")

	settings_file.set_value("audio", "General", audio.x)
	settings_file.set_value("audio", "Music", audio.y)
	settings_file.set_value("audio", "SFX", audio.z)

	settings_file.save("res://settings.cfg")


func _load_settings():
	if settings_file.load("res://settings.cfg") != OK:
		_first_time()
	else:
		display_resolution = settings_file.get_value("VIDEO", "Resolution", display_resolution)
		get_window().size = display_resolution

		audio.x = settings_file.get_value("audio", "General", 70.0)
		audio.y = settings_file.get_value("audio", "Music", 70.0)
		audio.z = settings_file.get_value("audio", "SFX", 70.0)

		%General_HScrollBar.value = audio.x
		%Music_HScrollbar.value = audio.y
		%SFX_Hscrollbar.value = audio.z


func _save_settings() -> void:
	settings_file.set_value("VIDEO", "Resolution", display_resolution)
	settings_file.set_value("VIDEO", "vsync", vsync)
	settings_file.set_value("VIDEO", "Window Mode", "Maximized")
	settings_file.set_value("VIDEO", "Graphics", "Medium")
	settings_file.set_value("VIDEO", "Color blind", "None")

	settings_file.set_value("audio", "General", audio.x)
	settings_file.set_value("audio", "Music", audio.y)
	settings_file.set_value("audio", "SFX", audio.z)

	settings_file.save("res://settings.cfg")


func _ready():
	_load_settings()
	var res_index = _check_resolution(display_resolution)
	if res_index != -1:
		resolution_option_button.select(res_index)


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_option_button_pressed():
	option_container.visible = true
	main_container.visible = false


func _on_exit_button_pressed():
	get_tree().quit()


# -- VIDEO TAB --

func _on_resolution_optionbutton_item_selected(index):
	var new_resolution = _get_resolution(index)
	if new_resolution.x > 0 and new_resolution.y > 0:
		get_window().size = new_resolution


func _on_window_mode_optionbutton_item_selected(_index):
	pass  # Implement window mode handling here


func _on_preset_h_slider_value_changed(_value):
	pass  # Implement graphics preset handling here


# -- AUDIO TAB --

func _on_general_h_scroll_bar_value_changed(value):
	audio.x = value


func _on_music_h_scroll_bar_value_changed(value):
	audio.y = value


func _on_sfx_h_scroll_bar_value_changed(value):
	audio.z = value


# -- Save and Exit buttons --

func _on_return_button_pressed():
	main_container.visible = true
	option_container.visible = false


func _on_apply_button_pressed():
	main_container.visible = true
	option_container.visible = false
	_save_settings()


func _on_vsync_option_button_item_selected(index):
	vsync = index
	DisplayServer.window_set_vsync_mode(vsync)
