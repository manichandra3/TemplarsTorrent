extends Label

func _ready() -> void:
	ResourceManager.wood_changed.connect(_on_wood_changed)
	self.text = "Wood: " + str(ResourceManager.wood_count)

func _on_wood_changed(new_amount: int) -> void:
	self.text = "Wood: " + str(new_amount)
