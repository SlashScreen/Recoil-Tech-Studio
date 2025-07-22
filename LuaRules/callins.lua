--  Copyright (C) 2007, 2025 Dave Rodgers, SlashScreen.
--  Licensed under the terms of the GNU GPL, v3 or later.

local function default_loop(_, fn_name, gadgets, ...)
	for _, gadget in ipairs(gadgets) do
		gadget[fn_name](gadget, ...)
	end
end

local function default_return_false(_, fn_name, gadgets, ...)
	for _, gadget in ipairs(gadgets) do
		if gadget[fn_name](gadget, ...) then
			return true
		end
	end
	return false
end

local function default_return_true(_, fn_name, gadgets, ...)
	for _, gadget in ipairs(gadgets) do
		if not gadget[fn_name](gadget, ...) then
			return false
		end
	end
	return true
end

local function default_if_value(_, fn_name, gadgets, ...)
	for _, gadget in ipairs(gadgets) do
		local value = gadget[fn_name](gadget, ...)
		if value then
			return value
		end
	end
end

local function do_nothing(_, _, _, _) end

--- @type table<string, function>
local callins = {
	Save = default_loop,
	Load = default_loop,
	Pong = default_loop,
	Shutdown = default_loop,
	GameSetup = function(_, _, gadgets, state, ready, playerStates)
		local success, newReady = false, ready
		for _, g in ipairs(gadgets) do
			success, newReady = g:GameSetup(state, ready, playerStates)
		end
		return success, newReady
	end,
	GamePreload = default_loop,
	GameStart = default_loop,
	GameOver = default_loop,
	GameFrame = default_loop,
	GameFramePost = default_loop,
	GamePaused = default_loop,
	GameProgress = default_loop,
	GameID = default_loop,
	PlayerChanged = default_loop,
	PlayerAdded = default_loop,
	PlayerRemoved = default_loop,
	TeamDied = default_loop,
	TeamChanged = default_loop,
	UnitCreated = default_loop,
	UnitFinished = default_loop,
	UnitFromFactory = default_loop,
	UnitReverseBuilt = default_loop,
	UnitConstructionDecayed = default_loop,
	UnitDestroyed = default_loop,
	RenderUnitDestroyed = default_loop,
	UnitExperience = default_loop,
	UnitIdle = default_loop,
	UnitCmdDone = default_loop,
	UnitPreDamaged = function(
		_,
		_,
		gadgets,
		unitID,
		unitDefID,
		unitTeam,
		damage,
		paralyzer,
		weaponDefID,
		projectileID,
		attackerID,
		attackerDefID,
		attackerTeam
	)
		local retDamage = damage
		local retImpulse = 1.0
		for _, g in ipairs(gadgets) do
			local dmg, imp = g:UnitPreDamaged(
				unitID,
				unitDefID,
				unitTeam,
				retDamage,
				paralyzer,
				weaponDefID,
				projectileID,
				attackerID,
				attackerDefID,
				attackerTeam
			)
			if dmg ~= nil then
				retDamage = dmg
			end
			if imp ~= nil then
				retImpulse = imp
			end
		end
		return retDamage, retImpulse
	end,
	UnitDamaged = default_loop,
	UnitStunned = default_loop,
	UnitTaken = default_loop,
	UnitGiven = default_loop,
	UnitEnteredRadar = default_loop,
	UnitEnteredLos = default_loop,
	UnitLeftRadar = default_loop,
	UnitLeftLos = default_loop,
	UnitSeismicPing = default_loop,
	UnitLoaded = default_loop,
	UnitUnloaded = default_loop,
	UnitCloaked = default_loop,
	UnitDecloaked = default_loop,
	UnitUnitCollision = default_return_false,
	UnitFeatureCollision = default_return_false,
	UnitMoveFailed = do_nothing, -- TODO
	UnitMoved = do_nothing, -- TODO
	UnitEnteredAir = default_loop,
	UnitLeftAir = default_loop,
	UnitEnteredWater = default_loop,
	UnitLeftWater = default_loop,
	UnitEnteredUnderwater = default_loop,
	UnitLeftUnderwater = default_loop,
	UnitCommand = default_loop,
	UnitHarvestStorageFull = default_loop,
	StockpileChanged = default_loop,
	FeatureCreated = default_loop,
	FeatureDestroyed = default_loop,
	FeatureDamaged = default_loop,
	FeatureMoved = do_nothing, -- TODO
	FeaturePreDamaged = function(
		_,
		_,
		gadgets,
		featureID,
		featureDefID,
		featureTeam,
		damage,
		weaponDefID,
		projectileID,
		attackerID,
		attackerDefID,
		attackerTeam
	)
		local retDamage = damage
		local retImpulse = 1.0
		for _, g in ipairs(gadgets) do
			local dmg, imp = g:FeaturePreDamaged(
				featureID,
				featureDefID,
				featureTeam,
				retDamage,
				weaponDefID,
				projectileID,
				attackerID,
				attackerDefID,
				attackerTeam
			)
			if dmg ~= nil then
				retDamage = dmg
			end
			if imp ~= nil then
				retImpulse = imp
			end
		end
		return retDamage, retImpulse
	end,
	ProjectileCreated = default_loop,
	ProjectileDestroyed = default_loop,
	ShieldPreDamaged = default_loop,
	AllowCommand = default_return_true,
	AllowStartPosition = default_return_true,
	AllowUnitCreation = function(_, _, gadgets, unitDefID, builderID, builderTeam, x, y, z, facing)
		for _, g in ipairs(gadgets) do
			local allow, drop = g:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
			if not allow then
				return false, drop
			end
		end
		return true, true
	end,
	AllowUnitTransfer = default_return_true,
	AllowUnitBuildStep = default_return_true,
	AllowUnitCaptureStep = default_return_true,
	AllowUnitTransport = default_return_true,
	AllowUnitTransportLoad = default_return_true,
	AllowUnitTransportUnload = default_return_true,
	AllowUnitCloak = default_return_true,
	AllowUnitDecloak = default_return_true,
	AllowUnitKamikaze = default_return_true,
	AllowFeatureBuildStep = default_return_true,
	AllowFeatureCreation = default_return_true,
	AllowResourceLevel = default_return_true,
	AllowResourceTransfer = default_return_true,
	AllowDirectUnitControl = default_return_true,
	AllowBuilderHoldFire = default_return_true,
	AllowWeaponTargetCheck = function(_, _, gadgets, attackerID, attackerWeaponNum, attackerWeaponDefID)
		local ignore = true
		for _, g in ipairs(gadgets) do
			local allowCheck, ignoreCheck = g:AllowWeaponTargetCheck(attackerID, attackerWeaponNum, attackerWeaponDefID)
			if not ignoreCheck then
				ignore = false
				if not allowCheck then
					return 0
				end
			end
		end
		return ((ignore and -1) or 1)
	end,
	AllowWeaponTarget = function(
		_,
		_,
		gadgets,
		attackerID,
		targetID,
		attackerWeaponNum,
		attackerWeaponDefID,
		defPriority
	)
		local allowed = true
		local priority = 1.0
		for _, g in ipairs(gadgets) do
			local targetAllowed, targetPriority =
				g:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
			if not targetAllowed then
				allowed = false
				break
			end
			priority = math.max(priority, targetPriority)
		end
		return allowed, priority
	end,
	AllowWeaponInterceptTarget = default_return_true,
	Explosion = function(_, _, gadgets, weaponID, px, py, pz, ownerID, projectileID)
		for _, g in ipairs(gadgets) do
			if g:Explosion(weaponID, px, py, pz, ownerID, projectileID) then
				return true
			end
		end
		return false
	end,
	CommandFallback = function(_, _, gadgets, unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
		for _, g in ipairs(gadgets) do
			local used, remove = g:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
			if used then
				return remove
			end
		end
		return true -- remove the command
	end,
	MoveCtrlNotify = function(_, _, gadgets, unitID, unitDefID, unitTeam, data)
		local state = false
		for _, g in ipairs(gadgets) do
			if g:MoveCtrlNotify(unitID, unitDefID, unitTeam, data) then
				state = true
			end
		end
		return state
	end,
	TerraformComplete = function(
		_,
		_,
		gadgets,
		unitID,
		unitDefID,
		unitTeam,
		buildUnitID,
		buildUnitDefID,
		buildUnitTeam
	)
		for _, g in ipairs(gadgets) do
			if g:TerraformComplete(unitID, unitDefID, unitTeam, buildUnitID, buildUnitDefID, buildUnitTeam) then
				return true
			end
		end
		return false
	end,
	RecvLuaMsg = default_return_false,
	Update = default_loop,
	UnsyncedHeightMapUpdate = function(_, _, gadgets, ...)
		for _, gadget in ipairs(gadgets) do
			local x1, y1, x2, y2 = gadget:UnsyncedHeightMapUpdate()
			if x1 ~= nil then
				return x1, y1, x2, y2
			end
		end
		return 0, 0, 0, 0
	end,
	DrawGenesis = default_loop,
	DrawWorld = default_loop,
	DrawWorldPreUnit = default_loop,
	DrawOpaqueUnitsLua = default_loop,
	DrawOpaqueFeaturesLua = default_loop,
	DrawAlphaUnitsLua = default_loop,
	DrawAlphaFeaturesLua = default_loop,
	DrawShadowUnitsLua = default_loop,
	DrawShadowFeaturesLua = default_loop,
	DrawPreDecals = default_loop,
	DrawWorldPreParticles = default_loop,
	DrawWorldShadow = default_loop,
	DrawWorldReflection = default_loop,
	DrawWorldRefraction = default_loop,
	DrawGroundPreForward = default_loop,
	DrawGroundPostForward = default_loop,
	DrawGroundPreDeferred = default_loop,
	DrawGroundDeferred = default_loop,
	DrawGroundPostDeferred = default_loop,
	DrawUnitsPostDeferred = default_loop,
	DrawFeaturesPostDeferred = default_loop,
	DrawScreenEffects = default_loop,
	DrawScreenPost = default_loop,
	DrawScreen = default_loop,
	DrawInMiniMap = default_loop,
	DrawUnit = default_return_false,
	DrawFeature = default_return_false,
	DrawShield = default_return_false,
	DrawProjectile = default_return_false,
	DrawMaterial = default_return_false,
	FontsChanged = default_loop,
	SunChanged = default_loop,
	RecvFromSynced = default_return_false,
	RecvSkirmishAIMessage = default_if_value,
	DefaultCommand = default_if_value,
	ActiveCommandChanged = default_loop,
	CameraRotationChanged = do_nothing, -- TODO
	CameraPositionChanged = do_nothing, -- TODO
	CommandNotify = default_return_false,
	ViewResize = default_loop,
	LayoutButtons = do_nothing, -- TODO
	ConfigureLayout = do_nothing,
	AddConsoleLine = do_nothing,
	GroupChanged = do_nothing,
	GotChatMsg = function(gadget_handler, _, gadgets, msg, player)
		if (player == 0) and Spring.IsCheatingEnabled() then
			local sp = "^%s*" -- start pattern
			local ep = "%s+(.*)" -- end pattern
			local s, e, match
			s, e, match = string.find(msg, sp .. "togglegadget" .. ep)
			if match then
				gadget_handler:ToggleGadget(match)
				return true
			end
			s, e, match = string.find(msg, sp .. "enablegadget" .. ep)
			if match then
				gadget_handler:EnableGadget(match)
				return true
			end
			s, e, match = string.find(msg, sp .. "disablegadget" .. ep)
			if match then
				gadget_handler:DisableGadget(match)
				return true
			end
		end

		if gadget_handler.actionHandler.GotChatMsg(msg, player) then
			return true
		end

		for _, g in ipairs(gadgets) do
			if g:GotChatMsg(msg, player) then
				return true
			end
		end

		return false
	end,
	KeyPress = default_return_false,
	KeyRelease = default_return_false,
	TextInput = function(gadget_handler, _, gadgets, utf8, ...)
		if gadget_handler.tweakMode then
			return true
		end

		for _, g in ipairs(gadgets) do
			if g:TextInput(utf8, ...) then
				return true
			end
		end
		return false
	end,
	TextEditing = do_nothing,
	MousePress = function(gadget_handler, _, gadgets, x, y, button)
		local mo = gadget_handler.mouseOwner
		if mo then
			mo:MousePress(x, y, button)
			return true --  already have an active press
		end
		for _, g in ipairs(gadgets) do
			if g:MousePress(x, y, button) then
				gadget_handler.mouseOwner = g
				return true
			end
		end
		return false
	end,
	MouseMove = function(gadget_handler, _, gadgets, x, y, dx, dy, button)
		local mo = gadget_handler.mouseOwner
		if mo and mo.MouseMove then
			return mo:MouseMove(x, y, dx, dy, button)
		end
	end,
	MouseRelease = function(gadget_handler, _, gadgets, x, y, button)
		local mo = gadget_handler.mouseOwner
		local mx, my, lmb, mmb, rmb = Spring.GetMouseState()
		if not (lmb or mmb or rmb) then
			gadget_handler.mouseOwner = nil
		end
		if mo and mo.MouseRelease then
			return mo:MouseRelease(x, y, button)
		end
		return -1
	end,
	MouseWheel = default_return_false,
	IsAbove = default_return_false,
	GetTooltip = function(_, _, gadgets, x, y)
		for _, g in ipairs(gadgets) do
			if g.IsAbove(x, y) then
				local tip = g:GetTooltip(x, y)
				if string.len(tip) > 0 then
					return tip
				end
			end
		end
		return ""
	end,
	WorldTooltip = do_nothing, -- TODO
	MapDrawCmd = default_return_false,
	ShockFront = do_nothing, -- TODO
	DownloadQueued = default_loop,
	DownloadStarted = default_loop,
	DownloadFinished = default_loop,
	DownloadFailed = default_loop,
	DownloadProgress = default_loop,
}

return callins
