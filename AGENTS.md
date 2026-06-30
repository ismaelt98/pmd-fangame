# AGENTS.md

## Tech stack
- **Godot 4.7** (engine binary, not Mono). No external toolchain — no Node, Python, or compiled languages.
- All source is **GDScript** with static data in hand-authored **JSON** (`data/`).

## Running
- Open `project.godot` in Godot 4.7 Editor, press **F5** to play.
- CLI: `godot --path "<project-dir>"` (requires Godot 4.7 in PATH).
- There is no build step, no dev server, no package manager.

## Architecture

### Autoload singletons (always loaded, usable from any script)
- `EventBus` — global signal bus; all cross-system communication flows through it.
- `GameData` — loads all JSON files from `data/` at startup. Access via `GameData.get_pokemon(id)`, `GameData.get_move(id)`, etc.
- `TurnManager` — state machine: `WAITING_INPUT → PLAYER_ACTING → ENEMY_TURN → WAITING_INPUT`.

### Scene tree at runtime
```
GameRoot (game_root.gd)
  FloorManager (floor_manager.gd)
    DungeonGenerator (dungeon_generator.gd)
    Camera2D
    GridDrawer (Node2D inner class of FloorManager)
    Player (PlayerEntity, created at runtime in _spawn_player())
```

### Signal flow
All cross-cutting events go through `EventBus` signals (player_moved, turn_advanced, floor_generated, etc.). Scripts connect to signals they care about — no direct coupling between systems.

### Data
- `data/*.json` — hand-edited, no codegen. Schema is consistent but not validated.
- `GameData._load_all_data()` reads all 6 files via `FileAccess` + `JSON.parse()` at startup.
- Lookup functions return empty `{}` when an ID is not found.

## Development conventions
- **No tests exist.** No CI, no linter, no formatter configured.
- Use `class_name` for shared types (6 registered classes in global_script_class_cache.cfg).
- Signals declared at top of scripts; `@export` for inspector properties; `@onready` for node refs.
- 4-space indentation, no semicolons (standard GDScript style).
- File UIDs (`*.uid`) are **gitignored** — the editor regenerates them. Never commit them.
- Use `res://` paths in `.tscn` and `.gd` files.

## Input bindings
Defined in `project.godot` InputMap. Note: both `interact` and `move_diag_up_right` bind to physical key **E**, which may cause conflicts.
