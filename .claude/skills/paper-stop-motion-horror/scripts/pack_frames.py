# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10", "numpy>=1.26"]
# ///
"""Turn scanned / photographed pencil drawings into transparent PNG frames for Godot.

    uv run pack_frames.py IN_DIR OUT_DIR [options]

IN_DIR holds one folder per animation, named with DOGWALK prefixes:
    IN_DIR/LOOP-walk/*.jpg   IN_DIR/LOOP-idle/*.jpg   IN_DIR/ACTN-scream/*.jpg
Files are taken in name order. OUT_DIR gets the same folders with clean PNGs,
ready to copy to res://art/characters/<name>/ and run build_sprite_frames.gd.

--props: IN_DIR is a flat folder of single images (props, Nano Banana cut-outs);
each one is trimmed on its own, no shared canvas.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageOps

EXTS = {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff", ".bmp"}


def load(path: Path) -> np.ndarray:
    img = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
    return np.asarray(img, dtype=np.float32) / 255.0


def background(rgb: np.ndarray) -> np.ndarray:
    """Estimate paper colour per pixel (removes phone shadows / yellow paper)."""
    h, w, _ = rgb.shape
    small = Image.fromarray((rgb * 255).astype(np.uint8)).resize((max(w // 8, 1), max(h // 8, 1)))
    # Max filter first so pencil lines don't darken the paper estimate.
    small = small.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(max(w, h) / 160))
    return np.asarray(small.resize((w, h), Image.BILINEAR), dtype=np.float32) / 255.0 + 1e-4


def clean(rgb: np.ndarray, lo: float, hi: float, dropout_blue: bool, ink: tuple | None) -> np.ndarray:
    flat = np.clip(rgb / background(rgb), 0.0, 1.0)
    lum = flat @ np.array([0.299, 0.587, 0.114], np.float32)
    alpha = np.clip(((1.0 - lum) - lo) / (hi - lo), 0.0, 1.0)
    if dropout_blue:
        # Graphite is neutral grey; blue guides / construction lines have blue >> red.
        blueness = flat[..., 2] - flat[..., 0]
        alpha *= 1.0 - np.clip((blueness - 0.06) / 0.08, 0.0, 1.0)
    color = np.broadcast_to(np.array(ink, np.float32), flat.shape) if ink else flat
    return np.dstack([color, alpha])


def split_grid(rgb: np.ndarray, grid: tuple[int, int], margin: float) -> list[np.ndarray]:
    cols, rows = grid
    h, w, _ = rgb.shape
    cw, ch = w / cols, h / rows
    mx, my = int(cw * margin), int(ch * margin)
    return [rgb[int(r * ch) + my:int((r + 1) * ch) - my, int(c * cw) + mx:int((c + 1) * cw) - mx]
            for r in range(rows) for c in range(cols)]


def bbox(rgba: np.ndarray, thr: float = 0.3, min_pixels: int = 50):
    ys, xs = np.nonzero(rgba[..., 3] > thr)
    if len(xs) < min_pixels:  # empty cell / dust
        return None
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def to_image(rgba: np.ndarray) -> Image.Image:
    return Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")


def compose(frames: list[np.ndarray], align: str, pad: float) -> list[np.ndarray]:
    """Put every frame of a character on one shared canvas so scale and anchor match."""
    boxes = [bbox(f) for f in frames]
    keep = [(f, b) for f, b in zip(frames, boxes) if b is not None]
    if not keep:
        return []
    if align == "none":
        x0 = min(b[0] for _, b in keep); y0 = min(b[1] for _, b in keep)
        x1 = max(b[2] for _, b in keep); y1 = max(b[3] for _, b in keep)
        crops = [f[y0:y1, x0:x1] for f, _ in keep]
        ch, cw = y1 - y0, x1 - x0
    else:
        crops = [f[b[1]:b[3], b[0]:b[2]] for f, b in keep]
        ch, cw = max(c.shape[0] for c in crops), max(c.shape[1] for c in crops)
    p = int(max(ch, cw) * pad)
    H, W = ch + 2 * p, cw + 2 * p
    out = []
    for c in crops:
        canvas = np.zeros((H, W, 4), np.float32)
        h, w = c.shape[:2]
        y = H - p - h  # feet on the ground line (bottom padding)
        x = (W - w) // 2 if align != "none" else p
        canvas[y:y + h, x:x + w] = c
        out.append(canvas)
    return out


def resize(img: Image.Image, height: int) -> Image.Image:
    w = max(2, round(img.width * height / img.height) // 2 * 2)
    return img.resize((w, height), Image.LANCZOS)


def parse_ink(s: str):
    if s == "keep":
        return None
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("in_dir", type=Path)
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--height", type=int, default=512, help="output frame height in px (default 512)")
    ap.add_argument("--lo", type=float, default=0.15, help="darkness below this becomes transparent (raise to drop smudges)")
    ap.add_argument("--hi", type=float, default=0.55, help="darkness above this is fully opaque")
    ap.add_argument("--dropout-blue", action="store_true", help="ignore light-blue guides/construction lines")
    ap.add_argument("--ink", default="keep", help="'keep' original graphite colour or force a hex colour, e.g. 1a1410")
    ap.add_argument("--grid", default=None, help="cut each scan into COLSxROWS frames (template pages), e.g. 2x3")
    ap.add_argument("--grid-margin", type=float, default=0.04, help="fraction trimmed inside each grid cell")
    ap.add_argument("--align", choices=["bottom-center", "none"], default="bottom-center",
                    help="bottom-center: re-register each drawing on its feet (fixes misaligned photos); "
                         "none: keep paper positions (use with carefully registered scans)")
    ap.add_argument("--pad", type=float, default=0.04)
    ap.add_argument("--props", action="store_true", help="flat folder of single images, trimmed one by one")
    ap.add_argument("--sheet", action="store_true", help="also write a horizontal strip <anim>_sheet.png")
    a = ap.parse_args()
    ink = parse_ink(a.ink)
    grid = tuple(int(v) for v in a.grid.lower().split("x")) if a.grid else None

    def frames_of(files: list[Path]) -> list[np.ndarray]:
        out = []
        for f in files:
            rgb = load(f)
            for part in (split_grid(rgb, grid, a.grid_margin) if grid else [rgb]):
                frame = clean(part, a.lo, a.hi, a.dropout_blue, ink)
                if bbox(frame) is not None:  # skip empty template cells
                    out.append(frame)
        return out

    a.out_dir.mkdir(parents=True, exist_ok=True)
    if a.props:
        for f in sorted(p for p in a.in_dir.iterdir() if p.suffix.lower() in EXTS):
            fr = compose(frames_of([f]), "bottom-center", a.pad)
            if fr:
                resize(to_image(fr[0]), a.height).save(a.out_dir / (f.stem + ".png"))
                print(f"prop  {f.name}")
        return 0

    anim_dirs = sorted(d for d in a.in_dir.iterdir() if d.is_dir())
    if not anim_dirs:
        print(f"No animation folders in {a.in_dir} (expected LOOP-walk/, ACTN-scream/ ...)", file=sys.stderr)
        return 1
    per_anim = {d.name: frames_of(sorted(p for p in d.iterdir() if p.suffix.lower() in EXTS)) for d in anim_dirs}
    # One canvas for the whole character -> walk/idle/scream share scale and feet position.
    composed = compose([f for fr in per_anim.values() for f in fr], a.align, a.pad)
    meta = {}
    i = 0
    for name, fr in per_anim.items():
        out = a.out_dir / name
        out.mkdir(exist_ok=True)
        imgs = [resize(to_image(c), a.height) for c in composed[i:i + len(fr)]]
        i += len(fr)
        for n, img in enumerate(imgs, 1):
            img.save(out / f"{name.split('-', 1)[-1]}_{n:02d}.png")
        if a.sheet and imgs:
            sheet = Image.new("RGBA", (imgs[0].width * len(imgs), imgs[0].height))
            for n, img in enumerate(imgs):
                sheet.paste(img, (n * img.width, 0))
            sheet.save(a.out_dir / f"{name}_sheet.png")
        meta[name] = {"frames": len(imgs)}
        print(f"anim  {name}: {len(imgs)} frames")
    if composed:
        h = a.height
        w = resize(to_image(composed[0]), h).width
        meta["_frame_size"] = [w, h]
        meta["_godot_hint"] = {"Sprite3D.offset": [0, h // 2], "pixel_size_for_1.7m": round(1.7 / h, 5)}
    (a.out_dir / "frames.json").write_text(json.dumps(meta, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
