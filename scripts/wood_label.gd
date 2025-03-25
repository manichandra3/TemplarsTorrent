extends Label

func _process(delta: float) -> void:
	self.text = "Wood:"+ str(Game.wood_count)
