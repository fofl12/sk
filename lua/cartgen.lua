--!strict
assert(getfenv().owner, 'wrong environment')
local function cartgen()
	local model = Instance.new('Model')
	local base = Instance.new('Part', model)
	base.Name = 'Base'
	base.Size = Vector3.new(4, 1, 4)
	base.BrickColor = BrickColor.random()
	local wall1 = Instance.new('Part', model)
	wall1.Size = Vector3.new(4, 4, 1)
	local weld1 = Instance.new('Weld', base)
	weld1.Part0 = base
	weld1.Part1 = wall1
	weld1.C0 = CFrame.new(0, 2, 2)
	local wall2 = Instance.new('Part', model)
	wall2.Size = Vector3.new(4, 4, 1)
	local weld2 = Instance.new('Weld', base)
	weld2.Part0 = base
	weld2.Part1 = wall2
	weld2.C0 = CFrame.new(0, 2, -2)
	local wall3 = Instance.new('Part', model)
	wall3.Size = Vector3.new(1, 4, 4)
	local weld3 = Instance.new('Weld', base)
	weld3.Part0 = base
	weld3.Part1 = wall3
	weld3.C0 = CFrame.new(2, 2, 0)
	local wall4 = Instance.new('Part', model)
	wall4.Size = Vector3.new(1, 4, 4)
	local weld4 = Instance.new('Weld', base)
	weld4.Part0 = base
	weld4.Part1 = wall4
	weld4.C0 = CFrame.new(-2, 2, 0)
	for _, wall in { wall1, wall2, wall3, wall4 } do
		wall.BrickColor = BrickColor.random()
	end
	return model
end
local new = cartgen()
new.Parent = script
new.Base.CFrame = owner.Character.Head.CFrame