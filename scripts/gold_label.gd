extends Label

@onready var ResourceManage = get_node("../../../../ResourceManager")

func _ready():
	ResourceManage.gold_count_changed.connect(_on_gold_changed)
	#_on_gold_changed(ResourceManager.gold_count)
	

func _on_gold_changed(new_count: int) -> void:
	text = "Gold: %d" % new_count
