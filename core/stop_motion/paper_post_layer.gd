extends ColorRect
## Feeds StepClock beats into paper_horror_post.gdshader. Attach to the ColorRect that
## carries the ShaderMaterial (inside a CanvasLayer, layer above the game).

@export_range(1, 6) var hold := 2


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	StepClock.stepped.connect(_on_step)


func _on_step(step: int) -> void:
	if step % hold == 0:
		(material as ShaderMaterial).set_shader_parameter(&"step_seed", float(step % 997))
