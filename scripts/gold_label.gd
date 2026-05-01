extends Label

func _ready() -> void:
	ResourceManager.gold_changed.connect(_on_gold_changed)
	self.text = "Gold: " + str(ResourceManager.gold_count)

func _on_gold_changed(new_amount: int) -> void:
	self.text = "Gold: " + str(new_amount)
