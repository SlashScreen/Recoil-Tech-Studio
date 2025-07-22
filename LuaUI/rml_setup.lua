--  file:    rml.lua
--  brief:   RmlUi Setup
--  author:  lov + ChrisFloofyKitsune
--
--  Copyright (C) 2024.
--  Licensed under the terms of the GNU GPL, v2 or later.

if RmlGuard or not RmlUi then
	return
end
RmlGuard = true
local DEBUG_RMLUI = true

-- Load fonts
--- @type string[]
local fonts = {
	"JosefinSans-Regular.ttf",
}
for _, font in ipairs(fonts) do
	RmlUi.LoadFontFace("LuaUI/fonts/" .. font, true)
end

-- Mouse Cursor Aliases
--[[
	These let standard CSS cursor names be used when doing styling.
	If a cursor set via RCSS does not have an alias, it is unchanged.
	CSS cursor list: https://developer.mozilla.org/en-US/docs/Web/CSS/cursor
	RmlUi documentation: https://mikke89.github.io/RmlUiDoc/pages/rcss/user_interface.html#cursor
]]

local oldCreateContext = RmlUi.CreateContext

local function NewCreateContext(name)
	local context = oldCreateContext(name)

	-- set up dp_ratio considering the user's UI scale preference and the screen resolution
	local viewSizeX, viewSizeY = Spring.GetViewGeometry()

	local userScale = Spring.GetConfigFloat("ui_scale", 1)

	local baseWidth = 1920
	local baseHeight = 1080
	local resFactor = math.min(viewSizeX / baseWidth, viewSizeY / baseHeight)

	context.dp_ratio = resFactor * userScale

	context.dp_ratio = math.floor(context.dp_ratio * 100) / 100
	return context
end

RmlUi.CreateContext = NewCreateContext

-- when "cursor: normal" is set via RCSS, "cursornormal" will be sent to the engine
RmlUi.SetMouseCursorAlias("default", "cursornormal")
-- for command cursors, use the command name
-- RmlUi.SetMouseCursorAlias("pointer", 'Move')

RmlUi.CreateContext("shared")

if DEBUG_RMLUI then
	RmlUi.SetDebugContext("shared")
end
