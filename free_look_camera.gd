#Copyright © 2022 Marc Nahr: https://github.com/MarcPhi/godot-free-look-camera
extends Camera3D

@export_range(0, 10, 0.01) var sensitivity: float = 3
@export_range(0, 1000, 0.1) var default_velocity: float = 5
@export_range(0, 10, 0.01) var speed_scale: float = 1.17
@export_range(1, 100, 0.1) var boost_speed_multiplier: float = 3.0

@onready var _velocity = default_velocity

func _enter_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if not current:
		return
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation.y -= event.relative.x / 1000 * sensitivity
			rotation.x -= event.relative.y / 1000 * sensitivity
			rotation.x = clamp(rotation.x, PI / -2, PI / 2)
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	if not current:
		return
		
	var direction = Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()
	
	var velocity = _velocity;
	if Input.is_physical_key_pressed(KEY_SHIFT): # boost
		velocity *= boost_speed_multiplier
	
	translate(direction * velocity * delta)
