--!strict
--[[
	plateofdoom.lua
	Copyright 2024 fofl12 (comsurg (h)) BSD 3-clause New License
	github.com/fofl12/sk
	Hopefully compatible with non VSB-like environments

	Icons owned by Google: https://github.com/google/material-design-icons
	License: http://www.apache.org/licenses/LICENSE-2.0 (Apache License 2.0)
	Uploaded by qwreey74

	Neko cat icon assets owned by Google
	License: http://www.apache.org/licenses/LICENSE-2.0 (Apache License 2.0)
	Icon made and uploaded by fofl12
]]

-- non VSB-like compatibility
local owner: Player? = nil
if getfenv().owner then 
	owner = getfenv().owner
end

-- disable this if you are going to run the script in studio
local EnableMemoryStoreService = false


type PlatformEvent = {
	text: string,
	command: string,
	run: (platform: Part) -> ...any,
	condition: (platform: Part) -> boolean,
}
type PlayerEvent = {
	text: string,
	command: string,
	run: (player: Playing) -> ...any,
	condition: (player: Playing) -> boolean,
}
type Character = Model & {
	Humanoid: Humanoid,
	Head: Part,
	Health: Script?,
	Torso: Part
}
type Playing = Player & { -- if you know how to do this better, please tell me
	Character: Character,
	Backpack: Backpack,
	PlayerGui: PlayerGui
}
type PlateType = {
	name: string,
	color: BrickColor,
	run: (part: Part) -> nil
}
type DeviceAdvantage = {
	name: string,
	run: (c: Character) -> nil
}
type SurvivalRecord = {
	holder: string,
	rounds: number
}
type PlatformThing = {
	name: string,
	run: (platform: Part) -> nil
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Chat = game:GetService("Chat")
local MemoryStoreService = game:GetService("MemoryStoreService")
local PhysicsService = game:GetService("PhysicsService")

local survivalRecord: MemoryStoreQueue = nil
if EnableMemoryStoreService then
	survivalRecord = MemoryStoreService:GetQueue('github.com/fofl12/sk - plateofdoom.lua 2', 1)
end

local leaderboardban: { string } = {
	'game_fixing', -- this stupid interfered in a survival mode game (humiliate him)
}

local _spawn = Instance.new('SpawnLocation', script)
_spawn.Anchored = true

local hats: { number } = {
	30845203, 1081366,
	2309346267, 102619342,
	5549581794, 1097026,
	6837506, 23630696,
	1028859, 21754973,
	124746065, 215724779,
	271014536, 124745808,
	13700820,
	4078588496,
	89615321,
	139152472,
	16218365,
	1743924583,
	22547651,
	1374269,
	16218214,
	10476359,
	122275601,
	63689493,
	3138460373,
	16179349,
	1425132751,
	15967866,
}
local icons: { number } = {
	6023565902, 6031154875,
	6022668893, 6031280889,
	6031079152, 6031225842,
	6023426904, 6031289446,
	6023565896, 6022668961,
	6023426901, 6026568266,
	6022668882, 6023426942,
	6023426925, 6031154859,
	6023426951, 6031154866,
	6022668876, 6022668917,
	6026568224, 6026568210,
	6031289442, 6022668888,
	6026568239, 6022668899,
	6022668951, 6031154857,
	6023426944, 6031233833,
	6023426938, 6022668892,
	6026568202, 6031225831,
	6031280896, 6031289461,
	6031289446, 6023426926,
	6023426930, 6022668900,
	6026568249, 6031260776,
	6026568199, 6031260782,
	6031289442, 6031079172,
	6026568196, 6031154871,
	6026568253, 17069106011,
	6031075929,
	6023426905,
	6022668963,
	6026568237,
	6031265965,
	6026568239,
	6031260778,
	6026568216,
	6031084749,
	6031229335,
	6023426910,
	6031280896,
	6026568189,
	6031251505,
	6031233847,
	6023426931,
	6031265970,
	6022668879,
	6023565894,
}

local _gmessage: Hint = nil
local function gdeclare(message: string)
	_gmessage.Text = message
end

local _ltargets: { Hint } = {}
local function ldeclare(message: string)
	for _, target in next, _ltargets do
		if not target then continue end
		target.Text = message
	end
end

if PhysicsService:IsCollisionGroupRegistered('plateofdoom.lua') then
	PhysicsService:UnregisterCollisionGroup('plateofdoom.lua')
end
PhysicsService:RegisterCollisionGroup('plateofdoom.lua')
PhysicsService:CollisionGroupSetCollidable('Default', 'plateofdoom.lua', false)
PhysicsService:CollisionGroupSetCollidable('plateofdoom.lua', 'plateofdoom.lua', true)
local function colliderReg(part: Instance)
	if part:IsA('BasePart') then
		part.CollisionGroup = 'plateofdoom.lua'
	end
	for _, desc in next, part:GetDescendants() do
		if not desc:IsA('BasePart') then continue end
		desc.CollisionGroup = 'plateofdoom.lua'
	end
end

function getChatColor(user: string): Color3
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

	return CHAT_COLORS[(GetNameValue(user) % #CHAT_COLORS) + 1]
end

local function randomElement<T>(t: { T }): T?
	if #t == 0 then return end
	while true do
		local element = t[math.random(1, #t)]
		if not element then continue end
		return element
	end
end

local function platformbind(signal: RBXScriptSignal, platform: Part): RBXScriptSignal
	local new = Instance.new('BindableEvent', platform)
	local connection: RBXScriptConnection = nil
	signal:Connect(function(...)
		if not (new and platform) then connection:Disconnect();return end
		new:Fire(...)
	end)
	return new.Event
end

local function charPlaying(char: Instance?): boolean
	if not (char and char.Parent == workspace and char:IsA('Model')) then return false end
	for _, tool in next, char:GetChildren() do
		if not tool:IsA('BackpackItem') then continue end
		if not tool:GetAttribute('Certifiedbyh') then return false end
	end
	local hum: Instance? = char:FindFirstChild('Humanoid')
	local head: Instance? = char:FindFirstChild('Head')
	local torso: Instance? = char:FindFirstChild('Torso')
	if not (head and hum and torso) then return false end
	if not (hum:IsA('Humanoid') and head:IsA('Part') and torso:IsA('Part')) then return false end
	if hum.Health <= 0 then return false end
	return true
end

local function playerPlaying(player: Playing): boolean
	local backpack = player:FindFirstChild('Backpack')
	if not (backpack and backpack:IsA('Backpack')) then return false end
	for _, tool in next, backpack:GetChildren() do
		if not tool:GetAttribute('Certifiedbyh') then
			return false
		end
	end
	if not charPlaying(player.Character) then return false end
	return true
end

local ptweens: { Tween } = {}
local uconns: { RBXScriptConnection } = {}

local playerEvents: { PlayerEvent } = {
	{
		text = '%s will be accelerated',
		command = 'speedup',
		condition = function(player: Playing)
			return true
		end,
		run = function(player: Playing)
			player.Character.Humanoid.WalkSpeed *= math.random() * 4 + 1
		end
	},
	{
		text = '%s will be decelerated',
		command = 'slowdown',
		condition = function(player: Playing)
			return true
		end,
		run = function(player: Playing)
			player.Character.Humanoid.WalkSpeed *= math.random()
		end
	},
	{
		text = '%s will jump better',
		command = 'superjump',
		condition = function(player: Playing)
			return player.Character.Humanoid.JumpPower ~= 100
		end,
		run = function(player: Playing)
			player.Character.Humanoid.JumpPower = 100
		end
	},
	{
		text = '%s wont jump',
		command = 'nojump',
		condition = function(player: Playing)
			return player.Character.Humanoid.JumpPower ~= 0
		end,
		run = function(player: Playing)
			player.Character.Humanoid.JumpPower = 0
		end
	},
	{
		text = '%s will be given a device',
		command = 'device',
		condition = function(player: Playing)
			return not (player.Character:FindFirstChild('Device') or player.Backpack:FindFirstChild('Device'))
		end,
		run = function(player: Playing)
			local advantages: { DeviceAdvantage } = {
				{
					name = 'Possibly gain MaxHealth in the gambling casino!??!?!?!?!?!!!!!!!!!!!',
					run = function(c: Character)
						c.Humanoid.MaxHealth = math.random(20, 300)
					end
				},
				{
					name = 'Recover health :D!',
					run = function(c: Character)
						c.Humanoid.Health += math.random(1, 40)
					end
				},
				{
					name = 'Anchor yourself ?! (temporarily)',
					run = function(c: Character)
						c.Head.Anchored = true
						task.delay(math.random(6, 30), function()
							c.Head.Anchored = false
						end)
					end
				},
				{
					name = 'With modern technological advancements, it is now possible to summon Portable trampoline !',
					run = function(c: Character)
						local new = Instance.new('Part')
						new.Size = Vector3.new(5, 1, 5)
						new.Anchored = true
						new.BrickColor = BrickColor.Black()
						new.Position = c.Head.Position - Vector3.yAxis * 8
						new.Parent = script
						new.AssemblyLinearVelocity = Vector3.yAxis * 200
						colliderReg(new)
						Debris:AddItem(new, 10)
					end
				},
				{
					name = 'KABOOM',
					run = function(c: Character)
						local ff = Instance.new('ForceField', c)
						local x = Instance.new('Explosion')
						x.Position = c.Head.Position
						x.Parent = c.Head
						Debris:AddItem(ff, 1)
					end
				}
			}
			local new = Instance.new('Tool')
			new:SetAttribute('Certifiedbyh', true) -- truly the best anticheat mechanism
			new.Name = 'Device'
			local t = randomElement(advantages) :: DeviceAdvantage
			new.ToolTip = t.name
			local conn = new.Activated:Connect(function()
				local c = new.Parent
				if charPlaying(c) then t.run(c :: Character) end
				new:Destroy()
			end)
			table.insert(uconns, conn)
			local handle = Instance.new('Part')
			handle.Size = Vector3.one
			handle.Transparency = 1
			handle.Name = 'Handle'
			Instance.new('Sparkles', handle)
			handle.Parent = new
			colliderReg(handle)
			new.Parent = player.Backpack
		end
	},
	{
		text = '%s will be given protection for %i seconds',
		command = 'protect',
		condition = function(player: Playing)
			return not player.Character:FindFirstChildWhichIsA('ForceField')
		end,
		run = function(player: Player)
			local qty = math.random(20, 200)
			Debris:AddItem(Instance.new('ForceField', player.Character), qty)
			return qty
		end
	},
}
local platformEvents: { PlatformEvent } = {
	{
		text = '%s platform will expand by %.1f studs horizontally',
		command = 'hexpand',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local qty = math.random() * 20 - 10
			local t = math.random() * 20
			local tween = TweenService:Create(platform, TweenInfo.new(t), {
				Size = platform.Size + Vector3.new(qty, 0, qty)
			})
			table.insert(ptweens, tween)
			tween:Play()
			if platform.Size.X < -qty then
				task.delay(t, function()
					if tween.PlaybackState == Enum.PlaybackState.Cancelled then return end
					if platform then
						platform.Parent = nil
					end
				end)
			end
			return qty
		end
	},
	{
		text = '%s platform will expand by %.1f studs vertically',
		command = 'vexpand',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local qty = math.random() * 5 - 2.5
			local t = math.random() * 20
			local tween = TweenService:Create(platform, TweenInfo.new(t), {
				Size = platform.Size + Vector3.yAxis * qty
			})
			table.insert(ptweens, tween)
			tween:Play()
			if platform.Size.Y < -qty then
				task.delay(t, function()
					if tween.PlaybackState == Enum.PlaybackState.Cancelled then return end
					if platform then
						platform.Parent = nil
					end
				end)
			end
			return qty
		end
	},
	{
		text = '%s platform will be raised by %.1f studs',
		command = 'raise',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local qty = math.random() * 20 - 10
			local tween = TweenService:Create(platform, TweenInfo.new(math.random() * 20), {
				Position = platform.Position + Vector3.yAxis * qty
			})
			table.insert(ptweens, tween)
			tween:Play()
			return qty
		end
	},
	{
		text = '%s platform will fade',
		command = 'fade',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local qty = math.random() * 30 + 5
			local tween = TweenService:Create(platform, TweenInfo.new(qty), {
				Transparency = 1
			})
			table.insert(ptweens, tween)
			tween:Play()
			for _, desc in next, platform:GetDescendants() do
				if not desc:IsA('BasePart') then continue end
				TweenService:Create(desc, TweenInfo.new(qty), {
					Transparency = 1
				}):Play()
			end
			task.delay(qty, function()
				if tween.PlaybackState == Enum.PlaybackState.Cancelled then return end
				if platform then
					platform.Parent = nil
				end
			end)
		end
	},
	{
		text = '%s platform will become %s',
		command = 'transform',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local factora = math.random(1, 5)
			local factorb = math.random(1, 5)
			local types: { PlateType } = {
				{
					name = 'corrosive',
					color = BrickColor.Yellow(),
					run = function(part: Part)
						if math.random() < .5 then return end
						local tween = TweenService:Create(part, TweenInfo.new(factora * 10), {
							Transparency = 1
						})
						tween:Play()
						task.delay(factora * 10, function()
							if part then
								part:Destroy()
							end
						end)
					end
				},
				{
					name = 'a minefield',
					color = BrickColor.Black(),
					run = function(part: Part)
						if math.random() < .5 then return end
						Instance.new('Explosion', platform).Position = part.Position
					end
				},
				{
					name = 'healthy',
					color = BrickColor.Green(),
					run = function(part: Part)
						if not part.Parent then return end -- wtf.........
						local hum = part.Parent:FindFirstChildWhichIsA('Humanoid')
						if not hum then return end
						if hum.Health == hum.MaxHealth then
							hum.MaxHealth += factorb / 5
						else
							hum.Health += factora
						end
					end
				},
				{
					name = 'violent',
					color = BrickColor.Red(),
					run = function(part: Part)
						if not part.Parent then return end
						local hum = part.Parent:FindFirstChildWhichIsA('Humanoid')
						if not hum then return end
						hum:TakeDamage(factora * 5)
					end
				},
				{
					name = 'bouncy',
					color = BrickColor.Black(),
					run = function(part: Part)
						platform.AssemblyLinearVelocity = Vector3.new(0, factora * 100, 0)
					end
				},
				{
					name = 'a conveyer belt',
					color = BrickColor.Black(),
					run = function(part: Part)
						platform.AssemblyLinearVelocity = Vector3.new(factora * 4 - 10, 0, factorb * 4 - 10)
					end
				}
			}
			local t = randomElement(types) :: PlateType
			platform.BrickColor = t.color
			local conn = platformbind(platform.Touched, platform):Connect(t.run)
			table.insert(uconns, conn)
			return t.name
		end
	},
	{
		text = '%s platform will leave',
		command = 'leave',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil) -- ????????!??!?!?!?!!?!??!?!?!?!!
		end,
		run = function(platform: Part)
			local dir = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1)
			local tween = TweenService:Create(platform, TweenInfo.new(1000 / (math.random() * 5)), {
				Position = platform.Position + dir * 500
			})
			table.insert(ptweens, tween)
			tween:Play()
		end
	},
	--[[ 
	{ -- (temporarily?) removed for balance
		text = '%s platform will be cleared',
		command = 'clear',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil) and (#platform:GetChildren() > 0)
		end,
		run = function(platform: Part)
			platform:ClearAllChildren()
		end
	},
	]]
	{
		text = '%s will gain control of their platform',
		command = 'control',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil) and (not platform:FindFirstChildWhichIsA('VehicleSeat'))
		end,
		run = function(platform: Part)
			local seat = Instance.new('VehicleSeat')
			seat.Size = Vector3.one * 2
			seat.Color = platform:GetAttribute('originColor')
			seat.Parent = platform
			colliderReg(seat)
			local weld = Instance.new('Weld')
			weld.Part0 = platform
			weld.Part1 = seat
			weld.C0 = CFrame.new(0, platform.Size.Y / 2, 0)
			weld.Parent = platform

			task.spawn(function()
				while platform and seat do
					local delta = task.wait(1/20)
					platform.Position += Vector3.new(seat.SteerFloat, 0, -seat.ThrottleFloat) * delta * 2
				end
			end)
		end
	},
	{
		text = '%s will be given a new platform',
		command = 'newplatform',
		condition = function(platform: Part)
			return true
		end,
		run = function(platform: Part)
			for _, tween in next, ptweens do
				if tween.Instance == platform then
					tween:Cancel()
				end
			end
			platform.Size = Vector3.new(12, 1, 12)
			platform.Color = platform:GetAttribute('originColor')
			platform.AssemblyLinearVelocity = Vector3.zero
			platform.Transparency = 0
			platform:ClearAllChildren()
			platform.Parent = script
		end
	},
	{
		text = '%s platform will gain a bomb',
		command = 'bomb',
		condition = function(platform: Part)
			return true
		end,
		run = function(platform: Part)
			local new = Instance.new('Part')
			new.BrickColor = BrickColor.Black()
			new.Size = Vector3.one * 2
			new.Shape = Enum.PartType.Ball
			new.Parent = platform
			colliderReg(new)
			local weld = Instance.new('Weld')
			weld.Part0 = platform
			weld.Part1 = new
			weld.C0 = CFrame.new(math.random() * platform.Size.X - platform.Size.X / 2, platform.Size.Y / 2 + 1, math.random() * platform.Size.Z - platform.Size.Z / 2)
			weld.Parent = platform
			local bg = Instance.new('BillboardGui')
			bg.StudsOffsetWorldSpace = Vector3.yAxis * 4
			bg.Size = UDim2.fromScale(1, 1)
			local label = Instance.new('TextLabel')
			label.BackgroundTransparency = 1
			label.TextColor3 = BrickColor.Red().Color
			label.Size = UDim2.fromScale(1, 1)
			label.TextScaled = true
			label.Text = 'Hi'
			label.Parent = bg
			bg.Parent = new
			bg.Adornee = new
			local qty = math.random(20, 60)
			Debris:AddItem(new, qty + 3)
			task.spawn(function()
				for i = qty, 1, -1 do
					if not label then return end
					label.Text = tostring(i)
					task.wait(1)
				end
				if not (new and new.Parent == platform) then return end
				new.BrickColor = BrickColor.Red()
				local x = Instance.new('Explosion')
				x.BlastRadius = 10
				x.Position = new.Position
				x.Parent = platform
			end)
		end
	},
	{
		text = '%s platform will gain %s',
		command = 'platformthing',
		condition = function(platform: Part)
			return true
		end,
		run = function(platform: Part)
			local things: { PlatformThing } = {
				{
					name = 'truss',
					run = function(platform: Part)
						local new = Instance.new('TrussPart')
						local h = math.random(4, 20)
						new.Size = Vector3.new(1, 1, 1)
						new.BrickColor = BrickColor.random()
						new.Parent = platform
						colliderReg(new)
						local weld = Instance.new('Weld')
						weld.Part0 = platform
						weld.Part1 = new
						weld.C0 = CFrame.new(math.random() * platform.Size.X - platform.Size.X / 2, -h/2, math.random() * platform.Size.Z - platform.Size.Z / 2)
						weld.Parent = platform
						local t = math.random(5, 50)
						TweenService:Create(weld, TweenInfo.new(t), {
							C0 = weld.C0 + Vector3.yAxis * h
						}):Play()
						TweenService:Create(new, TweenInfo.new(t), {
							Size = Vector3.new(1, h, 1)
						}):Play()
					end
				},
				{
					name = 'wall',
					run = function(platform: Part)
						local angle = math.random() * math.pi
						local length: number = nil
						if angle < math.pi / 4 or angle > 3 * math.pi / 4 then
							length = math.abs(platform.Size.X / math.cos(angle))
						else
							length = platform.Size.Z / math.sin(angle)
						end
						local h = math.random(5, 30)
						local new = Instance.new('Part')
						new.Size = Vector3.new(1, 1, length)
						new.Material = Enum.Material.Brick
						new.BrickColor = BrickColor.Red()
						new.Parent = platform
						colliderReg(new)
						local weld = Instance.new('Weld')
						weld.Part0 = platform
						weld.Part1 = new
						weld.C0 = CFrame.Angles(0, angle, 0)
						weld.Parent = platform
						local t = math.random(5, 30)
						TweenService:Create(weld, TweenInfo.new(t), {
							C0 = CFrame.new(0, h / 2, 0) * weld.C0
						}):Play()
						TweenService:Create(new, TweenInfo.new(t), {
							Size = Vector3.new(1, h, length)
						}):Play()
					end
				},
				{
					name = 'a cactus',
					run = function(platform: Part)
						local new = Instance.new('Part')
						local h = math.random(4, 50)
						new.Size = Vector3.new(3, 1, 3)
						new.BrickColor = BrickColor.Green()
						new.Parent = platform
						colliderReg(new)
						local weld = Instance.new('Weld')
						weld.Part0 = platform
						weld.Part1 = new
						weld.C0 = CFrame.new(math.random() * platform.Size.X - platform.Size.X / 2, 0, math.random() * platform.Size.Z - platform.Size.Z / 2)
						weld.Parent = platform
						local t = math.random(5, 60)
						TweenService:Create(weld, TweenInfo.new(t), {
							C0 = weld.C0 + Vector3.yAxis * h / 2
						}):Play()
						TweenService:Create(new, TweenInfo.new(t), {
							Size = Vector3.new(3, h, 3)
						}):Play()
						local touch = platformbind(new.Touched, new):Connect(function(part: Part)
							if not part.Parent then return end
							local hum = part.Parent:FindFirstChildWhichIsA('Humanoid')
							if not hum then return end
							hum:TakeDamage(8)
						end)
						table.insert(uconns, touch)
					end
				}
			}
			local thing = randomElement(things) :: PlatformThing
			thing.run(platform)
			return thing.name
		end
	},
}

local autojoined: { Player } = {}

while true do
	for _, hint in next, _ltargets do
		if not hint then continue end
		hint:Destroy()
	end
	for i, conn in next, uconns do
		if not conn.Connected then 
			uconns[i] = nil
			continue
		end
		conn:Disconnect()
	end
	local err = xpcall(function()
		local conns: { RBXScriptConnection } = {}
		local joined: { Player } = table.clone(autojoined)
		for i, player: Player in next, Players:GetPlayers() do
			conns[i] = player.Chatted:Connect(function(message)
				if message == 'p%join' then
					local j = table.find(joined,player)
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
			end)
			table.insert(uconns, conns[i])
		end
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
		_gmessage = Instance.new('Hint', script)
		while t > 0 do
			local roster = ""
			for _, player in ipairs(joined) do
				roster ..= player.DisplayName .. '\n'
			end
			gdeclare(`{('\n'):rep(#joined)}\n\ngithub.com/fofl12/sk - Starting the plate of the doom in {t} seconds - Say p%join or p%auto to join\nWant to choose which events happen? Join comsurg's group and purchase the stakeholder t-shirt for 12 robux!\n{roster}`)
			task.wait(1)
			t -= 1
		end
		leftConn:Disconnect()
		for _, conn in next, conns do
			if conn.Connected then
				conn:Disconnect()
			end
		end
		if skipConn then skipConn:Disconnect() end
		_gmessage:Destroy()

		local platforms: { Part } = {}
		local playing: { Playing } = {}
		local function rem(i: number)
			if playing[i] and playing[i].Character and playing[i].Character.Humanoid then
				playing[i].Character.Humanoid.Health = 0
			end
			playing[i] = nil
			if platforms[i] then
				platforms[i].Transparency = 0.5
				platforms[i].BrickColor = BrickColor.Red()
				Debris:AddItem(platforms[i], 3)
			end
			platforms[i] = nil
		end
		local aliveConns = {}
		local chatConns = {}
		local remaining = 0
		local nextEvent: PlayerEvent | PlatformEvent = nil
		local nextEventType: string = ''
		for i, player in next, joined do
			local humdesc = Players:GetHumanoidDescriptionFromOutfitId(2913007835)
			humdesc.Face = Players:GetHumanoidDescriptionFromUserId(player.UserId).Face
			humdesc.HatAccessory = tostring(randomElement(hats))
			local color = getChatColor(player.Name)
			humdesc.TorsoColor = color
			humdesc.LeftLegColor = color
			humdesc.RightLegColor = color
			if player.Character then player.Character:Destroy() end
			player:LoadCharacterWithHumanoidDescription(humdesc)
			if not player.Character then player.CharacterAdded:Wait() end
			player:WaitForChild('Backpack', 5)
			local playingPlayer: Playing = player :: Playing 
			if playingPlayer.Character.Humanoid.RigType ~= Enum.HumanoidRigType.R6 then
				playingPlayer.Character:Destroy() -- if anyone knows how to force the avatar to be r6, please tell me
				continue
			end
			remaining += 1
			colliderReg(playingPlayer.Character)
			local healthScript: Instance? = playingPlayer.Character:FindFirstChild('Health')
			if healthScript then healthScript:Destroy() end
			local decal = Instance.new('Decal')
			decal.Texture = `rbxassetid://{randomElement(icons)}`
			decal.Parent = playingPlayer.Character.Torso
			playingPlayer.Character.Humanoid.WalkSpeed = 0
			task.delay(3, function()
				playingPlayer.Character.Humanoid.WalkSpeed = 16
			end)
			playingPlayer.Character.Head.CFrame = CFrame.new(0, 10000, 0)
			local alive = playingPlayer.Character.Humanoid.Died:Once(function()
				rem(i)
				remaining -= 1
			end)
			aliveConns[remaining] = alive
			table.insert(uconns, alive)
			_ltargets[remaining] = Instance.new('Hint', playingPlayer.PlayerGui)
			task.spawn(function()
				while task.wait(1) do
					if not alive.Connected then return end
					if not playerPlaying(playingPlayer) then break end
					if playingPlayer.Character.Head.Position.Y < (if playingPlayer.Character:FindFirstChildWhichIsA('ForceField') then 30 else 40) then break end
				end
				rem(remaining)
				alive:Disconnect()
				remaining -= 1
			end)
			local stakeholder = player:GetRankInGroup(8468419) >= 110
			chatConns[remaining] = player.Chatted:Connect(function(message: string)
				if not player.Character then return end
				Chat:Chat(player.Character, message)
				if not stakeholder then return end
				if message:sub(1, 8):lower() == 'p%event ' and #message > 9 then
					local name = message:sub(9, -1):lower()
					for _, event in next, playerEvents do
						if event.command == name then
							nextEvent = event
							nextEventType = 'player'
						end
					end
					for _, event in next, platformEvents do
						if event.command == name then
							nextEvent = event
							nextEventType = 'platform'
						end
					end
				end
			end)
			table.insert(uconns, chatConns[remaining])
			playing[remaining] = playingPlayer
		end
		local survival = remaining == 1
		local survivalplayer = joined[1]
		local w = math.ceil(math.sqrt(#joined))
		local h = math.floor(#joined / w)
		for i = 1, #playing do
			local new = Instance.new('Part')
			new.Anchored = true
			new.Color = getChatColor(joined[i].Name)
			new:SetAttribute('originColor', new.Color)
			new.Size = Vector3.new(12, 1, 12)
			new.Position = Vector3.new(0, 50, 0) + Vector3.new(i % w - w / 2, 0, math.floor(i / w) - h / 2) * 20
			new.Name = playing[i].DisplayName
			platforms[i] = new
			new.Parent = script
			colliderReg(new)
			playing[i].Character.Head.CFrame = new.CFrame + Vector3.yAxis * 50
		end

		ldeclare('Starting ' .. (if survival then 'Survival mode' else 'Battle royale mode'))
		task.wait(3)

		local rounds = 0
		local prevEvent: PlayerEvent | PlatformEvent = nil
		local failedEvents = 0
		while remaining > (if survival then 0 else 1) do
			assert(failedEvents < 3, 'Too many failed events!')
			local playerEventAttempted = 0
			local platformEventAttempted = 0
			while true do
				if platformEventAttempted > 5 and playerEventAttempted > 5 then 
					failedEvents += 1
					break
				end
				task.wait()
				local typ = if math.random() < .5 then 'player' else 'platform'
				local forced = false
				if nextEventType ~= '' then
					typ = nextEventType
					nextEventType = ''
					forced = true
				end
				if typ == 'player' then
					local player = randomElement(playing) :: Playing
					if not playerPlaying(player) then playerEventAttempted += 1; continue end
					local event = (if forced then nextEvent else randomElement(playerEvents)) :: PlayerEvent
					if not event then playerEventAttempted += 1; continue end
					if prevEvent == event then continue end
					if not event.condition(player) then continue end
					ldeclare(event.text:format(player.DisplayName, event.run(player)))
					prevEvent = event
				elseif typ == 'platform' then
					local platform = randomElement(platforms)
					if not platform then platformEventAttempted += 1; continue end
					local event = (if forced then nextEvent else randomElement(platformEvents)) :: PlatformEvent
					if not event then platformEventAttempted += 1; continue end
					if prevEvent == event then continue end
					if not event.condition(platform) then continue end
					ldeclare(event.text:format(platform.Name, event.run(platform)))
					prevEvent = event
				end
				break
			end
			rounds += 1
			task.wait(5)
		end

		for _, target in next, _ltargets do
			if not target then continue end
			target:Destroy()
		end

		_gmessage = Instance.new('Hint', script)
		if remaining == 1 then
			local winner = randomElement(playing) :: Playing
			gdeclare(`{winner.DisplayName} won ! ! !`)
		elseif survival then
			gdeclare(`{survivalplayer.DisplayName} survived for {rounds} rounds ! ! !`)
			if EnableMemoryStoreService and not table.find(leaderboardban, survivalplayer.Name) then
				xpcall(function()
					local records = survivalRecord:ReadAsync(5, false, 0) :: { SurvivalRecord }
					if not records then
						records = { { rounds = 0, holder = '???' } }
					end
					local recordlist = ''
					for i = 1, 5 do
						local record = if #records >= i then records[i] else { rounds = 0, holder = '???' }
						recordlist ..= `{i}. {record.rounds} by {record.holder}\n`
					end
					gdeclare(`{('\n'):rep(6)}{if records[1].rounds < rounds then '\n' else ''}{survivalplayer.DisplayName} survived for {rounds} rounds ! ! !\n{if records[1].rounds < rounds then 'NEW RECORD\n' else ''}{recordlist}`)
					survivalRecord:AddAsync({
						rounds = rounds,
						holder = `{survivalplayer.DisplayName} ({survivalplayer.Name})`
					}, 3888000, rounds)
					task.wait(5)
				end, function(...) warn('Error while using MemoryStoreService:', debug.traceback(...)) end)
			end
		else
			gdeclare('Everyone died...')
		end

		for _, conn in next, aliveConns do
			if not conn.Connected then continue end
			conn:Disconnect()
		end
		for _, conn in next, chatConns do
			if not conn.Connected then continue end
			conn:Disconnect()
		end

		task.wait(5)
		script:ClearAllChildren()
	end, function(...)
		warn(debug.traceback(...))
	end)
	if not err then
		script:ClearAllChildren()
		_gmessage = Instance.new('Hint', script)
		gdeclare('Restarting because of error')
		task.wait(5)
	end
end
