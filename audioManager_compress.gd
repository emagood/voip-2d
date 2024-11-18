extends Node



@onready var input: AudioStreamPlayer
var index: int
var effect: AudioEffectCapture
@onready var playbackNode = $"../AudioStreamPlayer2D"
var playback: AudioStreamGeneratorPlayback
@export var outputPath: NodePath
var inputThreshold: float = 0.1
var receiveBuffer:= PackedFloat32Array()
var data_buffer = PackedFloat32Array()
var buffer_size_threshold = 1024



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

		return
	#if Input.is_action_pressed("rec") and is_multiplayer_authority():
	elif is_multiplayer_authority():
		processMic()






func processVoice():
	#if multiplayer.is_server():
		#prints("proces voies server warring")
		
	if receiveBuffer.size() < 1:
		return
	
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)




func quantize_data(data: PackedFloat32Array, masking_effect: float, aggressive: bool = false, similar_numbers_equal: bool = false) -> PackedFloat32Array:
	#prints("quantized data size ", data.size())
	var min_val = data[0]
	var max_val = data[0]
	for i in range(data.size()):
		if data[i] < min_val:
			min_val = data[i]
		if data[i] > max_val:
			max_val = data[i]

	var range = max_val - min_val
	var step = range / 512 #  256 niveles
	var N = sqrt(12 * masking_effect / pow(step, 2))
	var B = log(N) / log(2)  
	var bits_needed = int(ceil(B))

	if aggressive:
		bits_needed = max(bits_needed - 1, 1)
	
	var num_levels = pow(2, bits_needed)
	var quantized_data = PackedFloat32Array()
	quantized_data.resize(data.size())
	
	step = range / float(num_levels - 1)
	
	var quantization_levels = Array()
	
	for i in range(num_levels):
		quantization_levels.append(min_val + i * step)

	for i in range(data.size()):
		var normalized_val = (data[i] - min_val) / range
		var quantized_val = round(normalized_val * (num_levels - 1)) / (num_levels - 1) * range + min_val
		quantized_data[i] = quantized_val

	if similar_numbers_equal:
		#print(max_val, "  ", min_val, "  ", min_val * max_val)
		var similarity_tolerance = 0.0001 # Tolerancia 
		var low_value_threshold = -0.3 # ajuste inmediato de valores bajos
		var reference_values = Array()
		var ref_size = 1096 # array de referecia
		var added_values = 0

		for i in range(data.size()):
			var current_val = quantized_data[i]
			
			# Ajuste inmediato para valores bajos
			if current_val < low_value_threshold:
				quantized_data[i] = -0.300000
				continue

			var found = false

			for j in range(reference_values.size()):
				if abs(current_val - reference_values[j]) < similarity_tolerance:
					quantized_data[i] = min(current_val, reference_values[j])
					# print("Encontrado valor similar:", current_val, "igualado a:", quantized_data[i]) # Imprimir cuando se encuentra un valor similar y se iguala
					found = true
					break

			if not found:
				if added_values < ref_size:
					reference_values.append(current_val)
					added_values += 1
				else:
					print("Array de referencia lleno. Reiniciando y llenando con nuevos valores.")
					reference_values.clear()
					reference_values.append(current_val)
					added_values = 1  

	return quantized_data




func dequantize_data(quantized_data: PackedFloat32Array, num_levels: int, min_val: float = -1.0, max_val: float = -1.0) -> PackedFloat32Array:
	var dequantized_data = PackedFloat32Array()
	dequantized_data.resize(quantized_data.size())

	if min_val == -1.0 or max_val == -1.0:
		min_val = quantized_data[0]
		max_val = quantized_data[0]
		for i in range(quantized_data.size()):
			if quantized_data[i] < min_val:
				min_val = quantized_data[i]
			if quantized_data[i] > max_val:
				max_val = quantized_data[i]

	var range = max_val - min_val
	var step = range / float(num_levels - 1)
	
	for i in range(quantized_data.size()):
		var normalized_val = (quantized_data[i] - min_val) / range
		var dequantized_val = normalized_val * range + min_val
		dequantized_data[i] = dequantized_val
	
	# Interpolación directa dentro de dequantize_data
	var interpolated_data = PackedFloat32Array()
	interpolated_data.resize(dequantized_data.size())
	for i in range(dequantized_data.size()):
		if i > 0 and i < dequantized_data.size() - 1:
			interpolated_data[i] = (dequantized_data[i - 1] + dequantized_data[i] + dequantized_data[i + 1]) / 3
		else:
			interpolated_data[i] = dequantized_data[i]
	dequantized_data = interpolated_data

	var smoothed_data = smooth_data(dequantized_data, 4)
	
	return smoothed_data





# Definimos un buffer global y el umbral fuera de la función


func processMic(masking_effect: float = 0.0001, aggressive: bool = true):
	if effect == null:
		return

	var StereoData = effect.get_buffer(effect.get_frames_available())
	# prints(StereoData.size())
	if StereoData.size() >= 512:
		var new_data = PackedFloat32Array()
		new_data.resize(StereoData.size())
		var maxAmplitude = 0.01
		for i in range(StereoData.size()):
			var value = StereoData[i].x + StereoData[i].y
			maxAmplitude = max(value, maxAmplitude)
			new_data[i] = value
		
		if maxAmplitude < inputThreshold:
			prints("menor amplitude array borrado y cache  ")
			data_buffer = PackedFloat32Array()
			new_data = PackedFloat32Array()
			StereoData = PackedFloat32Array()
			
			return
		elif maxAmplitude > 1.2:
			data_buffer = PackedFloat32Array()
			new_data = PackedFloat32Array()
			StereoData = PackedFloat32Array()
			return
			
		elif maxAmplitude >= 0.8:
			aggressive = true
			prints("major 'o' igual 0.8")
			masking_effect = 0.001
			
		elif maxAmplitude < 0.8 and maxAmplitude > 0.3:
			prints("menor a 0.8 pero mayor a 3")
			masking_effect = 0.0008
			aggressive = true
		else:
			prints("mayor a 0.09")
			masking_effect = 0.0001
			aggressive = true
			
		#	prints("amplitud es alta ay datos y audio ")
			pass
		# Agregar los nuevos datos al buffer global en orden
		data_buffer.append_array(new_data)
		
		# Verificar si el buffer ha alcanzado el tamaño umbral
		if data_buffer.size() >= buffer_size_threshold:
			# Tomar los primeros 2024 datos para procesar
			var data_to_process = data_buffer.slice(0, buffer_size_threshold)
			
			# Eliminar los datos procesados del buffer
			var remaining_data = data_buffer.slice(buffer_size_threshold, data_buffer.size())
			data_buffer = PackedFloat32Array()
			data_buffer.append_array(remaining_data)
			
		
			prints("Tamaño de datos originales: ", data_to_process.size() * 4)  # Cada float32 ocupa 4 bytes
			
			var compressed_data_no_cuantize = compress_audio(data_to_process)
			
			# Imprimir tamaño de los datos sin cuantificar
			prints("Tamaño de los datos comprimidos sin cuantificar: ", compressed_data_no_cuantize.size())
			
			var quantized_data = quantize_data(data_to_process, masking_effect, aggressive, true)  
			
		
			prints("Tamaño de los datos cuantificados: ", quantized_data.size() * 4)
			
			var compressed_data = compress_audio(quantized_data)
			
		
			prints("Tamaño de los datos cuantificados comprimidos: ", compressed_data.size())
			
			sendData.rpc(compressed_data, self.get_path())
	else:
		return



@rpc("any_peer", "call_remote")
func sendData(compressed_data, audioManagerPath: NodePath):
	
	
	var quantized_data = decompress_audio(compressed_data)
	var data = dequantize_data(quantized_data, 512)
	#prints("Tamaño de datode descomprimidos recuperados " , quantized_data.size())
	get_node(audioManagerPath).receiveBuffer.append_array(quantized_data)
	processVoice()



func calculate_bits_needed(data: PackedFloat32Array, masking_effect: float) -> int:
	var min_val = data[0]
	var max_val = data[0]

	# mínimos y máximos 
	for i in range(data.size()):
		if data[i] < min_val:
			min_val = data[i]
		if data[i] > max_val:
			max_val = data[i]

	var range = max_val - min_val
	var step = range / 255.0  #  256 niveles 
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

	
func compress_audio(data: PackedFloat32Array) -> PackedByteArray:
	var byte_array = data.to_byte_array()
	var compressed_data = byte_array.compress(1)  # Usando DEFLATE mode 1
	return compressed_data










# Función para descomprimir datos de audio
func decompress_audio(compressed_data: PackedByteArray) -> PackedFloat32Array:
	var decompressed_data = compressed_data.decompress_dynamic(-1, 1)  # Usando DEFLATE
	return decompressed_data.to_float32_array()
