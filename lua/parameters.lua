local origin = Vector3.zero
local owner = getfenv().owner
if owner and owner.Character and owner.Character:FindFirstChild('Head') then
	origin = owner.Character.Head.Position - Vector3.yAxis * 4.5
else
	local ray = workspace:Raycast(Vector3.yAxis * 100, Vector3.yAxis * -200)
	if ray then
		origin = ray.Position
	end
end

local prompts = {
	'ocean', 'cloud', 'forest', 'fire'
}

local function pick(t)
	return t[math.random(1, #t)]
end

local sg = Instance.new('Model')
local sphere = Instance.new('Part', sg)
sphere.Shape = Enum.PartType.Ball
sphere.Size = Vector3.one * 3
sphere.Position = origin + Vector3.yAxis * 1.5
--sphere.Reflectance = 1
sphere.Name = 'Head'
sphere.Anchored = true
local shum = Instance.new('Humanoid', sg)
shum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
shum.DisplayName = 'A...'
sg.Parent = script

local hp = {
	a = 0,
	b = 0,
	c = 0,
	d = 0,
	e = 0,
	f = 0
}

