# RZS Maze

A Lua maze generation library that uses the [Loop-Erased Random Walk](https://bl.ocks.org/mbostock/11357811) algorithm,
also known as Wilson's Algorithm, to create mazes.


## Features

* Generate mazes of virtually any dimensions and sizes
* Supports a custom random function
* Built-in support for generating loops
* Export options to a boolean representation, to fully custom objects or to a string


## Installation

Get it from [LuaRocks](https://luarocks.org):
```
luarocks install RZSMaze
```

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

#### First of all, two important notes:
1.	Tables are used to represent coordinates (and dimensions), **where the most significant coordinate is first**.
	In other words, coordinates/dimensions in the form (x, y, z) would be represented as {z, y, x}.

2.	Directions are represented with positive integers, where an odd number is a +1 shift and an even number is a -1 shift in the *n<sup>th</sup>* least significant coordinate, where *n* is given by diving the direction number by 2 and rounding up. To illustrate:

	| Direction # | Coordinate Shift |
	|-------------|------------------|
	| 1           | x + 1            |
	| 2           | x - 1            |
	| 3           | y + 1            |
	| 4           | y - 1            |
	| 5           | z + 1            |
	etc

<br>

Despite the code being documented using comments, I haven't gotten around yet to generating any proper docs. For now, an unformatted, hand-written version will have to suffice (sorry!). Or you could, you know, look into the code.

<br>

The module returns an `RZSMaze` class, which has the following functions:
* `RZSMaze.new(dimensions, randomFunc)` which creates a new blank `RZSMaze`,
* `RZSMaze:generate(completionTolerance, startCoordinates)` which generates a maze,
* `RZSMaze:createLoops(loopPercentage, maxAttempts)` which randomly creates loops in the generated maze,
* `RZSMaze:toSimpleRepresentation()` which creates a simple boolean representation of the maze,
* `RZSMaze:toCustomObjects(constructor, adjacentsInitializer)` which lets you export the maze to a custom representation, and lastly,
* `RZSMaze:toString(wallChar, spaceChar)` which returns the maze in a human-readable format.

```
RZSMaze.new(dimensions, randomFunc)
	* dimensions - a list of the maze's dimensions. Each dimension must be a positive integer greater than 2,
		and at least 2 values must be provided.
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
	* startCoordinates - the coordinates of the initial cell. The amount of coordinates must match the number
		of dimensions in the maze.
		Optional, defaults to the coordinates of the top-left-most cell ({1, 1, ...}).
	
	Returns:
	* Nothing



RZSMaze:createLoops(loopPercentage, maxAttempts)
	* loopPercentage - a number between 0 and 1, giving the % of cells that will attempt to make an extra
		connection to an adjacent cell. In some cases, such as this number being quite high, the desired
		percentage will not be achieved.
		Recommended to be set to numbers less than 0.4.
		Optional, defaults to 0.2
	* maxAttempts - the maximum number of attempts to take when attempting to create an extra connection.
		Attempts may fail when there are already many connections.
		Optional, defaults to 5.

	Returns:
	* a list of dictionaries each holding data about a created loop, in the format
		{coordinates = int[], direction = int} where coordinates is a coordinates table of a Cell
		and direction indicates in which direction the connection was created.



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



RZSMaze:toCustomObjects(constructor, adjacentsInitializer)
	* constructor - a function which takes the following values:
			* int[] coordinates an array of coordinate values
			* int number a unique number which designates the object
			* boolean[] a list of booleans where a true under index n means that the object is connected
				to another in direction n.
		This function also has to return some value.
	* adjacentsInitializer - a function which takes a value of the same type as returned by
		the constructor function, as well as an array of similar objects where the index of each object
		represents the direction in which that object is adjacent to the object passed as the first parameter.
	
	Returns:
	* A nested array of the custom objects



RZSMaze:toString(wallChar, spaceChar)
	* wallChar - a string, usually a single character, to use to represent filled spaces.
		Optional, defaults to the █ character.
	* spaceChar - a string, usually a single character, to use to represent empty spaces
		Optional, defaults to the ░ character.
	
	Returns:
	* A string in human-readable format which displays the maze
	
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
