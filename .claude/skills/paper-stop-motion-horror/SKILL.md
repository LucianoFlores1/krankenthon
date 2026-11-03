---
name: paper-stop-motion-horror
description: Use when building this Godot 4.7 2.5D horror game - hand-drawn pencil/paper sprites, spritesheets, scanning drawings, stop-motion or "choppy" animation (on twos/threes), Sprite3D/AnimatedSprite3D characters in a 3D diorama, dark/lúgubre look, Nano Banana textures, or anything about animación, dibujos escaneados, spritesheet, movimiento entrecortado.
---

# Paper stop-motion horror (Godot 4.7, 2.5D)

## Overview
Lápiz sobre papel, escaneado y metido en un diorama 3D oscuro. La sensación stop-motion sale de **un único reloj de beats** (24/s) que mueve todo lo visual en saltos: dibujos, posición, giro, luces y grano. Es la técnica de DOGWALK (Blender Studio): animar "en 2s/3s/4s" para poder **cambiar de estado de golpe, sin blending**, lo que en un hackathon ahorra mucho tiempo.

Regla de oro: **la física se mueve suave, lo visible se mueve a saltos.**

## Ya instalado en este proyecto
| Archivo | Qué hace |
|---|---|
| `core/stop_motion/step_clock.gd` | Autoload `StepClock`: señal `stepped(step)` a 24/s. `step % hold == 0` = pose |
| `core/stop_motion/stepped_sprite_3d.gd` | `SteppedSprite3D`: cambia dibujo solo en beats. `show_anim()`, señal `action_finished` |
| `core/stop_motion/stepped_transform.gd` | `SteppedTransform`: los visuales saltan a la posición del cuerpo físico solo en beats |
| `core/stop_motion/value_slicer.gd` | `ValueSlicer.facing()/slice()`: cuantiza ángulo/velocidad con histéresis (de DOGWALK) |
| `core/stop_motion/paper_horror_post.gdshader` + `paper_post_layer.gd` | Post-proceso: papel, grano, viñeta, desaturado con un color acento, salto de cámara por beat |
| `tools/build_sprite_frames.gd` | Carpetas de PNG → `<personaje>_frames.tres` |
| `tests/test_stop_motion.tscn` | Prueba headless del núcleo (debe dar `RESULT: PASS`) |

Copias maestras en `godot/` de esta skill. Scripts de imagen en `scripts/` (se ejecutan con `uv run`, instalan dependencias solos).

## Holds (cuántos beats dura cada pose)
| Quién | hold | Por qué |
|---|---|---|
| Jugador | 2 (12 poses/s) | Legible y responde bien |
| Monstruo / cosas "mal" | 3–4 | Más entrecortado = más inquietante. El contraste con el jugador es la clave |
| Idle con "boiling" | 3 | 2–3 calcos del mismo dibujo; las líneas tiemblan |
| Luces que parpadean, grano | 2 | Cambian con el beat, nunca cada frame |
| Pico de susto | cambia el hold a 1 o 6 durante 1 s | Romper el ritmo asusta |

Duración por dibujo: en el editor de SpriteFrames, "Duration" = nº de holds; o nombra el archivo `scream_04_x3.png`.

## Nombres de animación (DOGWALK)
Carpeta = `PREFIJO-nombre`: `LOOP-` (bucle: walk, idle, run), `ACTN-` (una vez: scream, grab), `CINE-` (narrativa), `SYNC-` (dos personajes coordinados). El build quita el prefijo: `LOOP-walk` → `walk`.

## Pipeline (de papel a juego)
1. **Plantilla:** `uv run .claude/skills/paper-stop-motion-horror/scripts/make_template.py plantilla.png --grid 2x3` → imprimir.
2. **Dibujar:** ver `dibujos-a-sprites.md` (reglas de dibujo, cuántos dibujos por animación).
3. **Escanear** con app escáner (recorta + endereza) → `scans/<personaje>/LOOP-walk/*.jpg`.
4. **Limpiar:** `uv run .claude/skills/paper-stop-motion-horror/scripts/pack_frames.py scans/<p> art/characters/<p> --grid 2x3 --dropout-blue` (quita papel, sombras y guías azules, alinea por los pies, misma escala para todo el personaje; deja `frames.json` con `offset` y `pixel_size`).
5. **Importar y construir:** `godot --headless --path . --import` y luego `godot --headless --path . -s res://tools/build_sprite_frames.gd`.
6. Asignar `art/characters/<p>/<p>_frames.tres` al `SteppedSprite3D`.

Props / fondos / imágenes de Nano Banana sobre blanco: `pack_frames.py IN OUT --props`.

## Personaje 2.5D (estructura)
```
CharacterBody3D            # física suave, script de movimiento
├─ CollisionShape3D
└─ SteppedTransform        # hold = 2
   └─ SteppedSprite3D      # billboard = Y-Billboard, shaded = on, alpha_cut = Discard,
                           # offset.y = alto/2 (pies en el origen), pixel_size de frames.json
```
```gdscript
# En el script del CharacterBody3D:
var _facing := 0
func _physics_process(delta: float) -> void:
	# ... velocity, move_and_slide() normales ...
	if velocity.length() > 0.1:
		$SteppedTransform/Sprite.show_anim(&"walk")
		# 2 slices: 1 = +X (derecha), 0 = -X (izquierda). Cámara mirando hacia -Z.
		# La histéresis evita parpadeo al moverse en vertical (hacia/desde cámara).
		_facing = ValueSlicer.facing(atan2(velocity.z, velocity.x), 2, _facing)
		if StepClock.is_on(2):  # girar solo en un beat, como DOGWALK
			$SteppedTransform/Sprite.flip_h = _facing == 0  # dibujos miran a la derecha
	else:
		$SteppedTransform/Sprite.show_anim(&"idle")
```
Dibujar **solo de perfil mirando a la derecha** y usar `flip_h`. Las 8 direcciones multiplican el trabajo de dibujo por 4.

Diorama, luces, niebla, post-proceso y prompts de Nano Banana: ver `escena-2-5d.md`.

## Errores comunes
| Síntoma | Causa → arreglo |
|---|---|
| La animación va fluida/rápida | Alguien llamó `play()` en `SteppedSprite3D`. Usar solo `show_anim()` |
| Personaje "patina" | Falta `SteppedTransform` entre el cuerpo y el sprite |
| El personaje salta de tamaño o de lugar entre animaciones | Se limpió cada animación por separado. Pasar el personaje entero a `pack_frames.py` de una vez |
| Halos grises / manchas | Subir `--lo` (0.2–0.25). Usar lápiz azul para construcción + `--dropout-blue` |
| Sprites que parpadean o se ordenan mal | `alpha_cut = Discard`, no Blend |
| Líneas dentadas de lejos | Importar las texturas con mipmaps y filtro Linear, no Nearest |
| Usar Tweens para mover cosas | Rompe el estilo. Mueve en `stepped`, o deja que `SteppedTransform` lo cuantice |
| `StepClock` no existe | Falta el autoload en `project.godot` |
| `build_sprite_frames` dice "Not imported yet" | Ejecutar `--import` antes |

Verificar tras tocar el núcleo: `godot --headless --path . res://tests/test_stop_motion.tscn` → `RESULT: PASS`.
