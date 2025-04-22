extends RichTextLabel

func _process(delta: float) -> void:
	self.text = "Wood: " + str(ResourceManager2.wood_count)
