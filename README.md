# UBC HtC1 - Functional Programming in BSL

## Final Project - Space Invaders

The aim of this project was to build a 'Space Invaders' style game using [BSL](https://docs.racket-lang.org/htdp-langs/beginner.html) (a subset of [Racket](https://racket-lang.org/)), as a 'world' program utilising the `big-bang` function. The specification for the game can be seen below.

![Image showing three states of gameplay in the space invader game. 1 - Game start with small black tank at bottom of screen and blue invaders floating down from the top of the screen. 2 - mid gameplay with the tank firing red missiles up at the invaders to destroy them. 3 - Game over screen where an invader has reached the bottom of the screen.](./space-invader.png)

### How to Play

This program can be run using the [DrRacket](https://download.racket-lang.org/all-versions.html) IDE. After installing, open the project file `1-space-invaders.rkt` and then click the green 'Run' arrow in the IDE. This loads the game and runs all its tests. To then play the game, type the following in the DrRacket terminal:

`> (main (make-game empty empty T0))`

The objective of the game is to destroy the space ships that move down from the top of the screen, by shooting them with missiles from the player-controlled 'Tank' at the bottom. If a space ship reaches the bottom of the screen, you lose!

#### Controls

- `Left / Right Arrow Keys` - Change direction the player 'Tank' is moving in.
- `Spacebar` - Fire a missile from the 'Tank'.

### Program Details

The game runs using the `big-bang` function - this function 'ticks' 28 times per second, and on each tick can will call a series of other functions in order to:

- update the game state (`on-tick`)
- render the new game state to the screen (`to-draw`)
- end the game state when appropriate (`stop-when`)
- handle key presses to allow the player to control the game (`on-key`)

The game state (`Game` data definition) consists of a list of `Invader`, a list of `Missile` and a `Tank`.

- `Tank` contains a Number `x` and an Integer[-1, 1] `dir`, its x-coordinate and the direction it is moving (-1 for moving left, 1 for moving right).
- `Invader` contains three Numbers `x`, `y`, and `dx` - its x and y coords on the screen, and its velocity in the x-direction (negative meaning moving left).
- `Missile` contains two Numbers `x` and `y`, the onscreen coordinates of the missile.

On each tick of the game, the `on-tick` function of `big-bang` calls `update-game` which performs the following steps:

- Updates the list of `Invader` in the `Game` by:
  - Removing any `Invader` that is colliding with a `Missile` (`destroy-invaders`)
  - Moving the remaining `Invaders` according to their current `dx`, and bouncing them off any walls if they collide (`move-invaders`)
  - Randomly spawning a new `Invader` at the top of the screen and adding it to the end of the list of `Invader` (`spawn-invaders`)
- Updates the list of `Missile` in the `Game` by:
  - Removing any `Missile` that is colliding with an `Invader`(`destroy-missiles`)
  - Moving the remaining `Missiles` vertically up the screen, removing any that have already left the top of the screen (`move-missiles`).
- Updates the `Tank` position according to its movement direction (`move-tank`)

Once the `Game` state is updated, the new scene is rendered by `to-draw` calling `render`, which renders the 'Tank`, then 'Missiles' and finally 'Invaders' onto the game background.

The `on-key` function calls `handle-key` to handle any user keyboard input, which:

- checks if the left or right arrow key is pressed, and will update the tanks direction if so (`update-tank-direction`)
- checks if the spacebar is pressed, and if so, spawns a new missile at the current `Tank` position (`add-missile`)

On each tick `stop-when` calls `game-over?` which checks if any `Invader` has reached the bottom of the screen, if this is the case then the game ends.

### Specification

There are many different versions of Space Invaders. For this project, your Space Invaders game should have the following behaviour:

- The tank should move right and left at the bottom of the screen when you press the arrow keys. If you press the left arrow key, it will continue to move left at a constant speed until you press the right arrow key.
- The tank should fire missiles straight up from its current position when you press the space bar.
- The invaders should appear randomly along the top of the screen and move at a 45 degree angle. When they hit a wall they will bounce off and continue at a 45 degree angle in the other direction.
- When an invader reaches the bottom of the screen, the game is over.
