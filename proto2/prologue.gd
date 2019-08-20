extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func start():
	print("Started")
	var forest
	var airport
	var residental
	for v in range(roadmap.lots.lots.size()):
		var lot = roadmap.lots.lots[v]
		if lot.type == roadmap.Lots.LOT_FOREST:
			forest = lot
		if lot.type == roadmap.Lots.LOT_AIRPORT:
			airport = lot
		if lot.type == roadmap.Lots.LOT_RESIDENTAL:
			airport = lot
		if forest && airport:
			break
	var start_vertex = -1
	var start_lot
	if residental:
		start_lot = residental
	if airport:
		start_lot = airport
	for v in range(roadmap.vertices.size()):
		if start_vertex < 0:
			start_vertex = v
		var max_dist = roadmap.vertices[start_vertex].pos.distance_to(start_lot.xform.origin)
		var cur_dist = roadmap.vertices[v].pos.distance_to(start_lot.xform.origin)
		if max_dist > cur_dist:
			start_vertex = v
	print(start_vertex)
	print(start_lot)
	print(forest)

var reset_car = true		
func area_enter(body):
	if body == $car1:
		reset_car = true

var car_wrap_pos: Vector3
var grass_mat: SpatialMaterial
var rock_mat: SpatialMaterial
var tree_mat: SpatialMaterial
var car_mat: SpatialMaterial
var car_bottom_mat: SpatialMaterial
func _ready():
	notifications.set_main(self)
	roadmap.connect("complete", self, "start")
	$"car1/back-left-3".use_as_traction = true
	$"car1/back-right-3".use_as_traction = true
	$"car1/front-left-3".use_as_steering = true
	$"car1/front-right-3".use_as_steering = true
	$car1.steering = 0.0
	$car1.engine_force = 10000.0
	$Area.connect("body_entered", self, "area_enter")
	car_wrap_pos = $car_wrap.global_transform.origin
	var mark_mat = SpatialMaterial.new()
	mark_mat.albedo_color = Color(0.9, 0.9, 0.9, 1.0)
	mark_mat.roughness = 0.6
	for c in range(150):
		var pos = Vector3(0.0, 0.1, -100.0 + 3.0 + float(c) * 4.0)
		var mark = MeshInstance.new()
		add_child(mark)
		mark.global_transform.origin = pos
		var m : = PlaneMesh.new()
		m.size = Vector2(0.2, 2.0)
		m.subdivide_depth = 8.0
		m.subdivide_width = 2.0
		m.material = mark_mat
		mark.mesh = m
	grass_mat = SpatialMaterial.new()
	grass_mat.albedo_color = Color(0.3, 1.0, 0.3, 1.0)
	rock_mat = SpatialMaterial.new()
	rock_mat.albedo_color = Color(0.45, 0.3, 0.3, 1.0)
	tree_mat = SpatialMaterial.new()
	tree_mat.albedo_texture = load("res://elements/TreeTexture.png")
	car_mat = SpatialMaterial.new()
	car_mat.albedo_color = Color(0.6, 0.2, 0.2, 1.0)
	car_mat.metallic = 0.6
	car_mat.rim = 0.3
	car_mat.rim_tint = 0.12
	car_mat.rim_enabled = true
	car_mat.roughness = 0.45
	car_bottom_mat = SpatialMaterial.new()
	car_bottom_mat.albedo_color = Color(0.01, 0.01, 0.01, 1.0)
	car_bottom_mat.metallic = 0.6
	car_bottom_mat.roughness = 0.6
	for h in grass:
		h.surface_set_material(0, grass_mat)
	for h in rocks:
		h.surface_set_material(0, rock_mat)
	for h in big_rocks:
		h.surface_set_material(0, rock_mat)
	for h in trees:
		h.surface_set_material(0, tree_mat)
	for h in trees2:
		var grass_id = 0
		var tree_id = 1
		h.surface_set_material(grass_id, grass_mat)
		h.surface_set_material(tree_id, tree_mat)
	$"car1/car1-2500".set_surface_material(0, car_mat)
	$"car1/front-door-left".set_surface_material(0, car_mat)
	$"car1/front-door-right".set_surface_material(0, car_mat)
	$"car1/trunk_rotate/trunk_cover".set_surface_material(0, car_mat)
	$"car1/floor".set_surface_material(0, car_bottom_mat)

var narration = [
	"It was never a good sign to go to forest in a car trunk...",
	"You used much of the path to relax and rest, but now",
	"it is the time to do some action."
]
enum {STATE_INIT, STATE_NARRATION, STATE_IDLE, STATE_KICK_TRUNK, STATE_FINISH}
var _state = STATE_INIT

func _process(delta):
	var p1 = $cam.global_transform.origin
	var target = $car1.global_transform.origin
	var tpos = target
	p1.x = tpos.x
	p1.z = tpos.z
#	p1 = target
	$cam.global_transform.origin = p1
	match(_state):
		STATE_INIT:
			_state = STATE_NARRATION
		STATE_NARRATION:
			for e in narration:
				notifications.narration_notification(e)
				_state = STATE_IDLE
		STATE_IDLE:
			var trig: int = randi() % 2
			if Input.is_action_just_pressed("move_east") && trig == 1:
				if $progress.value < 100:
					$progress.value += (2 + randi() % 4)
			if Input.is_action_just_pressed("move_west") && trig == 0:
				if $progress.value < 100:
					$progress.value += (2 + randi() % 4)
			if randf() > 0.9:
				if $progress.value > 0:
					$progress.value -= (1 + randi() % 2)
			if $progress.value >= 99:
				_state = STATE_KICK_TRUNK
		STATE_KICK_TRUNK:
			if $vehicle_camera.global_transform.origin.distance_to($car1.global_transform.origin) < 5.0:
				$car1/trunk_rotate.rotation.x = lerp($car1/trunk_rotate.rotation.x, PI / 6.0, delta * 0.3)
				if abs($car1/trunk_rotate.rotation.x - PI/6.0) < 0.1:
					_state = STATE_FINISH
		STATE_FINISH:
			var sc = load("res://ui/act1_start.tscn")
			get_tree().change_scene_to(sc)
var grass = [
	load("res://elements/forest/grass_1.mesh"),
	load("res://elements/forest/grass_2.mesh"),
	load("res://elements/forest/grass3.mesh"),
	load("res://elements/forest/grass_4.mesh")
]
var big_rocks = [
	load("res://elements/forest/rock1.mesh"),
	load("res://elements/forest/rock2.mesh"),
	load("res://elements/forest/rock3.mesh")
]
var rocks = [
	load("res://elements/forest/rock4.mesh"),
	load("res://elements/forest/rock5.mesh"),
	load("res://elements/forest/rock6.mesh"),
	load("res://elements/forest/rock7.mesh"),
	load("res://elements/forest/rock8.mesh")
]
var trees = [
	load("res://elements/forest/tree1.mesh"),
	load("res://elements/forest/tree3.mesh"),
	load("res://elements/forest/tree4.mesh"),
	load("res://elements/forest/tree5.mesh"),
#	load("res://elements/forest/tree6.mesh")
#	load("res://elements/forest/tree7.mesh")
#	load("res://elements/forest/tree8.mesh")
#	load("res://elements/forest/tree9.mesh")
]
var trees2 = [
	load("res://elements/forest/trees1.mesh"),
#	load("res://elements/forest/trees2.mesh")
]

func rebuild():
	for n in get_tree().get_nodes_in_group("foliage"):
		n.queue_free()
	for c in range(300):
		var n = MeshInstance.new()
		add_child(n)
		var pos = Vector3(randf() * 100.0 - 50.0, 0.0, randf() * 200.0 - 100.0)
		if pos.x >= 0.0 && pos.x < 9.0:
			pos.x += 9.0
		elif pos.x < 0.0 && pos.x > -9.0:
			pos.x -= 9.0
		n.global_transform.origin = pos
		n.global_transform = n.global_transform.rotated(Vector3.UP, randf() * PI)
		n.global_transform.origin = pos
		var choice = randi() % 40
		match(choice):
			1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 17, 18, 19, 20, 21, 22, 23:
				var trees_list = trees + trees2
				n.mesh = trees_list[randi() % trees_list.size()]
			2, 14, 15:
				n.mesh = rocks[randi() % rocks.size()]
			13:
				n.mesh = big_rocks[randi() % big_rocks.size()]
			_:
				n.mesh = grass[randi() % grass.size()]
		n.add_to_group("foliage")
	
func _physics_process(delta):
	if reset_car:
		rebuild()
		$car1.global_transform.origin = car_wrap_pos
		$cam.global_transform.origin = car_wrap_pos
		$vehicle_camera.global_transform.origin = car_wrap_pos + Vector3(0, 2.4, $vehicle_camera.dist)
		reset_car = false
	var car_ll = $car1.linear_velocity
	car_ll.y = 0
	var car_speed = car_ll.length()
	if _state != STATE_KICK_TRUNK:
		if car_speed > 50.0:
			$car1.engine_force *= (1.0 - delta * 0.2)
		if car_speed <= 30.0:
			if $car1.engine_force > 4000.0:
				$car1.engine_force *= (1.0 + delta * 0.2)
			else:
				$car1.engine_force = 4000.0
	else:
			$car1.engine_force = (1.0 - delta * 0.2)
			if car_speed < 10:
				$car1.brake = 4000.0
