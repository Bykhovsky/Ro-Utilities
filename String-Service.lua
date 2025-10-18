--!strict
--[[
	@class StringService
	
	> [Contains string-related high-usage functions]
	
	Methods:
		* FormatNumber(num: number) -> string
		* ParseColor(str: string, asColor3?: boolean) -> (number, number, number) | Color3
		* Truncate(str: string, num: number) -> string
		* Interpolate(str: string, vars: {[string]: any}) -> string
		* IsEmpty(str: string) -> boolean
		* Slugify(str: string) -> string
		* FormatDuration(seconds: number, short?: boolean) -> string
		* ParseVector3(str: string) -> Vector3
		* ParseVector2(str: string) -> Vector2
		* ParseUDim2(str: string) -> UDim2
		* ParseCFrame(str: string) -> CFrame
		* Serialize(value: any) -> string
		* Deserialize(str: string) -> any
		* PadLeft(str: string, len: number, char: string) -> string
		* PadRight(str: string, len: number, char: string) -> string
	
		> Author: @Bykhovsky
		> Updated: 10/18/2025
]]--
local StringService = {}

local HttpService = game:GetService("HttpService")

StringService.NumberSuffixes = {
	[1] = "K",[2] = "M",[3] = "B",
	[4] = "T",[5] = "Qa",[6] = "Qi",
	[7] = "Sx",[8] = "Sp",[9] = "Oc",
	[10] = "No",[11] = "De",[12] = "Ud",
	[13] = "Dd",[14] = "Td",[15] = "Qad",
	[16] = "Qid",[17] = "Sxd",[18] = "Spd",
	[19] = "Ocd",[20] = "Nod",[21] = "Vg"
}

--[[
	FormatNumber(num: number) -> string
	> Converts a number to a string with a suffix.
	* Suffixes: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, De, Ud, Dd, Td, Qad, Qid, Sxd, Spd, Ocd, Nod, Vg
	
	Examples:
		FormatNumber(1250) -> "1.25K"
		FormatNumber(1250000) -> "1.25M"
		
	Use case:
		Displaying large numbers in a more readable format.
	
	- @param num number
	- @return string
]]--
function StringService:FormatNumber(num : number) : string
	if type(num) ~= "number" or num ~= num then return "NaN" end
	if num < 1000 then return tostring(math.floor(num)) end

	local magnitude = math.floor(math.log10(num) / 3)
	local suffix = StringService.NumberSuffixes[magnitude]

	if not suffix then
		return string.format("%.1fe+%d", num / 10 ^ (magnitude * 3), magnitude * 3)
	end

	local shortNum = num / (10 ^ (magnitude * 3))
	return string.format("%.1f%s", shortNum, suffix)
end

--[[
	Truncate(str: string, num: number) -> string
	> Shorten long strings and append "..." when truncated.

	Examples:
		StringService:Truncate("Hello world", 8)  -> "Hello..."
		StringService:Truncate("Short", 10)       -> "Short"

	Use case:
		Useful for UI labels, tooltips, notifications where text must fit a fixed width.
		
	- @param str string
	- @param maxLen number
	- @return string
]]--
function StringService:Truncate(str: string, maxLen: number): string
	if type(str) ~= "string" or type(maxLen) ~= "number" then
		error("Bad argument to Truncate")
	end

	if #str <= maxLen then return str end
	if maxLen <= 3 then return str:sub(1, maxLen) end

	return str:sub(1, maxLen - 3) .. "..."
end

--[[
	Interpolate(str: string, vars: {[string]: any}) -> string
	> Replace tokens in the format "{key}" with values from a table.

	Examples:
		StringService:Interpolate("Hello {name}", { name = "Sam" })               -> "Hello Sam"
		StringService:Interpolate("{g} + {g} = {sum}", { g = "x", sum = "2x" })   -> "x + x = 2x"

	Use case:
		Simple templating for UI text, debug messages, or localizable strings.
		If a key is missing, it leaves the placeholder intact.
		
	- @param str string
	- @param vars table
	- @return string
]]--
function StringService:Interpolate(str: string, vars: {[string]: any}): string
	if type(str) ~= "string" or type(vars) ~= "table" then
		error("Bad argument to Interpolate: expected (string, table)")
	end
	return (str:gsub("{(.-)}", function(key)
		local val = vars[key]
		if val == nil then return "{" .. key .. "}" end
		return tostring(val)
	end))
end

--[[ 
	IsEmpty(str: string) -> boolean
	> Returns true if the string is nil, empty, or whitespace only.
	
	Examples:
		StringService:IsEmpty("")        -> true
		StringService:IsEmpty("   ")     -> true
		StringService:IsEmpty("Hello")   -> false
	
	Use case:
		Validating text inputs or optional fields.
		
	- @param str string
	- @return boolean
]]--
function StringService:IsEmpty(str: string?): boolean
	if str == nil then return true end
	return str:match("^%s*$") ~= nil
end

--[[ 
	Slugify(str: string) -> string
	> Converts a string into a lowercase, hyphen-separated identifier.
	
	Examples:
		StringService:Slugify("Hello World!")      -> "hello-world"
		StringService:Slugify("  My@Script_Name ") -> "my-script-name"
	
	Use case:
		File-safe / key-safe names for saving, URLs, or folder references.
		
	- @param str string
	- @return string
]]--
function StringService:Slugify(str: string): string
	local slug = string.lower(str)

	slug = slug:gsub("[^A-Za-z0-9 %-]", "")
	slug = slug:gsub("%s+", "-")
	slug = slug:gsub("%-+", "-")
	slug = slug:gsub("^%-+", ""):gsub("%-+$", "")

	return slug
end

--[[ 
	FormatDuration(seconds: number, short?: boolean) -> string
	> Converts seconds into a human-friendly duration string.
	
	Examples:
		StringService:FormatDuration(3661)         -> "1h 1m 1s"
		StringService:FormatDuration(61, true)     -> "1:01"
		StringService:FormatDuration(7325, true)   -> "2:02:05"
	
	Use case:
		Display total playtime, cooldowns, or durations cleanly.
		
	- @param seconds number
	- @param short boolean? (default: false)
	- @return string
]]--
function StringService:FormatDuration(seconds: number, short: boolean?): string
	if type(seconds) ~= "number" then return "NaN" end
	seconds = math.floor(math.max(seconds, 0))

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if short then
		if hours > 0 then
			return string.format("%d:%02d:%02d", hours, minutes, secs)
		else
			return string.format("%d:%02d", minutes, secs)
		end
	else
		local parts = {}
		if hours > 0 then table.insert(parts, hours .. "h") end
		if minutes > 0 then table.insert(parts, minutes .. "m") end
		table.insert(parts, secs .. "s")
		return table.concat(parts, " ")
	end
end

-- // ======================================================
-- // 	PARSING & SERIALIZATION
-- // ======================================================

--[[
	ParseColor(str: string, asColor3?: boolean) -> (number, number, number) | Color3
	> Parses "r, g, b" text input into RGB components or Color3.
	
	Examples:
		StringService:ParseColor("255, 0, 255")         -> 255, 0, 255
		StringService:ParseColor("128, 200, 50", true)  -> Color3.fromRGB(128,200,50)
	
	Use case:
		Convert string input fields into usable color values.
		
	- @param str string
	- @param asColor3 boolean? (defaults to false)
	- @return number | Color3
]]--
function StringService:ParseColor(str: string, asColor3: boolean?): Color3 | number
	local rStr, gStr, bStr = str:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
	if not rStr or not gStr or not bStr then
		if asColor3 then
			return Color3.new(0,0,0)
		else
			return 0,0,0
		end
	end

	local r = math.clamp(tonumber(rStr) or 0, 0, 255)
	local g = math.clamp(tonumber(gStr) or 0, 0, 255)
	local b = math.clamp(tonumber(bStr) or 0, 0, 255)

	if asColor3 then
		return Color3.fromRGB(r,g,b)
	end
	return r,g,b
end

--[[
	ParseVector3(str: string) -> Vector3
	> Parses a string into Vector3
	
	Example:
		```lua
		ParseVector3("1, 2, 3") -> Vector3.new(1,2,3)
		```
	
	Use case:
		Useful for returning a Vector3 from a string input.
	
	- @param str string
	- @return Vector3
]]
function StringService:ParseVector3(str: string): Vector3?
	local x, y, z = str:match("(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)")
	if x and y and z then
		return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
	end
	return nil
end

--[[
	ParseVector2(str: string) -> Vector2
	> Parses a string into Vector2
	
	Example:
		```lua
		ParseVector2("(10, 5)") -> Vector2.new(10,5)
		```
	
	Use case:
		Useful for returning a Vector2 from a string input.
	
	- @param str string
	- @return Vector2
]]--
function StringService:ParseVector2(str: string): Vector2?
	local x, y = str:match("(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)")
	if x and y then
		return Vector2.new(tonumber(x), tonumber(y))
	end
	return nil
end

--[[
	ParseUDim2(str: string) -> UDim2
	> Parses a string into UDim2
	
	Example:
		```lua
		ParseUDim2("0.5, 0, 1, -50") -> UDim2.new(0.5,0,1,-50)
		```
		
	Use case:
		Useful for returning a UDim2 from a string input.
	
	- @param str string
	- @return UDim2
]]
function StringService:ParseUDim2(str: string): UDim2?
	local sx, ox, sy, oy = str:match("(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)")
	if sx and ox and sy and oy then
		return UDim2.new(tonumber(sx), tonumber(ox), tonumber(sy), tonumber(oy))
	end
	return nil
end

--[[
	ParseCFrame(str: string) -> CFrame
	> Parses a string into CFrame
	> Also supports full matrix (rarely needed).
	
	Example:
		```lua
		ParseCFrame("1,2,3") or "1 2 3" -> CFrame.new(1,2,3)
		```
	
	Use case:
		Useful for returning a CFrame from a string input.
	
	- @param str string
	- @return CFrame
]]
function StringService:ParseCFrame(str: string): CFrame?
	local nums: {any} = {}
	for n in str:gmatch("%-?[%d%.]+") do
		table.insert(nums, tonumber(n))
	end

	if #nums == 3 then
		return CFrame.new(nums[1], nums[2], nums[3])
	elseif #nums == 12 then
		return CFrame.new(nums[1], nums[2], nums[3],
			nums[4], nums[5], nums[6],
			nums[7], nums[8], nums[9],
			nums[10], nums[11], nums[12])
	end

	return nil
end

--[[
	Serialize(value: any): string
	> Converts most Roblox datatypes into a readable string.
	> Supports tables, primitives, Color3, Vector2/3, UDim2, CFrame.
	
	Example:
		```lua
		Serialize({1,2,3}) -> "{1,2,3}"
		```
	
	Use case:
		Useful for logging or debugging complex data structures.
	
	- @param value any
	- @return string
]]
function StringService:Serialize(value: any): string
	local t = typeof(value)
	if t == "number" or t == "boolean" then
		return tostring(value)
	elseif t == "string" then
		return string.format("%q", value)
	elseif t == "Color3" then
		local r, g, b = math.floor(value.R * 255), math.floor(value.G * 255), math.floor(value.B * 255)
		return string.format("Color3.fromRGB(%d,%d,%d)", r, g, b)
	elseif t == "Vector3" then
		return string.format("Vector3.new(%.3f,%.3f,%.3f)", value.X, value.Y, value.Z)
	elseif t == "Vector2" then
		return string.format("Vector2.new(%.3f,%.3f)", value.X, value.Y)
	elseif t == "UDim2" then
		return string.format("UDim2.new(%.3f,%d,%.3f,%d)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
	elseif t == "CFrame" then
		return "CFrame.new(" .. table.concat({value:GetComponents()}, ",") .. ")"
	elseif t == "table" then
		local success, result = pcall(function() return HttpService:JSONEncode(value) end)
		if success then return result end
		return "{table}"
	else
		return "<" .. t .. ">"
	end
end

--[[
	Deserialize(str: string): any
	> Converts a serialized representation back into a value.
	> Only supports safe value types (numbers, booleans, strings, vectors, colors, etc.)
	
	Example:
		```lua
		Deserialize("Vector3.new(1,2,3)") -> Vector3.new(1,2,3)
		```
	
	Use case:
		Deserializing data for logging, saving, or passing to other systems.
	
	- @param str string
	- @return any
]]
function StringService:Deserialize(str: string): any
	if not str or str == "" then return nil end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(str)
	end)
	if ok then return decoded end

	local v3 = self:ParseVector3(str)
	if v3 then return v3 end

	local v2 = self:ParseVector2(str)
	if v2 then return v2 end

	local ud = self:ParseUDim2(str)
	if ud then return ud end

	local cf = self:ParseCFrame(str)
	if cf then return cf end

	local r,g,b = str:match("(%d+),%s*(%d+),%s*(%d+)")
	if r and g and b then
		return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
	end

	return str
end

--[[
	PadLeft(str: string, len: number, char: string) -> string
	> Pads a string on the left with a specified character to a certain length.
	
	Example:
		```lua
		PadLeft("42", 5, "0") -> "00042"
		```
	
	Use case:
		Formatting numbers or codes with fixed widths.
	
	- @param str string
	- @param len number
	- @param char string
	- @return string
]]
function StringService:PadLeft(str: string, len: number, char: string): string
	char = char or " "
	if #str >= len then return str end
	return string.rep(char, len - #str) .. str
end

--[[
	PadRight(str: string, len: number, char: string) -> string
	> Pads a string on the right with a specified character to a certain length.
	
	Example:
		```lua
		PadRight("42", 5, "_") -> "42___"
		```
	
	Use case:
		Formatting numbers or codes with fixed widths.
	
	- @param str string
	- @param len number
	- @param char string
	- @return string
]]
function StringService:PadRight(str: string, len: number, char: string): string
	char = char or " "
	if #str >= len then return str end
	return str .. string.rep(char, len - #str)
end

return StringService
