extends GdUnitTestSuite


func test_rust_health_damage_and_heal() -> void:
	var health := RustHealth.new()
	health.setup(100)
	health.damage(30)
	assert_int(health.current()).is_equal(70)
	health.heal(500)
	assert_int(health.current()).is_equal(100)
	health.damage(500)
	assert_bool(health.is_dead()).is_true()
