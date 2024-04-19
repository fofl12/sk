--[[
	war.lua
	Copyright 2024 fofl12 (comsurg (h)) BSD 3-clause New License
	github.com/fofl12/sk

	the hexagons were made possible by the saint that wrote this: https://www.redblobgames.com/grids/hexagons/

	contributions to the pre-game settings by ryry (copied from plateofdoom.lua)
]]

type Character = Model & {
	Head: Part,
	Humanoid: Humanoid
}
type Owner = Player & {
	Character: Character,
	Chatted: RBXScriptSignal & {
		Connect: ((string) -> ()) -> RBXScriptConnection
	}
}

local chars = {
	{
		name = 'King',
		outfit = 29228213795,
		maxhp = 500
	},
	{
		name = 'Warrior',
		outfit = 29228438216,
		maxhp = 100
	},
	{
		name = 'Boat',
		outfit = 29228386770,
		maxhp = 200
	},
	{
		name = 'Commander',
		outfit = 29228336290,
		maxhp = 150
	},
	{
		name = 'Explosive',
		outfit = 29228243221,
		maxhp = 1
	},
	{
		name = 'Archer',
		outfit = 29228180259,
		maxhp = 60
	},
	{
		name = 'Scout',
		outfit = 29228157425,
		maxhp = 60
	},
}
local names = {
	'collective', 'empire', 'faction', 'republic', 'union'
}

local origin = Vector3.zero
local owner: Owner = getfenv().owner
if owner then -- this breaks when the owner doesn't have a character but im too lazy to fix it
	origin = owner.Character.Head.Position - Vector3.yAxis * 4.5
else
	local ray = workspace:Raycast(Vector3.yAxis * 100, Vector3.yAxis * -200)
	if ray then
		origin = ray.Position
	end
end

local Players = game:GetService('Players')

local rhexsize = 3 -- Functional Programming: BEGONE
local sq = math.sqrt
local rhex = {
	position = function(coord: Vector3): Vector3
		local rv, qv = Vector3.new(3/2, 0, sq(3)/2), Vector3.new(0, 0, sq(3))
		return (coord.X * rv + coord.Y * qv) * rhexsize
	end,
	new = function()
		local mid = Instance.new('Part')
		mid.Size = Vector3.new(rhexsize, 1, rhexsize * sq(3))

		local w1 = Instance.new('WedgePart')
		w1.Size = Vector3.new(1, rhexsize / 2, rhexsize * sq(3) / 2)
		w1.Orientation = Vector3.new(0, 0, 90)

		local w2 = Instance.new('WedgePart')
		w2.Size = w1.Size
		w2.Orientation = Vector3.new(0, 0, -90)

		local w3 = Instance.new('WedgePart')
		w3.Size = w1.Size
		w3.Orientation = Vector3.new(180, 0, 90)

		local w4 = Instance.new('WedgePart')
		w4.Size = w1.Size
		w4.Orientation = Vector3.new(180, 0, -90)

		local repr = {
			mid = mid,
			group = { mid, w1, w2, w3, w4 }
		}
		setmetatable(repr, {
			__newindex = function(_, k, v)
				if k == 'Position' then
					mid.Position = v
					w1.Position = v + Vector3.new(-rhexsize * 0.75, 0, -rhexsize * sq(3) / 4)
					w2.Position = v + Vector3.new(rhexsize * 0.75, 0, -rhexsize * sq(3) / 4)
					w3.Position = v + Vector3.new(-rhexsize * 0.75, 0, rhexsize * sq(3) / 4)
					w4.Position = v + Vector3.new(rhexsize * 0.75, 0, rhexsize * sq(3) / 4)
				elseif k == 'Height' then
					mid.Size = Vector3.new(mid.Size.X, v, mid.Size.Z)
					w1.Size = Vector3.new(v, w1.Size.Y, w1.Size.Z)
					w2.Size = Vector3.new(v, w1.Size.Y, w1.Size.Z)
					w3.Size = Vector3.new(v, w1.Size.Y, w1.Size.Z)
					w4.Size = Vector3.new(v, w1.Size.Y, w1.Size.Z)
				else
					for _, e in next, repr.group do
						e[k] = v -- the typechecker has a mental breakdown when it sees this
					end
				end
			end
		})

		repr.Anchored = true
		repr.TopSurface = Enum.SurfaceType.Smooth -- i cried while writing this...
		repr.BottomSurface = Enum.SurfaceType.Smooth

		return repr
	end
}
local hex = {
	dist = function(a: Vector3, b: Vector3): number
		return math.max(math.abs(a.X - b.X), math.abs(a.Y - b.Y), math.abs(a.Z - b.Z))
	end
}

local rig = Players:CreateHumanoidModelFromUserId(owner.UserId)
rig.Parent = workspace
rig.Head.CFrame = owner.Character.Head.CFrame
local utils = {
	chatcolor = function(name: string): Color3
		local CHAT_COLORS =
			{
				Color3.new(253/255, 41/255, 67/255), -- BrickColor.new("Bright red").Color,
				Color3.new(1/255, 162/255, 255/255), -- BrickColor.new("Bright blue").Color,
				Color3.new(2/255, 184/255, 87/255), -- BrickColor.new("Earth green").Color,
				BrickColor.new("Bright violet").Color,
				BrickColor.new("Bright orange").Color,
				BrickColor.new("Bright yellow").Color,
				BrickColor.new("Light reddish violet").Color,
				BrickColor.new("Brick yellow").Color,
			}

		local function GetNameValue(pName)
			local value = 0
			for index = 1, #pName do
				local cValue = string.byte(string.sub(pName, index, index))
				local reverseIndex = #pName - index + 1
				if #pName%2 == 1 then
					reverseIndex = reverseIndex - 1
				end
				if reverseIndex%4 >= 2 then
					cValue = -cValue
				end
				value = value + cValue
			end
			return value
		end

		return CHAT_COLORS[(GetNameValue(name) % #CHAT_COLORS) + 1]
	end,
	summonrig = function(dchar, pos: Vector3, cell)
		local desc = Players:GetHumanoidDescriptionFromOutfitId(dchar.outfit)
		desc.TorsoColor = BrickColor.random().Color
		local rig = (Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6) :: Character)
		rig:ScaleTo(0.6)
		rig.Head.CFrame = CFrame.new(rhex.position(pos)) + Vector3.yAxis * (cell.rheight + 2.5) + origin
		rig.Head.Anchored = true
		rig.Humanoid.DisplayName = dchar.name
		rig.Humanoid.MaxHealth = dchar.maxhp
		rig.Humanoid.Health = rig.Humanoid.MaxHealth
		rig.Parent = script
		return rig
	end,
	gdeclare = function(message: string)
		rig.Humanoid.DisplayName = message
	end,
	randomElement = function<T>(i: { T }, exclude: { number }?): (number, T)
		local k = 0
		while true do
			local j = math.random(1, #i)
			local e = i[j]
			if e and (if exclude then not table.find(exclude, j) else true) then return j, e end
			k += 1
			if k % 16 == 0 then task.wait() end
		end
	end
}

local uconns: { RBXScriptConnection } = {}
local autojoined: { Player } = {}
local mapsize = 10
while true do
	script:ClearAllChildren()
	for i, conn in next, uconns do
		if not conn.Connected then
			uconns[i] = nil
			continue
		end
		conn:Disconnect()
	end
	local success, _ = xpcall(function()
		local joined: { Player } = table.clone(autojoined)
		local conns: { RBXScriptConnection } = {}
		local function handlePreGameCommand(player: Player)
			return function(message: string)
				if message == 'p%join' then
					local j = table.find(joined, player)
					if not j then
						table.insert(joined, player)
					end
				elseif message == "p%leave" then
					local j = table.find(joined,player)
					if j then
						table.remove(joined,j)
					end
				elseif message == 'p%auto' then
					local j = table.find(joined,player)
					if not j then
						table.insert(joined, player)
					end

					local k = table.find(autojoined,player)
					if not k then
						table.insert(autojoined, player)
					else
						table.remove(autojoined, k)
					end
				end
			end
		end
		for i, player: Player in next, Players:GetPlayers() do
			conns[i] = player.Chatted:Connect(handlePreGameCommand(player))
			table.insert(uconns, conns[i])
		end
		local pjoinConn = Players.PlayerAdded:Connect(function(player: Player)
			local conn = player.Chatted:Connect(handlePreGameCommand(player))
			table.insert(conns, conn)
			table.insert(uconns, conn)
		end)
		local leftConn = Players.PlayerRemoving:Connect(function(player: Player)
			local i = table.find(joined, player)
			if i then
				table.remove(joined, i)
			end
		end)
		table.insert(uconns, leftConn)
		local t = 25
		local skipConn: RBXScriptConnection = nil
		if owner then
			skipConn = owner.Chatted:Connect(function(h)
				if h == "p%skip" then
					t = 0
				end
			end)
			table.insert(uconns, skipConn)
		end
		--_gmessage = Instance.new('Hint', script)
		while t > 0 do
			local roster = ""
			for _, player in ipairs(joined) do
				roster ..= player.DisplayName .. '\n'
			end
			utils.gdeclare(`{('\n'):rep(#joined)}\n\ngithub.com/fofl12/sk - Starting the war in {t} seconds - Say p%join or p%auto to join\n{roster}`)
			task.wait(1)
			t -= 1
		end
		leftConn:Disconnect()
		pjoinConn:Disconnect()
		for _, conn in next, conns do
			if conn.Connected then
				conn:Disconnect()
			end
		end
		if skipConn then skipConn:Disconnect() end
		--_gmessage:Destroy()

		local cells = {}
		local rcells = {}
		local ents = {}
		local rents = {}

		for r = -mapsize, mapsize do
			for q = -mapsize, mapsize do
				local s = -r -q
				if math.abs(r) + math.abs(q) + math.abs(s) > mapsize * 2 then continue end
				local height = math.noise(r / 5, q / 5, s / 5) * 4 + 2
				local rcell = rhex.new()
				rcell.Anchored = true
				local clickd = Instance.new('ClickDetector', rcell.mid)
				local voffset = 0
				if height < 0.5 then
					rcell.BrickColor = BrickColor.Blue()
					rcell.Height = 0.5
					voffset = 0.5
				elseif height < 1 then
					rcell.BrickColor = BrickColor.Yellow()
					rcell.Height = height
					voffset = height
				elseif height < 3 then
					rcell.Color = Color3.new(0.278431, 0.525490, 0.215686):Lerp(Color3.new(0.074510, 0.266667, 0.066667), (height - 1) / 5)
					rcell.Height = height
					voffset = height
				else
					rcell.BrickColor = BrickColor.White()
					rcell.Height = height * 1.5
					voffset = height * 1.5
				end
				cells[Vector3.new(r, q, s)] = {
					height = height,
					rheight = voffset,
					water = height < 0.5,
					mountain = height > 3,
					slow = height < 1,
					click = clickd.MouseClick
				}
				rcell.Position = rhex.position(Vector3.new(r, q)) + origin + Vector3.yAxis * voffset / 2
				rcell.Parent = script
				rcells[Vector3.new(r, q, s)] = rcell
			end
		end

		for _ = 1, mapsize do
			local pos: Vector3 = nil
			while (not cells[pos]) or cells[pos].water or cells[pos].mountain do
				local r, q = math.random(-mapsize, mapsize), math.random(-mapsize, mapsize)
				local s = -r -q
				pos = Vector3.new(r, q, s)
			end
			local cell = cells[pos]
			local id, dchar = utils.randomElement(chars, { 1 })
			ents[pos] = {
				owner = nil,
				dchar = dchar,
				hp = dchar.maxhp
			}
			local rig = utils.summonrig(dchar, pos, cell)
			rents[pos] = rig
		end

		for _, player in next, joined do
			local pos: Vector3 = nil
			while (not cells[pos]) or ents[pos] or cells[pos].water or cells[pos].mountain do
				local r, q = math.random(-mapsize, mapsize), math.random(-mapsize, mapsize)
				local s = -r -q
				pos = Vector3.new(r, q, s)
			end
			local cell = cells[pos]
			local dchar = chars[1]
			ents[pos] = {
				owner = player,
				dchar = dchar,
				hp = dchar.maxhp
			}
			local rig = utils.summonrig(dchar, pos, cell)
			rents[pos] = rig
			local name = string.char(math.random(65, 90)) .. ' ' .. ({utils.randomElement(names)})[2]
			rig.Humanoid.DisplayName = name
			if player.Character and player.Character:FindFirstChild('Head') and player.Character:FindFirstChild('Humanoid') then
				player.Character.Head.CFrame = rig.Head.CFrame + Vector3.yAxis * 10
				player.Character.Humanoid.DisplayName = name
			end
		end
	end, function(...) warn(..., debug.traceback(' ')) end)
	if not success then
		utils.gdeclare('Restarting due to error')
		script:ClearAllChildren()
	end
	task.wait(30)
end