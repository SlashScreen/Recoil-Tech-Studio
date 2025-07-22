if not RmlUi then
	Spring.Echo("No RmlUI!")
	return false
end

local widget = handler:NewWidget() --- @type Widget

local DATA_MODEL_NAME = "sidebar_model"

function widget:GetInfo()
	return {
		name = "RTS Side Panel",
		desc = "RTS Side Panel",
		author = "Slashscreen",
		date = "Present Day, Present Time",
		license = "https://unlicense.org/",
		layer = -828888,
		handler = true,
		enabled = true,
	}
end

local document --- @type RmlUi.Document
local dm_handle --- @type RmlUi.SolLuaDataModel<SidebarModel>
--- @class SidebarModel
local sidebar_model = {}

function widget:Initialize()
	widget.rmlContext = RmlUi.GetContext("shared")

	dm_handle = widget.rmlContext:OpenDataModel(DATA_MODEL_NAME, sidebar_model)
	assert(dm_handle ~= nil, "RmlUi: Failed to open data model " .. DATA_MODEL_NAME)

	document = widget.rmlContext:LoadDocument("LuaUi/Widgets/sidebar.rml", widget)
	assert(document ~= nil, "Failed to load document")

	RmlUi.SetDebugContext(widget.info.name)
	document:ReloadStyleSheet()
	document:Show()

	Spring.Echo("Initialized Info Panel")
end

function widget:Shutdown()
	if document then
		document:Close()
	end

	if widget.rmlContext then
		RmlUi.RemoveContext(widget.info.name)
	end
end

return widget
