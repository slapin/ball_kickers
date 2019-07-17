extends KinematicBody2D
signal arrived

enum {STATE_IDLE, STATE_WALKTO, STATE_DIALOGUE, STATE_FOLLOW, STATE_CONTROL}
var destination = Vector2()
var state = STATE_IDLE
var velocity = Vector2()
var next_dst = Vector2()
var nav: Navigation2D
var arrived = false
var dst_node

func _ready():
	nav = get_node("/root/main/nav")
	add_to_group("npc")
func calc_next_dst():
	var path = nav.get_simple_path(nav.get_closest_point(global_position), nav.get_closest_point(destination))
	if path.size() > 1:
		var ok = false
		for p in path:
			if global_position.distance_squared_to(p) >= 25.0:
				next_dst = p
				ok = true
				break
		if !ok:
			if global_position.distance_squared_to(destination) < 25.0:
				next_dst = destination
			else:
				next_dst = global_position + (destination - global_position).normalized() * 20.0 + Vector2(randf() - 0.5, randf() - 0.5) * 40.0
	else:
		next_dst = destination
func update_destination():
	destination = dst_node.global_position
func walkto(p: Vector2):
	arrived = false
	destination = p
	state = STATE_WALKTO
	calc_next_dst()
func follow(n: Node2D):
	arrived = false
	state = STATE_FOLLOW
	dst_node = n
	update_destination()
	calc_next_dst()
func avoidance(delta):
	var avdst = 800.0
	var velsum = Vector2()
	for n in get_tree().get_nodes_in_group("npc"):
		if n == self:
			continue
		var dist = n.global_position.distance_squared_to(global_position)
		if dist < avdst:
			var d = global_position - n.global_position
			velsum += d
	velocity = velocity.linear_interpolate(velsum.normalized() * velocity.length() + Vector2(randf() - 0.5, randf() - 0.5) * velocity.length() * 0.3, delta)
func flock(delta):
	var avdst = 3600.0
	var maxdst = 10000.0
	var velsum = Vector2()
	for n in get_tree().get_nodes_in_group("npc"):
		if n == self:
			continue
		var dist = n.global_position.distance_squared_to(global_position)
		if dist > avdst && dist < maxdst:
			var d = global_position - n.global_position
			velsum += -d
	velocity = velocity.linear_interpolate(velsum.normalized() * velocity.length() + Vector2(randf() - 0.5, randf() - 0.5) * velocity.length() * 0.3, delta)
func attack():
	var bodies = $capture.get_overlapping_bodies()
	for b in bodies:
		if b is RigidBody2D:
			var e = velocity
			if e.length() == 0:
				e = Vector2(randf() - 0.5, randf() - 0.5)
			b.apply_impulse(Vector2(), e.normalized() * (100.0 + 100.0 * randf()))
		elif b.is_in_group("npc"):
			var e = velocity * 2.0
			if e.length() == 0:
				e = Vector2(randf() - 0.5, randf() - 0.5) * 5000.0
			b.velocity = e
			b.move_and_slide(e)
func _process(delta):
	match(state):
		STATE_IDLE:
			if randf() > 0.99:
				velocity = velocity.linear_interpolate(Vector2(randf() * 300.0 - 150.0, randf() * 300.0 - 150.0), 0.1 + delta * 0.9)
			else:
				velocity = velocity.linear_interpolate(Vector2(), delta)
			avoidance(delta)
			flock(delta)
			velocity = move_and_slide(velocity)
		STATE_WALKTO:
			var vel_base = 540.0
			if global_position.distance_squared_to(next_dst) < 25.0:
				calc_next_dst()
			if global_position.distance_squared_to(next_dst) < 900.0:
				vel_base = 160.0
			var dir = (next_dst - position).normalized()
			velocity = velocity.linear_interpolate(dir * vel_base, 0.3 * delta)
			avoidance(delta)
			flock(delta)
			if velocity.length() < 3.0:
				velocity += Vector2(randf() - 0.5, randf() - 0.5) * 6.0
				attack()
			velocity = move_and_slide(velocity)
			if global_position.distance_squared_to(destination) < 25.0:
				emit_signal("arrived", destination)
				state = STATE_IDLE
				arrived = true
		STATE_FOLLOW:
			var vel_base = 540.0
			update_destination()
			calc_next_dst()
			if global_position.distance_squared_to(next_dst) < 900.0:
				vel_base = 160.0
			var dir = (next_dst - position).normalized()
			velocity = velocity.linear_interpolate(dir * vel_base, 0.3 * delta)
			avoidance(delta)
			flock(delta)
			if velocity.length() < 3.0:
				velocity += Vector2(randf() - 0.5, randf() - 0.5) * 6.0
				attack()
			velocity = move_and_slide(velocity)
			if global_position.distance_squared_to(destination) < 25.0:
				emit_signal("arrived", destination)
				state = STATE_IDLE
				arrived = true
		STATE_DIALOGUE:
			pass
		STATE_CONTROL:
			pass
	
