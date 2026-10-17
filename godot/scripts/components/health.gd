class_name Health
extends RefCounted

var max_value: int
var current: int


static func create(maximum: int) -> Health:
	var health := Health.new()
	health.max_value = maximum
	health.current = maximum
	return health


func damage(amount: int) -> void:
	current = clampi(current - maxi(amount, 0), 0, max_value)


func heal(amount: int) -> void:
	current = clampi(current + maxi(amount, 0), 0, max_value)


func is_dead() -> bool:
	return current == 0
