-- using revolutionary technology, j
assert(getfenv().owner, 'wrong environment')
local rows, columns = 60, 60

local board = Instance.new('Part')
board.Position = owner.Character.Head.Position + Vector3.new(0, 10)
board.Size = Vector3.new(16, 24, 0)
board.Color = Color3.new()
board.Anchored = true
board.Transparency = 0--.6
board.Material = 'Glass'
board.Parent = script

local gui = Instance.new('SurfaceGui')
gui.SizingMode = 'PixelsPerStud'

local chatText = Instance.new('TextBox')
chatText.Font = 'Code'
chatText.BorderSizePixel = 0
chatText.TextXAlignment = 'Left'
chatText.RichText = true
chatText.TextEditable = false
chatText.TextColor3 = Color3.new(1, 1, 1)
chatText.BackgroundColor3 = Color3.new()
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

local x, y = 0, 0
local sx, sy = 0, 0
local bg, fg = Color3.new(), Color3.new(1, 1, 1)
local colors = {
	[30] = Color3.new(),
	[31] = Color3.new(1, 0, 0),
	[32] = Color3.new(0, 1, 0),
	[33] = Color3.new(1, 1, 0),
	[34] = Color3.new(0, 0, 1),
	[35] = Color3.new(1, 0, 1),
	[36] = Color3.new(0, 1, 1),
	[37] = Color3.new(1, 1, 1),
	[39] = fg,
	[49] = bg
}
local bgChanged, fgChanged = false, false
local control = false
local function out(str)
	for i = 1, #str do
		local c = str:sub(str, i)
		if c == '\x0a' then
			y += 1
			x = 0
		elseif c == '\x1b' then
			control = ''
		elseif c == '\x9b' then
			control = '['
		elseif c == '\x90' then
			control = 'P'
		elseif c == '\x9d' then
			control = ']'
		elseif c == ' ' and control == '' then
			continue
		elseif c == '\x08' and x >= 0 and x <= columns and y >= 0 and y < rows then
			x -= 1
			grid[x][y] = ''
		elseif c == '\x09' then
			x += 4
		elseif c == '\x0d' then
			x = 0
		elseif c == '\x7f' and x >= 0 and x < columns and y >= 0 and y < rows then
			grid[x][y] = ''
		elseif control == '[H' then
			control = false
			x = 0
			y = 0
		elseif control and control:sub(1, 1) == '[' and (control:sub(-1, -1) == 'H' or control:sub(-1, -1) == 'f') then
			control = false
			local split = control:sub(2, -2):split(';')
			x = tonumber(split[1])
			y = tonumber(split[2])
		elseif control and control:sub(1, 1) == '[' and ('ABCDEF'):match(control:sub(-1, -1)) then
			control = false
			local dir = control:sub(-1, -1)
			local q = tonumber(control:sub(2, -2))
				if dir == 'A' then y -= q
			elseif dir == 'B' then y += q
			elseif dir == 'C' then x += q
			elseif dir == 'D' then x -= q
			elseif dir == 'E' then x = 0; y += q + 1
			elseif dir == 'F' then x = 0; y -= q + 1
			end
		elseif control and control:sub(1, 1) == '[' and control:sub(-1, -1) == 'G' then
			control = false
			x = tonumber(control:sub(2, -2))
		elseif control == 'M' then
			control = false
			y -= 1
		elseif control == '7' or control == '[s' then
			control = false
			sx = x
			sy = y
		elseif control == '8' or control == '[u' then
			control = false
			x = sx
			y = sy
		elseif (control == '[J' or control == '[0J') and y >= 0 and y < columns then
			control = false
			for z = x, columns - 1 do
				grid[z][y] = ''
			end
			if y == rows - 1 then continue end
			for x = 0, columns - 1 do
				for z = y + 1, rows - 1 do
					grid[x][z] = ''
				end
			end
		elseif control == '[1J' and y >= 0 and y < columns then
			control = false
			for z = 0, x do
				grid[z][y] = ''
			end
			if y == 0 then continue end
			for w = 0, columns - 1 do
				for z = 0, y - 1 do
					grid[w][z] = ''
				end
			end
		elseif control == '[2J' then
			control = false
			for x = 0, columns - 1 do
				for y = 0, rows - 1 do
					grid[x][y] = ''
				end
			end
		elseif control == '[0K' and y >= 0 and y < columns then
			control = false
			for z = x, columns - 1 do
				grid[z][y] = ''
			end
		elseif control == '[1K' and y >= 0 and y < columns then
			control = false
			for z = 0, x do
				grid[z][y] = ''
			end
		elseif control == '[2K' and y >= 0 and y < columns then
			control = false
			for z = 0, columns - 1 do
				grid[z][y] = ''
			end
		elseif x < columns and y < rows and x >= 0 and y >= 0 then
			grid[x][y].Text = c
			if bgChanged then
				grid[x][y].BackgroundColor3 = bg
			end
			if fgChanged then
				grid[x][y].BackgroundColor3 = fg
			end
			x += 1
		end
	end
end