--!strict
--[[
	@class TableService

	> [TableService extends Roblox's built-in table library with high-utility functions.]

	Methods:
		* DeepCopy(tbl: {}) -> {}
		* Merge(dest: {}, ...others: {}) -> {}
		* Filter(tbl: {}, predicate: (value, key) -> boolean) -> {}
		* Map(tbl: {}, mapper: (value, key) -> any) -> {}
		* Count(tbl: {}, value?: any) -> number
		* IsEmpty(tbl: {}) -> boolean
		* Shuffle(array: {any}) -> {any}
		* Unique(array: {any}) -> {any}
		* Slice(array: {}, start?: number, finish?: number) -> {any}
		* Flatten(tbl: {}) -> {any}
		* ToString(tbl: {}, options?: {indent?: number, ___internal?: boolean}) -> string
		* DeepMerge(target: {}, ...sources: {}) -> {}
		* Keys(tbl: {}) -> {any}
		* Values(tbl: {}) -> {any}
		* Invert(tbl: {}) -> {}
		* AssignDefaults(dest: {}, defaults: {}) -> {}
		* Difference(a: {any}, b: {any}) -> {any}
		* Intersect(a: {any}, b: {any}) -> {any}
		* Chunk(array: {any}, size: number) -> {{any}}
		* Zip(...arrays: {any}) -> {{any}}
		* Unzip(zipped: {{any}}) -> {{any}}
		* GroupBy(array: {any}, fn: (any) -> any) -> {[any]: {any}}
		* Equals(a: {}, b: {}, deep?: boolean) -> boolean
		* FlattenDeep(tbl: {}) -> {any}
		* Reverse(tbl: {any}) -> {any}
	
	> Author: @Bykhovsky
	> Updated: 10/18/2025
]]--

local TableService = {}

--[[
	DeepCopy(tbl: {}) -> {}
	> Creates a deep copy of a table (including nested tables).
	> Handles recursive references safely.
	
	Example:
		```lua
		local t = {a = 1, b = {c = 2}}
		local copy = TableService.DeepCopy(t)
		copy.b.c = 10
		print(t.b.c) --> 2
		```
		
	Use case:
		Deep copies a table to avoid modifying the original.
		
	- @param tbl table
	- @return table
]]--
function TableService:DeepCopy(tbl: {}): {}
	local lookup: {[any]: any} = {}
	
	local function _deepcopy(t: {}): {}
		if lookup[t] then return lookup[t] end
		local copy = {}
		lookup[t] = copy
		for i, v in pairs(t) do
			if type(v) == "table" then
				copy[i] = _deepcopy(v)
			else
				copy[i] = v
			end
		end
		return copy
	end
	
	return _deepcopy(tbl)
end

--[[
	Merge(dest: {}, ...others: {}) -> {}
	> Merges multiple tables into the destination table
	> Later tables override earlier values.
	
	Example:
		```lua
		local base = {a = 1, b = 2}
		local merged = TableService.Merge(base, {b = 10, c = 3})
		print(merged.b, merged.c) --> 10, 3
		```
	
	Use case:
		Useful for combining default settings with user-defined settings.
	
	- @param dest table
	- @param ... table
	- @return table
]]--
function TableService:Merge(dest: {}, ...: {}): {}
	for _, src in pairs({...}) do
		for i, v in pairs(src) do
			dest[i] = v
		end
	end; return dest
end

--[[
	Filter(tbl: {}, predicate: (value, key) -> boolean) -> {}
	> Returns a new table containing only elements where predicate returns true.
	
	Example:
		```lua
		local t = {1,2,3,4,5}
		local evens = TableService.Filter(t, function(v) return v % 2 == 0 end)
		print(table.concat(evens, ",")) --> 2,4
		```
	
	Use case:
		Filtering tables based on custom logic.
	
	- @param tbl table
	- @param predicate (value, key) -> boolean
	- @return table
]]--
function TableService:Filter(tbl: {}, predicate: (any, any) -> boolean): {}
	local result = {}
	for i, v in pairs(tbl) do
		if predicate(v, i) then result[i] = v end
	end; return result
end

--[[
	Map(tbl: {}, mapper: (value, key) -> any) -> {}
	> Returns a new table with mapped values.
	
	Example:
		```lua
		local nums = {1, 2, 3}
		local squares = TableService.Map(nums, function(v) return v * v end)
		print(table.concat(squares, ",")) --> 1,4,9
		```
		
	Use case:
		Transforming table values while preserving keys.
	
	- @param tbl table
	- @param mapper (value, key) -> any
	- @return table
]]--
function TableService:Map(tbl: {}, mapper: (any, any) -> any): {}
	local result = {}
	for i, v in pairs(tbl) do result[i] = mapper(v, i) end
	return result
end

--[[
	Count(tbl: {}, value?: any) -> number
	> If `value` provided, counts its occurrences; otherwise returns key count.
	
	Example:
		```lua
		local t = {a = 1, b = 1, c = 2}
		print(TableService.Count(t, 1)) --> 2
		print(TableService.Count(t)) --> 3
		```
		
	Use case:
		Counting elements or keys in a table.
	
	- @param tbl table
	- @param value any?
	- @return number
]]--
function TableService:Count(tbl: {}, value: any?): number
	local n = 0
	if value ~= nil then
		for _, v in pairs(tbl) do
			if v == value then n += 1 end
		end
	else
		for _ in pairs(tbl) do n += 1 end
	end
	return n
end

--[[
	IsEmpty(tbl: {}) -> boolean
	> Returns true if table has no keys.
	
	Example:
		```lua
		print(TableService.IsEmpty({})) --> true
		print(TableService.IsEmpty({a = 1})) --> false
		```
		
	Use case:
		Checking if a table is empty.
	
	- @param tbl table
	- @return boolean
]]--
function TableService:IsEmpty(tbl: {}): boolean
	return next(tbl) == nil
end

--[[
	Shuffle(array: {any}) -> {any}
	> Returns a new array with randomized order (Fisher-Yates algorithm).
	
	Example:
		```lua
		local shuffled = TableService.Shuffle({1,2,3,4,5})
		print(table.concat(shuffled, ",")) --> random order
		```
		
	Use case:
		Randomizing elements in an array.
	
	- @param array {any}
	- @return {any}
]]--
function TableService:Shuffle(array: {any}): {any}
	local shuffled = table.clone(array)
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end; return shuffled
end

--[[
	Unique(array: {any}) -> {any}
	> Returns array with duplicate values removed.

	Example:
		```lua
		local u = TableService.Unique({1,1,2,3,3})
		print(table.concat(u, ",")) --> 1,2,3
		```
		
	Use case:
		Removing duplicates from an array.
	
	- @param array {any}
	- @return {any}
]]--
function TableService:Unique(array: {any}): {any}
	local seen: {[any]: boolean} = {}
	local result = {}
	for _, v in pairs(array) do
		if not seen[v] then
			seen[v] = true
			table.insert(result, v)
		end
	end; return result
end

--[[
	Slice(array: {}, start?: number, finish?: number) -> {any}
	> Returns sub-array between indices (inclusive)
	
	Example:
		```lua
		local t = {10,20,30,40}
		local s = TableService.Slice(t, 2, 3)
		print(table.concat(s, ",")) --> 20,30
		```
	
	Use case:
		Extracting a sub-array from an array.
	
	- @param array {}
	- @param start number? (defaults to 1)
	- @param finish number? (defaults to #array)
	- @return {any}
]]--
function TableService:Slice(array: {any}, startIndex: number?, endIndex: number?): {any}
	local startI = startIndex or 1
	local endI = endIndex or #array
	local result = {}
	for i = startI, endI do table.insert(result, array[i]) end
	return result
end

--[[
	Flatten(tbl: {}) -> {any}
	> Flattens nested arrays into a single array.
	
	Example:
		```lua
		local nested = {1, {2, 3}, {4, {5}}}
		local flat = TableService.Flatten(nested)
		print(table.concat(flat, ",")) --> 1,2,3,4,5
		```
	
	Use case:
		Reducing nested arrays to a single array.
	
	- @param tbl {}
	- @return {any}
]]--
function TableService:Flatten(tbl: {}): {any}
	local result = {}
	local function recurse(t: {})
		for _, v in pairs(t) do
			if type(v) == "table" then
				recurse(v) else table.insert(result, v)
			end
		end
	end
	recurse(tbl); return result
end

--[[
	ToString(tbl: {}, options?: {indent?: number, ___internal?: boolean}) -> string
	> Returns a human-readable representation of a table for debugging.
	> Supports nested indentation
	
	Example:
		```lua
		local t = {a = 1, b = {c = 2}}
		print(TableService.ToString(t)) ->
			{
			  a = 1,
			  b = {
				c = 2,
			  },
			}
		```
	
	Use case:
		Inspecting complex tables for debugging.
	
	- @param tbl {}
	- @param options {}? (optional)
	- @return string
]]--
function TableService:ToString(tbl: {}, options: {indent: number?, ___internal: boolean?}?): string
	local indent = options and options.indent or 0
	local spacing = string.rep(" ", indent)
	local strTbl = {"{"}
	
	for i, v in pairs(tbl) do
		local keyStr = tostring(i)
		local valueStr = ""
		if type(v) == "table" then
			valueStr = TableService.ToString(v, {indent = indent + 2, ___internal = true})
		elseif type(v) == "string" then
			valueStr = string.format("%q", v)
		else
			valueStr = tostring(v)
		end
		table.insert(strTbl, string.format("\n%s  [%s] = %s,", spacing, keyStr, valueStr))
	end
	
	table.insert(strTbl, "\n" .. spacing .. "}")
	return table.concat(strTbl)
end

--[[
	DeepMerge(target: {}, ...sources: {}) -> {}
	> Recursively merges tables. Nested tables are merged, not replaced.
	
	Example:
		```lua
		local a = {info = {x = 1}}
		local b = {info = {y = 2}}
		local merged = TableService.DeepMerge(a, b)
		print(merged.info.x, merged.info.y) --> 1,2
		```
		
	Use case:
		Combining multiple configuration tables without losing nested data.
	
	- @param target {}
	- @param ...sources: {}
	- @return {}
]]--
function TableService:DeepMerge(target: {}, ...: {}): {}
	for _, src in pairs({...}) do
		for i, v in pairs(src) do
			if type(v) == "table" and type(target[i]) == "table" then
				TableService:DeepMerge(target[i], v)
			else
				target[i] = v
			end
		end
	end; return target
end

--[[
	Keys(tbl: {}) -> {any}
	> Returns a list of all keys in a table.
	
	Example:
		```lua
		local t = {a = 1, b = 2, c = 3}
		local keys = TableService.Keys(t) --> {"a", "b", "c"}
		```
		
	Use case:
		Extracting keys from a table for iteration or processing.
		
	- @param tbl {}
	- @return {any}
]]--
function TableService:Keys(tbl: {}) : {any}
	local result = {}
	for i in pairs(tbl) do table.insert(result, i) end
	return result
end

--[[
	Values(tbl: {}) -> {any}
	> Returns a list of all values in a table.
	
	Example:
		```lua
		local t = {a = 1, b = 2, c = 3}
		local values = TableService.Values(t) --> {1, 2, 3}
		```
		
	Use case:
		Extracting values from a table for processing or type checking.
		
	- @param tbl {}
	- @return {any}
]]--
function TableService:Values(tbl: {}): {any}
	local result = {}
	for _, v in pairs(tbl) do table.insert(result, v) end
	return result
end

--[[
	Invert(tbl: {}) -> {}
	> Swaps keys and values. Warning: duplicate values will overwrite.
		
	Example:
		```lua
		print(TableService.Invert({a = 1, b = 2})[1]) --> "a"
		```
		
	Use case:
		Creating a reverse lookup table or swapping keys and values.
		
	- @param tbl {}
	- @return {}
]]--
function TableService:Invert(tbl: {}): {}
	local inverted = {}
	for i, v in pairs(tbl) do inverted[v] = i end
	return inverted
end

--[[
	AssignDefaults(dest: {}, defaults: {}) -> {}
	> Fills in missing keys from defaults without overwriting.
		
	Example:
		```lua
		local target = {a = 1, b = 2}
		TableService.AssignDefaults(target, {b = 3, c = 4})
		print(target) --> {a = 1, b = 2, c = 4}
		```
		
	Use case:
		Setting up default values for a table while preserving existing data.
		
	- @param dest {}
	- @param defaults {}
	- @return {}
]]--
function TableService:AssignDefaults(dest: {}, defaults: {}): {}
	for i, v in pairs(defaults) do
		if dest[i] == nil then dest[i] = v end
	end; return dest
end

--[[
	Difference(a: {any}, b: {any}) -> {any}
	> Returns array of values in A not found in B.
		
	Example:
		```lua
		TableService.Difference({1, 2, 3}, {2, 3, 4}) --> {1, 4}
		```
		
	Use case:
		Identifying unique elements between two tables.
		
	- @param a {any}
	- @param b {any}
	- @return {any}
]]--
function TableService:Difference(a: {any}, b: {any}): {any}
	local result = {}
	local lookup: {[any]: boolean} = {}
	for _, v in pairs(b) do lookup[v] = true end
	for _, v in pairs(a) do if not lookup[v] then table.insert(result, v) end end
	return result
end

--[[
	Intersect(a: {any}, b: {any}) -> {any}
	> Returns array of shared values between A and B.
		
	Example:
		```lua
		TableService.Intersect({1, 2, 3}, {2, 3, 4}) --> {2, 3}
		```
		
	Use case:
		Finding common elements between two tables.
		
	- @param a {any}
	- @param b {any}
	- @return {any}
]]--
function TableService:Intersect(a: {any}, b: {any}): {any}
	local result = {}
	local lookup: {[any]: boolean} = {}
	for _, v in pairs(b) do lookup[v] = true end
	for _, v in pairs(a) do if lookup[v] then table.insert(result, v) end end
	return result
end

--[[
	Chunk(array: {any}, size: number) -> {{any}}
	> Splits an array into chunks of given size.
		
	Example:
		```lua
		local chunks = TableService.Chunk({1,2,3,4,5}, 2) --> {{1,2},{3,4},{5}}
		```
		
	Use case:
		Processing large arrays in smaller, manageable batches.
		
	- @param array {any}
	- @param size number
	- @return {{any}}
]]--
function TableService:Chunk(array: {any}, size: number): {{any}}
	assert(size > 0, "Chunk size must be positive")
	local result = {}
	for i = 1, #array, size do
		local chunk = {}
		for j = i, math.min(i + size - 1, #array) do
			table.insert(chunk, array[j])
		end; table.insert(result, chunk)
	end; return result
end

--[[
	Zip(...arrays: {any}) -> {{any}}
	> Combines multiple arrays into one array of tuples.
		
	Example:
		```lua
		local zipped = TableService.Zip({1,2}, {"a","b"}) --> {{1,"a"}, {2,"b"}}
		```
		
	Use case:
		Aligning corresponding elements from multiple arrays.
		
	- @param ...arrays {any}
	- @return {{any}}
]]--
function TableService:Zip(...: {any}): {{any}}
	local arrays = {...}
	local result = {}
	local minLength = math.huge
	
	for _, arr in pairs(arrays) do
		minLength = math.min(minLength, #arr)
	end
	
	for i = 1, minLength do
		local tuple = {}
		for _, arr in pairs(arrays) do
			table.insert(tuple, arr[i])
		end; table.insert(result, tuple)
	end; return result
end

--[[
	Unzip(zipped: {{any}}) -> {{any}}
	> Inverse of Zip. Transposes tuples back into arrays.
		
	Example:
		```lua
		local unzipped = TableService.Unzip({{1,"a"}, {2,"b"}}) --> {{1,2}, {"a","b"}}
		```
		
	Use case:
		Reversing the alignment of elements from multiple arrays.
	
	- @param zipped {{any}}
	- @return {{any}}
]]--
function TableService:Unzip(zipped: {{any}}): {{any}}
	local result: {{any}} = {}
	if #zipped == 0 then return result end
	
	for i = 1, #zipped[1] do result[i] = {} end
	
	for _, tuple in pairs(zipped) do
		for i, v in pairs(tuple) do table.insert(result[i], v) end
	end; return result
end

--[[
	GroupBy(array: {any}, fn: (any) -> any) -> {[any]: {any}}
	> Groups elements by a computed key.
	
	Example:
	```lua
	local animals = {"cat", "cow", "dog", "donkey"}
	local grouped = TableService.GroupBy(animals, function(a) return a:sub(1,1) end)
	-- { c = {"cat","cow"}, d = {"dog","donkey"} }
	```
	
	Use case:
		Creating a dictionary where each key corresponds to a group of elements.
	
	- @param array {any}
	- @param fn (any) -> any
	- @return {[any]: {any}}
]]--
function TableService:GroupBy(array: {any}, fn: (any) -> any): {[any]: {any}}
	local result: {[any]: {any}} = {}
	for _, v in pairs(array) do
		local key = fn(v)
		if not result[key] then result[key] = {} end
		table.insert(result[key], v)
	end; return result
end

--[[
	Equals(a: {}, b: {}, deep?: boolean) -> boolean
	> Compares two tables for equality. If deep = true, checks nested tables recursively.
	
	Example:
		```lua
		TableService.Equals({x=1,y=2},{x=1,y=2}) --> true
		TableService.Equals({a={1,2}}, {a={1,2}}, true) --> true
		```
	
	Use case:
		Comparing data structures for equality.
	
	- @param a {}
	- @param b {}
	- @param deep? boolean
	- @return boolean
]]--
function TableService:Equals(a: {}, b: {}, deep: boolean?): boolean
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	
	for i, v in pairs(a) do
		local bv = b[i]
		if deep and type(v) == "table" and type(bv) == "table" then
			if not TableService:Equals(v, bv, true) then return false end
		else 
			if v ~= bv then return false end
		end
	end
	
	for i in pairs(b) do
		if a[i] == nil then return false end
	end; return true
end

--[[
	FlattenDeep(tbl: {}) -> {any}
	> Recursively flattens nested arrays into a single-level array.
	
	Example:
		```lua
		TableService.FlattenDeep({1,{2,{3,4}},5}) --> {1,2,3,4,5}
		```
	
	Use case:
		Reducing nested data structures to a single array.
	
	- @param tbl {}
	- @return {any}
]]--
function TableService:FlattenDeep(tbl: {}): {any}
	local result: {any} = {}
	local function recurse(subtbl: {})
		for _, v in pairs(subtbl) do
			if type(v) == "table" then recurse(v) else table.insert(result, v) end
		end
	end; recurse(tbl); return result
end

--[[
	Reverse(tbl: {any}) -> {any}
	> Reverses an array order in place. Returns the same table for chaining.
	
	Example:
		```lua
		local arr = {1,2,3}
		TableService.Reverse(arr) --> {3,2,1}
		```
	
	Use case:
		Reversing arrays without creating new tables.
	
	- @param tbl {any}
	- @return {any}
]]--
function TableService:Reverse(tbl: {any}): {any}
	local n = #tbl
	for i = 1, math.floor(n / 2) do
		local j = n - i + 1
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end; return tbl
end

return TableService
