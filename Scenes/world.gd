@tool
extends Node2D


@export var extend_world: bool = false
@export var debug: bool = false

@onready var right_boundary_collision: CollisionShape2D = %RightBoundaryCollision
@onready var right_boundary: Sprite2D = %RightBoundary

func _ready() -> void:
	right_boundary_collision.disabled = extend_world
	right_boundary.visible = !extend_world
	%TopJumpArea.visible = debug


func _on_world_extend_button_pressed() -> void:
	right_boundary_collision.disabled = !right_boundary_collision.disabled
	right_boundary.visible = !right_boundary.visible
	if right_boundary.visible:
		%WorldExtendButton.self_modulate = Color.GREEN
	else:
		%WorldExtendButton.self_modulate = Color.GAINSBORO
	
