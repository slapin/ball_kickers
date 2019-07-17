extends RigidBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var update = false
var kinematic = false
var new_parent
var new_position
var impulse = Vector2()
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _physics_process(delta):
	if update:
		if new_position:
			if mode == RigidBody2D.MODE_KINEMATIC:
				global_position = new_position
			else:
				apply_impulse(Vector2(), (new_position - global_position) * mass)
			new_position = null
		elif kinematic:
			mode = RigidBody2D.MODE_KINEMATIC
			collision_mask = 0
			collision_layer = 2
			position = Vector2()
			if get_parent() && new_parent:
				get_parent().remove_child(self)
				new_parent.add_child(self)
		else:
			mode = MODE_RIGID
			collision_mask = 1
			collision_layer = 1
			var old_pos = global_position
			if get_parent() && new_parent:
				get_parent().remove_child(self)
				new_parent.add_child(self)
			global_position = old_pos
			apply_impulse(Vector2(), impulse)
		update = false
		
