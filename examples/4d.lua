--[[
	The maze generator can generate mazes that have theoretically any number of dimensions!
]]

local Maze = require("RZSMazeGenerator")

local myMaze = Maze.new({5, 5, 5, 5}) -- Create a 5x5x5x5 maze... yes, even the 4th (amd above!) dimension is supported!
myMaze:generate()
myMaze:createLoops() -- Everything still works as before even with more dimensions
print(myMaze:toString()) -- Including :toSimpleRepresentation() and even :toString()! The output might be a bit confusing at first though...