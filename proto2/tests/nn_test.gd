extends MainLoop

var nn
var train_ds = [
	[1, 0, 1],
	[0, 1, 1],
	[0, 0, 0],
	[1, 1, 0]
]
func _initialize():
	print("hello, world!")
	nn = NeuralNetwork.new(2, 2, 1)
#	var o = nn.feedforward([1,2,3])
#	print(o)
	for k in range(10000):
		for k in range(train_ds.size()):
			var d = randi() % train_ds.size()
			var e = train_ds[d]
			var inputs = [e[0], e[1]]
			var targets = [e[2]]
			nn.train(inputs, targets)
	print(nn.feedforward([0, 0]))
	print(nn.feedforward([1, 0]))
	print(nn.feedforward([0, 1]))
	print(nn.feedforward([1, 1]))
func _iteration(delta):
	return true

