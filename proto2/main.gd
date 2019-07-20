extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
var frame_tf: Transform = Transform()

func _ready():
	$master.add_to_group("master")
	controls.master_node = $master
	world.init_data()
	for k in world.line.keys():
		var cd = world.line[k]
		if cd.type == 0:
			var char_sc = load("res://characters/male_2018.tscn").instance()
			cd.scene = char_sc
			get_tree().get_root().add_child(char_sc)
			var nav: Navigation2D = get_node("nav")
			var p = nav.get_closest_point(get_node("line_spawn").global_transform.origin + Vector3(randf() * 20.0 - 10.0, 0.0, randf() * 20 - 10.0))
			char_sc.translation = p
#			world.team[newkey] = cd
#			world.line.erase(k)
		else:
			var char_sc = load("res://characters/female_2018.tscn").instance()
			cd.scene = char_sc
			get_tree().get_root().add_child(char_sc)
			var nav: Navigation2D = get_node("nav")
			var p = nav.get_closest_point(get_node("line_spawn").global_transform.origin + Vector3(randf() * 20.0 - 10.0, 0.0, randf() * 20 - 10.0))
			char_sc.translation = p
#			world.team[newkey] = cd
#		cd.scene.set_meta("data", cd)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var pos = $master.global_transform.origin
	pos.y = $Camera.global_transform.origin.y
	$Camera.global_transform.origin = $Camera.global_transform.origin.linear_interpolate(pos, 0.53 * delta)
