# Platformer Template (LÖVE2D)

A minimal, no-libraries, no-classes starting point for 2D platformers. Built
incrementally, one small verifiable step at a time, so every mechanic in here
is well understood rather than copy-pasted from somewhere and half-trusted.

No assets included on purpose — this is a movement/collision/camera skeleton
meant to be the starting point for a specific game, not a game itself.

## Philosophy

- **No libraries.** Everything (collision, camera lerp, input handling) is
  hand-rolled, on purpose, so nothing here is a black box.
- **No classes.** Just plain Lua tables holding state (`Player.new(...)`
  returns a table) plus functions that take that table as their first
  argument and operate on it (`Player.update(p, dt, ...)`). A shared `Entity`
  base class is deliberately _not_ included yet — that abstraction is only
  worth building once a second moving thing (an enemy) creates real
  duplication to extract it from. Building it earlier means guessing at the
  split without a second data point to check the guess against.
- **Small, verified steps.** Every mechanic below was added and tested in
  isolation before the next one was layered on top, so bugs are easy to
  trace to a specific, recent change rather than buried in a big diff.

## Structure

```
conf.lua      -- window size/title (LÖVE config)
main.lua      -- wires everything together: load, update, input, draw
player.lua    -- player state + movement, jump, dash, wall slide/jump, collision
camera.lua    -- camera state + follow, look-ahead, smoothing
```

## Running it

Requires [LÖVE](https://love2d.org/). From the project root:

```
love .
```

## Controls (default, remappable — see below)

| Action                                           | Key                         |
| ------------------------------------------------ | --------------------------- |
| Move left / right                                | `a` / `d`                   |
| Jump (hold for full height, tap for a short hop) | `space`                     |
| Dash                                             | `j`                         |
| Wall jump                                        | `space`, while wall sliding |

## Features

**Movement & jump**

- `dt`-based movement (frame-rate independent)
- Gravity with acceleration, not constant fall speed
- **Coyote time** — a jump pressed shortly after walking off a ledge still works
- **Jump buffer** — a jump pressed shortly before landing still fires, right on landing
- **Variable jump height** — release early for a short hop, hold for a full jump.
  This also correctly applies to _buffered_ jumps: if the key was released
  before a buffered jump even fired, the cut is applied the instant it does.

**Dash**

- Fixed-duration horizontal burst, gravity disabled for the duration
- Resets on touching ground **or** regaining a wall to slide against

**Wall slide & wall jump**

- Wall contact is detected with a 1px "probe" check (nudge a copy of the
  player's box toward the wall, test for overlap, without moving the real
  position) — needed because normal collision resolution only fires _during_
  active movement into something, not on every frame you're merely touching it
- Sliding down a wall caps fall speed below normal gravity
- Wall jump pushes up and away from the wall (fixed height/distance), with a
  brief input-lock window so holding toward the wall doesn't instantly re-stick you

**Collision**

- Platforms and hazards are both plain `{ x, y, w, h }` rectangles
- Collision side (above/below/left/right) is determined by comparing the
  player's position _last frame_ to the platform's edges — not by comparing
  current overlap depth, which is ambiguous and was the source of two real
  bugs (dash-into-wall snapping onto the platform's top; jumping through a
  platform teleporting horizontally)

**Hazards**

- A hazard is just a rectangle that resets the player to spawn on contact
- Shares a `resetToSpawn` function with the "fell off the stage" check, so
  there's one definition of what "reset" means, not two

**Camera**

- Follows the player, biased toward the direction of travel (look-ahead)
- Look-ahead is **distance-based, not time-based** — it only shifts while the
  player is actually covering ground, and freezes the instant they stop, so a
  quick direction tap doesn't visibly jerk the camera
- Both the look-ahead value and the camera's position ease toward their
  targets (lerp) rather than snapping, for a smooth follow
- Reads screen width/height fresh every frame, so a resizable window works
  with no extra changes

**Key remapping**

- `Player.new(x, y, keys)` takes an optional table overriding any of
  `left` / `right` / `jump` / `dash`; anything omitted falls back to the default
  ```lua
  player = Player.new(100, 100, { jump = 'z', dash = 'x' })
  ```

## Extending this template

**Adding platforms/hazards** — just add entries to the tables in `main.lua`:

```lua
platforms = {
  { x = 0,   y = 400, w = 800, h = 100 },
  { x = 250, y = 280, w = 150, h = 20 },
}

hazards = {
  { x = 300, y = 380, w = 40, h = 20 },
}
```

**Adding an enemy** — this is the natural point to extract a shared
`entity.lua` (gravity + platform collision only — input, dash, and wall-jump
stay player-specific) once there's a second thing that actually needs the
same physics as the player.

**Camera Y-locking by zone** (e.g. camera holds still while the player is
within a "ground floor" band of platforms, only moves once they climb into a
taller area) — the _mechanism_ belongs here (a `zones` parameter passed into
`Camera.update`, same pattern as `hazards`), but the zone boundaries
themselves are level content and belong in the specific game, not this
template. Not implemented yet — deliberately deferred until there's a real
level to validate the zone shapes against.

**Things intentionally left out of this template**, to be built per-game
instead: a real tilemap/level format, scene/state management (menu → playing
→ game over), win conditions, sound, save systems. These depend on what the
specific game actually is; building them here would mean guessing at a shape
with nothing concrete to check the guess against.
