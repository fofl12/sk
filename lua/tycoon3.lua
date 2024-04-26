assert(getfenv().owner, 'wrong environment')
local sources = {}
for i = 1, 20 do
    sources[i] = {
        pos = owner.Character.Head.Position + Vector3.new(math.random(-100, 100), math.random(0, 10), math.random(-100, 100)),
        radius = math.random(4, 10),
        q = math.random(500, 10000)
    }
    local new = Instance.new('Part')
    new.Size = Vector3.one * sources[i].radius
    new.Shape = Enum.PartType.Ball
    new.Position = sources[i].pos
    new.BrickColor = BrickColor.random()
    new.Transparency = 0.8
    new.CanCollide = false
    new.Anchored = true
    new.Parent = script
    sources[i].real = new
end
--local compass = Instance.new('')