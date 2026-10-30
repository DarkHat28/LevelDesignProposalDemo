@tool
extends Node2D


@export var extend_world: bool = false

@onready var camera: CameraFollow = %Camera
@onready var right_boundary_collision: CollisionShape2D = %RightBoundaryCollision
@onready var right_boundary: Sprite2D = %RightBoundary
@onready var right_boundary_marker: Marker2D = %RightBoundaryMarker
@onready var world_extend_button: Button = %WorldExtendButton


func _ready() -> void:
	right_boundary_collision.disabled = extend_world
	right_boundary.visible = !extend_world
	%FloatingIsland.visible = false
	camera.limit_right = 835
	
	#world_extend_button.focus_mode = Control.FOCUS_NONE

func _on_world_extend_button_pressed() -> void:
	right_boundary_collision.disabled = !right_boundary_collision.disabled
	right_boundary.visible = !right_boundary.visible
	if right_boundary.visible:
		%WorldExtendButton.self_modulate = Color.GAINSBORO
		%FloatingIsland.visible = false
		camera.limit_right = 835
	else:
		%WorldExtendButton.self_modulate = Color.GREEN
		%FloatingIsland.visible = true
		camera.limit_right = 2365
