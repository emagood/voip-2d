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
	
		##print("called from: %s; effect: %s; playback: %s" % [id, effect, get_node(outputPath).get_path()])

func _process(delta):
	if multiplayer.is_server():
		return
	#if Input.is_action_pressed("rec") and is_multiplayer_authority():
	elif is_multiplayer_authority():
		processMic()
	


func processMic():
	if multiplayer.is_server():
		prints("The server processes mic only if it does not instantiate multiple apps")
	if effect == null:
		return
	var StereoData: PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if StereoData.size() >= 128:
		var data = PackedFloat32Array()
		data.resize(StereoData.size())
		var maxAmplitude: float = 0.03
		for i in range(StereoData.size()):
			var value = StereoData[i].x + StereoData[i].y
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
	
	
	
		if maxAmplitude < inputThreshold:
			return
	
	
		var bite = data.to_byte_array() #packarray from packarray32float
		prints(bite.size())

		var bite2 = bite.compress(1)# comprimido deflate mode 1
		data = bite2
	
	

	
		prints(data.size(), "  size data compress")
		sendData.rpc(data, self.get_path())
		#sendData.rpc(data, self.get_path())



func processVoice():
	if multiplayer.is_server():
		prints("proces voies server warring")
		
	if receiveBuffer.size() < 1:
		return
	
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)


@rpc("any_peer", "call_remote")
func sendData(data , audioManagerPath: NodePath):

	###if multiplayer.is_server():
		#prints("escuxhoi")
	## descompress data 
	
	var decomp_dynamic: PackedByteArray
	#tipo = "FASTLZ:0" ,"DEFLATE:1" ,"ZSTD:2", "GZIP:3"
	
	decomp_dynamic = data.decompress_dynamic(-1, 1) 

	
	
	# desompress dynamic
	
	#var bit_array:Array = Array(decomp_dynamic)# combert packed array a array
	data = decomp_dynamic.to_float32_array()
	#data = PackedFloat32Array(bit_array)# combert array a packed float 32
	get_node(audioManagerPath).receiveBuffer.append_array(data)
	processVoice()
