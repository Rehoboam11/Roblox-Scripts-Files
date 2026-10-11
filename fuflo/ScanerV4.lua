-- === Tool System - Self-Creating ===
-- This script creates the entire tool from scratch from code.
-- Mode modules (Base, Translator) remain as children of this LocalScript.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local script_2 = script
local v1 = { "rbxassetid://8681113666", "rbxassetid://8681113503" }
local v2 = Color3.new()
local LocalPlayer = game.Players.LocalPlayer

-- Create the Tool locally (client-side only)
local Parent = Instance.new("Tool")
Parent.Name = "Scanner"
Parent.TextureId = "rbxassetid://86882268877357"

-- ============================================================
-- === TOOL BUILDER: Create all physical instances from code ===
-- ============================================================

local ROT = CFrame.new(40.922359, 0.416887, 25.345053, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298)

-- Helper: create a sound with distortion + equalizer effects
local function makeSound(name, soundId, parent, props)
    local snd = Instance.new("Sound")
    snd.Name = name
    snd.SoundId = soundId
    snd.Parent = parent
    snd.RollOffMode = Enum.RollOffMode.Inverse
    snd.RollOffMinDistance = props.minDist or 10
    snd.RollOffMaxDistance = props.maxDist or 70
    snd.Volume = props.volume or 0.4
    snd.PlaybackSpeed = props.playbackSpeed or 1.08
    snd.Looped = props.looped or false
    snd.AcousticSimulationEnabled = true
    local dist = Instance.new("DistortionSoundEffect")
    dist.Level = 0.19
    dist.Parent = snd
    local eq = Instance.new("EqualizerSoundEffect")
    eq.LowGain = -2
    eq.Parent = snd
    return snd
end

-- Helper: create a MeshPart (tries real MeshPart first, falls back to Part + SpecialMesh)
local meshPartWorks = nil -- cached check result

local function makeMeshPart(name, parent, meshId, size, color, material, cframe, matVariant)
    -- First call: test if we can assign MeshId on a MeshPart
    if meshPartWorks == nil then
        local test = Instance.new("MeshPart")
        local ok = pcall(function()
            test.MeshId = meshId
        end)
        test:Destroy()
        meshPartWorks = ok
    end

    if meshPartWorks then
        -- Try real MeshPart
        local p = Instance.new("MeshPart")
        p.Name = name
        p.MeshId = meshId
        p.Size = size
        p.Color = color
        p.Material = material
        p.Anchored = false
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Massless = true
        if matVariant then
            p.MaterialVariant = matVariant
        end
        p.CFrame = cframe or ROT
        p.Parent = parent
        CollectionService:AddTag(p, "Tool")
        return p
    else
        -- Fallback: Part + SpecialMesh
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = material
        p.Anchored = false
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Massless = true
        if matVariant then
            p.MaterialVariant = matVariant
        end
        p.CFrame = cframe or ROT
        p.Parent = parent
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = meshId
        mesh.Scale = Vector3.new(0.1, 0.1, 0.1)
        mesh.Parent = p
        CollectionService:AddTag(p, "Tool")
        return p
    end
end

-- Helper: create a ManualWeld
local function makeWeld(name, parent, part0, part1, c0, c1)
    local w = Instance.new("ManualWeld")
    w.Name = name
    w.Part0 = part0
    w.Part1 = part1
    w.C0 = c0
    w.C1 = c1
    w.Parent = parent
    return w
end

-- Helper: create a Motor6D
local function makeMotor6D(name, parent, part0, part1, c0, c1)
    local m = Instance.new("Motor6D")
    m.Name = name
    m.Part0 = part0
    m.Part1 = part1
    m.C0 = c0
    m.C1 = c1
    m.Parent = parent
    return m
end

-- === Tool properties ===
Parent.RequiresHandle = true
Parent.CanBeDropped = false
Parent.ManualActivationOnly = false
Parent.Enabled = true
Parent.Grip = CFrame.Angles(0, math.rad(180), 0)

-- === Create RemoteEvents and BindableEvent ===
local scannerRemote = Instance.new("RemoteEvent")
scannerRemote.Name = "ScannerRemote"
scannerRemote.Parent = Parent

local remoteInspect = Instance.new("RemoteEvent")
remoteInspect.Name = "RemoteInspect"
remoteInspect.Parent = Parent

local remote = Instance.new("RemoteEvent")
remote.Name = "Remote"
remote.Parent = Parent

local inspectEvent = Instance.new("BindableEvent")
inspectEvent.Name = "Inspect"
inspectEvent.Parent = Parent

-- === Create Animations folder ===
local animationsFolder = Instance.new("Folder")
animationsFolder.Name = "Animations"
animationsFolder.Parent = Parent

local animData = {
    pulse = "rbxassetid://115807527355203",
    idle_open = "rbxassetid://119934405970307",
    open = "rbxassetid://97556807275075",
    next_mode = "rbxassetid://83536005758085",
    idleflash = "rbxassetid://106123983525813",
    close = "rbxassetid://82257777041378",
    hurt_player = "rbxassetid://92597413839265",
    idle = "rbxassetid://95245369097972",
    equip = "rbxassetid://100315894378762",
    inspect_open = "rbxassetid://129601876662747",
    inspect = "rbxassetid://138959594202805",
}
for animName, animId in pairs(animData) do
    local anim = Instance.new("Animation")
    anim.Name = animName
    anim.AnimationId = animId
    anim.Parent = animationsFolder
end

-- === Create Handle (try MeshPart first, fallback to Part + SpecialMesh) ===
if meshPartWorks == nil then
    local test = Instance.new("MeshPart")
    local ok = pcall(function()
        test.MeshId = "rbxassetid://72135053121437"
    end)
    test:Destroy()
    meshPartWorks = ok
end

local Handle
if meshPartWorks then
    Handle = Instance.new("MeshPart")
    Handle.Name = "Handle"
    Handle.MeshId = "rbxassetid://72135053121437"
    Handle.Size = Vector3.new(0.7948293685913086, 1.0606509447097778, 0.38293057680130005)
    Handle.Color = Color3.new(0.30588236451148987, 0.3137255012989044, 0.30588236451148987)
    Handle.Material = Enum.Material.Concrete
    Handle.Anchored = false
    Handle.CanCollide = false
    Handle.CanQuery = false
    Handle.CanTouch = false
    Handle.CastShadow = false
    Handle.Massless = true
    Handle.CFrame = ROT
    Handle.Parent = Parent
else
    Handle = Instance.new("Part")
    Handle.Name = "Handle"
    Handle.Size = Vector3.new(0.7948293685913086, 1.0606509447097778, 0.38293057680130005)
    Handle.Color = Color3.new(0.30588236451148987, 0.3137255012989044, 0.30588236451148987)
    Handle.Material = Enum.Material.Concrete
    Handle.Anchored = false
    Handle.CanCollide = false
    Handle.CanQuery = false
    Handle.CanTouch = false
    Handle.CastShadow = false
    Handle.Massless = true
    Handle.CFrame = ROT
    Handle.Parent = Parent
    local handleMesh = Instance.new("SpecialMesh")
    handleMesh.MeshType = Enum.MeshType.FileMesh
    handleMesh.MeshId = "rbxassetid://72135053121437"
    handleMesh.Scale = Vector3.new(0.1, 0.1, 0.1)
    handleMesh.Parent = Handle
end

CollectionService:AddTag(Handle, "Tool")

-- ToolGripAttach
local toolGrip = Instance.new("Attachment")
toolGrip.Name = "ToolGripAttach"
toolGrip.CFrame = CFrame.new(-1.2, -0.15, 0.3, -1, 0, 0, 0, 1, 0, 0, 0, -1)
toolGrip.Parent = Handle

-- Handle sounds
makeSound("ScannedIdle", "rbxassetid://94419645391952", Handle, {volume = 1, minDist = 10, maxDist = 50, looped = true})
makeSound("NextMode", "rbxassetid://95848045493309", Handle, {volume = 0.4, minDist = 10, maxDist = 70})
makeSound("SystemIdle", "rbxassetid://8689839904", Handle, {volume = 0.4, minDist = 10, maxDist = 50, looped = true})
makeSound("BootSystem", "rbxassetid://8689839379", Handle, {volume = 0.4, minDist = 10, maxDist = 70})
makeSound("CloseSystem", "rbxassetid://8690667956", Handle, {volume = 0.4, minDist = 10, maxDist = 70})

-- === Create sub-meshparts ===

-- Top
local Top = makeMeshPart("Top", Handle, "rbxassetid://136068389764944",
    Vector3.new(0.7948293685913086, 0.7948293685913086, 0.15888497233390808),
    Color3.new(0.2862745225429535, 0.29411765933036804, 0.2862745225429535),
    Enum.Material.Concrete,
    CFrame.new(41.792847, 0.294155, 24.998211, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298))

-- ScanInner (child of Top)
local ScanInner = makeMeshPart("ScanInner", Top, "rbxassetid://84793978414643",
    Vector3.new(0.5189781785011292, 0.13837042450904846, 0.04632126912474632),
    Color3.new(0.30980393290519714, 0.30980393290519714, 0.3333333432674408),
    Enum.Material.DiamondPlate,
    CFrame.new(42.004807, 0.145912, 24.919277, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298),
    "GoodDiamondPlate")

-- ScanFrame (child of Top)
local ScanFrame = makeMeshPart("ScanFrame", Top, "rbxassetid://73398346744646",
    Vector3.new(0.6161409020423889, 0.23811613023281097, 0.11020133644342422),
    Color3.new(0.14509804546833038, 0.14509804546833038, 0.15294118225574493),
    Enum.Material.Concrete,
    CFrame.new(42.005005, 0.149562, 24.919027, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298))

-- Screen (child of Top)
local Screen = Instance.new("Part")
Screen.Name = "Screen"
Screen.Size = Vector3.new(0.6487300395965576, 0.6466816663742065, 0.08410091698169708)
Screen.Color = Color3.new(0.0941176488995552, 0.0941176488995552, 0.11372549086809158)
Screen.Material = Enum.Material.Glass
Screen.Anchored = false
Screen.CanCollide = false
Screen.CanQuery = false
Screen.CanTouch = false
Screen.CastShadow = false
Screen.Massless = true
Screen.CFrame = CFrame.new(41.793365, 0.301033, 24.997944, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298)
Screen.Parent = Top
CollectionService:AddTag(Screen, "Tool")

-- ButtonRight
local ButtonRight = makeMeshPart("ButtonRight", Handle, "rbxassetid://91975580778439",
    Vector3.new(0.19025619328022003, 0.3685862123966217, 0.03358990326523781),
    Color3.new(0.23137255012989044, 0.3176470696926117, 0.23137255012989044),
    Enum.Material.Concrete,
    CFrame.new(41.096157, 0.449216, 25.453396, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298))

-- ButtonLeft
local ButtonLeft = makeMeshPart("ButtonLeft", Handle, "rbxassetid://136649740219349",
    Vector3.new(0.19025619328022003, 0.3685862123966217, 0.03358990326523781),
    Color3.new(0.3137255012989044, 0.20392157137393951, 0.20392157137393951),
    Enum.Material.Concrete,
    CFrame.new(40.970959, 0.434805, 25.144295, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298))

-- Hinges
local Hinges = makeMeshPart("Hinges", Handle, "rbxassetid://129054646143137",
    Vector3.new(0.6349631547927856, 0.05071982368826866, 0.05856619402766228),
    Color3.new(0.2666666805744171, 0.27450981736183167, 0.29019609093666077),
    Enum.Material.DiamondPlate,
    CFrame.new(41.419662, 0.360839, 25.14625, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298),
    "GoodDiamondPlate")

-- Neon
local Neon = makeMeshPart("Neon", Handle, "rbxassetid://111984697679909",
    Vector3.new(0.45905303955078125, 0.09092073142528534, 0.04118501767516136),
    Color3.new(0.13725490868091583, 0.14509804546833038, 0.16470588743686676),
    Enum.Material.Glass,
    CFrame.new(42.004089, 0.146825, 24.919525, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298))

-- Antenna
local Antenna = makeMeshPart("Antenna", Handle, "rbxassetid://74801546219578",
    Vector3.new(0.10972104966640472, 0.5924474596977234, 0.06363590806722641),
    Color3.new(0.24705882370471954, 0.2549019753932953, 0.24705882370471954),
    Enum.Material.DiamondPlate,
    CFrame.new(42.480549, 0.260207, 25.047796, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298),
    "GoodDiamondPlate")

-- Void
local Void = makeMeshPart("Void", Handle, "rbxassetid://124381943286292",
    Vector3.new(0.015310646966099739, 0.49222472310066223, 0.0771745890378952),
    Color3.new(0, 0, 0),
    Enum.Material.Neon,
    CFrame.new(40.970287, 0.302114, 24.903645, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298))

-- Ports
local Ports = makeMeshPart("Ports", Handle, "rbxassetid://82557323015392",
    Vector3.new(0.02375197783112526, 0.5249946117401123, 0.10225042700767517),
    Color3.new(0.2823529541492462, 0.2823529541492462, 0.3019607961177826),
    Enum.Material.Concrete,
    CFrame.new(40.971096, 0.301877, 24.896341, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298))

-- Speaker
local Speaker = makeMeshPart("Speaker", Handle, "rbxassetid://135471906631508",
    Vector3.new(0.4476732015609741, 0.17081105709075928, 0.006285981275141239),
    Color3.new(0.14509804546833038, 0.14509804546833038, 0.1568627506494522),
    Enum.Material.DiamondPlate,
    CFrame.new(40.573936, 0.638871, 25.475815, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298),
    "GoodDiamondPlate")

-- === Create welds and joints ===

-- Motor6D: Top_Joint (Handle -> Top)
makeMotor6D("Top_Joint", Top, Handle, Top,
    CFrame.new(0, 0.53717041015625, -0.02056884765625),
    CFrame.new(0, -0.406463623046875, -0.07220458984375))

-- Motor6D: ButtonRight_Joint (Handle -> ButtonRight)
makeMotor6D("ButtonRight_Joint", ButtonRight, Handle, ButtonRight,
    CFrame.new(-0.166900634765625, 0.1181640625, -0.0341796875),
    CFrame.new(0, 0, 0))

-- Motor6D: ButtonLeft_Joint (Handle -> ButtonLeft)
makeMotor6D("ButtonLeft_Joint", ButtonLeft, Handle, ButtonLeft,
    CFrame.new(0.166900634765625, 0.1181640625, -0.0341796875),
    CFrame.new(0, 0, 0))

-- Motor6D: Antenna_Joint (Top -> Antenna)
makeMotor6D("Antenna_Joint", Antenna, Top, Antenna,
    CFrame.new(-0.3023681640625, 0.37750244140625, 0.0001220703125),
    CFrame.new(0, -0.243072509765625, 0))

-- ManualWelds
local FLIP = CFrame.new(0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1)

makeWeld("Weld", ScanInner, ScanInner, Top, FLIP,
    CFrame.new(0, 0.236663818, 0.130859375, -1, 0, 0, 0, 1, 0, 0, 0, -1))

makeWeld("Weld", ScanFrame, ScanFrame, Top, FLIP,
    CFrame.new(0, 0.236663818, 0.127197266, -1, 0, 0, 0, 1, 0, 0, 0, -1))

makeWeld("Weld", Screen, Screen, Top, FLIP,
    CFrame.new(-0.000244140625, 6.10351562e-05, -0.00689697266, -1, 0, 0, 0, 1, 0, 0, 0, -1))

makeWeld("Weld", Hinges, Hinges, Handle, FLIP,
    CFrame.new(0, 0.538269043, 0.0154418945, -1, 0, 0, 0, 1, 0, 0, 0, -1))

makeWeld("Weld", Void, Void, Handle, FLIP,
    CFrame.new(0.395721436, 0.216918945, 0.0816040039, -1, 0, 0, 0, 1, 0, 0, 0, -1))

makeWeld("Weld", Ports, Ports, Handle, FLIP,
    CFrame.new(0.402191162, 0.220397949, 0.0812988281, -1, 0, 0, 0, 1, 0, 0, 0, -1))

makeWeld("Weld", Speaker, Speaker, Handle, FLIP,
    CFrame.new(0, -0.387756348, -0.19342041, -1, 0, 0, 0, 1, 0, 0, 0, -1))

makeWeld("Weld", Neon, Neon, Top, FLIP,
    CFrame.new(0, 0.235839844, 0.130004883, -1, 0, 0, 0, 1, 0, 0, 0, -1))

-- === Create Neon effects ===

-- AttachmentStart
local attStart = Instance.new("Attachment")
attStart.Name = "AttachmentStart"
attStart.CFrame = CFrame.new(0, 0, 0.03289794921875, -1, 0, 0, 0, 1, 0, 0, 0, -1)
attStart.Visible = false
attStart.Parent = Neon

-- Shiny ParticleEmitter (child of AttachmentStart)
local shiny = Instance.new("ParticleEmitter")
shiny.Name = "Shiny"
shiny.Texture = "rbxassetid://15148942452"
shiny.Lifetime = NumberRange.new(0.3, 0.3)
shiny.Rate = 20
shiny.Speed = NumberRange.new(0.05, 0.05)
shiny.SpreadAngle = Vector2.new(0, 0)
shiny.Rotation = NumberRange.new(-3, 3)
shiny.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0.8)})
shiny.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5, 0), NumberSequenceKeypoint.new(1, 0.5, 0)})
shiny.Color = ColorSequence.new(Color3.fromRGB(80, 72, 28))
shiny.LightEmission = 1
shiny.LightInfluence = 0
shiny.LockedToPart = true
shiny.Enabled = false
shiny.Orientation = Enum.ParticleOrientation.FacingCamera
shiny.EmissionDirection = Enum.NormalId.Bottom
shiny.Shape = Enum.ParticleEmitterShape.Box
shiny.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
shiny.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
shiny.Parent = attStart

-- AttachmentEnd
local attEnd = Instance.new("Attachment")
attEnd.Name = "AttachmentEnd"
attEnd.CFrame = CFrame.new(0, 0, 8.666000366210938)
attEnd.Visible = false
attEnd.Parent = Neon

-- LightAttach
local lightAtt = Instance.new("Attachment")
lightAtt.Name = "LightAttach"
lightAtt.CFrame = CFrame.new(0, 0, 0.10992431640625, -1, 0, 0, 0, 1, 0, 0, 0, -1)
lightAtt.Visible = false
lightAtt.Parent = Neon

-- SpotLight (child of LightAttach)
local spotLight = Instance.new("SpotLight")
spotLight.Name = "SurfaceLight"
spotLight.Enabled = false
spotLight.Shadows = true
spotLight.Color = Color3.fromRGB(255, 235, 130)
spotLight.Face = Enum.NormalId.Front
spotLight.Range = 60
spotLight.Angle = 90
spotLight.Brightness = 3
spotLight.Parent = lightAtt

-- PointLight (child of Neon)
local pointLight = Instance.new("PointLight")
pointLight.Name = "PointLight"
pointLight.Enabled = false
pointLight.Color = Color3.fromRGB(255, 240, 140)
pointLight.Range = 3
pointLight.Brightness = 3
pointLight.Shadows = false
pointLight.Parent = Neon

-- Beam (child of Neon)
local beam = Instance.new("Beam")
beam.Name = "Beam"
beam.Attachment0 = lightAtt
beam.Attachment1 = attEnd
beam.Enabled = false
beam.FaceCamera = true
beam.Width0 = 1
beam.Width1 = 20
beam.Texture = "rbxassetid://15149007027"
beam.TextureLength = 14
beam.TextureMode = Enum.TextureMode.Static
beam.TextureSpeed = 0
beam.Segments = 20
beam.LightEmission = 1
beam.LightInfluence = 0
beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80))
beam.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.05, 0.95),
    NumberSequenceKeypoint.new(1, 0)
})
beam.Parent = Neon

-- Weld (Weld class) for WideLight
local neonWeld = Instance.new("Weld")
neonWeld.Name = "Weld"
neonWeld.Part0 = Neon
neonWeld.Part1 = nil -- will set after WideLight is created
neonWeld.C0 = CFrame.new(0.000366210938, 0.00021982193, -0.000305175781)
neonWeld.C1 = CFrame.new(0, 0, 0)
neonWeld.Parent = Neon

-- WideLight (Part, child of Neon)
local wideLight = Instance.new("Part")
wideLight.Name = "WideLight"
wideLight.Size = Vector3.new(5.5, 0.09099999815225601, 0.04100000113248825)
wideLight.Color = Color3.new(0.13725490868091583, 0.14509804546833038, 0.16470588743686676)
wideLight.Material = Enum.Material.Plastic
wideLight.Anchored = true
wideLight.CanCollide = false
wideLight.CanQuery = false
wideLight.CanTouch = false
wideLight.CastShadow = false
wideLight.Massless = true
wideLight.Transparency = 1
wideLight.CFrame = CFrame.new(42.004166, 0.147097, 24.919083, -0.375053, 0.925434, -0.053924, -0.043184, -0.075549, -0.996207, -0.925997, -0.371302, 0.068298)
wideLight.Parent = Neon
CollectionService:AddTag(wideLight, "Tool")

-- Set WideLight as Part1 of the Weld
neonWeld.Part1 = wideLight

-- SurfaceLight (child of WideLight)
local wideSurfLight = Instance.new("SurfaceLight")
wideSurfLight.Name = "SurfaceLight"
wideSurfLight.Enabled = false
wideSurfLight.Shadows = false
wideSurfLight.Color = Color3.fromRGB(255, 245, 160)
wideSurfLight.Brightness = 3
wideSurfLight.Range = 120
wideSurfLight.Angle = 55
wideSurfLight.Face = Enum.NormalId.Back
wideSurfLight.Parent = wideLight

-- === Create ScreenUI (SurfaceGui) ===
local ScreenUI = Instance.new("SurfaceGui")
ScreenUI.Name = "ScreenUI"
ScreenUI.Active = true
ScreenUI.Enabled = true
ScreenUI.Face = Enum.NormalId.Front
ScreenUI.CanvasSize = Vector2.new(800, 600)
ScreenUI.PixelsPerStud = 300
ScreenUI.Brightness = 3.4
ScreenUI.LightInfluence = 0
ScreenUI.ClipsDescendants = true
ScreenUI.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
ScreenUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenUI.AlwaysOnTop = false
ScreenUI.ZOffset = 0
ScreenUI.Parent = Screen

-- Static1 (ImageLabel)
local static1Img = Instance.new("ImageLabel")
static1Img.Name = "Static1"
static1Img.Image = "rbxassetid://8681113503"
static1Img.ImageColor3 = Color3.fromRGB(255, 242, 153)
static1Img.ImageTransparency = 0.95
static1Img.AnchorPoint = Vector2.new(0.5, 0.5)
static1Img.Size = UDim2.new(5, 0, 5, 0)
static1Img.Position = UDim2.new(0.5, 0, 0.5, 0)
static1Img.BackgroundTransparency = 1
static1Img.ScaleType = Enum.ScaleType.Tile
static1Img.TileSize = UDim2.new(0, 500, 0, 300)
static1Img.ResampleMode = Enum.ResamplerMode.Pixelated
static1Img.Visible = true
static1Img.ZIndex = 4
static1Img.Parent = ScreenUI

-- Static2 (ImageLabel)
local static2Img = Instance.new("ImageLabel")
static2Img.Name = "Static2"
static2Img.Image = "rbxassetid://8681113503"
static2Img.ImageColor3 = Color3.fromRGB(255, 242, 153)
static2Img.ImageTransparency = 0.95
static2Img.AnchorPoint = Vector2.new(0.5, 0.5)
static2Img.Size = UDim2.new(5, 0, 5, 0)
static2Img.Position = UDim2.new(0.5, 0, 0.5, 0)
static2Img.BackgroundTransparency = 1
static2Img.ScaleType = Enum.ScaleType.Tile
static2Img.TileSize = UDim2.new(0, 500, 0, 300)
static2Img.ResampleMode = Enum.ResamplerMode.Pixelated
static2Img.Visible = true
static2Img.ZIndex = 4
static2Img.Parent = ScreenUI

-- Vignette (ImageLabel)
local vignetteImg = Instance.new("ImageLabel")
vignetteImg.Name = "Vignette"
vignetteImg.Image = "rbxassetid://7464710175"
vignetteImg.ImageColor3 = Color3.fromRGB(40, 35, 12)
vignetteImg.ImageTransparency = 0.2
vignetteImg.AnchorPoint = Vector2.new(0.5, 0.5)
vignetteImg.Size = UDim2.new(1, 0, 1, 0)
vignetteImg.Position = UDim2.new(0.5, 0, 0.5, 0)
vignetteImg.BackgroundTransparency = 1
vignetteImg.ScaleType = Enum.ScaleType.Crop
vignetteImg.ResampleMode = Enum.ResamplerMode.Pixelated
vignetteImg.Visible = true
vignetteImg.ZIndex = 4
vignetteImg.Parent = ScreenUI

-- Frame (main scanner frame)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Frame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.Position = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 11, 4)
mainFrame.BackgroundTransparency = 0
mainFrame.Visible = true
mainFrame.ZIndex = -3
mainFrame.Parent = ScreenUI

-- Frame UIPadding
local framePad = Instance.new("UIPadding")
framePad.PaddingTop = UDim.new(0, 0)
framePad.PaddingBottom = UDim.new(0.03, 0)
framePad.PaddingLeft = UDim.new(0, 0)
framePad.PaddingRight = UDim.new(0, 0)
framePad.Parent = mainFrame

-- InnerFrame (child of Frame)
local innerFrame = Instance.new("Frame")
innerFrame.Name = "InnerFrame"
innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
innerFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
innerFrame.BackgroundColor3 = Color3.fromRGB(28, 25, 10)
innerFrame.BackgroundTransparency = 1
innerFrame.Visible = true
innerFrame.ZIndex = 5
innerFrame.Parent = mainFrame

-- InnerFrame UIPadding
local innerPad = Instance.new("UIPadding")
innerPad.PaddingTop = UDim.new(0.05, 0)
innerPad.PaddingBottom = UDim.new(0.05, 0)
innerPad.PaddingLeft = UDim.new(0.05, 0)
innerPad.PaddingRight = UDim.new(0.05, 0)
innerPad.Parent = innerFrame

-- InnerFrame UIStroke
local innerStroke = Instance.new("UIStroke")
innerStroke.Color = Color3.fromRGB(217, 199, 89)
innerStroke.Thickness = 0.025
innerStroke.Transparency = 0
innerStroke.Parent = innerFrame

-- ImageLabel (child of Frame)
local frameImg = Instance.new("ImageLabel")
frameImg.Name = "ImageLabel"
frameImg.Image = "rbxassetid://100718803042146"
frameImg.ImageColor3 = Color3.fromRGB(217, 199, 89)
frameImg.ImageTransparency = 0.6
frameImg.AnchorPoint = Vector2.new(0.5, 0.5)
frameImg.Size = UDim2.new(0.7, 0, 0.7, 0)
frameImg.Position = UDim2.new(0.5, 0, 0.5, 0)
frameImg.BackgroundTransparency = 1
frameImg.Visible = true
frameImg.ZIndex = 1
frameImg.Parent = mainFrame

-- ModeName (TextLabel, child of InnerFrame)
local modeName = Instance.new("TextLabel")
modeName.Name = "ModeName"
modeName.Size = UDim2.new(1, 0, 0.3, 0)
modeName.Position = UDim2.new(0, 4, 0, -4)
modeName.BackgroundColor3 = Color3.new(1, 1, 1)
modeName.BackgroundTransparency = 1
modeName.Visible = true
modeName.ZIndex = 3
modeName.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
modeName.Text = "SCANNER"
modeName.TextColor3 = Color3.fromRGB(255, 242, 153)
modeName.TextTransparency = 0
modeName.TextStrokeTransparency = 1
modeName.TextSize = 14
modeName.TextXAlignment = Enum.TextXAlignment.Right
modeName.TextWrapped = true
modeName.Parent = innerFrame

-- ModeName UIStroke
local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(255, 242, 153)
modeStroke.Thickness = 0.5
modeStroke.Transparency = 0
modeStroke.Parent = modeName

-- Battery (Frame, child of InnerFrame)
local battery = Instance.new("Frame")
battery.Name = "Battery"
battery.Size = UDim2.new(0.225, 0, 0.1, 0)
battery.Position = UDim2.new(0, 0, 0, 0)
battery.BackgroundColor3 = Color3.new(0.141176, 0.196078, 0.133333)
battery.BackgroundTransparency = 1
battery.Visible = true
battery.ZIndex = 5
battery.Parent = innerFrame

-- Battery UIStroke
local batStroke = Instance.new("UIStroke")
batStroke.Color = Color3.fromRGB(217, 199, 89)
batStroke.Thickness = 0.25
batStroke.Transparency = 0.6
batStroke.Parent = battery

-- Battery UIPadding
local batPad = Instance.new("UIPadding")
batPad.PaddingTop = UDim.new(0.05, 0)
batPad.PaddingBottom = UDim.new(0.05, 0)
batPad.PaddingLeft = UDim.new(0.05, 0)
batPad.PaddingRight = UDim.new(0.05, 0)
batPad.Parent = battery

-- Battery UIGridLayout
local batGrid = Instance.new("UIGridLayout")
batGrid.CellSize = UDim2.new(0.2025, 0, 1, 0)
batGrid.CellPadding = UDim2.new(0.06, 0, 0, 0)
batGrid.SortOrder = Enum.SortOrder.LayoutOrder
batGrid.FillDirection = Enum.FillDirection.Horizontal
batGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
batGrid.VerticalAlignment = Enum.VerticalAlignment.Top
batGrid.Parent = battery

-- Battery cells
for i = 1, 4 do
    local cell = Instance.new("Frame")
    cell.Name = "Battery" .. i
    cell.Size = UDim2.new(1, 0, 1, 0)
    cell.Position = UDim2.new(0, 0, 0, 0)
    cell.BackgroundColor3 = Color3.fromRGB(217, 199, 89)
    cell.BackgroundTransparency = 0.5
    cell.Visible = true
    cell.ZIndex = 6
    cell.Parent = battery
end

-- OffScreen (Frame, child of ScreenUI)
local offScreen = Instance.new("Frame")
offScreen.Name = "OffScreen"
offScreen.Size = UDim2.new(1, 0, 1, 0)
offScreen.Position = UDim2.new(0, 0, 0, 0)
offScreen.BackgroundColor3 = Color3.fromRGB(5, 4, 2)
offScreen.BackgroundTransparency = 0
offScreen.Visible = false
offScreen.ZIndex = 10
offScreen.Parent = ScreenUI

-- OffScreen Vignette
local offVig = Instance.new("ImageLabel")
offVig.Name = "Vignette"
offVig.Image = "rbxassetid://7464710175"
offVig.ImageColor3 = Color3.fromRGB(14, 12, 5)
offVig.ImageTransparency = 0.2
offVig.AnchorPoint = Vector2.new(0.5, 0.5)
offVig.Size = UDim2.new(1, 0, 1, 0)
offVig.Position = UDim2.new(0.5, 0, 0.5, 0)
offVig.BackgroundTransparency = 1
offVig.ScaleType = Enum.ScaleType.Crop
offVig.ResampleMode = Enum.ResamplerMode.Pixelated
offVig.Visible = true
offVig.ZIndex = 25
offVig.Parent = offScreen

-- OffScreen Static2
local offStatic2 = Instance.new("ImageLabel")
offStatic2.Name = "Static2"
offStatic2.Image = "rbxassetid://8681113503"
offStatic2.ImageColor3 = Color3.fromRGB(40, 36, 14)
offStatic2.ImageTransparency = 0.97
offStatic2.AnchorPoint = Vector2.new(0.5, 0.5)
offStatic2.Size = UDim2.new(5, 0, 5, 0)
offStatic2.Position = UDim2.new(0.5, 0, 0.5, 0)
offStatic2.BackgroundTransparency = 1
offStatic2.ScaleType = Enum.ScaleType.Tile
offStatic2.TileSize = UDim2.new(0, 500, 0, 500)
offStatic2.Visible = true
offStatic2.ZIndex = 15
offStatic2.Parent = offScreen

-- OffScreen OffFrame
local offFrame = Instance.new("Frame")
offFrame.Name = "OffFrame"
offFrame.AnchorPoint = Vector2.new(0.5, 0.5)
offFrame.Size = UDim2.new(1, 0, 1, 0)
offFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
offFrame.BackgroundColor3 = Color3.fromRGB(245, 230, 140)
offFrame.BackgroundTransparency = 0
offFrame.BorderSizePixel = 0
offFrame.Visible = true
offFrame.ZIndex = 20
offFrame.Parent = offScreen

-- OffScreen OffStatic
local offStatic = Instance.new("ImageLabel")
offStatic.Name = "OffStatic"
offStatic.Image = "rbxassetid://8681113503"
offStatic.ImageColor3 = Color3.fromRGB(40, 36, 14)
offStatic.ImageTransparency = 0.97
offStatic.AnchorPoint = Vector2.new(0.5, 0.5)
offStatic.Size = UDim2.new(5, 0, 5, 0)
offStatic.Position = UDim2.new(0.5, 0, 0.5, 0)
offStatic.BackgroundTransparency = 1
offStatic.ScaleType = Enum.ScaleType.Tile
offStatic.TileSize = UDim2.new(0, 500, 0, 500)
offStatic.Visible = true
offStatic.ZIndex = 15
offStatic.Parent = offScreen

-- === Create Ping and Found sounds (children of LocalScript) ===
makeSound("Ping", "rbxassetid://121990188670142", script, {volume = 0.4, minDist = 10, maxDist = 70, playbackSpeed = 1})
makeSound("Found", "rbxassetid://88963994815565", script, {volume = 0.4, minDist = 10, maxDist = 70})

-- === Create TranslatorDialog RemoteEvent (locally) ===
local remotesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("RemotesFolder")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "RemotesFolder"
    remotesFolder.Parent = game:GetService("ReplicatedStorage")
end
local translatorDialog = remotesFolder:FindFirstChild("TranslatorDialog")
if not translatorDialog then
    translatorDialog = Instance.new("RemoteEvent")
    translatorDialog.Name = "TranslatorDialog"
    translatorDialog.Parent = remotesFolder
end

-- ============================================================
-- === Set default attributes for auto-open ===
Parent:SetAttribute("ScannerMode", "Base")
Parent:SetAttribute("Durability", 4)
Parent:SetAttribute("DurabilityMax", 4)
Parent:SetAttribute("_ServerAnimated", false)
Parent:SetAttribute("ToolOffset", Vector3.new(0, 0.1, -0.3))
Parent:SetAttribute("StarCharge", 100)

-- ============================================================
-- === MODE DEFINITIONS (inlined, no ModuleScripts) ===
-- ============================================================

local MODES = {}

-- === Base Mode ===
MODES.Base = {
    Name = "Base",
    Label = "SCANNER",
    BootImage = "rbxassetid://100718803042146",
    BoxArt = "rbxassetid://100718803042146",
    Drain = 1,
    PulseInterval = 2.5,
    PulseRange = 60,
    RevealTime = 2,
    Color = Color3.fromRGB(255, 230, 120),
    Tags = {
        SalvageDrop = "star",
        RBS = "star",
        ScannerBox = "box"
    }
}

-- === Translator Mode ===
local trRand = Random.new()
local trGlyphs = "abcdefghijklmnopqrstuvwxyz0123456789#%&?!"

local function trCreateScreen()
    local scr = Instance.new("Frame")
    scr.Name = "Screen"
    scr.Size = UDim2.new(1, 0, 1, 0)
    scr.Position = UDim2.new(0, 0, 0, 0)
    scr.BackgroundTransparency = 1

    local speaker = Instance.new("TextLabel")
    speaker.Name = "Speaker"
    speaker.Size = UDim2.new(0.6, 0, 0.06, 0)
    speaker.Position = UDim2.new(0.05, 0, 0.475, 0)
    speaker.AnchorPoint = Vector2.new(0, 1)
    speaker.BackgroundTransparency = 1
    speaker.ZIndex = 3
    speaker.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
    speaker.Text = "COBBLER"
    speaker.TextColor3 = Color3.fromRGB(150, 140, 255)
    speaker.TextTransparency = 0
    speaker.TextStrokeTransparency = 1
    speaker.TextSize = 14
    speaker.TextWrapped = true
    speaker.TextXAlignment = Enum.TextXAlignment.Left
    speaker.TextYAlignment = Enum.TextYAlignment.Bottom
    speaker.RichText = true
    speaker.Parent = scr

    local spStroke = Instance.new("UIStroke")
    spStroke.Color = Color3.fromRGB(150, 140, 255)
    spStroke.Thickness = 1
    spStroke.Transparency = 0
    spStroke.Parent = speaker

    local dialog = Instance.new("TextLabel")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0.9, 0, 0.2, 0)
    dialog.Position = UDim2.new(0.05, 0, 0.48, 0)
    dialog.BackgroundTransparency = 1
    dialog.ZIndex = 3
    dialog.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
    dialog.Text = "COBBLER"
    dialog.TextColor3 = Color3.fromRGB(150, 140, 255)
    dialog.TextTransparency = 0
    dialog.TextStrokeTransparency = 1
    dialog.TextSize = 16
    dialog.TextWrapped = true
    dialog.TextXAlignment = Enum.TextXAlignment.Left
    dialog.TextYAlignment = Enum.TextYAlignment.Top
    dialog.Parent = scr

    local dlgStroke = Instance.new("UIStroke")
    dlgStroke.Color = Color3.fromRGB(150, 140, 255)
    dlgStroke.Thickness = 0.5
    dlgStroke.Transparency = 0.5
    dlgStroke.Parent = dialog

    return scr
end

local function trDecode(ctx, label, text, speed, session)
    local chars = {}
    local revealed = {}
    local glitched = {}
    local len = #text
    for i = 1, len do
        chars[i] = string.sub(text, i, i)
    end
    for i, ch in ipairs(chars) do
        if ctx.session == session then
            if ch == " " then
                revealed[i] = " "
            else
                local n = trRand:NextInteger(2, 5)
                for _ = 1, n do
                    local idx = trRand:NextInteger(1, 41)
                    local glyph = string.sub(trGlyphs, idx, idx)
                    label.Text = table.concat(revealed) .. (glyph or "")
                    task.wait(speed)
                    if ctx.session ~= session then return end
                end
                if trRand:NextNumber() < 0.15 then
                    local idx = trRand:NextInteger(1, 41)
                    revealed[i] = string.sub(trGlyphs, idx, idx)
                    table.insert(glitched, i)
                else
                    revealed[i] = ch
                end
            end
            label.Text = table.concat(revealed) .. ""
        else
            return
        end
    end
    for _, pos in ipairs(glitched) do
        task.wait(speed * 4)
        local n = trRand:NextInteger(2, 4)
        for _ = 1, n do
            if ctx.session ~= session then return end
            local idx = trRand:NextInteger(1, 41)
            revealed[pos] = string.sub(trGlyphs, idx, idx)
            label.Text = table.concat(revealed) .. ""
            task.wait(speed)
        end
        revealed[pos] = chars[pos]
        label.Text = table.concat(revealed) .. ""
    end
end

local function trReset(ui)
    for _, lbl in ipairs({ui.Speaker, ui.Dialog}) do
        lbl.Text = ""
        lbl.TextTransparency = 0
        local stk = lbl:FindFirstChildWhichIsA("UIStroke")
        if stk then stk.Transparency = 0 end
    end
end

local function trWaiting(ctx, session)
    trReset(ctx.ui)
    ctx.ui.Speaker.TextColor3 = ctx.color
    local dots = 0
    while ctx.session == session do
        ctx.ui.Speaker.Text = "WAITING" .. string.rep(".", dots)
        dots = (dots + 1) % 4
        task.wait(0.4)
    end
end

local function trFade(ctx, session)
    task.wait(30)
    if ctx.session ~= session then return end
    for _, lbl in ipairs({ctx.ui.Speaker, ctx.ui.Dialog}) do
        TweenService:Create(lbl, TweenInfo.new(3), { TextTransparency = 1 }):Play()
        local stk = lbl:FindFirstChildWhichIsA("UIStroke")
        if stk then
            TweenService:Create(stk, TweenInfo.new(3), { Transparency = 1 }):Play()
        end
    end
    task.wait(3)
    if ctx.session == session then
        ctx.session += 1
        task.spawn(trWaiting, ctx, ctx.session)
    end
end

MODES.Translator = {
    Name = "Translator",
    Label = "TRANSLATOR",
    BootImage = "rbxassetid://129244684951811",
    BoxArt = "rbxassetid://129244684951811",
    Pulses = false,
    Drain = 2,
    PulseInterval = 3,
    PulseRange = 40,
    RevealTime = 1,
    Color = Color3.fromRGB(230, 200, 90),
    Tags = {},
    CreateScreen = trCreateScreen,
    OnEnter = function(ctx)
        local ui = ctx.ui
        if not ui then return end
        ui.Speaker.TextColor3 = ctx.color
        ui.Dialog.TextColor3 = ctx.color
        ctx.session = 0
        task.spawn(trWaiting, ctx, 0)
        ctx.translate = translatorDialog.OnClientEvent:Connect(function(_, dialogText, _, speakerText)
            ctx.session += 1
            local session = ctx.session
            ctx.flash()
            trReset(ui)
            task.spawn(trDecode, ctx, ui.Speaker, string.upper(speakerText or ""), 0.02, session)
            task.spawn(function()
                task.wait(0.15)
                trDecode(ctx, ui.Dialog, dialogText, 0.035, session)
                trFade(ctx, session)
            end)
        end)
    end,
    OnExit = function(ctx)
        if ctx.translate then
            ctx.translate:Disconnect()
            ctx.translate = nil
        end
        ctx.session = (ctx.session or 0) + 1
        if ctx.ui then
            trReset(ctx.ui)
        end
    end
}

-- ============================================================
-- === SCANNER LOGIC ===
-- ============================================================

local CurrentCamera = workspace.CurrentCamera
local v3, Frame, ImageLabel, InnerFrame, ModeName, Battery, OffScreen, OffFrame, Static1, v4, OffStatic, v5, v6, Part
local v7 = {}
local v8 = {}
local v9 = {}
local v10
local v11 = {}
local v12 = ""
local v13, v14, v15
local v16 = 0
local v17 = -10
local v18 = 0
local v19 = 0
local v20 = 0
local v21 = -10
local v22 = -10
local v23 = false
local v24 = -10
local v25 = 0
local v26 = {}

-- Inspect state (from *ToolClientFunctions)
local inspectActive = false
local inspectTrack
local inspectCtx

local function WaitForDescendants(v27, v28, v29) -- line 53
    local v30 = {}
    local v31 = {}
    local v32 = 0
    local v33 = 0
    for v34, v35 in v28 do
        if not v31[v35] then
            v31[v35] = true
            v33 += 1
            v32 = v33
        end
    end

    local function tryResolve(v36) -- line 58 | captures: v32, v27, v30, v31
        if v31[v36] then
            local v37 = v27:FindFirstChild(v36, true)
            if v37 then
                v30[v36] = v37
                v31[v36] = nil
                v32 -= 1
            end
        end
    end

    local v38 = coroutine.running()
    local v39 = false
    local v40 = false
    local v41, v42

    local function finish() -- line 65 | captures: v39, v40, v41, v42, v38
        if v40 then
            return
        end
        v40 = true
        v41:Disconnect()
        if v42 and coroutine.status(v42) == "suspended" then
            task.cancel(v42)
        end
        if v39 then
            task.spawn(v38)
        end
    end

    v41 = v27.DescendantAdded:Connect(function(v43) -- line 72 | captures: v32, v27, v30, v31, finish
        if not v31[v43.Name] then
            return
        end
        local Name = v43.Name
        if v31[Name] then
            local v44 = v27:FindFirstChild(Name, true)
            if v44 then
                v30[Name] = v44
                v31[Name] = nil
                v32 -= 1
            end
        end
        if v32 == 0 then
            finish()
        end
    end)
    for v45 in v31 do
        if v31[v45] then
            local v46 = v27:FindFirstChild(v45, true)
            if v46 then
                v30[v45] = v46
                v31[v45] = nil
                v32 -= 1
            end
        end
    end
    if v32 == 0 then
        finish()
    else
        if v29 then
            v42 = task.delay(v29, finish)
        end
        v39 = true
        coroutine.yield()
    end
    if v32 > 0 then
        local v47 = {}
        for v48 in v31 do
            table.insert(v47, v48)
        end
        return nil, v47
    end
    return v30
end

local function PlayOneShot(v49, v50) -- line 89
    local v51 = v49:Clone()
    v51.PlaybackSpeed = v50 or 1
    v51.Parent = script
    v51:Play()
    v51.Ended:Once(function() -- line 94 | captures: v51
        v51:Destroy()
    end)
end

local function PlayFound(v52) -- line 98 | captures: v24, v25
    local v53 = os.clock()
    if v53 - v24 > 0.6 then
        v24 = v53
        v25 = 0
    end
    if v25 >= 3 then
        return
    end
    v25 += 1
    local v54 = script.Found:Clone()
    v54.PlaybackSpeed = v52 or 1
    v54.Parent = script
    v54:Play()
    v54.Ended:Once(function() -- line 94 | captures: v54
        v54:Destroy()
    end)
end

local function PlayAnim(v55) -- line 109 | captures: v11
    local v56 = v11[v55]
    if v56 then
        v56:Play(0.05, 1, 1)
    end
end

local function Pivot(v57) -- line 114
    if v57:IsA("Model") then
        return v57:GetBoundingBox()
    end
    return v57.CFrame, v57.Size
end

local function Tween(v58, v59, v60, v61, v62) -- line 119 | captures: TweenService
    TweenService:Create(v58, TweenInfo.new(v59, v61 or Enum.EasingStyle.Quad, v62 or Enum.EasingDirection.Out), v60):Play()
end

local function Dark(v63, v64) -- line 123
    local v65, v66, v67 = v63:ToHSV()
    return Color3.fromHSV(v65, v66, v67 * v64)
end

local function EachTag(v68) -- line 129 | captures: v13
    for v69, v70 in v13.Tags or {} do
        if type(v69) == "number" then
            v68(v70, "star")
        else
            v68(v69, v70)
        end
    end
end

local function NewPart(v71) -- line 135
    local Part = Instance.new("Part")
    Part.Anchored = true
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CastShadow = false
    Part.Parent = v71
    return Part
end

local function Ignored(v72, v73) -- line 146
    local v74 = v72
    while true do
        if v74 then
            if v74 == v73.Parent then
                return false
            end
            if v74:GetAttribute("ScannerIgnore") then
                break
            end
            v74 = v74.Parent
            continue
        end
        return false
    end
    return true
end

local function BindUI() -- line 156 | captures: v3, Frame, ImageLabel, InnerFrame, ModeName, Battery, OffScreen, OffFrame, Static1, v4, OffStatic, LocalPlayer, Handle, ScreenUI, WaitForDescendants
    local v75, v76 = WaitForDescendants(ScreenUI, {
        "Frame",
        "ImageLabel",
        "InnerFrame",
        "ModeName",
        "Battery",
        "OffScreen",
        "OffFrame",
        "Static1",
        "OffStatic"
    }, 10)
    if v76 then
        warn("scanner ui missing", v76)
    else
        v3 = ScreenUI:Clone()
        v3.Name = "ScannerScreen"
        v3.Adornee = Handle.Top.Screen
        v3.Parent = LocalPlayer.PlayerGui
        Frame = v3.Frame
        ImageLabel = Frame.ImageLabel
        InnerFrame = Frame.InnerFrame
        ModeName = InnerFrame.ModeName
        Battery = InnerFrame.Battery
        OffScreen = v3.OffScreen
        OffFrame = OffScreen.OffFrame
        Static1 = v3.Static1
        v4 = v3:FindFirstChild("Static2")
        OffStatic = OffScreen.OffStatic
        ScreenUI.Enabled = false
    end
end

local function UnbindUI() -- line 176 | captures: v3, v5, v6, Part, ScreenUI
    if v3 then
        v3:Destroy()
        v3 = nil
    end
    ScreenUI.Enabled = true
    v5 = nil
    v6 = nil
    Part = nil
end

local function EnsureViewport() -- line 182 | captures: ImageLabel, InnerFrame, v5, v6, Part
    if v5 then
        return
    end
    v5 = Instance.new("ViewportFrame")
    v5.Name = "Scan"
    v5.Size = UDim2.fromScale(1, 1)
    v5.BackgroundTransparency = 1
    v5.Ambient = Color3.new(1, 1, 1)
    v5.LightColor = Color3.new(1, 1, 1)
    v5.ZIndex = ImageLabel.ZIndex + 1
    v6 = Instance.new("Camera")
    v6.Parent = v5
    v5.CurrentCamera = v6
    v5.Parent = InnerFrame
    local v77 = v5
    local Part_2 = Instance.new("Part")
    Part_2.Anchored = true
    Part_2.CanCollide = false
    Part_2.CanQuery = false
    Part_2.CastShadow = false
    Part_2.Parent = v77
    Part = Part_2
    Part.Shape = Enum.PartType.Cylinder
    Part.Material = Enum.Material.Neon
    Part.Transparency = 1
end

local function SetGhostAlpha(v78, v79) -- line 203
    if v78.style == "icon" then
        for v80, v81 in v78.part:GetChildren() do
            if v81:IsA("Decal") then
                v81.Transparency = v79
            end
        end
    elseif v78.style == "box" then
        v78.part.Transparency = 0.1 + 0.3 * v79
    else
        v78.part.Transparency = v79
        for v82, v83 in v78.part:GetDescendants() do
            if v83:IsA("Decal") or v83:IsA("Texture") then
                v83.Transparency = v79
            end
        end
    end
end

local function NewGhost(v84, v85) -- line 218 | captures: v5, v7, v13, SetGhostAlpha
    local ScannerIcon = v84:GetAttribute("ScannerIcon")
    local v86 = if ScannerIcon then "icon" else v85
    local Part
    if v86 == "box" then
        local v87 = v5
        Part = Instance.new("Part")
        Part.Anchored = true
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CastShadow = false
        Part.Parent = v87
        Part.Material = Enum.Material.ForceField
        Part.Color = v13.Color
    elseif v86 == "icon" then
        local v88 = v5
        Part = Instance.new("Part")
        Part.Anchored = true
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CastShadow = false
        Part.Parent = v88
        Part.Size = Vector3.new(2.5, 2.5, 0.05000000074505806)
        Part.Transparency = 1
        for v89, v90 in {
                Enum.NormalId.Front,
                Enum.NormalId.Back
            } do
            local Decal = Instance.new("Decal")
            Decal.Face = v90
            Decal.Texture = ScannerIcon
            Decal.Color3 = v13.Color
            Decal.Parent = Part
        end
    end
    local v91 = {
        born = (1/0),
        order = 1,
        found = true,
        part = Part,
        style = v86,
        seed = math.random() * 50,
        baseSize = Part.Size
    }
    SetGhostAlpha(v91, 1)
    v7[v84] = v91
    return v91
end

local function ClearGhosts() -- line 254 | captures: v7
    for v92, v93 in v7 do
        v93.part:Destroy()
    end
    v7 = {}
end

local function NewThreat(v94) -- line 260 | captures: v5, v8, v2, Ignored
    local Model = Instance.new("Model")
    Model.Name = "Threat"
    local v95 = {}
    local v96 = v94:GetDescendants()
    if v94:IsA("BasePart") then
        table.insert(v96, v94)
    end
    for v97, v98 in v96 do
        if v98:IsA("BasePart") and not (v98.Transparency > 0.95) and not Ignored(v98, v94) then
            local v99 = v98:Clone()
            for v100, v101 in v99:GetChildren() do
                if v101:IsA("SpecialMesh") then
                    v101.TextureId = ""
                    v101.VertexColor = Vector3.new(0, 0, 0)
                else
                    v101:Destroy()
                end
            end
            v99.Anchored = true
            v99.CanCollide = false
            v99.CanQuery = false
            v99.CastShadow = false
            v99.Color = v2
            v99.Material = Enum.Material.SmoothPlastic
            v99.Reflectance = 0
            v99.Transparency = 1
            if v99:IsA("MeshPart") then
                pcall(function() v99.TextureID = "" end)
            end
            v99.Parent = Model
            local v102 = { v98, v99 }
            table.insert(v95, v102)
        end
    end
    if #v95 == 0 then
        local v103
        if v94:IsA("Model") then
            local v104
            v104, v103 = v94:GetBoundingBox()
        else
            local CFrame = v94.CFrame
            v103 = v94.Size
        end
        local ScannerSphere = v94:GetAttribute("ScannerSphere")
        if not ScannerSphere then
            local X = v103.X
            local Y = v103.Y
            local Z = v103.Z
            local v105 = math.max(X, Y, Z)
            ScannerSphere = math.clamp(v105, 2, 8)
        end
        local Part = Instance.new("Part")
        Part.Anchored = true
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CastShadow = false
        Part.Parent = Model
        Part.Shape = Enum.PartType.Ball
        Part.Size = Vector3.new(ScannerSphere, ScannerSphere, ScannerSphere)
        Part.Color = v2
        Part.Material = Enum.Material.SmoothPlastic
        Part.Transparency = 1
        local v106 = { v94, Part, true }
        table.insert(v95, v106)
    end
    local v107 = {}
    for v108 = 1, 5 do
        local Part = Instance.new("Part")
        Part.Anchored = true
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CastShadow = false
        Part.Parent = Model
        Part.Color = v2
        Part.Material = Enum.Material.SmoothPlastic
        Part.Transparency = 1
        table.insert(v107, Part)
    end
    Model.Parent = v5
    local v109 = {
        alpha = 1,
        model = Model,
        pairs = v95,
        glitch = v107
    }
    v8[v94] = v109
    return v109
end

local function ClearThreats() -- line 316 | captures: v8
    for v110, v111 in v8 do
        v111.model:Destroy()
    end
    v8 = {}
end

local function SetThreatAlpha(v112, v113) -- line 321
    v112.alpha = v113
    for v114, v115 in v112.pairs do
        v115[2].Transparency = v113
    end
end

local function StepThreats(v116, v117) -- line 327 | captures: v6, v8, v13, v18, v20, v24, v25, CollectionService, EachTag, NewThreat
    if v116 - v20 < 0.08333333333333333 then
        return false
    end
    local v118 = v116 - v20
    v20 = v116
    local Rotation = v6.CFrame.Rotation
    EachTag(function(v119, v120) -- line 335 | captures: v117, v8, v13, v18, v24, v25, CollectionService, NewThreat
        if v120 == "threat" then
            for v121, v122 in CollectionService:GetTagged(v119) do
                if not v8[v122] and v122:IsDescendantOf(workspace) then
                    local v123
                    if v122:IsA("Model") then
                        v123 = v122:GetBoundingBox()
                    else
                        v123 = v122.CFrame
                        local Size = v122.Size
                    end
                    if (v123.Position - v117.Position).Magnitude <= v13.PulseRange then
                        NewThreat(v122)
                        local v124 = os.clock()
                        if v124 - v24 > 0.6 then
                            v24 = v124
                            v25 = 0
                        end
                        if not (v25 >= 3) then
                            v25 += 1
                            local v125 = script.Found:Clone()
                            v125.PlaybackSpeed = 0.7
                            v125.Parent = script
                            v125:Play()
                            v125.Ended:Once(function() -- line 94 | captures: v125
                                v125:Destroy()
                            end)
                        end
                        v18 = 1
                    end
                end
            end
        end
    end)
    local v126 = false
    for v127, v128 in v8 do
        local v129 = v127.Parent ~= nil
        if v129 then
            local v130
            if v127:IsA("Model") then
                v130 = v127:GetBoundingBox()
            else
                v130 = v127.CFrame
                local Size = v127.Size
            end
            v129 = (v130.Position - v117.Position).Magnitude <= v13.PulseRange
        end
        local v131 = if v129 then 0 else 1
        local alpha = v128.alpha
        local v132 = v131 - v128.alpha
        local v133 = alpha + math.sign(v132) * v118 / v13.RevealTime
        local v134 = math.clamp(v133, 0, 1)
        if v134 ~= v128.alpha then
            v128.alpha = v134
            for v135, v136 in v128.pairs do
                v136[2].Transparency = v134
            end
        end
        if v134 >= 1 then
            if v129 then
                for v137, v138 in v128.pairs do
                    if v138[1].Parent then
                        local v139 = v138[2]
                        if v138[3] then
                            local v140 = v138[1]
                            local v141
                            if v140:IsA("Model") then
                                v141 = v140:GetBoundingBox()
                            else
                                v141 = v140.CFrame
                                local Size = v140.Size
                            end
                            v139.CFrame = v141 or v138[1].CFrame
                        else
                            v139.CFrame = v138[1].CFrame
                        end
                    end
                end
                v126 = true
                for v142, v143 in v128.glitch do
                    local pairs = v128.pairs
                    local random = math.random
                    local v144 = #v128.pairs
                    local v145 = pairs[random(1, (math.max(v144, 1)))]
                    if v145 and math.random() < 0.5 then
                        local Position
                        if v145[3] then
                            local v146 = v145[1]
                            local v147
                            if v146:IsA("Model") then
                                v147 = v146:GetBoundingBox()
                            else
                                v147 = v146.CFrame
                                local Size = v146.Size
                            end
                            Position = v147.Position or v145[1].Position
                        else
                            Position = v145[1].Position
                        end
                        local v148 = math.random(20, 60) / 10
                        local v149 = math.random(2, 6) / 10
                        v143.Size = Vector3.new(v148, v149, 0.1)
                        local v150 = Rotation + Position
                        local v151 = (math.random() - 0.5) * 2
                        local v152 = (math.random() - 0.5) * 2
                        v143.CFrame = v150 + Vector3.new(v151, v152, 0)
                        v143.Transparency = v134
                    else
                        v143.Transparency = 1
                    end
                    v126 = true
                end
            else
                v128.model:Destroy()
                v8[v127] = nil
            end
        else
            for v153, v154 in v128.pairs do
                if v154[1].Parent then
                    local v155 = v154[2]
                    if v154[3] then
                        local v156 = v154[1]
                        local v157
                        if v156:IsA("Model") then
                            v157 = v156:GetBoundingBox()
                        else
                            v157 = v156.CFrame
                            local Size = v156.Size
                        end
                        v155.CFrame = v157 or v154[1].CFrame
                    else
                        v155.CFrame = v154[1].CFrame
                    end
                end
            end
            v126 = true
            for v158, v159 in v128.glitch do
                local pairs = v128.pairs
                local random = math.random
                local v160 = #v128.pairs
                local v161 = pairs[random(1, (math.max(v160, 1)))]
                if v161 and math.random() < 0.5 then
                    local Position
                    if v161[3] then
                        local v162 = v161[1]
                        local v163
                        if v162:IsA("Model") then
                            v163 = v162:GetBoundingBox()
                        else
                            v163 = v162.CFrame
                            local Size = v162.Size
                        end
                        Position = v163.Position or v161[1].Position
                    else
                        Position = v161[1].Position
                    end
                    local v164 = math.random(20, 60) / 10
                    local v165 = math.random(2, 6) / 10
                    v159.Size = Vector3.new(v164, v165, 0.1)
                    local v166 = Rotation + Position
                    local v167 = (math.random() - 0.5) * 2
                    local v168 = (math.random() - 0.5) * 2
                    v159.CFrame = v166 + Vector3.new(v167, v168, 0)
                    v159.Transparency = v134
                else
                    v159.Transparency = 1
                end
                v126 = true
            end
        end
    end
    return v126
end

local function ApplyColor(v169) -- line 383 | captures: v3, Frame, ImageLabel, InnerFrame, ModeName, Battery, OffScreen, OffFrame, Static1, v4, OffStatic, v5, Part, v7, v13
    local Frame_2 = Frame
    local v170 = v13.FrameDark or 0.08
    local v171, v172, v173 = v169:ToHSV()
    Frame_2.BackgroundColor3 = Color3.fromHSV(v171, v172, v173 * v170)
    local InnerFrame_2 = InnerFrame
    local v174 = v13.InnerDark or 0.14
    local v175, v176, v177 = v169:ToHSV()
    InnerFrame_2.BackgroundColor3 = Color3.fromHSV(v175, v176, v177 * v174)
    local Vignette = v3.Vignette
    local v178, v179, v180 = v169:ToHSV()
    Vignette.ImageColor3 = Color3.fromHSV(v178, v179, v180 * 0.25)
    local Vignette_2 = OffScreen.Vignette
    local v181, v182, v183 = v169:ToHSV()
    Vignette_2.ImageColor3 = Color3.fromHSV(v181, v182, v183 * 0.15)
    InnerFrame.UIStroke.Color = v169
    ImageLabel.ImageColor3 = v169
    ModeName.TextColor3 = v169
    local UIStroke = ModeName:FindFirstChildWhichIsA("UIStroke")
    if UIStroke then
        local v184, v185, v186 = v169:ToHSV()
        UIStroke.Color = Color3.fromHSV(v184, v185, v186 * 0.3)
    end
    Static1.ImageColor3 = v169
    if v4 then
        v4.ImageColor3 = v169
    end
    v5.ImageColor3 = v169
    Battery.UIStroke.Color = v169
    for v187, v188 in Battery:GetChildren() do
        if v188:IsA("GuiObject") then
            v188.BackgroundColor3 = v169
            local UIStroke = v188:FindFirstChildWhichIsA("UIStroke")
            if UIStroke then
                UIStroke.Color = v169
            end
        end
    end
    Part.Color = v169
    for v189, v190 in v7 do
        if v190.style == "icon" then
            for v191, v192 in v190.part:GetChildren() do
                if v192:IsA("Decal") then
                    v192.Color3 = v169
                end
            end
        else
            v190.part.Color = v169
        end
    end
    local OffScreen_2 = OffScreen
    local v193, v194, v195 = v169:ToHSV()
    OffScreen_2.BackgroundColor3 = Color3.fromHSV(v193, v194, v195 * 0.05)
    local OffFrame_2 = OffFrame
    local v196, v197, v198 = v169:ToHSV()
    OffFrame_2.BackgroundColor3 = Color3.fromHSV(v196, v197, v198 * 0.35)
    OffStatic.ImageColor3 = v169
end

local function RefreshBattery() -- line 417 | captures: Battery, Parent
    local v199 = Parent:GetAttribute("Durability") or 0
    local v200 = Parent:GetAttribute("DurabilityMax") or 1
    local v201 = {}
    for v202, v203 in Battery:GetChildren() do
        if v203:IsA("GuiObject") then
            table.insert(v201, v203)
        end
    end
    local v204 = v199 / v200 * #v201
    local v205 = math.ceil(v204)
    for v206, v207 in v201 do
        v207.Visible = v206 <= v205
    end
end

local function Pulse() -- line 428 | captures: v7, v13, v15, v17, v18, CollectionService, LocalPlayer, v11, EachTag, NewGhost
    local Character = LocalPlayer.Character
    local v208 = Character and Character.PrimaryPart
    if v208 and v13 then
        local pulse = v11.pulse
        if pulse then
            pulse:Play(0.05, 1, 1)
        end
    else
        return
    end
    local v209 = script.Ping:Clone()
    v209.PlaybackSpeed = 1
    v209.Parent = script
    v209:Play()
    v209.Ended:Once(function() -- line 94 | captures: v209
        v209:Destroy()
    end)
    v18 = 1
    v17 = os.clock()
    local v210 = {}
    EachTag(function(v211, v212) -- line 439 | captures: v208, v210, v13, CollectionService
        if v212 ~= "threat" then
            for v213, v214 in CollectionService:GetTagged(v211) do
                if v214:IsDescendantOf(workspace) then
                    if v13.Filter then
                        if v13.Filter(v214) then
                            local v215
                            if v214:IsA("Model") then
                                v215 = v214:GetBoundingBox()
                            else
                                v215 = v214.CFrame
                                local Size = v214.Size
                            end
                            local Magnitude = (v215.Position - v208.Position).Magnitude
                            if Magnitude <= v13.PulseRange then
                                local v216 = {
                                    inst = v214,
                                    dist = Magnitude,
                                    style = v212
                                }
                                table.insert(v210, v216)
                            end
                        end
                    else
                        local v217
                        if v214:IsA("Model") then
                            v217 = v214:GetBoundingBox()
                        else
                            v217 = v214.CFrame
                            local Size = v214.Size
                        end
                        local Magnitude = (v217.Position - v208.Position).Magnitude
                        if Magnitude <= v13.PulseRange then
                            local v218 = {
                                inst = v214,
                                dist = Magnitude,
                                style = v212
                            }
                            table.insert(v210, v218)
                        end
                    end
                end
            end
        end
    end)
    table.sort(v210, function(v219, v220) -- line 452
        return v219.dist < v220.dist
    end)
    local v221 = {}
    for v222, v223 in v210 do
        local v224 = v7[v223.inst] or NewGhost(v223.inst, v223.style)
        v224.born = os.clock() + v223.dist / v13.PulseRange * 0.6
        v224.order = v222
        v224.found = false
        local inst = v223.inst
        table.insert(v221, inst)
    end
    if v13.OnPulse then
        v13.OnPulse(v15, v221)
    end
end

local function AnimateStatic(v225) -- line 465 | captures: Static1, v4, OffStatic, v18, v19, v21, v1
    if v225 - v19 < 0.033444816053511704 then
        return
    end
    v19 = v225
    local v226 = (v225 - v21) / 1.5
    local v227 = math.clamp(v226, 0, 1)
    local v228 = {}
    v228[Static1] = v227 * 0.85
    v228[v4] = 0.975
    v228[OffStatic] = 0.6
    for v229, v230 in v228 do
        v229.Position = UDim2.new(0.5, math.random(-28, 28) * 6, 0.5, math.random(-18, 18) * 6)
        v229.Image = v1[math.random(1, 2)]
        local v231 = v230 - v18 * 0.55
        v229.ImageTransparency = math.clamp(v231, 0, 1)
    end
end

local function Step(v232) -- line 476 | captures: v5, v6, Part, v7, v13, v16, v17, v18, v22, v23, v24, v25, Parent, LocalPlayer, Handle, CurrentCamera, SetGhostAlpha, StepThreats, Pulse, AnimateStatic
    local v233 = os.clock()
    local v234 = v18 - v232 * 2.5
    v18 = math.max(v234, 0)
    AnimateStatic(v233)
    local v235, v236
    if v5 then
        if v23 then
            v236 = true
        elseif v13 then
            local v237 = (v233 - v22) / 0.8
            local v238 = 1 - (1 - math.clamp(v237, 0, 1)) ^ 3
            v6.CFrame = CurrentCamera.CFrame
            v6.FieldOfView = (1 + (CurrentCamera.FieldOfView - 1) * v238) * (v13.FOVScale or 1)
            local Character = LocalPlayer.Character
            v235 = Character and Character.PrimaryPart
            v236 = false
        else
            v236 = true
        end
    else
        v236 = true
    end
    if v236 then
        return
    end
    local Durability = Parent:GetAttribute("Durability")
    local v239 = if Durability == nil then true else Durability > 0
    if v239 and v13.Pulses ~= false and v16 <= v233 then
        v16 = v233 + v13.PulseInterval
        Pulse()
    end
    local v240 = (v233 - v17) / 0.8
    if not (v235 and v240 < 1) then
        Part.Transparency = 1
    else
        local v241 = v13.PulseRange * 2 * v240
        Part.Size = Vector3.new(0.15, v241, v241)
        Part.CFrame = CFrame.new(v235.Position - Vector3.new(0, 2.799999952316284, 0)) * CFrame.Angles(0, 0, 1.5707963267948966)
        Part.Transparency = 0.4 + 0.6 * v240
    end
    local Rotation = v6.CFrame.Rotation
    local v242 = false
    for v243, v244 in v7 do
        if v243.Parent then
            local v245, v246
            if v243:IsA("Model") then
                v245, v246 = v243:GetBoundingBox()
            else
                v245, v246 = v243.CFrame, v243.Size
            end
            if v244.style == "box" then
                v244.part.CFrame = v245
                v244.part.Size = v246
            else
                local v247
                local Magnitude = (v247 - v6.CFrame.Position).Magnitude
                v244.part.CFrame = Rotation + v247
                v244.part.Size = v244.baseSize * (1 + Magnitude / v13.PulseRange * 0.6)
            end
            local v249 = v233 - v244.born
            if v249 >= 0 and not v244.found then
                v244.found = true
                local v250 = 1 + (v244.order - 1) * 0.08
                local v251 = os.clock()
                if v251 - v24 > 0.6 then
                    v24 = v251
                    v25 = 0
                end
                if not (v25 >= 3) then
                    v25 += 1
                    local v252 = script.Found:Clone()
                    v252.PlaybackSpeed = v250 or 1
                    v252.Parent = script
                    v252:Play()
                    v252.Ended:Once(function() -- line 94 | captures: v252
                        v252:Destroy()
                    end)
                end
            end
            local v253
            if v249 < 0 then
                v253 = 0
            elseif v249 < 0.15 then
                v253 = v249 / 0.15
                if not v253 then
                    local v254 = 1 - (v249 - 0.15) / v13.RevealTime
                    v253 = math.clamp(v254, 0, 1)
                end
            else
                local v255 = 1 - (v249 - 0.15) / v13.RevealTime
                v253 = math.clamp(v255, 0, 1)
            end
            local v256 = v253 * (1 + math.noise(v233 * 12, v244.seed) * 0.35)
            SetGhostAlpha(v244, 1 - math.clamp(v256, 0, 1) * 0.7)
            if v256 > 0.05 then
                v242 = true
            end
            if v13.RevealTime + 1 < v249 then
                v244.part:Destroy()
                v7[v243] = nil
            end
        else
            v244.part:Destroy()
            v7[v243] = nil
        end
    end
    if v235 and v239 and StepThreats(v233, v235) then
        v242 = true
    end
    local ScannedIdle = Handle:FindFirstChild("ScannedIdle")
    if ScannedIdle then
        if not v242 or ScannedIdle.IsPlaying then
            if not v242 and ScannedIdle.IsPlaying then
                ScannedIdle:Stop()
            end
        else
            ScannedIdle:Play()
        end
    end
end

local function EnterMode(v257, v258) -- line 555 | captures: Frame, ImageLabel, InnerFrame, ModeName, OffScreen, v5, v6, v12, v13, v14, v15, v16, v18, v21, v22, v23, script_2, Parent, LocalPlayer, EnsureViewport, ClearGhosts, ClearThreats, ApplyColor
    if v13 and v13.OnExit then
        v13.OnExit(v15)
    end
    if v14 then
        v14:Destroy()
        v14 = nil
    end
    ClearGhosts()
    ClearThreats()
    v12 = v257
    v13 = MODES[v257]
    if not v13 then
        return
    end
    EnsureViewport()
    v15 = {
        tool = Parent,
        def = v13,
        viewport = v5,
        camera = v6,
        color = v13.Color,
        character = LocalPlayer.Character
    }
    ApplyColor(v13.Color)
    ImageLabel.Image = v13.BootImage or "rbxassetid://0"
    ModeName.Text = v13.Label
    if v13.CreateScreen then
        v14 = v13.CreateScreen()
        v14.Name = "ModeUI"
        v14.Parent = InnerFrame
    end
    v15.ui = v14

    function v15.flash() -- line 579 | captures: v18
        v18 = 1
    end

    if v13.OnEnter then
        v13.OnEnter(v15)
    end
    Frame.Visible = true
    OffScreen.Visible = false
    v18 = 1
    if v258 then
        PlayAnim("open")
    else
        PlayAnim("next_mode")
    end
    if v258 then
        v21 = os.clock()
    end
    v23 = true
    ImageLabel.ImageTransparency = 0.6
    v5.Visible = false
    local delay = task.delay
    local v260 = if v258 then 0.9 else 0.35
    delay(v260, function() -- line 591 | captures: v257, v258, ImageLabel, v5, v12, v16, v22, v23
        if v12 ~= v257 then
            return
        end
        v23 = false
        ImageLabel.ImageTransparency = 0.85
        v5.Visible = true
        v22 = v258 and os.clock() or -10
        v16 = os.clock() + 0.3
    end)
end

local function Close() -- line 601 | captures: Frame, OffScreen, OffFrame, v12, v13, v14, v15, TweenService, Handle, ClearGhosts, ClearThreats
    local v261 = v12 ~= ""
    PlayAnim("close")
    if v13 and v13.OnExit then
        v13.OnExit(v15)
    end
    if v14 then
        v14:Destroy()
        v14 = nil
    end
    ClearGhosts()
    ClearThreats()
    v12 = ""
    v13 = nil
    v15 = nil
    Frame.Visible = false
    OffScreen.Visible = true
    local ScannedIdle = Handle:FindFirstChild("ScannedIdle")
    if ScannedIdle then
        ScannedIdle:Stop()
    end
    if v261 then
        OffFrame.Size = UDim2.fromScale(1, 1)
        local OffFrame_2 = OffFrame
        local v262 = { Size = UDim2.fromScale(1, 0.1) }
        TweenService:Create(OffFrame_2, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), v262):Play()
        task.delay(0.31, function() -- line 617 | captures: OffFrame, v12, TweenService
            if v12 ~= "" then
                return
            end
            local OffFrame_2 = OffFrame
            local v263 = { Size = UDim2.fromScale(0, 0.1) }
            local Quad = Enum.EasingStyle.Quad
            local In = Enum.EasingDirection.In
            local new = TweenInfo.new
            local v264 = Quad or Enum.EasingStyle.Quad
            TweenService:Create(OffFrame_2, new(0.4, v264, In or Enum.EasingDirection.Out), v263):Play()
        end)
    else
        OffFrame.Size = UDim2.fromScale(0, 0.1)
    end
end

local function OnModeChanged() -- line 625 | captures: v12, Parent, EnterMode, Close
    local v265 = Parent:GetAttribute("ScannerMode") or ""
    if v265 == "" then
        Close()
    else
        EnterMode(v265, v12 == "")
    end
end

function v26.equip() -- line 630 | captures: v3, v9, v10, v12, RunService, Parent, LocalPlayer, v11, BindUI, RefreshBattery, Step, EnterMode, Close, OnModeChanged
    -- Unanchor all parts so the tool follows the character
    for _, desc in Parent:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = false
        end
    end
    BindUI()
    if not v3 then
        return
    end
    local Character = LocalPlayer.Character
    local v266 = Character and Character:FindFirstChild("Humanoid")
    if v266 then
        local anims = Parent:FindFirstChild("Animations")
        if anims then
            local loopedAnims = { idle_open = true, idle = true, idleflash = true }
            for _, anim in anims:GetChildren() do
                if anim:IsA("Animation") then
                    local track = v266:LoadAnimation(anim)
                    if loopedAnims[anim.Name] then
                        track.Looped = true
                    end
                    v11[anim.Name] = track
                end
            end
        end
        if v11.inspect then
            inspectCtx = {
                Animations = { v11.inspect },
                Cancelled = false
            }
        end
    end
    PlayAnim("equip")
    -- Start the looping idle_open animation as the static idle pose
    task.delay(0.1, function()
        PlayAnim("idle_open")
    end)
    v9.mode = Parent:GetAttributeChangedSignal("ScannerMode"):Connect(OnModeChanged)
    v9.dur = Parent:GetAttributeChangedSignal("Durability"):Connect(RefreshBattery)
    RefreshBattery()
    local v267 = Parent:GetAttribute("ScannerMode") or ""
    if v267 == "" then
        Close()
    else
        local v268 = v12 == ""
        EnterMode(v267, v268)
    end
    v10 = RunService.RenderStepped:Connect(Step)
end

function v26.unequip() -- line 646 | captures: v3, v5, v6, Part, v9, v10, ScreenUI, Close
    -- Re-anchor all parts so the tool stays put when not held
    for _, desc in Parent:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = true
        end
    end
    if inspectCtx then
        inspectCtx.Cancelled = true
    end
    inspectActive = false
    if inspectTrack then
        inspectTrack:Stop(0.2)
        inspectTrack = nil
    end
    inspectCtx = nil
    for _, track in v11 do
        track:Stop()
        track:Destroy()
    end
    v11 = {}
    for v269, v270 in v9 do
        v270:Disconnect()
    end
    v9 = {}
    if v10 then
        v10:Disconnect()
        v10 = nil
    end
    if v3 then
        Close()
    end
    if v3 then
        v3:Destroy()
        v3 = nil
    end
    ScreenUI.Enabled = true
    v5 = nil
    v6 = nil
    Part = nil
end

function v26.fire() -- line 654 | captures: Parent
    local Remote = Parent:FindFirstChild("Remote")
    if Remote then
        Remote:FireServer()
    end
end

function v26.cancel() -- line 659 | captures: v12, Parent
    local v271
    if v12 == "" or v12 == "Base" then
        v271 = true
    else
        local ScannerRemote = Parent:FindFirstChild("ScannerRemote")
        if ScannerRemote then
            ScannerRemote:FireServer("eject")
        end
        v271 = false
    end
    return not v271
end

-- === *ToolClientFunctions: Inspect toggle ===
local function doInspect(ctx)
    local anim = ctx.Animations and ctx.Animations[1]
    if not anim or (Parent:GetAttribute("ScannerMode") or "") == "" then
        inspectActive = false
    elseif inspectActive then
        inspectActive = false
        inspectTrack = nil
        anim.TimePosition = 3.083333333333333
    else
        inspectActive = true
        inspectTrack = anim
        while true do
            task.wait()
            if not ctx.Cancelled and anim.IsPlaying then
                if anim.TimePosition >= 3.083333333333333 then
                    break
                end
                continue
            end
            break
        end
        if not ctx.Cancelled and inspectTrack == anim then
            anim:AdjustSpeed(0)
        end
    end
end

Parent:GetAttributeChangedSignal("ScannerMode"):Connect(function()
    inspectActive = false
    if inspectTrack then
        inspectTrack:Stop(0.2)
        inspectTrack = nil
    end
end)

-- === Tool Event Connections ===
Parent.Equipped:Connect(function()
    v26.equip()
end)

Parent.Unequipped:Connect(function()
    v26.unequip()
end)

Parent.Activated:Connect(function()
    PlayAnim("next_mode")
    v26.fire()
end)

-- Right-click (PKM) also triggers next_mode animation
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not v3 then return end -- only when tool is equipped and UI is active
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        PlayAnim("next_mode")
    end
end)

local InspectEvent = Parent:FindFirstChild("Inspect")
if InspectEvent then
    InspectEvent.Event:Connect(function()
        if inspectCtx then
            doInspect(inspectCtx)
        end
    end)
end

-- ============================================================
-- === GIVE TOOL TO PLAYER ===
-- ============================================================
-- Keep the tool parented to script as safe storage between respawns.
-- Move it to the Backpack when the character spawns.

local function giveToolToPlayer()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        Parent.Parent = backpack
    end
end

-- Store tool safely before character is removed (Backpack gets destroyed)
LocalPlayer.CharacterRemoving:Connect(function()
    Parent.Parent = script
end)

-- Give tool to player on each spawn
LocalPlayer.CharacterAdded:Connect(function()
    task.defer(function()
        task.wait()
        giveToolToPlayer()
    end)
end)

-- Give immediately if character already exists
if LocalPlayer.Character then
    giveToolToPlayer()
else
    Parent.Parent = script
end

