extends Spatial

export var target_path: NodePath

var target: Node
var dist = 0.0
func _ready():
	target = get_node(target_path)

var speed_slow = 4.5
var speed_fast = 8.5
var speed_cur = 3.5

func _process(delta):
	if !target:
		return
	var p1 = global_transform.origin
	var p2 = target.global_transform.origin
	dist = p1.distance_to(p2)
	if dist < 20.0:
		speed_cur -= delta * 0.2
	elif dist >= 25.0:
		speed_cur += delta * 0.1
	speed_cur = clamp(speed_cur, speed_slow, speed_fast)
	if dist <  10.0 && dist > 3.5:
		p1 = p1.linear_interpolate(p2, clamp(speed_cur * delta * (dist / 6.0 - 2.0 / 3.0), 0.0, 1.0))
	elif dist >= 10.0:
		p1 = p1.linear_interpolate(p2, clamp(speed_cur * delta, 0.0, 1.0))
	p1.y = 1.4
	global_transform.origin = p1
#	elif dist >= 30.0:
#		global_transform.origin = p1 + (p2 - p1).normalized() * ((p2 - p1).length() - 3.0)
	global_transform = global_transform.looking_at(p2, Vector3.UP)
	global_transform = global_transform.orthonormalized()
