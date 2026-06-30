# AGENTS.md — Pokémon Mystery Dungeon Fangame (PMD)

## Project identity

**Game:** Pokémon Mystery Dungeon fangame
**Engine:** Godot 4.7 (standard, not Mono/.NET)
**Language:** GDScript 2.0 (all game logic)
**Data format:** hand-authored JSON in `data/`
**Developer:** ismael (GitHub: ismaelt98)
**Repository:** https://github.com/ismaelt98/pmd-fangame

This is a **Pokémon Mystery Dungeon fangame** — NOT a main-series Pokémon game. Key differences from mainline:
- Grid-based movement (1 tile per input)
- Turn-based system: 1 action = 1 turn, enemies move after player
- Combat happens ON the dungeon grid (no separate battle scene)
- Belly/hunger system
- No Poké Balls for catching; enemies are recruited after defeat
- Floors are procedurally generated
- Levels reset when leaving a dungeon (PMD classic style)

---

## Running the project

- Open `project.godot` in Godot 4.7 Editor, press **F5** to play.
- CLI alternative: `godot --path "<project-dir>"` (Godot must be in PATH).
- No build step, no package manager, no Node/Python required.

---

## Architecture

### Autoload singletons (global, loaded at startup)

| Singleton | File | Purpose |
|-----------|------|---------|
| `EventBus` | `scripts/autoload/event_bus.gd` | Global signal bus. ALL cross-system communication flows here. No direct coupling. |
| `GameData` | `scripts/autoload/game_data.gd` | Loads all 6 JSON data files at startup. Access via `GameData.get_pokemon(id)`, `GameData.get_move(id)`, etc. Returns `{}` when ID not found. |
| `TurnManager` | `scripts/autoload/turn_manager.gd` | State machine: `WAITING_INPUT → PLAYER_ACTING → ENEMY_TURN → WAITING_INPUT`. One action = one full cycle. |

### Scene tree at runtime

```
GameRoot (game_root.gd) — triggers dungeon generation on _ready()
  └─ FloorManager (floor_manager.gd) — group: "floor_managers"
       ├─ DungeonGenerator (dungeon_generator.gd) — BSP algorithm
       ├─ Camera2D — follows player
       ├─ GridDrawer (inner class) — renders floor with _draw()
       └─ Player (PlayerEntity) — created at runtime via _spawn_player()
```

### Signal flow (via EventBus)

```
Input → GridMover._handle_input()
  → TurnManager.request_player_action()
    → executes action (move/attack/wait)
    → TurnManager._execute_enemy_turn()
    → each enemy.take_turn()
    → EventBus.turn_advanced.emit(turn_number)
    → state = WAITING_INPUT (ready for next input)
```

Key signals:
- `player_moved(position, direction)` — emit after player moves
- `turn_advanced(turn_number)` — emit after full turn cycle
- `enemy_turn_started / enemy_turn_ended`
- `floor_generated(floor_data)` — new floor is ready
- `player_damaged(amount, source)` / `enemy_defeated(enemy)`
- `hunger_changed(value, max_value)`
- `game_over`

### Class hierarchy (entities)

```
CharacterBody2D
  ├─ GridMover (grid_movement.gd) — grid-based movement, WASD input
  │    └─ PlayerEntity (player.gd) — player-specific: attack, facing enemy detection
  └─ PokemonEntity (pokemon_entity.gd) — base for enemies/allies
       stats: PokemonStats resource (pokemon_id, level, hp, atk, def, spa, spd, spe, types, moves, belly)
```

---

## File structure

```
pmd-fangame/
├── project.godot              # Engine config, autoloads, InputMap
├── AGENTS.md                  # This file
├── .gitignore                 # Ignores .godot/, *.uid, .import/
├── icon.svg                   # PMD logo placeholder
├── assets/                    # Sprites, audio, fonts (empty, placeholders)
│   ├── sprites/pokemon/
│   ├── sprites/tiles/
│   ├── sprites/ui/
│   ├── audio/bgm/
│   ├── audio/sfx/
│   └── fonts/
├── data/                      # All game data as JSON
│   ├── pokemon.json           # 4 test Pokémon: bulbasaur, charmander, squirtle, pikachu
│   ├── moves.json             # 12 moves with type, category, power, accuracy, range
│   ├── abilities.json         # 5 abilities
│   ├── items.json             # 10 items: berries, food, orbs, held items
│   ├── type_chart.json        # Full 18-type effectiveness chart
│   └── dungeons.json          # 3 dungeons: test_dungeon, tiny_woods, thunder_cave
├── scenes/
│   ├── main.tscn              # GameRoot → FloorManager → DungeonGenerator → Camera2D
│   └── ui/                    # Future: HUD, menus, dialogue
└── scripts/
    ├── autoload/
    │   ├── event_bus.gd
    │   ├── game_data.gd
    │   └── turn_manager.gd
    ├── game_root.gd           # Kickstarts floor generation
    ├── dungeon/
    │   ├── dungeon_generator.gd   # BSP room generation + hallway carving
    │   └── floor_manager.gd       # Visual rendering, player spawn, walkability check
    ├── entities/
    │   ├── grid_movement.gd       # Base player movement (WASD grid)
    │   ├── player.gd              # Player-specific: attack, damage, level
    │   ├── pokemon_entity.gd      # Base entity for all Pokémon
    │   └── stats.gd               # PokemonStats resource (HP, stats, belly, moves)
    ├── combat/                # Future: move_resolver, damage_calculator, status_effects
    ├── systems/               # Future: hunger, inventory, recruitment, save
    └── ui/                    # Future: HUD, menus
```

---

## Data conventions

- **IDs are in English, display names in Spanish.** e.g., `"id": "thunder_shock"`, `"name": "Impactrueno"`.
- All JSON files are hand-edited, no code generation.
- `GameData._load_json()` uses `FileAccess` + `JSON.parse()`. Missing files produce a warning but don't crash.
- Type chart is attacker-type → defender-type map. `get_type_effectiveness()` returns a float multiplier.

### Pokemon data format (pokemon.json key entry)
```json
"pikachu": {
  "id": "pikachu",
  "name": "Pikachu",
  "types": ["electric"],
  "base_stats": {"hp": 35, "atk": 55, "def": 40, "spa": 50, "spd": 50, "spe": 90},
  "moves_levelup": {"1": ["thunder_shock", "growl"], "4": ["tail_whip"], ...},
  "abilities": ["static"],
  "evolution": {"into": "raichu", "method": "thunder_stone"}
}
```

### Move data format
```json
"thunderbolt": {
  "id": "thunderbolt", "name": "Rayo",
  "type": "electric", "category": "special",
  "power": 90, "accuracy": 100, "pp": 15,
  "range": 1
}
```

---

## Dungeon generation (BSP algorithm)

`DungeonGenerator` uses recursive Binary Space Partition:

1. Grid initialized as all WALL
2. Root area split horizontally or vertically (random choice)
3. Split recursively until max rooms or max depth
4. Each leaf creates a room (random size within area)
5. Rooms carved as FLOOR tiles
6. Adjacent rooms connected with L-shaped hallways (HALLWAY tiles)
7. Stairs placed in the last room

**Tile enum:**
```gdscript
enum Tile { FLOOR=0, WALL=1, WATER=2, LAVA=3, STAIRS=4, TRAP=5, HALLWAY=6 }
```

Walkable tiles: FLOOR, HALLWAY, STAIRS (checked via `DungeonGenerator.is_walkable()` → exposed through `FloorManager.is_tile_walkable()`).

---

## Movement system

- **Grid-based:** Player moves 1 tile at a time. Each move = 1 turn.
- **Input keys:**
  - WASD = cardinal movement
  - QEZC = diagonal movement
  - Space = wait (pass turn)
  - E = interact (conflicts with diagonal up-right in current InputMap — needs fix)
  - F = attack
  - Escape = open menu
- **Walkability:** `GridMover._is_tile_walkable()` queries the FloorManager group (not physics — no collision bodies exist).
- **Smooth interpolation:** Visual movement uses `move_toward()` at 120px/s for smooth tile-to-tile sliding.
- **Facing:** Direction tracked as Vector2i, used for attack targeting.

---

## Current state

### ✅ Implemented
- Grid-based movement with WASD + diagonals
- Turn system (player → enemies → wait for input)
- BSP dungeon generation (rooms, hallways, stairs)
- Colored tile rendering via `_draw()`
- PokemonStats resource with stat calculation formula
- 4 test Pokémon with moves, 12 moves, full type chart
- PlayerEntity with basic attack (facing-tile targeting)
- Damage calculation (type effectiveness + STAB + random factor)

### ❌ Not yet implemented
- Enemy spawning in dungeons
- Enemy AI (wander, chase, attack)
- Real combat with move selection UI
- Status effects (paralysis, burn, sleep, etc.)
- Belly/hunger system (data exists in stats.gd, not wired)
- Inventory system
- Team/companions (recruitment)
- UI/HUD (HP bar, belly bar, minimap)
- Save/load system
- Story, dialogue, towns, NPCs
- Audio
- Proper sprites (currently colored rectangles)
- Stairs interaction (descending to next floor)

---

## Development conventions

- **GDScript 2.0** — no semicolons, 4-space indentation, typed arrays where useful.
- **`class_name`** for shared types: `GridMover`, `PokemonEntity`, `PlayerEntity`, `FloorManager`, `DungeonGenerator`, `PokemonStats`.
- **`@export`** for inspector-tweakable properties; **`@onready`** for node references.
- **`EventBus` signals** for all cross-system communication. Never call methods across systems directly.
- **`res://` paths** in `.tscn` and `.gd` files — relative to project root.
- **`.uid` files are gitignored** — Godot regenerates them. Never commit.
- **`.godot/` is gitignored** — editor-specific cache.
- **Physics is NOT used** for walkability — uses grid data direct queries via FloorManager group. Collision shapes on entities exist but are decorative/for future use.
- **Floor rendering** uses `_draw()` with colored rectangles — no TileMap nodes, no external tilesets.
- **No tests, no CI, no linter** at this stage.
- **Sprites/sound** will be added later by the user; the engine expects placeholder colors/textures.

---

## Roadmap (planned phases)

| Phase | Week | Systems |
|-------|------|---------|
| 1 | 1-2 | ✅ Grid movement + TurnManager |
| 2 | 3-4 | ✅ Dungeon BSP generation |
| 3 | 5-6 | 🔜 Enemy spawning + basic AI (wander/chase) |
| 4 | 7-8 | Combat system (move resolver, type chart, status effects) |
| 5 | 9 | Hunger + inventory + items |
| 6 | 10-11 | Companions, recruitment, team management |
| 7 | 12 | UI/HUD (HP bars, belly, minimap, menus) |
| 8 | 13-14 | Save/load + progression system |
| 9 | 15+ | Story, towns, NPCs, polish, audio, sprites |

**Next immediate task:** Enemy spawning + basic enemy AI (wander randomly, chase player if visible).

---

## GitHub workflow

The developer (ismael) works on a Windows PC with Godot 4.7 + GitHub Desktop. The AI assistant pushes code from this server.

```
ismael's PC (Godot) ──pull──► GitHub ◄──push── AI (server)
    │                                              │
    └── git pull (GitHub Desktop)                  └── git commit + push
```

When the AI makes changes:
1. AI commits and pushes to GitHub
2. ismael opens GitHub Desktop, clicks "Pull origin"
3. Changes appear in Godot project

When ismael makes changes:
1. ismael works in Godot (creates scenes, adds sprites, tweaks values)
2. Opens GitHub Desktop, commits and pushes
3. AI pulls (`git pull`) before making new changes

---

## Important: E-key input conflict

In `project.godot` InputMap, both `interact` and `move_diag_up_right` bind to physical key **E**. This causes the player to move diagonally when trying to interact. Needs resolution — likely remap `interact` to a different key or remove diagonal E binding.

---

## Resource links

- Godot 4.7 download: https://godotengine.org
- Godot GDScript docs: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- Mystery Dungeon mechanics reference: https://bulbapedia.bulbagarden.net/wiki/Pokémon_Mystery_Dungeon
- PMD ROM editor (for studying mechanics): https://github.com/SkyTemple/skytemple
