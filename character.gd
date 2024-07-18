extends Node2D

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	pass

func _ready():
	$Label.text = name
	get_node("audioManager").setupAudio(name.to_int())


func _physics_process(delta):
	if !is_multiplayer_authority():
		return
	
	if Input.is_action_pressed("ui_left"):
		self.position.x -= 10
	elif Input.is_action_pressed("ui_right"):
		self.position.x += 10
	elif Input.is_action_pressed("ui_down"):
		self.position.y -= 10
	elif Input.is_action_pressed("ui_up"):
		self.position.y += 10
