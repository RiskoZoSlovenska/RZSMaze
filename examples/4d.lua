--[[
	The maze generator can generate mazes that have theoretically any number of dimensions!
]]

local RZSMaze = require("RZSMaze")

local myMaze = RZSMaze.new({5, 5, 5, 5}) -- Create a 5x5x5x5 maze... yes, even the 4th (and above!) dimension is supported!
myMaze:generate()
myMaze:createLoops() -- Everything still works as before even with more dimensions
print(myMaze:toString()) -- Including :toSimpleRepresentation() and even :toString()! The output might look a bit confusing at first though...