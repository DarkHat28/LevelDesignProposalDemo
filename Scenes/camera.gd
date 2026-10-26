class_name CameraFollow
extends Camera2D


@onready var foreground: Sprite2D = %Foreground


@export var player: Player

@export_category("Camera Movement")
## The node to follow (drag your Player here in the inspector).
## Speed the camera starts with when it begins moving from rest (pixels/second).
@export var initial_speed: float = 150.0
## Top speed of the camera in pixels/second.
@export var max_speed: float = 600.0
## Acceleration in pixels/second², applied from initial_speed up to max_speed.
@export var acceleration: float = 200.0
## Camera stays still while closer than this to the player (pixels).
@export var deadzone: float = 5.0
## Shifts the camera relative to the player (e.g. look slightly above).
@export var follow_offset: Vector2 = Vector2.ZERO
## Snap to the player instantly when the scene starts.
@export var snap_on_ready: bool = true

@export_category("Zoom Settings")
## Zoom when the player is in the upper area (foreground hidden).
@export var zoom_in_level: Vector2 = Vector2(2.0, 2.0)
## Zoom when the player is in the lower area (foreground visible).
@export var zoom_out_level: Vector2 = Vector2(1.5, 1.5)
## How long the zoom transition takes, in seconds.
@export var zoom_duration: float = 1.0
## Player Y position that switches between the two zoom states.
@export var foreground_threshold_y: float = 35.0

var _is_zoomed_in: bool = false
var _speed: float = 0.0
var _zoom_tween: Tween


func _ready() -> void:
	if player == null:
		# Fallback: look for a sibling named "Player"
		player = get_parent().get_node_or_null("Player") as Player
	if player != null and snap_on_ready:
		global_position = player.global_position + follow_offset

func _process(delta: float) -> void:
	if player == null:
		return
	camera_follow(delta)
	foreground_manager()

func camera_follow(delta: float)-> void:
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


func foreground_manager() -> void:
	var should_zoom_in: bool = player.global_position.y < foreground_threshold_y
	if should_zoom_in == _is_zoomed_in:
		return
	_is_zoomed_in = should_zoom_in
	if _is_zoomed_in:
		# Zoom in first, hide the foreground once the zoom has finished.
		_tween_zoom(zoom_in_level, true)
	else:
		# Show the foreground right away, then zoom out.
		foreground.show()
		_tween_zoom(zoom_out_level, false)

func _tween_zoom(target_zoom: Vector2, hide_foreground_when_done: bool) -> void:
	# Stop the previous zoom so two tweens never fight over `zoom`.
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.set_trans(Tween.TRANS_SINE)
	_zoom_tween.set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_property(self, "zoom", target_zoom, zoom_duration)
	if hide_foreground_when_done:
		_zoom_tween.tween_callback(foreground.hide)
