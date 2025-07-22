Spring.Echo("IM LUAUI aehoo")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    main.lua
--  brief:   the entry point from gui.lua, relays call-ins to the widget manager
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LUAUI_DIRNAME = "LuaUI/"
LUAUI_VERSION = "LuaUI v0.3"

Spring.SendCommands({ "ctrlpanel " .. LUAUI_DIRNAME .. "ctrlpanel.txt" })

VFS.Include(LUAUI_DIRNAME .. "rml_setup.lua", nil, VFS.ZIP)
VFS.Include(LUAUI_DIRNAME .. "utils.lua", utilFile)
--VFS.Include("libs/teal/integration.lua")

WG = {}
Spring.Utilities = {}
VFS.Include("LuaRules/Utilities/glvolumes.lua")
VFS.Include("LuaUI/fonts.lua")

include("setupdefs.lua")
include("savetable.lua")

include("debug.lua")

-- Override default engine UI handling

include("layout.lua") -- contains a simple LayoutButtons()

-- consider using ZK or BAR LayoutButtons, they might handle some gotchas
-- see also: https://github.com/beyond-all-reason/Beyond-All-Reason/blob/27b2e2fa9a62c85db50a825ca4a88ebf689a1e16/luaui/layout.lua#L42-L80

-- refresh, this prevents default engine buildmenu still showing up after a luaui reload
Spring.ForceLayoutUpdate()

--/ Override default engine UI handling

VFS.Include("LuaUI/widgets.lua", nil, VFS.GAME) -- the widget handler

--------------------------------------------------------------------------------
--
-- print the header
--

if RestartCount == nil then
	RestartCount = 0
else
	RestartCount = RestartCount + 1
end

do
	local restartStr = ""
	if RestartCount > 0 then
		restartStr = "  (" .. RestartCount .. " Restarts)"
	end
	Spring.SendCommands({ "echo " .. LUAUI_VERSION .. restartStr })
end

--------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  A few helper functions
--

function Say(msg)
	Spring.SendCommands({ "say " .. msg })
end
