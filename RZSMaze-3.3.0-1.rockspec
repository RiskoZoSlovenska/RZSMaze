package = "RZSMaze"
version = "3.3.0-1"
source = {
	url = "git://github.com/RiskoZoSlovenska/RZSMaze",
	tag = "v3.3.0",
}
description = {
	summary = "A library for generating multi-dimensional mazes",
	detailed = "A maze generation library that uses the Loop-Erased Random Walk algorithm, also known as Wilson's Algorithm, to create mazes.",
	homepage = "https://github.com/RiskoZoSlovenska/RZSMaze",
	license = "MIT",
}
dependencies = {
	"lua >= 5.1",
}
build = {
	type = "builtin",
	modules = {
		RZSMaze = "RZSMaze.lua",
	},
}
