# AGENTS.md

Minnen is a HaxeFlixel 6.2 / OpenFL 9.5 / Lime 8.3 game (Haxe) about night terrors, being rebuilt around a curved "rolling log" world.
- Entry: `source/Main.hx` boots `menu/MenuState` (or `planes/LogWorld` with `-Dskipmenu`). Active work lives in `source/logworld/` and `source/planes/LogWorld.hx`; `planes/Level1.hx`, `planes/BetterTutorial.hx`, LDtk (`assets/data/tutorial.ldtk`) and Tiled levels are older prototypes.
- Build/run: `lime test linux` (add `-Dskipmenu`, `-Dskipmenu -Ddemo`, or `-debug`). Native builds require shaders. No automated tests; verify by running the build.
- Libraries are declared in `Project.xml` (`flixel`, `flixel-addons`, `ldtk-haxe-api`, `deepnightLibs`, `hxcpp-debug-server`).

## Code Review Rules

### Always flag (P0/P1)
- Changes to the projection math in `logworld/LogCamera.hx` (`refresh`, `project`, horizon/fog values) without the matching change to the inverse in the GLSL of `logworld/LogGroundShader.hx`, or vice versa. The class docs require the two to stay in sync; props and ground will visibly separate otherwise. Safe path: change both in the same PR, and add any new uniform to `LogGroundShader.sync()`.
- New per-frame allocations in `update()` / `draw()` of `LogWorld`, `WorldSprite`, `WorldShadow`, `LogPlayer` or `CreepyFilter`: `new FlxPoint`/`FlxRect`, arrays, anonymous structures, string building, or `Placeholder.*` calls. `draw()` runs for thousands of props (`TREE_COUNT` 1500 + rocks + houses + shadows). Safe path: reuse fields like `proj`/`clipBuffer`/`LogCamera.scratch`, or pooled `FlxPoint.get()` paired with `put()`. The debug HUD string in `handleDebugKeys` is an accepted exception while it stays gated on `hud.visible`.
- `WorldSprite.draw()` mutations that are not restored: it temporarily overwrites `x`, `y` and `scale` for projection and must restore them before returning, or collisions (`FlxG.collide(obstacles, player)`) run against projected screen coordinates.
- Pooled objects that leak or double-free: every `FlxPoint.get()`/`FlxRect.get()` needs exactly one `put()` (see the grid cleanup at the end of `LogWorld.populate()` and `WorldSprite.destroy()`).
- Procedural art in `Placeholder` that bypasses `paint()`'s `FlxG.bitmap` cache key, or reuses a key for different content. Graphics are `persist = true`, so a key that includes a per-call random or float value leaks a new bitmap on every call, and a colliding key silently returns the wrong art.
- `Sys.*` calls (such as `Sys.exit`) not behind a `#if sys`/`#if desktop`/`#if demo` style guard. They break html5/flash targets that `Project.xml` still declares.

### Flag when relevant
- Static mutable state (`LogCamera` tunables/focus, `Reg` fields, `FlxG.worldBounds`, `FlxG.mouse.visible`, `FlxG.autoPause`) set in one state's `create()` but assumed reset by another state. It survives `FlxG.switchState`. Safe path: set what the state needs in its own `create()`.
- Extra cameras or filters (`hudCamera`, `CreepyFilter.filter`) added in a way that stacks when the state is re-entered (for example, Backspace to menu and back), or HUD objects not assigned to the HUD camera, which makes them get the CRT/VHS filter.
- Uniform names passed to `FlxRuntimeShader.setFloat` that don't match a `uniform` declared in the shader source. This fails silently at runtime.
- Asset paths that differ in case from the files under `assets/`, including `@:sound(...)` paths in `tools/TypeText.hx` and the LDtk macro path in `tools/LdtkProject.hx`. Linux builds are case-sensitive.
- Depth sorting in `LogWorld.draw()` that drops the far-to-near order, or new entity groups whose members are not refreshed with `refreshProjection()` before `super.draw()`.
- Changes to `LogWorld`'s `FlxRandom(1337)` seed, or new unseeded `FlxG.random` calls in world generation. The layout is deterministic on purpose, including for the `-Ddemo` footage route.
- `Project.xml` library or window changes (`require-shaders`, `allow-shaders`, fps, resolution) that aren't mentioned in the PR description.

### Don't flag
- Code-generated placeholder art, magic tuning constants, or the debug key bindings in the log world. They are documented prototype shortcuts.
- Legacy code in `planes/Level1.hx`, `planes/BetterTutorial.hx`, `players/Player.hx`, `tools/TypeText.hx` and the Tiled/LDtk assets, unless the PR changes it.
- Formatting (`hxformat.json` owns it), naming style, or missing unit tests.
