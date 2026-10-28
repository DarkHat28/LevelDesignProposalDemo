## AreaBodies.gd
class_name CollisionTrigger
extends Node2D


@export var push_up_velocity: float = 50.0
@export var left_world_boundary_initial: int = -835.0
@export var left_world_boundary_reposition: float = 295.0

@onready var player: Player = %Player
@onready var right_boundary_marker: Marker2D = %RightBoundaryMarker


## Platform Collisions
# Static Body Collision
@onready var top_left_collision: CollisionPolygon2D = %TopLeftCollision
@onready var top_right_collision: CollisionPolygon2D = %TopRightCollision
@onready var top_one_way_collision: CollisionPolygon2D = %TopOneWayCollision
@onready var stair_collision: CollisionPolygon2D = %StairCollision
# Area Body Collisions
@onready var top_trigger_collision: CollisionShape2D = %TopTriggerCollision
@onready var stair_top_trigger_collision: CollisionShape2D = %StairTopTriggerCollision


func _ready() -> void:
	%LeftBoundary.global_position.x = left_world_boundary_initial


#func _physics_process(delta: float) -> void:
	#print("Player Global Position Y: ", player.global_position.y)

func _on_top_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("PLAYER"):
		return
	if player.is_on_floor():
		top_left_collision.set_deferred("disabled", false)
		top_right_collision.set_deferred("disabled", false)
		top_one_way_collision.set_deferred("disabled", false)
		if %LeftBoundary.position.x == left_world_boundary_reposition:
			player.velocity.y = -push_up_velocity
		%LeftBoundary.position.x = left_world_boundary_initial


func _on_stair_top_trigger_body_entered(body: Node2D) -> void:
	top_trigger_collision.set_deferred("disabled", false)
	top_left_collision.set_deferred("disabled", true)
	top_right_collision.set_deferred("disabled", true)
	top_one_way_collision.set_deferred("disabled", true)


func _on_middle_trigger_body_entered(body: Node2D) -> void: ## DONE ✅
	if not body.is_in_group("PLAYER"):
		return
	stair_top_trigger_collision.set_deferred("disabled", false)
	stair_collision.set_deferred("disabled", false)
	top_trigger_collision.set_deferred("disabled", true)
	if right_boundary_marker:
		%LeftBoundary.position.x = right_boundary_marker.global_position.x
		return
	%LeftBoundary.position.x = left_world_boundary_reposition


## Bottom Trigger Green Color
func _on_bottom_trigger_body_entered(body: Node2D) -> void: ## DONE ✅
	if not body.is_in_group("PLAYER"):
		return
	top_left_collision.set_deferred("disabled", true)
	top_right_collision.set_deferred("disabled", true)
	top_one_way_collision.set_deferred("disabled", true)
	stair_collision.set_deferred("disabled", true)
	
	top_trigger_collision.set_deferred("disabled", true)
	stair_top_trigger_collision.set_deferred("disabled", true)
	%LeftBoundary.position.x = left_world_boundary_initial
