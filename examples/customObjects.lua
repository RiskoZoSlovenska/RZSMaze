--[[
	This example should demonstrate the usage of the Maze:toCustomObjects() function.
]]

local Maze = require("RZSMazeGenerator")


local Room = {} -- Custom class
Room.__index = Room

--[[
	A function that takes precisely these arguments
]]
function Room.new(coordinates, number, connections)
	local self = setmetatable({}, Room)

	self.coordinates = coordinates
	self.number = number

	self._adjacentCells = {}
	self._connectedCells = {}
	self._connections = connections

	return self -- Must return an object
end

--[[
	A function which accepts a list of adjacent Room objects. Do note that the list received will have holes.
]]
function Room:addAdjacents(adjacents)
	self._adjacentCells = adjacents

	-- Make a table of connected Rooms directly
	for direction, isConnected in ipairs(self._connections) do
		if isConnected then
			self._connectedCells[direction] = self._adjacentCells[direction]
		end
	end
end

--[[
	An alternate method of adding adjacent Rooms.
]]
function Room:addAdjacent(direction, adjacent)
	self._adjacentCells[direction] = adjacent

	if self._connections[direction] then
		self._connectedCells[direction] = adjacent
	end
end


local myMaze = Maze.new()
myMaze:generate()
myMaze:createLoops()

local customMaze = myMaze:toCustomObjects(Room.new, Room.addAdjacents)

local customMaze2 = myMaze:toCustomObjects(Room.new, function(room, adjacents) -- Alternate method
	for direction = 1, 4 do -- A 2D maze has 4 possible directions
		room:addAdjacent(direction, adjacents[direction])
	end
end)