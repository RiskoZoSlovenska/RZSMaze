--[[
	This example should demonstrate usage of the Maze:toSimpleRepresentation() function.
]]

local Maze = require("RZSMazeGenerator")


local function placeBlock(x, y)
	-- Assume that this function creates a physical block in some virtual environment.
end


local myMaze = Maze.new({6, 6})
myMaze:generate()
myMaze:createLoops()
for y, row in ipairs(myMaze:toSimpleRepresentation()) do
	for x, isBlock in ipairs(row) do
		if isBlock then
			placeBlock(x, y)
		end
	end
end