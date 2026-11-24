"""Orthographic CPU renderer for controlled, paired visual regression captures.

Objects are original analytic solids. The candidate goes through the same camera
and shading pipeline as the reference. Labels come from intervening on the scene.
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path
import numpy as np
from PIL import Image

RIGHT = np.array([0.814, 0.0, -0.581])
UP = np.array([-0.268, 0.887, -0.376])
VIEW = np.cross(RIGHT, UP)
LIGHT = np.array([-0.48, 0.83, 0.28])
LIGHT /= np.linalg.norm(LIGHT)
PALETTES = [
    [(220, 86, 48), (96, 95, 164), (196, 205, 210), (40, 59, 78)],
    [(43, 132, 136), (224, 160, 57), (196, 210, 199), (40, 69, 78)],
    [(192, 107, 137), (101, 106, 172), (214, 200, 182), (58, 57, 81)],
    [(238, 129, 52), (76, 120, 156), (192, 211, 214), (46, 68, 83)],
]
KINDS = ["unchanged", "exposure", "jitter", "missing", "material", "displaced"]


def scene(seed):
    r = np.random.default_rng(seed)
    pal = PALETTES[seed % len(PALETTES)]
    dx, dz = r.uniform(-0.24, 0.24, 2)
    objects = []

    def add(shape, xyz, size, color, tag="structure"):
        objects.append(
            dict(
                shape=shape,
                c=np.array(xyz, dtype=float),
                s=np.array(size, dtype=float),
                color=np.array(color, dtype=float),
                tag=tag,
            )
        )

    add("box", (0, 0.12, 0), (2.68, 0.14, 1.63), pal[3])
    add("box", (-0.05, 0.29, -0.03), (2.51, 0.05, 1.49), pal[2])
    for k in range(3):
        add(
            "box",
            (-1.42 + dx, 0.44 + k * 0.15, -0.35 + dz),
            (0.84 - 0.13 * k, 0.10, 0.79 - 0.08 * k),
            pal[1],
        )
    radius = r.uniform(0.62, 0.86)
    add(
        "ringz",
        (-1.29 + dx, 0.76 + radius, -0.32 + dz),
        (radius, radius * 0.54, 0.23),
        pal[0],
        "ring",
    )
    add("cyl", (1.12, 0.53, -0.44), (0.70, 0.19, 0), pal[3])
    add("cyl", (1.12, 0.85, -0.44), (0.57, 0.18, 0), pal[1], "wheel")
    add("cyl", (1.12, 1.08, -0.44), (0.30, 0.055, 0), pal[2])
    add("sphere", (0.14 + dx, 0.72, 0.76 + dz), (0.37, 0, 0), pal[0], "sphere")
    for k in range(7):
        add("box", (0.89 + 0.16 * k, 0.45, 0.83), (0.039, 0.105, 0.37), pal[3])
    for x, z in [(-2.20, 1.22), (2.18, 1.22), (-2.20, -1.22), (2.18, -1.22)]:
        add("cyl", (x, 0.365, z), (0.074, 0.027, 0), pal[3])
    return objects


def intersect(o, origin, d):
    p = origin - o["c"]
    size = o["s"]
    shape = o["shape"]
    if shape == "box":
        ds = np.where(np.abs(d) < 1e-12, 1e-12, d)
        a = (-size - p) / ds
        b = (size - p) / ds
        lo = np.minimum(a, b)
        hi = np.maximum(a, b)
        t = np.max(lo, axis=-1)
        ok = (np.min(hi, axis=-1) >= t) & (t > 1e-5)
        normal = np.eye(3)[np.argmax(lo, axis=-1)] * -np.sign(ds)
        return np.where(ok, t, np.inf), normal
    if shape == "sphere":
        proj = np.sum(p * d, axis=-1)
        disc = proj * proj - (np.sum(p * p, axis=-1) - size[0] ** 2)
        t = -proj - np.sqrt(np.maximum(disc, 0))
        normal = (p + t[..., None] * d) / size[0]
        return np.where((disc >= 0) & (t > 1e-5), t, np.inf), normal
    axis = 2 if shape == "ringz" else 1
    uv = [i for i in range(3) if i != axis]
    radii = [(size[0], 1)] + ([(size[1], -1)] if shape == "ringz" else [])
    height = size[2] if shape == "ringz" else size[1]
    best = np.full(p.shape[:-1], np.inf)
    norm = np.zeros_like(p)
    a = np.dot(d[uv], d[uv])
    b = np.sum(p[..., uv] * d[uv], axis=-1)
    rsq = np.sum(p[..., uv] ** 2, axis=-1)
    for rad, sign in radii:
        disc = b * b - a * (rsq - rad * rad)
        for root in (-1, 1):
            t = (-b + root * np.sqrt(np.maximum(disc, 0))) / a
            hit = (
                (disc >= 0)
                & (t > 1e-5)
                & (np.abs(p[..., axis] + t * d[axis]) <= height)
                & (t < best)
            )
            n = (p + t[..., None] * d) / rad
            n[..., axis] = 0
            best = np.where(hit, t, best)
            norm = np.where(hit[..., None], sign * n, norm)
    for side in (-1, 1):
        t = (side * height - p[..., axis]) / d[axis]
        r2 = np.sum((p[..., uv] + t[..., None] * d[uv]) ** 2, axis=-1)
        hit = (t > 1e-5) & (t < best) & (r2 <= size[0] ** 2)
        if shape == "ringz":
            hit &= r2 >= size[1] ** 2
        n = np.zeros(3)
        n[axis] = side
        best = np.where(hit, t, best)
        norm = np.where(hit[..., None], n, norm)
    return best, norm


def render(seed, kind, w, h, *, beauty=False):
    objects = scene(seed)
    rng = np.random.default_rng(seed + 833)
    tag = ["ring", "wheel", "sphere"][seed % 3]
    if kind == "missing":
        objects = [o for o in objects if o["tag"] != tag]
    elif kind in ("material", "displaced"):
        for o in objects:
            if o["tag"] == tag:
                if kind == "material":
                    o["color"] = (
                        np.array([125.0, 180.0, 88.0])
                        if seed % 2
                        else np.array([84.0, 126.0, 173.0])
                    )
                else:
                    o["c"] += np.array([0.48, 0.16, -0.12])
    yy, xx = np.mgrid[0:h, 0:w]
    # Framing and component offsets vary by scene seed.
    jitter = 0.9 if kind == "jitter" else 0.0
    view_width = 7.35 + rng.uniform(-0.35, 0.35)
    px = (xx + 0.5 - w / 2 + jitter * w / 192) * view_width / w + rng.uniform(
        -0.22, 0.22
    )
    py = (h / 2 - yy - 0.5) * view_width / w + 0.62 + rng.uniform(-0.08, 0.08)
    origin = px[..., None] * RIGHT + py[..., None] * UP + VIEW * 12
    ray = -VIEW
    t = -origin[..., 1] / ray[1]
    floor = origin + t[..., None] * ray
    n = np.zeros_like(floor)
    n[..., 1] = 1
    base = np.broadcast_to(np.array([192.0, 198.0, 211.0]), floor.shape).copy()
    ident = np.full((h, w), -1)
    for i, obj in enumerate(objects):
        ti, ni = intersect(obj, origin, ray)
        hit = ti < t
        t = np.where(hit, ti, t)
        n = np.where(hit[..., None], ni, n)
        base[hit] = obj["color"]
        ident[hit] = i
    pt = origin + t[..., None] * ray
    lam = np.clip(n @ LIGHT, 0, 1)
    # Soft contact shadows use each solid's footprint projected along the light.
    shadow = np.zeros((h, w))
    for i, o in enumerate(objects):
        c = o["c"]
        delta = c[1] - pt[..., 1]
        x = pt[..., 0] - (c[0] - delta * LIGHT[0] / LIGHT[1])
        z = pt[..., 2] - (c[2] - delta * LIGHT[2] / LIGHT[1])
        sx, _, sz = o["s"]
        sz = max(0.2, sz) if o["shape"] == "box" else sx * 0.82
        a = (x / (sx + 0.22)) ** 2 + (z / (sz + 0.20)) ** 2
        occ = np.exp(-a * 1.9) * np.clip(delta * 1.55 + 0.21, 0, 0.7) * (ident != i)
        shadow = np.maximum(shadow, occ)
    shade = (0.70 + 0.33 * lam) * (1 - 0.53 * shadow)
    color = base * shade[..., None]
    spec = np.maximum(n @ ((LIGHT + VIEW) / np.linalg.norm(LIGHT + VIEW)), 0) ** 24
    color += spec[..., None] * 14
    color += np.where(ident < 0, 6 * np.tanh(floor[..., 2] / 4), 0)[..., None]
    if kind == "exposure":
        color = color * rng.choice([0.90, 1.11]) + rng.uniform(-2, 2)
    return np.clip(color, 0, 255).astype(np.uint8)


def save(path, arr):
    Image.fromarray(arr).save(path)


def build_dataset(root, n_train=60, n_val=18, n_test=26):
    root.mkdir(parents=True, exist_ok=True)
    rows = []
    for split, count, start in [
        ("train", n_train, 30),
        ("validation", n_val, 160),
        ("test", n_test, 270),
    ]:
        for seed in range(start, start + count):
            ref = render(seed, "unchanged", 192, 112)
            rf = f"{seed}-reference.png"
            save(root / rf, ref)
            for kind in KINDS:
                arr = ref if kind == "unchanged" else render(seed, kind, 192, 112)
                key = f"{seed}-{kind}"
                cf = rf if kind == "unchanged" else key + ".png"
                if cf != rf:
                    save(root / cf, arr)
                mask = (
                    np.max(np.abs(arr.astype(int) - ref.astype(int)), axis=2) > 9
                    if kind in KINDS[3:]
                    else np.zeros(ref.shape[:2], bool)
                )
                mf = key + "-mask.png"
                save(root / mf, (mask * 255).astype("uint8"))
                rows.append(
                    dict(
                        id=key,
                        split=split,
                        seed=seed,
                        kind=kind,
                        reference=rf,
                        candidate=cf,
                        mask=mf,
                    )
                )
    (root / "manifest.json").write_text(json.dumps(rows))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    build_dataset(args.directory)
