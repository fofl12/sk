--[[
	warnet.lua
	Copyright 2024 fofl12 (comsurg (h)) BSD 3-clause New License
	github.com/fofl12/sk
	h Industry a1 client implementation

	the hexagons were made possible by the saint that wrote this: https://www.redblobgames.com/grids/hexagons/
	contributions to the pre-game settings by ryry (copied from plateofdoom.lua)
	cat assets from android 11 under apache license
	base64 encoding and decoding from github.com/Reselim/Base64 under MIT license
]]
owner=game.Players:WaitForChild('comsurg')
assert(getfenv().owner, 'wrong environment')

local server = 'http://localhost:3000' -- terrible things will happen to you if you dox me
local displayname = 'roblox client'

type Character = Model & {
	Head: Part,
	Humanoid: Humanoid
}
type Owner = Player & {
	Character: Character,
	Backpack: Backpack,
	Chatted: RBXScriptSignal & {
		Connect: ((string) -> ()) -> RBXScriptConnection
	}
}
type Cell = {
	real: Part,
	height: number,
	type: number,
	prompt: ProximityPrompt
}
type CharDescription = {
	outfit: number,
	maxhp: number,
	speed: number,
	attack: number,
	range: number
}
type Ent = {
	owned: boolean,
	dchar: string,
	hp: number,
	real: Character,
	pos: number
}

local chars: { [string]: CharDescription } = {
	King = {
		name = 'King', -- the
		outfit = 29228213795,
		maxhp = 300,
		speed = 3,
		attack = 20,
		range = 3,
	},
	Warrior = {
		name = 'Warrior',
		outfit = 29228438216,
		maxhp = 100,
		speed = 3,
		attack = 70,
		range = 1,
	},
	Tank = {
		name = 'Tank',
		outfit = 29228386770,
		maxhp = 200,
		speed = 1,
		attack = 70,
		range = 3,
	},
	Commander = {
		name = 'Commander',
		outfit = 29228336290,
		maxhp = 150,
		speed = 4,
		attack = 50,
		range = 1,
	},
	Explosive = {
		name = 'Explosive',
		outfit = 29228243221,
		maxhp = 1,
		speed = 3,
		attack = 150,
		range = 1,
	},
	Archer = {
		name = 'Archer',
		outfit = 29228180259,
		maxhp = 80,
		speed = 3,
		attack = 70,
		range = 6,
	},
	Scout = {
		name = 'Scout',
		outfit = 29228157425,
		maxhp = 60,
		speed = 6,
		attack = 40,
		range = 2,
	},
	['h Synthesis'] = {
		name = 'h Synthesis',
		outfit = 147030032777,
		maxhp = 200,
		speed = 2,
		attack = 0,
		range = 0
	}
}

local origin = Vector3.zero
local owner: Owner = getfenv().owner
if owner.Character and owner.Character:FindFirstChild('Head') then
	origin = owner.Character.Head.Position - Vector3.yAxis * 4.5
else
	local ray = workspace:Raycast(Vector3.yAxis * 100, Vector3.yAxis * -200)
	if ray then
		origin = ray.Position
	end
end

local Players = game:GetService('Players')
local Debris = game:GetService('Debris')
local HttpService = game:GetService("HttpService")

local rhexsize = 3 -- Functional Programming: BEGONE
local rhexh = 10
local sq = math.sqrt
local rhex = {
	position = function(coord: Vector3): Vector3
		local qv, rv = Vector3.new(3/2, 0, sq(3)/2), Vector3.new(0, 0, sq(3))
		return (coord.X * qv + coord.Y * rv) * rhexsize
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
		att.CFrame = CFrame.fromEulerAnglesXYZ(0, 0, -math.pi/2)
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
	end,
	vis = function(pos: Vector3, dir: number)
		local vis = Instance.new('Part')
		vis.Anchored = true
		vis.Size = Vector3.new(0.2, 0.2, 3)
		vis.CFrame = CFrame.new(pos + origin + Vector3.yAxis * 5) * CFrame.fromEulerAnglesYXZ(0, dir, 0)
		vis.Parent = script
		Debris:AddItem(vis, 120)
	end
}
local hex = {
	dist = function(a: Vector3, b: Vector3): number
		return math.max(math.abs(a.X - b.X), math.abs(a.Y - b.Y), math.abs(a.Z - b.Z))
		--return sq((math.abs(a.X - b.X) ^ 2) + (math.abs(a.Y - b.Y) ^ 2) + (math.abs(a.Z - b.Z) ^ 2)) -- if you use this, Do not
	end,
	round = function(a: Vector3): Vector3
		local q, r, s = math.round(a.X), math.round(a.Y), math.round(a.Z)
		local dq, dr, ds = math.abs(a.X - r), math.abs(a.Y - q), math.abs(a.Z - s)
		if dr > dq and dr > ds then
			r = -q -s
		elseif dq > ds then
			q = -r -s
		else
			s = -r -q
		end
		return Vector3.new(q, r, s)
	end,
	angle = function(a: Vector3, b: Vector3): number
		local ra, rb = rhex.position(a), rhex.position(b)
		--local ra, rb = a, b
		local dir = rb - ra
		return -math.atan2(dir.Z, dir.X) - math.pi * (1/2) -- ??????
	end
}

local rig: Character = nil
local utils: { -- the luau moment
	chatcolor: (name: string) -> Color3,
	summonrig: (rd: any) -> Character,
	randomElement: <T>(i: { T }, exlude: { number }?) -> T,
	gdeclare: (message: string) -> (),
	bchar: (n: number) -> string,
	ownercalc: (cells: { [Vector3]: Cell }, ents: { [Vector3]: Ent }) -> {{ range: number, attack: number, speed: number, h: number }},
	rangecalc: (grid: { [Vector3]: Cell }, from: Vector3, to: Vector3) -> number,
	q: (path: string) -> {}
} = nil
local b64 = (function()
local lookupValueToCharacter = buffer.create(64)
local lookupCharacterToValue = buffer.create(256)

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local padding = string.byte("=")

for index = 1, 64 do
	local value = index - 1
	local character = string.byte(alphabet, index)
	
	buffer.writeu8(lookupValueToCharacter, value, character)
	buffer.writeu8(lookupCharacterToValue, character, value)
end

local function encode(input: buffer): buffer
	local inputLength = buffer.len(input)
	local inputChunks = math.ceil(inputLength / 3)
	
	local outputLength = inputChunks * 4
	local output = buffer.create(outputLength)
	
	-- Since we use readu32 and chunks are 3 bytes large, we can't read the last chunk here
	for chunkIndex = 1, inputChunks - 1 do
		local inputIndex = (chunkIndex - 1) * 3
		local outputIndex = (chunkIndex - 1) * 4
		
		local chunk = bit32.byteswap(buffer.readu32(input, inputIndex))
		
		-- 8 + 24 - (6 * index)
		local value1 = bit32.rshift(chunk, 26)
		local value2 = bit32.band(bit32.rshift(chunk, 20), 0b111111)
		local value3 = bit32.band(bit32.rshift(chunk, 14), 0b111111)
		local value4 = bit32.band(bit32.rshift(chunk, 8), 0b111111)
		
		buffer.writeu8(output, outputIndex, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputIndex + 1, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputIndex + 2, buffer.readu8(lookupValueToCharacter, value3))
		buffer.writeu8(output, outputIndex + 3, buffer.readu8(lookupValueToCharacter, value4))
	end
	
	local inputRemainder = inputLength % 3
	
	if inputRemainder == 1 then
		local chunk = buffer.readu8(input, inputLength - 1)
		
		local value1 = bit32.rshift(chunk, 2)
		local value2 = bit32.band(bit32.lshift(chunk, 4), 0b111111)

		buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputLength - 2, padding)
		buffer.writeu8(output, outputLength - 1, padding)
	elseif inputRemainder == 2 then
		local chunk = bit32.bor(
			bit32.lshift(buffer.readu8(input, inputLength - 2), 8),
			buffer.readu8(input, inputLength - 1)
		)

		local value1 = bit32.rshift(chunk, 10)
		local value2 = bit32.band(bit32.rshift(chunk, 4), 0b111111)
		local value3 = bit32.band(bit32.lshift(chunk, 2), 0b111111)
		
		buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputLength - 2, buffer.readu8(lookupValueToCharacter, value3))
		buffer.writeu8(output, outputLength - 1, padding)
	elseif inputRemainder == 0 and inputLength ~= 0 then
		local chunk = bit32.bor(
			bit32.lshift(buffer.readu8(input, inputLength - 3), 16),
			bit32.lshift(buffer.readu8(input, inputLength - 2), 8),
			buffer.readu8(input, inputLength - 1)
		)

		local value1 = bit32.rshift(chunk, 18)
		local value2 = bit32.band(bit32.rshift(chunk, 12), 0b111111)
		local value3 = bit32.band(bit32.rshift(chunk, 6), 0b111111)
		local value4 = bit32.band(chunk, 0b111111)

		buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputLength - 2, buffer.readu8(lookupValueToCharacter, value3))
		buffer.writeu8(output, outputLength - 1, buffer.readu8(lookupValueToCharacter, value4))
	end
	
	return output
end

local function decode(input: buffer): buffer
	local inputLength = buffer.len(input)
	local inputChunks = math.ceil(inputLength / 4)
	
	-- TODO: Support input without padding
	local inputPadding = 0
	if inputLength ~= 0 then
		if buffer.readu8(input, inputLength - 1) == padding then inputPadding += 1 end
		if buffer.readu8(input, inputLength - 2) == padding then inputPadding += 1 end
	end

	local outputLength = inputChunks * 3 - inputPadding
	local output = buffer.create(outputLength)
	
	for chunkIndex = 1, inputChunks - 1 do
		local inputIndex = (chunkIndex - 1) * 4
		local outputIndex = (chunkIndex - 1) * 3
		
		local value1 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex))
		local value2 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 1))
		local value3 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 2))
		local value4 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 3))
		
		local chunk = bit32.bor(
			bit32.lshift(value1, 18),
			bit32.lshift(value2, 12),
			bit32.lshift(value3, 6),
			value4
		)
		
		local character1 = bit32.rshift(chunk, 16)
		local character2 = bit32.band(bit32.rshift(chunk, 8), 0b11111111)
		local character3 = bit32.band(chunk, 0b11111111)
		
		buffer.writeu8(output, outputIndex, character1)
		buffer.writeu8(output, outputIndex + 1, character2)
		buffer.writeu8(output, outputIndex + 2, character3)
	end
	
	if inputLength ~= 0 then
		local lastInputIndex = (inputChunks - 1) * 4
		local lastOutputIndex = (inputChunks - 1) * 3
		
		local lastValue1 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex))
		local lastValue2 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 1))
		local lastValue3 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 2))
		local lastValue4 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 3))

		local lastChunk = bit32.bor(
			bit32.lshift(lastValue1, 18),
			bit32.lshift(lastValue2, 12),
			bit32.lshift(lastValue3, 6),
			lastValue4
		)
		
		if inputPadding <= 2 then
			local lastCharacter1 = bit32.rshift(lastChunk, 16)
			buffer.writeu8(output, lastOutputIndex, lastCharacter1)
			
			if inputPadding <= 1 then
				local lastCharacter2 = bit32.band(bit32.rshift(lastChunk, 8), 0b11111111)
				buffer.writeu8(output, lastOutputIndex + 1, lastCharacter2)
				
				if inputPadding == 0 then
					local lastCharacter3 = bit32.band(lastChunk, 0b11111111)
					buffer.writeu8(output, lastOutputIndex + 2, lastCharacter3)
				end
			end
		end
	end
	
	return output
end

return {
	encode = encode,
	decode = decode,
}
end)()
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
	summonrig = function(rd)
		local desc = Players:GetHumanoidDescriptionFromOutfitId(rd.outfit)
		local rig = (Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6) :: Character)
		rig:ScaleTo(0.6)
		rig.Head.Anchored = true
		rig.Humanoid.DisplayName = rd.name
		rig.Humanoid.MaxHealth = rd.maxhp
		rig.Humanoid.Health = rig.Humanoid.MaxHealth
		Instance.new('Attachment', rig.Head)
		if rd.name == 'h Synthesis' then
			local p = Instance.new('ParticleEmitter', rig.Head)
			p.Rate /= 5 -- idk
			p.Texture = 'rbxassetid://17294399888'
			p.Enabled = false
		end
		rig.Head.Attachment.CFrame = CFrame.fromEulerAnglesXYZ(0, 0, -math.pi/2)
		rig.Parent = script
		return rig
	end,
	gdeclare = function(message: string)
		if not (rig and rig:FindFirstChild('Humanoid')) then
			local desc = Players:GetHumanoidDescriptionFromOutfitId(chars.Commander.outfit)
			rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6) :: Character
			rig.Parent = script
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
	bchar = function(n: number): string
		local b = '234678abcdefhjkmnprstuvwxyzABCDEFHJKMNPRSTUVWXYZ'
		if (n + 1) > #b then
			return b:sub(n % #b + 1, n % #b + 1) .. b:sub(math.floor(n / #b) + 1, math.floor(n / #b) + 1)
		else
			return b:sub(n + 1, n + 1)
		end
	end,
	ownercalc = function(cells, ents)
		local ret = {}
		for pos, ent in next, ents do
			if not ent.owner then continue end
			if ent.dchar.name == 'Commander' then
				if not cells[pos].gold then continue end
				if ret[ent.owner] then
					ret[ent.owner].range += 2
					ret[ent.owner].speed += 2
					ret[ent.owner].attack += 2
				else
					ret[ent.owner] = {
						range = 2,
						speed = 2,
						attack = 20,
						h = 0
					}
				end
			elseif ent.dchar.name == 'h Synthesis' then
				if not cells[pos].build then
					ent.real.Head.ParticleEmitter.Enabled = false
					continue
				end
				ent.real.Head.ParticleEmitter.Enabled = true
				if ret[ent.owner] then
					ret[ent.owner].h += 1
				else
					ret[ent.owner] = {
						range = 0,
						speed = 0,
						attack = 0,
						h = 1
					}
				end
			end
		end
		return ret
	end,
	rangecalc = function(cells, from, to)
		local dist = hex.dist(from, to)
		local rdist = dist
		local ppos = from
		for i = 1, dist do
			local ipos = hex.round(from:Lerp(to, i / dist + 1))
			if ipos == ppos then continue end
			local icell = cells[hex.round(from:Lerp(to, i / dist))] -- ????????
			local pcell = cells[ppos]
			if icell.height - pcell.height > 25 then
				rdist += icell.height - pcell.height
			end
			if icell.snow then
				rdist += 1.25
			end
			if icell.water and pcell.water then
				rdist += 999999
				break
			end
			ppos = ipos
		end
	end,
	q = function(path)
		return HttpService:JSONDecode(HttpService:GetAsync(server .. path, true))
	end
}
local mats = {
	[0] = Enum.Material.Grass,
	Enum.Material.Sand,
	Enum.Material.Sand,
	Enum.Material.Glass,
	Enum.Material.Glass,
	Enum.Material.Foil,
	Enum.Material.DiamondPlate
}

local token = ''
exitConn = owner.Chatted:Connect(function(message)
	if message == 'n%exit' then
		utils.q(`/game/{token}/exit`)
	end
end)
local uconns: { RBXScriptConnection } = {}
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
		utils.gdeclare('Connecting to server...')
		local data = utils.q(`/game/join?name={displayname}`)
		if not data.accept then
			utils.gdeclare(`Cannot connect to server: {data.reason}`)
			task.wait(3)
			error(`Connection failed: {data.reason}`)
		end
		utils.gdeclare(data.reason)
		token = data.token

		local state = {
			game = false,
			grid = false,
			ents = false,
			alive = false
		}
		local cellpos: { Vector3 } = {}
		local cells: { Cell } = {}
		local ents: { Ent } = {}
		local entmap: { [Vector3]: number? } = {}
		local hsig = Instance.new('BindableEvent', script)
		local debonk = os.time()
		local seen = {}
		while true do
			if os.time() - debonk < 5 then task.wait(5 + debonk - os.time()) end
			local events = utils.q(`/game/{token}/poll`)
			local lastGrid: buffer
			local entUpdate = false
			for _, event in ipairs(events) do
				if table.find(seen, event.id) then continue end
				for k, v in next, event do print(k, v) end
				seen[#seen + 1] = event
				if event.type == 'exit' then
					utils.gdeclare(`Disconnect from server: {event.reason}`)
					task.wait(4)
					error(`Disconnect: {event.reason}`)
				elseif event.type == 'playerlist' then
					local list = ''
					for player, h in ipairs(event.list) do
						list ..= `{player}: {h}\n`
					end
					utils.gdeclare(list)
				elseif event.type == 'start' then
					if state.game then continue end
					local tbuf = b64.decode(buffer.fromstring(event.tilepos))
					for i = 0, buffer.len(tbuf) - 1, 2 do -- im sorry
						local q, r = buffer.readi8(tbuf, i), buffer.readi8(tbuf, i + 1)
						cellpos[i / 2] = Vector3.new(q, r, -q-r)
					end
					for i, dchar in next, event.ents do
						local rd = chars[dchar]
						ents[i - 1] = { -- ,,,,,,
							dchar = dchar,
							pos = 0,
							hp = rd.maxhp,
							owned = false,
							real = utils.summonrig(rd)
						}
					end
					rig.Head.CFrame += Vector3.yAxis * 20
				elseif event.type == 'grid' then
					if state.grid then
						print('The grid is being updated ?!')
						lastGrid = event.grid
						continue
					else
						local gbuf = b64.decode(buffer.fromstring(event.grid))
						for i = 0, buffer.len(gbuf) - 1, 5 do
							local pos = cellpos[i / 5]
							assert(pos, 'bad event')
							local height = buffer.readu8(gbuf, i + 4)
							local mat = buffer.readu8(gbuf, i)
							local rcell = rhex.new()
							rcell.Anchored = true
							rcell.Color = Color3.fromRGB(buffer.readu8(gbuf, i + 1), buffer.readu8(gbuf, i + 2), buffer.readu8(gbuf, i + 3))
							rcell.Height = height / rhexh
							if not mats[mat] then print(mat, mats[mat], i) end
							rcell.Material = mats[mat]
							local prompt = Instance.new('ProximityPrompt')
							prompt.ObjectText = `Cell {utils.bchar(i / 5)} - Elevation {height}`
							prompt.HoldDuration = 0
							prompt.RequiresLineOfSight = false
							prompt.Parent = rcell.att
							prompt.Triggered:Connect(function(...)
								hsig:Fire(i / 5, ...)
							end)
							rcell.Position = rhex.position(pos) + origin + Vector3.yAxis * height / (rhexh * 2)
							rcell.Parent = script
							cells[i / 5] = {
								height = height,
								prompt = prompt,
								real = rcell,
								type = mat
							}
						end
					end
				elseif event.type == 'ents' then
					entUpdate = true
					local ebuf = b64.decode(buffer.fromstring(event.moves))
					for i = 0, buffer.len(ebuf) - 1, 4 do
						local eid, newpos, hp = buffer.readu8(ebuf, i), buffer.readu8(ebuf, i + 1), buffer.readu16(ebuf, i + 2)
						local oent = ents[eid]
						assert(oent, 'bad event')
						assert(cellpos[newpos], 'bad event')
						entmap[oent.pos] = nil
						if hp == 0 then
							oent.real:Destroy()
							ents[eid] = nil
							continue
						end
						entmap[newpos] = eid
						local nent = {
							dchar = oent.dchar,
							pos = newpos,
							hp = hp == 65535 and oent.hp or hp,
							owned = hp ~= 65535,
							real = oent.real
						}
						ents[eid] = nent
					end
					-- rig.Head.CFrame = CFrame.new(rhex.position(pos)) + Vector3.yAxis * (cell.rheight + 2.5) + origin
				end
			end
			if lastGrid then
				local gbuf = b64.decode(buffer.tostring(lastGrid))
				for i = 0, buffer.len(gbuf) - 1, 5 do
					local ocell = cells[i / 5]
					assert(ocell, 'bad event')
					local pos = cellpos[i / 5]
					local ncell = {
						height = buffer.readu8(gbuf, i + 4),
						prompt = ocell.prompt,
						real = ocell.real,
						type = buffer.readu8(gbuf, i)
					}
					local rcell = ncell.real
					rcell.Color = Color3.fromRGB(buffer.readu8(gbuf, i + 1), buffer.readu8(gbuf, i + 2), buffer.readu8(gbuf, i + 3))
					rcell.Height = ncell.height / rhexh
					rcell.Material = mats[ncell.type]
					ncell.prompt.ObjectText = `Elevation {ncell.height}`
					rcell.Position = rhex.position(pos) + origin + Vector3.yAxis * ncell.height / (rhexh * 2)
					cells[i / 5] = ncell
				end
			end
			if entUpdate then
				for i, ent in next, ents do
					local pos = cellpos[ent.pos]
					local cell = cells[ent.pos]
					ent.real.Head.CFrame = CFrame.new(rhex.position(pos)) + Vector3.yAxis * ((cell.height / rhexh) + 2.5) + origin
				end
			end
		end
		task.wait(10)
	end, function(...)
		warn(debug.traceback(...))
	end)
	if not success then
		utils.gdeclare('Restarting due to error ' .. (err or 'fix your sandbox'))
		print(err or 'fix your sandbox')
		script:ClearAllChildren()
	end
	task.wait(30)
end