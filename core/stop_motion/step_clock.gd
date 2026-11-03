extends Node
## Global stop-motion beat (autoload as "StepClock").
## Ticks at base_fps ("on ones"). Each listener decides its own hold:
## step % 2 == 0 -> "on twos" (12 poses/s), % 3 -> on threes (8/s), % 4 -> on fours (6/s).
## Same idea as DOGWALK's FRAME_TIME = 1/24 + on_animation_step flag.

signal stepped(step: int)

@export var base_fps := 24.0
@export var paused := false

var step := 0
var _acc := 0.0


func _process(delta: float) -> void:
	if paused:
		return
	_acc += delta
	var step_time := 1.0 / base_fps
	if _acc < step_time:
		return
	# On a hitch emit once and drop the backlog: a burst of beats looks worse than a skipped one.
	_acc = fmod(_acc, step_time)
	step += 1
	stepped.emit(step)


## True on the beats a node animated "on <hold>s" should pose.
func is_on(hold: int) -> bool:
	return step % maxi(hold, 1) == 0
