# SHOOTO

**A parkour shooter game by Tommy.**

Run, double jump, wall jump and dash your way through four levels. Shoot the
monsters, break open the chests, beat the boss, and escape through the portal
before it all starts again — harder.

Made in [Godot 4.6](https://godotengine.org) with GDScript.

## The game has no pictures and no sound files

Every single thing you see and hear is made out of code.

- The knight, the goblins, the slimes, the bats, the boss — all drawn line by
  line with `_draw()`.
- Every sound effect and the whole background tune are built out of maths in
  `scripts/sfx.gd`. Sound is just a speaker moving in and out very fast, so the
  game works out the numbers for how to move it.

That is why the whole game is about 4,500 lines of code and nothing else.

## How to play

| Key | What it does |
|---|---|
| **A / D** or **arrow keys** | Run |
| **Space** or **W** | Jump — press again in the air to **double jump** |
| **Shift** | Dash |
| **Mouse** | Aim |
| **Left click** | Shoot |
| **1 – 5** | Use whatever is in that bag slot |
| **P** or **Esc** | Pause |

Jump at a wall and hold on to slide down it, then jump again to kick off. Guns
kick you backwards when you fire, so a big gun can throw you across a gap.

## What is in it

**Four levels** — Green Hills, Sky Towers, Ice Caves and Lava Fortress. Finish
the last one and it loops back to the first, but tougher.

**Four monsters**

- **Goblin** — red, runs along platforms and chases you
- **Slime** — green blob, hops about, squishes when it lands
- **Bat** — purple, flies straight at you
- **Brute** — big and armoured, slow, takes three shots

**A boss on every level.** It stomps after you, throws fireballs, and leaps over
holes. It has the key to the exit, so you cannot leave until you beat it. Below
half health it goes red and gets angry.

**Eight guns** — pistol, shotgun, machine gun, SMG, AR, AK, rocket launcher and
laser. The laser shoots straight through monsters. The rocket blows up
everything nearby. Run out of ammo and you drop back to the trusty pistol.

**Power-ups** — hearts and medkits to heal, plus rapid fire, triple shot and
super speed. Pick things up and they go in your bag; press 1–5 to use them.

**Chests** — shoot one three times and it bursts open with loot.

**Four teams** — Red, Blue, Green and Yellow. Pick one on the TEAM screen and
your knight wears that armour for the whole game.

## Versus mode

Two players, one keyboard, one screen, one arena. Last knight standing wins.

| | Player 1 | Player 2 |
|---|---|---|
| Run | **A / D** | **← / →** |
| Jump | **W** or **Space** | **↑** |
| Dash | **Shift** | **Ctrl** |
| Aim | **Mouse** | aims at Player 1 automatically |
| Shoot | **Left click** | **Enter** |

New weapons and medkits drop into the arena every few seconds, so get to them
first. Press **Enter** to play again, **Esc** for the title screen.

## Running the game

You need [Godot 4.6](https://godotengine.org/download) or newer.

```bash
godot           # play
godot -e        # open it in the Godot editor
```

Or open the Godot editor, click **Import**, and pick the `project.godot` file.

## How it is put together

```
scenes/     the handful of scene files — most things are built in code instead
scripts/    all the game code
  main.gd       the campaign, with all four levels written as data
  player.gd     moving, shooting, and drawing the knight
  enemy.gd      all four monsters
  boss.gd       the boss
  versus.gd     two-player mode
  sfx.gd        every sound and the music, made from maths
  menu.gd       the title screen and menus
```

There is a longer tour in [CLAUDE.md](CLAUDE.md).

## Credits

Made by **Tommy**, **Dad** and **Claude**.
