extends GdUnitTestSuite


func test_accept_deals_damage() -> void:
	var runner := scene_runner("res://src/main.tscn")
	var label: Label = runner.find_child("HealthLabel")
	assert_str(label.text).is_equal("HP 100")
	runner.simulate_action_pressed("ui_accept")
	await runner.await_input_processed()
	assert_str(label.text).is_equal("HP 90")
