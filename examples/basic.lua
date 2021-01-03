--[[
	This example should demonstrate the most basic usage of the maze functions.
]]

local Maze = require("RZSMazeGenerator")

local myMaze = Maze.new() -- Create a blank 5x5 maze
myMaze:generate() -- Generate it
myMaze:createLoops() -- Create some loops
print(myMaze:toString())