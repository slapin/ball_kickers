extends RigidBody
class_name Item

var _taken: bool = false
var _taken_by: Object
var _dropped: bool = false
var _dropped_by: Object
var is_at_hands: bool = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("activatable")
	add_to_group("items")

func get_take_act():
	return "Take item"

func get_drop_act():
	return "Drop item"

func get_act():
	if is_at_hands:
		return get_drop_act()
	else:
		return get_take_act()
func activate():
	if is_at_hands:
		dropped(world.master_node)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _taken_act(pobj):
	mode = RigidBody.MODE_KINEMATIC
	collision_layer = 16
	collision_mask = 16 | 2
	get_parent().remove_child(self)
	pobj.add_child(self)
	transform = Transform()
	set_as_toplevel(false)
	is_at_hands = true
func _dropped_act(pobj):
	mode = RigidBody.MODE_RIGID
	collision_layer = 1
	collision_mask = 1 | 2
	get_parent().remove_child(self)
	world.master_node.get_node("/root/main").add_child(self)
	global_transform = pobj.global_transform
	set_as_toplevel(true)
	is_at_hands = false
func _physics_process(delta):
	if _taken:
		_taken_act(_taken_by)
		_taken = false
		_taken_by = null
	if _dropped:
		_dropped_act(_dropped_by)
		_dropped = false
		_dropped_by = null
func taken(pobj):
	_taken = true
	_taken_by = pobj
func dropped(pobj):
	_dropped = true
	_dropped_by = pobj
