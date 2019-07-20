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
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()
	global_transform.basis = orientation.basis
	skel.rotation = Vector3()
