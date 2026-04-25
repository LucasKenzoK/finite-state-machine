extends CharacterBody2D

# mov vars
@export_group("Movement")
@export var speed = 200.00
@export var acceleration = 1500.00
@export var friction = 2500.00			## no input
@export var deceleration = 3000.00		## changin direction

@export_group("Jump")
@export var jump_velocity = -400.00
@export var jump_cut_multiplier := 0.4
@export var fall_gravity_multiplier := 2.0
@export var coyote_time = 0.5
@export var jump_buffer_time = 0.5

## States
enum States {IDLE, RUNNING, JUMPING, FALLING}
var current_state: States = States.IDLE

var coyote_timer = 0.0
var jump_buffer_timer = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_update_timers(delta)
	_handle_horizontal(delta)
	_hanlde_jump()
	move_and_slide()
	resolve_state()
	
func _apply_gravity(delta:float) -> void:
	if velocity.y > 0:
		velocity += get_gravity() * fall_gravity_multiplier * delta
	else:
		velocity += get_gravity() * delta

func _update_timers(delta: float) -> void:
	coyote_timer = coyote_time if is_on_floor() else coyote_timer - delta
	jump_buffer_timer = jump_buffer_time if Input.is_action_just_pressed("ui_accept") else jump_buffer_timer - delta

func _hanlde_jump() -> void:
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		coyote_timer = 0
		jump_buffer_timer = 0
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y  *= jump_cut_multiplier

func _handle_horizontal(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right") ##direction == direction pressed
	if direction != 0:
		animated_sprite_2d.flip_h = direction < 0
		if sign(direction) != sign(velocity.x) and velocity.x != 0:
			velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x =  move_toward(velocity.x, 0, friction * delta) 	

func resolve_state() -> void:
	var new_state: States
	if not is_on_floor():
		if velocity.y < 0:
			new_state = States.JUMPING
		else:
			new_state = States.FALLING
	else:
		if abs(velocity.x) > 1.0:
			new_state = States.RUNNING
		else:
			new_state = States.IDLE
	
	if new_state != current_state:
		current_state = new_state
		animate_state()

func animate_state() -> void:
	match current_state:
		States.IDLE:
			animated_sprite_2d.play("Idle")
		States.RUNNING:
			animated_sprite_2d.play("Run")
		States.JUMPING:
			animated_sprite_2d.play("Jump")
		States.FALLING:
			animated_sprite_2d.play("Fall")
