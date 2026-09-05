class_name InteractionPoint
extends Area3D

@export var action: GameIds.Action = GameIds.Action.GREET

func prompt() -> String:
	return String(GameIds.ACTION_LABELS[action])
