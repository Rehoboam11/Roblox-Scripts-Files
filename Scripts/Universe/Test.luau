-- DVD-style bouncing TextLabel
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DVDScreenSaverGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Create the TextLabel
local label = Instance.new("TextLabel")
label.Name = "DVDLabel"
label.Text = "Loadstring Is Working!"
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.BackgroundTransparency = 0.4
label.BorderSizePixel = 0
label.Size = UDim2.new(0, 300, 0, 60)
label.Parent = screenGui

-- Colors to cycle through (classic DVD vibe)
local colors = {
    Color3.fromRGB(255, 80, 80),
    Color3.fromRGB(80, 255, 80),
    Color3.fromRGB(80, 80, 255),
    Color3.fromRGB(255, 255, 80),
    Color3.fromRGB(255, 80, 255),
    Color3.fromRGB(80, 255, 255),
}
local colorIndex = 1

-- Position starts at a random spot in the top-left area
local pos = Vector2.new(50, 50)
-- Velocity in pixels per second
local speed = 250
local velocity = Vector2.new(1, 1).Unit * speed
local colorChangedThisBounce = false

local function getViewportSize()
    local cam = workspace.CurrentCamera
    return Vector2.new(cam.ViewportSize.X, cam.ViewportSize.Y)
end

RunService.RenderStepped:Connect(function(dt)
    local vp = getViewportSize()
    local labelSize = Vector2.new(label.AbsoluteSize.X, label.AbsoluteSize.Y)

    -- Move
    pos = pos + velocity * dt

    local bounced = false

    -- Horizontal bounce
    if pos.X <= 0 then
        pos = Vector2.new(0, pos.Y)
        velocity = Vector2.new(-velocity.X, velocity.Y)
        bounced = true
    elseif pos.X + labelSize.X >= vp.X then
        pos = Vector2.new(vp.X - labelSize.X, pos.Y)
        velocity = Vector2.new(-velocity.X, velocity.Y)
        bounced = true
    end

    -- Vertical bounce
    if pos.Y <= 0 then
        pos = Vector2.new(pos.X, 0)
        velocity = Vector2.new(velocity.X, -velocity.Y)
        bounced = true
    elseif pos.Y + labelSize.Y >= vp.Y then
        pos = Vector2.new(pos.X, vp.Y - labelSize.Y)
        velocity = Vector2.new(velocity.X, -velocity.Y)
        bounced = true
    end

    -- Corner hit = color change (only once per bounce frame)
    if bounced and not colorChangedThisBounce then
        colorIndex = (colorIndex % #colors) + 1
        label.TextColor3 = colors[colorIndex]
        colorChangedThisBounce = true
    elseif not bounced then
        colorChangedThisBounce = false
    end

    -- Apply position
    label.Position = UDim2.new(0, math.floor(pos.X), 0, math.floor(pos.Y))
end)