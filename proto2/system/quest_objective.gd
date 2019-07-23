extends Reference
class_name QuestObjective

var _complete: bool = false
var _title: String

func _init(title: String):
	_title = title
func is_complete():
	return _complete
func update():
	pass
func get_title():
	return _title
