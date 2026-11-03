# Krankethon — juego de horror 2.5D (hackathon)

- Godot **4.7.2**, GDScript, Forward+. Exe: `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
- Estilo: dibujos a lápiz escaneados (sucio está bien) en un diorama 3D oscuro, animación stop-motion. **Usa la skill `paper-stop-motion-horror`** para todo lo visual, animación y sprites.
- Prioridad: terminar rápido. Usa nodos integrados de Godot antes que código propio, nada de abstracciones especulativas.
- MCP `godot-ai`: editor vivo (escenas, scripts, capturas, errores). Úsalo para verificar en el juego real.
- Tests del núcleo: `godot --headless --path . res://tests/test_stop_motion.tscn` → `RESULT: PASS`.
- Decisiones, instalación, problemas resueltos y próximos pasos: `docs/HACKATHON.md`.
- `_ref/DOGWALK/`: código de DOGWALK (Blender Studio, scripts MIT, assets CC-BY), solo como referencia. Godot lo ignora (`.gdignore`).
