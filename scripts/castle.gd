extends StaticBody2D

func _ready() -> void:
	add_to_group("castle")
	var player_node = get_parent()
	var id = player_node.player_id
	print(str(id) + " name")
	$MultiplayerSynchronizer.set_multiplayer_authority(id)
	
func _physics_process(delta: float) -> void:
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		pass
