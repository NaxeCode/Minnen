import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { PNG } from "pngjs";
import { sampleFrame, extract, COLS, ROWS, TILE } from "../web/analysis.mjs";
const dir = process.argv[2];
const manifest = JSON.parse(readFileSync(join(dir, "manifest.json")));
const out = [];
let refName = "",
  ref;
for (const row of manifest) {
  const read = (name) => PNG.sync.read(readFileSync(join(dir, name)));
  if (row.reference !== refName) {
    ref = sampleFrame(read(row.reference));
    refName = row.reference;
  }
  const { features } = extract(ref, sampleFrame(read(row.candidate)));
  const mask = read(row.mask);
  const labels = [];
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++) {
      let marked = 0;
      for (let iy = 0; iy < TILE; iy++)
        for (let ix = 0; ix < TILE; ix++)
          if (
            mask.data[((y * TILE + iy) * mask.width + x * TILE + ix) * 4] > 127
          )
            marked++;
      labels.push(marked >= 4 ? 1 : 0);
    }
  out.push({
    id: row.id,
    split: row.split,
    seed: row.seed,
    kind: row.kind,
    features,
    labels,
  });
}
writeFileSync(join(dir, "features.json"), JSON.stringify(out));
console.log(out.length + " frame pairs extracted");
