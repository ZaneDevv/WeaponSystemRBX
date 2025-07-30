local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Modules = ReplicatedStorage:WaitForChild('Modules')
local BreakGlass = require(Modules.BreakGlass)

local Remotes = ReplicatedStorage:WaitForChild('Remotes')
local BreakGlassRemote = Remotes.BreakGlass

BreakGlassRemote.OnServerEvent:Connect(function(_, glass: Part, brokenPoint: Vector3)
	BreakGlass(glass, brokenPoint)
end)
