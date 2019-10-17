extends Node

func _ready():
	var dnatool : = DNATool.new()
	var pt : = Vector3(0.25, 0.25, 3)
	var p1 : = Vector3(0, 0, 0)
	var p2 : = Vector3(1, 0, 0)
	var p3 : = Vector3(0, 1, 0)
	var bc = dnatool.get_baricentric(pt, p1, p2, p3)
	print(bc)
	print([1.0 - bc.x, 1.0 - bc.y, 1.0 - bc.z])
	print(p1 * bc.x + p2 * bc.y + p3 * bc.z)
