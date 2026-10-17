extends Node2D

var health := Health.create(100)

@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	_refresh()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		health.damage(10)
		_refresh()


func _refresh() -> void:
	health_label.text = "HP %d" % health.current
