extends Node

# Resource management variables 
var wood_count: int = 50
var gold_count: int = 0

signal wood_count_changed(new_count: int)
signal gold_count_changed(new_count: int)


# Resource Management
func add_wood(amount: int):
	wood_count += amount
	emit_signal("wood_count_changed", wood_count)
	print("Wood added: ", amount, " (Total: ", wood_count, ")")

func get_wood_count() -> int:
	return wood_count

func spend_wood(amount: int) -> bool:
	print("wood count before ", wood_count)
	if wood_count >= amount:
		wood_count -= amount
		emit_signal("wood_count_changed", wood_count)
		print("wood count after ", wood_count)
		return true
	return false

func add_gold(amount: int):
	gold_count += amount
	emit_signal("gold_count_changed", gold_count)
	print("Gold added: ", amount, " (Total: ", gold_count, ")")

func get_gold_count() -> int:
	return gold_count

func spend_gold(amount: int) -> bool:
	if gold_count >= amount:
		gold_count -= amount    
		emit_signal("gold_count_changed", gold_count)                      
		return true
	return false
