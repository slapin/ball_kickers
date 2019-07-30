extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("activatable")

func get_act():
	return "Get a ball"
func activate():
	print("Getting a ball...")
	var ball_st = load("res://items/ball/ball.tscn").instance()
	get_node("/root/main").add_child(ball_st)
	ball_st.global_transform = world.master_node.global_transform
	ball_st.global_transform.origin += ball_st.global_transform.xform(Vector3(0, 0.5, -0.25))
	ball_st.taken(world.master_node)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
