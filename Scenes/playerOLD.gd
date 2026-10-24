class_name PlayerOLD
extends CharacterBody2D


enum State { IDLE, RUN, JUMP, FALL }

#signal state_changed(old_state: int, new_state: int)
#signal double_jumped

@export_category("Movement")
@export var run_speed := 350.0
@export var acceleration := 1600.0
@export var friction := 1800.0
@export_range(0.0, 1.0) var air_control := 0.8

@export_category("Jump")
@export var jump_velocity := 600
@export_range(0.0, 1.0) var jump_vel_cut := 0.5  ## Velocity multiplier when jump is released early
@export var max_fall_speed := 700.0
@export var max_air_jumps := 1
@export var drop_through_time := 0.2   ## Seconds a one-way platform is ignored after dropping through it
@export var drop_speed := 150.0        ## Initial downward speed when dropping through

var state: State = State.IDLE

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
#var _interactables: Array[Interactable] = []
var _air_jumps_left := 0

@onready var sprite: Sprite2D = %Sprite
@onready var sensor: Area2D = %Sensor

func _ready() -> void:
	_air_jumps_left = max_air_jumps
	#sensor.area_entered.connect(_on_sensor_area_entered)
	#sensor.area_exited.connect(_on_sensor_area_exited)

# ---------------------------------------------------------------------------
# State machine core
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	match state:
		State.IDLE, State.RUN:
			_state_ground(delta)
		State.JUMP, State.FALL:
			_state_air(delta)
	move_and_slide()

func change_state(new_state: State) -> void:
	if new_state == state:
		return
	var _old: State = state
	state = new_state
	_enter_state(new_state)
	#state_changed.emit(old, new_state)

func _enter_state(new_state: State) -> void:
	match new_state:
		State.JUMP:
			velocity.y = -jump_velocity

# ---------------------------------------------------------------------------
# States
# ---------------------------------------------------------------------------
func _state_ground(delta: float) -> void:
	_apply_gravity(delta)
	var dir := _move_horizontal(delta)
	if is_on_floor():
		_air_jumps_left = max_air_jumps
	if not is_on_floor():
		change_state(State.FALL)
	elif Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_down") and _try_drop_through():
		pass
	elif Input.is_action_just_pressed("jump"):
		change_state(State.JUMP)
	else:
		change_state(State.RUN if dir != 0.0 else State.IDLE)

func _state_air(delta: float) -> void:
	_apply_gravity(delta)
	_move_horizontal(delta)
	# Double jump (works from both JUMP and FALL)
	if Input.is_action_just_pressed("jump") and _air_jumps_left > 0:
		_air_jumps_left -= 1
		if state == State.JUMP:
			velocity.y = -jump_velocity   # already in JUMP, so just re-launch
		else:
			change_state(State.JUMP)
		#double_jumped.emit()
		return
	if state == State.JUMP:
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= jump_vel_cut
		if velocity.y >= 0.0:
			change_state(State.FALL)
	elif is_on_floor():
		change_state(State.IDLE)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + _gravity * delta, max_fall_speed)

func _move_horizontal(delta: float) -> float:
	var dir := Input.get_axis("move_left", "move_right")
	var control := 1.0 if is_on_floor() else air_control
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * run_speed, acceleration * control * delta)
		sprite.flip_h = dir < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)
	return dir

func _try_drop_through() -> bool:
	var platform: OneWayPlatform = _get_one_way_below()
	if platform == null:
		return false
	add_collision_exception_with(platform)
	velocity.y = drop_speed
	change_state(State.FALL)
	get_tree().create_timer(drop_through_time).timeout.connect(_restore_platform.bind(platform))
	return true

func _restore_platform(platform: OneWayPlatform) -> void:
	if is_instance_valid(platform):
		remove_collision_exception_with(platform)

func _get_one_way_below() -> OneWayPlatform:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().dot(up_direction) < 0.7:
			continue
		var platform := c.get_collider() as OneWayPlatform
		if platform and platform.can_drop_through:
			return platform
	return null

func _nearest(areas: Array) -> Area2D:
	var best: Area2D = null
	var best_dist := INF
	for a: Area2D in areas:
		var d := global_position.distance_squared_to(a.global_position)
		if d < best_dist:
			best_dist = d
			best = a
	return best

# ---------------------------------------------------------------------------
# Sensor tracking
# ---------------------------------------------------------------------------
#func _on_sensor_area_entered(area: Area2D) -> void:
	#if area is PathTrigger:
		#_interactables.append(area)
#
#func _on_sensor_area_exited(area: Area2D) -> void:
	#if area is Interactable:
		#_interactables.erase(area)
