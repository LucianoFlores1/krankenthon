class_name SteppedTransform
extends Node3D
## Put the visuals (SteppedSprite3D, props...) under this node.
## The physics parent moves smoothly; the visuals only jump to it on beats,
## like a stop-motion puppet moved between photos. Kills the "sliding on ice" look.

@export_range(1, 6) var hold := 2
@export var follow_rotation := false

var _target: Node3D


func _ready() -> void:
	_target = get_parent() as Node3D
	assert(_target != null, "SteppedTransform must be a child of a Node3D")
	top_level = true
	global_transform = _target.global_transform
	StepClock.stepped.connect(_on_step)


func _on_step(step: int) -> void:
	if step % hold != 0:
		return
	if follow_rotation:
		global_transform = _target.global_transform
	else:
		global_position = _target.global_position
