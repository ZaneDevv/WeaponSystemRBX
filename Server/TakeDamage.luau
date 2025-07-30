local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Remotes = ReplicatedStorage:WaitForChild('Remotes')
local TakeDamageRemote = Remotes.TakeDamage

TakeDamageRemote.OnServerEvent:Connect(function(_, Humanoid, Damage)
	Humanoid:TakeDamage(Damage)
end)
