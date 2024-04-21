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
type Cell = {
	real: Part,
	height: number,
	gold: boolean,
	sand: boolean,
	snow: boolean,
	water: boolean,
	rheight: number,
	click: RBXScriptSignal
}
type CharDescription = {
	name: string,
	outfit: number,
	maxhp: number,
	speed: number,
	attack: number,
	range: number
}
type Ent = {
	owner: number?,
	dchar: CharDescription,
	hp: number,
	lastTurn: number,
	real: Character
}
type Hex = {
	r: number,
	q: number,
	s: number
}

local chars: { CharDescription } = {
	{
		name = 'King',
		outfit = 29228213795,
		maxhp = 300,
		speed = 3,
		attack = 20,
		range = 3,
	},
	{
		name = 'Warrior',
		outfit = 29228438216,
		maxhp = 100,
		speed = 3,
		attack = 70,
		range = 1,
	},
	{
		name = 'Tank',
		outfit = 29228386770,
		maxhp = 200,
		speed = 1,
		attack = 70,
		range = 3,
	},
	{
		name = 'Commander',
		outfit = 29228336290,
		maxhp = 150,
		speed = 4,
		attack = 50,
		range = 1,
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
		maxhp = 80,
		speed = 3,
		attack = 70,
		range = 6,
	},
	{
		name = 'Scout',
		outfit = 29228157425,
		maxhp = 60,
		speed = 6,
		attack = 40,
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
local Debris = game:GetService('Debris')

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

		local repr: { mid: Part, group: { BasePart }, att: Attachment } = {
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
	end,
	round = function(a: Vector3): Vector3
		local r, q, s = math.round(a.X), math.round(a.Y), math.round(a.Z)
		local dr, dq, ds = math.abs(a.X - r), math.abs(a.Y - q), math.abs(a.Z, s)
		if dr > dq and dr > ds then
			r = -q -s
		elseif dq > dr and dq > ds then
			q = -r -s
		elseif ds > dr and ds > dq then
			s = -r -q
		end
		return Vector3.new(r, q, s)
	end,
	f3 = function(a: Vector3): Vector3
		return Vector3.new(a.X, a.Y, a.Z)
	end
}

local rig: Character = nil
local utils: { -- the luau moment
	chatcolor: (name: string) -> Color3,
	summonrig: (any, pos: Vector3, any, Color3?) -> (),
	randomElement: <T>(i: { T }, exlude: { number }?) -> T,
	gdeclare: (message: string) -> (),
	b64char: (n: number) -> string,
	hexcode: (cell: Vector3, mapsize: number) -> string,
	ownercalc: (cells: { [Vector3]: Cell }, ents: { [Vector3]: Ent }) -> {{ range: number, attack: number, speed: number }}
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
			local desc = Players:GetHumanoidDescriptionFromOutfitId(utils.randomElement(chars).outfit)
			rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6) :: Character
			rig.Parent = script -- how do i make my typechecker shut up?
			rig.Head.CFrame = CFrame.new(origin) + Vector3.yAxis * 6
		end
		rig.Humanoid.DisplayName = message
	end,
	randomElement = function<T>(i: { T }, exclude: { number }?): T
		local k = 0
		while true do
			local j = math.random(1, #i)
			local e = i[j]
			if e and (if exclude then not table.find(exclude, j) else true) then return e end
			k += 1
			if k % 16 == 0 then task.wait() end
		end
	end,
	b64char = function(n: number): string
		return ('1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'):sub(n + 1, n + 1)
	end,
	hexcode = function(cell: Vector3, mapsize: number): string
		return utils.b64char(cell.X + mapsize) .. utils.b64char(cell.Y + mapsize)
	end,
	ownercalc = function(cells, ents)
		local ret = {}
		for pos, ent in next, ents do
			if ent.dchar.name ~= 'Commander' then continue end
			if not ent.owner then continue end
			if not cells[pos].gold then continue end
			if ret[ent.owner] then
				ret[ent.owner].range += 2
				ret[ent.owner].speed += 2
				ret[ent.owner].attack += 2
			else
				ret[ent.owner] = {
					range = 2,
					speed = 2,
					attack = 20
				}
			end
		end
		return ret
	end
}

local uconns: { RBXScriptConnection } = {}
local autojoined: { Player } = {}
local mapsize = 12
while true do
	task.wait()
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
		local chatconns: { RBXScriptConnection } = {}
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
			chatconns[i] = player.Chatted:Connect(handlePreGameCommand(player))
			table.insert(uconns, chatconns[i])
		end
		local pjoinConn = Players.PlayerAdded:Connect(function(player: Player)
			local conn = player.Chatted:Connect(handlePreGameCommand(player))
			table.insert(chatconns, conn)
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
			if #joined > 0 then
				t -= 1
			end
		end
		leftConn:Disconnect()
		pjoinConn:Disconnect()
		for _, conn in next, chatconns do
			if conn.Connected then
				conn:Disconnect()
			end
		end
		if skipConn then skipConn:Disconnect() end
		--_gmessage:Destroy()

		local cells: { [Vector3]: Cell } = {}
		local ents: { [Vector3]: Ent } = {}

		local tparams = {
			scale = math.random() * 3 + 2,
			offset = math.random() * 5,
			value = math.random() * 0.03,
			snowTolerance = math.random() * 0.4 + 0.1,
			snowSpeed = math.random() * 0.4 + 0.6,
			sandSpeed = math.random() * 0.4 + 0.6
		}
		--local fmid: Part = nil
		local rng = math.random() * 500
		for r = -mapsize, mapsize do
			for q = -mapsize, mapsize do
				if q % 4 == 0 then task.wait() end
				local s = -r -q
				--if math.abs(r) + math.abs(q) + math.abs(s) > mapsize * 2 then continue end
				if hex.dist(Vector3.new(), Vector3.new(r, q, s)) > mapsize then continue end
				local height = math.noise(r / 5 + rng, q / 5 - rng, s / 5 + rng) * tparams.scale + tparams.offset
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
				prompt.ObjectText = 'Cell ' .. utils.hexcode(Vector3.new(r, q), mapsize)
				prompt.HoldDuration = 0
				prompt.RequiresLineOfSight = false
				prompt.Parent = rcell.att
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
					click = prompt.Triggered,
					real = rcell
				}
				rcell.Position = rhex.position(Vector3.new(r, q)) + origin + Vector3.yAxis * voffset / 2
				rcell.Parent = script
			end
		end
		--[[
		local unionPending = {}
		for pos, cell in next, cells do
			for _, p in next, cell.real.group do
				if p == mid then continue end
				unionPending[#unionPending + 1] = p
			end
			task.wait()
		end
		local union = fmid:UnionAsync(unionPending, Enum.CollisionFidelity.)
		]]

		for _ = 1, mapsize * 2 do
			local pos: Vector3 = nil
			while (not cells[pos]) or ents[pos] or cells[pos].water or (cells[pos].snow and math.random() < tparams.snowTolerance) do
				local r, q = math.random(-mapsize, mapsize), math.random(-mapsize, mapsize)
				local s = -r -q
				pos = Vector3.new(r, q, s)
				task.wait()
				if math.random() < 0.1 then print('finding', pos, cells[pos]) end
			end
			local cell = cells[pos]
			local dchar = utils.randomElement(chars, { 1 })
			local rig = utils.summonrig(dchar, pos, cell)
			ents[pos] = {
				owner = nil,
				dchar = dchar,
				hp = dchar.maxhp,
				real = rig,
				lastTurn = -1
			}
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
			local name = string.char(math.random(65, 90)) .. ' ' .. utils.randomElement(names)
			playing[i] = {
				owned = { pos },
				name = name,
				kingPos = pos,
				real = player,
				color = utils.chatcolor(player.Name),
			}
			local cell = cells[pos]
			local dchar = chars[1]
			local rig = utils.summonrig(dchar, pos, cell, utils.chatcolor(player.Name))
			ents[pos] = {
				owner = i,
				dchar = dchar,
				hp = dchar.maxhp,
				lastTurn = -1,
				real = rig
			}
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
		local function kill(i)
			kings -= 1
			local p = playing[i]
			for _, pos in next, p.owned do
				if not ents[pos] then continue end
				ents[pos].owner = nil
				ents[pos].real.Humanoid.DisplayName = ents[pos].dchar.name
			end
			if not ents[p.kingPos] then return end
			ents[p.kingPos].real:Destroy()
			ents[p.kingPos].real = nil
			ents[p.kingPos] = nil
		end
		table.insert(uconns, Players.PlayerRemoving:Connect(function(player)
			for i, p in next, playing do
				if p.real ~= player then continue end
				kill(i)
				break
			end
		end))
		local turn = 0
		local survival = kings == 1
		while kings > (if survival then 0 else 1) do
			turn += 1
			utils.gdeclare('Turn ' .. tostring(turn))
			task.wait(3)
			utils.gdeclare('Say p%done to complete turn ' .. tostring(turn))
			votes = 0
			local moves = {}
			local beams = {}
			local conns = {}
			local boosts = utils.ownercalc(cells, ents)
			for pos, ent in next, ents do
				if not ent.owner then continue end
				if ent.lastTurn == turn then continue end
				local range = ent.dchar.range + (if boosts[ent.owner] then boosts[ent.owner].range else 0)
				local speed = ent.dchar.speed + (if boosts[ent.owner] then boosts[ent.owner].speed else 0)
				local cell = cells[pos]
				local conn = cell.click:Once(function(player: BPlayer)
					if player ~= playing[ent.owner].real then return end
					local tool = Instance.new('Tool')
					tool.Name = ent.dchar.name
					tool.ToolTip = 'Click a cell to move or drop to transfer ownership'
					tool.Enabled = false
					local handle = Instance.new('Part')
					handle.Transparency = 1
					handle.Name = 'Handle'
					handle.Position = ent.real.Head.Position
					handle.Parent = tool
					local beam = Instance.new('Beam', handle)
					beam.Attachment0 = ent.real.Head.Attachment
					beam.Attachment1 = Instance.new('Attachment', handle)
					beam.Color = ColorSequence.new(utils.chatcolor(player.Name))
					beam.FaceCamera = true
					table.insert(beams, beam)
					tool.Parent = player.Backpack
					local hconns: { RBXScriptConnection } = {}
					for tpos, tcell in next, cells do
						local dist = hex.dist(tpos, pos)
						if dist > (if ents[tpos] then range else speed) or tpos == pos then continue end
						local good = true
						for _, move in next, moves do
							if move.to == tpos and not move.interact then
								good = false
								break
							end
						end
						if not good then continue end
						local rdist = 0
						--print(utils.hexcode(tpos, mapsize), '----')
						for i = 1, dist + 1 do
							--print(utils.hexcode(hex.round(pos:Lerp(tpos, i / dist)), mapsize))
							local icell = cells[hex.round(hex.f3(pos):Lerp(hex.f3(tpos), i / (dist + 1)))]
							local p = Instance.new('Part')
							p.Size = Vector3.one * 0.5
							p.Anchored = true
							p.BrickColor = BrickColor.Green()
							p.Material = Enum.Material.Neon
							p.Position = rhex.position(hex.round(hex.f3(pos):Lerp(hex.f3(tpos), i / (dist + 1)))) + origin + Vector3.yAxis * (6 + tcell.rheight - (i / 2))
							p.Parent = script
							Debris:AddItem(p, 40)
							local pcell = cells[hex.round(pos:Lerp(tpos, (i - 1) / (dist + 1)))]
							if not (pcell and icell) then warn('something has gone horribly wrong', hex.round(hex.f3(pos):Lerp(hex.f3(tpos), i / (dist + 1)))); p.BrickColor = BrickColor.Red(); rdist += 9999; break end
							if icell.snow then
								rdist += 1 / tparams.snowSpeed
							elseif icell.sand then
								rdist += 1 / tparams.sandSpeed
							elseif icell.water then
								rdist += 999999
							end
						end
						if rdist > (if ents[tpos] then range else speed) or tpos == pos then continue end
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
							ent.real.Humanoid.DisplayName = ent.dchar.name .. '\n' .. playing[holder].name
							beam.Attachment1 = tcell.real.att
							beam.Parent = tcell.real.mid
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
			boosts = utils.ownercalc(cells, ents)
			for _, move in next, moves do -- could be optimized
				if not move.interact then continue end
				local fchar = ents[move.from]
				local tchar = ents[move.to]
				if not (fchar and tchar) then continue end
				if fchar.dchar.name == 'King' and not tchar.owner then
					ents[move.to].owner = fchar.owner
					ents[move.to].real.Humanoid.DisplayName = tchar.dchar.name .. '\n' .. playing[fchar.owner].name
				elseif fchar.dchar.name == 'Explosive' then
					ents[move.to].hp -= fchar.dchar.attack + (if boosts[fchar.owner] then boosts[fchar.owner].attack else 0)
					ents[move.from].hp = 0
				elseif tchar.dchar.name == 'Explosive' then
					ents[move.from].hp -= tchar.dchar.attack + (if boosts[tchar.owner] then boosts[tchar.owner].attack else 0)
					ents[move.to].hp = 0
				else
					ents[move.to].hp -= fchar.dchar.attack + (if boosts[fchar.owner] then boosts[fchar.owner].attack else 0)
				end
				fchar.real.Humanoid.Health = ents[move.from].hp
				tchar.real.Humanoid.Health = ents[move.to].hp
				if ents[move.from].hp <= 0 then
					if fchar.dchar.name == 'King' then
						kill(fchar.owner)
					else
						if fchar.owner ~= nil then
							table.remove(playing[fchar.owner].owned, table.find(playing[fchar.owner].owned, move.from))
						end
						ents[move.from].real:Destroy()
						ents[move.from] = nil
					end
				end
				if ents[move.to].hp <= 0 then
					if tchar.dchar.name == 'King' then
						kill(tchar.owner)
					else
						if tchar.owner ~= nil then
							table.remove(playing[tchar.owner].owned, table.find(playing[tchar.owner].owned, move.from))
						end
						ents[move.to].real:Destroy()
						ents[move.to] = nil
					end
				end
			end
			for _, move in next, moves do -- could be optimized
				if move.interact then continue end
				local fchar = ents[move.from]
				if not fchar then continue end
				ents[move.from].real.Head.CFrame = CFrame.new(rhex.position(move.to)) + Vector3.yAxis * (cells[move.to].rheight + 2.5) + origin
				ents[move.from] = nil
				ents[move.to] = fchar
			end
		end
		utils.gdeclare('Game Over !')
		task.wait(10)
	end, function(...)
		warn(debug.traceback(...))
	end)
	if not success then
		utils.gdeclare('Restarting due to error ' .. (err or 'fix your sandbox'))
		script:ClearAllChildren()
	end
	task.wait(30)
end