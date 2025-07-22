-- (C) 2025 Slashscreen, 2007 Dave Rogers; Licensed under the terms of the GNU GPL, v3 or later.

local AddonHandler = VFS.Include("utils/addon_handler.lua")
local ActionHandler = VFS.Include("utils/action_handler.lua")
local callins = VFS.Include("LuaRules/callins.lua")

local action_handler = ActionHandler.new()

local GADGETS_PATH = "LuaRules/Gadgets"

--- @class GadgetHandlerProxy: AddonHandlerProxy
--- @field RaiseGadget fun(handler: GadgetHandlerProxy) Raises the gadget.
--- @field LowerGadget fun(handler: GadgetHandlerProxy) Lowers the gadget.
--- @field RemoveGadget fun(handler: GadgetHandlerProxy) Removes the gadget.
--- @field IsSyncedCode fun(handler: GadgetHandlerProxy):boolean Returns whether the code is synced.
--- @field RegisterCMDID fun(handler: GadgetHandlerProxy, id: number) Registers a command ID for the gadget.
--- @field RegisterGlobal fun(handler: GadgetHandlerProxy, name: string, value: any):any Registers a global variable for the gadget.
--- @field DeregisterGlobal fun(handler: GadgetHandlerProxy, name: string):any Deregisters a global variable for the gadget.
--- @field SetGlobal fun(handler: GadgetHandlerProxy, name: string, value: any):any Sets a global variable for the gadget.
--- @field AddChatAction fun(handler: GadgetHandlerProxy, cmd: string, func: function, help: string):any Adds a chat action for the gadget.
--- @field RemoveChatAction fun(handler: GadgetHandlerProxy, cmd: string):any Removes a chat action for the gadget.
--- @field IsMouseOwner fun(handler: GadgetHandlerProxy):boolean Returns whether the gadget is the mouse owner.
--- @field DisownMouse fun(handler: GadgetHandlerProxy) Disowns the mouse if the gadget is the owner.
--- @field AddSyncAction fun(handler: GadgetHandlerProxy, cmd: string, func: function, help: string):any Adds a sync action for the gadget.
--- @field RemoveSyncAction fun(handler: GadgetHandlerProxy, cmd: string):any Removes a sync action for the gadget.
--- @field NewGadget fun(handler: GadgetHandlerProxy):Gadget Creates a new gadget instance.

--- @class GadgetInfoPacket: AddonInfoPacket

--- @class Gadget: Addon

--- @param handler GadgetHandler
--- @param gadget Gadget
--- @return GadgetHandlerProxy
local function wrap_gadget_handler(handler, gadget)
	return {
		handler_gadget = gadget,
		RaiseGadget = function(self)
			handler:RequestAddonRaise(self.handler_gadget)
		end,
		LowerGadget = function(self)
			handler:RequestAddonLower(self.handler_gadget)
		end,
		RemoveGadget = function(self)
			handler:RequestAddonRemoval(self.handler_gadget)
		end,
		IsSyncedCode = function(_)
			return handler:IsSyncedCode()
		end,
		RegisterCMDID = function(self, id)
			handler:RegisterCMDID(self.handler_gadget, id)
		end,
		RegisterGlobal = function(self, name, value)
			return handler:RegisterGlobal(self.handler_gadget, name, value)
		end,
		DeregisterGlobal = function(self, name)
			return handler:DeregisterGlobal(self.handler_gadget, name)
		end,
		SetGlobal = function(self, name, value)
			return handler:SetGlobal(self.handler_gadget, name, value)
		end,
		AddChatAction = function(self, cmd, func, help)
			return action_handler.AddChatAction(self.handler_gadget, cmd, func, help)
		end,
		RemoveChatAction = function(self, cmd)
			return action_handler.RemoveChatAction(self.handler_gadget, cmd)
		end,
		IsMouseOwner = function(self)
			return (handler.mouse_owner == self.handler_gadget)
		end,
		DisownMouse = function(self)
			if handler.mouse_owner == self.handler_gadget then
				handler.mouse_owner = nil
			end
		end,
		NewGadget = function(self)
			local g = {}
			self.handler_gadget = g
			return g
		end,
		AddSyncAction = function(self, cmd, func, help)
			if handler:IsSyncedCode() then
				return nil
			end
			return action_handler.AddSyncAction(self.handler_gadget, cmd, func, help)
		end,
		RemoveSyncAction = function(self, cmd)
			if handler:IsSyncedCode() then
				return nil
			end
			return action_handler.RemoveSyncAction(self.handler_gadget, cmd)
		end,
	}
end

--- @class GadgetHandler: AddonHandler
local GadgetHandler = AddonHandler.new(callins, {
	wrapper_func = wrap_gadget_handler,
	log_section = "Gadget",
	system = VFS.Include("LuaRules/system.lua"),
	validation_func = function(_, gadget)
		if gadget.GetTooltip and not gadget.IsAbove then
			return "Gadget has GetTooltip() but not IsAbove()"
		end
		if gadget.TweakGetTooltip and not gadget.TweakIsAbove then --- @diagnostic disable-line undeclared-fields
			return "Gadget has TweakGetTooltip() but not TweakIsAbove()"
		end
		return nil
	end,
})

GadgetHandler:LoadFromDirectory(GADGETS_PATH)

return GadgetHandler
