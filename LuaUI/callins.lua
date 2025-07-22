Spring.Echo("Attempting to load callins...")

local function default_loop(_, fn_name, widgets, ...)
	for _, gadget in ipairs(widgets) do
		gadget[fn_name](widgets, ...)
	end
end

local function default_return_false(_, fn_name, widgets, ...)
	for _, gadget in ipairs(widgets) do
		if gadget[fn_name](widgets, ...) then
			return true
		end
	end
	return false
end

local function default_if_value(_, fn_name, widgets, ...)
	for _, gadget in ipairs(widgets) do
		local value = gadget[fn_name](widgets, ...)
		if value then
			return value
		end
	end
end

local function do_nothing(_, _, _, _) end

--- @type table<string, fun(self: WidgetHandler, ...):...>
return {
	-- Game lifecycle events
	GamePreload = default_loop,
	GameStart = default_loop,
	GameOver = default_loop,
	GamePaused = default_loop,
	Shutdown = default_loop,

	-- Player/Team events
	TeamDied = default_loop,
	TeamChanged = default_loop,
	PlayerChanged = default_loop,
	PlayerAdded = default_loop,
	PlayerRemoved = default_loop,

	-- Game state updates
	Update = default_loop,
	GameFrame = default_loop,
	ShockFront = default_loop,

	-- Commands and Selection
	CommandNotify = default_return_false,
	CommandsChanged = default_loop,
	DefaultCommand = default_if_value,
	SelectionChanged = function(_, fn_name, widgets, selectedUnits, subselection)
		for _, w in ipairs(widgets) do
			local unitArray = w[fn_name](w, selectedUnits, subselection)
			if unitArray then
				Spring.SelectUnitArray(unitArray)
				return true
			end
		end
		return false
	end,

	-- Drawing functions
	DrawGenesis = default_loop,
	DrawWorld = default_loop,
	DrawWorldPreUnit = default_loop,
	DrawWorldShadow = default_loop,
	DrawWorldReflection = default_loop,
	DrawWorldRefraction = default_loop,
	DrawUnitsPostDeferred = default_loop,
	DrawFeaturesPostDeferred = default_loop,
	DrawScreenEffects = default_loop,
	DrawScreen = default_loop,
	DrawScreenPost = default_loop,
	DrawInMiniMap = default_loop,

	-- View changes
	ViewResize = default_loop,
	SunChanged = default_loop,
	-- Input handling
	KeyPress = default_return_false,
	KeyRelease = default_return_false,
	TextInput = default_return_false,
	MousePress = function(self, fn_name, widgets, x, y, button)
		local mo = self.mouse_owner --[[@as Widget]]
		if not self.tweak_mode then
			if mo then
				mo[fn_name](mo, x, y, button)
				return true -- already have an active press
			end
			for _, w in ipairs(widgets) do
				if w[fn_name](w, x, y, button) then
					if not mo then
						self.mouse_owner = w
					end
					return true
				end
			end
			return false
		else
			if mo then
				mo:TweakMousePress(x, y, button)
				return true -- already have an active press
			end
			for _, w in
				ipairs(self.addon_callin_map["TweakMousePress"] --[[@as Widget[]])
			do -- TODO
				if w:TweakMousePress(x, y, button) then
					self.mouse_owner = w
					return true
				end
			end
			return true -- always grab the mouse
		end
	end,
	MouseMove = function(self, _, _, x, y, dx, dy, button)
		local mo = self.mouse_owner --[[@as Widget]]
		if not self.tweak_mode then
			if mo and mo.MouseMove then
				return mo:MouseMove(x, y, dx, dy, button)
			end
		else
			if mo and mo.TweakMouseMove then
				mo:TweakMouseMove(x, y, dx, dy, button)
			end
			return true
		end
	end,
	MouseRelease = function(self, _, _, x, y, button)
		local mo = self.mouse_owner --[[@as Widget]]
		local _, _, lmb, mmb, rmb = Spring.GetMouseState()
		if not (lmb or mmb or rmb) then
			self.mouse_owner = nil
		end

		if not self.tweak_mode then
			if mo and mo.MouseRelease then
				return mo:MouseRelease(x, y, button)
			end
			return -1
		else
			if mo and mo.TweakMouseRelease then
				mo:TweakMouseRelease(x, y, button)
			end
			return -1
		end
	end,
	MouseWheel = function(self, fn_name, widgets, up, value)
		if not self.tweak_mode then
			for _, w in ipairs(widgets) do
				if w[fn_name](w, up, value) then
					return true
				end
			end
			return false
		else
			for _, w in
				ipairs(self.addon_callin_map["TweakMouseWheel"] --[[@as Widget[]])
			do
				if w:TweakMouseWheel(up, value) then
					return true
				end
			end
			return false -- FIXME: always grab in tweak_mode?
		end
	end,
	JoyAxis = default_return_false,
	JoyHat = default_return_false,
	JoyButtonDown = default_return_false,
	JoyButtonUp = default_return_false,

	-- Unit events
	UnitCreated = default_loop,
	UnitFinished = default_loop,
	UnitFromFactory = default_loop,
	UnitReverseBuilt = default_loop,
	UnitDestroyed = default_loop,
	RenderUnitDestroyed = default_loop,
	UnitTaken = default_loop,
	UnitGiven = default_loop,
	UnitIdle = default_loop,
	UnitCommand = default_loop,
	UnitCmdDone = default_loop,
	UnitDamaged = default_loop,
	UnitStunned = default_loop,
	UnitEnteredRadar = default_loop,
	UnitEnteredLos = default_loop,
	UnitLeftRadar = default_loop,
	UnitLeftLos = default_loop,
	UnitEnteredWater = default_loop,
	UnitEnteredAir = default_loop,
	UnitLeftWater = default_loop,
	UnitLeftAir = default_loop,
	UnitSeismicPing = default_loop,
	UnitLoaded = default_loop,
	UnitUnloaded = default_loop,
	UnitCloaked = default_loop,
	UnitDecloaked = default_loop,
	UnitMoveFailed = default_loop,
	-- UI and tooltips
	IsAbove = function(self, _, _, x, y)
		if self.tweak_mode then
			return true
		end
		return (self:WidgetAt(x, y) ~= nil)
	end,
	GetTooltip = function(self, _, widgets, x, y)
		if not self.tweak_mode then
			for _, w in ipairs(widgets) do
				if w:IsAbove(x, y) then
					local tip = w:GetTooltip(x, y)
					if (type(tip) == "string") and (#tip > 0) then
						return tip
					end
				end
			end
			return ""
		else
			for _, w in
				ipairs(self.addon_callin_map["TweakGetTooltip"] --[[@as Widget[]])
			do
				if w:TweakIsAbove(x, y) then
					local tip = w:TweakGetTooltip(x, y) or ""
					if (type(tip) == "string") and (#tip > 0) then
						return tip
					end
				end
			end
			return "Tweak Mode  --  hit ESCAPE to cancel"
		end
	end,
	GroupChanged = default_loop,
	WorldTooltip = default_if_value,
	MapDrawCmd = function(_, fn_name, widgets, playerID, cmdType, px, py, pz, ...)
		local retval = false
		for _, w in ipairs(widgets) do
			if w[fn_name](w, playerID, cmdType, px, py, pz, ...) then
				retval = true
			end
		end
		return retval
	end,
	AddConsoleLine = default_loop,
	RecvLuaMsg = default_return_false,

	-- AI and synced messages
	RecvFromSynced = default_return_false,
	RecvSkirmishAIMessage = default_if_value,
	GameSetup = do_nothing,

	-- Download events
	DownloadStarted = default_loop,
	DownloadQueued = default_loop,
	DownloadFinished = default_loop,
	DownloadFailed = default_loop,
	DownloadProgress = default_loop,

	-- Miscellaneous
	StockpileChanged = default_loop,
	TextCommand = default_return_false,

	-- Dummy tweaked mode events
	TweakMousePress = do_nothing,
	TweakMouseMove = do_nothing,
	TweakMouseRelease = do_nothing,
	TweakMouseWheel = do_nothing,
	TweakIsAbove = do_nothing,
	TweakGetTooltip = do_nothing,
}
