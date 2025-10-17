--!strict
--[[
	@class MathService
	
	> [MathService extends Roblox's math library with additional numerical, vector, interpolation, and probability utilities].
	
		> Author: @Bykhovsky
		> Updated: 10/16/2025
]]--

local MathService = {}

-- // ======================================================
-- // 	GENERAL UTILITIES
-- // ======================================================

--[[
	IsClose(a, b, epsilon) -> boolean
	> Compares two numbers with a tolerance threshold.
	
	Examples:
		MathService:IsClose(1.000001, 1) -> true
		MathService:IsClose(1.1, 1, 0.2) -> true
		
	Use case:
		Prevents issues with floating-point precision when comparing values.
		
	- @param a number
	- @param b number
	- @param epsilon number? (defaults to 1e-6)
	- @return boolean
]]--
function MathService:IsClose(a: number, b: number, epsilon: number): boolean
	epsilon = epsilon or 1e-6; return math.abs(a - b) < epsilon
end

--[[
	Wrap(value, min, nax) -> number
	> Wraps a number between a range (inclusive).
	
	Examples:
		MathService:Wrap(5, 0, 4) -> 1
		MathService:Wrap(0, -1, 1) -> -1
		MathService:Wrap(-2, -2, 2) -> 0
		
	Use case:
		Helpful for wrapping indices, angles, or values that need periodic boundary conditions.
		
	- @param value number
	- @param min number
	- @param max number
	- @return number
]]--
function MathService:Wrap(value: number, min: number, max: number): number
	local range = max - min; return ((value - min) % range) + min
end

--[[
	LerpClamped(a, b, t) -> number
	> Linearly interpolates between two values with clamping.
	
	Examples:
		MathService:LerpClamped(10, 20, 0.5) -> 15
		MathService:LerpClamped(10, 20, 2) -> 20
		
	Use case:
		Interpolates between values while ensuring the result stays within the given range.
		
	- @param a number
	- @param b number
	- @param t number (0-1)
	- @return number
]]--
function MathService:LerpClamped(a: number, b: number, t: number): number
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- // ======================================================
-- // 	GEOMETRY / VECTOR MATH
-- // ======================================================

--[[
	Distance2d(x1, y1, x2, y2) -> number
	> Calculates the 2D distance between two points.
	
	Examples:
		MathService:Distance2d(0, 0, 3, 4) -> 5
		MathService:Distance2d(1, 2, 4, 6) -> 5
		
	Use case:
		Useful for pathfinding, collision detection, or any 2D spatial calculations.
		
	- @param x1 number
	- @param y1 number
	- @param x2 number
	- @param y2 number
	- @return number
]]--
function MathService:Distance2d(x1: number, y1: number, x2: number, y2: number): number
	local dx, dy = x2 - x1, y2 - y1; return math.sqrt(dx * dx + dy * dy)
end

--[[
	Direction(from, to) -> Vector3
	> Calculates the direction from one point to another.
	
	Examples:
		MathService:Direction(Vector3.new(0, 0, 0), Vector3.new(1, 2, 3)) -> Vector3.new(0.2672612419124252, 0.5345224838248497, 0.8017837257372723)
		MathService:Direction(Vector3.new(1, 2, 3), Vector3.new(4, 5, 6)) -> Vector3.new(0.6928209101344055, 0.7262104745724192, 0.06804852240082198)
		
	Use case:
		Useful for determining movement direction or aiming.
		
	- @param from Vector3
	- @param to Vector3
	- @return Vector3
]]--
function MathService:Direction(from: Vector3, to: Vector3): Vector3
	local delta = to - from
	if delta.Magnitude == 0 then return Vector3.zero end
	return delta.Unit
end

--[[
	RandomUnitVector() -> Vector3
	> Returns a random unit vector direction in 3D space.
	
	Examples:
		MathService:RandomUnitVector() -> Vector3.new(0.123456, 0.789012, 0.345678)
		MathService:RandomUnitVector() -> Vector3.new(-0.987654, 0.123456, 0.345678)
		
	Use case:
		Useful for randomizing directions in games or simulations.
		
	- @return Vector3
]]--
function MathService:RandomUnitVector(): Vector3
	local theta = math.random() * 2 * math.pi
	local z = math.random() * 2 - 1
	local root = math.sqrt(1 - z * z)
	return Vector3.new(root * math.cos(theta), root * math.sin(theta), z)
end

--[[
	RandomUnitVector2D() -> Vector2
	> Returns a random unit direction in 2D space.
	
	Examples:
		MathService:RandomUnitVector2D() -> Vector2.new(0.707107, 0.707107)
	
	Use case:
		Useful for 2D games or when working with circular directions.
		
	- @return Vector2
]]--
function MathService:RandomUnitVector2D(): Vector2
	local angle = math.random() * 2 * math.pi
	return Vector2.new(math.cos(angle), math.sin(angle))
end

--[[
	V3IsZero(v, epsilon) -> boolean
	> Checks if a Vector3 is close to zero within an epsilon tolerance.
	> If epsilon is not provided, it defaults to 1e-6.
	
	Examples:
		MathService:V3IsZero(Vector3.new(0, 0, 0)) -> true
		MathService:V3IsZero(Vector3.new(0.0001, 0, 0)) -> true
		MathService:V3IsZero(Vector3.new(0.1, 0, 0)) -> false
		MathService:V3IsZero(Vector3.new(0.1, 0, 0), 0.05) -> true
		
	Use case:
		Useful for checking if a Vector3 is effectively zero, especially when dealing with floating-point precision.
		
	- @param v Vector3
	- @param epsilon number?
	- @return boolean
]]--
function MathService:V3IsZero(v: Vector3, epsilon: number): boolean
	epsilon = epsilon or 1e-6; return math.abs(v.X) < epsilon and math.abs(v.Y) < epsilon and math.abs(v.Z) < epsilon
end

--[[
	Midpoint(a, b) -> Vector3
	> Calculates the midpoint between two Vector3 points.
	
	Examples:
		MathService:Midpoint(Vector3.new(0, 0, 0), Vector3.new(1, 2, 3)) -> Vector3.new(0.5, 1, 1.5)
		MathService:Midpoint(Vector3.new(1, 2, 3), Vector3.new(4, 5, 6)) -> Vector3.new(2.5, 3.5, 4.5)
		
	Use case:
		Useful for finding the center point between two locations or objects.
		
	- @param a Vector3
	- @param b Vector3
	- @return Vector3
]]--
function MathService:Midpoint(a: Vector3, b: Vector3): Vector3
	return (a + b) / 2
end

--[[
	Distance3d(v1, v2) -> number
	> Calculates the 3D distance between two Vector3 points.
	
	Examples:
		MathService:Distance3d(Vector3.new(0, 0, 0), Vector3.new(1, 2, 3)) -> 3.7416573867739413
		MathService:Distance3d(Vector3.new(1, 2, 3), Vector3.new(4, 5, 6)) -> 5.196152422706632
		
	Use case:
		Useful for 3D pathfinding, collision detection, or any 3D spatial calculations.
		
	- @param v1 Vector3
	- @param v2 Vector3
	- @return number
]]--
function MathService:Distance3d(v1: Vector3, v2: Vector3): number
	return (v1 - v2).Magnitude
end

--[[
	Flatten(v) -> Vector3
	> Removes the Y component from a Vector3.
	
	Examples:
		MathService:Flatten(Vector3.new(1, 2, 3)) -> Vector3.new(1, 0, 3)
		
	Use case:
		When working with flat surfaces or terrain where Y is not relevant.
	
	- @param v Vector3
	- @return Vector3
]]--
function MathService:Flatten(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

--[[
	AngleBetween(v1, v2) -> number
	> Calculates the angle in radians between two Vector3 directions.
	
	Examples:
		MathService:AngleBetween(Vector3.new(1, 0, 0), Vector3.new(0, 1, 0)) -> 1.5707963267948966 (90 degrees)
		MathService:AngleBetween(Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)) -> 3.141592653589793 (180 degrees)
		MathService:AngleBetween(Vector3.new(1, 0, 0), Vector3.new(1, 0, 0)) -> 0 (0 degrees)
		
	Use case:
		Useful for calculating angles between directions, rotations, or for pathfinding around obstacles.
	
	- @param v1 Vector3
	- @param v2 Vector3
	- @return number
]]--
function MathService:AngleBetween(v1: Vector3, v2: Vector3): number
	return math.acos(math.clamp(v1:Dot(v2) / (v1.Magnitude * v2.Magnitude), -1, 1))
end

--[[
	Project(v1, v2) -> Vector3
	> Calculates the projection of v1 onto v2.
	
	Examples:
		MathService:Project(Vector3.new(1, 2, 3), Vector3.new(0, 1, 0)) -> Vector3.new(0, 2, 0)
		
	Use case:
		Useful for decomposing vectors, calculating work done by a force, or for pathfinding along a direction.
	
	- @param v1 Vector3
	- @param v2 Vector3
	- @return Vector3
]]--
function MathService:Project(v1: Vector3, v2: Vector3): Vector3
	return v2.Unit * v1:Dot(v2.Unit)
end

--[[
	Reject(a, b) -> Vector3
	> Rejects vector a from vector b (returns the perpendicular component).
	
	Examples:
		MathService:Reject(Vector3.new(1, 2, 3), Vector3.new(0, 1, 0)) -> Vector3.new(1, 0, 3)
		
	Use case:
		Useful for finding the component of a vector that is perpendicular to another vector.
	
	- @param a Vector3
	- @param b Vector3
	- @return Vector3
]]--
function MathService:Reject(a: Vector3, b: Vector3): Vector3
	return a - self:Project(a, b)
end

--[[
	Reflect(direction, normal) -> Vector3
	> Reflects a direction vector off a surface with the given normal.
	
	Examples:
		MathService:Reflect(Vector3.new(1, 2, 3), Vector3.new(0, 1, 0)) -> Vector3.new(1, -2, 3)
		
	Use case:
		Useful for simulating reflections, bouncing objects, or for pathfinding around obstacles.
	
	- @param direction Vector3
	- @param normal Vector3
	- @return Vector3
]]--
function MathService:Reflect(direction: Vector3, normal: Vector3): Vector3
	return direction - 2 * direction:Dot(normal) * normal
end

--[[
	ForwardFromYaw(yaw) -> Vector3
	> Returns a forward direction vector from yaw (in radians).
	
	Examples:
		MathService:ForwardFromYaw(0) -> Vector3.new(0, 0, -1)
		MathService:ForwardFromYaw(math.pi / 2) -> Vector3.new(0, 0, 1)
		MathService:ForwardFromYaw(math.pi) -> Vector3.new(0, 0, -1)
		MathService:ForwardFromYaw(3 * math.pi / 2) -> Vector3.new(0, 0, 1)
			
	Use case:
		Useful for setting the forward direction of an object based on a yaw angle.
			
	- @param yaw number
	- @return Vector3
]]--
function MathService:ForwardFromYaw(yaw: number): Vector3
	return Vector3.new(math.sin(yaw), 0, math.cos(yaw))
end

--[[
	YawFromDirection(dir) -> number
	> Returns the yaw (in radians) for a given direction vector.
	
	Examples:
		MathService:YawFromDirection(Vector3.new(1, 0, 0)) -> 0
		MathService:YawFromDirection(Vector3.new(0, 0, -1)) -> math.pi / 2
		MathService:YawFromDirection(Vector3.new(-1, 0, 0)) -> math.pi / 2
		MathService:YawFromDirection(Vector3.new(0, 0, 1)) -> 3 * math.pi / 2
		MathService:YawFromDirection(Vector3.new(0, 0, 0)) -> 0 (or math.pi)
			
	Use case:
		Useful for determining the yaw angle of an object based on its direction.
			
	- @param dir Vector3
	- @return number
]]--
function MathService:YawFromDirection(dir: Vector3): number
	return math.atan2(dir.X, dir.Z)
end

--[[
	ClampMagnitude(v, maxLength) -> Vector3
	> Clamps the magnitude of a Vector3 to a maximum length.
	
	Examples:
		MathService:ClampMagnitude(Vector3.new(3, 4, 0), 5) -> Vector3.new(3, 4, 0)
		MathService:ClampMagnitude(Vector3.new(1, 2, 3), 2) -> Vector3.new(0.4472135954999579, 0.894427189499916, 1.3416371149985624)
		
	Use case:
		Useful for limiting the speed of a moving object, or for normalizing vectors while preserving their direction.
	
	- @param v Vector3
	- @param maxLength number
	- @return Vector3
]]--
function MathService:ClampMagnitude(v: Vector3, maxLength: number): Vector3
	local mag = v.Magnitude
	if mag > maxLength then return v.Unit * maxLength end
	return v
end

--[[
	V3QuadraticBezier(p0, p1, p2, t) -> Vector3
	> Returns a point on a 3D quadratic Bezier curve for a given t value.
	
	Examples:
		MathService:V3QuadraticBezier(Vector3.new(0, 0, 0), Vector3.new(1, 1, 1), Vector3.new(2, 2, 2), 0.5) -> Vector3.new(1, 1, 1)
		
	Use case:
		Useful for creating smooth, curved paths for objects to follow.
	
	- @param p0 Vector3
	- @param p1 Vector3
	- @param p2 Vector3
	- @param t number
	- @return Vector3
]]--
function MathService:V3QuadraticBezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local u = 1 - t; return (u * u) * p0 + (2 * u * t) * p1 + (t * t) * p2
end

--[[
	V3CubicBezier(p0, p1, p2, p3, t) -> Vector3
	> Returns a point on a 3D cubic Bezier curve for a given t value.
	
	Examples:
		MathService:V3CubicBezier(Vector3.new(0, 0, 0), Vector3.new(1, 1, 1), Vector3.new(2, 2, 2), Vector3.new(3, 3, 3), 0.5) -> Vector3.new(1.5, 1.5, 1.5)
		
	Use case:
		Useful for creating more complex curved paths for objects to follow.
	
	- @param p0 Vector3
	- @param p1 Vector3
	- @param p2 Vector3
	- @param p3 Vector3
	- @param t number
	- @return Vector3
]]--
function MathService:V3CubicBezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local u = 1 - t; return (u ^ 3) * p0 + (3 * u * u * t) * p1 + (3 * u * t * t) * p2 + (t ^ 3) * p3
end

--[[
	V3SmoothDamp(current, target, velocity, smoothTime, deltaTime) -> (Vector3, Vector3)
	> Applies velocity-based smooth damping (spring motion) to a Vector3 value.
	
	Examples:
		```lua
		local current = Vector3.new(0, 0, 0)
		local target = Vector3.new(10, 10, 10)
		local velocity = Vector3.new(0, 0, 0)
		local smoothTime = 1
		local deltaTime = 0.1
		local newPos, newVel = V3SmoothDamp(current, target, velocity, smoothTime, deltaTime)
		```
		
	Use case:
		Useful for creating smooth transitions or animations where velocity is important, like realistic object movement or camera smoothing.
	
	- @param current Vector3
	- @param target Vector3
	- @param velocity Vector3
	- @param smoothTime number
	- @param deltaTime number
	- @return Vector3, Vector3
]]--
function MathService:V3SmoothDamp(current: Vector3, target: Vector3, velocity: Vector3, smoothTime: number, deltaTime: number): (Vector3, Vector3)
	local omega = 2 / smoothTime
	local x = omega * deltaTime
	local exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	local change = current - target
	local temp = (velocity + change * omega) * deltaTime
	local newVel = (velocity - temp * omega) * exp
	local newPos = target + (change + temp) * exp
	return newPos, newVel
end

-- // ======================================================
-- // 	RANDOMIZATION / PROBABILITY
-- // ======================================================

--[[
	RandomSign() -> number
	Returns either -1 or 1 randomly
	
	Examples:
		MathService:RandomSign() -> -1
		MathService:RandomSign() -> 1
		
	Use case:
		Useful for adding random direction to a value, such as randomizing the direction of a force or velocity.
	
	- @return number
]]--
function MathService:RandomSign(): number
	return math.random(0, 1) == 1 and 1 or -1
end

--[[
	RandomFloat(min, max) -> number
	> Returns a random number between min and max.
	
	Examples:
		MathService:RandomFloat(0, 1) -> 0.5346628871247098
		MathService:RandomFloat(-10, 10) -> 2.3456789012345678
		MathService:RandomFloat(-100, 100) -> -45.67890123456789
		MathService:RandomFloat(0, 100) -> 56.78901234567891
			
	Use case:
		Useful for generating random values within a range, such as randomizing the speed or position of an object.
	
	- @param min number
	- @param max number
	- @return number
]]--
function MathService:RandomFloat(min: number, max: number): number
	return math.random() * (max - min) + min
end

--[[
	WeightedRandom(weights) -> string
	> Returns a random key from the given table, where the chance of each key is determined by its value.
	
	Examples:
		MathService:WeightedRandom({ a = 1, b = 2, c = 3 }) -> "b"
		MathService:WeightedRandom({ x = 10, y = 20, z = 30 }) -> "z"
		
	Use case:
		Useful for weighted random selection, such as weighted random rewards or weighted random events.
	
	- @param weights table
	- @return string
]]--
function MathService:WeightedRandom(weights: { [string]: number }): string
	local total = 0
	for _, weight in pairs(weights) do
		total += weight
	end
	local threshold = math.random() * total
	local cumulative = 0
	
	for key, weight in pairs(weights) do
		cumulative += weight
		if threshold <= cumulative then return key end
	end
	
	return next(weights) or ""
end

--[[
	Chance(percent) -> boolean
	> Rolls a random chance based on a percentage.
	
	Examples:
		MathService:Chance(50) -> true
		MathService:Chance(25) -> false
		MathService:Chance(100) -> true
		MathService:Chance(0) -> false
		
	Use case:
		Useful for implementing random events with a certain chance, such as random loot drops or random enemy spawns.
	
	- @param percent number
	- @return boolean
]]--
function MathService:Chance(percent: number): boolean
	return math.random() * 100 <= percent
end

-- // ======================================================
-- // 	INTERPOLATION & EASING
-- // ======================================================

--[[
	SmoothStep(t) -> number
	> Smoothstep curve (ease-in-out interpolation).
	
	Examples:
		MathService:SmoothStep(0) -> 0
		MathService:SmoothStep(0.5) -> 0.5
		MathService:SmoothStep(1) -> 1
		
	Use case:
		Useful for smooth interpolation between two values, such as smooth transitions or easing functions.
	
	- @param t number
	- @return number
]]--
function MathService:SmoothStep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

--[[
	LerpAngle(a, b, t) -> number
	> Lerps between two angles, wrapping around 360°.
	
	Examples:
		MathService:LerpAngle(0, 180, 0.5) -> 90
		MathService:LerpAngle(100, 200, 0.25) -> 125
		MathService:LerpAngle(350, 10, 0.5) -> 190
		
	Use case:
		Useful for lerping angles or rotations, ensuring smooth wrapping around 360°.
	
	- @param a number
	- @param b number
	- @param t number
	- @return number
]]--
function MathService:LerpAngle(a: number, b: number, t: number): number
	local diff = ((b - a + 180) % 360) - 180
	return a + diff * math.clamp(t, 0, 1)
end

--[[
	Remap(x, inMin, inMax, outMin, outMax) -> number
	> Remaps a number from one range to another.
	
	Examples:
		MathService:Remap(0.5, 0, 1, 10, 20) -> 15
		MathService:Remap(100, 0, 1000, 0, 1) -> 0.1
		
	Use case:
		Useful for scaling values from one range to another, such as normalizing data or converting units.
	
	- @param x number
	- @param inMin number
	- @param inMax number
	- @param outMin number
	- @param outMax number
	- @return number
]]--
function MathService:Remap(x: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

--[[
	EaseInOutQuad(t) -> number
	> Ease-in-out quadratic curve (0->1->0)
	
	Examples:
		MathService:EaseInOutQuad(0) -> 0
		MathService:EaseInOutQuad(0.5) -> 1
		MathService:EaseInOutQuad(1) -> 0
		
	Use case:
		Useful for creating smooth acceleration and deceleration patterns, such as UI animations or easing functions.
	
	- @param t number
	- @return number
]]--
function MathService:EaseInOutQuad(t: number): number
	t = math.clamp(t, 0, 1)
	return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end

-- // ======================================================
-- // 	ROUNDING / PRECISION
-- // ======================================================

--[[
	RoundDecimal(num, places) -> number
	> Rounds a number to a specified number of decimal places.
	
	Examples:
		MathService:RoundDecimal(3.14159, 2) -> 3.14
		MathService:RoundDecimal(1.23456, 3) -> 1.235
		
	Use case:
		Useful for displaying or storing numbers with a specific precision, such as currency or scientific data.
	
	- @param num number
	- @param places number
	- @return number
]]--
function MathService:RoundDecimal(num: number, places: number): number
	local mult = 10 ^ places
	return math.floor(num * mult + 0.5) / mult
end

--[[
	Snap(num, increment) -> number
	> Snaps a number to the nearest increment.
	
	Examples:
		MathService:Snap(12.34, 5) -> 10
		MathService:Snap(17.8, 5) -> 15
		
	Use case:
		Useful for aligning values to grid systems or simplifying data for display.
	
	- @param num number
	- @param increment number
	- @return number
]]--
function MathService:Snap(num: number, increment: number): number
	return math.floor((num / increment) + 0.5) * increment
end

--[[
	Fraction(num) -> number
	> Returns the fractional part of a number.
	
	Examples:
		MathService:Fraction(3.14) -> 0.14
		MathService:Fraction(-2.75) -> 0.25
		
	Use case:
		Useful for extracting the decimal part of a number, such as in time calculations or normalizing values.
	
	- @param num number
	- @return number
]]--
function MathService:Fraction(num: number): number
	return num - math.floor(num)
end

-- // ======================================================
-- // 	PHYSICS / MOTION
-- // ======================================================

--[[
	AccelerateTowards(current, target, accel, deltaTime) -> number
	> Accelerates a value towards a target with a given acceleration rate and time step.
	
	Examples:
		MathService:AccelerateTowards(10, 20, 2, 0.1) -> 12
		MathService:AccelerateTowards(5, 10, 5, 0.2) -> 6.0625
		
	Use case:
		Useful for creating smooth acceleration or deceleration effects, such as in physics simulations or UI animations.
	
	- @param current number
	- @param target number
	- @param accel number
	- @param deltaTime number
	- @return number
]]--
function MathService:AccelerateTowards(current: number, target: number, accel: number, deltaTime: number): number
	if current == target then return target end
	local diff = target - current
	local step = math.sin(diff) * accel * deltaTime
	if math.abs(step) > math.abs(diff) then
		return target
	end; return current + step
end

--[[
	Damp(value, target, smoothing, deltaTime) -> number
	> Exponentially damps a value towards a target with a given smoothing rate and time step.
	
	Examples:
		MathService:Damp(10, 20, 0.1, 0.1) -> 19.8
		MathService:Damp(5, 10, 0.2, 0.2) -> 9.808
		
	Use case:
		Useful for creating smooth transitions or filtering noisy data, such as in physics simulations or UI animations.
	
	- @param value number
	- @param target number
	- @param smoothing number
	- @param deltaTime number
	- @return number
]]--
function MathService:Damp(value: number, target: number, smoothing: number, deltaTime: number): number
	return math.lerp(value, target, 1 - math.exp(-smoothing * deltaTime))
end

--[[
	Overshoot(current, target, strength) -> number
	> Overshoots a value towards a target with a given strength.
	
	Examples:
		MathService:Overshoot(10, 20, 0.5) -> 20.5
		MathService:Overshoot(5, 10, 2) -> 12.5
		
	Use case:
		Useful for creating overshooting or bouncing effects, such as in physics simulations or UI animations.
	
	- @param current number
	- @param target number
	- @param strength number
	- @return number
]]--
function MathService:Overshoot(current: number, target: number, strength: number): number
	return target + (target - current) * strength
end

-- // ======================================================
-- // 	TIMING / CYCLIC
-- // ======================================================

--[[
	PingPong(t, length) -> number
	> Returns a value that oscillates between 0 and length.
	
	Examples:
		MathService:PingPong(1.5, 1) -> 0.5
		MathService:PingPong(2.5, 1) -> 0.5
		
	Use case:
		Useful for creating periodic or looping animations or effects.
	
	- @param t number
	- @param length number
	- @return number
]]--
function MathService:PingPong(t: number, length: number): number
	local val = math.abs((t % (2 * length)) - length); return val
end

--[[
	Repeat(t, length) -> number
	> Returns a value t that repeats between 0 and length.
	
	Examples:
		MathService:Repeat(1.5, 1) -> 0.5
		MathService:Repeat(2.5, 1) -> 0.5
		
	Use case:
		Useful for creating periodic or looping animations or effects.
	
	- @param t number
	- @param length number
	- @return number
]]--
function MathService:Repeat(t: number, length: number): number
	return t - math.floor(t / length) * length
end

return MathService
