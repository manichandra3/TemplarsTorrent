extends Label

@onready var ResourceManage = get_node("../../../../ResourceManager2")
var wood_count: int

func _ready():
	ResourceManage.wood_count_changed.connect(_on_wood_changed)
	#_on_wood_changed(ResourceManager2.wood_count)

func _on_wood_changed(new_count: int) -> void:
	print("hello"+ str(new_count))
	self.text = "Wood: " + str(new_count)
