extends KinematicBody
var orientation: Transform
var velocity: Vector3 = Vector3()
var skel: Skeleton
const GRAVITY = Vector3(0, -9.8, 0)
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	orientation = Transform()
	skel = get_children()[0]
	add_to_group("characters")
	add_to_group("activatable")

func get_act():
	return "Talk"

func idle():
	var sm: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/base/playback"]
	sm.travel("Idle")
func walk():
	var sm: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/base/playback"]
	sm.travel("Walk")
func set_walk_speed(spd: float):
	$AnimationTree["parameters/base/Walk/speed/scale"] = spd
func get_walk_speed() -> float:
	return $AnimationTree["parameters/base/Walk/speed/scale"]

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

func _process(delta):
	orientation = global_transform
	orientation.origin = Vector3()
	var sm: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/base/playback"]
	var rm = $AnimationTree.get_root_motion_transform()
	orientation *= rm
	var h_velocity = orientation.origin / delta
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
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
			var direction: Vector3 = (next - global_transform.origin).normalized()
			var actual_direction: Vector3 = -global_transform.basis[2]
			var angle: float = Vector2(actual_direction.x, actual_direction.z).angle_to(Vector2(direction.x, direction.z))
			var tf_turn = Transform(Quat(Vector3(0, 1, 0), -angle * delta))
			orientation *= tf_turn
		if !_path || _path.size() == 0:
			idle()
		
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()
	global_transform.basis = orientation.basis
	skel.rotation = Vector3()
