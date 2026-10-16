extends GdUnitTestSuite

func test_starts_full() -> void:
	var health := Health.create(100)
	assert_int(health.current).is_equal(100)

func test_damage_reduces_and_clamps_at_zero() -> void:
	var health := Health.create(100)
	health.damage(30)
	assert_int(health.current).is_equal(70)
	health.damage(500)
	assert_int(health.current).is_equal(0)
	assert_bool(health.is_dead()).is_true()

func test_heal_clamps_at_max() -> void:
	var health := Health.create(100)
	health.damage(50)
	health.heal(80)
	assert_int(health.current).is_equal(100)

func test_negative_amounts_are_ignored() -> void:
	var health := Health.create(100)
	health.damage(-10)
	health.heal(-10)
	assert_int(health.current).is_equal(100)
