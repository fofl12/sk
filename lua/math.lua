-- problems and solutions stolen from imo 2022
-- obby mechanism stolen from sc

local offset = Vector3.zero
if getfenv().owner then
	local owner = getfenv().owner -- ?!?!
	assert(owner.Character and owner.Character.Head, 'fix your character...')
	offset = owner.Character.Head.Position - Vector3.yAxis * 4.5
end
local debris = game:GetService('Debris')

local colors = {
	[1] = Color3.new(), -- black
	[2] = Color3.new(1, 1, 1), -- white
	[3] = Color3.new(0.3, 0.3, 0.3), -- grey
	[4] = Color3.new(1, 0, 0), -- red
	[5] = Color3.new(0, 1, 0), -- green
	[6] = Color3.new(0, 0, 1), -- blue
	[7] = Color3.new(1, 1, 0), -- yellow
	[8] = Color3.new(0, 1, 1) -- cyan
}
local rg = {
	clear = function()
		script:ClearAllChildren()
	end,
	offset = function(inc)
		offset += inc
	end,
	hint = function(text)
		local hint = Instance.new('Hint', script)
		hint.Text = text or '?'
		local hintApi = {
			set = function(text)
				hint.Text = text
			end,
			get = function()
				return hint.Text
			end,
			raw = hint,
			destroy = function()
				hint:Destroy()
			end
		}
		return hintApi
	end,
	block = function(p, s, c, t)
		local block = Instance.new(t or 'Part', script)
		block.Position = p + offset
		block.Anchored = true
		block.Size = s or Vector3.new(2, 2, 2)
		if type(c) == 'number' then
			block.Color = colors[c]
		else
			block.Color = c or colors[2]
		end

		local blockApi = {
			raw = block,
			destroy = function()
				block:Destroy()
			end
		}
		setmetatable(blockApi, {
			__index = function(_, k)
				if k == 'p' then
					return block.Position
				elseif k == 's' then
					return block.Size
				elseif k == 'c' then
					return block.Color
				end
				return
			end,
			__newindex = function(_, k, v)
				if k == 'p' then
					block.Position = v + offset
				elseif k == 's' then
					block.Size = v
				elseif k == 'c' then
					block.Color = v
				end
			end
		})
		return blockApi
	end,
	timebomb = function(o, t)
		debris:AddItem(o.raw, t)
	end,
}

local points = {}
local stage = 0
local sa = rg.hint("Obby - Stage : " .. stage)
local players = game:GetService'Players'

local problems = {
	{
		problem = "In each square of a garden shaped like a 2022 x 2022 board, there is initially a tree of height 0. A gardener and a lumberjack alternate turns playing the following game, with the gardener taking the first turn: 1. The gardener chooses a square in the garden. Each tree on that square and all the surrounding squares (of which there are at most eight) then becomes one unit taller. 2. The lumberjack then chooses four different squares on the board. Each tree of positive height on those squares then becomes one unit shorter. We say that a tree is majestic if its height is at least 10^6. Determine the largest number K such that the gardener can ensure there are eventually K majestic trees on the board, no matter how the lumberjack plays.",
		solution = "2271380"
	},
	{
		problem = "What is 2 + 4?",
		solution = "6"
	},
	{
		problem = "Alice fills the fields of an n x n board with numbers from 1 to n^2, each number being used exactly once. She then counts the total number of good paths on the board. A good path is a sequence of fields of arbitrary length (including 1) such that: 1. The first field in the sequence is one that is only adjacent to fields with larger numbers, 2. Each subsequent field in the sequence is adjacent to the previous field, 3. The numbers written on the fields in the sequence are in increasing order. Two fields are considered adjacent if they share a common side. Find the smallest possible number of good paths Alice can obtain, as a function of n.",
		solution = "2n^2 - 2n + 1"
	},
	{
		problem = "A number is called Norwegian if it has three distinct positive divisors whose sum is equal to 2022. Determine the smallest Norwegian number. (Note: The total number of positive divisors of a Norwegian number is allowed to be larger than 3.)",
		solution = "1344"
	},
	{
		problem = "Find all triples of positive integers (a, b, p) with p prime and a^p = b! + p",
		solution = "(2, 2, 2) and (3, 4, 3)"
	},
}

local function choose(elements)
	return elements[math.random(1, #elements)]
end

local checkpintd = {}
local function checkpint(platform2)
	local mst = stage
	platform2.raw.Touched:Connect(function(c)
		local p = players:GetPlayerFromCharacter(c.Parent)
		if p and points[p] ~= mst and not checkpintd[p] then
			checkpintd[p] = true
			task.delay(10, function()
				checkpintd[p] = nil
			end)
			local gui = Instance.new('ScreenGui')
			local frame = Instance.new('Frame')
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromScale(0.5, 0.5)
			frame.Size = UDim2.fromOffset(800, 600)
			local label = Instance.new('TextBox')
			label.TextEditable = false
			label.Size = UDim2.fromOffset(800, 200)
			label.Text = 'Solve the problem below to continue. Send your answer in the chat.'
			label.TextScaled = true
			label.Parent = frame
			local pbox = Instance.new('TextBox')
			pbox.TextEditable = false
			pbox.TextScaled = true
			pbox.Size = UDim2.fromOffset(800, 400)
			pbox.Position = UDim2.fromOffset(0, 200)
			local problem = choose(problems)
			pbox.Text = problem.problem
			pbox.Parent = frame
			frame.Parent = gui
			gui.Parent = p.PlayerGui
			c.Parent.Humanoid.WalkSpeed = 0
			c.Anchored = true
			if p.Chatted:Wait() ~= problem.solution then
				p:LoadCharacter()
				return
			end
			c.Parent.Humanoid.WalkSpeed = 16
			c.Anchored = false
			gui:Destroy()
			checkpintd[p] = nil
			points[p] = mst
			p.CharacterAdded:Connect(function(c)
				task.wait(1)
				if points[p] == mst then
					c.Head.CFrame = platform2.raw.CFrame + Vector3.new(0, 10, 0)
				end
			end)
		end
	end)
end

local function truss()
	local truss = rg.block(Vector3.new(0, 10), Vector3.new(0, 20), 3, 'TrussPart')
	truss.raw.Touched:Wait()
	rg.offset(Vector3.new(0, 20, 0))
end

local function balls(mix)
	--[[local platform1 = ]]rg.block(Vector3.new(0, 0, 5), Vector3.new(10, 2, 10))
	local platform2 = rg.block(Vector3.new(0, 0, 45), Vector3.new(10, 2, 10))
	for i = 15, 40, 8 do
		local ball = rg.block(Vector3.new(math.random(-4, 4), mix and 0 or math.random(-2.5, 2.5), i), Vector3.new(2, 2, 2), math.random(1, 8))
		ball.raw.Shape = 'Ball'
	end
	local lava = rg.block(Vector3.new(0, -8, 25), Vector3.new(20, 1, 40), 4)
	lava.Material = 'Neon'
	lava.raw.Touched:Connect(game.Destroy)
	if not mix then
		checkpint(platform2)
	end
	platform2.raw.Touched:Wait()
	rg.offset(Vector3.new(0, 0, 50))
end

local function paths(mix)
	--[[local platform1 = ]]rg.block(Vector3.new(0, 0, 5), Vector3.new(10, 2, 10))
	local platform2 = rg.block(Vector3.new(0, 0, 45), Vector3.new(10, 2, 10))
	
	local paths = {
		rg.block(Vector3.new(-4, 0, 25), Vector3.new(2, 1, 30), 4),
		rg.block(Vector3.new(0, 0, 25), Vector3.new(2, 1, 30), 5),
		rg.block(Vector3.new(4, 0, 25), Vector3.new(2, 1, 30), 6),
	}
	local chosenPath = math.random(1, #paths)
	for i, p in ipairs(paths) do
		if i ~= chosenPath then
			p.raw.Touched:Connect(game.Destroy)
		end
	end

	if not mix then 
		checkpint(platform2)
	end
	platform2.raw.Touched:Wait()
	rg.offset(Vector3.new(0, 0, 50))
	for i, p in ipairs(paths) do
		if i ~= chosenPath then
			p.destroy()
		end
	end
end

local function lava()
	--[[local platform1 = ]]rg.block(Vector3.new(0, 0, 20), Vector3.new(10, 2, 40))
	local platform2 = rg.block(Vector3.new(0, 0, 45), Vector3.new(10, 2, 10))

	for i = 1, 8 do
		local lava = rg.block(Vector3.new(0, 1.5, i * 5), Vector3.new(10, 1, 1), 4)
		lava.raw.Material = 'Neon'
		lava.raw.Touched:Connect(game.Destroy)
	end
	
	checkpint(platform2)
	platform2.raw.Touched:Wait()
	rg.offset(Vector3.new(0, 0, 50))
end

local function slava(mix)
	if not mix then
		--[[local platform1 = ]]rg.block(Vector3.new(0, 0, 20), Vector3.new(10, 2, 40))
		print'nomix'
	end
	local platform2 = rg.block(Vector3.new(0, 0, 45), Vector3.new(10, 2, 10))

	for i = 1, 2 do
		local lava = rg.block(Vector3.new(0, mix and 15 or 12, i * 15 + 5), Vector3.new(25, 2, 2), 4)
		lava.raw.CanCollide = false
		lava.raw.Material = 'Neon'
		task.spawn(function()
			while true do
				local delta = task.wait()
				lava.raw.CFrame *= CFrame.Angles(0, 0, i * 2 * delta)
			end
		end)
		lava.raw.Touched:Connect(game.Destroy)
	end
	if not mix then
		checkpint(platform2)
		platform2.raw.Touched:Wait()
		rg.offset(Vector3.new(0, 0, 50))
	end
end

local options = {truss, balls, paths, lava, slava}
local mixable1 = {balls, lava, paths}
local mixable2 = {slava}

truss()
while true do
	stage += 1
	sa.set("Obby - Stage : " .. stage)
	if math.random() < 0.05 then
		local mix1 = mixable1[math.random(1, #mixable1)]
		local mix2 = mixable2[math.random(1, #mixable2)]
		task.spawn(mix2, true)
		mix1(true)
	else
		options[math.random(1, #options)]()
	end
end