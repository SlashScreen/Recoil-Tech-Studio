Spring.Echo("Synced LuaRules: loading utils")

Spring.Utilities = Spring.Utilities or {}

local utilFiles = VFS.DirList("LuaRules/Utilities/", "*.lua")
for i = 1, #utilFiles do
	if (string.find(utilFiles[i], "json.lua") or -1) > -1 then
		Spring.Utilities.json = VFS.Include(utilFiles[i])
	else
		VFS.Include(utilFiles[i])
	end
end

VFS.Include("LuaRules/setupdefs.lua")

Spring.Echo("Synced LuaRules: starting loading")
local GadgetHandler = VFS.Include("LuaRules/gadgets.lua", nil, VFS.GAME)
Spring.Echo("Synced LuaRules: finished loading")

VFS.Include("rtstudio/rtstudio.lua")

for _, value in ipairs(RTStudio.PluginManager:get_gadgets()) do
	GadgetHandler:LoadAddon(value.gadget)
end
