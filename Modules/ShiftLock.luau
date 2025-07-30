local ShiftLock = {}

local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

function ShiftLock.Activate(Humanoid: Humanoid)
	local RootPart: Part = Humanoid.RootPart :: Part
	local Camera = workspace.CurrentCamera
	
	Humanoid.CameraOffset = Vector3.xAxis * 2
	Humanoid.AutoRotate = false
	
	RunService:BindToRenderStep('ShiftLock', Enum.RenderPriority.Character.Value, function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		
		local LookingTowards = Camera.CFrame.LookVector
		local alpha = math.atan2(-LookingTowards.X, -LookingTowards.Z)
		
		RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.fromAxisAngle(Vector3.yAxis, alpha)
	end)
end

function ShiftLock.Desactivate(Humanoid: Humanoid)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	
	Humanoid.CameraOffset = Vector3.zero
	Humanoid.AutoRotate = true
	
	RunService:UnbindFromRenderStep('ShiftLock')
end

return ShiftLock
