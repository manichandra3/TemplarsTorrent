extends Label

func _process(_delta: float) -> void:
	self.text = "Wood: "+ str(ResourceManager.wood_count)
