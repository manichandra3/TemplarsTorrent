extends Node2D   # or whatever your player root is

# this shows up in the Inspector per‑scene if you want…
@export var player_id: int = 0

func _ready():
	# if you still want the SceneTree’s name to be the same ID, you can do:
	name = str(player_id)
