extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
var delay: float = 8.0
var sg = 1.0
func _process(delta):
	if delay < 0.0:
		var sc = load("res://main.tscn")
		world.init_data()
		get_tree().change_scene_to(sc)
	delay -= delta


