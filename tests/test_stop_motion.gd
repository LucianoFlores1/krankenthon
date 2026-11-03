extends Node
## Headless smoke test for the stop-motion core:
##   godot --headless --path . res://tests/test_stop_motion.tscn
## Exits 0 if all checks pass.

var _failures := 0


func _ready() -> void:
	_test_value_slicer()
	await _test_stepped_sprite()
	await _test_stepped_transform()
	_test_post_shader()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	get_tree().quit(_failures)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		push_error("FAIL: " + msg)
	else:
		print("ok  " + msg)


func _test_value_slicer() -> void:
	_check(ValueSlicer.slice(0.05, 0.0, 1.0, 10, 0) == 0, "slicer basic")
	_check(ValueSlicer.slice(0.55, 0.0, 1.0, 10, 0) == 5, "slicer jumps far")
	# Hysteresis: 0.205 is just over the border of slice 1->2, stays on previous slice 1.
	_check(ValueSlicer.slice(0.205, 0.0, 1.0, 10, 1) == 1, "slicer hysteresis holds")
	_check(ValueSlicer.slice(0.23, 0.0, 1.0, 10, 1) == 2, "slicer switches past threshold")
	_check(ValueSlicer.facing(PI - 0.01, 8, 0) == ValueSlicer.facing(-PI + 0.01, 8, 0), "facing wraps at +-PI")
	# The SKILL.md left/right recipe: atan2(z, x) -> 1 = moving +X, 0 = moving -X.
	_check(ValueSlicer.facing(atan2(0.0, 1.0), 2, 0) == 1, "facing: +X is 1 (right)")
	_check(ValueSlicer.facing(atan2(0.0, -1.0), 2, 1) == 0, "facing: -X is 0 (left)")
	_check(ValueSlicer.facing(atan2(1.0, 0.05), 2, 1) == 1, "facing: moving in Z keeps previous side")


func _test_stepped_sprite() -> void:
	var frames := load("res://art/characters/test_dummy/test_dummy_frames.tres") as SpriteFrames
	_check(frames != null, "SpriteFrames built by tools/build_sprite_frames.gd")
	if frames == null:
		return
	_check(frames.get_frame_count(&"walk") == 4 and frames.get_animation_loop(&"walk"), "walk: 4 frames, loops")
	_check(frames.get_frame_count(&"scream") == 3 and not frames.get_animation_loop(&"scream"), "scream: 3 frames, once")
	var s := SteppedSprite3D.new()
	s.sprite_frames = frames
	s.hold = 2
	add_child(s)
	s.show_anim(&"walk")
	var start_step := StepClock.step
	var changes := 0
	var last := s.frame
	while StepClock.step < start_step + 12:
		await get_tree().process_frame
		if s.frame != last:
			changes += 1
			last = s.frame
	# 12 beats on twos -> 6 pose changes (+-1 for phase)
	_check(changes >= 5 and changes <= 7, "on twos: %d pose changes in 12 beats" % changes)
	var finished := [false]
	s.action_finished.connect(func(_a): finished[0] = true)
	s.show_anim(&"scream")
	var t0 := StepClock.step
	while not finished[0] and StepClock.step < t0 + 20:
		await get_tree().process_frame
	_check(finished[0] and s.frame == 2, "ACTN plays once, emits action_finished, holds last frame")
	s.queue_free()


func _test_stepped_transform() -> void:
	var body := Node3D.new()
	add_child(body)
	var vis := SteppedTransform.new()
	vis.hold = 2
	body.add_child(vis)
	body.global_position = Vector3(5, 0, 0)
	_check(vis.global_position == Vector3.ZERO, "visual does not follow instantly")
	var t0 := StepClock.step
	while StepClock.step < t0 + 3:
		await get_tree().process_frame
	_check(vis.global_position == Vector3(5, 0, 0), "visual snaps to body on beat")
	body.queue_free()


func _test_post_shader() -> void:
	var sh := load("res://core/stop_motion/paper_horror_post.gdshader") as Shader
	_check(sh != null and sh.get_shader_uniform_list().size() >= 10, "post shader loads with uniforms")
