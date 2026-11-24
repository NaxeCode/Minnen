"""Append an exact held-out failure, baseline miss and the independent camera fixture."""

import json
import sys
import shutil
from pathlib import Path

public = Path(__file__).resolve().parents[1] / "web/assets"
dataset = Path(sys.argv[1])
cases = [
    row
    for row in json.loads((public / "cases.json").read_text())
    if row["id"] in ("lead", "finish", "offset", "exposure", "jitter")
]
results = json.loads((public / "test-cases.json").read_text())
for key, criterion, title, detail in [
    (
        "false-alarm",
        lambda r: r["learnedFlagged"] and not r["expectedDefect"],
        "A real false alarm",
        "A held-out camera shift crosses the learned threshold. The aligned baseline accepts it.",
    ),
    (
        "baseline-miss",
        lambda r: r["expectedDefect"] and not r["baselineFlagged"],
        "A baseline miss",
        "A held-out material change slips below the baseline threshold. The learned detector flags it.",
    ),
]:
    row = next(r for r in results if criterion(r))
    seed, kind = row["id"].split("-")
    for name, source in [
        ("reference", seed + "-reference.png"),
        ("candidate", row["id"] + ".png"),
    ]:
        shutil.copyfile(dataset / source, public / f"{key}-{name}.png")
    cases.append(
        dict(
            id=key,
            kind=kind,
            title=title,
            detail=detail + " Test pair " + row["id"] + ".",
            reference=f"assets/{key}-reference.png",
            candidate=f"assets/{key}-candidate.png",
        )
    )
cases.append(
    dict(
        id="camera",
        kind="camera",
        title="Minnen camera projection",
        detail="The same grove passes through Minnen’s Haxe camera with curvature enabled and disabled. Both captures use original fixture artwork. This pair is outside the training family.",
        reference="assets/camera-reference.png",
        candidate="assets/camera-candidate.png",
    )
)
(public / "cases.json").write_text(json.dumps(cases, indent=2) + "\n")
