assert(getfenv().NLS, 'wrong environment')
assert(getfenv().owner, 'wrong enviornment')
local rows, columns = 25, 40
local autoload = true

local uis = game:service'UserInputService'

local board = Instance.new('Part')
board.Position = owner.Character.Head.Position + Vector3.new(0, 2)
board.Size = Vector3.new(12, 12, 0)
board.Color = Color3.new()
board.Anchored = true
board.Transparency = 0.6
board.Material = 'Glass'
board.Parent = script

local gui = Instance.new('SurfaceGui')
gui.SizingMode = 'PixelsPerStud'

local chatText = Instance.new('TextBox')
chatText.Font = 'Code'
chatText.BorderSizePixel = 0
chatText.TextXAlignment = 'Left'
chatText.RichText = true
chatText.BackgroundTransparency = 1
chatText.TextEditable = false
chatText.TextColor3 = Color3.new(1, 1, 1)
chatText.Size = UDim2.fromScale(1 / columns, 1 / rows)
chatText.TextScaled = true
chatText.TextYAlignment = 'Top'

local grid = {}
for x = 0, columns - 1 do
	grid[x] = {}
	for y = 0, rows - 1 do
		local text = chatText:Clone()
		text.Position = UDim2.fromScale(x / columns, y / rows)
		text.Text = ''
		text.Parent = gui
		grid[x][y] = text
		if y % 8 == 0 then
			task.wait()
		end
	end
end
gui.Parent = board

local x, y, noline = 0, 0, false
local bg, fg = Color3.new(), Color3.new(1, 1, 1)
local function clone(t)
	local new = {}
	for k, v in next, t do
		if type(v) == 'table' then
			new[k] = clone(v)
		elseif typeof(v) == 'Instance' then
			new[k] = {
				BackgroundTransparency = v.BackgroundTransparency,
				Text = v.Text,
				BackgroundColor3 = v.BackgroundColor3,
				TextColor3 = v.TextColor3
			}
		else
			new[k] = v
		end
	end
	return new
end
local function compareColor(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
local function scroll(n)
	local buffer = clone(grid)
	for x = 0, columns - 1 do
		for y = n<0 and 0 or n, n<0 and rows - (-n + 1) or rows - 1 do
			local target = grid[x][y]
			local buffered = buffer[x][y-n]
			target.Text = buffered.Text
			target.BackgroundTransparency = buffered.BackgroundTransparency
			target.BackgroundColor3 = buffered.BackgroundColor3
			target.TextColor3 = buffered.TextColor3
		end
		local target
		if n < 0 then
			target = grid[x][rows - 1]
		elseif n > 0 then
			target = grid[x][0]
		end
		target.Text = ''
		target.BackgroundTransparency = 1
		target.BackgroundColor3 = Color3.new()
		target.TextColor3 = Color3.new(1, 1, 1)
	end
	y += n
end
local function out(str)
	for f, l in utf8.graphemes(str) do
		local c = str:sub(f, l)
		if y >= rows then
			scroll(-1)
		end
		if c == '\n' then
			y += 1
			x = 0
		elseif x < columns then
			grid[x][y].Text = c
			if compareColor(bg, Color3.new()) then
				grid[x][y].BackgroundTransparency = 1
			else
				grid[x][y].BackgroundTransparency = 0
				grid[x][y].BackgroundColor3 = bg
			end
			grid[x][y].TextColor3 = fg
			x += 1
			if x >= columns and not noline then
				y += 1
				x = 0
				print('Wrapping', noline)
			end
		end
	end
end

out('Welcome to Marcuskernel !\n')
out('Establishing input connection...\n')
local remote = Instance.new('RemoteEvent', owner.PlayerGui)
NLS([[
local uis = game:service'UserInputService'
local remote = script.Parent

local ui = Instance.new('ScreenGui')
local frame = Instance.new('Frame')
frame.Size = UDim2.fromOffset(20, 20)
frame.AnchorPoint = Vector2.one
frame.Position = UDim2.fromScale(1, 1)
frame.Parent = ui

local message = Instance.new('TextBox')
message.Text = ''
message.Size = UDim2.fromScale(1, 1)
message.Parent = frame

message.FocusLost:Connect(function(r)
	if r then
		remote:FireServer(Enum.KeyCode.Return)
		message.Text = ''
	end
end)
uis.InputBegan:Connect(function(i)
	if i.UserInputType.Name == 'Keyboard' and message:IsFocused() then
		remote:FireServer(i.KeyCode)
		message.Text = ''
	end
end)
uis.InputEnded:Connect(function(i)
	if i.KeyCode.Name == 'LeftShift' and message:IsFocused() then
		remote:FireServer(i.KeyCode)
	end
end)

ui.Parent = script
]], remote)
local shiftmap = {
	['1'] = '!',
	['2'] = '@',
	['3'] = '#',
	['4'] = '$',
	['5'] = '%',
	['6'] = '^',
	['7'] = '&',
	['8'] = '*',
	['9'] = '(',
	['0'] = ')',
	['-'] = '_',
	['='] = '+',
	['['] = '{',
	[']'] = '}',
	[';'] = ':',
	["'"] = '"',
	['\\'] = '|',
	[','] = '<',
	['.'] = '>',
	['/'] = '?'
}
local cmap = {
	One = '1',
	Two = '2',
	Three = '3',
	Four = '4',
	Five = '5',
	Six = '6',
	Seven = '7',
	Eight = '8',
	Nine = '9',
	Zero = '0',
	Minus = '-',
	Equals = '=',
	LeftBracket = '[',
	RightBracket = ']',
	Semicolon = ';',
	Quote = "'",
	QuotedDouble = '"',
	BackSlash = '\\',
	Comma = ',',
	Period = '.',
	Slash = '/',
	Space = ' '
}
local lines = {}
local function input()
	local message = ''
	local done = false
	local shift = false
	repeat
		local input = select(2, remote.OnServerEvent:Wait())
		local string = uis:GetStringForKeyCode(input)
		if #string > 1 then
			string = cmap[string] or '?'
		end
		if input.Name == 'Return' then
			done = true
		elseif input.Name == 'Backspace' then
			if #message > 0 then
				message = message:sub(1, -2)
				x -= 1
				if x < 0 then
					x = columns - 1
					y -= 1
				end
				grid[x][y].Text = ''
			end
		elseif input.Name == 'Tab' then
			message ..= '    '
		elseif input.Name == 'LeftShift' then
			shift = not shift
		elseif shiftmap[string] then
			if shift then
				string = shiftmap[string]
			end
			message ..= string
			out(string)
		elseif shift then
			message ..= string:upper()
			out(string:upper())
		else
			message ..= string:lower()
			out(string:lower())
		end
		print(done)
	until done
	return message
end

local utils = {
	service = function(n)
		return game:GetService(n)
	end,
	clear = function()
		for x = 0, columns - 1 do
			for y = 0, rows - 1 do
				grid[x][y].Text = ''
			end
		end
		x, y = 0, 0
	end
}

utils.clear()
out('Marcus Educational Engine 2014\n')

local missions = {
	{
		name = 'robux synthesis',
		desc = [[Robux corporation: Unfortunately the component in the robux synthesizer has broken down... For the robux synthesizer to operate correctly, the component must generate the following signal to o0:

after 0 ticks: 0
after 4 ticks: 1
after 5 ticks: repeat

Additionally, when i0 is 1, the component must not output 1, otherwise horrible things will happen.]],
		check = {
			i0 = '0001003001'
		}
	},
}

for i, mission in ipairs(missions) do
	out(`Mission {i}: {mission.name}\n`)
	out(mission.desc .. '\n\n')
	out('Input ok to continue\n')
	while input() ~= 'ok' do task.wait() end
	utils.clear()
	while true do
		local inp = input()
		if inp == '--!run' then
			out('what\n')
		else
			
		end
	end
end
out('You win!')