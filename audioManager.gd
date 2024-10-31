extends Node

@onready var input: AudioStreamPlayer
var index: int
var effect: AudioEffectCapture
@onready var playbackNode = $"../AudioStreamPlayer2D"
var playback: AudioStreamGeneratorPlayback
@export var outputPath: NodePath
var inputThreshold: float = 0.005
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
		processMic()
	
	elif is_multiplayer_authority() and !multiplayer.is_server():
		processMic()
		processVoice()


func processMic():
	if multiplayer.is_server():
		prints("The server processes mic only if it does not instantiate multiple apps")
	if effect == null:
		return
	var StereoData: PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if StereoData.size() > 1020:
		var data = PackedFloat32Array()
		data.resize(StereoData.size())
		var maxAmplitude: float = 0.01
		
		for i in range(StereoData.size()):
			var value = StereoData[i].x 
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
	
	
	
		if maxAmplitude < inputThreshold:
			return
		var size_array = 0
		var tipo = 3
		## compress
		var bite = data.to_byte_array() #packarray from packarray32float
		var bite_3 = bite
		var bite_0 = bite
		size_array = bite.size()
		var bite2 = bite.compress(1)# comprimido deflate mode 1
		var bite3 = bite_3.compress(3)# comprimido deflate mode 3
		var bite4 = bite_0.compress(2)# comprimido deflate mode 2
	
	
	
		if bite2.size() <= bite3.size() and bite4.size():
			data = bite2
			tipo = 1
		elif bite2.size() >= bite3.size() and bite4.size():
			data = bite3
			tipo = 2
			prints(data.size()," bite3")
		else :
			tipo = 3
			data = bite4
			prints(data.size()," bite4")
	
	
	
		sendData.rpc(data,tipo,size_array , self.get_path())



func processVoice():
	if multiplayer.is_server():
		prints("proces voies server warring")
		
	if receiveBuffer.size() <= 1024:
		return
	
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)



@rpc("any_peer", "call_remote")
func sendData(data, tipo,size_array , audioManagerPath: NodePath):

	###if multiplayer.is_server():
		#prints("escuxhoi")
	## descompress data 
	
	var decomp_dynamic: PackedByteArray
	#tipo = "FASTLZ:0" ,"DEFLATE:1" ,"ZSTD:2", "GZIP:3"
	if tipo == 1 :
		decomp_dynamic = data.decompress_dynamic(-1, 1) 
	if tipo == 2:
		decomp_dynamic = data.decompress_dynamic(-1, 3) 
	elif tipo == 3:
		decomp_dynamic = data.decompress_dynamic(size_array, 2)
	
	
	# desompress dynamic
	
	var bit_array:Array = Array(decomp_dynamic)# combert packed array a array
	data = PackedFloat32Array(bit_array)# combert array a packed float 32
	
	get_node(audioManagerPath).receiveBuffer.append_array(data)
	
