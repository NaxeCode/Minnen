import { sampleFrame, analyze, COLS, ROWS } from "./analysis.mjs";

const el = (id) => document.getElementById(id);
const loadJSON = async (file) => {
  const r = await fetch("./assets/" + file + ".json");
  if (!r.ok) throw new Error("Could not read " + file + ".json");
  return r.json();
};
let model,
  cases,
  active,
  result,
  generation = 0,
  custom,
  urls = [],
  currentMethod = "learned";
const layers = ["ref", "cand"];
function imageAt(url) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error("This image could not be decoded."));
    image.src = url;
  });
}
function pixels(image) {
  const canvas = document.createElement("canvas");
  canvas.width = image.naturalWidth;
  canvas.height = image.naturalHeight;
  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  ctx.drawImage(image, 0, 0);
  return sampleFrame(ctx.getImageData(0, 0, canvas.width, canvas.height));
}
function refresh() {
  if (!result) return;
  const learned = currentMethod === "learned";
  const scores = learned ? result.scores : result.baseline;
  const flagged = learned ? result.flagged : result.baselineFlagged;
  const threshold = learned ? model.threshold : model.baselineThreshold;
  el("learned").setAttribute("aria-pressed", String(learned));
  el("baseline").setAttribute("aria-pressed", String(!learned));
  el("decision").textContent = flagged
    ? "Review this pair"
    : "No tiles flagged";
  el("decision").parentElement.classList.toggle("ok", !flagged);
  el("regions").textContent = flagged + " / " + COLS * ROWS;
  el("align").textContent =
    result.alignment.dx + ", " + result.alignment.dy + " px";
  const canvas = el("overlay"),
    ctx = canvas.getContext("2d");
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  if (!el("mask").checked) return;
  const w = canvas.width / COLS,
    h = canvas.height / ROWS;
  ctx.fillStyle = "rgba(167, 41, 120, .23)";
  ctx.strokeStyle = "rgba(127, 26, 93, .86)";
  ctx.lineWidth = 1;
  scores.forEach((score, i) => {
    if (score >= threshold) {
      const x = (i % COLS) * w,
        y = Math.floor(i / COLS) * h;
      ctx.fillRect(x, y, w, h);
      ctx.strokeRect(x + 0.5, y + 0.5, w - 1, h - 1);
    }
  });
}
async function inspectPair(row) {
  const token = ++generation;
  const [a, b] = await Promise.all([
    imageAt(row.reference),
    imageAt(row.candidate),
  ]);
  if (token !== generation) return false;
  if (a.naturalWidth !== b.naturalWidth || a.naturalHeight !== b.naturalHeight)
    throw new Error("Choose images with identical dimensions.");
  if (a.naturalWidth * a.naturalHeight > 12_000_000)
    throw new Error("Choose images of 12 megapixels or fewer.");
  const measured = analyze(pixels(a), pixels(b), model);
  result = measured;
  active = row;
  [a, b].forEach((img, i) => {
    el(layers[i]).src = img.src;
  });
  el("viewer").style.aspectRatio = a.naturalWidth + " / " + a.naturalHeight;
  el("caseTitle").textContent = row.title;
  el("caseDetail").textContent = row.detail;
  el("dimensions").textContent = a.naturalWidth + " × " + a.naturalHeight;
  el("download").disabled = false;
  el("feedback").textContent = "";
  refresh();
  return true;
}
function changeWipe(value) {
  const v = Math.max(0, Math.min(100, Math.round(value)));
  el("wipe").value = String(v);
  el("viewer").style.setProperty("--wipe", v + "%");
  el("wipeValue").value = v + "%";
}
const viewer = el("viewer");
function pointerWipe(e) {
  const rect = viewer.getBoundingClientRect();
  changeWipe(((e.clientX - rect.left) * 100) / rect.width);
}
viewer.addEventListener("pointerdown", (e) => {
  if (e.button === 0) {
    viewer.setPointerCapture(e.pointerId);
    pointerWipe(e);
  }
});
viewer.addEventListener("pointermove", (e) => {
  if (viewer.hasPointerCapture(e.pointerId)) pointerWipe(e);
});
el("wipe").addEventListener("input", (e) => changeWipe(e.target.value));
for (const method of ["learned", "baseline"])
  el(method).onclick = () => {
    currentMethod = method;
    refresh();
  };
el("mask").onchange = refresh;
el("scene").onchange = async (e) => {
  const choice =
    e.target.value === "local"
      ? custom
      : cases.find((x) => x.id === e.target.value);
  try {
    await inspectPair(choice);
  } catch (error) {
    el("scene").value = active?.id || "";
    el("feedback").textContent = error.message;
  }
};
el("upload").onclick = () => {
  el("error").textContent = "";
  el("local").showModal();
};
el("dismiss").onclick = () => el("local").close();
el("localForm").onsubmit = async (e) => {
  e.preventDefault();
  const files = ["localRef", "localCand"].map((id) => el(id).files[0]);
  if (
    files.some(
      (f) =>
        !f ||
        !["image/png", "image/jpeg", "image/webp"].includes(f.type) ||
        f.size > 24_000_000,
    )
  ) {
    el("error").textContent =
      "Choose a PNG, JPEG or WebP under 24 MB for each frame.";
    return;
  }
  const pending = files.map((f) => URL.createObjectURL(f));
  const localRow = {
    id: "local",
    title: "Your local pair",
    detail: files.map((f) => f.name).join(" → "),
    reference: pending[0],
    candidate: pending[1],
  };
  el("inspect").disabled = true;
  el("error").textContent = "";
  try {
    if (!(await inspectPair(localRow))) {
      pending.forEach(URL.revokeObjectURL);
      return;
    }
    urls.forEach(URL.revokeObjectURL);
    urls = pending;
    custom = localRow;
    if (!el("scene").querySelector('option[value="local"]'))
      el("scene").add(new Option("Your local pair", "local"));
    el("scene").value = "local";
    el("local").close();
  } catch (error) {
    pending.forEach(URL.revokeObjectURL);
    el("error").textContent = error.message;
  } finally {
    el("inspect").disabled = false;
  }
};
el("download").onclick = () => {
  const data = {
    schema: 1,
    caseId: active.id,
    dimensions: el("dimensions").textContent,
    columns: COLS,
    rows: ROWS,
    modelVersion: model.version,
    threshold: model.threshold,
    baselineThreshold: model.baselineThreshold,
    ...result,
  };
  const url = URL.createObjectURL(
    new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = "frame-triage-" + active.id + ".json";
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
};
try {
  let metrics;
  [model, cases, metrics] = await Promise.all(
    ["model", "cases", "evaluation"].map(loadJSON),
  );
  el("scene").replaceChildren(
    ...cases.map((row) => new Option(row.title, row.id)),
  );
  for (const [key, label] of [
    ["learned", "Learned detector"],
    ["baseline", "Pixel baseline"],
  ]) {
    const m = metrics[key],
      tr = document.createElement("tr");
    for (const [i, val] of [
      label,
      m.tp + " / " + (m.tp + m.fn),
      m.fp,
      m.meanMaskIoU.toFixed(3),
    ].entries()) {
      const cell = document.createElement(i ? "td" : "th");
      if (!i) cell.scope = "row";
      cell.textContent = val;
      tr.append(cell);
    }
    el("metrics").append(tr);
  }
  await inspectPair(cases[0]);
  el("scene").disabled = false;
} catch (error) {
  el("feedback").textContent = "Workbench could not load. " + error.message;
}
