--[[
	This example should demonstrate the usage of the maze functions, using
	custom arguments.
]]

local RZSMaze = require("RZSMaze")

local myMaze = RZSMaze.new({10, 10}) -- Create a blank 10x10 maze
myMaze:generate(0.8, {5, 5}) -- Generate a minimum of 80%, starting at the middle cell
myMaze:createLoops(0.2) -- Create some loops, using a 20% chance
print(myMaze:toString("#", ".")) -- Use # and . instead of █ and ░