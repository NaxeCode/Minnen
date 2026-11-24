from pathlib import Path
import sys, json
from PIL import Image
import numpy as np
from render import render

path = Path(__file__).resolve().parents[1] / "web" / "assets"
cases = [
    (
        "lead",
        12,
        "missing",
        "Missing ceramic ring",
        "A component is skipped when the candidate frame is drawn.",
    ),
    (
        "finish",
        40,
        "material",
        "Changed material",
        "One component picks up a different material while the camera stays fixed.",
    ),
    (
        "offset",
        56,
        "displaced",
        "Displaced part",
        "A translation changes the position of a single part.",
    ),
    (
        "exposure",
        21,
        "exposure",
        "Routine exposure drift",
        "A gain change affects the whole frame. The geometry stays put.",
    ),
    (
        "jitter",
        32,
        "jitter",
        "Subpixel camera drift",
        "The camera shifts slightly across the entire frame.",
    ),
]
rows = []
for id, s, k, title, detail in cases:
    ref = render(s, "unchanged", 768, 448)
    cand = render(s, k, 768, 448)
    for tag, pix in [("reference", ref), ("candidate", cand)]:
        Image.fromarray(pix).save(path / f"{id}-{tag}.png", optimize=True)
    rows.append(
        dict(
            id=id,
            kind=k,
            title=title,
            detail=detail,
            reference=f"assets/{id}-reference.png",
            candidate=f"assets/{id}-candidate.png",
        )
    )
(path / "cases.json").write_text(json.dumps(rows, indent=2) + "\n")
