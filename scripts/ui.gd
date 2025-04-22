extends CanvasLayer

@export var pawn_scene: PackedScene
@export var knight_scene: PackedScene

func _on_cancel_pressed() -> void:
	Game._on_cancel_selection_pressed()


func _on_spawn_pawn_pressed() -> void:
	if ResourceManager.spend_wood(40):
		Game.spawn_unit(pawn_scene)


func _on_spawn_knight_pressed() -> void:
	if ResourceManager.spend_wood(20):
		Game.spawn_unit(knight_scene)
