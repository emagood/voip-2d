extends Node

func _ready() -> void:

	var my_arr = [1, 1, 1, 1, 0, 0, 0, 0]
	var result = FFT.fft(my_arr.duplicate(true))
	result = FFT.fft(result)
	prints(result)
	for item in result:
		item.log()
