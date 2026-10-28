class_name Player
extends CharacterBody2D


enum State { IDLE, RUN, JUMP, FALL }
var state: State = State.IDLE

const STAIR_GROUP := &"STAIR"

@onready var sprite: Sprite2D = %Sprite

@export_category("Movement")
@export var run_speed: float = 250.0
@export var acceleration: float = 1200.0
@export var friction: float = 1500.0
@export_range(0.0, 1.0) var air_control: float = 0.75

@export_category("Jump")
@export var jump_velocity: float = 400.0
@export var max_fall_speed: float = 700.0
@export var max_air_jumps: int = 1                  ## Extra jumps allowed in the air (1 = double jump)
@export var drop_through_time := 0.25               ## Seconds a one-way platform is ignored after dropping through it
@export var drop_speed: float = 150.0               ## Initial downward speed when dropping through

@export_category("Stair Movement")
@export var stair_speed: float = 150.0

var jump_cut: float = 0.5     ## Velocity multiplier when jump is released early
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _air_jumps_left: int = 0
var _on_stair: bool = false


func _ready() -> void:
	_air_jumps_left = max_air_jumps - 1
	floor_snap_length = maxf(floor_snap_length, 8.0)  # keeps you glued to the slope and its ends

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE, State.RUN:
			_state_ground(delta)
		State.JUMP, State.FALL:
			_state_air(delta)
	move_and_slide()
	_on_stair = _check_on_stair()

# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------
## Returns true if the player is standing on a body in the "STAIR" group.
## Works like is_on_floor(): updated after every move_and_slide().
func is_on_stair() -> bool:
	return _on_stair

# ---------------------------------------------------------------------------
# States
# ---------------------------------------------------------------------------
func _state_ground(delta: float) -> void:
	var dir: float = 0.0
	if _is_on_sloped_stair():
		# On a stair, movement follows the slope exactly (ZERO when there is no input).
		var stair_velocity: float = _get_stair_velocity()
		velocity.x = stair_velocity
		#dir = signf(stair_velocity)
		#if dir != 0.0:
			#sprite.flip_h = dir < 0.0
	else:
		_apply_gravity(delta)
		dir = _move_horizontal(delta)

	if is_on_floor():
		_air_jumps_left = max_air_jumps - 1
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
		return
	if state == State.JUMP:
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= jump_cut
		if velocity.y >= 0.0:
			change_state(State.FALL)
	elif is_on_floor():
		change_state(State.IDLE)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
## Gravity
func _apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + _gravity * delta, max_fall_speed)

## Input Movement
func _move_horizontal(delta: float) -> float:
	var dir: float = Input.get_axis("move_left", "move_right")
	var control: float = 1.0 if is_on_floor() else air_control
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * run_speed, acceleration * control * delta)
		sprite.flip_h = dir < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)
	return dir

## State
func change_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	if new_state == State.JUMP:
		velocity.y = -jump_velocity

## Stairs
## Probes just below the feet, so it works even while standing still or sliding along the slope.
func _check_on_stair() -> bool:
	if not is_on_floor():
		return false
	var c := move_and_collide(-up_direction * maxf(floor_snap_length, 4.0), true)
	if c == null:
		return false
	if c.get_normal().dot(up_direction) < cos(floor_max_angle) - 0.01:
		return false
	var body := c.get_collider() as Node
	return body != null and body.is_in_group(STAIR_GROUP)

func _is_on_sloped_stair() -> bool:
	return _on_stair and is_on_floor() and absf(get_floor_normal().x) > 0.05

## Velocity along the stair slope for the current left/right input, or ZERO if there is no input.
#func _get_stair_velocity() -> Vector2:
	#var h: float = Input.get_axis("move_left", "move_right")
	#if h == 0.0:
		#return Vector2.ZERO
#
	#var n: Vector2 = get_floor_normal()
	#var slope := Vector2(n.y, -n.x)         # direction along the slope
	#if signf(slope.x) != signf(h):
		#slope = -slope                      # point it the way the player is pressing
	#return slope * stair_speed

func _get_stair_velocity() -> float:
	var h: float = Input.get_axis("move_left", "move_right")
	return h * stair_speed

## OneWayPlatform
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
