class_name CameraFollow
extends Camera2D


@onready var foreground: Sprite2D = %Foreground
@onready var stair_collision: CollisionPolygon2D = %StairCollision
## The StaticBody2D that owns the stair collision polygon.
@onready var stair_body: Node = stair_collision.get_parent()

@export var player: Player

@export_category("Camera Movement")
@export var initial_speed: float = 150.0 ## Speed the camera starts with when it begins moving from rest (pixels/second).
@export var max_speed: float = 500.0 ## Top speed of the camera in pixels/second.
@export var acceleration: float = 150.0 ## Acceleration in pixels/second², applied from initial_speed up to max_speed.
@export var deadzone: float = 15.0 ## Camera stays still while closer than this to the player (pixels).
@export var follow_offset: Vector2 = Vector2.ZERO ## Shifts the camera relative to the player (e.g. look slightly above).
@export var snap_on_ready: bool = true ## Snap to the player instantly when the scene starts.

@export_category("Zoom Settings")
@export var zoom_speed: float = 0.8 ## Max zoom change per second (1.0 = full zoom range in 1 second).
@export var zoom_out_level: Vector2 = Vector2(1.8, 1.8)
@export var zoom_in_level: Vector2 = Vector2(2.3, 2.3)
@export var zoom_start_y: float = 160.0
@export var zoom_end_y: float = 50.0

@export_category("Foreground Fade")
@export var fade_out_gradually: bool = true ## Fade the foreground out smoothly (false = hide instantly).
@export var fade_in_gradually: bool = true ## Fade the foreground in smoothly (false = show instantly).
@export var fade_duration: float = 0.7 ## Seconds for a full fade, used for both fade out and fade in.


var _speed: float = 0.0
var _zoom_t: float = 0.0 ## Current zoom progress: 0.0 = zoom_out_level, 1.0 = zoom_in_level.
var _display_t: float = 0.0
var _fade_tween: Tween


func _ready() -> void:
	if player == null:
		player = get_parent().get_node_or_null("Player") as Player # Fallback: look for a sibling named "Player"
	if player != null and snap_on_ready:
		global_position = player.global_position + follow_offset
	zoom = zoom_out_level


func _physics_process(delta: float) -> void:
	if player == null:
		return
	camera_follow(delta)
	zoom_manager(delta)


func camera_follow(delta: float) -> void:
	var goal: Vector2 = player.global_position + follow_offset
	var to_goal: Vector2 = goal - global_position
	var distance: float = to_goal.length()
	# Inside the deadzone: stop and stay put (no jitter).
	if distance <= deadzone:
		_speed = 0.0
		return
	# Starting from rest: jump straight to the initial speed.
	if _speed < initial_speed:
		_speed = initial_speed
	# Then accelerate toward max speed.
	_speed = minf(_speed + acceleration * delta, max_speed)
	var step: float = minf(_speed * delta, distance)
	global_position += to_goal / distance * step

func zoom_manager(delta: float) -> void:
	# Where the player's height says the zoom should be (0.0 yellow, 1.0 red).
	var y_t: float = clampf(inverse_lerp(zoom_start_y, zoom_end_y, player.global_position.y), 0.0, 1.0)
	if _is_player_on_stairs():
		# Standing on the stairs: target follows height both ways.
		_zoom_t = y_t
	else:
		# Jumping, falling or on other ground: target can only go out, never in.
		_zoom_t = minf(_zoom_t, y_t)
	# Move the displayed zoom toward the target at a fixed rate (smooth in and out).
	_display_t = move_toward(_display_t, _zoom_t, zoom_speed * delta)
	zoom = zoom_out_level.lerp(zoom_in_level, _display_t)


# ---------------------------------------------------------------------------
# Foreground API (call these from other scripts)
# ---------------------------------------------------------------------------
## Fades the foreground in (or shows it instantly if fade_in_gradually is off).
func appear_foreground() -> void:
	_fade_foreground(1.0, fade_in_gradually)

## Fades the foreground out (or hides it instantly if fade_out_gradually is off).
func disappear_foreground() -> void:
	_fade_foreground(0.0, fade_out_gradually)

func _fade_foreground(target_alpha: float, gradual: bool) -> void:
	# Stop any fade that is still running so two tweens never fight each other.
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	var visible_at_end: bool = target_alpha > 0.0
	if visible_at_end:
		foreground.visible = true # Must be visible for the fade-in to be seen.

	if not gradual or fade_duration <= 0.0:
		foreground.modulate.a = target_alpha
		foreground.visible = visible_at_end
		return

	# Scale the duration by how far there is left to fade, so a half-faded sprite takes half the time.
	var duration: float = absf(foreground.modulate.a - target_alpha) * fade_duration
	_fade_tween = create_tween()
	_fade_tween.tween_property(foreground, "modulate:a", target_alpha, duration)
	if not visible_at_end:
		_fade_tween.tween_callback(func() -> void: foreground.visible = false) # Skip drawing when fully transparent.


func _is_player_on_stairs() -> bool:
	if not player.is_on_floor():
		return false
	for i: int in player.get_slide_collision_count():
		var c: KinematicCollision2D = player.get_slide_collision(i)
		if c.get_collider() == stair_body and c.get_normal().dot(player.up_direction) > 0.7:
			return true
	return false


#class_name CameraFollow
#extends Camera2D
#
#
#@onready var foreground: Sprite2D = %Foreground
#@onready var stair_collision: CollisionPolygon2D = %StairCollision
### The StaticBody2D that owns the stair collision polygon.
#@onready var stair_body: Node = stair_collision.get_parent()
#
#@export var player: Player
#
#@export_category("Camera Movement")
#@export var initial_speed: float = 150.0 ## Speed the camera starts with when it begins moving from rest (pixels/second).
#@export var max_speed: float = 500.0 ## Top speed of the camera in pixels/second.
#@export var acceleration: float = 150.0 ## Acceleration in pixels/second², applied from initial_speed up to max_speed.
#@export var deadzone: float = 15.0 ## Camera stays still while closer than this to the player (pixels).
#@export var follow_offset: Vector2 = Vector2.ZERO ## Shifts the camera relative to the player (e.g. look slightly above).
#@export var snap_on_ready: bool = true ## Snap to the player instantly when the scene starts.
#
#@export_category("Zoom Settings")
#@export var zoom_speed: float = 0.8 ## Max zoom change per second (1.0 = full zoom range in 1 second).
#@export var zoom_out_level: Vector2 = Vector2(1.8, 1.8)
#@export var zoom_in_level: Vector2 = Vector2(2.3, 2.3)
#@export var zoom_start_y: float = 160.0
#@export var zoom_end_y: float = 50.0
#
#@export_category("Foreground Fade")
#@export var fade_out_gradually: bool = true ## Fade the foreground out when fully zoomed in (false = hide instantly).
#@export var fade_in_gradually: bool = true ## Fade the foreground back in when zooming out (false = show instantly).
#@export var fade_duration: float = 0.7 ## Seconds for a full fade, used for both fade out and fade in.
#
#
#var _speed: float = 0.0
#var _zoom_t: float = 0.0 ## Current zoom progress: 0.0 = zoom_out_level, 1.0 = zoom_in_level.
#var _display_t: float = 0.0
#
#
#func _ready() -> void:
	#if player == null:
		#player = get_parent().get_node_or_null("Player") as Player # Fallback: look for a sibling named "Player"
	#if player != null and snap_on_ready:
		#global_position = player.global_position + follow_offset
	#zoom = zoom_out_level
#
#
#func _physics_process(delta: float) -> void:
	#if player == null:
		#return
	#camera_follow(delta)
	#zoom_manager(delta)
	#foreground_manager(delta)
#
#
#func camera_follow(delta: float) -> void:
	#var goal: Vector2 = player.global_position + follow_offset
	#var to_goal: Vector2 = goal - global_position
	#var distance: float = to_goal.length()
	## Inside the deadzone: stop and stay put (no jitter).
	#if distance <= deadzone:
		#_speed = 0.0
		#return
	## Starting from rest: jump straight to the initial speed.
	#if _speed < initial_speed:
		#_speed = initial_speed
	## Then accelerate toward max speed.
	#_speed = minf(_speed + acceleration * delta, max_speed)
	#var step: float = minf(_speed * delta, distance)
	#global_position += to_goal / distance * step
#
#func zoom_manager(delta: float) -> void:
	## Where the player's height says the zoom should be (0.0 yellow, 1.0 red).
	#var y_t: float = clampf(inverse_lerp(zoom_start_y, zoom_end_y, player.global_position.y), 0.0, 1.0)
	#if _is_player_on_stairs():
		## Standing on the stairs: target follows height both ways.
		#_zoom_t = y_t
	#else:
		## Jumping, falling or on other ground: target can only go out, never in.
		#_zoom_t = minf(_zoom_t, y_t)
	## Move the displayed zoom toward the target at a fixed rate (smooth in and out).
	#_display_t = move_toward(_display_t, _zoom_t, zoom_speed * delta)
	#zoom = zoom_out_level.lerp(zoom_in_level, _display_t)
#
#func foreground_manager(delta: float) -> void:
	## Fade out only when fully zoomed in. Fade back in as soon as zoom drops below that.
	#var hide_foreground: bool = _display_t >= 1.0
	#var target_alpha: float = 0.0 if hide_foreground else 1.0
	#var gradual: bool = fade_out_gradually if hide_foreground else fade_in_gradually
	#var alpha: float = foreground.modulate.a
	#if gradual and fade_duration > 0.0:
		#alpha = move_toward(alpha, target_alpha, delta / fade_duration)
	#else:
		#alpha = target_alpha
	#foreground.modulate.a = alpha
	#foreground.visible = alpha > 0.0 # Skip drawing when fully transparent.
#
#func _is_player_on_stairs() -> bool:
	#if not player.is_on_floor():
		#return false
	#for i: int in player.get_slide_collision_count():
		#var c: KinematicCollision2D = player.get_slide_collision(i)
		#if c.get_collider() == stair_body and c.get_normal().dot(player.up_direction) > 0.7:
			#return true
	#return false
