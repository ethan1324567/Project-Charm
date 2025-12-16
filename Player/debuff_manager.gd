extends Node
class_name DebuffManager

var owner_player: CharacterBody3D
var status_timer_ui: TextureProgressBar # <-- NEW: Reference to the UI node
var active_debuff := {}  # {effect_name: {value: float, timer: Timer}}

func init(player: CharacterBody3D, ui: TextureProgressBar):
	owner_player = player
	status_timer_ui=ui
	

func apply_debuff(effect_name: String, value: float, duration: float) -> void:
	match effect_name:
		"stun":
			owner_player.current_speed *= value
			owner_player.current_jump_velocity *= value
			owner_player.current_mouse_sensitivity *= value/2
		"slow":
			owner_player.current_speed *= value
			owner_player.current_jump_velocity *= value
		"freeze":
			owner_player.current_speed = 0
			owner_player.current_jump_velocity = 0
			owner_player.can_look = false
# add more effects here
	
	if active_debuff.has(effect_name):
		var existing_data = active_debuff[effect_name]
		existing_data["timer"].stop()
		existing_data["timer"].start(duration)
		active_debuff[effect_name]["timer"].stop()
		active_debuff[effect_name]["timer"].start(duration)
		if status_timer_ui.current_effect_timer == existing_data["timer"]:
			status_timer_ui.start_tracking_effect(existing_data["timer"], false)
	else:
		var timer = Timer.new()
		timer.one_shot = true
		timer.timeout.connect(func(): _remove_debuff(effect_name, value))
		add_child(timer)
		timer.start(duration)
		active_debuff[effect_name] = {"value": value, "timer": timer}
		status_timer_ui.start_tracking_effect(timer, false) # 'false' for bad effect
		
func _remove_debuff(effect_name: String, value: float) -> void:
	match effect_name:
		"stun":
			owner_player.current_speed /= value
			owner_player.current_jump_velocity /= value
			owner_player.current_mouse_sensitivity /= value/2
		"slow":
			owner_player.current_jump_velocity /= value
		"freeze":
			owner_player.current_speed = owner_player.speed
			owner_player.current_jump_velocity = owner_player.jump_velocity
			owner_player.can_look = true
# reverse other effects here
	active_debuff.erase(effect_name)
