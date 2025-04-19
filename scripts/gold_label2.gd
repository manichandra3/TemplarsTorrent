extends Label

func _process(_delta: float) -> void:
	self.text = "Gold:"+ str(ResourceManager2.gold_count)
