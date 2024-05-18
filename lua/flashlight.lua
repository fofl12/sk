--!strict
local owner = getfenv().owner
assert(owner, 'wrong environment')

local tool = Instance.new('Tool')
tool.Name = 'Light'
tool.ToolTip = 'Drop for light'
tool.CanBeDropped = true

local handle = Instance.new('Part')
handle.Size = Vector3.new(1, 1, 2)
handle.Name = 'Handle'
local slight = Instance.new('SpotLight')
slight.Range = 60
slight.Brightness = 2
slight.Parent = handle
handle.Parent = tool

tool.AncestryChanged:Connect(function()
	if tool.Parent == workspace then
		task.wait(1)
		local block = Instance.new('Part')
		block.Size = Vector3.one
		block.Position = handle.Position
		local light = Instance.new('PointLight', block)
		light.Range = 60
		light.Brightness = 1
		block.Parent = script
		tool.Parent = owner.Character
	end
end)

tool.Parent = owner.Backpack