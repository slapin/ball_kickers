extends Reference
class_name NeuralNetwork

class Matrix:
	var r
	var c
	var data = []
	func _init(rows, cols):
		r = rows
		c = cols
		data.resize(r * c)
		for i in range(r):
			for j in range(c):
				data[i * c + j] = 0.0
	func _s(row, col, value):
		data[row * c + col] = value
	func _g(row, col):
		return data[row * c + col]
	static func multiply(m1, m2):
		assert(m1.c == m2.r)
		var result = Matrix.new(m1.r, m2.c)
		for i in range(result.r):
			for j in range(result.c):
				var sum = 0.0
				for k in range(m1.c):
					sum += m1.data[i * m1.c + k] * m2.data[k * m2.c + j]
				result.data[i * result.c + j] = sum
		return result
	
	func multiply_elementwise(val):
		if val is Matrix:
			for i in range(data.size()):
				data[i] *= val.data[i]
		else:
			for i in range(data.size()):
				data[i] *= val
	func add(val):
		if val is Matrix:
			for i in range(data.size()):
				data[i] += val.data[i]
		else:
			for i in range(data.size()):
				data[i] += val
	func randomize():
		for i in range(data.size()):
			data[i] = floor(randf() * 2.0 - 1.0)
	func transposed():
		var result = Matrix.new(c, r)
		for i in range(r):
			for j in range(c):
				result.data[j * result.c + i] = data[i * c + j]
		return result
	static func transpose(mat):
		var result = Matrix.new(mat.c, mat.r)
		for i in range(mat.r):
			for j in range(mat.c):
				result.data[j * result.c + i] = mat.data[i * mat.c + j]
		return result
	static func from_array(arr):
		var m = Matrix.new(arr.size(), 1)
		for i in range(m.data.size()):
			m.data[i] = arr[i]
		return m
	static func subtract(m1, m2):
		var result = Matrix.new(m1.r, m1.c)
		for e in range(m1.data.size()):
			result.data[e] = m1.data[e] -  m2.data[e]
		return result
	func display():
		print("[")
		for i in range(r):
			var mat_row = "\t[ "
			for j in range(c):
				mat_row += str(data[i * c + j])
				if j < c - 1:
					mat_row += " "
				else:
					mat_row += " ]"
			print(mat_row)
		print("]")
	func map(obj, f):
		for e in range(data.size()):
			var val = obj.call(f, data[e])
			data[e] = val
	static func map_s(m, obj, f):
		var result = Matrix.new(m.r, m.c)
		for e in range(m.data.size()):
			var val = obj.call(f, m.data[e])
			result.data[e] = val
		return result
	func to_array():
		return data
	
			
var input_nodes
var hidden_nodes
var output_nodes
var weights_ih
var weights_ho
var bias_h
var bias_o
var learning_rate = 0.1
# 3Blue1Brown
func tst(data):
	return 1.0
func sigmoid(x):
	return 1.0 / (1.0 + exp(-x))
func dsigmoid(x):
	return x * (1.0 - x)
func feedforward(inputs_array):
	# Hidden outputs
	var inputs = Matrix.from_array(inputs_array)
	var hidden = Matrix.multiply(weights_ih, inputs)
	hidden.add(bias_h)
	hidden.map(self, "sigmoid")

	var output = Matrix.multiply(weights_ho, hidden)
	output.add(bias_o)
	output.map(self, "sigmoid")
	
	return output.to_array()
func train(inputs_array, targets_array):
	var inputs = Matrix.from_array(inputs_array)
	var hidden = Matrix.multiply(weights_ih, inputs)
	hidden.add(bias_h)
	hidden.map(self, "sigmoid")

	var outputs = Matrix.multiply(weights_ho, hidden)
	outputs.add(bias_o)
	outputs.map(self, "sigmoid")

	var targets = Matrix.from_array(targets_array)
	var output_errors = Matrix.subtract(targets, outputs)
	var gradients = Matrix.map_s(outputs, self, "dsigmoid")
	gradients.multiply_elementwise(output_errors)
	gradients.multiply_elementwise(learning_rate)

	var hidden_T = Matrix.transpose(hidden)
	var weights_ho_deltas = Matrix.multiply(gradients, hidden_T)
	weights_ho.add(weights_ho_deltas)
	bias_o.add(gradients)

	var who_t = Matrix.transpose(weights_ho)
	var hidden_errors = Matrix.multiply(who_t, output_errors)
	var hidden_gradients = Matrix.map_s(hidden, self, "dsigmoid")
	hidden_gradients.multiply_elementwise(hidden_errors)
	hidden_gradients.multiply_elementwise(learning_rate)
	var inputs_T = Matrix.transpose(inputs)
	var weights_ih_deltas = Matrix.multiply(hidden_gradients, inputs_T)
	weights_ih.add(weights_ih_deltas)
	bias_h.add(hidden_gradients)
	
	
#	outputs.display()
#	targets.display()
#	error.display()
	
func _init(numI, numH, numO):
	input_nodes = numI
	hidden_nodes = numH
	output_nodes = numO
	weights_ih = Matrix.new(hidden_nodes, input_nodes)
	weights_ho = Matrix.new(output_nodes, hidden_nodes)
	weights_ih.randomize()
	weights_ho.randomize()
	bias_h = Matrix.new(hidden_nodes, 1)
	bias_h.randomize()
	bias_o = Matrix.new(output_nodes, 1)
	bias_o.randomize()
	

#	var matrix = Matrix.new(3, 2)
#	matrix.randomize()
#	matrix.display()
#	var matrix2 = Matrix.new(2, 3)
#	matrix2.randomize()
#	matrix2.display()
#	var matrix3 = Matrix.multiply(matrix, matrix2)
#	matrix3.display()
#	Matrix.transpose(matrix3).display()
#	matrix3.map(self, "tst")
#	matrix3.display()


