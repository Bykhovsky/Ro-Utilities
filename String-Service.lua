--!strict
--[[
	@class StringService
	
	> [Contains string-related high-usage functions]
	
		> Author: @Bykhovsky
		> Updated: 10/16/2025
]]--
local StringService = {}

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
	FormatNumber(num) -> string
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
	ParseColor(str [, asColor3]) -> (number, number, number) | Color3
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
	Truncate(str, num) -> string
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
	Interpolate(str, table) -> string
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
	IsEmpty(str) -> boolean
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
	Slugify(str) -> string
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
	FormatDuration(seconds, short) -> string
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

return StringService
