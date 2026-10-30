class_name CameraFollowOLD
extends Camera2D


@onready var foreground: Sprite2D = %Foreground
@onready var stair_collision: CollisionPolygon2D = %StairCollision

@export var player: Player

@export_category("Camera Movement")
## Speed the camera starts with when it begins moving from rest (pixels/second).
@export var initial_speed: float = 150.0
## Top speed of the camera in pixels/second.
@export var max_speed: float = 500.0
## Acceleration in pixels/second², applied from initial_speed up to max_speed.
@export var acceleration: float = 150.0
## Camera stays still while closer than this to the player (pixels).
@export var deadzone: float = 5.0
## Shifts the camera relative to the player (e.g. look slightly above).
@export var follow_offset: Vector2 = Vector2.ZERO
## Snap to the player instantly when the scene starts.
@export var snap_on_ready: bool = true

@export_category("Zoom Settings")
## Zoom at the bottom of the stairs (yellow dot). Also the default zoom.
@export var zoom_out_level: Vector2 = Vector2(1.5, 1.5)
## Zoom at the top of the stairs (red dot). Foreground hides at this zoom.
@export var zoom_in_level: Vector2 = Vector2(2.0, 2.0)
## Player global Y at the yellow dot (zoom_out_level).
@export var zoom_start_y: float = 160.0
## Player global Y at the red dot (zoom_in_level).
@export var zoom_end_y: float = 50.0 #35.0

var _speed: float = 0.0


func _ready() -> void:
	if player == null:
		# Fallback: look for a sibling named "Player"
		player = get_parent().get_node_or_null("Player") as Player
	if player != null and snap_on_ready:
		global_position = player.global_position + follow_offset
	zoom = zoom_out_level


func _physics_process(delta: float) -> void:
	if player == null:
		return
	camera_follow(delta)


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
