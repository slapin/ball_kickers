extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var characters = [load("res://characters/male_2018.tscn"), load("res://characters/female_2018.tscn")]
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
#func _physics_process(delta):
#	for obj in get_tree().get_nodes_in_group("characters"):
#		pass
