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
	var m = get_meta("quest")
	if m != null:
		for k in _objectives:
			k.set_meta("quest", m)
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
		return
	for k in _children:
		if !k.is_complete():
			_complete = false
			break
	if _complete:
		emit_signal("complete", self)
		_active = false
func start():
	_active = true
	for k in _children:
		k.start()
	emit_signal("started", self)
func get_cur_task_text():
	var ret: String = "No current task"
	if _active:
		for p in _children:
			if p.is_active():
				ret = p.get_cur_task_text()
				return ret
		for p in _objectives:
			if !p.is_complete():
				return p.get_title()
		return _title
	return ret
func get_title():
	return _title
func get_description():
	return _description
