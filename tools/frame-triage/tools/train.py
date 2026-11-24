"""Fit on train only; select thresholds on validation; report untouched scene seeds."""

import json, sys
from pathlib import Path
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

root = Path(sys.argv[1])
dest = Path(__file__).resolve().parents[1] / "web" / "assets"
data = json.loads((root / "features.json").read_text())
parts = {
    s: [r for r in data if r["split"] == s] for s in ("train", "validation", "test")
}


def flatten(rows, k):
    return np.concatenate([r[k] for r in rows])


x = flatten(parts["train"], "features")
y = flatten(parts["train"], "labels")
sc = StandardScaler().fit(x)
lr = LogisticRegression(
    C=0.45, class_weight="balanced", max_iter=400, random_state=25
).fit(sc.transform(x), y)


def prepare(rows):
    f = np.asarray([r["features"] for r in rows])
    s = lr.predict_proba(sc.transform(f.reshape(-1, f.shape[-1])))[:, 1].reshape(
        f.shape[:2]
    )
    return (
        s,
        f[:, :, 0],
        np.asarray([r["labels"] for r in rows], dtype=bool),
        np.array([r["kind"] in ("missing", "material", "displaced") for r in rows]),
    )


def metrics(scores, labels, targets, t):
    pred = scores >= t
    decision = pred.any(axis=1)
    tp = int(np.sum(decision & targets))
    fp = int(np.sum(decision & ~targets))
    fn = int(np.sum(~decision & targets))
    tn = int(np.sum(~decision & ~targets))
    inter = np.sum(pred & labels, axis=1)
    union = np.sum(pred | labels, axis=1)
    return dict(
        tp=tp,
        fp=fp,
        fn=fn,
        tn=tn,
        frameF1=round(2 * tp / max(1, 2 * tp + fp + fn), 4),
        meanMaskIoU=round(
            float(np.mean(inter[targets] / np.maximum(1, union[targets]))), 4
        ),
    )


v, b, l, tg = prepare(parts["validation"])


def tune(s):
    # Both methods get the same grid and objective. Localization breaks ties in frame F1.
    thresholds = np.unique(np.r_[np.quantile(s, np.linspace(0, 1, 701)), 1e-9])
    return float(
        max(
            thresholds,
            key=lambda t: (lambda m: (m["frameF1"], m["meanMaskIoU"]))(
                metrics(s, l, tg, t)
            ),
        )
    )


threshold, base_t = tune(v), tune(b)
s, b, l, tg = prepare(parts["test"])
model = dict(
    version=1,
    mean=sc.mean_.tolist(),
    scale=sc.scale_.tolist(),
    weights=lr.coef_[0].tolist(),
    bias=float(lr.intercept_[0]),
    threshold=threshold,
    baselineThreshold=base_t,
)
results = dict(
    splits={
        k: dict(pairs=len(r), seeds=len({x["seed"] for x in r}))
        for k, r in parts.items()
    },
    learned=metrics(s, l, tg, threshold),
    baseline=metrics(b, l, tg, base_t),
    byKind={},
)
for kind in sorted({r["kind"] for r in parts["test"]}):
    ix = np.array([r["kind"] == kind for r in parts["test"]])
    results["byKind"][kind] = dict(
        total=int(ix.sum()),
        learnedFlagged=int((s[ix] >= threshold).any(axis=1).sum()),
        baselineFlagged=int((b[ix] >= base_t).any(axis=1).sum()),
    )
for name, obj in [("model", model), ("evaluation", results)]:
    (dest / (name + ".json")).write_text(json.dumps(obj, indent=2) + "\n")
print(json.dumps(results, indent=2))
case_results = []
for idx, row in enumerate(parts["test"]):
    case_results.append(
        dict(
            id=row["id"],
            expectedDefect=bool(tg[idx]),
            learnedFlagged=bool(np.any(s[idx] >= threshold)),
            baselineFlagged=bool(np.any(b[idx] >= base_t)),
        )
    )
(dest / "test-cases.json").write_text(json.dumps(case_results, indent=2) + "\n")
