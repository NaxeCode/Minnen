// Verify that the browser inference implementation reproduces every held-out decision.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import assert from "node:assert/strict";
import { score } from "../web/analysis.mjs";
const root = process.argv[2];
if (!root) throw new Error("Usage: node tools/verify-benchmark.mjs DATASET");
const readJSON = (path) => JSON.parse(readFileSync(path));
const model = readJSON("web/assets/model.json");
const expectedCases = readJSON("web/assets/test-cases.json");
const evaluation = readJSON("web/assets/evaluation.json");
const heldOut = readJSON(join(root, "features.json")).filter(
  (row) => row.split === "test",
);
assert.equal(heldOut.length, expectedCases.length);
for (const method of ["learned", "baseline"]) {
  let correctDefects = 0,
    falseAlarms = 0,
    overlapSum = 0,
    defects = 0;
  for (const [idx, row] of heldOut.entries()) {
    const scores =
      method === "learned"
        ? score(row.features, model)
        : row.features.map((f) => f[0]);
    const threshold =
      method === "learned" ? model.threshold : model.baselineThreshold;
    const predicted = scores.map((v) => v >= threshold);
    const expected = expectedCases[idx];
    assert.equal(expected.id, row.id);
    const flagged = predicted.some(Boolean);
    assert.equal(flagged, expected[method + "Flagged"], row.id);
    if (expected.expectedDefect) {
      defects++;
      if (flagged) correctDefects++;
      const intersection = predicted.filter(
        (p, i) => p && row.labels[i],
      ).length;
      const union = predicted.filter((p, i) => p || row.labels[i]).length;
      overlapSum += intersection / Math.max(1, union);
    } else if (flagged) falseAlarms++;
  }
  const report = evaluation[method];
  assert.equal(correctDefects, report.tp);
  assert.equal(falseAlarms, report.fp);
  assert.equal(Number((overlapSum / defects).toFixed(4)), report.meanMaskIoU);
  console.log(
    method +
      ": " +
      heldOut.length +
      " held-out decisions and mask overlap reproduced in JavaScript",
  );
}
