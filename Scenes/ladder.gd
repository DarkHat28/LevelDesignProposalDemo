class_name Ladder
extends Area2D
## Put a CollisionShape2D (RectangleShape2D) under this Area2D covering the ladder.


func _get_shape_node() -> CollisionShape2D:
	for c in get_children():
		if c is CollisionShape2D:
			return c
	return null


## X the player snaps to while climbing.
func get_center_x() -> float:
	var s := _get_shape_node()
	return s.global_position.x if s else global_position.x


## World Y of the bottom edge of the ladder.
func get_bottom_y() -> float:
	var s := _get_shape_node()
	if s == null:
		return global_position.y
	var half_h := 0.0
	if s.shape is RectangleShape2D:
		half_h = (s.shape as RectangleShape2D).size.y * 0.5 * s.global_transform.get_scale().y
	return s.global_position.y + half_h
