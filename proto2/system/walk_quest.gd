extends Quest
class_name WalkQuest

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var destination: Spatial
var quest_marker: Spatial
class WalkQuestObjective extends QuestObjective:
	var dest: Spatial
	func _init(title, destination: Spatial).(title):
		dest = destination
	func update():
		var org = world.master_node.global_transform.origin
		if org.distance_to(dest.global_transform.origin) < 2.5:
			_complete = true
func _init(title, desc, dest).(title, desc):
	destination = dest
	add_objective(WalkQuestObjective.new("Walk to destination", dest))
func update():
	.update()
func start():
	.start()
	quest_marker = load("res://markers/quest_marker.tscn").instance()
	world.master_node.get_node("/root/main").add_child(quest_marker)
	quest_marker.global_transform.origin = destination.global_transform.origin
	print("destination: ", quest_marker.global_transform.origin)
	

func quest_complete():
	.quest_complete()
	quest_marker.queue_free()
