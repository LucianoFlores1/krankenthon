# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Printable A4 drawing template (300 dpi PNG) with light-blue guides.

    uv run make_template.py out.png [--grid 2x3] [--ground 0.85]

Each cell = one frame. Draw the character standing on the ground line, centred on
the dashed axis, same size every frame. Guides are light blue so pack_frames.py
--dropout-blue erases them. Scan with a scanner app (auto-crop + deskew) and run:
    uv run pack_frames.py scans/ out/ --grid 2x3 --dropout-blue
"""
import argparse

from PIL import Image, ImageDraw

BLUE = (150, 200, 255)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--grid", default="2x3")
    ap.add_argument("--ground", type=float, default=0.85, help="ground line height inside a cell (0-1)")
    a = ap.parse_args()
    cols, rows = (int(v) for v in a.grid.lower().split("x"))
    W, H = 2480, 3508  # A4 @ 300 dpi
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    cw, ch = W / cols, H / rows
    for r in range(rows):
        for c in range(cols):
            x0, y0 = c * cw, r * ch
            m = cw * 0.04
            d.rectangle([x0 + m, y0 + m, x0 + cw - m, y0 + ch - m], outline=BLUE, width=3)
            gy = y0 + ch * a.ground
            d.line([x0 + m, gy, x0 + cw - m, gy], fill=BLUE, width=4)
            cx = x0 + cw / 2
            for y in range(int(y0 + m), int(gy), 40):
                d.line([cx, y, cx, y + 20], fill=BLUE, width=2)
            d.text((x0 + m + 12, y0 + m + 8), f"{r * cols + c + 1:02d}", fill=BLUE)
    img.save(a.out, dpi=(300, 300))
    print(f"wrote {a.out} ({cols}x{rows} frames)")


if __name__ == "__main__":
    main()
