extends Node

signal wood_changed(new_amount: int)
signal gold_changed(new_amount: int)

# Resource management variables 
var wood_count: int = 50
var gold_count: int = 0

# Resource Management
func add_wood(amount: int) -> void:
	wood_count += amount
	wood_changed.emit(wood_count)
	print("Wood added: ", amount, " (Total: ", wood_count, ")")

func get_wood_count() -> int:
	return wood_count

func spend_wood(amount: int) -> bool:
	print("wood count before ", wood_count)
	if wood_count >= amount:
		wood_count -= amount
		wood_changed.emit(wood_count)
		print("wood count after ", wood_count)
		return true
	return false

func add_gold(amount: int) -> void:
	gold_count += amount
	gold_changed.emit(gold_count)
	print("Gold added: ", amount, " (Total: ", gold_count, ")")

func get_gold_count() -> int:
	return gold_count

func spend_gold(amount: int) -> bool:
	if gold_count >= amount:
		gold_count -= amount                          
		gold_changed.emit(gold_count)
		return true
	return false
