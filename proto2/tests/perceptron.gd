extends Reference
class_name Perceptron
var weights = []
var learning_rate = 0.15
func _init():
	print("hello perceptron")
	weights.resize(3)
	for i in range(weights.size()):
		weights[i] = randf()
func guess(inputs):
	var sum = 0.0
	for i in range(weights.size()):
		sum += inputs[i] * weights[i]
	var ret = sign(sum)
	return ret
func train(inputs, target):
	var g = guess(inputs)
	var err = target - g
	for i in range(weights.size()):
		weights[i] += err * inputs[i] * learning_rate

