local gadget = handler:NewGadget()

Spring.Echo("Initializing Map Editor gadget")

function gadget:GetInfo()
	return {
		name = "Map Editor Gadget",
		desc = "Map editor",
		author = "Slashscreen",
		date = "Present Day, Present Time",
		license = "GPL 3",
		layer = 0,
		enabled = true,
	}
end

local features = {}
for _, value in ipairs({}) do -- TODO
	table.insert(features, VFS.Include(value))
end

return gadget
