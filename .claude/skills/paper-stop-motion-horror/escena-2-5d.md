# Escena 2.5D lúgubre (diorama de papel)

## Diorama
- **Capas como un teatro de papel:** fondos, árboles, casas y muebles como `Sprite3D` (sin billboard) o `MeshInstance3D` + `QuadMesh` con textura recortada, puestos a distintas profundidades. La parallax sale gratis con la cámara 3D.
- **Suelo:** `PlaneMesh` con textura de lápiz tileable (Nano Banana) y `uv1_scale` alto.
- **Recortes:** `pack_frames.py IN OUT --props`. Material: `transparency = Alpha Scissor` (o en Sprite3D `alpha_cut = Discard`) y `cull_mode = Disabled` para ver ambos lados.
- Idea de DOGWALK (`_ref/DOGWALK/source/shaders/paper-default.gdshader`): el reverso del recorte con color papel (`FRONT_FACING`), bordes rasgados con una textura de borde y desgaste por vertex color. Solo si sobra tiempo.

## Luz y niebla (lo que más vende el horror)
- `WorldEnvironment`: fondo negro, luz ambiente casi 0, tonemap Filmic o AgX, glow suave.
- **Volumetric Fog** activo, densidad 0.03–0.08, albedo gris frío. Oculta los límites del nivel y deja que las siluetas aparezcan y desaparezcan.
- **Una sola fuente principal:** la linterna o farol del jugador (`SpotLight3D`/`OmniLight3D` con sombras). Los `Sprite3D` necesitan `shaded = on` para recibir luz.
- Parpadeo **por beats**, no con ruido continuo:
```gdscript
func _ready() -> void:
	StepClock.stepped.connect(func(step: int) -> void:
		if step % 2 == 0:
			light_energy = base_energy * (0.6 if randf() < 0.15 else randf_range(0.9, 1.05)))
```
- Cámara: plano fijo o seguimiento lento con ángulo bajo. Para los sustos, pon la cámara bajo un `SteppedTransform` (hold 3–4) unos segundos y la imagen tiembla como si alguien golpeara el trípode.

## Post-proceso
`CanvasLayer` (layer 10) → `ColorRect` con `ShaderMaterial(paper_horror_post.gdshader)` + script `paper_post_layer.gd`.
- `paper_tex`: escanea una hoja en blanco arrugada o sucia y úsala tal cual.
- Punto de partida: desaturate 0.75, accent rojo con accent_keep 0.8 (solo la sangre y los ojos mantienen el color), grain 0.07, jitter_px 1 (súbelo a 4 en los sustos), vignette 0.65.
- El HUD y los menús van en un CanvasLayer más alto para que el shader no los afecte, o más bajo si quieres que también parezcan dibujados.

## Nano Banana (texturas y fondos)
Se usa en la app de Gemini o por API. **Adjunta siempre 1–2 escaneos de vuestros dibujos** como referencia de estilo para que no se note "IA".

Plantilla para **textura tileable**:
> Seamless tileable texture of {wooden floorboards}, drawn in graphite pencil on rough off-white paper, cross-hatching shading, smudged and dirty, uneven pressure, monochrome with faint sepia stains, flat even lighting, no perspective, no text, no border. Match the line style of the attached drawing.

Plantilla para **prop / fondo recortable**:
> A single {dead tree with twisted branches} drawn in graphite pencil, rough sketchy lines, cross-hatching, slightly wrong proportions, unsettling, isolated on pure white background, no shadow on the ground, no text. Match the line style of the attached drawing.

Después pásalo por `pack_frames.py --props` para recortarlo. En las texturas tileables, comprueba las costuras en Godot con `uv1_scale` 4. Si se notan, pide "seamless" otra vez o usa la textura en zonas pequeñas.

Paleta: casi monocroma (grafito, papel, sepia) + **un solo acento rojo**. No metas más colores.
