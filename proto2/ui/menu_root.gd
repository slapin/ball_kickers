extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.

func start_game():
	var sc = load("res://prologue.tscn")
	world.init_data()
	roadmap.build(444444)
	get_tree().change_scene_to(sc)
func load_game():
	pass
func display_options():
	var sc = load("res://ui/options.tscn")
	get_tree().change_scene_to(sc)
func display_development():
	var sc = load("res://ui/development_menu.tscn")
	get_tree().change_scene_to(sc)
func quit_game():
	get_tree().quit()
func _ready():
	$VBoxContainer/exit.connect("pressed", self, "quit_game")
	$VBoxContainer/start.connect("pressed", self, "start_game")
	$"VBoxContainer/load".connect("pressed", self, "load_game")
	$VBoxContainer/options.connect("pressed", self, "display_options")
	$VBoxContainer/development.connect("pressed", self, "display_development")
