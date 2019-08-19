extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var quest_notification_scene = preload("res://ui/start_quest_notification.tscn")
var quest_complete_notification_scene = preload("res://ui/quest_complete_notification.tscn")
var narration_notification_scene = preload("res://ui/narration_notification.tscn")
var qn: Node
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var queue = []
const cooldown_time: float = 3.0
var time_count: float = 0.0
enum {N_QUEST, N_QUEST_COMPLETE, N_NARRATION, N_OTHER}
enum {STATE_INIT, STATE_IDLE, STATE_DISPLAY}
var state: int = STATE_INIT
func quest_notfication(title, desc):
	queue.push_back({"type": N_QUEST, "title": title, "desc": desc})

func quest_complete_notfication(title, desc):
	queue.push_back({"type": N_QUEST_COMPLETE, "title": title, "desc": desc})
	
func narration_notification(text):
	queue.push_back({"type": N_NARRATION, "text": text})

var _main: Node

func set_main(main: Node):
	_main = main

func _process(delta):
	match(state):
		STATE_INIT:
			time_count = 0.0
			state = STATE_IDLE
		STATE_IDLE:
			if queue.size() > 0 && time_count > cooldown_time:
				state = STATE_DISPLAY
				if qn:
					qn.queue_free()
					qn = null
			elif time_count > cooldown_time * 2.5:
				if qn:
					qn.queue_free()
					qn = null
		STATE_DISPLAY:
			var desc
			var title
			var data = queue[0]
			queue.pop_front()
			match(data.type):
				N_QUEST:
					qn = quest_notification_scene.instance()
					_main.add_child(qn)
					qn.display_notification(data.title, data.desc)
					time_count = 0.0
				N_QUEST_COMPLETE:
					qn = quest_complete_notification_scene.instance()
					_main.add_child(qn)
					qn.display_notification(data.title)
					time_count = 0.0
				N_NARRATION:
					qn = narration_notification_scene.instance()
					_main.add_child(qn)
					qn.display_notification(data.text)
					time_count = 0.0
			state = STATE_IDLE
	if time_count < 2000.0:
		time_count += delta
