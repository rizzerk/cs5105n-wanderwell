# Wanderwell

2D precision platformer made in Godot 4.7.2 for CS-5105N Game Development.
 
## Overview
 
The player controls a girl carrying a lantern who moves through platform levels. Visibility is limited to the area around the lantern, so jumps have to be judged from partial information. The focus is on jump feel: input forgiveness (coyote time), landing feedback, and levels where safe ground and hazards are easy to tell apart.

## Game Genre

**2D Platformer / Atmospheric Precision Platforming**

The game focuses on:

* Precise, responsive jump-based movement
* Limited visibility as the core source of tension
* Navigating platform layouts mostly by instinct and partial information
* Physics-based interaction with the world
* Game feel — making commitment to an uncertain jump satisfying rather than frustrating

## Activity 1 — Hello World Scene

The first prototype for Wanderwell is a simple 2D Godot scene containing a `Node2D` root and a `Sprite2D` placeholder. The scene runs successfully as the initial foundation for the game.

* Created the **Wanderwell** Godot project.
* Created a `Node2D` as the root node.
* Added a `Sprite2D` with a placeholder image.
* Ran the 2D scene successfully.
* Created and initialized the Git repository.
* Added a Godot `.gitignore`.
* Configured Git LFS for large art and audio files.
* Created the GitHub repository and pushed the project.

### Screenshot

![Activity 1 — Hello World Scene](screenshots/hello-world.png)

## Activity 2 — Core Mechanic & Game Feel

**Core Mechanic:** The player jumps between platforms to descend through the level.

### Objectives

* Implement keyboard-driven player movement using Godot's Input Map system.
* Build a level layout using `StaticBody2D` collision geometry for boundaries and platforms.
* Implement the player as a `CharacterBody2D`, handling gravity, horizontal movement, and jumping via `move_and_slide()`.
* Add at least one "juice" element to make the core mechanic feel more responsive.
* Diagnose and resolve issues arising from the interaction between visual scale, collision shapes, and Godot's default collision layer/mask system.

### Level Construction

The level (`Main` scene) was built using a combination of node types suited to static, non-moving geometry:

* **Boundary walls** — `left`, `right`, `top`, and `ground` `StaticBody2D` nodes, each with an assigned `CollisionShape2D`, forming the playable bounds of the level.
* **Platforms** — `l-platform`, `floating-platform`, and `t-platform`, each using `CollisionPolygon2D` for more precise, non-rectangular collision geometry matching their tile art.


### Input Configuration

Three input actions were defined under **Project Settings → Input Map**:

| Action | Binding |
|---|---|
| `move_left` | A / Left Arrow |
| `move_right` | D / Right Arrow |
| `jump` | Space |

These map directly to `Input.get_axis()` and `Input.is_action_just_pressed()` calls in the player script, decoupling gameplay logic from specific key bindings.

### Player Script — Core Mechanic

The Player node is a `CharacterBody2D` with an attached GDScript handling:

* **Gravity and vertical movement** — applied manually each physics frame when the player is airborne, reset when grounded.
* **Horizontal movement** — driven by `Input.get_axis("move_left", "move_right")`, scaled by an exported `speed` value for easy tuning from the Inspector.
* **Jumping** — triggered on `jump` input, applying a negative vertical velocity (`jump_velocity`).
* **Coyote time** — a short (0.12s) grace window after leaving a platform edge during which a jump input still registers, preventing the common "walked off and pressed jump a frame too late" frustration. The timer is explicitly zeroed the instant a jump is consumed, ensuring it cannot be reused to perform an unintended double jump mid-air.

### Game Feel (Juice)

Two juice elements were implemented:

1. **Coyote time** (described above) — improves input forgiveness and perceived responsiveness.
2. **Squash-and-stretch on landing** — the player sprite briefly scales non-uniformly on landing, then smoothly interpolates (`lerp`) back to its resting scale, giving landings visual weight and impact.

### Testing & Results

* Player responds correctly to horizontal input and jump input.
* Player collides correctly with all boundary and platform geometry.
* Coyote time verified to allow a single late jump after leaving a platform edge, without permitting an additional mid-air jump.
* Squash-and-stretch effect visibly triggers on landing and correctly returns to the sprite's original authored scale.
* Physics values (speed, gravity, jump height) tuned via the Inspector until movement felt responsive rather than floaty or overly heavy.

### Screenshot

![Activity 2 — Core Mechanic & Game Feel](screenshots/core-mechanic.png)


## Activity 3 — Level Design
 
**Goal:** Two playable levels built with `TileMapLayer`, each with a start, a goal, hazards, and a transition to the next level.
 
### Implementation
 
* Levels are painted on a `TileMapLayer` using the `Ground` terrain in `tileset_64.tres`. Edges and corners are connected automatically.
* Spikes are `Area2D` scenes with `hazard.gd`. A wide `Area2D` below each level acts as a kill zone for falling out of the level.
* The goal is an `Area2D` with `goal.gd`. Level 1's `next_level` points to `level_2.tscn`. Level 2 leaves it empty.
* The player starts at a `Marker2D` position and respawns there after a hazard.
* The Activity 2 `StaticBody2D` platforms were replaced by the tilemap.

### Difficulty Curve
 
Jump limits with the current values: height is `v² / (2g)` = 73.5 px (about 1.1 tiles), air time is `2v / g` = 0.7 s, and horizontal distance is `speed × air time` = 210 px (about 3.3 tiles). Coyote time adds about 36 px. Every step up in the levels is 1 tile or less.
 
### Readability and Inclusive Content
 
**Reflection:** All characters and set pieces are original and stylized, with no real-world cultural symbols used as decoration or hazards, and hazards are distinguished by shape and brightness, not color alone, so the levels stay readable for color-blind players.
 
* Spikes are pale and jagged. Safe ground has a bright top edge.
* The goal is the only warm light in the level.
* Checked in grayscale: hazards are still distinguishable from safe ground.
### Testing & Results
 
* Level 1 can be completed from start to goal.
* Level 2 can be completed from start to goal.
* Touching spikes or falling into a pit respawns the player at the start.
* Reaching the goal in Level 1 loads Level 2.
* The player cannot stand up under a low ceiling while crouched.
* All animations play correctly.
### Screenshots
 
**Level 1**
 
![Activity 3 — Level 1](screenshots/level-1.png)
 
**Level 2**
 
![Activity 3 — Level 2](screenshots/level-2.png)
 
## Credits
 
Tileset, character sprites, and the player, hazard, and goal scripts were made with AI assistance (Claude) and edited for this project.


## Activity 4 — Art, Animation & Particles

**Note:** The character's main animations (idle, run, jump, crouch, etc.) were
built in Week 3 as part of the tilemap and player-state work, before this
activity's scope was clarified. This week adds the AnimationPlayer-driven 
effects, particles, lighting, and AI asset below.

### AnimationPlayer

An `AnimationPlayer` was added to the Player, building two animations in code
at runtime (`_build_animations()` in `player.gd`):

* `land_squash` — tweens `AnimatedSprite2D.scale` on landing, replacing the
  manual `lerp` used in Week 2/3.
* `lantern_flicker` — loops a subtle random flicker on the lantern's
  `PointLight2D.energy`, between 0.85 and 1.0, on a 1.4s cycle.

### Particles

A `CPUParticles2D` node (`LandingDust`) emits a one-shot burst of 10 particles
when the player lands, using the pre-collision fall speed (captured just
before `move_and_slide()`, since `move_and_slide()` zeroes `velocity.y` on
contact with the floor). Dust triggers when fall speed exceeds 100 px/s, so
small hops stay quiet and real falls kick up visible dust.

### Lighting

* The lantern carries a `PointLight2D` (child of `AnimatedSprite2D`) using a
  radial `GradientTexture2D`, warm amber color, mirrored on the X axis with
  the character's facing direction.
* Each level has a `CanvasModulate` darkening the scene, so the lantern is the
  main source of visible light. Darkness increases per level:

### AI-Generated Asset

* **Tool:** Google Gemini (Nano Banana)
* **Asset:** a decorative glowing crystal cluster, placed in levels as ambient
  scenery, lit by its own `PointLight2D`.
* **Edits made:** the first generation was smooth-shaded and didn't match the
  game's flat pixel art, so it went through a second pass: background removed
  (alpha-keyed), cropped to content, downscaled and color-quantized to a
  7-color palette shared with the tileset, then re-scaled with
  nearest-neighbor to restore hard pixel edges consistent with the rest of
  the game's art.

![Activity 4](screenshots/week4.png)

### Testing & Results

* Landing dust appears on real falls, not on small hops.
* Lantern light follows the player and flips sides with facing direction.
* Lantern flicker animation loops without stopping.
* Crystal asset is lit and visible in at least one level.
