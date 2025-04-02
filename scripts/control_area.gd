extends Area2D

@export var gold_production_rate := 10  # Gold per second
@export var goldmine_active := false

var controlling_faction: int = -1  # -1 means neutral
var occupying_units: Dictionary = {}  # Tracks units per faction
var faction_gold: Dictionary = {}  # Tracks gold per faction
var pawn_timer: float = 0.0  # Timer for pawn gold addition

signal goldmine_activated(state)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _process(delta):
	if goldmine_active and controlling_faction != -1:
		if controlling_faction in faction_gold:
			faction_gold[controlling_faction] += gold_production_rate * delta
		else:
			faction_gold[controlling_faction] = gold_production_rate * delta
		
		# Pawn gold reward system
		pawn_timer += delta
		if pawn_timer >= 10.0:
			Game.add_gold(5)
			pawn_timer = 0.0

func _on_body_entered(body):
	if body.has_method("get_faction"):
		var faction = body.get_faction()
		if faction in occupying_units:
			occupying_units[faction] += 1
		else:
			occupying_units[faction] = 1
		
		controlling_faction = get_dominant_faction()
		goldmine_active = true
		emit_signal("goldmine_activated", true)
	
	if body.is_in_group("pawns"):
		Game.add_gold(5)

func _on_body_exited(body):
	if body.has_method("get_faction"):
		var faction = body.get_faction()
		if faction in occupying_units:
			occupying_units[faction] -= 1
			if occupying_units[faction] <= 0:
				occupying_units.erase(faction)
		
		if occupying_units.is_empty():
			goldmine_active = false
			emit_signal("goldmine_activated", false)
			controlling_faction = -1

func get_dominant_faction():
	var max_count = 0
	var dominant_faction = -1
	
	for faction in occupying_units.keys():
		if occupying_units[faction] > max_count:
			max_count = occupying_units[faction]
			dominant_faction = faction
	
	return dominant_faction
