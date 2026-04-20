extends CharacterBody2D

# mov vars
@export var speed = 200.00
@export var acceleration = 1500.00
@export var friction = 1000.00
@export var jump_velocity = -400.00
@export var jump__cut_multiplier := 0.4

@export var fall_gravity_multiplier = 2

@export var coyote_time = 0.5
var coyote_timer = 0.0

@export var jump_buffer_time = 0.5
var jump_buffer_timer = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
		
	# Gravity w/ multiplier
	if velocity.y > 0:
		velocity += get_gravity() * fall_gravity_multiplier * delta
	else:
		velocity += get_gravity() * delta

	
	# Coyote Jump
	if is_on_floor(): 
		coyote_timer = coyote_time
	else: coyote_timer -= delta

	# Jump Buffer
	if Input.is_action_just_pressed("ui_accept"): 
		jump_buffer_timer = jump_buffer_time
	else: jump_buffer_timer -= delta

	#Jump logic
	
	if jump_buffer_timer > 0 and coyote_timer > 0:
		
		velocity.y = jump_velocity
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= jump__cut_multiplier
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()
