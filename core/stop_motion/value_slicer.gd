class_name ValueSlicer
extends RefCounted
## Adapted from DOGWALK (Blender Studio, source/utility/value_slicer.gd, MIT).
## Snaps a continuous value (angle, speed...) into N slices with hysteresis so the
## result doesn't flicker on slice borders. DOGWALK only updates the slice on
## animation beats, so rotation/speed also move "in poses".


## Returns the slice index for `value`. Pass the previous result back in as `previous`.
## threshold: fraction of a slice the value must overshoot before switching.
## looping: for angles (slices are centered, index wraps).
static func slice(value: float, range_min: float, range_max: float, slices: int,
		previous: int, threshold := 0.1, looping := false) -> int:
	var slice_size := (range_max - range_min) / slices
	if looping:
		var idx := _snap(value + slice_size * 0.5, range_min, slice_size, slices, previous, threshold)
		return posmod(idx, slices)
	return clampi(_snap(value, range_min, slice_size, slices, previous, threshold), 0, slices - 1)


## Angle (radians) -> one of `directions` facings, e.g. 8 for 8-way sprites, 2 for left/right.
static func facing(angle: float, directions: int, previous: int) -> int:
	return slice(angle, -PI, PI, directions, previous, 0.1, true)


static func _snap(value: float, range_min: float, slice_size: float, slices: int,
		previous: int, threshold: float) -> int:
	var prev_middle := (previous + 0.5) * slice_size + range_min
	if threshold > 0.0 and absf(prev_middle - value) < slice_size:
		# Pull towards the previous slice's middle -> hysteresis.
		value += threshold * slice_size * signf(prev_middle - value)
	return floori((value - range_min) / slice_size)
