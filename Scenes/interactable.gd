## Generic interactable (lever, sign, chest...). Connect to `interacted` or extend and override interact().
class_name Interactable
extends Area2D


signal interacted(player: Player)


func interact(player: Player) -> void:
	interacted.emit(player)
