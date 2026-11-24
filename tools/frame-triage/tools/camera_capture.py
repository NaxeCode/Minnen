"""Illustrate the real LogCamera projection with a deterministic, original calibration grove."""

import argparse
import json
from pathlib import Path
import subprocess
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SIZE = (768, 448)


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def draw(points):
    w, h = SIZE
    image = Image.new("RGB", SIZE)
    pen = ImageDraw.Draw(image)
    for y in range(h):
        pen.line((0, y, w, y), fill=mix((152, 167, 193), (72, 105, 103), y / h))
    pen.ellipse((63, 16, 116, 69), fill=(222, 213, 183))
    for pt in sorted(points, key=lambda p: -p["row"]):
        x, y, s, fog = (pt[k] for k in ("x", "y", "scale", "fog"))
        col, row = pt["col"], pt["row"]
        if abs(col - 8) <= 1:
            if col == 8 and row % 2 == 0:
                pen.ellipse(
                    (x - 6 * s, y - 2 * s, x + 6 * s, y + 2 * s), fill=(192, 176, 140)
                )
            continue
        height = (72 + (row * 11 + col * 13) % 55) * s
        ink = mix((39, 67, 70), (155, 169, 182), fog * 0.9)
        pen.line((x, y, x, y - height * 0.8), fill=ink, width=max(1, round(4 * s)))
        for tier, spread in ((1, 0.26), (0.80, 0.33), (0.58, 0.39)):
            pen.polygon(
                (
                    (x, y - height * tier),
                    (x - height * spread, y - height * (tier - 0.43)),
                    (x + height * spread, y - height * (tier - 0.43)),
                ),
                fill=ink,
            )
    return image


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("game_source", type=Path, help="Path to Minnen/source")
    args = parser.parse_args()
    for config, name in (("curved", "reference"), ("flat", "candidate")):
        proc = subprocess.run(
            [
                "haxe",
                "-cp",
                str(args.game_source.resolve()),
                "-cp",
                str(ROOT / "tools/camera"),
                "--run",
                "Capture",
                config,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        draw(json.loads(proc.stdout)).save(
            ROOT / "web/assets" / f"camera-{name}.png", optimize=True
        )
