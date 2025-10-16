--!strict
--[[
	@class TokenService
	
	> [A token-based service to assist in validating intentions to become actions on the server].
	
	Example:
		```lua
		local tokenService = TokenService.new()
		local token = tokenService:issue(player, "jump", { ["intent"] = args }, 0.1)
		local payload, msg = tokenService:consume(player, token, "jump")
		```
	
		> Author: @Bykhovsky
		> Updated: 10/16/2025
]]--

local HttpService = game:GetService("HttpService")

local TokenService = {}
TokenService.__index = TokenService

function TokenService.new()
	return setmetatable({ store = {} }, TokenService)
end

function TokenService:_bucketFor(player: Player)
	local b = self.store[player]
	if not b then b = {}
		self.store[player] = b
		player.AncestryChanged:Connect(function(_, parent)
			if not parent then self.store[player] = nil end
		end)
	end; return b
end

function TokenService:issue(player: Player, action: string, payload: {}?, ttlSec: number): string
	local bucket = self:_bucketFor(player)
	local id = HttpService:GenerateGUID(false)
	bucket[id] = {
		action = action,
		payload = payload or {},
		expiresAt = os.clock() + (ttlSec or 2.0),
	}
	return id
end

function TokenService:consume(player: Player, tokenId, expectedAction): any
	local bucket = self:_bucketFor(player)
	local rec = bucket[tokenId]
	if not rec then return nil, "invalid" end
	bucket[tokenId] = nil
	if rec.action ~= expectedAction then return nil, "wrong_action" end
	if os.clock() > rec.expiresAt then return nil, "expired" end
	return rec.payload, "success"
end

return TokenService
