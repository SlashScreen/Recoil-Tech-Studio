--- @class RTSProject
--- @field root_folder string
--- @field units_folder string
--- @field features_folder string
--- @field scripts_folder string
--- @field units UnitDef[]
--- @field features FeatureDef[]
--- @field scripts RTSScript[]

--- @class ProjectManager
--- @field projects {[string]: RTSProject}
local ProjectManager = {
	projects = {},
}

return ProjectManager
