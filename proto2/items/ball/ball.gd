extends Item

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _taken_act(pobj):
	mode = RigidBody.MODE_KINEMATIC
	collision_layer = 16
	collision_mask = 16 | 2
	get_parent().remove_child(self)
	if pobj.is_in_group("characters"):
		pobj.ball_carry.add_child(self)
		pobj.item_right_hand = self
		remove_from_group("activatable")
		print("character")
	else:
		pobj.add_child(self)
		print("NOT character")
	set_as_toplevel(false)
	transform = Transform()
	is_at_hands = true
	print("ball: taken")
func _dropped_act(pobj):
	._dropped_act(get_parent())
	pobj.item_right_hand = null
	add_to_group("activatable")
	print("ball: dropped")

func get_take_act():
	return "Take ball"

func get_drop_act():
	return "Drop ball"

func activate():
	if is_at_hands:
		dropped(world.master_node)
		world.emit_signal("start_training", self)
	else:
		taken(world.master_node)
