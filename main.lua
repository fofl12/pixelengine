screenx, screeny = unpack(owner.Chatted:Wait():split('x'))

timeout = 0
pixels = {}
colors = {
  black = Color3.fromRGB(26, 28, 44),
  purple = Color3.fromRGB(93, 39, 93),
  red = Color3.fromRGB(177, 62, 83),
  orange = Color3.fromRGB(239, 125, 87),
  yellow = Color3.fromRGB(255, 205, 117),
  lightGreen = Color3.fromRGB(167, 240, 112),
  green = Color3.fromRGB(56, 183, 100),
  darkGreen = Color3.fromRGB(37, 113, 121),
  darkBlue = Color3.fromRGB(41, 54, 11),
  blue = Color3.fromRGB(59, 93, 201),
  lightBlue = Color3.fromRGB(65, 166, 246),
  cyan = Color3.fromRGB(115, 239, 247),
  white = Color3.fromRGB(244, 244, 244),
  lightGray = Color3.fromRGB(148, 176, 194),
  gray = Color3.fromRGB(86, 108, 134),
  darkGray = Color3.fromRGB(51, 60, 87)
}
anchor = owner.Character.Head.Position
for x = -screenx/2, screenx/2 do
  pixels[x + (screenx/2) + 1] = {}
  for y = screeny/2, -screeny/2, -1 do
    timeout += 1
    if timeout >= 999 then
      wait(1)
      timeout = 0
    end
    local pixel = Instance.new('WedgePart')
    pixel.Anchored = true
    pixel.Locked = true
    pixel.CanCollide = false
    pixel.Position = anchor + Vector3.new(x/5, y/5 +(screeny/10 - 3), 0)
    pixel.Size = Vector3.new(0.2, 0.2, 0)
    pixel.Color = (x%2 == 0 and y%2 == 0) and colors.white or (x%2 == 0) and colors.yellow or (y%2==0) and colors.purple or colors.red
    pixel.Parent = script
    table.insert(pixels[x + (screenx/2) + 1], pixel)
  end
end
local psound = Instance.new('Sound')
psound.Parent = pixels[math.floor(screenx/2)][math.floor(screeny/2)]
psound.Looped = true
local pamount = 0
letters = loadstring(game:GetService('HttpService'):GetAsync('https://store.snoo8.repl.co/letters'))() -- this was 500 lines long!

binds = {
  update = {},
  input = {},
}
pressing = {}
api = {
  pset = function(x, y, color)
    if not pixels[x] then
      return
    elseif not pixels[x][y] then
      return
    end
    pixels[x][y].Color = color
  end,
  pget = function(x, y)
    if not pixels[x] then
      return
    elseif not pixels[x][y] then
      return
    end
    return pixels[x][y].Color
  end,
  rect = function(x1, y1, x2, y2, color)
    for x = x1, x2 do
      for y = y1, y2 do
        api.pset(x, y, color)
      end
    end
  end,
  text = function(text, x, y, color)
    x = x or 1
    y = y or 1
    color = color or colors.white
    text = text:upper()
    for i = 1, #text do
      local c = text:sub(i, i)
      for _, pixel in ipairs(letters[c] or {}) do
        api.pset(pixel.x + ((i -1) * 4) + x, pixel.y + y, color)
      end
    end
  end,
  cls = function(color)
    color = color or colors.black
    api.rect(1, 1, screenx +1, screeny +1, color)
  end,
  bind = function(channel, listener)
    assert(binds[channel], 'bad argument #1 (channel): channel not found')
    table.insert(binds[channel], listener)
  end,
  lerp = function(a,b,t)
    return a+(b-a)*t
  end,
  line = function(x1,y1,x2,y2,color,points)
    points = points or 25
    for i=1,points do
      local a = i/points
      local x = api.lerp(x1,x2,a)
      local y = api.lerp(y1,y2,a)
      x,y = math.floor(x),math.floor(y)
      api.pset(x,y,color)
    end
  end,
  circ = function(x, y, radius, color)
    for px = x - radius, x + radius do
      for py = y - radius, y + radius do
        if (px - x)^2 + (py - y)^2 < radius^2 then
          api.pset(px, py, color)
        end
      end
    end
  end,
  btn = function(key)
    return pressing[key]
  end,
  sound = function(note,num,duration,sync) -- retro_jono
    local notes = {
    c=16.35,
    ["c#"]=17.32,
    d=18.35,
    ["d#"]=19.45,
    e=20.60,
    ["f"]=21.83,
    ["f#"]=23.12,
    ["g"]=24.50,
    ["g#"]=25.96,
    ["a"]=27.50,
    ["a#"]=29.14,
    ["b"]=30.87
    }
    num = num or 0
    local frequency = notes[note:lower()]
    frequency += notes.c*num
    sync = sync or true
    pamount = pamount + 1
    psound.SoundId = 'rbxassetid://4634655379'
    psound.Looped = true
    psound.Volume = 0.6
    local div = frequency/200
    psound.PlaybackSpeed = div
    psound:Play()
    if sync then
    wait(duration)
    psound:Stop()
    pamount = pamount - 1
    else
    spawn(function()
    wait(duration)
    sound:Stop()
    pamount = pamount - 1
    end)
    end
  end,
  getLoudness = function()
  return pamount
  end,
  broadcast = function(key,value)
    _G['pixel_'..key]=value
  end,
  subscribe = function(key,func)
  local v = _G['pixel_'..key]
  api.bind('update',function()
  local cv = _G['pixel_'..key]
  if cv ~= v then
  v = cv
  func(cv)
  end
  end)
  end
}
newenv = {
  print = print,
  screenx = screenx,
  screeny = screeny,
  math = math,
  table = table,
  os = os,
  wait = wait,
  tostring = tostring,
  tonumber = tonumber,
  pcall = pcall,
  ipairs = ipairs,
  pairs = pairs
}
for k, func in pairs(api) do
  newenv[k] = func
end
for name, color in pairs(colors) do
  newenv[name] = color
end
updates = {}

-- receive input from client
runport = Instance.new('RemoteEvent', owner.PlayerGui)
runport.Name = 'RunPortPIXELENGINE'
runport.OnServerEvent:Connect(function(p, c, m)
  if p == owner then
    if m == 'c' then
      c = loadstring(c)
      table.insert(updates, c)
      setfenv(c, newenv)
      c()
    elseif m == 'ie' then
      pressing[c] = false
      for _, func in ipairs(binds.input) do
        func(c)
      end
    elseif m == 'is' then
      pressing[c] = true
    end
  end
end)
NLS([[
port = script.Parent
uis = game:GetService('UserInputService')

gui = Instance.new('ScreenGui', script)
script.Parent = owner.PlayerGui
port.Parent = script

editor = Instance.new('TextBox')
editor.BackgroundColor3 = Color3.new()
editor.Position = UDim2.fromScale(0.93, 0.9)
editor.Size = UDim2.fromScale(0.2, 0.2)
editor.MultiLine = true
editor.TextScaled = true
editor.Font = 'Code'
editor.ClearTextOnFocus = false
editor.AnchorPoint = Vector2.new(1, 1)
editor.AutomaticSize = 'None'
editor.TextColor3 = Color3.new(1, 1, 1)
editor.TextXAlignment = 'Left'
editor.TextYAlignment = 'Top'
editor.TextSize = 20
editor.Parent = gui

button = Instance.new('TextButton')
button.Text = 'Run!'
button.TextScaled = true
button.Font = 'Code'
button.BackgroundColor3 = Color3.new()
button.TextColor3 = Color3.new(1, 1, 1)
button.AnchorPoint = Vector2.new(1, 0)
button.Size = UDim2.fromScale(0.2, 0.1)
button.Position = editor.Position
button.MouseButton1Click:Connect(function()
  port:FireServer(editor.Text, 'c')
end)
button.Parent = gui

uis.InputBegan:Connect(function(input, processed)
  port:FireServer(uis:GetStringForKeyCode(input.KeyCode), 'is')
end)
uis.InputEnded:Connect(function(input, processed)
  port:FireServer(uis:GetStringForKeyCode(input.KeyCode), 'ie')
end)
]], runport)

game:GetService('RunService').Heartbeat:Connect(function(delta)
  for _, func in ipairs(binds.update) do
    func(delta)
  end
end)
owner.Chatted:Connect(function(m)
  local command = m:split('/')
  if command[1] == 'pixel' then
    if command[2] == 'stop' then
      for name, _ in pairs(binds) do
        print(#binds[name])
        table.clear(binds[name])
      end
    end
  end
end)

api.cls()
api.text('PixelEngine ready!')
api.text('Use the built in IDE', 1, 8)
api.text('Press "Run!" to run', 1, 16)
