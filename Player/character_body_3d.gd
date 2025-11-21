extends CharacterBody3D

@export_group("Keybinds")
@export_subgroup("Movement")
@export var move_left: String = "a_key"
@export var move_right: String = "d_key"
@export var move_forward: String = "w_key"
@export var move_backward: String = "s_key"
@export var crouch: String = "c_key"
@export var jump: String = "space_key"
@export var melee_attack: String = "left_click"


@export_subgroup("Interface")
@export var free_cursor: String = "esc_key"
@export var log_data: String = "p_key"
@export var test_key: String = "f_key"

@export_group("Settings")
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.3
@export var default_height: float = 2.0
@export var crouch_height: float = 1.0
@export var transition_speed: float = 10.0
@export var ProjectileScene: PackedScene
@export_subgroup("Melee Settings")
@export var attack_range: float = 5.0 # Max distance to hit an enemy
@export var melee_cooldown: float = 0.5 # Time between attacks
@export var enemy_collision_layer: int = 3 # The physics layer where your enemies are located

var is_attacking: bool = false # Tracks attack status to enforce cooldown


var current_speed: float
var current_jump_velocity: float 
var current_mouse_sensitivity: float 

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var head: Node3D
var ray: RayCast3D
var camera: Camera3D
var crouched: bool = false
var can_look: bool = true
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_shape: MeshInstance3D = $MeshInstance3D
var original_camera_y: float
var target_height: float

@export var fire_rate: float = 0.5
var can_shoot: bool = true

const ACTION_SHOOT = "shoot"

# Reference to our power-up and debuff manager node
@onready var powerup_manager = $PowerUpManager
@onready var debuff_manager = $DebuffManager


func _ready():
	current_speed = speed
	current_jump_velocity = jump_velocity
	current_mouse_sensitivity = mouse_sensitivity
	
	head = get_node("Head")
	camera = get_node("Head/Camera3D")
	ray = get_node("Head/Camera3D/RayCast3D")

# Let the powerup manager know who owns it
	if powerup_manager and powerup_manager.has_method("init"):
		powerup_manager.init(self)
		
#Let the debuff manager establish itself in heirarchy
	if debuff_manager and debuff_manager.has_method("init"):
		debuff_manager.init(self)

	if not (collision_shape.shape is CapsuleShape3D and mesh_shape.mesh is CapsuleMesh):
		push_error("Assigned nodes must have CapsuleShape3D and CapsuleMesh resources.")
		return

	original_camera_y = head.position.y
	target_height = default_height

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		
		
func _input(event: InputEvent):
	#Mouse Movements
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and can_look:
		rotate_y(deg_to_rad(-event.relative.x * current_mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * current_mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

		
	#Key Presses
	if event is InputEventKey:
		if Input.is_action_just_pressed(free_cursor):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if Input.is_action_just_pressed(log_data):
			print("Speed: ", current_speed)
			print("Jump: ", current_jump_velocity)
			
	if Input.is_action_just_pressed(melee_attack):
		perform_crosshair_melee_attack()
			
	#Mouse Clicks
	if event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed(jump) and is_on_floor():
		velocity.y = current_jump_velocity
		#print(current_speed)

	crouched = Input.is_action_pressed(crouch)
	target_height = crouch_height if crouched else default_height

	var current_height = collision_shape.shape.height
	var new_height = lerp(current_height, target_height, delta * transition_speed)

	collision_shape.shape.height = new_height
	mesh_shape.mesh.height = new_height

	var new_camera_y = lerp(
		head.position.y,
		original_camera_y * (new_height / default_height),
		delta * transition_speed
	)
	head.position.y = new_camera_y

# Movement using current_speed
	var input_dir = Input.get_vector(move_left, move_right, move_forward, move_backward)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and not crouched:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	elif direction and crouched:
		velocity.x = direction.x * current_speed * 0.75
		velocity.z = direction.z * current_speed * 0.75
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()


# Wrapper so power-ups can call a single function
func apply_power_up(effect_name: String, value: float, duration: float) -> void:
	if powerup_manager:
		powerup_manager.apply_power_up(effect_name, value, duration)
		
		
		
		
#func apply_speed_boost(amount: float, duration: float) -> void:
	#current_speed = speed * amount
	#get_tree().create_timer(duration).timeout.connect(func(): current_speed = speed)
	#
#func apply_jump_boost(amount: float, duration: float) -> void:
	#current_jump_velocity = jump_velocity * amount
	#get_tree().create_timer(duration).timeout.connect(func(): current_jump_velocity = jump_velocity)
	
	
#Debuff application wrapper
func apply_debuff(debuff_name: String, value: float, duration: float) -> void:
	print(debuff_name, " Applied")
	if debuff_manager:
		debuff_manager.apply_debuff(debuff_name, value, duration)
	
	
func check_speed():
	print_debug("Speed: ", speed)
	
	
# --- New Melee Function ---
func perform_crosshair_melee_attack():
	if is_attacking:
		return

	# 1. Start Cooldown and Attack State
	is_attacking = true
	var cooldown_timer = get_tree().create_timer(melee_cooldown, false)
	cooldown_timer.timeout.connect(func(): is_attacking = false)

	# Optional: Trigger your arm swing animation here
	# Example (assuming PlayerArm has an AnimationPlayer):
	# $Head/Camera3D/PlayerArm/AnimationPlayer.play("swing")
	
	# 2. Calculate Ray Origin and End Point (using Camera)
	var ray_origin = camera.global_position
	# The camera's negative Z-axis is the forward direction
	var ray_direction = -camera.global_transform.basis.z 
	var ray_end = ray_origin + ray_direction * attack_range

	# 3. Setup Physics Query
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	# Exclude the player's own body from the check
	query.exclude = [self] 
	
	# Only check objects on the designated enemy layer
	# Collision layers use a bitmask (1 << layer_number - 1)
	query.collision_mask = (1 << (enemy_collision_layer - 1))
	
	# 4. Perform the Raycast
	var result = space.intersect_ray(query)

	# 5. Process the Result
	if result.is_empty() == false:
		var hit_body = result.collider
		
		# Check if the hit object is in the "enemy" group (best practice)
		if hit_body.is_in_group("enemy"):
			print_debug("Melee hit target: ", hit_body.name)
			
			# Call a damage function on the entity
			if hit_body.has_method("take_damage"):
				hit_body.take_damage(25) # Example damage
				
			# Optional: Add hit effect at result.position
			# You can use the raycast info for a directional particle effect
			# print("Hit Position: ", result.position)
	
