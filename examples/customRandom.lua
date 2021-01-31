--[[
	This example should demonstrate the usage of the optional getRandom parameter.

	For this example, I will use Random, a random number generation library provided
	by Roblox (https://developer.roblox.com/en-us/api-reference/datatype/Random).
]]

local RZSMaze = require("RZSMaze")


local function getRandomGenerator(seed)
	local random = Random.new(seed)

	return function(n, m)
		if n and m then
			return random:NextInteger(n, m)
		elseif n then
			return random:NextInteger(1, n)
		else
			return random:NextNumber()
		end
	end
end


local myRandom1 = getRandomGenerator(123)
local myMaze1 = RZSMaze.new({5, 5}, myRandom1)
myMaze1:generate()
myMaze1:createLoops()
print("Maze 1", myMaze1:toString())


-- This maze will be different from the first one
local myRandom2 = getRandomGenerator(456)
local myMaze2 = RZSMaze.new({5, 5}, myRandom2)
myMaze2:generate()
myMaze2:createLoops()
print("Maze 2", myMaze2:toString())


-- This maze will be identical to the first one
local myRandom3 = getRandomGenerator(123)
local myMaze3 = RZSMaze.new({5, 5}, myRandom3)
myMaze3:generate()
myMaze3:createLoops()
print("Maze 3", myMaze3:toString())