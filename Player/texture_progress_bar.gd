# texture_progress_bar.gd
extends TextureProgressBar

# How fast the progress bar fades in/out
@export var fade_speed: float = 5.0

# Using null as default since you don't have textures yet
@export var good_effect_icon: Texture2D = null 
@export var bad_effect_icon: Texture2D = null 

# Reference to the TextureRect child node that displays the icon
@onready var icon_display: TextureRect = $TextureRect 

# Store the Timer node currently being tracked
var current_effect_timer: Timer = null
# Store the initial duration of the current effect for max_value calculation
var current_max_duration: float = 0.0

func _ready():
	# Hide the UI at the start
	modulate.a = 0.0
	visible = false
	# Check for the icon child node setup
	if icon_display == null:
		push_error("StatusTimer node requires a child TextureRect node named 'TextureRect' for the icon.")

func _process(delta):
	if current_effect_timer != null:
		# Update progress value based on remaining time
		value = current_effect_timer.time_left
		
		# If the progress bar is active, ensure it's fully visible
		if modulate.a < 1.0:
			modulate.a = lerp(modulate.a, 1.0, delta * fade_speed)
			visible = true
	
	else:
		# If no timer is active, fade out the progress bar
		if modulate.a > 0.0:
			modulate.a = lerp(modulate.a, 0.0, delta * fade_speed)
			if modulate.a < 0.05:
				modulate.a = 0.0
				visible = false


# Called by the Manager scripts to start tracking an effect
func start_tracking_effect(timer: Timer, is_good_effect: bool) -> void:
	current_effect_timer = timer
	current_max_duration = timer.time_left
	
	# Set up the progress bar values
	max_value = current_max_duration
	value = current_max_duration
	
	# Set the icon and tint color
	if icon_display:
		# Use a null check here to handle missing textures
		icon_display.texture = good_effect_icon if is_good_effect else bad_effect_icon
		
		# Set a color tint regardless of the icon being present
		icon_display.modulate = Color.GREEN if is_good_effect else Color.RED
	
	# Connect to the timer's timeout signal to stop tracking when the effect ends
	if timer.timeout.is_connected(stop_tracking):
		timer.timeout.disconnect(stop_tracking)
		
	timer.timeout.connect(stop_tracking)


# Called when the timer times out (via signal connection)
func stop_tracking() -> void:
	current_effect_timer = null
