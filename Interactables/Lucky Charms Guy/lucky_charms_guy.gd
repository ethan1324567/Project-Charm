extends CharacterBody3D

# Lucky Charms Guy AI: starts idle/wandering, then chases the player after a delay

@export var player: Node3D
@export var CHASE_SPEED: float = 3.5
@export var WANDER_SPEED: float = 1.0
@export var CHASE_DISTANCE: float = 50.0 # max distance to consider chasing (safety)
@export var START_CHASE_DELAY: float = 4.0

var _chasing: bool = false
var wander_direction: Vector3 = Vector3.ZERO
var _wander_timer: Timer
var _start_timer: Timer

func _ready() -> void:
	# create timers
	_wander_timer = Timer.new()
	add_child(_wander_timer)
	_wander_timer.wait_time = 2.0
	_wander_timer.timeout.connect(_on_wander_timer_timeout)
	_pick_new_wander_direction()
	_wander_timer.start()

	_start_timer = Timer.new()
	add_child(_start_timer)
	_start_timer.wait_time = START_CHASE_DELAY
	_start_timer.one_shot = true
	_start_timer.timeout.connect(_on_start_chase_timeout)
	_start_timer.start()

func _physics_process(delta: float) -> void:
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not is_on_floor():
		velocity.y -= gravity * delta

	if _chasing:
		_execute_chase()
	else:
		_execute_wander()

	move_and_slide()

func _execute_wander() -> void:
	var target_velocity = wander_direction * WANDER_SPEED
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	if velocity.length_squared() > 0:
		look_at(global_position + wander_direction, Vector3.UP)

func _execute_chase() -> void:
	if not player:
		# try to find the player in the scene tree if not assigned
		player = get_node_or_null("/root/Main/Player") if has_node("/root/Main/Player") else player
	if not player:
		return

	# only chase if within reasonable distance to avoid silly long-range chasing
	var dist = global_position.distance_to(player.global_position)
	if dist > CHASE_DISTANCE:
		# fall back to wandering
		_chasing = false
		_wander_timer.start()
		return

	var raw_dir: Vector3 = player.global_position - global_position
	raw_dir.y = 0
	var direction_to_player = raw_dir.normalized()
	var target_velocity = direction_to_player * CHASE_SPEED
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	if velocity.length_squared() > 0:
		look_at(global_position + direction_to_player, Vector3.UP)

func _on_wander_timer_timeout() -> void:
	_pick_new_wander_direction()

func _pick_new_wander_direction() -> void:
	var random_angle = randf() * TAU
	wander_direction = Vector3(cos(random_angle), 0, sin(random_angle))

func _on_start_chase_timeout() -> void:
	# enable chasing behavior
	_chasing = true
	# stop wandering while chasing
	if _wander_timer:
		_wander_timer.stop()

func force_start_chase() -> void:
	# public method to start chasing immediately
	_start_timer.stop()
	_on_start_chase_timeout()
