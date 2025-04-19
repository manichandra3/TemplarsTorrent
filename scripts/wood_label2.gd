extends Label

func _process(_delta: float) -> void:
	self.text = "Wood: "+ str(ResourceManager2.wood_count)
