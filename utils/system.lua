--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    system.lua
--  brief:   defines the global entries placed into a gadget's table
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return {
	--
	--  Custom Spring tables
	--
	Script = Script,
	Spring = Spring,
	Engine = Engine,
	Platform = Platform,
	Game = Game,
	gl = gl,
	GL = GL,
	CMD = CMD,
	CMDTYPE = CMDTYPE,
	COB = COB,
	SFX = SFX,
	VFS = VFS,
	LOG = LOG,

	--
	-- Custom Constants
	--
	COBSCALE = COBSCALE,

	--
	--  Synced Utilities
	--
	CallAsTeam = CallAsTeam,
	SendToUnsynced = SendToUnsynced,

	--
	--  Unsynced Utilities
	--
	SYNCED = SYNCED,

	--
	--  Standard libraries
	--
	io = io,
	os = os,
	math = math,
	debug = debug,
	table = table,
	string = string,
	package = package,
	coroutine = coroutine,

	--
	--  Standard functions and variables
	--
	assert = assert,
	error = error,

	print = print,

	next = next,
	pairs = pairs,
	ipairs = ipairs,

	tonumber = tonumber,
	tostring = tostring,
	type = type,

	collectgarbage = collectgarbage,
	gcinfo = gcinfo,

	unpack = unpack,
	select = select,
	dofile = dofile,
	loadfile = loadfile,
	loadstring = loadstring,
	require = require,

	getmetatable = getmetatable,
	setmetatable = setmetatable,

	rawequal = rawequal,
	rawget = rawget,
	rawset = rawset,

	getfenv = getfenv,
	setfenv = setfenv,

	pcall = pcall,
	xpcall = xpcall,

	_VERSION = _VERSION,
}
