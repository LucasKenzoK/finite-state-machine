class_name Character
extends CharacterBody2D

signal health_changed(current: int, maximun: int)
signal damaged(amount: int, source: Node)
signal died

@export_group("Health")
@export var max_health := 100

@export_group("Physics")
@export var fall_gravity_multiplier := 2.0

@onready var health: int = max_health
var is_dead := false

func _apply_gravity(delta: float) -> void:
	if velocity.y > 0:
		velocity +=  get_gravity() * fall_gravity_multiplier * delta
	else:
		velocity += get_gravity() * delta

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead or amount <= 0:
		return
	health = max(health - amount, 0)
	damaged.emit(amount, source)
	health_changed.emit(health, max_health)
	_on_damaged(amount, source)
	if health == 0:
		die()

func heal(amount: int) -> void:
	if is_dead:
		return
	health += min(health + amount, max_health)
	health_changed.emit(health, max_health)


func die() -> void:
	is_dead = true
	died.emit()
	_on_death()

func _on_damaged(_amount: int, _source: Node) -> void:
	pass

func _on_death() ->void:
	queue_free()
