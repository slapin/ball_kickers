extends KinematicBody2D
var motion : = Vector2()
enum {STATE_NORMAL, STATE_DIALOGUE}
var state = STATE_NORMAL
func _ready():
	world.master_node = self
func _physics_process(delta):
	match(state):
		STATE_NORMAL:
			var horizontal: float = Input.get_action_strength("move_east") - Input.get_action_strength("move_west")
			var vertical: float = Input.get_action_strength("move_south") - Input.get_action_strength("move_north")
			motion = Vector2(horizontal, vertical) * 140.5
			motion = move_and_slide(motion)
	

func _process(delta):
	match(state):
		STATE_NORMAL:
			if Input.is_action_just_pressed("action1"):
				world.action1()
