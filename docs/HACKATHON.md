# Krankethon — bitácora del hackathon

Juego de **horror 2.5D** en **Godot 4.7.2**. Personajes y props **dibujados a lápiz en papel**, escaneados y metidos en un diorama 3D oscuro. Animación **stop-motion** inspirada en DOGWALK (Blender Studio). Prioridad: **terminarlo rápido**. Que quede sucio no importa, es parte del estilo.

Estado al 2026-11-03: entorno listo, núcleo stop-motion programado y probado, sin escenas de juego todavía.

---

## 1. Decisiones tomadas

| Tema | Decisión | Por qué |
|---|---|---|
| Perspectiva | **2.5D**: sprites dibujados (`Sprite3D`) en un mundo 3D | Aprovecha los dibujos en papel; la luz y la niebla 3D venden el horror |
| Animación | **Stop-motion "en 2s/3s/4s"** con un reloj de beats global | Técnica de DOGWALK. Permite cambiar de estado sin blending: más barato y rápido |
| Direcciones | Solo **perfil a la derecha** + `flip_h` | 8 direcciones = 4× más dibujos |
| Texturas y fondos | **Gemini (plan gratis) a mano**, adjuntando nuestros dibujos como referencia | Gratis. Ojo con el límite diario y la marca de agua de la esquina |
| Paleta | Grafito + papel + sepia + **un solo acento rojo** | Identidad lúgubre y coherente |
| Godot MCP | **godot-ai** (hi-godot) | Editor vivo: escenas, scripts, capturas, errores |
| Ponytail | Instalado (scope proyecto) | Menos código. Ganancia real ~10–15% según JetBrains |
| **No usamos** | Blender MCP, Nano Banana MCP, ECC (everything-claude-code), Graphify | No hay 3D en Blender; Gemini a mano; ECC es pesado y no trae nada de Godot; Graphify sobra en un proyecto pequeño |

## 2. Lo aprendido de DOGWALK

Código en `_ref/DOGWALK/` (mirror de nikitalita/DOGWALK, scripts MIT, assets CC-BY). Godot lo ignora gracias a `.gdignore`.

- **Animar en 2s, 3s o 4s**: cada pose se sostiene varios frames. "Permite saltar entre estados sin preocuparse por el blending."
- Reloj a 24 fps (`FRAME_TIME := 1.0 / 24.0`) y un flag `on_animation_step`. **La rotación y la velocidad del personaje solo cambian en esos beats**, cuantizadas con `ValueSlicer` (con histéresis). Ese es el secreto del aspecto de marioneta (`chocomel.gd`, `value_slicer.gd`).
- Animaciones con prefijo: `LOOP-` (bucle), `ACTN-` (una vez), `CINE-` (narrativa), `SYNC-` (dos personajes).
- Shader de papel (`source/shaders/paper-default.gdshader`): reverso color papel, bordes rasgados, desgaste. Solo si sobra tiempo.

Fuentes: [Animating for DOGWALK](https://studio.blender.org/blog/animations-for-dogwalk/) · [Workflow Blender + Godot](https://studio.blender.org/blog/our-workflow-with-blender-and-godot/)

## 3. Qué hay instalado y dónde

| Cosa | Dónde |
|---|---|
| Godot 4.7.2 (winget) | `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe`. Acceso directo: menú Inicio → "Godot 4.7.2" |
| uv (winget) | Lo usan godot-ai y los scripts de imagen |
| Plugin godot-ai v4.4.1 | `addons/godot_ai/` (activado en `project.godot`) |
| MCP godot-ai en Claude Code | Registrado. Comprobar con `claude mcp get godot-ai` → `✔ Connected` |
| Ponytail | `.claude/settings.json` |
| Skill del proyecto | `.claude/skills/paper-stop-motion-horror/` |

## 4. Estructura del proyecto

```
project.godot                 autoloads: StepClock, _mcp_game_helper (godot-ai)
CLAUDE.md                     contexto para Claude (se carga solo)
docs/HACKATHON.md             este documento
core/stop_motion/             núcleo stop-motion (ver §5)
tools/build_sprite_frames.gd  carpetas de PNG -> SpriteFrames .tres
art/characters/<personaje>/   frames limpios + <personaje>_frames.tres
art/characters/test_dummy/    muñeco de prueba (lo usa el test)
tests/test_stop_motion.tscn   test headless del núcleo
.claude/skills/paper-stop-motion-horror/
  SKILL.md                    guía principal (holds, pipeline, estructura, errores)
  dibujos-a-sprites.md        cómo dibujar y escanear, cuántos dibujos por animación
  escena-2-5d.md              diorama, luces, niebla, post-proceso, prompts de Gemini
  scripts/make_template.py    plantilla A4 para imprimir
  scripts/pack_frames.py      limpia escaneos -> PNG transparentes
_ref/DOGWALK/                 referencia (ignorada por Godot)
```

## 5. Núcleo stop-motion (`core/stop_motion/`)

| Pieza | Uso |
|---|---|
| `StepClock` (autoload) | Señal `stepped(step)` a 24/s. Una pose cuando `step % hold == 0` |
| `SteppedSprite3D` | Cambia de dibujo solo en los beats. Usar `show_anim(&"walk")`, **nunca `play()`**. Señal `action_finished` |
| `SteppedTransform` | El cuerpo físico se mueve suave y el dibujo salta a su posición en los beats (sin "patinar") |
| `ValueSlicer` | `facing()`/`slice()`: cuantiza dirección/velocidad con histéresis |
| `paper_horror_post.gdshader` + `paper_post_layer.gd` | Post-proceso: papel, grano, viñeta, desaturado salvo el rojo, salto de cámara por beat |

Holds recomendados: **jugador 2**, **monstruo 3–4** (el contraste inquieta), idle con boiling 3, luces y grano 2.

## 6. Pipeline: de papel a juego

1. Imprimir plantilla: `uv run .claude/skills/paper-stop-motion-horror/scripts/make_template.py plantilla.png --grid 2x3`
2. Dibujar con lápiz 2B–6B. Construcción en **lápiz azul**. Pies sobre la línea de suelo, mismo tamaño, perfil a la derecha.
3. Escanear con app (Microsoft Lens / Adobe Scan / Drive) → `scans/<personaje>/LOOP-walk/*.jpg`
4. Limpiar: `uv run .claude/skills/paper-stop-motion-horror/scripts/pack_frames.py scans/<p> art/characters/<p> --grid 2x3 --dropout-blue`
5. `godot --headless --path . --import` y luego `godot --headless --path . -s res://tools/build_sprite_frames.gd`
6. Asignar `art/characters/<p>/<p>_frames.tres` al `SteppedSprite3D`.

Props o imágenes de Gemini sobre fondo blanco: `pack_frames.py IN OUT --props` (recortad antes la marca de agua).

Mínimo para un personaje jugable: ~12 dibujos (idle 3 + walk 4–6 + 1 acción).

## 7. Verificación

- Test del núcleo: `godot --headless --path . res://tests/test_stop_motion.tscn` → **`RESULT: PASS` (16/16)** al 2026-11-03.
- `pack_frames.py` probado con escaneos sintéticos (papel amarillo, sombra, dibujos desalineados, guías azules) → limpio y alineado.
- **Sin verificar todavía:** cómo se ve el post-proceso en pantalla (compila, pero nadie lo ha visto renderizado).

## 8. Problemas que tuvimos (y su solución)

| Problema | Causa | Solución |
|---|---|---|
| El panel de godot-ai no respondía ("0/28", Configure no hacía nada) | Godot se abrió desde una terminal iniciada **antes** de instalar uv, así que el plugin no encontraba `uvx` y su servidor no arrancaba (nada en los puertos 8000/9500) | Cerrar Godot y abrirlo de nuevo (menú Inicio). Ahora el panel muestra "Server connected" |
| ¿Choque de puertos con el acceso remoto? | No: el acceso remoto usa cloudflared → node en el 8080 | godot-ai usa 8000/9500 solo en localhost. Se pueden cambiar en Godot AI → Clients & Tools → Settings |
| Aviso "archivos más recientes en disco" | Se editó `project.godot` con el editor abierto | Pulsar **Recargar**, nunca "Volver a guardar" (borraría cambios hechos fuera) |
| El proyecto no aparecía en Godot | Primera vez en el gestor de proyectos | **Importar** → `D:\krankethon\project.godot` |
| La release de godot-ai traía un "migration bridge" | Ese zip es para actualizar desde v3 | Se instaló `godot-ai-v4-plugin.zip` (checksum verificado) |

Si godot-ai se desconecta: abrir Godot con el proyecto → panel Godot AI en verde → `claude mcp get godot-ai`. **Godot tiene que estar abierto** para que Claude use sus herramientas.

## 9. Próximos pasos

1. Escena base: muñeco de prueba caminando en un diorama oscuro con niebla, linterna y post-proceso. Sirve para validar el estilo **antes** de dibujar en serio.
2. Definir la historia o loop de juego mínimo (qué hace el jugador, qué lo persigue, cómo termina).
3. Primera tanda de dibujos: protagonista (idle + walk) y monstruo (idle en 4s).
4. Texturas de suelo y paredes con Gemini.
5. Sonido (sin decidir todavía).
