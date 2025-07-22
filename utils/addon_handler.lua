--[[
	Addon Handler
	(C) 2025 Slashscreen, 2007 Dave Rogers
	Licensed under the terms of the GNU GPL, v3 or later.

	Handles the loading and execution of addon scripts.

	Main features:
    - Scans a directory for addon scripts, loads and initializes them in a controlled environment.
    - Maintains metadata and ordering for each addon (name, layer, enabled state, etc.).
    - Automatically registers and routes engine call-ins (event functions) to all loaded addons that implement them.
    - Provides safe global variable registration and management per-addon.
    - Handles command ID registration and ownership.

    This handler is designed to be flexible and reusable for different types of Lua extension systems in Spring RTS.
]]

--- @module "utils/addon_handler/d"

-- Utility

local VFSMODE = VFS.ZIP_FIRST
if Spring.IsDevLuaEnabled() then
	VFSMODE = VFS.RAW_FIRST
end

--- @private
--- @param fullpath string
--- @return string basename
--- @return string dirname
local function get_basename(fullpath)
	local _, _, base = string.find(fullpath, "([^\\/:]*)$")
	local _, _, path = string.find(fullpath, "(.*[\\/:])[^\\/:]*$")
	path = path or ""
	base = base or ""
	return base, path
end

--- @class AddonHandler
--- @field addons Addon[]
--- @field addon_callin_map table<string, Addon[]> Maps callin names to lists of addons that implement them
--- @field addon_implemented_callins table<Addon, string[]> Maps addons to the list of callins they implement
--- @field order_list table<string, number>
--- @field known_addons table<string, {active: boolean, filepath: string}> This keeps track of previously registered addons, so it can fetch their filepaths right away
--- @field suppress_sort boolean Set to true to stop it from sorting addons when they are added or removed from the list. Used as an optimization during startup to avoid sorting over and over again as a million addons are loaded at once.
--- @field sort_func fun(self: AddonHandler) Function used to sort the addons.
--- @field validation_func fun(self: AddonHandler, addon: Addon): string? Function used to validate the addons. If a string is returned, it is treated as an error message, and the addon is skipped.
--- @field wrapper_func fun(self: AddonHandler, addon: Addon): AddonHandlerProxy Function used to return a safe wrapper for the handler that addons can use. The wrapper is to avoid gameplay code injection vulnerabilities.
--- @field log_section string
--- @field callin_list table<string, fun(addon_handler: AddonHandler, fn_name: string, addons: Addon[], ...: any)>
--- @field command_ids table<number, Addon> Command IDs and their owners
--- @field globals table<string, any> Global variables
--- @field SG table Addon shared globals
--- @field operation_queue {type: "add"|"remove"|"layer", addon: Addon, new_layer: integer?}[]
--- @field mouse_owner Addon?
--- @field system table globals for the addon environment
local addon_handler = {
	addons = {},
	addon_callin_map = {},
	addon_implemented_callins = {},
	order_list = {},
	known_addons = {},
	suppress_sort = false,
	SG = {},
	sort_func = function(self)
		-- Default addon sort function. Ascending order by layer, then name.
		if self.suppress_sort then
			return
		end

		--- @param g1 Addon
		--- @param g2 Addon
		--- @return boolean
		local sort_fun = function(g1, g2)
			local l1 = g1.custom_layer or g1.info.layer
			local l2 = g2.custom_layer or g2.info.layer
			if l1 ~= l2 then
				return (l1 < l2)
			end
			local n1 = g1.info.name
			local n2 = g2.info.name
			local o1 = self.order_list[n1]
			local o2 = self.order_list[n2]
			if o1 ~= o2 then
				return (o1 < o2)
			else
				return (n1 < n2)
			end
		end

		-- sort main list
		table.sort(self.addons, sort_fun)
		-- sort all callin maps
		for _, list in pairs(self.addon_callin_map) do
			table.sort(list, sort_fun)
		end
	end,
	validation_func = function(self, addon)
		return nil
	end,
	wrapper_func = function(self, addon)
		return {}
	end,
	log_section = "Addons",
	callin_list = {},
	command_ids = {},
	globals = {},
	operation_queue = {},
	mouse_owner = nil,
	system = {},
}

--- @param callin_list table<string, fun(addon_handler: AddonHandler, fn_name: string, addons: Addon[], ...: any)>
--- @param settings {
--- 	sort_func: fun(self: AddonHandler)?,
--- 	validation_func: (fun(self: AddonHandler, addon: Addon): string?)?,
--- 	wrapper_func: (fun(self: AddonHandler, addon: Addon): AddonHandlerProxy)?,
--- 	log_section: string?,
--- 	system: table?,
--- }
--- @return AddonHandler
function addon_handler.new(callin_list, settings)
	--- @diagnostic disable-next-line: missing-fields
	local self = {} --- @type AddonHandler
	setmetatable(self, { __index = addon_handler })

	-- Set settings
	self.sort_func = settings.sort_func or addon_handler.sort_func
	self.validation_func = settings.validation_func or addon_handler.validation_func
	self.wrapper_func = settings.wrapper_func or addon_handler.wrapper_func
	self.log_section = settings.log_section or addon_handler.log_section
	self.callin_list = callin_list
	self.system = settings.system or addon_handler.system

	-- Register callins
	--[[
		For each callin, it registers the function name in the global namespace.
		When the function is called, it runs the loop through all addons.
	]]
	for fn_name, func in pairs(callin_list) do
		self.addon_callin_map[fn_name] = {}
		-- fed to callin
		local function run_loop(...)
			local addons_list = self.addon_callin_map[fn_name]
			local values = { func(self, fn_name, addons_list, ...) }
			self:ProcessOperationQueue()
			return unpack(values)
		end
		-- If this manager has a function for this callin, call it first.
		if self[fn_name] then
			_G[fn_name] = function(...)
				local self_values = { self[fn_name](self, ...) }
				local addons_values = { run_loop(...) }
				if #self_values == 0 then -- if we return nil from the self function, defer to the others.
					return unpack(addons_values)
				end
				return unpack(self_values)
			end
		else
			_G[fn_name] = run_loop
		end
		--- @diagnostic disable-next-line: undefined-field
		Script.UpdateCallIn(fn_name)
	end

	return self
end

--#region Addon Loading

--- @param directory string
function addon_handler:LoadFromDirectory(directory)
	Spring.Echo("Loading addons from " .. directory)
	Spring.Log(self.log_section, LOG.INFO, "Loading addons from " .. directory)
	self.suppress_sort = true
	local syncedHandler = Script.GetSynced()
	local addon_files = VFS.DirList(directory, "*.lua")
	for _, file in ipairs(addon_files) do
		local addon = self:LoadAddon(file)
		if addon then
			self:AddAddon(addon)
			local gtype = ((syncedHandler and "SYNCED") or "UNSYNCED")
			local gname = addon.info.name
			local gbasename = addon.info.basename
			Spring.Log(
				self.log_section,
				LOG.INFO,
				string.format("Loaded %s gadget:  %-18s  <%s>", gtype, gname, gbasename)
			)
		end
	end

	-- Sort addons
	self.suppress_sort = false
	self:SortAddons()
end

--- Loads an addon from the file, executes it, finishes setup
--- @param file string Filepath of the addon code
--- @return Addon? addon Nil if failed
function addon_handler:LoadAddon(file)
	local basename, path = get_basename(file)

	-- Load text from disk
	local text = VFS.LoadFile(file, VFSMODE)
	if text == nil then
		Spring.Log(self.log_section, LOG.ERROR, "Failed to load: " .. file)
		return nil
	end

	-- Load text into chunk
	local chunk, err = loadstring(text, file)
	if chunk == nil then
		Spring.Log(self.log_section, LOG.ERROR, "Failed to load: " .. file .. "  (" .. err .. ")")
		return nil
	end

	-- Build addon environment
	local env = {
		_G = _G,
		SG = self.SG,
		handler = self:wrapper_func({}), --- @diagnostic disable-line: missing-fields
	}
	env.include = function(f)
		return VFS.Include(f, env, VFSMODE)
	end
	setmetatable(env, { __index = self.system })

	-- Set environment for chunk
	setfenv(chunk, env)

	-- Execute code to load addon
	local success, res = pcall(chunk)
	if not success then
		Spring.Log(self.log_section, LOG.ERROR, "Failed to load: " .. file .. "  (" .. tostring(res) .. ")")
		return nil
	end
	if res == nil or res == false then -- Return false means "quiet death"
		Spring.Log(self.log_section, LOG.INFO, "Addon at file " .. file .. " requested silent death")
		return nil
	end

	local addon = res --[[@as Addon]]

	self:FinalizeAddon(addon, path, basename)

	-- Validate addon
	err = self:validation_func(addon)
	if err then
		Spring.Log(self.log_section, LOG.ERROR, "Failed to load: " .. file .. "  (" .. err .. ")")
		return nil
	end

	local addon_info = addon.info
	if addon.info.enabled == false then -- skip if not enabled
		return nil
	end
	-- Add to known info, if not already present
	local known_info = self.known_addons[addon_info.name]
	if known_info then
		if known_info.active then
			Spring.Log(self.log_section, LOG.ERROR, "Failed to load: " .. file .. "  (duplicate name)")
			return nil
		end
	else
		known_info = {}
		known_info.filepath = addon_info.filename
		self.known_addons[addon_info.name] = known_info
	end
	known_info.active = true

	if addon_info.handler then
		env.raw_handler = self
	end

	return addon
end

--- Setup info table
--- @param addon Addon
--- @param filename string
--- @param basename string
function addon_handler:FinalizeAddon(addon, filename, basename)
	if addon == nil then
		Spring.Log(self.log_section, "warning", "Attempted to finalize nil addon at filename " .. filename)
		return
	end
	--- @diagnostic disable-next-line: missing-fields
	local ai = {
		filename = filename,
		basename = basename,
	} --- @type AddonInfo

	if addon.GetInfo then
		local info = addon:GetInfo()
		ai.name = info.name or basename
		ai.layer = info.layer or 0
		ai.desc = info.desc or ""
		ai.author = info.author or ""
		ai.license = info.license or ""
		ai.enabled = info.enabled or false
		ai.handler = info.handler or false
	else
		ai.name = basename
		ai.layer = 0
	end

	setmetatable(ai, {
		__newindex = function()
			error("Addon info tables are read-only.")
		end,
		__metatable = "protected",
	})

	addon.info = ai
end

--#endregion
--#region Addon Operations

--- Add an addon
--- @param addon Addon
function addon_handler:AddAddon(addon)
	if addon == nil then
		return
	end

	--self.addon_callin_map[addon] = {}
	self.addon_implemented_callins[addon] = {}
	local implemented_list = self.addon_implemented_callins[addon]
	-- Create a list of implemented callins by looping through the callin list and checking if that's a function in the addon
	for listname, _ in pairs(self.callin_list) do
		local func = addon[listname]
		if func and type(func) == "function" then
			table.insert(implemented_list, listname)
		end
	end

	-- Add the gadget to the list of addons that implement each callin
	for _, callin in ipairs(implemented_list) do
		local list = self.addon_callin_map[callin]
		if list then
			table.insert(list, addon)
		end
	end

	--table.insert(self.addons, addon)

	if addon.Initialize then
		addon:Initialize()
	end

	-- remove addons from the command ids they own
	for id, a in pairs(self.command_ids) do
		if a == addon then
			self.command_ids[id] = nil
		end
	end

	self:SortAddons()
end

function addon_handler:RemoveAddon(addon)
	if addon == nil then
		return
	end

	for index, value in ipairs(self.addons) do
		if value == addon then
			table.remove(self.addons, index)
			break
		end
	end

	for _, callin in ipairs(self.addon_implemented_callins[addon]) do
		local list = self.addon_callin_map[callin]
		for index, value in ipairs(list) do
			if value == addon then
				table.remove(list, index)
				break
			end
		end
	end

	if addon.Shutdown then
		addon:Shutdown()
	end

	self:RemoveAddonGlobals(addon)
	-- Remove associated command IDs
	for id, a in pairs(self.command_ids) do
		if a == addon then
			self.command_ids[id] = nil
		end
	end

	self:SortAddons()
end

--- Process any operations requested by addons
function addon_handler:ProcessOperationQueue()
	if #self.operation_queue == 0 then
		return
	end

	self.suppress_sort = true
	for _, operation in ipairs(self.operation_queue) do
		if operation.type == "add" then
			-- TODO
		elseif operation.type == "remove" then
			self:RemoveAddon(operation.addon)
		elseif operation.type == "layer" then
			self:MoveAddonToLayer(operation.addon, operation.new_layer)
		end
	end
	self.suppress_sort = false

	self:SortAddons()
	self.operation_queue = {}
end

function addon_handler:GetAddonCurrentLayer(addon)
	return addon.custom_layer or addon.info.layer
end

--- Find the index of this addon in the list
--- @param addon Addon
--- @return integer? index nil if not found
function addon_handler:FindAddonIndex(addon)
	for index, a in ipairs(self.addons) do
		if a == addon then
			return index
		end
	end
end

function addon_handler:MoveAddonToLayer(addon, layer)
	addon.custom_layer = layer
	self:SortAddons()
end

function addon_handler:RequestAddonAddition(addon)
	table.insert(self.operation_queue, { type = "add", addon = addon })
end

--- Request an addon to be removed the next chance it gets.
--- @param addon Addon
function addon_handler:RequestAddonRemoval(addon)
	table.insert(self.operation_queue, { type = "remove", addon = addon })
end

--- Request a layer change for the addon to be executed the next chance it gets.
--- @param addon Addon
--- @param layer integer
function addon_handler:RequestAddonLayerChange(addon, layer)
	table.insert(self.operation_queue, { type = "layer", addon = addon, layer = layer })
end

--- Will attempt to raise the layer of the addon to be above the next highest addon the next chance it gets.
--- @param addon Addon
function addon_handler:RequestAddonRaise(addon)
	local idx = self:FindAddonIndex(addon)
	if idx == nil then
		Spring.Log(
			self.log_section,
			"warning",
			"Attempted to raise addon " .. addon.info.name .. ", which was not in the manager list."
		)
		-- if not in the list, do nothing.
		return
	end

	if idx >= #self.addons then
		-- if this addon is at the top of the list, we don't need to raise it
		return
	end

	local new_layer = self:GetAddonCurrentLayer(self.addons[idx + 1]) + 1
	self:RequestAddonLayerChange(addon, new_layer)
end

--- Will attempt to lower the layer of the addon to be below the next lowest index the next chance it gets.
--- @param addon Addon
function addon_handler:RequestAddonLower(addon)
	local idx = self:FindAddonIndex(addon)
	if idx == nil then
		Spring.Log(
			self.log_section,
			"warning",
			"Attempted to lower addon " .. addon.info.name .. ", which was not in the manager list."
		)
		-- if not in the list, do nothing.
		return
	end

	if idx <= 1 then
		-- if this addon is at the bottom of the list, we don't need to lower it
		return
	end

	local new_layer = self:GetAddonCurrentLayer(self.addons[idx + 1]) - 1
	self:RequestAddonLayerChange(addon, new_layer)
end

--#endregion
--#region Globals

--- Register a global variable and tie it to an addon
--- @param owner Addon
--- @param name string
--- @param value any
--- @return boolean success
function addon_handler:RegisterGlobal(owner, name, value)
	if name == nil then
		return false
	end
	if _G[name] then
		return false
	end
	if self.globals[name] then
		return false
	end

	_G[name] = value
	self.globals[name] = owner
	return true
end

--- Unregister a global variable
--- @param owner Addon
--- @param name string
--- @return boolean success
function addon_handler:DeregisterGlobal(owner, name)
	if name == nil then
		return false
	end
	_G[name] = nil

	if owner then
		self.globals[name] = nil
	end

	return true
end

--- Set a global value. This will be locked to the addon that registered it
--- @param owner Addon
--- @param name string
--- @param value any
--- @return boolean success
function addon_handler:SetGlobal(owner, name, value)
	if (name == nil) or (self.globals[name] ~= owner) then
		return false
	end

	_G[name] = value
	return true
end

--- Remove all registered global values for an addon
--- @param owner Addon
function addon_handler:RemoveAddonGlobals(owner)
	for name, o in pairs(self.globals) do
		if o == owner then
			_G[name] = nil
			self.globals[name] = nil
		end
	end
end

--#endregion

--- Sort the addons
function addon_handler:SortAddons()
	self:sort_func()
end

--- Register a command ID to an addon
--- @param addon Addon
--- @param id integer
function addon_handler:RegisterCMDID(addon, id)
	if id <= 1000 then
		Spring.Log(
			self.log_section,
			LOG.ERROR,
			"Gadget (" .. addon.info.name .. ") " .. "tried to register a reserved CMD_ID"
		)
		Script.Kill("Reserved CMD_ID code: " .. id)
	end

	if self.command_ids[id] ~= nil then
		Spring.Log(
			self.log_section,
			LOG.ERROR,
			"Gadget (" .. addon.info.name .. ") " .. "tried to register a duplicated CMD_ID"
		)
		Script.Kill("Duplicate CMD_ID code: " .. id)
	end

	self.command_ids[id] = addon
end

--- Are we running in a synced context?
--- @return boolean
function addon_handler:IsSyncedCode()
	return Script.GetSynced()
end

return addon_handler
