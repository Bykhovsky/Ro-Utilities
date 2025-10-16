--!strict
--[[
	@class UIService
	
	> [UIService provides further UI-related functionality on the client]
	
		> Author: @Bykhovsky
		> Updated: 10/16/2025
]]--

local UIService = {}
UIService.__index = UIService

local PlayersService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

function UIService.new()
	local self = setmetatable({}, UIService)
	
	self.Player = PlayersService.LocalPlayer
	self.Mouse = self.Player:GetMouse()
	self.UITypes = {}
	
	return self
end

--[[
	isMouseInGUIObj(frame) -> boolean
	> Checks if the mouse is hovering over a GUI object.
	
	Examples:
		```lua
		repeat wait() until isMouseInGUIObj(frame) == false
		```
		
	Use case:
		- Useful for UI designs that involve mouse-hover detections
	
	@param frame GuiObject
	@return boolean
]]--
function UIService:isMouseInGUIObj(frame: GuiObject): boolean
	local Y = frame.AbsolutePosition.Y <= self.Mouse.Y and self.Mouse.Y <= frame.AbsolutePosition.Y + frame.AbsoluteSize.Y
	local X = frame.AbsolutePosition.X <= self.Mouse.X and self.Mouse.X <= frame.AbsolutePosition.X + frame.AbsoluteSize.X
	return (Y and X)
end

--[[
	createDraggable(frame, tweenInfo) -> {}
	> Creates a draggable frame with tween parameters.
	
	Examples:
		```lua
		local connectDrag = createDraggable(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		```
		
	Use case:
		- Viable for making frames draggable in a smoother and more consistent manner (Currently roblox's drag isn't up to par).
	
	@param frame GuiObject
	@param tweenInfo TweenInfo
	@return {} -- Connections
]]--
function UIService:createDraggable(frame: GuiObject, tweenInfo: TweenInfo): {}
	local connections = {}
	local dragging, dragInput, dragStart, startPos
	table.insert(connections, frame.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = frame.Position
			local con = nil; con = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false; con:Disconnect() end
			end)
		end
	end))
	table.insert(connections, frame.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input: InputObject) 
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			local xScale, xOffset = startPos.X.Scale, startPos.X.Offset
			local yScale, yOffset = startPos.Y.Scale, startPos.Y.Offset
			TweenService:Create(frame, tweenInfo, { ["Position"] = UDim2.new(xScale, xOffset + delta.X, yScale, yOffset + delta.Y) }):Play()
		end	
	end))
	return connections
end

--[[
	AddUIType(name, function)
	> Adds a UI type to be called when the UI-functionality is created.
	
	Examples:
		```lua
		AddUIType("TextButton", function(uiObject: GuiObject, arguments: {}, fn: () -> ())
			uiObject.MouseButton1Click:Connect(function()
				print("Clicked")
				coroutine.wrap(fn)(arguments)
			end)
			
			uiObject.MouseEnter:Connect(function()
				uiObject.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
				repeat task.wait() until not UIService:isMouseInGUIObj(uiObject)
				uiObject.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end)
		end)
		```
		
	Use case:
		- is a necessity for adding functionality to UI elements, as well as being the counterpart for AddFunction.
	
	@param name string
	@param fn (uiObject: GuiObject, arguments: {}, fn: () -> ()) -> ()
]]--
function UIService:AddUIType(name: string, fn: () -> ())
	self.UITypes[name] = fn
end

--[[
	AddFunction(_type, uiObject, fn)
	> Adds functionality to the uiObject with a specified functionality-type and an associated behavior.
	
	Examples:
		```lua
		AddFunction("TextButton", ATextButton, function(arguments: {})
			print("Click received!")
		end)
		```
		
	Use case:
		- Works in conjunction with AddUIType to add functionality to UI elements.
	
	@param _type string
	@param uiObject GuiObject
	@param fn () -> ()
]]--
function UIService:AddFunction(_type: string, uiObject: GuiObject, fn: () -> ())
	if self.UITypes[_type] then self.UITypes[_type](uiObject, {}, fn) end
end

return UIService
