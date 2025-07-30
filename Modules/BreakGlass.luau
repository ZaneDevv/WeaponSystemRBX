local SECONDS_TO_WAIT_TO_REGENERATE_GLASS = 5

local SoundService = game:GetService('SoundService')
local Debris = game:GetService('Debris')

local BreakSFX = SoundService:WaitForChild('BreakGlass')

local Wedge = Instance.new("WedgePart")
Wedge.Anchored = true
Wedge.TopSurface = Enum.SurfaceType.Smooth
Wedge.BottomSurface = Enum.SurfaceType.Smooth

-- Code slightly modified from https://github.com/EgoMoose/Articles/blob/master/3d%20triangles/3D%20triangles.md
local function GenerateTriangleAmongThreePoints(a, b, c, thickness, properties)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)

	if (abd > acd and abd > bcd) then
		a, c = c, a
	elseif (acd > abd and acd > bcd) then
		a, b = b, a
	end

	ab, ac, bc = b - a, c - a, c - b

	local right = ac:Cross(ab).Unit
	local up, back = bc:Cross(right).Unit, bc.Unit

	local height = math.abs(ab:Dot(up))

	local Wedge1 = Wedge:Clone()
	Wedge1.Size = Vector3.new(thickness, height, math.abs(ab:Dot(back)))
	Wedge1.CFrame = CFrame.fromMatrix((a + b) * .5, right, up, back)

	local Wedge2 = Wedge:Clone()
	Wedge2.Size = Vector3.new(thickness, height, math.abs(ac:Dot(back)))
	Wedge2.CFrame = CFrame.fromMatrix((a + c) * .5, -right, up, -back)
	
	for propertyName: string, value: any in properties do
		Wedge1[propertyName] = value
		Wedge2[propertyName] = value
	end
	
	Wedge1.Parent = workspace
	Wedge2.Parent = workspace

	return Wedge1, Wedge2
end

return function(glass: Part, center: Vector3)
	local sfx = BreakSFX:Clone()
	sfx.Parent = script
	sfx:Play()
	Debris:AddItem(sfx, 3)
	
	local cframe = glass.CFrame
	local size = glass.Size
	local transparency = glass.Transparency
	local color = glass.Color
	local thickness = size.Z

	local Corners = table.create(0)
	if size.Z > size.X then
		thickness = size.X
		
		Corners = {
			cframe * CFrame.new(0, size.Y * .5, size.Z * .5);
			cframe * CFrame.new(0, size.Y * .5, 0);
			cframe * CFrame.new(0, size.Y * .5, -size.Z * .5);
			cframe * CFrame.new(0, 0, -size.Z * .5);
			cframe * CFrame.new(0, -size.Y * .5, -size.Z * .5);
			cframe * CFrame.new(0, -size.Y * .5, 0);
			cframe * CFrame.new(0, -size.Y * .5, size.Z * .5);
			cframe * CFrame.new(0, 0, size.Z * .5);
		};
	else
		Corners = {
			cframe * CFrame.new(size.X * .5, size.Y * .5, 0);
			cframe * CFrame.new(0, size.Y * .5, 0);
			cframe * CFrame.new(-size.X * .5, size.Y * .5, 0);
			cframe * CFrame.new(-size.X * .5, 0, 0);
			cframe * CFrame.new(-size.X * .5, -size.Y * .5, 0);
			cframe * CFrame.new(0, -size.Y * .5, 0);
			cframe * CFrame.new(size.X * .5, -size.Y * .5, 0);
			cframe * CFrame.new(size.X * .5, 0, 0);
		};
	end

	glass.Transparency = 1
	glass.CanCollide = false


	local SavedTriangles = {}

	for index: number, cornerPosition: CFrame in next, Corners do
		local nextCorner = Corners[index + 1]
		if nextCorner == nil then
			nextCorner = Corners[1]
		end
		
		local Wedge1, Wedge2 = GenerateTriangleAmongThreePoints(cornerPosition.Position, nextCorner.Position, center, thickness, {
			Anchored = false,
			Color = color,
			Transparency = transparency
		})
		
		table.insert(SavedTriangles, Wedge1)
		table.insert(SavedTriangles, Wedge2)
	end

	task.wait(SECONDS_TO_WAIT_TO_REGENERATE_GLASS)

	for _, triangle: BasePart in ipairs(SavedTriangles) do
		triangle:Destroy()
	end

	glass.Transparency = transparency
	glass.CanCollide = true
end
