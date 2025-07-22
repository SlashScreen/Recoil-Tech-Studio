--- @class PluginInfo
--- @field name string
--- @field description string
--- @field author string

--- @class Plugin
--- @field info PluginInfo
--- @field gadget string?
--- @field widget string?
local Plugin = {}

Spring.Echo("Initializing Plugin Manager...")

--- @param root_path string
--- @return Plugin
function Plugin.new(root_path)
	--- @type PluginInfo
	local info = VFS.Include(root_path .. "plugin.lua")
		or { name = "FAILED TO INITIALIZE PLUGIN AT " .. root_path, description = "", author = "" }

	--- @type Plugin
	local p = {
		info = info,
	}

	local gadget_path = root_path .. "gadget.lua"
	if VFS.FileExists(gadget_path) then
		p.gadget = gadget_path
	end
	local widget_path = root_path .. "widget.lua"
	if VFS.FileExists(widget_path) then
		p.widget = widget_path
	end

	setmetatable(p, { __index = p })
	return p
end

-- * MANAGER

--- @class PluginManager
--- @field plugins {[string]: Plugin}
local PluginManager = {
	plugins = {},
}

--- @return Plugin[]
function PluginManager:get_widgets()
	local w = {}
	for _, value in pairs(self.plugins) do
		if value.widget then
			table.insert(w, value)
		end
	end
	return w
end

--- @return Plugin[]
function PluginManager:get_gadgets()
	local g = {}
	for _, value in pairs(self.plugins) do
		if value.gadget then
			table.insert(g, value)
		end
	end
	return g
end

-- * load plugins

Spring.Echo("Plugin Manager: Loading Plugins...")

for _, path in ipairs(VFS.SubDirs("plugins")) do
	Spring.Echo("Plugin Manager: Loading Plugin from " .. path)
	local p = Plugin.new(path)
	PluginManager.plugins[p.info.name] = p
end

return PluginManager
