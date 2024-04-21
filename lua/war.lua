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
type BPlayer = Player & {
	Backpack: Backpack
}
type Owner = BPlayer & {
	Character: Character,
	Chatted: RBXScriptSignal & {
		Connect: ((string) -> ()) -> RBXScriptConnection
	}
}
type Playing = {
	real: BPlayer,
	owned: { Vector3 },
	kingPos: Vector3?,
	color: Color3,
	name: string
}

local chars = {
	{
		name = 'King',
		outfit = 29228213795,
		maxhp = 500,
		speed = 3,
		attack = 20,
		range = 1,
	},
	{
		name = 'Warrior',
		outfit = 29228438216,
		maxhp = 100,
		speed = 4,
		attack = 40,
		range = 1,
	},
	{
		name = 'Tank',
		outfit = 29228386770,
		maxhp = 200,
		speed = 1,
		attack = 50,
		range = 3,
	},
	{
		name = 'Commander',
		outfit = 29228336290,
		maxhp = 150,
		speed = 4,
		attack = 60,
		range = 3,
	},
	{
		name = 'Explosive',
		outfit = 29228243221,
		maxhp = 1,
		speed = 3,
		attack = 150,
		range = 1,
	},
	{
		name = 'Archer',
		outfit = 29228180259,
		maxhp = 60,
		speed = 3,
		attack = 50,
		range = 5,
	},
	{
		name = 'Scout',
		outfit = 29228157425,
		maxhp = 60,
		speed = 6,
		attack = 30,
		range = 2,
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

		local att = Instance.new('Attachment', mid)
		--Instance.new('Sparkles', att)

		local repr = {
			mid = mid,
			group = { mid, w1, w2, w3, w4 },
			att = att
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
					att.Position = Vector3.yAxis * v / 2
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
		--return sq((math.abs(a.X - b.X) ^ 2) + (math.abs(a.Y - b.Y) ^ 2) + (math.abs(a.Z - b.Z) ^ 2)) -- if you use this, Do not
	end
}

local rig: Character = nil
local utils: { -- the luau moment
	chatcolor: (name: string) -> Color3,
	summonrig: (any, pos: Vector3, any, Color3?) -> (),
	randomElement: <T>(i: { T }, exlude: { number }?) -> (number, T),
	gdeclare: (message: string) -> (),
	b64char: (n: number) -> string
} = nil
utils = {
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
	summonrig = function(dchar, pos: Vector3, cell, color: Color3?)
		local desc = Players:GetHumanoidDescriptionFromOutfitId(dchar.outfit)
		desc.TorsoColor = if color then color else BrickColor.random().Color
		local rig = (Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6) :: Character)
		rig:ScaleTo(0.6)
		rig.Head.CFrame = CFrame.new(rhex.position(pos)) + Vector3.yAxis * (cell.rheight + 2.5) + origin
		rig.Head.Anchored = true
		rig.Humanoid.DisplayName = dchar.name
		rig.Humanoid.MaxHealth = dchar.maxhp
		rig.Humanoid.Health = rig.Humanoid.MaxHealth
		Instance.new('Attachment', rig.Head)
		rig.Parent = script
		return rig
	end,
	gdeclare = function(message: string)
		if not (rig and rig:FindFirstChild('Humanoid')) then
			local desc = Players:GetHumanoidDescriptionFromOutfitId(({utils.randomElement(chars)})[2].outfit)
			rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6) :: Character
			rig.Parent = script
			rig.Head.CFrame = CFrame.new(origin) + Vector3.yAxis * 6
		end
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
	end,
	b64char = function(n: number): string
		return ('1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'):sub(n + 1, n + 1)
	end
}

local uconns: { RBXScriptConnection } = {}
local autojoined: { Player } = {}
local mapsize = 12
while true do
	script:ClearAllChildren()
	for i, conn in next, uconns do
		if not conn.Connected then
			uconns[i] = nil
			continue
		end
		conn:Disconnect()
	end
	local success, err = xpcall(function()
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
		local t = 40
		local skipConn: RBXScriptConnection = nil
		if owner then
			skipConn = owner.Chatted:Connect(function(h)
				if h == "p%skip" then
					t = 0
				elseif h == 'p%jskip' then
					table.insert(joined, owner)
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

		local tparams = {
			scale = math.random() * 3 + 2,
			offset = math.random() * 5,
			value = math.random() * 0.03,
			snowTolerance = math.random() * 0.4,
			snowSpeed = math.random() * 0.5 + 0.5,
			sandSpeed = math.random() * 0.5 + 0.5
		}
		for r = -mapsize, mapsize do
			for q = -mapsize, mapsize do
				local s = -r -q
				--if math.abs(r) + math.abs(q) + math.abs(s) > mapsize * 2 then continue end
				if hex.dist(Vector3.zero, Vector3.new(r, q, s)) > mapsize then continue end
				local height = math.noise(r / 5, q / 5, s / 5) * tparams.scale + tparams.offset
				local gold = math.random() < tparams.value
				local rcell = rhex.new()
				rcell.Anchored = true
				--[[ -- tragedy...
				local clickbind = Instance.new('BindableEvent', rcell.mid)
				for _, part in next, rcell.group do
					local conn = Instance.new('ClickDetector', part).MouseClick:Connect(function(...)
						clickbind:Fire(...)
					end)
					table.insert(uconns, conn)
				end
				]]
				local prompt = Instance.new('ProximityPrompt')
				prompt.ActionText = 'Pick'
				prompt.ObjectText = 'Cell ' .. utils.b64char(r + mapsize) .. utils.b64char(q + mapsize)
				prompt.HoldDuration = 0
				prompt.RequiresLineOfSight = false
				prompt.Parent = rcell.mid
				local voffset = 0
				if height < 0.5 then
					rcell.BrickColor = BrickColor.Blue()
					rcell.Material = Enum.Material.Glass
					rcell.Height = 0.5
					voffset = 0.5
				elseif height < 1 then
					rcell.BrickColor = BrickColor.Yellow()
					rcell.Material = Enum.Material.Sand
					rcell.Height = height
					voffset = height
				elseif height < 3 then
					rcell.Color = Color3.new(0.278431, 0.525490, 0.215686):Lerp(Color3.new(0.074510, 0.266667, 0.066667), (height - 1) / 5)
					rcell.Material = Enum.Material.Grass
					rcell.Height = height
					voffset = height
				else
					rcell.BrickColor = BrickColor.White()
					rcell.Material = Enum.Material.Sand
					rcell.Height = height * 1.5
					voffset = height * 1.5
				end
				if gold then
					rcell.Color = BrickColor.random().Color
					rcell.Material = Enum.Material.Foil
				end
				cells[Vector3.new(r, q, s)] = {
					height = height,
					rheight = voffset,
					water = height < 0.5,
					snow = height > 3,
					sand = height < 1,
					gold = gold,
					click = prompt.Triggered
				}
				rcell.Position = rhex.position(Vector3.new(r, q)) + origin + Vector3.yAxis * voffset / 2
				rcell.Parent = script
				rcells[Vector3.new(r, q, s)] = rcell
			end
		end

		for _ = 1, mapsize * 2 do
			local pos: Vector3 = nil
			while (not cells[pos]) or ents[pos] or cells[pos].water or (cells[pos].snow and math.random() < tparams.snowTolerance) do
				local r, q = math.random(-mapsize, mapsize), math.random(-mapsize, mapsize)
				local s = -r -q
				pos = Vector3.new(r, q, s)
				task.wait()
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

		local playing = {}
		local votes = 0
		for i, player in next, joined do
			local pos: Vector3 = nil
			while (not cells[pos]) or ents[pos] or cells[pos].water or (cells[pos].snow and math.random() < tparams.snowTolerance) do
				local r, q = math.random(-mapsize, mapsize), math.random(-mapsize, mapsize)
				local s = -r -q
				pos = Vector3.new(r, q, s)
				task.wait()
			end
			local name = string.char(math.random(65, 90)) .. ' ' .. ({utils.randomElement(names)})[2]
			playing[i] = {
				owned = { pos },
				name = name,
				kingPos = pos,
				real = player,
				color = utils.chatcolor(owner.Name)
			}
			local cell = cells[pos]
			local dchar = chars[1]
			ents[pos] = {
				owner = i,
				dchar = dchar,
				hp = dchar.maxhp,
				lastTurn = -1
			}
			local rig = utils.summonrig(dchar, pos, cell, utils.chatcolor(player.Name))
			rents[pos] = rig
			rig.Humanoid.DisplayName = 'King\n' .. name
			if player.Character and player.Character:FindFirstChild('Head') and player.Character:FindFirstChild('Humanoid') then
				player.Character.Head.CFrame = rig.Head.CFrame + Vector3.yAxis * 10
				player.Character.Humanoid.DisplayName = name
			end
			table.insert(uconns, player.Chatted:Connect(function(message: string) 
				if message == 'p%done' then
					votes += 1 -- this needs to be fixed (urgently)
				end
			end))
		end

		local kings = #playing
		table.insert(uconns, Players.PlayerRemoving:Connect(function(player)
			for i, p in next, playing do
				if p.real ~= player then continue end
				for _, pos in next, p.owned do
					ents[pos].owner = nil
					rents[pos].Humanoid.DisplayName = ents[pos].dchar.name
				end
				rents[p.kingPos]:Destroy()
				rents[p.kingPos] = nil
				ents[p.kingPos] = nil
				kings -= 1
				break
			end
		end))
		local turn = 0
		while kings > 0 do
			turn += 1
			utils.gdeclare('Turn ' .. tostring(turn))
			task.wait(3)
			utils.gdeclare('Say p%done to complete turn ' .. tostring(turn))
			votes = 0
			local moves = {}
			local beams = {}
			local conns = {}
			for pos, ent in next, ents do
				if not ent.owner then continue end
				if ent.lastTurn == turn then continue end
				local cell = cells[pos]
				local rent = rents[pos]
				local conn = cell.click:Once(function(player: BPlayer)
					if player ~= playing[ent.owner].real then return end
					local tool = Instance.new('Tool')
					tool.Name = ent.dchar.name
					tool.ToolTip = 'Click a cell to move or drop to transfer ownership'
					tool.CanBeDropped = ent.dchar.name ~= 'King'
					tool.Enabled = false
					local handle = Instance.new('Part')
					handle.Transparency = 1
					handle.Name = 'Handle'
					handle.Position = rent.Head.Position
					handle.Parent = tool
					local beam = Instance.new('Beam', handle)
					beam.Attachment0 = rent.Head.Attachment
					beam.Attachment1 = Instance.new('Attachment', handle)
					beam.Color = ColorSequence.new(utils.chatcolor(player.Name))
					beam.FaceCamera = true
					table.insert(beams, beam)
					tool.Parent = player.Backpack
					local hconns: { RBXScriptConnection } = {}
					task.wait(1)
					for tpos, tcell in next, cells do
						if hex.dist(tpos, pos) > ent.dchar.speed or tpos == pos then continue end
						if ent[tpos] and hex.dist(tpos, pos) > ent.dchar.range then continue end
						local rtcell = rcells[tpos]
						local hconn = tcell.click:Once(function(player)
							if not tool.Parent:FindFirstChildWhichIsA('Humanoid') then return end
							local rholder: Player = Players:GetPlayerFromCharacter(tool.Parent)
							if rholder ~= player then return end
							local holder = nil
							for i, ph in next, playing do
								if ph.real == rholder then
									holder = i
									break
								end
							end
							if not holder then return end
							ent.owner = holder
							rent.Humanoid.DisplayName = ent.dchar.name .. '\n' .. playing[holder].name
							beam.Attachment1 = rtcell.att
							beam.Parent = rtcell.mid
							table.insert(moves, {
								from = pos,
								to = tpos,
								interact = ents[tpos] ~= nil
							})
							for _, conn in next, hconns do
								if not conn.Connected then continue end
								conn:Disconnect()
							end
							tool:Destroy()
							ent.lastTurn = turn
						end)
						table.insert(hconns, hconn)
						table.insert(uconns, hconn)
					end
				end)
				table.insert(uconns, conn)
				table.insert(conns, conn)
			end
			while votes < kings do task.wait(1) end
			for _, beam in next, beams do
				beam:Destroy()
			end
			for _, conn in next, conns do
				if not conn.Connected then continue end
				conn:Disconnect()
			end
			utils.gdeclare('The moves are being considered')
			for _, move in next, moves do -- could be optimized
				if not move.interact then continue end
				local fchar = ents[move.from]
				local tchar = ents[move.to]
				if fchar.dchar.name == 'King' and not tchar.owner then
					ents[move.to].owner = fchar.owner
					rents[move.to].Humanoid.DisplayName = tchar.dchar.name .. '\n' .. playing[fchar.owner].name
				elseif fchar.dchar.name == 'Explosive' then
					ents[move.to].hp -= fchar.dchar.attack
					ents[move.from].hp = 0
				elseif tchar.dchar.name == 'Explosive' then
					ents[move.from].hp -= fchar.dchar.attack
					ents[move.to].hp = 0
				else
					ents[move.to].hp -= fchar.dchar.attack
				end
				if ents[move.from].hp <= 0 then
					if fchar.owner ~= nil then
						table.remove(playing[fchar.owner].owner, table.find(playing[fchar.owner].owned, move.from))
					end
					ents[move.from] = nil
					rents[move.from]:Destroy()
					rents[move.from] = nil
				end
				if ents[move.to].hp <= 0 then
					if tchar.owner ~= nil then
						table.remove(playing[tchar.owner].owner, table.find(playing[tchar.owner].owned, move.from))
					end
					ents[move.to] = nil
					rents[move.to]:Destroy()
					rents[move.to] = nil
				end
			end
			for _, move in next, moves do -- could be optimized
				if move.interact then continue end
				local fchar = ents[move.from]
				ents[move.from] = nil
				ents[move.to] = fchar
				rents[move.from].Head.CFrame = CFrame.new(rhex.position(move.to)) + Vector3.yAxis * (cells[move.to].rheight + 2.5) + origin
				rents[move.to] = rents[move.from]
				rents[move.from] = nil
			end
		end
	end, function(...)
		warn(debug.traceback(...))
	end)
	if not success then
		utils.gdeclare('Restarting due to error ' .. (err or 'fix your sandbox'))
		script:ClearAllChildren()
	end
	task.wait(30)
end