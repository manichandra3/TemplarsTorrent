# res://scripts/NetworkedCharacter.gd
extends MultiplayerSynchronizer

# list all the properties every unit should sync:
const SYNC_PROPS = [
	".:position",
	".:rotation",
	".:scale",
	".:skew",
	".pawn_animated:animation",
	".pawn_animated:frame",
	".pawn_animated:speed_scale",
	".pawn_animated:offset",
	".pawn_animated:filp_h",
	".pawn_animated:flip_v"
	# add other shared fields here…
]

func _ready():
  # get & clone the config so we don’t overwrite the editor’s default
	var cfg = replication_config.duplicate()
	for prop_path_str in SYNC_PROPS:
		var pp = NodePath(prop_path_str)
		cfg.add_property(pp)
		cfg.property_set_replication_mode(pp, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		# maybe you want the initial health to spawn immediately:
		cfg.property_set_spawn(pp, prop_path_str == ".:health")
	# assign back
	replication_config = cfg
	
	# you can also hook RPC notifications here:
	#connect("network_peer_connected", self, "_on_peer_connected")
	## …
#
#func _on_peer_connected(id):
	## custom code for when someone new joins
	#pass
