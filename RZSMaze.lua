--[[--
	@module RZSMaze
	@version 3.3
	@author RiskoZoSlovenska
	@date Feb 2021
	@license MIT

	A Lua maze generation library that uses the Loop-Erased Random Walk algorithm,
	also known as Wilson's Algorithm, to create mazes.

	Disclaimer: This algorithm is a minimal spanning tree algorithm, and I do not understand the math behind it;
	I know how it works, not why.

	The algorithm starts off with an empty set of cells, where every cell knows its neighbors. One cell is chosen
	to be the starting point, and it is added to the set of cells that belong to the maze. Then, the algorithm
	begins a walk - it moves from the first cell to a random adjacent, until it walks into either a cell that it
	visited before in the walk or a cell that belongs to the maze. If it comes upon a cell it visited in that walk,
	it erases the loop by retracing its steps back to that cell. If it comes upon a cell that is already part
	of the maze, all the cells that were visited in the walk are converted to maze cells and a new walk begins,
	starting from a random cell that belongs to the maze.

	The following link demonstrates the algorithm nicely:
		https://bl.ocks.org/mbostock/11357811

	Do note that this means that purely theoretically, the algorithm may never finish.
]]

local table, math, string = table, math, string
local tostring = tostring
local type, assert = type, assert
local setmetatable = setmetatable


--[[--
	Returns the opposite direction of a direction.

	@param int direction the direction to get the opposite of
	@return int the opposite direction of the one supplied
]]
local function getOppositeDirection(direction)
	return direction + (direction % 2 == 0 and -1 or 1) -- If is even, subtract 1, else add 1
end

--[[--
	Creates a table of a certain size initialized with a value.

	@param int size the size of the table to create
	@param any defaultValue the value to initialize the table with

	@return any[]
]]
local function createTable(size, defaultValue)
	local tbl = {}

	for index = 1, size do
		tbl[index] = defaultValue
	end

	return tbl
end

--[[--
	Creates a shallow copy of an array-like table. Does not copy and dictionary keys.

	@param any[] tbl
	@return any[]
]]
local function copyTable(tbl)
	local copy = {}
	for index = 1, #tbl do
		copy[index] = tbl[index]
	end

	return copy
end

--[[--
	Creates a copy of a table where every element has been multiplied by a number.

	@param number[] tbl the table of numbers to multiply
	@param number num the number to multiply each element by

	@return number[]
]]
local function multiplyTable(tbl, num)
	local multiplied = {}

	for index = 1, #tbl do
		multiplied[index] = tbl[index] * num
	end

	return multiplied
end

--[[--
	Creates a copy of a table where every element has been increased by a number.

	@param number[] tbl the table of numbers to add to
	@param number num the number to add each to element

	@return number[]
]]
local function addTable(tbl, num)
	local added = {}

	for index = 1, #tbl do
		added[index] = tbl[index] + num
	end

	return added
end


--[[--
	Used to validify user input.

	@param any[] coordinates the table to validify

	@return boolean whether a coordinate table is valid (2+ values, all values are integers)
	@return string|nil an error message if the coordinates are not valid, or nil
]]
local function validifyCoordinates(coordinates)
	local numOfCoordinates = #coordinates
	if numOfCoordinates < 2 then
		return false, "Too few coordinates provided (expected 2 or more, got " .. numOfCoordinates .. ")!"
	end

	for index = 1, numOfCoordinates do
		local coordinate = coordinates[index]
		if type(coordinate) ~= "number" or math.floor(coordinate) ~= coordinate then
			return false, "Invalid coordinate (" .. tostring(coordinate) .. ")!"
		end
	end

	return true, nil
end

--[[--
	Used to validify user input.

	@param any[] dimensions the table to validify

	@return boolean whether a dimensions table is valid (2+ values, all value are integers >= 2)
	@return string|nil an error message if the coordinates are not valid, or nil
]]
local function validifyDimensions(dimensions)
	local numOfDimensions = #dimensions
	if numOfDimensions < 2 then
		return false, "Too few dimensions provided (expected 2 or more, got " .. numOfDimensions .. ")!"
	end

	for index = 1, numOfDimensions do
		local dimension = dimensions[index]
		if type(dimension) ~= "number" or math.floor(dimension) ~= dimension or dimension < 2 then
			return false, "Invalid dimension (" .. tostring(dimension) .. ")!"
		end
	end

	return true, nil
end

--[[
	Validifies the type of a value, printing a neat-ish error message.

	@param string name the name of the value, for error-printing purposes
	@param any value the value to validify
	@param string expectedType a string as one that can be returned by type() that
		the value should have
	@param any|nil default a default value, which is returned if it is not nil
		and the value is
	@param function... any extra validation functions which should take the value as a parameter
		and should return a success boolean and an error message

	@return any the passed value if it is valid
	@throws Invalid argument exception
]]
local function validifyInput(name, value, expectedType, default, ...)
	if value == nil and default ~= nil then
		return default
	end

	local actualType = type(value)
	assert(actualType == expectedType, string.format(
		"Invalid type to argument %s (expected %s, got %s)", name, expectedType, actualType
	))

	local validators = {...}
	for validatorIndex = 1, #validators do
		assert(validators[validatorIndex](value))
	end

	return value
end


--[[--
	Returns a set of coordinates that's between two other coordinates.

	The resulting coordinates may have decimals. This function is used solely in @{Maze:getSimpleRepresentation()}
	where this case is handled (by multiplying by 2).

	@param int[] coordinates1
	@param int[] coordinates2

	@return number[]
]]
local function getMiddleCoordinates(coordinates1, coordinates2)
	local middleCoordinates = {}

	for index = 1, #coordinates1 do
		middleCoordinates[index] = (coordinates1[index] + coordinates2[index]) / 2 -- Average
	end

	return middleCoordinates
end

--[[--
	Creates a new multi-dimensional table initialized with a custom value.

	@param int[] dimensions a list of sizes in different dimensions, most significant first. The length of
		this table also determines the nesting level
	@param any|function core either a default value to be used to initialize, or a function
		which is called for every element with the element's coordinates as an argument
		and should return the value to be placed at that position.
	@param[opt=nil] layerProcessFunction function if supplied, a function through which each subtable is passed before
		it is returned. This function takes an any[] layer and an int depth as arguments and should
		have one return value of the same type as objects the input array holds.

	@return table the constructed table
]]
local function constructMultiDTable(dimensions, core, layerProcessFunction)
	local isCoreFunction = type(core) == "function"

	--[[--
		Actual construct function which builds up the coordinates.
	]]
	local function _construct(coordinates)
		local depth = #coordinates + 1
		if depth > #dimensions then -- We have all the coordinates required, return an actual element
			if isCoreFunction then
				return core(coordinates)
			else
				return core
			end
		end

		local layer = {} -- Main table on this level
		for coordinate = 1, dimensions[depth] do
			local newCoordinates = copyTable(coordinates) -- Don't modify the original
			newCoordinates[depth] = coordinate -- Add to the coordinates list

			layer[coordinate] = _construct(newCoordinates) -- Fill by recursion
		end

		return layerProcessFunction and layerProcessFunction(layer, depth) or layer
	end

	return _construct({}) -- Start with no coordinates
end

--[[--
	Returns an element of a multi-dimensional (nested) table according to the element's coordinates.

	If the supplied coordinates are out of bounds, returns nil.

	@param table tbl the multi-dimensional table
	@param int[] indexes the coordinates of the element

	@return any the retrieved value, or nil
]]
local function getElementInMultiDTable(tbl, indexes)
	for indexIndex = 1, #indexes do
		if tbl == nil then return nil end
		tbl = tbl[indexes[indexIndex]]
	end

	return tbl
end

--[[--
	Sets an element of a multi-dimensional (nested) table according to the element's coordinates.

	Unlike @{getElementInMultiDTable()}, will error of the coordinates are out of bounds.

	@param table tbl the multi-dimensional table
	@param int[] indexes the coordinates of the element
	@param any value the value to set
]]
local function setElementInMultiDTable(tbl, indexes, value)
	local len = #indexes

	for indexIndex = 1, len - 1 do
		tbl = tbl[indexes[indexIndex]]
	end

	tbl[indexes[len]] = value
end



--- Describes the status of a Cell
local CellStatus = {
	None = 1,
	Walk = 2,
	Maze = 3,
}

--[[--
	@class Cell

	A class that represents a singular cell/room/node of a maze and holds
	data about itself and its neighbors.
]]
local Cell = {}
Cell.__index = Cell

--[[--
	Creates a new blank Cell at the supplied coordinates. This Cell does not have a list adjacent cells initialized,
	and @{Cell:initAdjacent} needs to be called on it before this Cell is used.

	@param int num this Cell's number. Used only for identification
	@param int[] coordinates this Cell's coordinates

	@return Cell
]]
function Cell.new(num, coordinates)
	local self = setmetatable({}, Cell)

	self._adjacentCells = nil --- See @{Cell:initAdjacent}
	self._connections = {}

	self._enterDirection = nil
	self._leaveDirection = nil

	self.status = CellStatus.None

	self.number = num
	self.coordinates = coordinates

	self._numOfDimensions = #self.coordinates --- amount of dimensions

	return self
end

--[[--
	@return string a string describing this Cell
]]
function Cell:__tostring()
	return string.format("RZSMazeCell (#%d %s)", self.number, table.concat(self.coordinates, ", "))
end

--[[--
	Sets the internal adjacents table.

	@param Cell[] adjacentCells a table in which values are Cell objects/nil and each
		object's index indicates its adjacency direction
]]
function Cell:initAdjacent(adjacentCells)
	self._adjacentCells = adjacentCells
end

--[[--
	Returns a Cell object that's adjacent to this one in a certain direction, if it exists.

	@param int direction
	@return Cell|nil
]]
function Cell:getAdjacentInDirection(direction)
	return self._adjacentCells[direction]
end

--[[--
	@return int[] a list of the numbers of adjacent Cells, indexed by the adjacency direction
]]
function Cell:getAdjacentCellsNumbers()
	local adjacentCellNumbers = {}

	for direction = 1, self._numOfDimensions * 2 do
		local adjacent = self._adjacentCells[direction]
		if adjacent then
			adjacentCellNumbers[direction] = adjacent.number
		end
	end

	return adjacentCellNumbers
end

--[[--
	Returns a table holding boolean values, where a value of true under index n implies that the
	Cell is connected to another in direction n.

	@return boolean[]
]]
function Cell:getConnections()
	local connections = {}
	for direction = 1, self._numOfDimensions * 2 do
		connections[direction] = self._connections[direction] == true -- Convert any nil to a false
	end

	return connections
end

--[[--
	@return Cell[] a list of Cells which are connected to this one.
]]
function Cell:getConnectedCells()
	local connectedCells = {}

	for direction = 1, self._numOfDimensions * 2 do
		if self._connections[direction] then
			table.insert(connectedCells, self._adjacentCells[direction])
		end
	end

	return connectedCells
end

--[[--
	Returns whether this Cell is connected to another Cell in a certain direction.

	@param int direction
	@return boolean
]]
function Cell:getIsConnectedInDirection(direction)
	return self._connections[direction] == true
end

--[[--
	@return int[] a list of all the directions in which there is an adjacent Cell,
		excluding the direction this Cell was entered from by the walk.
]]
function Cell:getPossibleWalkDirections()
	local possibleWalkDirections = {}
	local nextIndex = 1 -- Speed; this function is called often during generation

	for direction = 1, self._numOfDimensions * 2 do
		if self._adjacentCells[direction] and direction ~= self._enterDirection then
			possibleWalkDirections[nextIndex] = direction
			nextIndex = nextIndex + 1
		end
	end

	return possibleWalkDirections
end

--[[--
	@return int[] a list of all the directions in which there is an adjacent Cell,
		excluding the directions where this Cell is already connected to other Cells.
]]
function Cell:getPossibleLoopDirections()
	local possibleLoopDirections = {}

	for direction = 1, self._numOfDimensions * 2 do
		if self._adjacentCells[direction] and not self._connections[direction] then
			table.insert(possibleLoopDirections, direction)
		end
	end

	return possibleLoopDirections
end


--[[--
	Creates a connection in a direction.
	This connection is one-way (it is not created from the adjacent Cell to this one).

	@param int direction the direction in which to create the connection
]]
function Cell:connectDirection(direction)
	self._connections[direction] = true
end

--[[--
	Creates a connection (@{Cell:connectDirection()}) in a direction and remembers it as the
	direction in which the walk left this cell.

	@param int direction
]]
function Cell:continueWalkInDirection(direction)
	self:connectDirection(direction)
	self._leaveDirection = direction
end

--[[--
	Creates a connection (@{Cell:connectDirection()}) in the inverse of a direction and remembers it as the
	direction in which the walk entered this cell. Changes the Cell's status to Walk.

	@param int direction the direction in which the walk was going when it entered the Cell
]]
function Cell:joinWalkInDirection(direction)
	local enteredFromDirection = getOppositeDirection(direction)
	self:connectDirection(enteredFromDirection)
	self._enterDirection = enteredFromDirection

	self.status = CellStatus.Walk
end

--[[--
	Disconnects from a Cell in the direction that the walk left this Cell.
	Used when a loop is erased at this Cell.
]]
function Cell:disconnectWalkedIntoCell()
	self._connections[self._leaveDirection] = nil
end

--[[--
	Resets the Cell's connections and anything else related to a walk.
	Used for when this Cell is loop-erased.
]]
function Cell:leaveWalk()
	self._connections = {}
	self._enterDirection = nil
	self._leaveDirection = nil

	self.status = CellStatus.None
end

--[[--
	Sets the Cell's status to Maze and discards away any unnecessary data.
]]
function Cell:joinMaze()
	self._enterDirection = nil
	self._leaveDirection = nil

	self.status = CellStatus.Maze
end




--[[--
	A Maze object which represents a single generation of a random maze. Handles generating self
	and then converting self to other representations.
]]
local Maze = {}
Maze.__index = Maze

--[[--
	Creates a new blank, un-generated Maze of a certain size, optionally with a custom random generator.

	@param[opt={5, 5}] int[] dimensions a list of the maze's dimensions. Each dimension must be a positive integer greater than 2, and at
		least 2 values must be provided
	@param[opt=@{math.random}] function getRandom a random number generator function which has an interface identical
		to @{math.random}:
			* If no arguments are provided, returns a decimal in the range [0, 1),
			* If one argument, n, is provided, returns an integer in the range [1, n],
			* If two arguments, n and m, are provided, returns an integer in the range [n, m]
		Additionally, this function can expect that n and m will always be positive integers greater than 0

	@return Maze the un-generated maze
]]
function Maze.new(dimensions, getRandom)
	local self = setmetatable({}, Maze)

	self.dimensions = copyTable(validifyInput("dimensions", dimensions, "table", {5, 5}, validifyDimensions))
	self._numOfDimensions = #self.dimensions

	self._random = validifyInput("getRandom", getRandom, "function", math.random)

	self._maze = nil
	do
		local cellNum = 0

		self._maze = constructMultiDTable(
			self.dimensions,
			function(coordinates)
				cellNum = cellNum + 1
				return Cell.new(cellNum, coordinates)
			end
		)
	end
	self._mazeCells = {}
	self._isGenerated = false

	-- Init cell adjacents
	for coordinates in self:_iterateCoordinates() do
		local cell = self:_getCell(coordinates)
		local adjacents = {}

		-- For each dimension, get the two Cells that are +1 or -1 in that dimension
		-- Really, it doesn't matter which direction means which dimension, only that opposites match
		for dimensionIndex = self._numOfDimensions, 1, -1 do -- Modify the least significant dimension first
			local adjacentCoordinates = copyTable(coordinates)
			adjacentCoordinates[dimensionIndex] = adjacentCoordinates[dimensionIndex] + 1 -- One unit forward in one dimension

			local oppAdjacentCoordinates = copyTable(coordinates)
			oppAdjacentCoordinates[dimensionIndex] = oppAdjacentCoordinates[dimensionIndex] - 1 -- Likewise, one unit back

			local direction = (self._numOfDimensions - dimensionIndex + 1) * 2
			adjacents[direction - 1] = self:_getCell(adjacentCoordinates)
			adjacents[direction    ] = self:_getCell(oppAdjacentCoordinates)
		end


		cell:initAdjacent(adjacents)
	end

	return self
end

--[[--
	@return string a string describing the maze
]]
function Maze:__tostring()
	return string.format("RZSMaze (%s, %sgenerated)", table.concat(self.dimensions, "x"), self._isGenerated and "" or "un")
end


--[[--
	Returns a random element from a list.

	@param any[] list
	@return any a random value picked from the list
]]
function Maze:_getRandomOfList(list)
	return list[self._random(#list)]
end

--[[--
	Returns a Cell at coordinates in the maze, if it exists.

	Wrapper for @{getElementInMultiDTable()}

	@param int[] coordinates the coordinates of the Cell to get
	@return Cell|nil the Cell found at the coordinate, or nil if the coordinates are out of bounds
]]
function Maze:_getCell(coordinates)
	return getElementInMultiDTable(self._maze, coordinates)
end

--[[--
	Returns an iterator which iterates over each Cell's coordinates

	The iterator returns an int[] coordinates table.

	@return function
]]
function Maze:_iterateCoordinates()
	local coordinates = createTable(self._numOfDimensions, 1)
	coordinates[self._numOfDimensions] = 0 -- Last one needs to be zero

	return function()
		coordinates[self._numOfDimensions] = coordinates[self._numOfDimensions] + 1 -- Increase the least significant coordinate...

		for coordinateIndex = self._numOfDimensions, 1, -1 do -- ...and shift any exceeded values to more significant coordinates...
			if coordinates[coordinateIndex] > self.dimensions[coordinateIndex] then
				if coordinateIndex == 1 then return nil end -- ...until the most significant coordinate is exceeded.

				coordinates[coordinateIndex] = 1
				coordinates[coordinateIndex - 1] = coordinates[coordinateIndex - 1] + 1
			else
				return copyTable(coordinates) -- Copy, as this table may be modified
			end
		end
	end
end


--[[--
	Loop-erases Cells from the walk stack until a certain Cell is reached.

	Every Cell removed it erased from the stack and has its @{Cell:leaveWalk()} function invoked.

	@param Cell[] walkCells the stack from which to erase Cells
	@param Cell intersectionCell the Cell at which to stop removing. This cell will not be removed
]]
function Maze:_eraseLoop(walkCells, intersectionCell)
	local removeIndex = #walkCells

	while true do
		local toRemove = walkCells[removeIndex]
		if toRemove == intersectionCell then return end

		toRemove:leaveWalk()
		walkCells[removeIndex] = nil

		removeIndex = removeIndex - 1
	end
end

--[[--
	Randomly walks from Cell to Cell, erasing loops if any are created, until it walks into a Cell which
	is already part of the Maze.

	@return Cell[] a list of Cell visited during the walk until the walk ended
]]
function Maze:_doWalk()
	local walkCells = {}

	local curCell = self:_getRandomOfList(self._mazeCells)
	while true do
		local walkDirection = self:_getRandomOfList(curCell:getPossibleWalkDirections())
		local nextCell = curCell:getAdjacentInDirection(walkDirection)

		if nextCell.status == CellStatus.Walk then
			-- We ran into the walk
			self:_eraseLoop(walkCells, nextCell)
			nextCell:disconnectWalkedIntoCell()

		elseif nextCell.status == CellStatus.Maze then
			-- We ran into the maze
			return walkCells

		else
			-- Contine walking
			curCell:continueWalkInDirection(walkDirection)
			nextCell:joinWalkInDirection(walkDirection)
			table.insert(walkCells, nextCell)
		end

		curCell = nextCell
	end
end

--[[--
	Sets the statuses of Cells to Maze and insert them into the mazeCells table.

	@param Cell[] walkCells the Cells to convert and save
]]
function Maze:_convertWalkToMaze(walkCells)
	for cellIndex = 1, #walkCells do
		local cell = walkCells[cellIndex]
		cell:joinMaze()
		table.insert(self._mazeCells, cell)
	end
end


--[[--
	Generates the Maze, optionally with some parameters. Has no effect if the Maze is already generated.

	@param[opt=1] number completionTolerance a number between 0 and 1 which dictates the minimum %
		of the Maze to be generated
	@param[opt={1, 1, ...}] int[] startCoordinates the coordinates of the initial Cell.
		The amount of coordinates must match the number of dimensions in the maze.
		Defaults to the Cell who's every coordinate is 1

	@throws Maze already generated exception
]]
function Maze:generate(completionTolerance, startCoordinates)
	assert(not self._isGenerated, "Maze has already been generated!")

	do
		local startCell = self:_getCell(
			validifyInput("startCoordinates", startCoordinates, "table", createTable(self._numOfDimensions, 1), validifyCoordinates)
		)
		assert(startCell and type(startCell) == "table" and startCell.number, "Invalid coordinates (Coordinates out of bounds)!") -- Meh

		self._isGenerated = true
		startCell:joinMaze()
		self._mazeCells[1] = startCell
	end


	local completionThreshold = math.min(validifyInput("completionTolerance", completionTolerance, "number", 1), 1) -- No more than 1
	for dimensionIndex = 1, self._numOfDimensions do
		completionThreshold = completionThreshold * self.dimensions[dimensionIndex]
	end

	-- This is the main loop: keep making walks until the minimum threshold is reached.
	repeat
		self:_convertWalkToMaze(self:_doWalk())

	until #self._mazeCells >= completionThreshold
end

--[[--
	Randomly creates connections between adjacent Cells, trying to reach a set percentage of cells.

	@param[opt=0.2] number loopPercentage a number between 0 and 1, giving the % of cells that will attempt to make an extra connection
		to an adjacent cell. In some cases, such as this number being quite high, the desired percentage will not be achieved.
		Recommended to be set to numbers less than 0.4
	@param[opt=5] number maxAttempts the maximum number of attempts to take when attempting to create an extra connection. Attempts
		may fail when there are already many connections

	@return table[] a list of dictionaries each holding data about a created loop, in the format
		{coordinates = int[], direction = int} where coordinates is a coordinates table of a Cell
		and direction indicates in which direction the connection was created
]]
function Maze:createLoops(loopPercentage, maxAttempts)
	loopPercentage = validifyInput("loopPercentage", loopPercentage, "number", 0.2)
	maxAttempts = validifyInput("maxAttempts", maxAttempts, "number", 5)

	local loops = {}

	for _ = 1, math.ceil(#self._mazeCells * loopPercentage) do
		local attempts = 0;

		while attempts < maxAttempts do
			-- Choose random Cell and try to create a connection in a walled direction
			local cell = self:_getRandomOfList(self._mazeCells)

			local possibleLoopDirections = cell:getPossibleLoopDirections()
			if #possibleLoopDirections > 0 then -- This is pretty much the only case we have to handle

				local loopDirection = self:_getRandomOfList(possibleLoopDirections)
				local adjacentCell = cell:getAdjacentInDirection(loopDirection)

				cell:connectDirection(loopDirection)
				adjacentCell:connectDirection(getOppositeDirection(loopDirection))

				table.insert(loops, {
					coordinates = copyTable(cell.coordinates),
					direction = loopDirection
				})
				break -- We can break the attempts loop
			end

			attempts = attempts + 1
		end
	end

	return loops
end


--[[--
	Returns a multi-dimensional array of booleans, where each boolean represents a space that is
	either filled or not.

	For example, the following 2D maze
	███████
	█░░░█░█
	███░█░█
	█░█░█░█
	█░█░█░█
	█░░░░░█
	███████
	would be returned as
	{
		{true, true,  true,  true,  true,  true,  true},
		{true, false, false, false, true,  false, true},
		{true, true,  true,  false, true,  false, true},
		{true, false, true,  false, true,  false, true},
		{true, false, true,  false, true,  false, true},
		{true, false, false, false, false, false, true},
		{true, true,  true,  true,  true,  true,  true},
	}

	@return table
]]
function Maze:toSimpleRepresentation()
	local size = addTable(multiplyTable(self.dimensions, 2), 1)
	local simple = constructMultiDTable(size, true)

	for coordinates in self:_iterateCoordinates() do
		local cell = self:_getCell(coordinates)

		-- For every connected adjacent Cell, get the space between that Cell and this Cell and set it to false.
		local connectedCells = cell:getConnectedCells()
		for connectedIndex = 1, #connectedCells do
			setElementInMultiDTable(
				simple,
				multiplyTable(getMiddleCoordinates(coordinates, connectedCells[connectedIndex].coordinates), 2),
				false
			)
		end

		setElementInMultiDTable(simple, multiplyTable(coordinates, 2), false) -- Self
	end

	return simple, size
end

--[[--
	Returns a multi-dimensional array of custom objects, created by a passed constructor function.

	@param function constructor a function which takes the following values:
		* int[] coordinates an array of coordinate values
		* int number a unique number which designates the object
		* boolean[] a list of booleans where a true under index n means that the object is connected
			to another in Direction n.
		This function also has to return a value
	@param function adjacentsInitializer a function which takes a value of the same type as returned by
		the constructor function, as well as an array of similar objects where the index of each object
		represents the direction in which that object is adjacent to the object passed as the first parameter

	@return table a nested array of the custom objects
]]
function Maze:toCustomObjects(constructor, adjacentsInitializer)
	constructor = validifyInput("constructor", constructor, "function")
	adjacentsInitializer = validifyInput("adjacentsInitializer", adjacentsInitializer, "function")

	local customObjects = {}
	local objectsCoordinates = {} -- We have to remember coordinates manually :c

	local customMaze = constructMultiDTable(
		self.dimensions,
		function(coordinates)
			local cell = self:_getCell(coordinates)

			local object = constructor(
				copyTable(cell.coordinates),
				cell.number,
				cell:getConnections()
				-- TODO: Support for custom extra ... args
			)

			customObjects[cell.number] = object
			objectsCoordinates[object] = cell.coordinates
			return object
		end
	)

	for objectIndex = 1, #customObjects do
		local object = customObjects[objectIndex]
		local cell = self:_getCell(objectsCoordinates[object])
		local cellAdjacentNumbers = cell:getAdjacentCellsNumbers()

		local adjacents = {}
		for direction = 1, self._numOfDimensions * 2 do
			adjacents[direction] = customObjects[cellAdjacentNumbers[direction]]
		end

		adjacentsInitializer(object, adjacents)
	end

	return customMaze
end

--[[--
	Returns the same output as @{Maze:toSimpleRepresentation()} but in human-readable string format, such as:

	███████
	█░░░█░█
	███░█░█
	█░█░█░█
	█░█░█░█
	█░░░░░█
	███████

	If there are more than two dimensions, each "layer" is printed separately.

	@see Maze:toSimpleRepresentation()

	@param[opt=█] wallChar a string, usually a single character, to use to represent filled spaces
	@param[opt=░] spaceChar a string, usually a single character, to use to represent empty spaces

	@return string
]]
function Maze:toString(wallChar, spaceChar)
	wallChar = validifyInput("wallChar", wallChar, "string", '█')
	spaceChar = validifyInput("spaceChar", spaceChar, "string", '░')

	local simple, size = self:toSimpleRepresentation()

	return constructMultiDTable(
		size,
		function(coordinates)
			return getElementInMultiDTable(simple, coordinates) and wallChar or spaceChar
		end,
		function(layer, depth)
			return table.concat(layer, string.rep("\n", self._numOfDimensions - depth))
		end
	)
end



return Maze