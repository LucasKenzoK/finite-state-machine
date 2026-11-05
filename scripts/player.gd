extends Character

# mov vars
@export_group("Movement")
@export var speed := 200.00
@export var acceleration := 1500.00
@export var friction := 2500.00			
@export var deceleration := 3000.00		

@export_group("Jump")
@export var jump_velocity := -400.00
@export var jump_cut_multiplier := 0.4
@export var coyote_time := 0.5
@export var jump_buffer_time := 0.5

## States
enum States {IDLE, RUNNING, JUMPING, FALLING}
var current_state: States = States.IDLE

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var jump_particles: CPUParticles2D = $CPUParticles2D

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_apply_gravity(delta)
	_update_timers(delta)
	_handle_horizontal(delta)
	_handle_jump()
	move_and_slide()
	resolve_state()

func _ready() -> void:
	health_changed.connect(func(current, maximum): print("HP: %d/%d" % [current, maximum])) ### DEBUG HEALTH

func _unhandled_input(event: InputEvent) -> void: ## DEBUG DANO
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		take_damage(10)

func _on_damaged(_amount: int, _source: Node) -> void:
	print("Hurt")

func _on_death() -> void:
	animated_sprite_2d.modulate = Color.RED
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
	queue_free()

func _update_timers(delta: float) -> void:
	coyote_timer = coyote_time if is_on_floor() else coyote_timer - max(coyote_timer - delta, 0.0)
	jump_buffer_timer = jump_buffer_time if Input.is_action_just_pressed("ui_accept") else jump_buffer_timer - delta

func _handle_jump() -> void:
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
		_on_state_changed(current_state, new_state)
		current_state = new_state
		animate_state()

func _on_state_changed(from: States , to: States) -> void:
	if to == States.JUMPING:
		animation_player.stop()
		animation_player.play("Jump_start")
		_burst_particles()
		
	elif to == States.IDLE or to == States.RUNNING:
		if from == States.FALLING or from == States.JUMPING:
			animation_player.stop()
			animation_player.play("Jump_land")
			_burst_particles()

func _burst_particles() -> void:
	jump_particles.restart()
	jump_particles.emitting = true

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
