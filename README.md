<img src=".github/brand/logo.svg" width="80" alt="" />

# Minnen

A psychological game about night terrors, built in HaxeFlixel. Started in 2017, currently being rebuilt around a curved "rolling log" world.

![status](https://img.shields.io/badge/status-wip-dbbc7f?style=flat&labelColor=2d353b)
![Haxe](https://img.shields.io/badge/Haxe-7fbbb3?style=flat&labelColor=2d353b&logo=haxe&logoColor=d3c6aa)
![HaxeFlixel](https://img.shields.io/badge/HaxeFlixel_6.2-7fbbb3?style=flat&labelColor=2d353b)
![OpenFL](https://img.shields.io/badge/OpenFL_9.5-7fbbb3?style=flat&labelColor=2d353b)

<p align="center"><img src="assets/images/CharSpriteSheet_BLACK.png" alt="Minnen character walk-cycle sprite sheet" width="420"></p>

<p align="center"><sub>The protagonist's hand-drawn walk cycle, from <code>assets/images/</code>.</sub></p>

## What it does

The current build boots to a title screen and then into the rolling log world prototype:

- An Animal Crossing style curved world: gameplay runs on a flat 8192x8192 map, while rendering wraps it around a cylinder so the ground rolls away over a horizon
- A ground shader that draws the flat map texture onto the curve per pixel; props are drawn upright with distance scaling, fog, depth sorting and horizon clipping
- A placeholder world generated in code: dead trees, gravestones, flickering street lamps, houses, ponds, roads, and faceless watchers that vanish when approached
- A post-process filter with CRT barrel distortion, colour fringing, grain, scanlines, a VHS tracking band, a breathing vignette and glitch bursts
- The spiral-head protagonist with walk and idle animations and a soft shadow

Older work still in the tree: an LDtk tutorial level with typed dialogue and an NPC, and Tiled levels from the 2018 top-down prototype.

## Play

**Engine:** Haxe with HaxeFlixel 6.2, Lime 8.3.2 and OpenFL 9.5.2. Libraries from `Project.xml`: `flixel`, `flixel-addons`, `ldtk-haxe-api`, `deepnightLibs`, `hxcpp-debug-server`.

```bash
haxelib install flixel
haxelib install flixel-addons
haxelib install ldtk-haxe-api
haxelib install deepnightLibs
haxelib install hxcpp-debug-server

lime test linux                        # or windows / mac / hl
lime test linux -Dskipmenu             # boot straight into the log world
lime test linux -Dskipmenu -Ddemo      # scripted walk for recording footage
lime test linux -debug                 # enables the F / A / Esc keys below
```

The native build requires shader support. Builds go to `export/`.

**Controls** (from `Reg.hx`, `LogPlayer.hx` and `LogWorld.hx`):

| Input | Action |
|---|---|
| Arrow keys / D-pad | Move |
| Shift | Run |
| Enter | Start from the title screen |
| 1 / 2 | Curvature radius |
| 3 / 4 | Camera height |
| 5 / 6 | Camera distance |
| 7 / 8 | Zoom |
| C | Toggle the curve |
| H | Toggle the debug help |
| Backspace | Back to the title screen |
| F / A / Esc | Fullscreen / antialiasing / quit (debug builds, desktop) |

## Status

Work in progress. The log world uses placeholder art generated in code; the 0.1.0 milestone in `Todo.txt` (architecture, hub, level structure) is still open. History goes back to 2017 (see `Minnen_Changelog.txt`); this repo starts in 2018, moved to LDtk in 2021, and updated to HaxeFlixel 6.2 in September 2026.

## How this project is run

[![Tracked in Linear](https://img.shields.io/badge/tracked_in-Linear-5e6ad2?style=flat&labelColor=2d353b&logo=linear&logoColor=d3c6aa)](https://linear.app)
[![AI code review](https://img.shields.io/badge/code_review-Codex-7fbbb3?style=flat&labelColor=2d353b&logo=openai&logoColor=d3c6aa)](AGENTS.md)
[![master is PR-only](https://img.shields.io/badge/master-PR--only-a7c080?style=flat&labelColor=2d353b&logo=github&logoColor=d3c6aa)](#how-this-project-is-run)

- **Planning:** work is tracked in Linear as initiatives → projects → milestones → issues; branches and PR titles carry the issue ID so status moves automatically from In Progress to Done.
- **Review:** every pull request gets an automatic Codex review guided by this repo's own Code Review Rules in [`AGENTS.md`](AGENTS.md), and review threads must be resolved before merge.
- **Guardrails:** the default branch (`master`) only changes through pull requests — no direct pushes or force-pushes.

## License

Apache 2.0

---
<sub>Built by [Aladdin Ali](https://github.com/NaxeCode) · [naxecode.github.io](https://naxecode.github.io)</sub>
