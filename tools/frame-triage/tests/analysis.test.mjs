import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { execFileSync, spawnSync } from "node:child_process";
import { PNG } from "pngjs";
import { analyze, sampleFrame } from "../web/analysis.mjs";
const model = JSON.parse(readFileSync("web/assets/model.json"));
const frame = (name) =>
  sampleFrame(PNG.sync.read(readFileSync("web/assets/" + name + ".png")));
test("same frame has neither learned nor baseline alerts", () => {
  const a = frame("lead-reference");
  const result = analyze(a, a, model);
  assert.equal(result.flagged, 0);
  assert.equal(result.baselineFlagged, 0);
  assert.deepEqual(result.alignment, { dx: 0, dy: 0 });
});
test("held-out failure examples reproduce the recorded opposing decisions", () => {
  for (const [key, learned, baseline] of [
    ["false-alarm", true, false],
    ["baseline-miss", true, false],
  ]) {
    const result = analyze(
      frame(key + "-reference"),
      frame(key + "-candidate"),
      model,
    );
    assert.equal(result.flagged > 0, learned);
    assert.equal(result.baselineFlagged > 0, baseline);
  }
  const manifest = JSON.parse(readFileSync("web/assets/test-cases.json"));
  assert.equal(manifest.length, 156);
  for (const [key, label] of [
    ["275-jitter", false],
    ["274-material", true],
  ]) {
    assert.deepEqual(
      manifest.find((r) => r.id === key),
      {
        id: key,
        expectedDefect: label,
        learnedFlagged: true,
        baselineFlagged: false,
      },
    );
  }
});
test("CLI shares inference and rejects mismatched frame dimensions", () => {
  const files = ["lead-reference", "lead-candidate"].map(
    (s) => "web/assets/" + s + ".png",
  );
  const result = JSON.parse(
    execFileSync(process.execPath, ["tools/inspect.mjs", ...files]),
  );
  assert.ok(result.flagged > 0);
  assert.equal(result.scores.length, 336);
  const bad = spawnSync(process.execPath, [
    "tools/inspect.mjs",
    files[0],
    "web/assets/false-alarm-candidate.png",
  ]);
  assert.equal(bad.status, 1);
  assert.match(bad.stderr.toString(), /dimensions/);
});
test("invalid inputs are rejected and alpha composites onto white", () => {
  assert.throws(() => sampleFrame({ width: 4, height: 8, data: [] }));
  assert.deepEqual(
    sampleFrame({ width: 1, height: 1, data: [87, 10, 24, 0] }),
    sampleFrame({ width: 1, height: 1, data: [255, 255, 255, 255] }),
  );
});
