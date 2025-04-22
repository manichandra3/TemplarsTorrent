extends RichTextLabel

func _process(delta: float) -> void:
	self.text = "Gold: " + str(ResourceManager2.gold_count)
