extends StaticBody2D

signal construction_complete(constructing_unit)
signal destruction_complete()

enum TOWER_STATE {
	CONSTRUCTED,
	CONSTRUCTION,
	DESTROYING,
	DESTROYED
}

@export var attack_damage: float = 100.0  # Damage (or progress) per second per unit.
@export var full_health: float = 200.0

@onready var animated_sprite: AnimatedSprite2D = $tower_animated

var tower_state = TOWER_STATE.CONSTRUCTED

# Health values for each process.
var destruction_health: float = full_health
var construction_health: float = full_health

# Track multiple units for destruction.
var destructing_units: Array = []
# Only one unit can contribute to construction.
var constructing_pawn: Node2D = null

func _ready():
	add_to_group("towers")
	var player_node = get_parent()
	var id = player_node.player_id
	print(str(id) + " name")
	$MultiplayerSynchronizer.set_multiplayer_authority(id)
	update_animation()

func _process(delta):
	# Apply continuous damage for destruction.
	if tower_state == TOWER_STATE.DESTROYING and destructing_units.size() > 0:
		destruction_health -= attack_damage * destructing_units.size() * delta
		print("Destruction health:", destruction_health)
		if destruction_health <= 0:
			_on_destruction_complete()
	# Apply continuous progress for construction.
	elif tower_state == TOWER_STATE.CONSTRUCTION and constructing_pawn:
		construction_health -= attack_damage * delta
		print("Construction health:", construction_health)
		if construction_health <= 0:
			_on_construction_complete()

func update_animation():
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		match tower_state:
			TOWER_STATE.CONSTRUCTED:
				animated_sprite.play("built")
			TOWER_STATE.CONSTRUCTION:
				animated_sprite.play("construction")
			TOWER_STATE.DESTROYING:
				play_shake()
			TOWER_STATE.DESTROYED:
				animated_sprite.play("destroyed")

# --- Destruction Methods ---

# Called by a unit that starts destroying the tower.
func destroy_tower(unit: Node2D):
	# Only allow destruction on a built tower or one already being destroyed.
	if tower_state == TOWER_STATE.DESTROYED:
		return
	if tower_state == TOWER_STATE.CONSTRUCTED:
		# Start the destruction process.
		tower_state = TOWER_STATE.DESTROYING
		destruction_health = full_health
		update_animation()
	# Add the unit if it is not already contributing.
	if unit not in destructing_units:
		destructing_units.append(unit)

# Called when a unit stops contributing to destruction.
func stop_destructing(unit: Node2D):
	if unit in destructing_units:
		destructing_units.erase(unit)
		print("Unit", unit, "stopped destroying")

func _on_destruction_complete():
	print("Tower destroyed")
	tower_state = TOWER_STATE.DESTROYED
	update_animation()
	destruction_health = full_health
	for unit in destructing_units:
		print("kay")
		emit_signal("destruction_complete", unit)
	destructing_units.clear()
	# Emit the signal so destroying units can react.
	
	

# --- Construction Methods ---

# Called by a unit that starts constructing the tower.
func construct_tower(unit: Node2D):
	# Only start construction if the tower is currently destroyed and no other unit is constructing.
	if tower_state == TOWER_STATE.DESTROYED and constructing_pawn == null:
		tower_state = TOWER_STATE.CONSTRUCTION
		construction_health = full_health
		constructing_pawn = unit
		update_animation()
	# Only the unit that started construction can contribute.
	elif tower_state == TOWER_STATE.CONSTRUCTION and constructing_pawn == unit:
		# Continue construction progress.
		pass
	# Ignore if another unit tries to start construction while one is already active.
	else:
		print("Construction already in progress by another unit.")

# Called when a unit stops contributing to construction.
func stop_constructing(unit: Node2D):
	# Only allow removal if the unit is the one constructing.
	if constructing_pawn == unit:
		print("Unit", unit, "stopped constructing")
		constructing_pawn = null
		# Optionally, reset progress when construction is interrupted.
		construction_health = full_health
		tower_state = TOWER_STATE.DESTROYED
		update_animation()

func _on_construction_complete():
	print("Tower constructed")
	tower_state = TOWER_STATE.CONSTRUCTED
	update_animation()
	construction_health = full_health
	# Emit the signal so the constructing unit (pawn) can react.
	emit_signal("construction_complete", constructing_pawn)
	constructing_pawn = null

func play_shake():
	var tween = create_tween()
	var target_sprite = $tower_animated  # Update this path if necessary
	tween.tween_property(target_sprite, "position:x", target_sprite.position.x + 5, 0.1)
	tween.tween_property(target_sprite, "position:x", target_sprite.position.x - 5, 0.1)
	tween.tween_property(target_sprite, "position:x", target_sprite.position.x, 0.1)

func is_built() -> bool:
	return tower_state == TOWER_STATE.CONSTRUCTED

func is_destroyed() -> bool:
	return tower_state == TOWER_STATE.DESTROYED
