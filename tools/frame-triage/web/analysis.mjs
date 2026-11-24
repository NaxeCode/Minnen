/* The offline evaluator, PNG command line and browser all execute this module. */
export const WIDTH = 192;
export const HEIGHT = 112;
export const TILE = 8;
export const COLS = WIDTH / TILE;
export const ROWS = HEIGHT / TILE;
export const FEATURES = [
  "mean residual",
  "brightest residuals",
  "changed area",
  "chroma residual",
  "edge residual",
  "surrounding change",
  "frame residual",
  "frame coverage",
];
const lum = (r, g, b) => 0.2126 * r + 0.7152 * g + 0.0722 * b;
const clamp = (v, max) => Math.max(0, Math.min(v, max));

export function sampleFrame({ width, height, data }) {
  if (
    !Number.isSafeInteger(width) ||
    !Number.isSafeInteger(height) ||
    width < 1 ||
    height < 1 ||
    width * height > 12_000_000 ||
    data.length !== width * height * 4
  ) {
    throw new Error("Expected an RGBA image up to 12 megapixels.");
  }
  // Area averaging keeps a whole small defect from vanishing between sample centers.
  const frame = new Float32Array(WIDTH * HEIGHT * 3);
  for (let y = 0; y < HEIGHT; y++) {
    const top = Math.floor((y * height) / HEIGHT);
    const bottom = Math.min(
      height,
      Math.max(top + 1, Math.floor(((y + 1) * height) / HEIGHT)),
    );
    for (let x = 0; x < WIDTH; x++) {
      const left = Math.floor((x * width) / WIDTH);
      const right = Math.min(
        width,
        Math.max(left + 1, Math.floor(((x + 1) * width) / WIDTH)),
      );
      const dest = 3 * (y * WIDTH + x);
      for (let sy = top; sy < bottom; sy++)
        for (let sx = left; sx < right; sx++) {
          const source = (sy * width + sx) * 4;
          for (let c = 0; c < 3; c++)
            frame[dest + c] +=
              (data[source + c] / 255) * (data[source + 3] / 255) +
              (1 - data[source + 3] / 255);
        }
      for (let c = 0; c < 3; c++)
        frame[dest + c] /= (bottom - top) * (right - left);
    }
  }
  return frame;
}
function grayscale(frame) {
  const gray = new Float32Array(WIDTH * HEIGHT);
  for (let i = 0; i < gray.length; i++)
    gray[i] = lum(frame[3 * i], frame[3 * i + 1], frame[3 * i + 2]);
  return gray;
}
function align(reference, candidate) {
  let best = { dx: 0, dy: 0, cost: Infinity };
  // Sparse trimmed-error alignment tolerates a changed part occupying a minority of the frame.
  for (const dy of [0, -1, 1, -2, 2])
    for (const dx of [0, -1, 1, -2, 2]) {
      let cost = 0;
      for (let y = 3; y < HEIGHT - 3; y += 3)
        for (let x = 3; x < WIDTH - 3; x += 3) {
          cost += Math.min(
            0.1,
            Math.abs(
              reference[y * WIDTH + x] - candidate[(y + dy) * WIDTH + x + dx],
            ),
          );
        }
      if (cost < best.cost - 1e-7) best = { dx, dy, cost };
    }
  return best;
}
export function extract(reference, candidate) {
  const a = grayscale(reference),
    b = grayscale(candidate);
  const { dx, dy } = align(a, b);
  const buckets = Array.from({ length: COLS * ROWS }, () => ({
    d: [],
    chroma: 0,
    edge: 0,
    changed: 0,
  }));
  let globalSum = 0,
    globalChanged = 0;
  for (let y = 0; y < HEIGHT; y++)
    for (let x = 0; x < WIDTH; x++) {
      const ai = y * WIDTH + x,
        bx = clamp(x + dx, WIDTH - 1),
        by = clamp(y + dy, HEIGHT - 1),
        bi = by * WIDTH + bx;
      const dr = reference[3 * ai] - candidate[3 * bi],
        dg = reference[3 * ai + 1] - candidate[3 * bi + 1],
        db = reference[3 * ai + 2] - candidate[3 * bi + 2];
      const d = (Math.abs(dr) + Math.abs(dg) + Math.abs(db)) / 3;
      const bucket =
        buckets[Math.floor(y / TILE) * COLS + Math.floor(x / TILE)];
      bucket.d.push(d);
      bucket.chroma += Math.abs(dr - dg) + Math.abs(dg - db);
      if (x + 1 < WIDTH && bx + 1 < WIDTH)
        bucket.edge += Math.abs(a[ai + 1] - a[ai] - (b[bi + 1] - b[bi]));
      if (y + 1 < HEIGHT && by + 1 < HEIGHT)
        bucket.edge += Math.abs(
          a[ai + WIDTH] - a[ai] - (b[bi + WIDTH] - b[bi]),
        );
      if (d > 0.04) {
        bucket.changed++;
        globalChanged++;
      }
      globalSum += d;
    }
  const mean = buckets.map((v) => v.d.reduce((a, b) => a + b, 0) / v.d.length);
  const pixels = WIDTH * HEIGHT;
  const features = buckets.map((v, i) => {
    v.d.sort((a, b) => a - b);
    let surrounding = 0,
      count = 0;
    for (
      let yy = Math.max(0, Math.floor(i / COLS) - 1);
      yy <= Math.min(ROWS - 1, Math.floor(i / COLS) + 1);
      yy++
    )
      for (
        let xx = Math.max(0, (i % COLS) - 1);
        xx <= Math.min(COLS - 1, (i % COLS) + 1);
        xx++
      ) {
        surrounding += mean[yy * COLS + xx];
        count++;
      }
    return [
      mean[i],
      v.d[Math.floor(v.d.length * 0.9)],
      v.changed / v.d.length,
      v.chroma / v.d.length,
      v.edge / v.d.length,
      surrounding / count,
      globalSum / pixels,
      globalChanged / pixels,
    ];
  });
  return { features, alignment: { dx, dy } };
}
export function score(features, model) {
  return features.map((row) => {
    const z = row.reduce(
      (sum, v, i) =>
        sum + ((v - model.mean[i]) / model.scale[i]) * model.weights[i],
      model.bias,
    );
    return 1 / (1 + Math.exp(-Math.max(-40, Math.min(40, z))));
  });
}
export function analyze(reference, candidate, model) {
  const { features, alignment } = extract(reference, candidate);
  const scores = score(features, model);
  const baseline = features.map((row) => row[0]);
  return {
    alignment,
    scores,
    baseline,
    flagged: scores.filter((v) => v >= model.threshold).length,
    baselineFlagged: baseline.filter((v) => v >= model.baselineThreshold)
      .length,
  };
}
