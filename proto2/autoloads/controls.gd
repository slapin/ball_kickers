extends Node
signal user_click

var frame_tf: Transform = Transform()
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var master_node: Node
var camera: Camera
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
		
