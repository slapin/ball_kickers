extends Reference
class_name LinReg

var data = []
var m = []
var b = []
var errors = []
var size = 30
func _init():
	b.resize(size)
	m.resize(size)
	errors.resize(size)
	for j in range(size):
		b[j] = 0.0
		m[j] = 1.0
	print("hello linreg")
func sample_x():
	var ret = []
	for k in range(size):
		ret.push_back(randf() * 2.0 - 1.0)
	return ret
func iterate(delta):
	var x = sample_x()
	var y = 0.0
	for nx in x:
		y += nx * nx
	y /= size
	data.push_back([x, y])
	linearRegression_gd()
#	print(m)
#	print(b)
	print(errors)
	return false
func linearRegression_sq():
	var xsum = []
	var num = []
	var den = []
	xsum.resize(size)
	num.resize(size)
	den.resize(size)
	for j in range(xsum.size()):
		xsum[j] = 0.0
		num[j] = 0.0
		den[j] = 0.0
		b[j] = 0.0
		m[j] = 1.0
	var ysum = 0.0
	for i in range(data.size()):
		for j in range(data[i][0].size()):
			xsum[j] += data[i][0][j]
			ysum += data[i][1]
	var xmean = []
	for j in range(xsum.size()):
		xmean.push_back(xsum[j] / data.size())
	var ymean = ysum / data.size()
	for i in range(data.size()):
		var x = data[i][0]
		var y = data[i][1]
		for j in range(x.size()):
			num[j] += (x[j] - xmean[j]) * (y - ymean)
			den[j] += (x[j] - xmean[j]) * (x[j] - xmean[j])
	for j in range(size):
		m[j] = num[j] / den[j]
		b[j] = ymean - m[j] * xmean[j]

var learning_rate = 0.15
func linearRegression_gd():
	for e in range(30):
		for i in range(data.size()):
			var x = data[i][0]
			var y = data[i][1]
			for j in range(x.size()):
				var guess = m[j] * x[j] + b[j]
				var error = y - guess
				errors[j] = error
				m[j] += error * x[j] * learning_rate
				b[j] += error * learning_rate
	
