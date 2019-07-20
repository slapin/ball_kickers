extends Node

var frame_tf: Transform = Transform()
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var master_node: Node
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !master_node:
		return
	if Input.is_action_pressed("move_north"):
		var n = lerp(master_node.get_walk_speed(), 2.8, 0.4 * delta)
		master_node.set_walk_speed(n)
		master_node.walk()
	else:
		var n = lerp(master_node.get_walk_speed(), 1.0, 0.4 * delta)
		master_node.set_walk_speed(n)
		master_node.idle()
	if Input.is_action_pressed("move_east"):
		var tf_turn = Transform(Quat(Vector3(0, 1, 0), -PI * 0.6 * delta))
		frame_tf *= tf_turn
	if Input.is_action_pressed("move_west"):
		var tf_turn = Transform(Quat(Vector3(0, 1, 0), PI * 0.6 * delta))
		frame_tf *= tf_turn

