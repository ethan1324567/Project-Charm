extends Node
class_name PowerUpManager

var owner_player: CharacterBody3D
var active_powerups := {}  # {effect_name: {value: float, timer: Timer}}

func init(player: CharacterBody3D):
	owner_player = player
	

func apply_power_up(effect_name: String, value: float, duration: float) -> void:
	print_debug("Applying powerup")
	print_debug("Fed parameters - effect_name: ",effect_name, " | value: ", value," | duration: ", duration)
	match effect_name:
		"speed":
			print_debug("Applying speed effect")
			owner_player.current_speed *= value
			owner_player.check_speed()
		"jump":
			owner_player.current_jump_velocity *= value
		_:
			push_warning("Unknow power-up type: %s" % effect_name)
# add more effects here
	
	if active_powerups.has(effect_name):
		active_powerups[effect_name]["timer"].stop()
		active_powerups[effect_name]["timer"].start(duration)
	else:
		var timer = Timer.new()
		timer.one_shot = true
		timer.timeout.connect(func(): _remove_power_up(effect_name, value))
		add_child(timer)
		timer.start(duration)
		active_powerups[effect_name] = {"value": value, "timer": timer}
		
func _remove_power_up(effect_name: String, value: float) -> void:
	match effect_name:
		"speed":
			owner_player.current_speed /= value
		"jump":
			owner_player.current_jump_velocity /= value
# reverse other effects here
	active_powerups.erase(effect_name)
