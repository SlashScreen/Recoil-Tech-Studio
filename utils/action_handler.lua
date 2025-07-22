-- $Id: actions.lua 2491 2008-07-17 13:36:51Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    actions
--  brief:   hooks for GotChatMsg() and RecvFromSynced() calls
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local chatActions = {}

local syncActions = {}

local isSyncedCode = (SendToUnsynced ~= nil)

local function MakeWords(line)
	local words = {}
	for w in line:gmatch("[^%s]+") do
		table.insert(words, w)
	end
	return words
end

--#region Insertions

local function InsertCallInfo(callInfoList, addon, func, help)
	local layer = addon.custom_layer or addon.info.layer
	local index = 1
	for i, ci in ipairs(callInfoList) do
		local g = ci[2]
		if g == addon then
			return false --  already in the table
		end
		if layer >= g.info.layer then
			index = i + 1
		end
	end
	table.insert(callInfoList, index, { func, addon, help = help })
	return true
end

local function InsertAction(map, addon, cmd, func, help)
	local callInfoList = map[cmd]
	if callInfoList == nil then
		callInfoList = {}
		map[cmd] = callInfoList
	end
	return InsertCallInfo(callInfoList, addon, func, help)
end

--#endregion
--#region Removals

local function RemoveCallInfo(callInfoList, addon)
	local count = 0
	for i, callInfo in ipairs(callInfoList) do
		local g = callInfo[2]
		if g == addon then
			table.remove(callInfoList, i)
			count = count + 1
			-- break
		end
	end
	return count
end

local function RemoveAction(map, addon, cmd)
	local callInfoList = map[cmd]
	if callInfoList == nil then
		return false
	end
	local count = RemoveCallInfo(callInfoList, addon)
	if #callInfoList <= 0 then
		map[cmd] = nil
	end
	return (count > 0)
end

local function RemoveaddonActions(addon)
	local function clearActionList(actionMap)
		for cmd, callInfoList in pairs(actionMap) do
			RemoveCallInfo(callInfoList, addon)
		end
	end
	clearActionList(chatActions)
	clearActionList(syncActions)
end

--#endregion
--#region  Add / Remove Chat Action

local function AddChatAction(addon, cmd, func, help)
	return InsertAction(chatActions, addon, cmd, func, help)
end

local function RemoveChatAction(addon, cmd)
	return RemoveAction(chatActions, addon, cmd)
end

--#endregion
--#region Add / Remove Sync Action

local function AddSyncAction(addon, cmd, func, help)
	return InsertAction(syncActions, addon, cmd, func, help)
end

local function RemoveSyncAction(addon, cmd)
	return RemoveAction(syncActions, addon, cmd)
end

--#endregion

local function EchoLines(msg)
	for line in msg:gmatch("([^\n]+)\n?") do
		Spring.Echo(line)
	end
end

local function Help(playerID, cmd)
	if cmd == nil then
		-- print the list of commands, alphabetically
		local sorted = {}
		for name in pairs(chatActions) do
			table.insert(sorted, name)
		end
		table.sort(sorted)
		local str = Script.GetName() .. " commands: "
		for _, name in ipairs(sorted) do
			str = str .. "  " .. name
		end
		Spring.Echo(str)
		if isSyncedCode then
			SendToUnsynced(playerID, "help")
		end
	else
		local callInfoList = chatActions[cmd]
		if not callInfoList then
			if not isSyncedCode then
				Spring.Echo("unknown command:  " .. cmd)
			end
		else
			for i, callInfo in ipairs(callInfoList) do
				if callInfo.help then
					EchoLines(cmd .. callInfo.help)
					return
				end
			end
		end
		if isSyncedCode then
			SendToUnsynced(playerID, "help " .. cmd)
		end
	end
end

local function GotChatMsg(msg, playerID)
	local words = MakeWords(msg)
	local cmd = words[1]
	if cmd == nil then
		return false
	end

	local callInfoList = chatActions[cmd]
	if callInfoList == nil then
		if cmd == "help" then
			Help(playerID, words[2])
			return true
		end
		return false
	end

	-- remove the command from the words list and the raw line
	table.remove(words, 1)
	local _, _, msg = msg:find("[%s]*[^%s]+[%s]+(.*)")
	if msg == nil then
		msg = "" -- no args
	end

	for i, callInfo in ipairs(callInfoList) do
		local func = callInfo[1]
		-- local addon = callInfo[2]
		if func(cmd, msg, words, playerID) then
			return true
		end
	end

	return false
end

local function RecvFromSynced(arg1, arg2, ...)
	if type(arg1) == "string" then
		-- a raw sync msg
		local callInfoList = syncActions[arg1]
		if callInfoList == nil then
			return false
		end

		for i, callInfo in ipairs(callInfoList) do
			local func = callInfo[1]
			-- local addon = callInfo[2]
			if func(arg1, arg2, ...) then
				return true
			end
		end
		return false
	end

	return false -- unknown type
end

local AH = {}

AH.GotChatMsg = GotChatMsg
AH.RecvFromSynced = RecvFromSynced

AH.AddChatAction = AddChatAction
AH.AddSyncAction = AddSyncAction
AH.RemoveChatAction = RemoveChatAction
AH.RemoveSyncAction = RemoveSyncAction

AH.RemoveaddonActions = RemoveaddonActions

AH.HaveChatAction = function()
	return (next(chatActions) ~= nil)
end
AH.HaveSyncAction = function()
	return (next(syncActions) ~= nil)
end

function AH.new()
	local n = {}
	setmetatable(n, { __index = AH })
	return n
end

return AH
