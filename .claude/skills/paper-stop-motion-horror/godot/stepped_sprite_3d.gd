class_name SteppedSprite3D
extends AnimatedSprite3D
## Hand-drawn frames that only change on StepClock beats -> stop-motion feel.
## Never call play(): this node drives `frame` itself. Use show_anim().
## Per-frame "Duration" in the SpriteFrames editor = how many beats that drawing holds.

signal action_finished(anim: StringName)

@export_range(1, 6) var hold := 2 ## 2 = on twos. Monsters on 3 or 4 feel creepier.

var _beats_on_frame := 0


func _ready() -> void:
	stop()
	StepClock.stepped.connect(_on_step)


## Switch animation instantly (stepped style snaps, no blending needed).
func show_anim(anim: StringName, restart := false) -> void:
	if animation == anim and not restart:
		return
	animation = anim
	frame = 0
	_beats_on_frame = 0


func _on_step(step: int) -> void:
	if step % hold != 0 or sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	_beats_on_frame += 1
	var needed := maxi(1, roundi(sprite_frames.get_frame_duration(animation, frame)))
	if _beats_on_frame < needed:
		return
	_beats_on_frame = 0
	var count := sprite_frames.get_frame_count(animation)
	if frame + 1 < count:
		frame += 1
	elif sprite_frames.get_animation_loop(animation):
		frame = 0
	else:
		action_finished.emit(animation)
