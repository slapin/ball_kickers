extends MainLoop

var pct
var dataset

func build_training_set():
	var data = []
	for k in range(400000):
		var x = randf() * 2.0 - 1.0
		var y = randf() * 2.0 - 1.0
		var label = 0
		if x > y:
			label = 1
		else:
			label = -1
		data.push_back([x, y, label])
	return data

func _initialize():
	print("hello, world!")
	pct = Perceptron.new()
	dataset = build_training_set()
	for i in range(dataset.size()):
		var pt = dataset[i]
		pct.train([pt[0], pt[1], 1.0], pt[2])
	return 
func _iteration(delta):
	if dataset.size() == 0:
		return true
	var pt = dataset.pop_front()
	var output = pct.guess([pt[0], pt[1], 1.0])
	print(output, " / ", pt[2] - output)
	return false

