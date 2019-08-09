extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var expose_time:float = 0.0
var cooldown_time: float = 0.0
var queue = []
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if queue.size() > 0:
		if cooldown_time <= 0.0:
			var item = queue[0]
			queue.pop_front()
			if visible:
				hide()
			$v/quest_title.text = item.title
			$v/quest_desc.text = item.desc
			expose_time = 0.0
			cooldown_time = 2.0
			show()
			release_focus()
	if expose_time > 10.0:
		if visible:
			hide()
		cooldown_time -= delta
	else:
		expose_time += delta
func start_notification(title, desc):
	queue.push_back({"title": title, "desc": desc})
	print("start notification", title)
