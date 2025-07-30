local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Debris = game:GetService('Debris')
local SoundService = game:GetService('SoundService')
local CollectionService = game:GetService('CollectionService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

local TWEEN_AIM_INFORMATION = TweenInfo.new(.5, Enum.EasingStyle.Exponential)

local TweenStartAiming = TweenService:Create(workspace.Camera, TWEEN_AIM_INFORMATION, {FieldOfView = 45})
local TweenStopAiming = TweenService:Create(workspace.Camera, TWEEN_AIM_INFORMATION, {FieldOfView = 70})

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')
local WeaponUI = PlayerGui:WaitForChild('Weapon')

local WeaponSFX = SoundService:WaitForChild('Weapon')
local ShootSFX = WeaponSFX.PistolShoot
local ReloadSFX = WeaponSFX.Reload

local Assets = ReplicatedStorage:WaitForChild('Assets')
local BulletHole = Assets.BulletHole

local Remotes = ReplicatedStorage:WaitForChild('Remotes')
local TakeDamageRemote = Remotes.TakeDamage
local BreakGlassRemote = Remotes.BreakGlass

local Modules = ReplicatedStorage:WaitForChild('Modules')
local CreateSegment = require(Modules.CreateSegment)
local ShiftLock = require(Modules.ShiftLock)

local Tool = script.Parent
local Handle = Tool:WaitForChild('Handle')

local RandomGenerator = Random.new()

local EventsConnected: {RBXScriptConnection} = {}

local Settings = require(script.Parent:WaitForChild('Settings'))


local ammo = Settings.MaxBullets

local isReloading = false
local isAiming = false

local function Shoot()
	if isReloading then return end
	if (LocalPlayer.Character == nil) then return end
	if (ammo <= 0) then return end
	
	ammo -= 1
	WeaponUI.Ammo.Text = `{ammo}/{Settings.MaxBullets}`
	
	task.defer(function()
		local currentAlpha = 0
		local t = 0
		
		while true do
			local deltaTime = RunService.Heartbeat:Wait() * 20
			t += deltaTime
			
			currentAlpha = Settings.Recoil * (1 - (1 - t) ^  2.5)
			workspace.CurrentCamera.CFrame *= CFrame.fromAxisAngle(Vector3.xAxis, currentAlpha * deltaTime)
			
			if (t > 1) then
				break
			end
		end
	end)
	
	local raycastParams = RaycastParams.new()
	raycastParams.IgnoreWater = true
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local sfx = ShootSFX:Clone()
	sfx.Parent = script
	sfx:Play()
	Debris:AddItem(sfx, 2)
	
	local MousePositionIn3D = Mouse.Hit.Position
	
	for i = 1, Settings.BulletsPerShoot do
		local spreadX = RandomGenerator:NextNumber(-Settings.Spread, Settings.Spread)
		local spreadY = RandomGenerator:NextNumber(-Settings.Spread, Settings.Spread)
		
		if (isAiming) then
			spreadX /= Settings.SpreadDivisorWhenAim
			spreadY /= Settings.SpreadDivisorWhenAim
		end
		
		local StartingPoint = Handle.ShootingInitialPoint.WorldPosition
		local Direction = (CFrame.lookAt(StartingPoint, MousePositionIn3D) * CFrame.Angles(spreadX, spreadY, 0)).LookVector
		
		local raycastResult = workspace:Raycast(StartingPoint, Direction * Settings.BulletFalls, raycastParams)
		if (raycastResult) then
			local Segment = CreateSegment(StartingPoint, raycastResult.Position)
			Segment.Parent = workspace
			Debris:AddItem(Segment, .1)
			
			local Humanoid = raycastResult.Instance.Parent:FindFirstChildWhichIsA('Humanoid')
			if (Humanoid == nil) then
				raycastResult.Instance.Parent.Parent:FindFirstChildWhichIsA('Humanoid')
			end
			if (Humanoid) then
				TakeDamageRemote:FireServer(Humanoid, Settings.Damage)
			else
				
				if (CollectionService:HasTag(raycastResult.Instance, 'Glass')) then
					BreakGlassRemote:FireServer(raycastResult.Instance, raycastResult.Position)
					
				else
					local hole = BulletHole:Clone()
					hole.Parent = workspace
					hole.CFrame = CFrame.lookAt(raycastResult.Position, raycastResult.Normal + raycastResult.Position)
					Debris:AddItem(hole, 5)
					
				end
			end
		end
		
		local Segment = CreateSegment(StartingPoint, StartingPoint + Direction * Settings.BulletFalls)
		Segment.Parent = workspace
		Debris:AddItem(Segment, .1)
	end
end

local function Reload()
	if (isReloading) then return end
	isReloading = true
	
	local sfx = ReloadSFX:Clone()
	sfx.Parent = script
	sfx:Play()
	Debris:AddItem(sfx, 2)
	
	task.wait(2)
	
	ammo = Settings.MaxBullets
	WeaponUI.Ammo.Text = `{ammo}/{Settings.MaxBullets}`
	
	isReloading = false
end

Tool.Equipped:Connect(function()
	if (LocalPlayer.Character == nil) then return end
	ShiftLock.Activate(LocalPlayer.Character:WaitForChild('Humanoid'))
	
	local stopShoot = false
	
	table.insert(EventsConnected, Tool.Activated:Connect(function()
		stopShoot = false

		while true do
			Shoot()
			
			local timePassedBy = 0
			local canShoot = true
			
			if (stopShoot) then
				break
			end
			
			while true do
				timePassedBy += RunService.Heartbeat:Wait()
				
				if (stopShoot) then
					canShoot = false
					break
				end
				
				if (timePassedBy >= Settings.Cooldown) then
					break
				end
			end
			
			if (not canShoot) then
				break
			end
		end
	end))
	
	table.insert(EventsConnected, Tool.Deactivated:Connect(function()
		stopShoot = true
	end))
	
	table.insert(EventsConnected, WeaponUI.Reload.MouseButton1Up:Connect(Reload))
	table.insert(EventsConnected, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.R then
			Reload()
		end
	end))
	
	table.insert(EventsConnected, Mouse.Button2Down:Connect(function()
		isAiming = true
		TweenStartAiming:Play()
	end))
	
	table.insert(EventsConnected, Mouse.Button2Up:Connect(function()
		isAiming = false
		TweenStopAiming:Play()
	end))
	
	table.insert(EventsConnected, Tool.Unequipped:Connect(function()
		if (LocalPlayer.Character == nil) then return end
		ShiftLock.Desactivate(LocalPlayer.Character:WaitForChild('Humanoid'))
		
		stopShoot = true

		for _, event in ipairs(EventsConnected) do
			event:Disconnect()
		end
		table.clear(EventsConnected)
	end))

end)
