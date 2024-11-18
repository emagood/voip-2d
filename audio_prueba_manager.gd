extends Node

@onready var input: AudioStreamPlayer
var index: int
var effect: AudioEffectCapture
@onready var playbackNode = $"../AudioStreamPlayer2D"
var playback: AudioStreamGeneratorPlayback
@export var outputPath: NodePath
var inputThreshold: float = 0.1
var receiveBuffer:= PackedFloat32Array()



func _ready():
	playback = get_node(outputPath).get_stream_playback()
	pass

func setupAudio(id):
	input = $input
	set_multiplayer_authority(id)
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)

func _process(delta):
	if multiplayer.is_server():
		pass
	elif is_multiplayer_authority():
		processMic()

func processVoice():
	#if multiplayer.is_server():
		#prints("proces voices server warning")
		
	if receiveBuffer.size() < 1:
		return
	
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)


func test_audio_processing(data: PackedFloat32Array, masking_effect: float = 0.01, aggressive: bool = false):
	prints("Tamaño de datos originales: ", data.size() * 4)  # Tamaño original en bytes
	return

	var complex_data = Array()
	for i in range(data.size()):
		complex_data.append(Complex.new(data[i], 0))  

	# Aplicar FFT
	var fft_data = FFT.fft(complex_data)
	prints("Tamaño de los datos FFT: ", fft_data.size() * 4)

	#coeficientes de Fourier
	var quantized_fft_data = quantize_data(fft_data, masking_effect, aggressive)
	prints("Tamaño de los datos cuantificados: ", quantized_fft_data.size() * 4)


	for i in range(quantized_fft_data.size()):
		if quantized_fft_data[i] == null:
			prints("Error: elemento en `quantized_fft_data` es `nil` en índice ", i)
			return


	var packed_quantized_data = PackedFloat32Array()
	packed_quantized_data.resize(quantized_fft_data.size())
	for i in range(quantized_fft_data.size()):
		packed_quantized_data[i] = quantized_fft_data[i].re

	var compressed_data = compress_audio(packed_quantized_data)
	prints("Tamaño de los datos comprimidos: ", compressed_data.size())


	var decompressed_data = decompress_audio(compressed_data)
	prints("Tamaño de los datos descomprimidos: ", decompressed_data.size())

	if decompressed_data.size() != packed_quantized_data.size():
		prints("Error: tamaño de los datos descomprimidos incorrecto")
		return

	var dequantized_fft_data = Array()
	for i in range(decompressed_data.size()):
		dequantized_fft_data.append(Complex.new(decompressed_data[i], 0))

	var dequantized_data = dequantize_data(dequantized_fft_data, 256)
	prints("Tamaño de los datos de-cuantizados: ", dequantized_data.size())


	var processed_data = FFT.ifft(dequantized_data)
	prints("Tamaño de los datos después de iFFT: ", processed_data.size())

	var real_data = PackedFloat32Array()
	real_data.resize(processed_data.size())
	for i in range(processed_data.size()):
		real_data[i] = processed_data[i].re
	prints(real_data.size(), "datos finales después de todo el proceso")
	
	return real_data



func processMic(masking_effect: float = 0.0003, aggressive: bool = false):
	if multiplayer.is_server():
		print("The server processes mic only if it does not instantiate multiple apps")
	if effect == null:
		return
	var StereoData = effect.get_buffer(effect.get_frames_available())
	
	if StereoData.size() >= 320:
		var data = PackedFloat32Array()
		data.resize(StereoData.size())
		var maxAmplitude = 0.3
		for i in range(StereoData.size()):
			var value = StereoData[i].x + StereoData[i].y
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value

		if maxAmplitude < inputThreshold:
			return

		print("Tamaño de datos originales: ", data.size() * 4)

		var complex_data = Array()
		for i in range(data.size()):
			complex_data.append(Complex.new(data[i], 0))


		var fft_data = FFT.fft(complex_data)
		print("Datos FFT:")
		for item in fft_data:
			if typeof(item) == TYPE_OBJECT and item is Complex:
				if item.re == 0:
					pass
				elif item.im < 0:
					pass
				else:
					pass
			else:
				pass

		var quantized_fft_data = quantize_data(fft_data, masking_effect, aggressive)
		print("Datos Cuantificados:")
		for item in quantized_fft_data:
			if typeof(item) == TYPE_OBJECT and item is Complex:
				if item.re == 0:
					pass
				elif item.im < 0:
					pass
				else:
					pass
			else:
				pass

		for i in range(quantized_fft_data.size()):
			if quantized_fft_data[i] == null:
				print("Error: elemento en `quantized_fft_data` es `nil` en índice ", i)
				return

		# Convertir `quantized_fft_data` a `PackedFloat32Array` para la compresión
		var packed_quantized_data = PackedFloat32Array()
		packed_quantized_data.resize(quantized_fft_data.size())
		for i in range(quantized_fft_data.size()):
			packed_quantized_data[i] = quantized_fft_data[i].re

		# Comprimir los datos cuantificados
		var compressed_data = compress_audio(packed_quantized_data)
		print("Tamaño de los datos comprimidos: ", compressed_data.size())

		sendData.rpc(compressed_data, self.get_path())






func log(complex_number):
	if typeof(complex_number) == TYPE_OBJECT and complex_number is Complex:
		if complex_number.re == 0:
			prints(str(complex_number.im) + "j")
		elif complex_number.im < 0:
			prints(str(complex_number.re) + str(complex_number.im) + "j")
		else:
			prints(str(complex_number.re) + " + " + str(complex_number.im) + "j")
	else:
		prints("Invalid type in log():", str(complex_number))


@rpc("any_peer", "call_remote")
func sendData(compressed_data: PackedByteArray, audioManagerPath: NodePath):
	var decompressed_data = decompress_audio(compressed_data)
	print("Tamaño de los datos descomprimidos: ", decompressed_data.size())


	var dequantized_fft_data = Array()
	for i in range(decompressed_data.size()):
		dequantized_fft_data.append(Complex.new(decompressed_data[i], 0))

	var dequantized_data = dequantize_data(dequantized_fft_data, 256)
	print("Datos De-Cuantificados:")
	for item in dequantized_data:
		if item.re == 0:
			pass
		elif item.im < 0:
			pass
		else:
			pass

	# Aplicar iFFT usando el singleton FFT para regresar al dominio del tiempo
	var processed_data = FFT.ifft(dequantized_data)

	for item in processed_data:
		pass

	# Convertir de números complejos a reales
	var real_data = PackedFloat32Array()
	real_data.resize(processed_data.size())
	for i in range(processed_data.size()):
		real_data[i] = processed_data[i].re
	print(real_data.size(), "datos finales después de todo el proceso")
	
	get_node(audioManagerPath).receiveBuffer.append_array(real_data)
	processVoice()





func format_complex_array(data: Array) -> Array:
	var formatted_data = Array()
	for item in data:
		if typeof(item) == TYPE_OBJECT and item is Complex:
			formatted_data.append(str(item.re) + " + " + str(item.im) + "j")
		else:
			formatted_data.append("Invalid Complex Object")
	return formatted_data



func compress_audio(data: PackedFloat32Array) -> PackedByteArray:
	var byte_array = data.to_byte_array()
	var compressed_data = byte_array.compress(1)  
	return compressed_data






func decompress_audio(compressed_data: PackedByteArray) -> PackedFloat32Array:
	var decompressed_data = compressed_data.decompress_dynamic(-1, 1)  
	return decompressed_data.to_float32_array()






func quantize_data(data: Array, masking_effect: float, aggressive: bool = false) -> Array:
	var bits_needed = calculate_bits_needed(data, masking_effect)
	
	if aggressive:
		bits_needed = max(bits_needed - 1, 1)
	
	var num_levels = pow(2, bits_needed)
	var quantized_data = Array()
	quantized_data.resize(data.size())
	
	if data.size() == 0:
		prints("Error: `data` está vacío.")
		return quantized_data
	
	var min_val = float('inf')
	var max_val = float('-inf')

	for i in range(data.size()):
		if typeof(data[i]) == TYPE_OBJECT and data[i] is Complex:
			min_val = min(min_val, data[i].re)
			max_val = max(max_val, data[i].re)
		else:
			prints("Error: elemento en `data` no es una instancia de Complex en índice ", i)
			return quantized_data

	var range = max_val - min_val
	var step = range / float(num_levels - 1)
	
	for i in range(data.size()):
		if typeof(data[i]) == TYPE_OBJECT and data[i] is Complex:
			var normalized_val = (data[i].re - min_val) / range
			var quantized_val = round(normalized_val * (num_levels - 1)) / (num_levels - 1) * range + min_val
			quantized_data[i] = Complex.new(quantized_val, data[i].im)
		else:
			prints("Error: elemento en `data` no es una instancia de Complex en índice ", i)
			return quantized_data

	
	return quantized_data










func dequantize_data(quantized_data: Array, num_levels: int) -> Array:
	var dequantized_data = Array()
	dequantized_data.resize(quantized_data.size())
	var min_val = float('inf')
	var max_val = float('-inf')


	for i in range(quantized_data.size()):
		if typeof(quantized_data[i]) == TYPE_OBJECT and quantized_data[i] is Complex:
			min_val = min(min_val, quantized_data[i].re)
			max_val = max(max_val, quantized_data[i].re)
		else:
			prints("Error: elemento en `quantized_data` no es una instancia de Complex en índice ", i)
			return dequantized_data

	var range = max_val - min_val
	var step = range / float(num_levels - 1)
	
	for i in range(quantized_data.size()):
		if typeof(quantized_data[i]) == TYPE_OBJECT and quantized_data[i] is Complex:
			var normalized_val = (quantized_data[i].re - min_val) / range
			var dequantized_val = normalized_val * range + min_val
			dequantized_data[i] = Complex.new(dequantized_val, quantized_data[i].im)
		else:
			prints("Error: elemento en `quantized_data` no es una instancia de Complex en índice ", i)
			return dequantized_data
	

	return dequantized_data



func calculate_bits_needed(data: PackedFloat32Array, masking_effect: float) -> int:
	var min_val = data[0]
	var max_val = data[0]


	for i in range(data.size()):

		min_val = data[i]
		if data[i] > max_val:
			max_val = data[i]

	var range = max_val - min_val
	var step = range / 255.0 
	var N = sqrt(12 * masking_effect / pow(step, 2))
	var B = log(N) / log(2)  
	

	return int(ceil(B))



func smooth_data(data: PackedFloat32Array, window_size: int) -> PackedFloat32Array:
	var smoothed_data = PackedFloat32Array()
	smoothed_data.resize(data.size())
	
	for i in range(data.size()):
		var sum = 0.0
		var count = 0
		for j in range(max(0, i - window_size), min(data.size(), i + window_size + 1)):
			sum += data[j]
			count += 1
		smoothed_data[i] = sum / count
	
	return smoothed_data
