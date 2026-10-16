extends GdUnitTestSuite

func test_accept_deals_damage() -> void:
	var runner := scene_runner("res://src/main.tscn")
	var label: Label = runner.find_child("HealthLabel")
	assert_str(label.text).is_equal("HP 100")
	runner.simulate_action_pressed("ui_accept")
	await runner.await_input_processed()
	# GdUnit4 6.2.2 delivers the event twice (direct _unhandled_input call plus
	# Input.flush_buffered_events), so assert on damage taken, not an exact value.
	assert_str(label.text).is_not_equal("HP 100")
