--!strict
--[[
	@class ManagerService
	
	> [Advanced resource cleanup manager]
	
		> Author: @Bykhovsky
		> Updated: 10/17/2025
	
	Notes:
		- Tracks resources in both an indexed list (for deterministic cleanup order) and a keyed map (for Get/Remove by name).
		- Attempts reasonable heuristics to cleanup objects if no explicit cleanup provided:
			* RBXScriptConnection -> Disconnect
			* Instance -> Destroy
			* Table with Destroy/Disconnect -> Call
			* Function -> Call
		- Call: Clean() deterministically to avoid leaks.
		- ManagerService has a registry (for diagnostics/reporting)
]]--

type CleanupFunc = (any) -> ()

export type ManagerServiceType = {
	_name: string?,
	_items: { any },
	_keys: { [string]: any },
	_indexMap: { [number]: any },
	_cleaned: boolean,
	Add: (self: ManagerServiceType, item: any, cleanup: (string | CleanupFunc)?) -> number,
	Give: (self: ManagerServiceType, key: string, item: any, cleanup: (string | CleanupFunc)?) -> (),
	Get: (self: ManagerServiceType, key: string) -> any,
	Remove: (self: ManagerServiceType, keyOrIndex: any, keepItem: boolean?) -> any,
	Clean: (self: ManagerServiceType) -> (),
	Destroy: (self: ManagerServiceType) -> (),
	BindToInstance: (self: ManagerServiceType, inst: Instance) -> (),
	After: (self: ManagerServiceType, delayTime: number, fn: () -> ()) -> number,
	IsCleaned: (self: ManagerServiceType) -> boolean,
	_push: (self: ManagerServiceType, itemRecord: { item: any, cleanup: CleanupFunc }) -> number,
}

local ManagerService: any = {}
ManagerService.__index = ManagerService

local registry: { [number]: { manager: ManagerServiceType, createdTrace: string } } = {}
setmetatable(registry, { __mode = "v" })

local function isConnection(obj: any): boolean
	return typeof(obj) == "RBXScriptConnection"
end

local function isInstance(obj: any): boolean
	if type(obj) == "userdata" or type(obj) == "table" then
		local ok, res = pcall(function() return obj and obj:IsA("Instance") end)
		return ok and res == true
	end
	return false
end

local function defaultCleanupFor(item: any): (any) -> ()
	if item == nil then
		return function() end
	end

	if isConnection(item) then
		return function()
			pcall(function() item:Disconnect() end)
		end
	end

	if isInstance(item) then
		return function()
			if item and item.Destroy then
				pcall(function() item:Destroy() end)
			end
		end
	end

	if type(item) == "table" then
		if type(item.Destroy) == "function" then
			return function() pcall(function() (item :: any):Destroy() end) end
		elseif type(item.Disconnect) == "function" then
			return function() pcall(function() (item :: any):Disconnect() end) end
		end
	end

	if type(item) == "function" then
		return function() pcall(item) end
	end

	return function() end
end

local function makeCleanup(funcOrMethod: (string | CleanupFunc)?, item: any): CleanupFunc
	if type(funcOrMethod) == "string" and item ~= nil then
		local methodName: string = funcOrMethod
		return function()
			pcall(function()
				local method = item[methodName]
				if type(method) == "function" then
					(method :: any)(item)
				end
			end)
		end
	elseif type(funcOrMethod) == "function" then
		return function()
			pcall(function() (funcOrMethod :: CleanupFunc)(item) end)
		end
	else
		return defaultCleanupFor(item)
	end
end

function ManagerService.new(name: string?): ManagerServiceType
	local raw = {
		_name = name,
		_items = {},
		_keys = {},
		_indexMap = {},
		_cleaned = false,
	}
	setmetatable(raw, ManagerService)

	local self: ManagerServiceType = (raw :: any) :: ManagerServiceType

	local trace = debug.traceback(nil, 2)
	local id = tick() + math.random()
	registry[id] = { manager = self, createdTrace = trace }

	return self
end

function ManagerService:_push(itemRecord: { item: any, cleanup: CleanupFunc }): number
	local idx: number = #self._items + 1
	self._items[idx] = itemRecord
	self._indexMap[idx] = itemRecord
	return idx
end

function ManagerService:Add(item: any, cleanup: (string | CleanupFunc)?): number
	assert(not self._cleaned, "ManagerService: Add called after Clean()")
	local cleanupFn = makeCleanup(cleanup, item)
	local record = { item = item, cleanup = cleanupFn }
	local idx = self:_push(record)
	return idx
end

function ManagerService:Give(key: string, item: any, cleanup: (string | CleanupFunc)?): ()
	assert(type(key) == "string", "ManagerService: Give key must be string")
	assert(not self._cleaned, "ManagerService: Give called after Clean()")
	local cleanupFn = makeCleanup(cleanup, item)
	self._keys[key] = { item = item, cleanup = cleanupFn }
end

function ManagerService:Get(key: string): any
	return self._keys[key] and self._keys[key].item or nil
end

function ManagerService:Remove(keyOrIndex: any, keepItem: boolean?): any
	if type(keyOrIndex) == "string" then
		local rec = self._keys[keyOrIndex]
		if not rec then
			return nil
		end
		local item = rec.item
		if not keepItem then
			pcall(rec.cleanup)
		end
		self._keys[keyOrIndex] = nil
		return item
	end

	if type(keyOrIndex) == "number" then
		local rec = self._indexMap[keyOrIndex]
		if not rec then
			return nil
		end
		local item = rec.item
		if not keepItem then
			pcall(rec.cleanup)
		end
		self._items[keyOrIndex] = nil
		self._indexMap[keyOrIndex] = nil
		return item
	end

	for k, rec in pairs(self._keys) do
		if rec.item == keyOrIndex then
			local item = rec.item
			if not keepItem then
				pcall(rec.cleanup)
			end
			self._keys[k] = nil
			return item
		end
	end

	for i, rec in self._items do
		if rec and rec.item == keyOrIndex then
			local item = rec.item
			if not keepItem then
				pcall(rec.cleanup)
			end
			self._items[i] = nil
			self._indexMap[i] = nil
			return item
		end
	end

	return nil
end

function ManagerService:After(delayTime: number, fn: () -> ()): number
	assert(type(delayTime) == "number" and delayTime >= 0, "ManagerService:After - invalid delay")
	assert(type(fn) == "function", "ManagerService:After - fn must be function")
	assert(not self._cleaned, "ManagerService:After called after Clean()")

	local handle: { cancelled: boolean } = { cancelled = false }
	local connectionIndex = self:Add(handle, function(h)
		h.cancelled = true
	end)

	task.delay(delayTime, function()
		if handle.cancelled then
			return
		end
		self:Remove(connectionIndex, true)
		pcall(fn)
	end)

	return connectionIndex
end

function ManagerService:BindToInstance(inst: Instance)
	assert(isInstance(inst), "ManagerService: BindToInstance expects an Instance")
	local ok, _ = pcall(function() return inst.Parent == nil and not inst:IsDescendantOf(game) end)
	local connection: RBXScriptConnection
	if inst.Destroying then
		connection = inst.Destroying:Connect(function()
			self:Clean()
		end)
	else
		connection = inst.AncestryChanged:Connect(function()
			if not inst or not inst:IsDescendantOf(game) then
				self:Clean()
			end
		end)
	end

	self:Add(connection)
end

function ManagerService:IsCleaned(): boolean
	return self._cleaned == true
end

function ManagerService:Clean()
	if self._cleaned then
		return
	end
	self._cleaned = true

	for k, rec in pairs(self._keys) do
		pcall(rec.cleanup)
		self._keys[k] = nil
	end

	for i = #self._items, 1, -1 do
		local rec = self._items[i]
		if rec then
			pcall(rec.cleanup)
			self._items[i] = nil
			self._indexMap[i] = nil
		end
	end

	for id, entry in pairs(registry) do
		if entry.manager == self then
			registry[id] = nil
		end
	end
end

function ManagerService:Destroy()
	return self:Clean()
end

function ManagerService.ReportLeaks()
	local found = false
	for id, entry in pairs(registry) do
		if entry and entry.manager and not entry.manager._cleaned then
			found = true
			warn(("[ManagerService] Potential leak: Manager created at:\n%s"):format(entry.createdTrace))
		end
	end
	if not found then
		print("[ManagerService] No manager leaks detected.")
	end
end

setmetatable(ManagerService, {
	__call = function(_, ...)
		return ManagerService.new(...)
	end,
})

return ManagerService
