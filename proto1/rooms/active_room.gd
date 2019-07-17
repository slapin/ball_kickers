extends Node2D
signal room_event

var bodies = []
func room_entered(body):
	print("entered " + name)
	if body.name == "master":
		world.current_room = self
	bodies.push_back(body)

func room_exited(body):
	print("exited " + name)
	if body.name == "master":
		if world.current_room == self:
			world.current_room = null
	bodies.erase(body)
func room_event(event):
	print("room: ", name, "room_event: ", event)
	emit_signal("room_event", name, event)
func point_in_room(p: Vector2) -> bool:
	var shape:CollisionShape2D = $Area2D/CollisionShape2D
	
	
	return false
func _ready():
	$Area2D.connect("body_entered", self, "room_entered")
	$Area2D.connect("body_exited", self, "room_exited")
	world.register_room_event(self, "action1", "room_event")
	add_to_group("rooms")
