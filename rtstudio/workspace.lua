--- @class Workspace
--- @field name string
--- @field sub_window_handles {[string]: RmlUi.Element}
local Workspace = {
	sub_window_handles = {},
}

--- @param name string
--- @param root_element RmlUi.Element
function Workspace:add_sub_window(name, root_element)
	self.sub_window_handles[name] = root_element
end

--- @param name string
function Workspace:remove_sub_window(name)
	self.sub_window_handles[name] = nil
end

--- @param name string
--- @return Workspace
function Workspace.new(name)
	local ws = { name = name }
	setmetatable(ws, { __index = Workspace })
	return ws
end

return Workspace
