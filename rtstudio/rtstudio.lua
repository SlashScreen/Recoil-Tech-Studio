-- Entry point of the RTStudio backend, called from the gadget and widget entry points

if RTStudio then
	return
end

Spring.Echo("Initializing RTStudio...")

--- @class RTStudio
--- @field ProjectManager ProjectManager
--- @field Workspaces {[string]: Workspace}
RTStudio = {
	ProjectManager = VFS.Include("rtstudio/project_manager.lua"),
	PluginManager = VFS.Include("rtstudio/plugin_manager.lua"),
	Workspaces = {},
}

--- @param name string
--- @param workspace Workspace
function RTStudio:add_workspace(name, workspace)
	self.Workspaces[name] = workspace
end

--- @param name string
function RTStudio:remove_workspace(name)
	self.Workspaces[name] = nil
end
