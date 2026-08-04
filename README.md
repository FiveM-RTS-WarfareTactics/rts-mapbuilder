# RTS Map Builder

In-game map editor for creating custom RTS battlefield maps with objective and spawn point placement.

**Dependencies:** `enyo-rts` (for GetMaps export), `rts-admin` (for Load Map integration)

## Commands
| Command | Description |
|---------|-------------|
| `/buildmap [x] [y] [z] [radius]` | Start editor at coordinates |
| `/spawn [model]` | Spawn preview object at cursor |
| `/removelast` | Remove last placed object |
| `/clearmap` | Clear all objects, objectives, and spawns |

## Model Browser
Left sidebar with search and categories:
- **PROPS** — 100+ pre-listed decorative objects
- **VEHICLES** — 40+ pre-listed vehicle models
- **OBJECTIVES** — Victory/Resource point placement with radius, capture rate, name
- **SPAWNS** — Team 1/Team 2 spawn point placement
- **Custom input** — type any model name and press Enter to spawn

## Editor Controls
| Key | Action |
|-----|--------|
| LMB | Place object / Place objective / Confirm spawn point |
| RMB | Cancel preview / Cancel pickup |
| E | Pick up object at cursor |
| C | Clone object at cursor (in placing mode) |
| Del | Delete object at cursor / Delete preview |
| ← → | Rotate object |
| Shift + move | Vertical height adjustment |
| R | Snap object to ground |
| Backspace | Exit builder |
| Mouse wheel | Zoom in/out |
| Mouse edges | Pan camera |

## Objective Placement
1. Select OBJECTIVES tab → click Victory or Resource
2. Gold circle follows cursor with zone marker
3. LMB to place → right panel shows property editor
4. Edit name, type, radius, capture rate, bonus
5. Click Update to save changes
6. Press E near an objective to move it, Del to delete

## Map Export
Click **Export** in top bar — outputs complete map config to F8 console in `Config.Maps` format including center, range, spawns, objectives, and decorative objects.

## Loading Existing Maps
From admin panel Builder tab: select a map → click Load Map. All objects, objectives, and spawns auto-place into the editor.

## Events
| Event | Type | Description |
|---|---|---|
| `rts-mapbuilder:loadMapData` | Client (received) | Load existing map data into editor |
| `rts-admin:openPanel` | Client (triggered) | Return to admin panel on exit |

## License
Apache 2.0
