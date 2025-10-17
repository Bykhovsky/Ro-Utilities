--!strict
--[[
	@class RagdollService
		
		> Robust ragdoll utility for characters.
	
	API:
		local RagdollService = require(RagdollService)
		local ragdollManager = RagdollService.new(player, config?)
		
		Player:SetAttribute("Ragdoll", 1) -> alternative to ragdoll from any server script
		ragdollManager:Ragdoll(seconds)   -> increment ragdoll timer by seconds (clamped)
		ragdollManager:Toggle(true/false) -> force a ragdoll state on a player
		ragdollManager:Destroy()          -> cleanup and restore humanoid properties
	
	
	> Author: @Bykhovsky
	> Updated: 10/17/2025
	> Version: 1.0.0
]]--

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")

local RagdollService = {}
RagdollService.__index = RagdollService

local DEFAULT_CONFIG = {
	MAX_RAGDOLL_TIME = 10,
	UNEQUIPS_TOOLS = true,
	RESETS_ON_DEATH = true,
	COLLIDABLE_PARTS = true,
	RAGDOLL_ON_DEATH = true,
	SETUP_COLLISIONS = true,
	COLLISIONS_NAME = "Player",
	BLACKLISTED_PARTS = { "Head", "HumanoidRootPart" },
	DEFAULT_HUMANOID_PROPERTIES = {
		RequiresNeck = true,
		BreakJointsOnDeath = true,
	},
	DEBUG = false,
	TAG_CREATED = false,
}

local CREATED_CLASSNAMES = {
	BallSocketConstraint = true,
	Attachment = true,
	WeldConstraint = true,
	Part = true,
}

local function shallowCopy(orig)
	local out = {}
	for k,v in pairs(orig) do out[k] = v end
	return out
end

local function mergeConfig(userConfig: { [any]: any })
	if not userConfig then return shallowCopy(DEFAULT_CONFIG) end
	local out = shallowCopy(DEFAULT_CONFIG)
	for k,v in pairs(userConfig) do out[k] = v end
	out.BLACKLISTED_PARTS = out.BLACKLISTED_PARTS or {}
	return out
end

local function safeDisconnect(conn)
	if conn and typeof(conn) == "RBXScriptConnection" then
		pcall(function() conn:Disconnect() end)
	end
end

local function newAttachmentName()
	return ("RagdollAT_%s"):format(tostring(HttpService:GenerateGUID(false)))
end

function RagdollService.new(player: Player, userConfig: {})
	assert(player and player:IsA("Player"), "RagdollService.new expects a Player")

	local self = setmetatable({}, RagdollService)

	self.Player = player
	self.Config = mergeConfig(userConfig)
	self.Connections = {}
	self.ActiveInstances = {}
	self.ActiveMotors = {}
	self._ragdollTime = 0
	self.Ragdolled = false
	self.Died = false
	self._humanoidOriginalProps = {}
	self._createdTrace = self.Config.DEBUG and debug.traceback(nil, 2) or nil

	self.Player:SetAttribute("Ragdoll", 0)

	if self.Player.Character and self.Player.Character.PrimaryPart then
		pcall(function() self:BindToCharacter(self.Player.Character) end)
	end

	table.insert(self.Connections, self.Player:GetAttributeChangedSignal("Ragdoll"):Connect(function()
		local v = self.Player:GetAttribute("Ragdoll")
		if v == nil or self.Died then return end
		self:Toggle(v > 0)
	end))

	table.insert(self.Connections, RunService.Heartbeat:Connect(function(deltaTime)
		local attr = self.Player:GetAttribute("Ragdoll")
		if attr == nil then return end
		if self.Ragdolled and attr > 0 then
			self._ragdollTime = math.max(0, attr - deltaTime)
			self._ragdollTime = math.clamp(self._ragdollTime, 0, self.Config.MAX_RAGDOLL_TIME)
			if math.abs(self._ragdollTime - attr) > 1e-6 then
				self.Player:SetAttribute("Ragdoll", self._ragdollTime)
			end
		end
		
		local character = self.Player.Character
		if character then
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			if humanoid and humanoid.Health <= 0 and not self.Died then
				self.Died = true
				if humanoid.PlatformStand then
					pcall(function() humanoid.PlatformStand = false end)
				end
				if self.Config.RAGDOLL_ON_DEATH then
					pcall(function() self:Toggle(true) end)
				end
			end
		end
	end))
	
	table.insert(self.Connections, self.Player.CharacterAdded:Connect(function(char)
		self:BindToCharacter(char)
	end))

	return self
end

function RagdollService:Ragdoll(seconds: number)
	if type(seconds) ~= "number" or seconds <= 0 then return end
	local current = self.Player:GetAttribute("Ragdoll") or 0
	local nextVal = math.clamp(current + seconds, 0, self.Config.MAX_RAGDOLL_TIME)
	self.Player:SetAttribute("Ragdoll", nextVal)
end

function RagdollService:BindToCharacter(character: Model)
	if not character or not character:IsA("Model") then return end
	local humanoid: Humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid or character:WaitForChild("Humanoid") :: Humanoid
	if not humanoid then return end

	self._humanoidOriginalProps["RequiresNeck"] = humanoid["RequiresNeck"]
	self._humanoidOriginalProps["BreakJointsOnDeath"] = humanoid["BreakJointsOnDeath"]
	humanoid["RequiresNeck"] = false; humanoid["BreakJointsOnDeath"] = false

	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	end)

	if self.Config.RESETS_ON_DEATH then
		self.Player:SetAttribute("Ragdoll", 0)
	end

	if self.Config.SETUP_COLLISIONS then
		pcall(function()
			if not PhysicsService:IsCollisionGroupRegistered(self.Config.COLLISIONS_NAME) then
				PhysicsService:RegisterCollisionGroup(self.Config.COLLISIONS_NAME)
			end
			PhysicsService:CollisionGroupSetCollidable(self.Config.COLLISIONS_NAME, self.Config.COLLISIONS_NAME, false)
		end)

		for _, basepart in pairs(character:GetDescendants()) do
			if basepart:IsA("BasePart") then
				pcall(function() basepart.CollisionGroup = self.Config.COLLISIONS_NAME end)
			end
		end
	end
end

local function createRagdollConstraint(motor: Motor6D): { [any]: any }
	local p0 = motor.Part0
	local p1 = motor.Part1
	if not (p0 and p1) then return {} end

	local atName = newAttachmentName()
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")

	a0.Name = atName .. "_0"
	a1.Name = atName .. "_1"

	a0.CFrame = motor.C0
	a1.CFrame = motor.C1

	a0.Parent = p0
	a1.Parent = p1

	local bsc = Instance.new("BallSocketConstraint")
	bsc.Attachment0 = a0
	bsc.Attachment1 = a1
	bsc.LimitsEnabled = true
	bsc.TwistLimitsEnabled = true
	bsc.Parent = motor.Parent

	return { motor = motor, bsc = bsc, a0 = a0, a1 = a1 }
end

function RagdollService:Toggle(enable: boolean)
	if self.Ragdolled == enable then return end

	local character = self.Player.Character
	if not character or not character.PrimaryPart then return end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

	self.Ragdolled = enable
	if enable then
		self.Died = false
		self._ragdollTime = math.clamp(self.Player:GetAttribute("Ragdoll") or 0, 0, self.Config.MAX_RAGDOLL_TIME)
		self.Player:SetAttribute("Ragdoll", self._ragdollTime)

		pcall(function() humanoid.PlatformStand = true end)
		if self.Config.UNEQUIPS_TOOLS then
			pcall(function() humanoid:UnequipTools() end)
		end
		
		for _, joint in pairs(character:GetDescendants()) do
			if joint:IsA("Motor6D") and joint.Parent and joint.Part0 and joint.Part1 then
				if table.find(self.Config.BLACKLISTED_PARTS, joint.Parent.Name) then continue end
				local created = createRagdollConstraint(joint)
				if created and created.bsc and created.a0 and created.a1 then
					table.insert(self.ActiveInstances, created.bsc)
					table.insert(self.ActiveInstances, created.a0)
					table.insert(self.ActiveInstances, created.a1)
					pcall(function() joint.Enabled = false end)
					table.insert(self.ActiveMotors, joint)
				end
			end
		end
		
		if self.Config.COLLIDABLE_PARTS then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					if string.find(part.Name, "Left") or string.find(part.Name, "Right") then
						local fake = Instance.new("Part")
						fake.Name = "RagdollFake"
						fake.Size = part.Size
						fake.CFrame = part.CFrame
						fake.Anchored = false
						fake.CanCollide = true
						fake.Massless = true
						fake.Transparency = 1
						fake.Parent = part

						local wc = Instance.new("WeldConstraint")
						wc.Part0 = fake
						wc.Part1 = part
						wc.Parent = fake

						table.insert(self.ActiveInstances, wc)
						table.insert(self.ActiveInstances, fake)

						if self.Config.SETUP_COLLISIONS and self.Config.COLLISIONS_NAME then
							pcall(function() fake.CollisionGroup = self.Config.COLLISIONS_NAME end)
						end
						
						if self.Config.TAG_CREATED then
							pcall(function() CollectionService:AddTag(fake, "RagdollService_Temp") end)
						end
					end
				end
			end
		end
	else
		pcall(function() humanoid.PlatformStand = false end)
		pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		
		for i = #self.ActiveMotors, 1, -1 do
			local motor = self.ActiveMotors[i]
			if motor and motor:IsA("Motor6D") then
				pcall(function() motor.Enabled = true end)
			end
			self.ActiveMotors[i] = nil
		end

		for i = #self.ActiveInstances, 1, -1 do
			local inst = self.ActiveInstances[i]
			if inst and typeof(inst) == "Instance" then
				pcall(function()
					if inst.Parent then inst:Destroy() end
				end)
			end
			self.ActiveInstances[i] = nil
		end
		
		self._ragdollTime = 0
		self.Player:SetAttribute("Ragdoll", 0)
	end
end

function RagdollService:Destroy()
	pcall(function() self:Toggle(false) end)
	pcall(function() self.Player:SetAttribute("Ragdoll", nil) end)
	
	for _, conn in ipairs(self.Connections) do
		safeDisconnect(conn)
	end
	table.clear(self.Connections)
	
	local character = self.Player.Character
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			for k,v in pairs(self._humanoidOriginalProps) do
				pcall(function() humanoid[k] = v end)
			end
		end
	end
	
	table.clear(self.ActiveInstances)
	table.clear(self.ActiveMotors)
	self._humanoidOriginalProps = {}
end

return RagdollService
