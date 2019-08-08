extends KinematicBody
var orientation: Transform
var velocity: Vector3 = Vector3()
var skel: Skeleton
var anim_tree: AnimationTree
var aplay: AnimationPlayer
const GRAVITY = Vector3(0, -9.8, 0)
var ball_carry: Node
var item_right_hand: Node
var head_node: Node
enum {RAYCAST_WAIT, RAYCAST_FRONT, RAYCAST_LEFT, RAYCAST_RIGHT, RAYCAST_END}
var _raycast_state = RAYCAST_WAIT
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	orientation = Transform()
	skel = get_children()[0].get_children()[0]
	var queue = [self]
	while queue.size() > 0:
		var item = queue[0]
		queue.pop_front()
		if item is Skeleton:
			skel = item
		if item is AnimationTree:
			anim_tree = item
		if item is AnimationPlayer:
			aplay = item
		if skel != null && anim_tree != null && aplay != null:
			break
		for c in item.get_children():
			queue.push_back(c)
	for v in aplay.get_animation_list():
		if v.ends_with("loop"):
			var anim = aplay.get_animation(v)
			anim.loop = true
	add_to_group("characters")
	add_to_group("activatable")
	ball_carry = get_children()[0].get_children()[0].get_node("item_carry/ball_carry")
	head_node = BoneAttachment.new()
	skel.add_child(head_node)
	head_node.bone_name = "head"

func get_act():
	return "Talk"

func idle():
	var sm: AnimationNodeStateMachinePlayback = anim_tree["parameters/base/playback"]
	sm.travel("Idle")
func walk():
	var sm: AnimationNodeStateMachinePlayback = anim_tree["parameters/base/playback"]
	sm.travel("Walk")
func set_walk_speed(spd: float):
	anim_tree["parameters/base/Walk/speed/scale"] = spd
func get_walk_speed() -> float:
	return anim_tree["parameters/base/Walk/speed/scale"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var _path: Array

func walkto(target: Vector3, spd: float = 1.4):
	var cur = world.nav.get_closest_point(global_transform.origin)
	target = world.nav.get_closest_point(target)
	var path: PoolVector3Array = world.nav.get_simple_path(cur, target)
	_path = Array(path)
	set_walk_speed(spd)
	walk()

func take_object(obj):
	if obj.is_in_group("items"):
		print("taking item ", obj.name)
		obj.taken(self)
		print("done taking item ", obj.name)

func drop_object(obj):
	if obj.is_in_group("items"):
		print("dropping item ", obj.name)
		obj.dropped(self)
		print("done dropping item ", obj.name)


func distance(obj1, obj2) -> float:
	var p1: Vector3 = obj1.global_transform.origin
	var p2: Vector3 = obj2.global_transform.origin
	return p1.distance_squared_to(p2)

func alignment(obj):
	var v: Vector3 = Vector3()
	var neighbor_count: int = 0
	for ch in get_tree().get_nodes_in_group("characters"):
		if ch == obj:
			continue
		if distance(obj, ch) < 1.5:
			v += ch.velocity
			neighbor_count += 1
	if neighbor_count == 0:
		return v
	v.x /= float(neighbor_count)
	v.z /= float(neighbor_count)
	v.y = 0
	return v.normalized()

func separation(obj):
	var v: Vector3 = Vector3()
	var neighbor_count: int = 0
	for ch in get_tree().get_nodes_in_group("characters"):
		if ch == obj:
			continue
		if distance(obj, ch) < 0.5:
			v += obj.global_transform.origin - ch.global_transform.origin
			neighbor_count += 1
	if neighbor_count == 0:
		return v
	v.x /= float(neighbor_count)
	v.z /= float(neighbor_count)
	v.y = 0
	return v.normalized()

		
var raycast_delay = 0.1
var raycasts : = {
	"front": {},
	"left": {},
	"right": {}
}
func _physics_process(delta):
	var space := get_world().direct_space_state
	var ray_origin : = global_transform.origin + Vector3(0.0, 0.5, 1.0)

	match(_raycast_state):
		RAYCAST_WAIT:
			raycast_delay -= delta
			if raycast_delay <= 0:
				_raycast_state = RAYCAST_FRONT
		RAYCAST_FRONT:
			raycasts.front = space.intersect_ray(ray_origin, ray_origin - global_transform.basis[2] * 0.5, [self], 512 | 1, true, false)
			_raycast_state = RAYCAST_LEFT
		RAYCAST_LEFT:
			raycasts.left = space.intersect_ray(ray_origin, ray_origin - global_transform.basis[0] * 0.5, [self], 512 | 1, true, false)
			_raycast_state = RAYCAST_RIGHT
		RAYCAST_RIGHT:
			raycasts.left = space.intersect_ray(ray_origin, ray_origin + global_transform.basis[0] * 0.5, [self], 512 | 1, true, false)
			_raycast_state = RAYCAST_END
		RAYCAST_END:
			_raycast_state = RAYCAST_WAIT
			raycast_delay = 0.1
	var correction_dir : = Vector3()
	orientation = global_transform
	orientation.origin = Vector3()
	var sm: AnimationNodeStateMachinePlayback = anim_tree["parameters/base/playback"]
	var rm = anim_tree.get_root_motion_transform()
	orientation *= rm
	var update_velocity: Vector3 = Vector3()
	if !is_in_group("master"):
		update_velocity = (alignment(self) + separation(self) + correction_dir.normalized()).normalized() * 3.0
	else:
		update_velocity = separation(self) * 0.5 * 0.8
	var h_velocity = orientation.origin / delta
	h_velocity.linear_interpolate(update_velocity, 0.5)
	velocity.x = h_velocity.x 
	velocity.z = h_velocity.z
	if raycasts.front.has("normal") && velocity.length_squared() > 0:
		var nx = global_transform.xform_inv(raycasts.front.normal)
		if nx.x > 0:
			correction_dir += global_transform.xform(Vector3(1, 0, 0))
		elif nx.x < 0:
			correction_dir += global_transform.xform(Vector3(-1, 0, 0))
		else:
			correction_dir += global_transform.xform(Vector3(0, 0, 1))
		if raycasts.left.has("normal"):
			correction_dir += global_transform.xform(Vector3(1, 0, 0))
		if raycasts.right.has("normal"):
			correction_dir += global_transform.xform(Vector3(-1, 0, 0))
			
	if !is_on_floor():
		velocity += GRAVITY * delta
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
	if is_in_group("master"):
		orientation *= controls.frame_tf
		controls.frame_tf = Transform()
	if _path && _path.size() > 0:
		while _path.size() > 0 && _path[0].distance_to(global_transform.origin) < 0.5:
			_path.pop_front()
		if _path.size() > 0:
			var next: Vector3 = _path[0]
			var direction: Vector3 = ((next - global_transform.origin).normalized() * 0.5 + update_velocity.normalized() * 0.5).normalized()
			var actual_direction: Vector3 = -global_transform.basis[2]
			var angle: float = Vector2(actual_direction.x, actual_direction.z).angle_to(Vector2(direction.x, direction.z))
			var tf_turn = Transform(Quat(Vector3(0, 1, 0), -angle * min(delta * 2.0, 1.0)))
			orientation *= tf_turn
		if !_path || _path.size() == 0:
			idle()
		
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()
	global_transform.basis = orientation.basis
	skel.rotation = Vector3()
