extends GdUnitTestSuite

func test_cpp_stamina_spend_and_recover() -> void:
	var stamina := CppStamina.new()
	stamina.setup(100)
	stamina.spend(30)
	assert_int(stamina.current()).is_equal(70)
	stamina.recover(500)
	assert_int(stamina.current()).is_equal(100)
	stamina.spend(500)
	assert_bool(stamina.is_exhausted()).is_true()
