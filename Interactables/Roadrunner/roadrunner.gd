class_name Roadrunner
extends CharacterBody3D

@export var player: Node3D

@export var WANDER_SPEED: float = 2.0
@export var FLEE_SPEED: float = 4.5
@export var FLEE_DISTANCE: float = 5.0
@export var SAFE_DISTANCE: float = 20.0
@export var WANDER_INTERVAL: float = 3.0

enum State { WANDER, FLEE }

var current_state: State = State.WANDER
var wander_direction: Vector3 = Vector3.ZERO
var _wander_timer: Timer

func _ready() -> void:
	_wander_timer = Timer.new()
	add_child(_wander_timer)
	_wander_timer.wait_time = WANDER_INTERVAL
	_wander_timer.timeout.connect(_on_wander_timer_timeout)
	_pick_new_wander_direction()
	_wander_timer.start()

func _physics_process(delta: float) -> void:
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not player:
		return

	_update_state()

	match current_state:
		State.WANDER:
			_execute_wander()
		State.FLEE:
			_execute_flee()
	
	move_and_slide()

func _update_state() -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if current_state == State.WANDER and distance_to_player <= FLEE_DISTANCE:
		current_state = State.FLEE
		_wander_timer.stop()
	elif current_state == State.FLEE and distance_to_player >= SAFE_DISTANCE:
		current_state = State.WANDER
		_wander_timer.start()
		_pick_new_wander_direction()

func _execute_wander() -> void:
	var target_velocity = wander_direction * WANDER_SPEED
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	if velocity.length_squared() > 0:
		look_at(global_position + wander_direction, Vector3.UP)

func _execute_flee() -> void:
	var direction_away = (global_position - player.global_position).normalized()
	var target_velocity = direction_away * FLEE_SPEED
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	if velocity.length_squared() > 0:
		look_at(global_position + direction_away, Vector3.UP)

func _on_wander_timer_timeout() -> void:
	_pick_new_wander_direction()

func _pick_new_wander_direction() -> void:
	var random_angle = randf() * TAU
	wander_direction = Vector3(cos(random_angle), 0, sin(random_angle))
