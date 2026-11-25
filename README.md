# pang-bubble-game
A Pang-style arcade game: fire your harpoon to split bouncing bubbles into smaller ones until the level is clear.

Built with **Godot 4.3+** (GL Compatibility renderer, so it runs on older phones too).
It uses no third-party assets. All graphics are drawn in code, and the sound effects are tiny WAV files made by `tools/make_sounds.py`.

## Gameplay
- Shoot the harpoon straight up. A bubble that gets hit splits into two smaller bubbles; the smallest ones just pop.
- Clear every bubble to finish the level. There are **50 levels** across 5 worlds (Sky, Jungle, Desert, Night, Candy).
- A bubble touching you, or the timer running out, costs a life. You start with 3.
- Popped bubbles sometimes drop power-ups:
  - **x2**: two harpoons at once
  - **F**: freezes the bubbles for 5 seconds
  - **S**: a shield that blocks one hit
  - **+1**: an extra life
- Your progress (highest level reached) and your high score are saved.

## Controls
| | Keyboard | Touch |
|---|---|---|
| Move | ← → or A / D | drag on the left half of the screen |
| Fire | Space, ↑, W or Enter | tap on the right half of the screen |

## Run it
1. Install Godot 4.3 or newer from https://godotengine.org/download
2. Open Godot, click **Import**, and select this folder's `project.godot`.
3. Press **F5** to play.

## Put it on an iPhone
This needs a Mac with Xcode and an Apple Developer account.
1. In Godot: **Editor → Manage Export Templates → Download and Install**.
2. **Project → Export → Add… → iOS**. Fill in your App Store Team ID and a bundle identifier (e.g. `com.densible.pangbubble`), then export the Xcode project.
3. Open the exported `.xcodeproj` in Xcode, connect your iPhone, choose it as the run target, and press **Run**.

## Project layout
```
project.godot        engine settings (1280x720 landscape)
scenes/main.tscn     the only scene
scripts/main.gd      game flow, levels, HUD, power-ups, saving
scripts/player.gd    the player
scripts/bubble.gd    bouncing bubbles
scripts/harpoon.gd   the harpoon shot
scripts/powerup.gd   power-up boxes
scripts/touch_controls.gd   on-screen joystick + fire button
scripts/config.gd    play-field constants
sounds/              generated sound effects
tools/make_sounds.py regenerates the sounds
```
