# RZS Maze

A Lua maze generation library that uses the [Loop-Erased Random Walk](https://bl.ocks.org/mbostock/11357811) algorithm,
also known as Wilson's Algorithm, to create mazes.


## Features

* Generate mazes of virtually any dimensions and sizes
* Supports a custom random function
* Built-in support for generating loops
* Export options to a boolean representation, to fully custom objects or to a string


## Installation

Coming to [LuaRocks](https://luarocks.org) and [lit](https://github.com/luvit/lit) soon.

Can also be found on [Roblox](https://www.roblox.com/library/6189563378/RZSMaze).


## Basic example

```lua
local RZSMaze = require("RZSMaze")

local myMaze = RZSMaze.new({6, 6}) -- Create a blank 6x6 maze
myMaze:generate() -- Generate it
myMaze:createLoops(0.3) -- Create some loops
print(myMaze:toString())
```


## Usage and Docs

The module returns an `RZSMaze` class, which has the following functions:
* `RZSMaze.new(dimensions, randomFunc)` which creates a new blank `RZSMaze`,
* `RZSMaze:generate(completionTolerance, startCoordinates)` which generates a maze,
* `RZSMaze:createLoops(loopChance)` which randomly creates loops in the generated maze,
* `RZSMaze:toSimpleRepresentation()` which creates a simple boolean representation of the maze,
* `RZSMaze:toCustomObjects(constructor, adjacentsInitializer, flipCoordinates)` which lets you export the maze to a custom representation, and lastly,
* `RZSMaze:toString(wallChar, spaceChar)` which returns the maze in a human-readable format.

Despite the code being documented using comments, I haven't gotten around yet to generating any proper docs. For now, an unformatted, hand-written version will have to suffice (sorry!). Or you could, you know, look into the code.

```
RZSMaze.new(dimensions, randomFunc)
		* dimensions - a list of the maze's dimensions, ordered with the least significant dimension first.
			(x, then y, then z and so on) Each dimension must be a positive integer greater than 2, and at least
			2 values must be provided.
			Optional, defaults to {5, 5}.
		* randomFunc - a random number generator function which has an interface identical
			to math.random:
				* If no arguments are provided, returns a decimal in the range [0, 1),
				* If one argument, n, is provided, returns an integer in the range [1, n],
				* If two arguments, n and m, are provided, returns an integer in the range [n, m]
			Additionally, this function can expect that n and m will always be positive integers greater than 0
			Optional, defaults to math.random.
		
		Returns:
		* A blank RZSMaze object.



	RZSMaze:generate(completionTolerance, startCoordinates)
		* completionTolerance - a number between 0 and 1 which dictates the minimum % of the Maze to be generated.
			Optional, defaults to 1.
		* startCoordinates - the coordinates of the initial Cell, least significant coordinate first.
			The amount of coordinates must match the number of dimensions in the maze.
			Optional, defaults to the Cell who's every coordinate is 1.
		
		Returns:
		* Nothing



	RZSMaze:createLoops(loopChance)
		* loopChance - a number between 0 and 1, giving the % chance each Cell will attempt to connect
			to an adjacent one. A value of 1 does not guarantee that every Cell will be connected with every Cell,
			and any value above 0 does not guarantee any new connections being made.
			Optional, defaults to 0.2

		Returns:
		* a list of dictionaries each holding data about a created loop, in the format
			{coordinates = int[], direction = int} where coordinates is a coordinates table of a Cell
			(least significant dimension first) and direction indicates in which direction the connection
			was created.
			
		Returns:
		* Nothing



	RZSMaze:toSimpleRepresentation()
	
		Returns:
		* A 2D boolean array, where true signifies a wall block and false a space.
		
		For example, the below maze would be expressed as:
		███████
		█ █   █
		█ ███ █
		█   █ █
		█ ███ █
		█ █   █
		█ █ ███
		█   █ █
		█ █ █ █
		█ █   █
		███████
			=
		{
			{true, true, true, true, true, true, true, true},
			{true, false, true, false, false, false, true},
			{true, false, true, true, true, false, true},
			{true, false, false, false, true, false, true}
			...
			{true, false, true, false, false, false, true},
			{true, true, true, true, true, true, true, true}
		}



	RZSMaze:toCustomObjects(constructor, adjacentsInitializer, flipCoordinates)
		* constructor - a function which takes the following values:
				* int[] coordinates an array of coordinate values
				* int number a unique number which designates the object
				* boolean[] a list of booleans where a true under index n means that the object is connected
					to another in Direction n.
			This function also has to return a value.
		* adjacentsInitializer - a function which takes a value of the same type as returned by
			the constructor function, as well as an array of similar objects where the index of each object
			represents the direction in which that object is adjacent to the object passed as the first parameter.
		* flipCoordinates - a boolean that determines whether the coordinates passed to the constructor function
			should be flipped. By default, they are given with the most significant coordinate first.
		
		Returns:
		* A nested array of the custom objects



	RZSMaze:toString(wallChar, spaceChar)
		* wallChar - a string, usually a single character, to use to represent filled spaces.
			Optional, defaults to the █ character.
		* spaceChar - a string, usually a single character, to use to represent empty spaces
			Optional, defaults to the ░ character.
		
		Returns:
		* A string in human-readable format which shows the maze
		
		Example:
		
		███████████████████
		█░░░█░░░░░░░░░█░░░█
		███░█████████░█░█░█
		█░░░░░░░░░█░░░█░░░█
		█░███████░█░█░███░█
		█░░░░░░░█░█░█░░░█░█
		███████░███████░█░█
		█░█░░░█░░░░░░░░░░░█
		█░█░█░█░███░█████░█
		█░░░█░░░█░█░█░█░░░█
		█░███░█░█░█░█░███░█
		█░█░░░█░█░░░░░░░░░█
		█░█░█░███░█████░███
		█░░░█░░░█░░░█░█░░░█
		█░█████░█░█░█░███░█
		█░░░░░█░░░█░░░█░█░█
		█░█████░█████░█░█░█
		█░░░░░░░░░░░░░░░█░█
		███████████████████
```