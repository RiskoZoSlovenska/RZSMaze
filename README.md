# RZS Maze Generation

A Lua maze generation library that uses the [Loop-Erased Random Walk](https://bl.ocks.org/mbostock/11357811) algorithm,
also known as Wilson's Algorithm, to create mazes.


## Features

* Generate mazes of virtually any dimensions and sizes
* Support a custom random function
* Built-in support for generating loops
* Export options to a boolean representation, to fully custom objects or to a string


## Installation

Coming to [LuaRocks](https://luarocks.org) and [lit](https://github.com/luvit/lit) soon.


## Basic example

```lua
local RZSMaze = require("RZSMaze")

local myMaze = RZSMaze.new() -- Create a blank 5x5 maze
myMaze:generate() -- Generate it
myMaze:createLoops() -- Create some loops
print(myMaze:toString())
```


## Usage

The module returns an `RZSMaze` class, which has the following functions (arguments not shown):
* `RZSMaze.new()` which creates a new blank `RZSMaze`,
* `RZSMaze:generate()` which generates a maze,
* `RZSMaze:createLoops()` which randomly creates loops in the generated maze,
* `RZSMaze:toSimpleRepresentation()` which creates a simple boolean representation of the maze,
* `RZSMaze:toCustomObjects()` which lets you export the maze to a custom representation, and lastly,
* `RZSMaze:toString()` which returns the maze in a human-readable format.

Unfortunately, I do not have any formal docs besides code comments (yet), but I've tried my best to make said comments comprehensive.