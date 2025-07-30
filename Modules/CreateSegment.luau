return function(origin: Vector3, target: Vector3): BasePart
	
	local Segment = Instance.new('Part')
	Segment.BrickColor = BrickColor.White()
	Segment.Transparency = .5
	Segment.Material = Enum.Material.SmoothPlastic
	Segment.CastShadow = false
	Segment.Anchored = true
	Segment.CanCollide = false
	Segment.CanQuery = false
	Segment.CanTouch = false
	Segment.Size = Vector3.new(.1, .1, (origin - target).Magnitude)
	Segment.CFrame = CFrame.lookAt((origin + target) * .5, target)
	
	return Segment
	
end
