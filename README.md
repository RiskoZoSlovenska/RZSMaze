# RZS Maze Generation

A Lua maze generation library that uses the Loop-Erased Random Walk algorithm,
also known as Wilson's Algorithm, to create mazes.

This generator supports generating mazes in virtually *any* number of dimensions, not just 2 or 3, optionally with a custom randomization function.

## Usage

The module returns an `RZSMaze` class, which has the following functions (arguments not shown):
* `RZSMaze.new()` which creates a new blank `RZSMaze`,
* `RZSMaze:generate()` which generates a maze,
* `RZSMaze:createLoops()` which randomly creates loops in the generated maze,
* `RZSMaze:toSimpleRepresentation()` which creates a simple boolean representation of the maze,
* `RZSMaze:toCustomObjects()` which lets you export the maze to a custom representation, and lastly,
* `RZSMaze:toString()` which returns the maze in a human-readable format.

Unfortunately, I do not have any formal docs besides code comments (yet), but I've tried my best to make said comments comprehensive.