extends Area2D

# Coin properties
@export var coin_value: int = 1  # Value of the coin
var is_collected: bool = false   # Track if coin has been collected

# Called when the node enters the scene tree
func _ready():
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)

# Called when a body enters the coin's area
func _on_body_entered(body):
	if body.is_in_group("pawns") and body.entity_type  == "pawn" and not is_collected:
		collect_coin(body)

# Handle coin collection
func collect_coin(player):
	if is_collected:
		return
	is_collected = true
	Game.add_gold(5)
	# Remove the coin from the scene
	queue_free()
