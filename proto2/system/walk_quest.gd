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
	var arrow: Spatial
	var nav: Navigation
	func _init(title, destination: Spatial).(title):
		dest = destination
		arrow = world.arrow
		nav = world.arrow.get_node("/root/main/nav")
	func update():
		var org = world.master_node.global_transform.origin
		var orgc = nav.get_closest_point(org)
		var dst = dest.global_transform.origin
		var dstc = nav.get_closest_point(dst)
		var path = nav.get_simple_path(orgc, dstc)
		var arrow_dir : = Vector3()
		if path.size() > 1:
			for e in path:
				if (e - org).length() > 1.0:
					arrow_dir = e - org
					break
		if arrow_dir.length() == 0 && arrow.visible:
			arrow.hide()
		elif arrow_dir.length() > 0:
			if !arrow.visible:
				arrow.show()
			arrow_dir.y = 0
			arrow.look_at(arrow.global_transform.origin + arrow_dir, Vector3.UP)
			
		if org.distance_to(dest.global_transform.origin) < 2.5:
			_complete = true
			arrow.hide()
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
	if world.arrow:
		world.arrow.show()
	

func quest_complete():
	.quest_complete()
	quest_marker.queue_free()
	if world.arrow:
		world.arrow.hide()
