extends Reference
class_name Quest
signal complete
signal failed
signal started
var _objectives = []
var _children = []
var _title: String
var _description: String
var _active: bool = false
var _complete: bool = false
var _next_quest: Quest
func _init(title: String, description: String):
	_title = title
	_description = description
func add_child(quest: Quest):
	_children.push_back(quest)
func is_complete():
	return _complete
func is_active():
	return _active
func update():
	if !_active:
		return
#	var m = get_meta("quest")
#	if m != null:
#		for k in _objectives:
#			k.set_meta("quest", m)
	for k in _objectives:
		k.update()
	for k in _children:
		k.update()
	_complete = true
	for k in _objectives:
		if !k.is_complete():
			_complete = false
			break
	if !_complete:
		print("quest: ", _title, " objectives incomplete")
		return
	for k in _children:
		if !k.is_complete():
			_complete = false
			break
	if !_complete:
		print("quest: ", _title, " children incomplete")
	if _complete:
		emit_signal("complete", self)
		_active = false
		quest_complete()
func quest_complete_handler(quest: Quest):
	var next = quest.get_next_quest()
	if next != null:
		add_child(next)
		next.connect("complete", self, "quest_complete_handler")
		next.start()
func start():
	_active = true
	for k in _children:
		k.connect("complete", self, "quest_complete_handler")
		k.start()
	emit_signal("started", self)
	print("children: ", _children)
	print("quest: ", _title, " started")
func get_cur_task_text():
	var ret: String = "No current task"
	if _active:
		for p in _children:
			if p.is_active():
				ret = p.get_cur_task_text()
				return ret
		for p in _objectives:
			if !p.is_complete():
				return get_title() + ": " + p.get_title()
		return _title
	return ret
func get_title():
	return _title
func get_description():
	return _description
func quest_complete():
	print("quest: ", _title, " complete")
func add_objective(obj: QuestObjective):
	if !obj in _objectives:
		_objectives.push_back(obj)
func remove_objective(obj: QuestObjective):
	if obj in _objectives:
		_objectives.erase(obj)
func set_next_quest(obj: Quest):
	_next_quest = obj
func get_next_quest() -> Quest:
	return _next_quest
