extends Character

@export var speed:= 60.0
@export var run_time_rang := Vector2(2.0, 4.0) 
@export var idle_time_rang := Vector2(1.0, 3.0)
@export var attack_range := 40.0
@export var attack_range_buffer := 10.0

enum States {IDLE, RUNNING, CHASING, ATTACKING}
var target: Node2D = null
var current_state: States = States.RUNNING

var direction := -1

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ledge_check: RayCast2D = $RayCast2D
@onready var state_timer: Timer = $Timer
@onready var alert_icon: Label = $AlertIcon
@onready var alert_base_scale := alert_icon.scale
@onready var vision_area: Area2D = $Area2D
@onready var vision_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	if is_dead:
		alert_icon.reset_size()
		alert_icon.pivot_offset = alert_icon.size / 2.0
		alert_icon.position.x = -alert_icon.size.x / 2.0
		return
	ledge_check.position.x = abs(ledge_check.position.x) * direction
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	animated_sprite_2d.flip_h = direction < 0
	state_timer.one_shot = true
	state_timer.timeout.connect(_on_state_timer_timout)
	_set_state(States.RUNNING)

	health_changed.connect(func(current, maximum): print("HP: %d/%d" % [current, maximum])) ### DEBUG HEALTH

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_apply_gravity(delta)	
	_update_direction_to_target()
	_update_attack_state()


	match current_state:
		States.RUNNING, States.CHASING:
			velocity.x = direction * speed
		States.IDLE, States.ATTACKING:
			velocity.x = 0.0
	move_and_slide()
	if current_state == States.RUNNING or current_state == States.CHASING:
		_chech_turn()

func _unhandled_input(event: InputEvent) -> void: ## DEBUG DANO
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		take_damage(10)

func _update_attack_state() -> void:
	if target == null or current_state == States.IDLE or current_state == States.RUNNING:
		return
	var dist := global_position.distance_to(target.global_position)
	if current_state == States.CHASING and dist <= attack_range:
		_set_state(States.ATTACKING)
	if current_state == States.ATTACKING and dist > attack_range + attack_range_buffer:
		_set_state(States.CHASING)

func _on_damaged(_amount: int, _source: Node) -> void:
	print("Hurt")

func _on_death() -> void:
	animated_sprite_2d.modulate = Color.RED
	await get_tree().create_timer(1.0).timeout

func _chech_turn() -> void:
	if not is_on_floor():
		return
	if is_on_wall() or not ledge_check.is_colliding():
		flip()

func _set_state(new_state: States) -> void:
	var was_alerted := current_state == States.CHASING or current_state == States.ATTACKING
	current_state = new_state
	var is_alerted := current_state == States.CHASING or current_state == States.ATTACKING

	if is_alerted and not was_alerted:
		_show_alert()
	elif not is_alerted:
		alert_icon.visible = false

	match current_state:
		States.RUNNING:
			animated_sprite_2d.play("Run")
			state_timer.start(randf_range(run_time_rang.x, run_time_rang.y))
		States.IDLE:
			animated_sprite_2d.play("Idle")
			state_timer.start(randf_range(idle_time_rang.x, idle_time_rang.y))
		States.CHASING:
			animated_sprite_2d.play("Run")
			state_timer.stop()
		States.ATTACKING:
			animated_sprite_2d.play("Idle")
			state_timer.stop()

func _show_alert() -> void:
	alert_icon.visible = true
	alert_icon.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(alert_icon, "scale", alert_base_scale, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_state_timer_timout() -> void:
	if current_state == States.CHASING or current_state == States.ATTACKING:
		return
	if current_state == States.RUNNING:
		_set_state(States.IDLE)
	else:
		_set_state(States.RUNNING)

func _update_direction_to_target() ->void:
	if target == null or current_state == States.IDLE or current_state == States.RUNNING:
		return
	var new_direction := int(sign(target.global_position.x - global_position.x))
	if new_direction != 0 and new_direction != direction:
		direction = new_direction
		animated_sprite_2d.flip_h = direction < 0
		ledge_check.position.x = abs(ledge_check.position.x) * direction

func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		_set_state(States.CHASING)

func _on_vision_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		_set_state(States.RUNNING)

func flip() -> void:
	direction *= -1
	animated_sprite_2d.flip_h = direction < 0
	ledge_check.position.x = abs(ledge_check.position.x) * direction
