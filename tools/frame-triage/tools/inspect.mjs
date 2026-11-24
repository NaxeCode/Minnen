import { openSync, closeSync, readSync, readFileSync } from "node:fs";
import { PNG } from "pngjs";
import { analyze, sampleFrame, COLS, ROWS } from "../web/analysis.mjs";
function readFrame(path) {
  const header = Buffer.alloc(24);
  const fd = openSync(path, "r");
  try {
    if (
      readSync(fd, header, 0, 24, 0) !== 24 ||
      header.toString("hex", 0, 8) !== "89504e470d0a1a0a"
    )
      throw new Error("Expected a PNG image.");
  } finally {
    closeSync(fd);
  }
  if (header.readUInt32BE(16) * header.readUInt32BE(20) > 12_000_000)
    throw new Error("Input exceeds 12 megapixels.");
  return PNG.sync.read(readFileSync(path));
}
try {
  if (process.argv.length !== 4)
    throw new Error(
      "Usage: node tools/inspect.mjs REFERENCE.png CANDIDATE.png",
    );
  const [a, b] = process.argv.slice(2).map(readFrame);
  if (a.width !== b.width || a.height !== b.height)
    throw new Error("Image dimensions must match.");
  const m = JSON.parse(
    readFileSync(new URL("../web/assets/model.json", import.meta.url)),
  );
  console.log(
    JSON.stringify(
      {
        modelVersion: m.version,
        width: a.width,
        height: a.height,
        columns: COLS,
        rows: ROWS,
        threshold: m.threshold,
        baselineThreshold: m.baselineThreshold,
        ...analyze(sampleFrame(a), sampleFrame(b), m),
      },
      null,
      2,
    ),
  );
} catch (e) {
  console.error(e.message);
  process.exitCode = 1;
}
