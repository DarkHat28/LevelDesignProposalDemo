class_name Door
extends Area2D
## Press "interact" next to a door to go through it and come out of `target_door`.

signal player_entered(player: Player)   ## Player started going in (play your "open" animation here)
signal player_exited(player: Player)    ## Player is coming out of this door
signal blocked(player: Player)          ## Tried to use a locked / unlinked door

@export var target_door: Door
@export var locked := false
@export var exit_offset := Vector2.ZERO  ## Where the player appears, relative to this door


func can_enter() -> bool:
	return not locked and target_door != null


func get_exit_position() -> Vector2:
	return global_position + exit_offset
