tool
extends EditorScenePostImport

func post_import(scene):
	for g in scene.get_children():
		if g is VehicleBody:
			var car_data = g.name.split("-", true)
			if car_data.size() > 1:
				var bodymass = float(car_data[car_data.size() - 1])
				g.mass = bodymass
				var new_name = []
				for c in range(car_data.size() - 1):
					new_name += [car_data[c]]
				g.name = PoolStringArray(new_name).join("-")
			g.transform = g.transform.rotated(Vector3(0, 1, 0), PI)
			var queue = [g]
			while queue.size() > 0:
				var item = queue.pop_front()
				if item is VehicleWheel:
					var wheel_data = item.name.split("-", true)
					if wheel_data.size() > 1:
						var wheel_radius : = float(wheel_data[wheel_data.size() - 1]) / 10.0
						item.wheel_radius = wheel_radius
				if item.name == "collision":
					var mesh: ArrayMesh = item.mesh
					var hull = mesh.create_convex_shape()
					var col = CollisionShape.new()
					col.shape = hull
					col.name = "col"
					g.add_child(col)
					col.owner = g
					item.queue_free()
					continue
				item.owner = g
				for c in item.get_children():
					queue.push_back(c)
			var new_scene = PackedScene.new()
			var res = new_scene.pack(g)
			if res == OK:
				ResourceSaver.save("res://vehicles/cars/car_" + g.name + ".tscn", new_scene)
			scene.remove_child(g)
			scene.add_child(new_scene.instance())
	return scene
