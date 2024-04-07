--!strict

type PlatformEvent = {
	text: string,
	run: (platform: Part) -> any,
	condition: (platform: Part) -> boolean,
}
type PlayerEvent = {
	text: string,
	run: (player: Player) -> any,
	condition: (player: Player) -> boolean,
}
type Character = {
	Humanoid: Humanoid,
	Head: Part
}
type PlateType = {
	name: string,
	run: (part: Part) -> nil
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Debris = game:GetService("Debris")
local survivalRecord = MemoryStoreService:GetQueue('github.com/fofl12/sk - plateofdoom.lua', 1)

local _spawn = Instance.new('SpawnLocation', script)
_spawn.Anchored = true

local _message = Instance.new('Hint', script)
local function declare(message: string)
	if not _message then 
		_message = Instance.new('Hint', script)
	end
	_message.Text = message
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

local function randomElement(t: table): any
	while true do
		if #t == 0 then return nil end
		local element = t[math.random(1, #t)]
		if not element then continue end
		--if typeof(element) == 'Instance' and element.Parent == nil then return end
		return element
	end
end

local function platformbind(signal: RBXScriptSignal, platform: Part): RBXScriptSignal
	local new = Instance.new('BindableEvent', platform)
	local connection: RBXScriptConnection
	signal:Connect(function(...)
		if not (new and platform) then connection:Disconnect();return end
		new:Fire(...)
	end)
	return new.Event
end

local ptweens: { Tween } = {}

local playerEvents: { PlayerEvent } = {
	{
		text = '%s will be accelerated',
		condition = function(player: Player)
			return true
		end,
		run = function(player: Player)
			player.Character.Humanoid.WalkSpeed *= math.random() * 4 + 1
		end
	},
	{
		text = '%s will be decelerated',
		condition = function(player: Player)
			return true
		end,
		run = function(player: Player)
			player.Character.Humanoid.WalkSpeed *= math.random()
		end
	},
	{
		text = '%s will jump better',
		condition = function(player: Player)
			return player.Character.Humanoid.JumpPower ~= 100
		end,
		run = function(player: Player)
			player.Character.Humanoid.JumpPower = 100
		end
	},
	{
		text = '%s wont jump',
		condition = function(player: Player)
			return player.Character.Humanoid.JumpPower ~= 0
		end,
		run = function(player: Player)
			player.Character.Humanoid.JumpPower = 0
		end
	},
	{
		text = '%s will be given a device',
		condition = function(player: Player)
			return not (player.Character:FindFirstChild('Device') or player.Backpack:FindFirstChild('Device'))
		end,
		run = function(player: Player)
			local advantages = {
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
				}
			}
			local new = Instance.new('Tool')
			new.Name = 'Device'
			local t = randomElement(advantages)
			new.ToolTip = t.name
			new.Activated:Connect(function()
				local c = new.Parent
				t.run(c)
				new:Destroy()
			end)
			local handle = Instance.new('Part')
			handle.Size = Vector3.one
			handle.Transparency = 1
			handle.Name = 'Handle'
			Instance.new('Sparkles', handle)
			handle.Parent = new
			new.Parent = player.Backpack
		end
	},
	{
		text = '%s will be given protection for %i seconds',
		condition = function(player: Player)
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
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local qty = math.random() * 10 - 5
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
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local qty = math.random() * 1.8 - 0.9
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
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil)
		end,
		run = function(platform: Part)
			local qty = math.random() * 30
			local tween = TweenService:Create(platform, TweenInfo.new(qty), {
				Transparency = 1
			})
			table.insert(ptweens, tween)
			tween:Play()
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
						local hum = part.Parent:FindFirstChild('Humanoid')
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
						local hum = part.Parent:FindFirstChild('Humanoid')
						if not hum then return end
						hum:TakeDamage(factora * 5)
					end
				},
				{
					name = 'bouncy',
					color = BrickColor.Black(),
					run = function(part: Part)
						platform.Velocity = Vector3.new(0, factora * 10, 0)
					end
				},
				{
					name = 'a conveyer belt',
					color = BrickColor.Black(),
					run = function(part: Part)
						platform.Velocity = Vector3.new(factora * 4 - 10, 0, factorb * 4 - 10)
					end
				}
			}
			local t = randomElement(types)
			platform.BrickColor = t.color
			platformbind(platform.Touched, platform):Connect(t.run)
			return t.name
		end
	},
	{
		text = '%s platform will leave',
		condition = function(platform: Part)
			return (platform.Parent ~= nil) and platform
		end,
		run = function(platform: Part)
			local dir = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1)
			local tween = TweenService:Create(platform, TweenInfo.new(1000 / math.random()), {
				Position = platform.Position + dir * 500
			})
			table.insert(ptweens, tween)
			tween:Play()
		end
	},
	{
		text = '%s platform will be cleared',
		condition = function(platform: Part)
			print(platform, platform.Parent, #platform:GetChildren())
			return platform and (platform.Parent ~= nil) and (#platform:GetChildren() > 0)
		end,
		run = function(platform: Part)
			platform:ClearAllChildren()
		end
	},
	{
		text = '%s will gain control of their platform',
		condition = function(platform: Part)
			return platform and (platform.Parent ~= nil) and (not platform:FindFirstChildWhichIsA('VehicleSeat'))
		end,
		run = function(platform: Part)
			local seat = Instance.new('VehicleSeat')
			seat.Size = Vector3.one * 2
			seat.Anchored = true
			seat.BrickColor = platform.BrickColor
			seat.Parent = platform
			task.spawn(function()
				while platform and seat do
					local delta = task.wait(1/20)
					platform.Position += Vector3.new(seat.SteerFloat, 0, -seat.ThrottleFloat) * delta * 2
					seat.Position = platform.Position
				end
			end)
		end
	},
	{
		text = '%s will be given a new platform',
		condition = function(platform: Part)
			return true
		end,
		run = function(platform: Part)
			for _, tween in next, ptweens do
				if tween.Instance == platform then
					tween:Cancel()
				end
			end
			platform.Size = Vector3.new(8, 1, 8)
			platform.Transparency = 0
			platform:ClearAllChildren()
			platform.Parent = script
		end
	}
}

local autojoined = {}

while true do
	local err = xpcall(function()
		local conns: { RBXScriptConnection } = {}
		local joined: { Player } = table.clone(autojoined)
		for i, player in next, Players:GetPlayers() do
			conns[i] = player.Chatted:Connect(function(message)
				if message == 'p%join' then
					local i = table.find(joined,player)
					if not i then
						table.insert(joined, player)
					end
				elseif message == "p%leave" then
					local i = table.find(joined,player)
					if i then
						table.remove(joined,i)
					end
				elseif message == 'p%auto' then
					local i = table.find(joined,player)
					if not i then
						table.insert(joined, player)
					end

					local i = table.find(autojoined,player)
					if not i then
						table.insert(autojoined, player)
					else
						table.remove(autojoined, i)
					end
				end
			end)
		end
		local leftConn = Players.PlayerRemoving:Connect(function(player: Player)
			local i = table.find(joined, player)
			if i then
				table.remove(joined, i)
			end
		end)
		local i = 25
		local skipConn = owner.Chatted:Connect(function(h)
			if h == "p%skip" then
				i = 0
			end
		end)
		while i > 0 do
			local roster = ""
			for _, player in ipairs(joined) do
				roster ..= player.DisplayName .. '\n'
			end
			declare(`{('\n'):rep(#joined)}\ngithub.com/fofl12/sk - Starting the plate of the doom in {i} seconds - Say p%join or p%auto to join\n{roster}`)
			task.wait(1)
			i -= 1
		end
		leftConn:Disconnect()
		for _, conn in next, conns do
			if conn.Connected then
				conn:Disconnect()
			end
		end
		skipConn:Disconnect()

		local ingame = true
		local platforms: { Part } = {}
		local function rem(i: number)
			if joined[i].Character and joined[i].Character.Humanoid then
				joined[i].Character.Humanoid.Health = 0
			end
			joined[i] = nil
			if platforms[i] then
				platforms[i]:Destroy()
			end
			platforms[i] = nil
		end
		local aliveConns = {}
		local remaining = 0
		for i, player in next, joined do
			player:LoadCharacter()
			if not player.Character then player.CharacterAdded:Wait() end
			if player.Character:FindFirstChild('Health') then
				player.Character.Health:Destroy()
			end
			player.Character.Humanoid.WalkSpeed = 0
			task.delay(3, function()
				player.Character.Humanoid.WalkSpeed = 16
			end)
			player.Character.Head.CFrame = CFrame.new(0, 10000, 0)
			local alive = player.Character.Humanoid.Died:Once(function()
				rem(i)
				remaining -= 1
			end)
			task.spawn(function()
				while task.wait(1) do
					if not alive.Connected then return end
					if not (player and player.Character and player.Character:FindFirstChild('Head')) then break end
					if player.Character.Head.Position.Y < (if player.Character:FindFirstChildWhichIsA('ForceField') then 30 else 40) then break end
				end
				rem(i)
				alive:Disconnect()
				remaining -= 1
			end)
			aliveConns[i] = alive
			remaining += 1
		end
		local survival = remaining == 1
		local survivalplayer = joined[1]
		local w = math.ceil(math.sqrt(#joined))
		local h = math.floor(#joined / w)
		for i = 1, #joined do
			local new = Instance.new('Part')
			new.Anchored = true
			new.Color = getChatColor(joined[i].Name)
			new.Size = Vector3.new(8, 1, 8)
			new.Position = Vector3.new(0, 50, 0) + Vector3.new(i % w - w / 2, 0, math.floor(i / w) - h / 2) * 14
			new.Name = joined[i].DisplayName
			platforms[i] = new
			new.Parent = script
			joined[i].Character.Head.CFrame = new.CFrame + Vector3.yAxis * 50
		end

		declare('Starting ' .. (if survival then 'Survival mode' else 'Battle royale mode'))
		task.wait(3)

		local rounds = 0
		local prevEvent = {}
		while remaining > (if survival then 0 else 1) do
			while true do
				task.wait()
				local t = if math.random() < .5 then 'player' else 'platform'
				if t == 'player' then
					local player = randomElement(joined)
					local event = randomElement(playerEvents)
					if prevEvent == event then continue end
					if not event.condition(player) then continue end
					declare(event.text:format(player.DisplayName, event.run(player)))
					prevEvent = event
				elseif t == 'platform' then
					local platform = randomElement(platforms)
					local event = randomElement(platformEvents)
					if prevEvent == event then continue end
					if not event.condition(platform) then continue end
					declare(event.text:format(platform.Name, event.run(platform)))
					prevEvent = event
				end
				break
			end
			rounds += 1
			task.wait(5)
		end

		if remaining == 1 then
			local winner = randomElement(joined)
			declare(`{winner.DisplayName} won ! ! !`)
		elseif survival then
			local record, _ = survivalRecord:ReadAsync(1, true, 0)
			if not record then
				record = {
					rounds = 0,
					holder = 'Anonymous'
				}
			else
				record = record[1]
			end
			declare(`\n{if record.rounds < rounds then '\n' else ''}{survivalplayer.DisplayName} survived for {rounds} rounds ! ! !\n{if record.rounds < rounds then 'NEW RECORD\n' else ''}World record: {record.rounds} by {record.holder}`)
			if rounds > record.rounds then
				survivalRecord:AddAsync({
					rounds = rounds,
					holder = `{survivalplayer.DisplayName} ({survivalplayer.Name})`
				}, 3888000)
			end
		else
			declare('Everyone died...')
		end

		ingame = false
		for _, conn in next, aliveConns do
			conn:Disconnect()
		end
		for _, platform in next, platforms do
			platform:Destroy()
		end

		task.wait(5)
	end, function(...)
		warn(debug.traceback(...))
	end)
	if not err then
		script:ClearAllChildren()
		_message = Instance.new('Hint', script)
		declare('Restarting because of error')
		task.wait(5)
	end
end
