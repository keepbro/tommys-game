# CLAUDE.md

Notes for Claude Code working in this repo.

## Who you are talking to

**Tommy usually drives these sessions.** He is a kid, and this is his game — he
made it. So:

- Explain what you are doing in plain words. No jargon.
- Say what you changed and why, in a sentence or two, not a wall of text.
- Ask before doing anything big or hard to undo (deleting a level, rewriting a
  whole script, changing how the player moves).
- If an idea will not work, say so kindly and offer something that will.

Louis (dad) is around too and may take over mid-session.

## What this is

**Shooto** — a 2D parkour shooter built in **Godot 4.6** with **GDScript**.
Run and jump through levels, shoot monsters, beat the boss, take the exit.

The whole game is made of code. There are **no image files and no sound files**
anywhere in the project. Characters are drawn with `_draw()` calls and every
sound is built out of maths in `scripts/sfx.gd`.

## Running it

Godot lives at `/usr/bin/godot` (4.6.3 stable). Run these from the project root.

```bash
godot                    # play the game
godot -e                 # open the Godot editor
godot scenes/versus.tscn # jump straight into versus, skipping the menu
godot scenes/main.tscn   # jump straight into a level
```

To check your changes did not break anything **without opening a window**:

```bash
godot --headless --quit-after 5 scenes/main.tscn
godot --headless --quit-after 5 scenes/versus.tscn
```

Script errors show up as `SCRIPT ERROR:` in that output. A
`WARNING: ObjectDB instances leaked at exit` line is normal and harmless.

Do **not** use `godot --check-only --script <file>` — it does not load the
autoloads, so it reports fake errors about `Sfx` not existing.

Player settings (volume, team, username, friends) are saved outside the repo at
`~/.local/share/godot/app_userdata/Shooto/settings.cfg`.

## How the code is laid out

Everything is in `scripts/`. Scenes in `scenes/` are thin — most objects are
built in code rather than in the editor.

| File | What it does |
|---|---|
| `menu.gd` | Front end: loading, username, title, team, friends, settings screens |
| `main.gd` | The campaign. All 4 levels are data at the top of the file |
| `player.gd` | Moving, jumping, dashing, all 8 guns, the bag, and drawing the knight |
| `enemy.gd` | Four monsters: goblin, slime, bat, brute |
| `boss.gd` | The boss, plus `boss_bullet.gd` for its fireballs |
| `versus.gd` | Two-player mode, one keyboard, one screen |
| `sfx.gd` | **Autoload.** Every sound and the music, made from maths. Also saves settings |
| `input_setup.gd` | **Autoload.** Builds all the key bindings when the game starts |
| `hud.gd` | Bag, ammo, powerup timers, boss health bar, pop-up messages |
| `powerup.gd` | Every pickup, and the icons the HUD reuses |
| `chest.gd`, `exit_portal.gd`, `explosion.gd`, `spawn_effect.gd` | Level furniture and effects |
| `teams.gd` | The four team colours |
| `word_filter.gd` | Keeps rude words out of usernames |

### Adding a level

Levels are dictionaries in the `LEVELS` array in `main.gd`. Copy an existing one
and change the numbers. Each needs a name, colours, platforms, spawn points,
where the boss waits, and where the exit goes. The list loops back round to
level 1 when you finish the last one, but harder.

### Adding a weapon

Add an entry to the `WEAPONS` dictionary in `player.gd`, then an icon in
`draw_icon()` and a colour in `_icon_color()` in `powerup.gd`. Add its name to
the loot lists in `chest.gd` and `versus.gd` so it can actually drop.

## How to write code here

**Comments are written so Tommy can read them.** This matters — keep it up.
Explain *why* something happens in plain words, not what the syntax does.
Playful is good. Real examples from the codebase:

```gdscript
# MIND THE GAP! There is a big hole in the middle - don't fall in.
# The boss wakes up when you get near its lair
# POP! Burst into bits the same colour as the monster
# guns kick you backwards!
```

Other conventions:

- **Prefer making things out of code** — draw art in `_draw()`, build sounds in
  `sfx.gd`. That is the fun of this project. If something genuinely cannot be
  done that way, say so and ask before adding an asset file or a plugin.
- Tabs for indentation, typed variables (`var speed := 320.0`), snake_case.
- Tuning numbers go in `const` blocks at the top of the file, not buried in the
  middle of a function.

## Godot traps that have already bitten this project

- **Collision shapes must be built in `_init()`, not `_ready()`.** Godot will
  not let you add a collision shape while it is working out physics — which is
  exactly when chests burst open and monsters drop loot. See the note at the top
  of `powerup.gd`. `chest.gd`, `rocket.gd`, `boss_bullet.gd` and `boss.gd` all
  do the same thing.
- **Spawning during a physics step needs `add_child.call_deferred(thing)`**, for
  the same reason.
- Anything that must keep working while the game is paused needs
  `process_mode = Node.PROCESS_MODE_ALWAYS` — that is how `pause_menu.gd` can
  un-pause the game and how the music keeps playing.
- `Sfx` and `InputSetup` are autoloads, so they exist everywhere without being
  imported. Scripts loaded on their own will not see them.

## Git

Remote is `git@github.com:keepbro/tommys-game.git`. Everything goes to `main`.

- **Commit only when asked.** No feature branches — this is a family project
  with no code review, and branching just gets in the way.
- **Do offer.** When something is built and working, ask "want me to save that?"
  so there are points to go back to if the next thing breaks.
- Never push without asking first.
- End commit messages with:
  `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`

## Credits

Made by Tommy, Dad & Claude.
