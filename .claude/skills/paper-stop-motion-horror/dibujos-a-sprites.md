# Dibujos a mano → sprites

## Material
- Lápiz **2B–6B** para la línea final, apretando (el limpiador corta los grises claros).
- **Lápiz azul claro** para bocetos y construcción: `--dropout-blue` lo borra solo. El grafito gris se conserva.
- Papel blanco sin rayas. La plantilla ya trae guías azules: caja, línea de suelo y eje central.
- "Sucio" está bien y es parte del estilo, pero las manchas grandes y oscuras sí salen. Borra las que estorben.

## Reglas de dibujo (para que no salte en el juego)
1. **Pies sobre la línea de suelo, centrado en el eje, mismo tamaño en todos los dibujos** del personaje. La altura ideal es ~70% de la celda.
2. **Perfil mirando a la derecha.** La izquierda se resuelve con `flip_h`.
3. Usa un **calco** (ventana o pantalla del móvil con brillo al máximo) para redibujar sobre el anterior. Así salen el boiling y la consistencia.
4. No sombrees áreas grandes de gris parejo, porque quedan semitransparentes. Mejor tramado o rayado (cross-hatching), que además es más lúgubre.
5. Un dibujo por celda. Las celdas vacías se ignoran solas.

## Cuántos dibujos (presupuesto de hackathon)
| Animación | Dibujos | Hold | Notas |
|---|---|---|---|
| `LOOP-idle` | 2–3 | 3 | Mismo dibujo calcado 3 veces = boiling. Lo más barato y lo que más vende el estilo |
| `LOOP-walk` | 4–6 | 2 | Contacto, paso, contacto opuesto, paso |
| `LOOP-run` | 4 | 2 | Opcional |
| `ACTN-<acción>` | 3–6 | 2 | Anticipación (1), acción (1–2), sostener (1, `_x3`) |
| Monstruo `LOOP-idle` | 3–4 | 4 | Cambios pequeños pero "erróneos": la cabeza un poco ladeada, un dedo de más |
| `ACTN-jumpscare` | 3 | 1–2 | Rápido, y luego sostener el último dibujo (`_x6`) |

Para un personaje jugable mínimo bastan unos 12 dibujos (idle + walk + 1 acción).

## Escanear
- **App escáner del móvil** (Microsoft Lens, Adobe Scan, Google Drive "Escanear"): recorta y endereza la hoja. Exporta en JPG o PNG a máxima calidad.
- Usa luz pareja y sin flash. El limpiador ya compensa sombras suaves y el papel amarillento.
- Nombra los archivos en orden (`walk_p1.jpg`, `walk_p2.jpg`...). Las celdas se leen de izquierda a derecha y de arriba abajo.
- Si los dibujos no siguen la plantilla (hojas sueltas, cada uno en un papel), quita `--grid`. El limpiador re-registra igual por los pies (`--align bottom-center`, la opción por defecto).
- Si escaneaste con mucho cuidado y quieres conservar la posición exacta del papel (por ejemplo una acción que avanza), usa `--align none`.

## Ajustes de `pack_frames.py`
| Problema | Flag |
|---|---|
| Quedan manchas o grises de papel | `--lo 0.22` |
| La línea sale demasiado transparente | `--hi 0.45` |
| Quieres tinta de un color fijo (p. ej. negro carbón) | `--ink 1a1410` |
| Más resolución (personajes grandes o primeros planos) | `--height 768` |
| Quieres también una tira spritesheet | `--sheet` |
