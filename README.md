# Wanderwell

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
