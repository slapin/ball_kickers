extends Node
signal user_click

var frame_tf: Transform = Transform()
var master_node: Node
var camera: Camera
var monitored_objects = []
var mon_labels = {}
func _ready():
	pass
func _process(delta):
	if !master_node:
		return
	if Input.is_action_pressed("move_north"):
		var n = lerp(master_node.get_walk_speed(), 1.4, 0.5 * delta)
		master_node.set_walk_speed(n)
		master_node.walk()
	elif !master_node._path || master_node._path.size() == 0:
		var n = lerp(master_node.get_walk_speed(), 1.0, 0.5 * delta)
		master_node.set_walk_speed(n)
		master_node.idle()
	if Input.is_action_pressed("move_east"):
		var tf_turn = Transform(Quat(Vector3(0, 1, 0), -PI * 0.6 * delta))
		frame_tf *= tf_turn
	if Input.is_action_pressed("move_west"):
		var tf_turn = Transform(Quat(Vector3(0, 1, 0), PI * 0.6 * delta))
		frame_tf *= tf_turn
	var act_obj = null
	var act_dist = -1.0
	var opos =  master_node.global_transform.origin
	for k in get_tree().get_nodes_in_group("activatable"):
		if k == master_node:
			continue
		var epos = k.global_transform.origin
		var new_dist = opos.distance_squared_to(epos)
		if act_dist < 0:
			act_obj = k
			act_dist = new_dist
			continue
		elif act_dist > new_dist:
			act_dist = new_dist
			act_obj = k
#	if act_obj != null && act_dist < 3.0:
#		print("act: ", act_obj, " ", act_dist)
	if act_obj != null && !act_obj in monitored_objects:
		if act_dist < 4.0 && monitored_objects.size() < 4:
			print("act2: ", act_obj, " ", act_dist)
			monitored_objects.push_back(act_obj)
			mon_labels[act_obj] = Label.new()
			mon_labels[act_obj].text = act_obj.get_act()
			add_child(mon_labels[act_obj])
			mon_labels[act_obj].rect_position = camera.unproject_position(act_obj.global_transform.origin)
			print("act3:", mon_labels[act_obj].text)
	for k in  monitored_objects:
		var epos = k.global_transform.origin
		var new_dist = opos.distance_squared_to(epos)
		if new_dist > 6.0:
			monitored_objects.erase(k)
			mon_labels[k].queue_free()
			mon_labels.erase(k)
			print("removed label")
			break
		else:
			mon_labels[k].rect_position = camera.unproject_position(k.global_transform.origin)
		
		
var click2d: Vector2 = Vector2()
var click2d_update: bool = false
var click3d: Vector3 = Vector3()
var click3d_update: bool = false

func _unhandled_input(event):
	if event is InputEventMouse:
		if event.button_mask & BUTTON_MASK_LEFT:
			click2d = event.position
			click2d_update = true
func _physics_process(delta):
	if click2d_update:
		var space := camera.get_world().direct_space_state
		var ray_origin : = camera.project_ray_origin(click2d)
		var ray_normal : = camera.project_ray_normal(click2d)
		var result := space.intersect_ray(ray_origin, ray_origin + ray_normal * 120.0, [], 512, true, false)
		if result.has("position"):
			click3d = result.position
			click3d_update = true
			emit_signal("user_click", click3d)
		click2d_update = false
		
