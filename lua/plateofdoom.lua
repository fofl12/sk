--!strict

local ownername = if owner then owner.Name else 'Server'

type PlatformEvent = {
	text: string,
	run: (platform: Part) -> any
}
type PlayerEvent = {
	text: string,
	run: (player: Player) -> any
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

local _spawn = Instance.new('SpawnLocation', script)
_spawn.Anchored = true

local _message = Instance.new('Hint', script)
local function declare(message: string)
	if not _message then 
		_message = Instance.new('Hint', script)
	end
	_message.Text = message
end

local function randomElement(t: table): any
	while true do
		if #t == 0 then return nil end
		local element = t[math.random(1, #t)]
		if element then return element end
	end
end

local playerEvents: { PlayerEvent } = {
	{
		text = '%s will be accelerated',
		run = function(player: Player)
			player.Character.Humanoid.WalkSpeed *= 5
		end
	},
	{
		text = '%s will be decelerated',
		run = function(player: Player)
			player.Character.Humanoid.WalkSpeed *= .2
		end
	},
	{
		text = '%s will jump better',
		run = function(player: Player)
			player.Character.Humanoid.JumpPower = 100
		end
	},
	{
		text = '%s wont jump',
		run = function(player: Player)
			player.Character.Humanoid.JumpPower = 0
		end
	},
	{
		text = '%s will be given a device',
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
					name = 'Ascend (temporarily)',
					run = function(c: Character)
						c.Head.Velocity = Vector3.yAxis * 100
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
	}
}
local platformEvents: { PlatformEvent } = {
	{
		text = '%s platform will expand by %.1f studs horizontally',
		run = function(platform: Part)
			local qty = math.random() * 10 - 5
			if platform.Size.X < -qty then
				platform:Destroy()
			else
				platform.Size += Vector3.new(qty, 0, qty)
			end
			return qty
		end
	},
	{
		text = '%s platform will expand by %.1f studs vertically',
		run = function(platform: Part)
			local qty = math.random() * 1.8 - 0.9
			if platform.Size.Y < -qty then
				platform:Destroy()
			else
				platform.Size += Vector3.yAxis * qty
			end
			return qty
		end
	},
	{
		text = '%s platform will be raised by %.1f studs',
		run = function(platform: Part)
			local qty = math.random() * 20 - 10
			TweenService:Create(platform, TweenInfo.new(math.random() * 20), {
				Position = platform.Position + Vector3.yAxis * qty
			}):Play()
			return qty
		end
	},
	{
		text = '%s platform will fade',
		run = function(platform: Part)
			local qty = math.random() * 30
			local tween = TweenService:Create(platform, TweenInfo.new(qty), {
				Transparency = 1
			})
			tween:Play()
			task.delay(qty, function()
				if platform then
					platform:Destroy()
				end
			end)
		end
	},
	{
		text = '%s platform will become %s',
		run = function(platform: Part)
			local factor = math.random(1, 5)
			local types: { PlateType } = {
				{
					name = 'corrosive',
					color = BrickColor.Yellow(),
					run = function(part: Part)
						if math.random() < .5 then return end
						local tween = TweenService:Create(part, TweenInfo.new(factor * 10), {
							Transparency = 1
						})
						tween:Play()
						task.delay(factor * 10, function()
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
							hum.MaxHealth += factor / 5
						end
						hum.Health += factor
					end
				},
				{
					name = 'violent',
					color = BrickColor.Red(),
					run = function(part: Part)
						local hum = part.Parent:FindFirstChild('Humanoid')
						if not hum then return end
						hum:TakeDamage(factor * 5)
					end
				}
			}
			local t = randomElement(types)
			platform.BrickColor = t.color
			platform.Touched:Connect(t.run)
			return t.name
		end
	},
	{
		text = '%s platform will leave',
		run = function(platform: Part)
			local dir = Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1)
			TweenService:Create(platform, TweenInfo.new(1000 / math.random()), {
				Position = platform.Position + dir * 500
			}):Play()
		end
	},
	{
		text = '%s platform will be cleared',
		run = function(platform: Part)
			platform:ClearAllChildren()
		end
	},
	{
		text = '%s will gain control of their platform',
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
	}
}

while true do
	local err = xpcall(function()
		local conns: { RBXScriptConnection } = {}
		local joined: { Player } = {}
		for i, player in next, Players:GetPlayers() do
			conns[i] = player.Chatted:Connect(function(message)
				if message == 'p%join' then
					table.insert(joined, player)
					conns[i]:Disconnect()
				end
			end)
		end
		local leftConn = Players.PlayerRemoving:Connect(function(player: Player)
			local i = table.find(joined, player)
			if i then
				table.remove(joined, i)
			end
		end)
		for i = 25, 1, -1 do
			local roster = ""
			for _, player in ipairs(joined) do
				roster ..= player.DisplayName .. '\n'
			end
			declare(`{('\n'):rep(#joined)}\ngithub.com/fofl12/sk - {ownername} is running this script - Starting the plate of the doom in {i} seconds - Say p%join to join\n{roster}`)
			task.wait(1)
		end
		leftConn:Disconnect()
		for _, conn in next, conns do
			if conn.Connected then
				conn:Disconnect()
			end
		end

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
			if not (player and player.Character and player.Character:FindFirstChild('Head') and player.Character:FindFirstChild('Humanoid')) then
				table.remove(joined, i)
			else
				player.Backpack:ClearAllChildren()
				player.Character.Humanoid.WalkSpeed = 16
				player.Character.Humanoid.JumpPower = 50
				player.Character.Humanoid.MaxHealth = 100
				if player.Character:FindFirstChild('Health') then
					player.Character.Health:Destroy()
				end
				player.Character.Head.CFrame = CFrame.new(0, 100, 0)
				local alive = player.Character.Humanoid.Died:Once(function()
					rem(i)
					remaining -= 1
				end)
				task.spawn(function()
					while task.wait(1) do
						if not alive.Connected then return end
						if not (player and player.Character and player.Character:FindFirstChild('Head')) then break end
						if player.Character.Head.Position.Y < 40 then break end
					end
					rem(i)
					alive:Disconnect()
					remaining -= 1
				end)
				aliveConns[i] = alive
				remaining += 1
			end
		end
		local survival = remaining == 1
		local w = math.ceil(math.sqrt(#joined))
		local h = math.floor(#joined / w)
		for i = 1, #joined do
			local new = Instance.new('Part')
			new.Anchored = true
			new.BrickColor = BrickColor.random()
			new.Size = Vector3.new(8, 1, 8)
			new.Position = Vector3.new(0, 50, 0) + Vector3.new(i % w - w / 2, 0, math.floor(i / w) - h / 2) * 14
			new.Name = joined[i].DisplayName
			platforms[i] = new
			new.Parent = script
			joined[i].Character.Head.CFrame = new.CFrame + Vector3.yAxis * 10
		end

		declare('Starting...')
		task.wait(3)

		local itm = 4
		while remaining > (if survival then 0 else 1) do
			local t = if math.random() < .4 then 'player' else 'platform'
			if t == 'player' then
				local event = randomElement(playerEvents)
				local player = randomElement(joined)
				declare(event.text:format(player.DisplayName, event.run(player)))
			elseif t == 'platform' then
				local event = randomElement(platformEvents)
				local platform = randomElement(platforms)
				declare(event.text:format(platform.Name, event.run(platform)))
			end
			if itm > 1 then
				itm -= .1
			end
			task.wait(itm)
		end

		if remaining == 1 then
			local winner = randomElement(joined)
			declare(`{winner.DisplayName} won ! ! !`)
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