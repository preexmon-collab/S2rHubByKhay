--!nocheck
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

local CFG = {
SpeedCap = 1.15, HopRatio = 1.515, HopMin = 40, HopGap = 0.06, HopGapMin = 0.06, HopGapMax = 0.2,
HopRetries = 6, HopLift = 42, DimStep = 40, LandOffset = 14, LandSettle = 0.08, DropDelay = 0.05,
GrabInterval = 0.0005, RegrabFar = 40, Height = 70, ClimbShare = 0.5, CarryRatio = 0.9, EasyRatio = 1.3,
}
local COOLDOWN = 1.4
local cooldownUntil = os.clock() + 5 
local RELAY_SAFE = Vector3.new(542.93, 71.5, -405.58)
local DROP_POINT = Vector3.new(553.3, 70.4, -362.5)
local PHOTO_POINT = Vector3.new(544.1, 67.4, -362.4) 
local LEGIT_SPEED = 190
local DODGE_LANE_Z = -382
local DODGE_Y = 152
local DODGE_BURST_SPEED = 6000
local DODGE_BASE = Vector3.new(540.4, 70.8, -383.3)
local DODGE_TRIP = Vector3.new(5846.0, 17010.1, 15699.4)
local DODGE_TRIP_HOLD = 0.15
local DODGE_R1_WAIT = 1.2
local DODGE_R2_WAIT = 1.6
local DODGE_PICK_DELAY = 0.35
local MAX_ATTEMPTS = 3

local function safeRequire(getter) local ok, r = pcall(function() return require(getter()) end) return ok and r or nil end
local packagesFolder = ReplicatedStorage:WaitForChild("Packages", 10)
local networkingFolder = packagesFolder and packagesFolder:WaitForChild("Networking", 10) or nil
local EggState = safeRequire(function() return ReplicatedStorage.Client.EggState end)
local Assets   = safeRequire(function() return ReplicatedStorage.Data.Assets end)
local Mutations= safeRequire(function() return ReplicatedStorage.Shared.Modules.Mutations end)
local function remote(name)
    return networkingFolder and networkingFolder:FindFirstChild(name) or nil
end
local function root() local c = localPlayer.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function humanoid() local c = localPlayer.Character return c and c:FindFirstChildOfClass("Humanoid") end

local shield = { Original=nil, Clone=nil, Links={}, Connection=nil, Added=nil }
local function walkSpeed()
local c = localPlayer.Character local h = c and c:FindFirstChildOfClass("Humanoid")
local speed = h and h.WalkSpeed or 16
if shield.Original and shield.Original.Health > 0 then speed = math.min(speed, shield.Original.WalkSpeed) end
local ok, r = pcall(function()
local st = localPlayer:FindFirstChild("leaderstats"); st = st and st:FindFirstChild("Speed")
local util = require(ReplicatedStorage.Shared.Util.TreadmillUtil)
return st and util.SpeedPowerToWalkSpeed(st.Value) or nil
end)
if ok and type(r) == "number" and r > 0 then speed = math.min(speed, r) end
return speed
end
local function shieldControls(hum) pcall(function()
local s = localPlayer:FindFirstChild("PlayerScripts"); local m = s and s:FindFirstChild("PlayerModule")
if m then local c = require(m):GetControls() if type(c) == "table" then c.humanoid = hum end end
end) end
local function shieldAnimate(c)
local a = c and c:FindFirstChild("Animate")
if a and a:IsA("LocalScript") then task.spawn(function() a.Enabled = false task.wait() a.Enabled = true end) end
end
local function shieldUnlink() for _, l in ipairs(shield.Links) do pcall(function() l:Disconnect() end) end table.clear(shield.Links) end
local groundedStates = { [Enum.HumanoidStateType.Running]=true, [Enum.HumanoidStateType.RunningNoPhysics]=true, [Enum.HumanoidStateType.Landed]=true }
local function grounded(h) if not h or h.Health <= 0 or h.FloorMaterial == Enum.Material.Air then return false end return groundedStates[h:GetState()] == true end
local function shieldSwap()
local c = localPlayer.Character local h = c and c:FindFirstChildOfClass("Humanoid")
if not h or h.Health <= 0 then return end
if shield.Clone and shield.Clone.Parent == c then return end
if not grounded(h) then return end
local cloneOk, clone = pcall(function() return h:Clone() end)
if not cloneOk or not clone then return end
local parentOk = pcall(function()
    h.Parent = nil
    clone.Parent = c
end)
if not parentOk then
    if h.Parent == nil then pcall(function() h.Parent = c end) end
    pcall(function() clone:Destroy() end)
    return
end
local camera = workspace.CurrentCamera
if camera then pcall(function() camera.CameraSubject = clone end) end
shieldControls(clone) shieldAnimate(c)
shield.Original = h shield.Clone = clone
table.insert(shield.Links, h:GetPropertyChangedSignal("WalkSpeed"):Connect(function() if clone.Parent ~= nil then clone.WalkSpeed = h.WalkSpeed end end))
table.insert(shield.Links, clone.Died:Connect(function()
shieldUnlink() shield.Original, shield.Clone = nil, nil
local cur = localPlayer.Character
if cur and h.Parent == nil then
    h.Parent = cur
    local camera = workspace.CurrentCamera
    if camera then pcall(function() camera.CameraSubject = h end) end
    shieldControls(h)
end
pcall(function() clone:Destroy() end) h.Health = 0
end))
end
local function shieldUndo()
shieldUnlink()
local c, o, cl = localPlayer.Character, shield.Original, shield.Clone
shield.Original, shield.Clone = nil, nil
if o and cl and c and o.Parent == nil and cl.Parent == c then
o.Parent = c
local camera = workspace.CurrentCamera
if camera then pcall(function() camera.CameraSubject = o end) end
shieldControls(o)
pcall(function() cl:Destroy() end) shieldAnimate(c)
end
end
local function shieldStart()
pcall(shieldSwap)
local n = 0
shield.Connection = RunService.Heartbeat:Connect(function(dt)
n += dt
local c = localPlayer.Character
local miss = not (shield.Clone and c and shield.Clone.Parent == c)
if (miss and 0.25 or 3) <= n then n = 0 pcall(shieldSwap) end
end)
shield.Added = localPlayer.CharacterAdded:Connect(function(c)
shieldUnlink() shield.Original, shield.Clone = nil, nil
task.spawn(function() c:WaitForChild("Humanoid", 10) task.wait(1) if shield.Connection and localPlayer.Character == c then pcall(shieldSwap) end end)
end)
end
local function shieldStop()
if shield.Connection then shield.Connection:Disconnect() shield.Connection = nil end
if shield.Added then shield.Added:Disconnect() shield.Added = nil end
shieldUndo()
end

local alive = true
local sessionConnections = {}
local state = { Carrying=false, Uid=nil, Delivered=0, Busy=false, Cancel=false, Mult=1, PulledAt=0, HeldSeen=0, GuessedDrop=false, TripStartCF=nil, IgnoreRagdoll=false }
local function progress() end
if type(EggState) == "table" and type(EggState.CarryChanged) == "table" and type(EggState.CarryChanged.Connect) == "function" then
table.insert(sessionConnections, EggState.CarryChanged:Connect(function(arg)
local carrying = type(arg) == "table" and arg.IsCarrying == true
if carrying and arg.GuardDisabled == true then carrying = false end
state.GuessedDrop = false
if carrying then
state.HeldSeen = os.clock()
if not state.Carrying then state.CarryAt = os.clock() state.CarryLogged = false end
state.WakeReq = arg.RunBackWakeDelayRequired
end
if carrying and type(arg.Uid) == "string" then
state.Uid = arg.Uid
local m = tonumber(arg.SpeedMultiplier) if m and m > 0 then state.Mult = m end
end
state.Carrying = carrying
end))
end
pcall(function()
    local r = remote("RE/EggWorld/FieldEggRedeemVerdict")
    if r and r.OnClientEvent then
        table.insert(sessionConnections, r.OnClientEvent:Connect(function() state.Delivered = os.clock() end))
    end
end)
pcall(function() local r = remote("RE/Alerts/Raise")
if r and r.OnClientEvent then
        table.insert(sessionConnections, r.OnClientEvent:Connect(function(arg)
            if type(arg) == "table" and type(arg.Text) == "string" and string.find(string.lower(arg.Text), "delivery failed", 1, true) then
                state.DeliveryFailedAt = os.clock()
            end
        end))
    end
end)
pcall(function() local r = remote("RE/RigSync/Refresh")
if r and r.OnClientEvent then table.insert(sessionConnections, r.OnClientEvent:Connect(function(arg)
if state.IgnoreRagdoll then return end
if type(arg) == "string" then local ok, d = pcall(function() return game:GetService("HttpService"):JSONDecode(arg) end) arg = ok and d or nil end
if type(arg) ~= "table" then return end
if arg.Action == "Relocate" then
state.PulledAt = os.clock()
local a = arg.Arguments
if type(a) == "table" and tonumber(a[1]) and tonumber(a[2]) and tonumber(a[3]) then
state.RelocPos = Vector3.new(tonumber(a[1]), tonumber(a[2]), tonumber(a[3]))
else state.RelocPos = nil end
elseif arg.Action == "BeginRagdoll" then
state.Ragdoll = true state.RagdollAt = os.clock()
state.RagdollArgs = type(arg.Arguments) == "table" and arg.Arguments or nil
local r0 = root() if r0 then pcall(function() r0.AssemblyLinearVelocity = Vector3.zero end) end
elseif arg.Action == "EndRagdoll" then state.Ragdoll = false state.RagdollEnd = os.clock() end
end)) end end)
local function takeEgg(uid) if type(uid) == "string" and type(EggState) == "table" and type(EggState.CarryFieldEgg) == "function" then pcall(EggState.CarryFieldEgg, uid) end end
local function dropEgg() if type(EggState) == "table" and type(EggState.DropFieldEgg) == "function" then pcall(EggState.DropFieldEgg, "PlayerRequest") end end
local function promptNear(pos, r)
local best, bd = nil, r
for _, c in ipairs(workspace:GetChildren()) do
if c.Name == "SmartPromptPart" and c:IsA("BasePart") then
local p = c:FindFirstChild("CarryAreaEgg")
if p and p:IsA("ProximityPrompt") then
local d = (c.Position - pos).Magnitude
if d < bd then best, bd = p, d end
end
end
end
return best
end
local function heldByMe(uid)
local c = localPlayer.Character if type(uid) ~= "string" or not c then return false end
local e = workspace:FindFirstChild(uid) if not e then return false end
for _, d in ipairs(e:GetDescendants()) do
if d:IsA("WeldConstraint") or d:IsA("JointInstance") then
local ok, a, b = pcall(function() return d.Part0, d.Part1 end)
if ok and ((a and a:IsDescendantOf(c)) or (b and b:IsDescendantOf(c))) then return true end
end
end
return false
end
task.spawn(function()
while alive do
task.wait(0.2)
if not state.Carrying then
if state.GuessedDrop and heldByMe(state.Uid) then state.GuessedDrop, state.Carrying, state.HeldSeen = false, true, os.clock() end
elseif heldByMe(state.Uid) then state.HeldSeen = os.clock()
elseif os.clock() - state.HeldSeen > 0.8 then state.Carrying, state.GuessedDrop = false, true end
end
end)

local function snapshot()
local list = {}
local rf = remote("RF/EggWorld/AskFieldEggSnapshot") if not rf then return list end
local ok, r = pcall(function() return rf:InvokeServer() end)
local recs = ok and type(r) == "table" and (r.Records or r) or nil
if type(recs) ~= "table" then return list end
for _, rec in pairs(recs) do
if type(rec) == "table" and type(rec.Uid) == "string" then
local st = rec.State or "Slot"
if st == "Slot" or st == "Dropped" or st == true then
if typeof(rec.BottomCFrame) == "CFrame" then list[#list + 1] = rec end
end
end
end
return list
end
local function eggPosition(uid) for _, r in ipairs(snapshot()) do if r.Uid == uid then return r.BottomCFrame.Position end end return nil end
local function describe(rec)
local dir = type(Assets) == "table" and (Assets.Directory or Assets) or nil
local cat = tostring(rec.AssetCategory or rec.Category or "Unknown")
local entry = type(dir) == "table" and dir[cat] or nil
local info = { Uid = rec.Uid, Category = cat, Name = cat, Icon = "", Rarity = 0, Value = 0 }
if type(entry) == "table" then
info.Name = tostring(entry.DisplayName or entry.Name or cat)
local icon = entry.Icon
if icon ~= nil and tostring(icon) ~= "" then icon = tostring(icon) info.Icon = tonumber(icon) and ("rbxassetid://" .. icon) or icon end
if type(entry.Rarity) == "table" then info.Rarity = tonumber(entry.Rarity.RarityNumber or entry.Rarity.Rank) or 0
elseif tonumber(entry.Rarity) then info.Rarity = tonumber(entry.Rarity) end
local scale = tonumber(rec.AssetScale or rec.Scale) or 1
local factor = scale > 5 and (scale / 5) ^ 1.2 * 19.637875755794113 or scale ^ 1.85
local mut = 1
if type(Mutations) == "table" and type(Mutations.EarningsFor) == "function" then
local okM, rM = pcall(Mutations.EarningsFor, type(rec.Mutations) == "table" and rec.Mutations or {})
if okM and type(rM) == "number" then mut = rM end
end
info.Value = (tonumber(entry.EarningRate or entry.Value or 0)) * factor * mut
else
info.Name = "Egg (" .. tostring(rec.AssetCategory or "Special") .. ")"
info.Value = tonumber(rec.Value) or 1000
end
return info
end
local function money(v)
v = tonumber(v) or 0
if v ~= v or v == math.huge or v == -math.huge then v = 0 end
v = math.max(v, 0)
for _, u in ipairs({ {1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"} }) do
if v >= u[1] then return string.format("$%.2f%s/s", v/u[1], u[2]) end
end
return string.format("$%d/s", math.floor(v + 0.5))
end

local function netPing()
    local ping = 0.1
    pcall(function() ping = localPlayer:GetNetworkPing() end)
    return math.clamp(tonumber(ping) or 0.1, 0, 1)
end

local status = function() end
local semi = { Dodge=true, Frozen=false, Home=nil, Kind=nil, AtDrop=false, SlowRun=false, Fails=0, ResetDone=false, Rotate=nil, Log={} }
local function slog(msg)
local r = root()
semi.Log[#semi.Log+1] = string.format("%.1f %s | y=%s", os.clock()%1000, msg, r and string.format("%.0f", r.Position.Y) or "nil")
if #semi.Log > 300 then table.remove(semi.Log, 1) end
end
pcall(function() getgenv().S2rHubReport = function() return table.concat(semi.Log, "\n") end end)
local function frozenCamera()
local cam = workspace.CurrentCamera if not cam then return function() end end
local oldType, frame = cam.CameraType, cam.CFrame
pcall(function() cam.CameraType = Enum.CameraType.Scriptable cam.CFrame = frame end)
return function() pcall(function() cam.CameraType = oldType end) end
end
local stealClone = nil
local function dropClone() local c = stealClone stealClone = nil if c then pcall(function() c:Destroy() end) end end
local function randomName() return string.format("%08x", math.random(0, 2147483647)) end
local function postClone()
dropClone()
local c = localPlayer.Character if not c then return end
local was = c.Archivable c.Archivable = true local copy = c:Clone() c.Archivable = was
if copy then
for _, d in ipairs(copy:GetDescendants()) do
if d:IsA("LuaSourceContainer") or d:IsA("Animator") or d:IsA("AnimationController") or d:IsA("Sound") then pcall(function() d:Destroy() end)
elseif d:IsA("Humanoid") then pcall(function() d.PlatformStand = true d.AutoRotate = false d.WalkSpeed = 0 d.JumpPower = 0 d.JumpHeight = 0 d.BreakJointsOnDeath = false d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end)
elseif d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanTouch = false d.CanQuery = false end
end
copy.Name = "Clone" copy.Parent = workspace stealClone = copy
end
end
local function cloneModel(model, parent)
local map = {}
for _, d in ipairs(model:GetDescendants()) do map[d] = d.Archivable pcall(function() d.Archivable = true end) end
local was = model.Archivable model.Archivable = true
local ok, r = pcall(function() return model:Clone() end) model.Archivable = was
for inst, v in pairs(map) do pcall(function() inst.Archivable = v end) end
if not ok or not r then return nil end
r.Name = randomName()
for _, d in ipairs(r:GetDescendants()) do
if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ForceField") or d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("WeldConstraint") or d:IsA("BodyMover") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then pcall(function() d:Destroy() end)
elseif d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanQuery = false d.CanTouch = false
elseif d:IsA("Humanoid") then d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end
end
r.Parent = parent return r
end
local promptSaved = nil
local function hidePrompts(hide)
pcall(function()
local s = game:GetService("ProximityPromptService")
if hide then
promptSaved = promptSaved or { guis = {}, max = nil }
if promptSaved.max == nil then local okM, cur = pcall(function() return s.MaxPromptsVisible end) if okM then promptSaved.max = cur end end
pcall(function() s.MaxPromptsVisible = 0 end)
local pg = localPlayer:FindFirstChildOfClass("PlayerGui")
if pg then
for _, g in ipairs(pg:GetChildren()) do
local n = string.lower(g.Name)
if g:IsA("ScreenGui") and g.Enabled and not string.find(n, "s2rhub", 1, true) and (string.find(n, "prompt", 1, true) or string.find(n, "interact", 1, true)) then
g.Enabled = false promptSaved.guis[#promptSaved.guis+1] = g
end
end
end
elseif promptSaved then
local sv = promptSaved promptSaved = nil
for _, g in ipairs(sv.guis) do pcall(function() g.Enabled = true end) end
if sv.max ~= nil then pcall(function() s.MaxPromptsVisible = sv.max end) end
end
end)
end
local sinkName, touchSaved = nil, nil
local function sinkInput(on)
pcall(function()
local cas = game:GetService("ContextActionService")
if on then
if sinkName then return end
sinkName = "S2rHubFreeze" .. tostring(math.random(100000, 999999))
cas:BindActionAtPriority(sinkName, function() return Enum.ContextActionResult.Sink end, false, 3000,
Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Down,
Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Space, Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA)
elseif sinkName then local n = sinkName sinkName = nil cas:UnbindAction(n) end
end)
pcall(function()
local pg = localPlayer:FindFirstChildOfClass("PlayerGui") local t = pg and pg:FindFirstChild("TouchGui")
if on then if t and t:IsA("ScreenGui") and not touchSaved then touchSaved = { Gui = t, Enabled = t.Enabled } t.Enabled = false end
elseif touchSaved then local sv = touchSaved touchSaved = nil sv.Gui.Enabled = sv.Enabled end
end)
end
local function viewControls(on)
hidePrompts(not on) sinkInput(not on)
pcall(function()
local s = localPlayer:FindFirstChild("PlayerScripts") local m = s and s:FindFirstChild("PlayerModule")
if m then local c = require(m):GetControls() if on then c:Enable() else c:Disable() end end
end)
end

local viewState = nil
local function releaseView()
local v = viewState if not v then return end
viewState = nil semi.Frozen = false
viewControls(true)
if v.BindName then pcall(function() RunService:UnbindFromRenderStep(v.BindName) end) end
if v.Link then pcall(function() v.Link:Disconnect() end) end
if v.Beat then pcall(function() v.Beat:Disconnect() end) end
for _, p in ipairs(v.Hidden) do pcall(function() p.LocalTransparencyModifier = 0 end) end
for _, e in ipairs(v.Extras) do pcall(function() e.Inst.Enabled = e.Prev end) end
pcall(function()
v.Camera.CameraType = v.CameraType
if v.Follow then
local lc = localPlayer.Character local lh = lc and lc:FindFirstChildOfClass("Humanoid")
if lh then v.Camera.CameraSubject = lh end
end
end)
for _, c in ipairs(v.Copies) do pcall(function() c:Destroy() end) end
end
local function freezeView(character, offset, cameraCFrame, forced)
local cam = workspace.CurrentCamera
if viewState or not character or not cam then return false end
offset = offset or Vector3.zero
local v = { Camera = cam, CameraType = cam.CameraType, CameraCFrame = cameraCFrame or cam.CFrame, Copies = {}, Hidden = {}, Parts = {}, Extras = {} }
viewState = v v.Forced = forced == true v.Follow = getgenv().S2rHubCamFollow ~= false
if not v.Forced then task.delay(120, function() if viewState == v then releaseView() end end) end
local hiddenSet, extraSet = {}, {}
for _, d in ipairs(character:GetDescendants()) do
if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
hiddenSet[d] = true v.Hidden[#v.Hidden+1] = d
if d:IsA("BasePart") then v.Parts[#v.Parts+1] = d end
end
end
local lastScan = os.clock()
local function scanExtras()
for _, d in ipairs(character:GetDescendants()) do
if not extraSet[d] and (d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Highlight") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Light")) then
extraSet[d] = true
local okE, ev = pcall(function() return d.Enabled end)
v.Extras[#v.Extras+1] = { Inst = d, Prev = okE and ev or false }
end
end
end
pcall(scanExtras)
local function tick()
if os.clock() - lastScan > 0.5 then
lastScan = os.clock() if v.Semi then hidePrompts(true) end
pcall(function()
for _, d in ipairs(character:GetDescendants()) do
if not hiddenSet[d] and (d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture")) then
hiddenSet[d] = true v.Hidden[#v.Hidden+1] = d
if d:IsA("BasePart") then v.Parts[#v.Parts+1] = d end
end
end
for _, c in ipairs(v.Copies) do if c.Parent ~= cam then c.Parent = cam end end
scanExtras()
end)
end
local shown = v.Follow and 0 or 1
pcall(function() for _, p in ipairs(v.Parts) do if p.LocalTransparencyModifier ~= shown then p.LocalTransparencyModifier = shown end end end)
if #v.Extras > 0 then pcall(function() for _, e in ipairs(v.Extras) do if e.Inst.Enabled then e.Inst.Enabled = false end end end) end
pcall(function()
local live = workspace.CurrentCamera if live and live ~= cam then cam = live v.Camera = live end
if v.Follow then
local lc = localPlayer.Character local lh = lc and lc:FindFirstChildOfClass("Humanoid")
if lh then
if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
if cam.CameraSubject ~= lh then cam.CameraSubject = lh end
return
end
end
if cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Scriptable end
cam.CFrame = v.CameraCFrame
end)
end
tick()
v.BindName = randomName()
if not pcall(function() RunService:BindToRenderStep(v.BindName, Enum.RenderPriority.Last.Value + 1, tick) end) then
v.BindName = nil v.Link = RunService.RenderStepped:Connect(tick)
end
v.Beat = RunService.Heartbeat:Connect(tick)
local ok, copy = false, nil
if not v.Follow then ok, copy = pcall(cloneModel, character, cam) end
if ok and copy then
if offset.Magnitude > 0.01 then
for _, d in ipairs(copy:GetDescendants()) do if d:IsA("BasePart") then pcall(function() d.CFrame = d.CFrame + offset end) end end
end
v.Copies[#v.Copies+1] = copy
end
v.Semi = true viewControls(false) semi.Frozen = true return true
end
local function releaseBackHome(home)
local f = viewState if not f then return end
if typeof(home) ~= "Vector3" then releaseView() return end
local st = os.clock()
while os.clock() - st < 7 and viewState == f do local r = root() if not r or r.Position.Y < 5000 then break end RunService.Heartbeat:Wait() end
for _ = 1, 10 do
if viewState ~= f then return end
local r = root() if r then pcall(function() r.CFrame = CFrame.new(home) * r.CFrame.Rotation r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero end) end
RunService.Heartbeat:Wait()
end
if viewState == f then releaseView() end
end
local function swapped() local c = localPlayer.Character return shield.Clone ~= nil and c ~= nil and shield.Clone.Parent == c end

local function lineInfo()
local w = workspace:FindFirstChild("World") or workspace:FindFirstChild("__OBJECTS")
w = w and w:FindFirstChild("Areas") w = w and w:FindFirstChild("SeparationLine")
local ok = w and w:IsA("BasePart")
return ok and w.Position.X or 552.2, ok and w.Position.Y or 67.67
end
local function homePoint()
for _, def in ipairs({
{ { "GearGiver_Slap", "Podium" }, Vector3.new(-16.415, 21.072, -6.106) },
{ { "World", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
{ { "__OBJECTS", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
}) do
local node = workspace
for _, n in ipairs(def[1]) do node = node and node:FindFirstChild(n) or nil end
if node and node:IsA("BasePart") then return node.CFrame:PointToWorldSpace(def[2]) end
end
return Vector3.new(528.7, 70.57, -364.11)
end
local function placeCFrame(cf) local r = root() if not r then return end pcall(function() r.CFrame = cf r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero end) end
local function place(position) placeCFrame(CFrame.new(position)) end
local dangerCache, dangerAt = {}, 0
local function dangers()
if os.clock() - dangerAt < 5 then return dangerCache end
dangerAt = os.clock()
local list = {}
local function add(inst)
local ok, cf, size = pcall(function()
if inst:IsA("Model") then return inst:GetBoundingBox()
elseif inst:IsA("BasePart") then return inst.CFrame, inst.Size end
end)
if ok and cf and size then
local half = Vector3.new(math.abs(size.X), 0, math.abs(size.Z)) * 0.5
local rot = (cf - cf.Position):VectorToWorldSpace(half)
local rx = math.max(math.abs(rot.X), half.X, half.Z) local rz = math.max(math.abs(rot.Z), half.X, half.Z)
list[#list+1] = { MinX = cf.Position.X - rx, MaxX = cf.Position.X + rx, MinZ = cf.Position.Z - rz, MaxZ = cf.Position.Z + rz }
end
end
local function bad(name)
if name == "ScrambleLocalVisuals" or name == "DrScrambleEvent" then return false end
name = string.lower(name)
return string.find(name, "portal", 1, true) or string.find(name, "teleport", 1, true) or string.find(name, "mech", 1, true) or string.find(name, "arena", 1, true) or string.find(name, "scramble", 1, true)
end
for _, c in ipairs(workspace:GetChildren()) do
if (c:IsA("Model") or c:IsA("BasePart") or c:IsA("Folder")) and bad(c.Name) then
if c:IsA("Folder") then for _, i in ipairs(c:GetChildren()) do add(i) end else add(c) end
end
end
local build = workspace:FindFirstChild("World") build = build and build:FindFirstChild("Build")
if build then for _, c in ipairs(build:GetChildren()) do if bad(c.Name) then for _, i in ipairs(c:GetChildren()) do add(i) end end end end
dangerCache = list return list
end
local function avoid(from, to)
for _, d in ipairs(dangers()) do
local x0, x1, z0, z1 = d.MinX - 12, d.MaxX + 12, d.MinZ - 12, d.MaxZ + 12
local inside = from.X >= x0 and from.X <= x1 and from.Z >= z0 and from.Z <= z1
if not inside then
local t0, t1, hit = 0, 1, true
for _, ax in ipairs({ { from.X, to.X - from.X, x0, x1 }, { from.Z, to.Z - from.Z, z0, z1 } }) do
local pos, delta, lo, hi = ax[1], ax[2], ax[3], ax[4]
if math.abs(delta) < 1e-6 then if pos < lo or pos > hi then hit = false end
else
local ta, tb = (lo - pos) / delta, (hi - pos) / delta if ta > tb then ta, tb = tb, ta end
t0, t1 = math.max(t0, ta), math.min(t1, tb) if t0 > t1 then hit = false end
end
end
if hit then
local zL, zH = z0 - 2, z1 + 2
local z = math.abs(from.Z - zL) <= math.abs(from.Z - zH) and zL or zH
if z < -440 or z > -290 then z = z == zL and zH or zL end
local x = math.abs(from.X - x0) <= math.abs(from.X - x1) and x0 or x1
if math.abs(from.Z - z) < 3 then x = math.abs(to.X - x0) <= math.abs(to.X - x1) and x0 or x1 end
return Vector3.new(x, to.Y, z)
end
end
end
return to
end
local function eggNow(uid, cache)
local node = workspace:FindFirstChild(uid)
local slots = workspace:FindFirstChild("AreaEggSlotsClient")
node = node or (slots and slots:FindFirstChild(uid))
if node then
local ok, pos = pcall(function() return node:GetPivot().Position end)
if ok and pos then cache.Pos, cache.At = pos, os.clock() return pos end
end
if os.clock() - cache.At >= 0.5 then cache.At = os.clock() cache.Pos = eggPosition(uid) or cache.Pos end
return cache.Pos
end
local function holdStill()
local function zero() local r = root() if r then pcall(function() r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero end) end end
zero()
local link pcall(function() if RunService.Stepped then link = RunService.Stepped:Connect(zero) end end)
return function() if link then pcall(function() link:Disconnect() end) end end
end
local function ragdollWait()
if state.IgnoreRagdoll then return false end
local seen = state.RagdollAt
if not (state.Ragdoll and seen and os.clock() - seen < 12) then return false end
state.Hits = (state.Hits or 0) + 1
local release = holdStill() local stop = os.clock() + 8
while state.Ragdoll and os.clock() < stop and not state.Cancel do
RunService.Heartbeat:Wait() local r = root() if r then pcall(function() r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero end) end
end
release() state.Ragdoll = false
local calm = 0 while calm < 0.15 and not state.Cancel do calm += RunService.Heartbeat:Wait() end
return true
end

local function runToEgg(uid, egg, opts)
opts = opts or {}
local ratio = math.min(opts.Ratio or CFG.SpeedCap, CFG.SpeedCap)
local height = opts.Height or 0
local lineX = lineInfo() local home = homePoint()
local c = localPlayer.Character local h = c and c:FindFirstChildOfClass("Humanoid")
if h then h.PlatformStand = false if c:FindFirstChildWhichIsA("Tool") then pcall(function() h:UnequipTools() end) end end
local r = root() if not r then return false end
local stage = "field"
if not opts.Field and r.Position.X < lineX - 2 and Vector3.new(r.Position.X - home.X, 0, r.Position.Z - home.Z).Magnitude > 20 then stage = "safe" end
local runY = egg.Y + 3
local function snapToHeight(target)
local at = root() local cur = localPlayer.Character
if not at or not cur or math.abs(at.Position.Y - target) < 1 or math.abs(at.Position.Y - target) > 90 then return false end
pcall(function() cur:PivotTo(CFrame.new(Vector3.new(at.Position.X, target, at.Position.Z)) * at.CFrame.Rotation) at.AssemblyLinearVelocity = Vector3.new(at.AssemblyLinearVelocity.X, 0, at.AssemblyLinearVelocity.Z) end)
return true
end
if stage == "field" and height > 0.5 then snapToHeight(runY + height) end
local started, lastCheck, lastPos, lastTake = os.clock(), os.clock(), r.Position, 0
while os.clock() - started < 120 and not state.Cancel do
if ragdollWait() then started += 1 end
r = root() if not r then return false end
local flatEgg = Vector3.new(egg.X - r.Position.X, 0, egg.Z - r.Position.Z)
if state.Carrying and state.Uid == uid then break end
if stage == "field" and flatEgg.Magnitude <= 2.5 and (height <= 0.5 or r.Position.Y - runY < 4) then break end
local target = egg
if stage == "safe" then
if Vector3.new(home.X - r.Position.X, 0, home.Z - r.Position.Z).Magnitude <= 6 then stage = "field" if height > 0.5 then snapToHeight(runY + height) end
else target = home end
end
local wp = avoid(r.Position, target)
local flat = Vector3.new(wp.X - r.Position.X, 0, wp.Z - r.Position.Z)
local unit = flat.Magnitude > 0.01 and flat.Unit or Vector3.zero
local speed = math.max(walkSpeed() * ratio, 8)
if height > 0.5 and stage == "field" then
local wantY = flatEgg.Magnitude <= 3 and runY or runY + height
if (flatEgg.Magnitude <= 3 and snapToHeight(runY)) or (math.abs(wantY - r.Position.Y) > 2 and snapToHeight(wantY)) then RunService.Heartbeat:Wait() continue end
local vy = math.clamp((wantY - r.Position.Y) / 0.12, -speed * 0.5, speed * 0.5)
local speedSq = speed * speed
local hor = unit * math.min(math.sqrt(math.max(speedSq - (vy * vy), 0)), flat.Magnitude / 0.05)
pcall(function() r.AssemblyLinearVelocity = Vector3.new(hor.X, vy, hor.Z) end)
else
local v = unit * math.min(speed, flat.Magnitude / 0.05)
pcall(function() r.AssemblyLinearVelocity = Vector3.new(v.X, r.AssemblyLinearVelocity.Y, v.Z) if h and unit.Magnitude > 0 then h:Move(unit, false) end end)
end
if os.clock() - lastCheck >= 1.5 then
if (r.Position - lastPos).Magnitude < 3 and h and flatEgg.Magnitude > 15 then pcall(function() h.Jump = true end) end
lastPos, lastCheck = r.Position, os.clock()
end
if stage == "field" and flatEgg.Magnitude <= 9 and os.clock() - lastTake > 0.1 then lastTake = os.clock() task.spawn(takeEgg, uid) end
RunService.Heartbeat:Wait()
end
r = root() if r then pcall(function() r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) if h then h:Move(Vector3.zero, false) end end) end
return state.Carrying or (r ~= nil and Vector3.new(egg.X - r.Position.X, 0, egg.Z - r.Position.Z).Magnitude <= 6)
end
local function grab(uid, timeout)
local cache = { At = 0 } local waited, since = 0, 1
while not state.Carrying and waited < timeout and not state.Cancel do
local sf = os.clock() if ragdollWait() then timeout += os.clock() - sf since = 1 end
local r = root() local egg = eggNow(uid, cache)
local dt = math.max(RunService.Heartbeat:Wait(), 1/240) waited += dt since += dt
if r and egg then
local d = egg - r.Position
if d.Magnitude > 2 then
local pace = math.max(walkSpeed() * CFG.SpeedCap, 16)
local v = d / math.max(0.08, dt) if v.Magnitude > pace then v = v.Unit * pace end
pcall(function() r.AssemblyLinearVelocity = v + Vector3.new(0, workspace.Gravity * dt * 0.5, 0) r.AssemblyAngularVelocity = Vector3.zero end)
end
if since >= CFG.GrabInterval then
since = 0
local p = promptNear(egg - Vector3.new(0, 3, 0), 15)
if p and typeof(fireproximityprompt) == "function" then pcall(function() p.HoldDuration = 0 end) pcall(fireproximityprompt, p) end
task.spawn(takeEgg, uid)
end
elseif since >= CFG.GrabInterval then since = 0 task.spawn(takeEgg, uid) end
end
local r = root() if r then pcall(function() r.AssemblyLinearVelocity = Vector3.zero end) end
return state.Carrying and state.Uid == uid
end
local function regrab(uid)
if state.Carrying then return true end
local r = root() local egg = eggNow(uid, { At = 0 })
local gap = r and egg and Vector3.new(r.Position.X - egg.X, 0, r.Position.Z - egg.Z).Magnitude or 0
if gap > 1500 then return false end
if r and egg and gap > CFG.RegrabFar then place(egg + Vector3.new(0, 3, 0)) end
return grab(uid, 3)
end
local function groundY(pos, fallback)
local y = fallback
pcall(function()
local p = RaycastParams.new() p.FilterType = Enum.RaycastFilterType.Exclude p.FilterDescendantsInstances = { localPlayer.Character }
p.IgnoreWater = true p.RespectCanCollide = true
local hit = workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), p)
if hit and hit.Material ~= Enum.Material.Water and math.abs(hit.Position.Y - fallback) < 40 then y = hit.Position.Y + 3.5 end
end)
return y
end
local function legitWalkTo(targetPos, timeout)
local hum = humanoid() local r = root()
if not hum or not r then return end
local oldSpeed = hum.WalkSpeed
hum.WalkSpeed = LEGIT_SPEED
local startTime = os.clock()
while (r.Position - targetPos).Magnitude > 4 and (os.clock() - startTime) < (timeout or 6) and not state.Cancel do
hum:MoveTo(targetPos)
RunService.Heartbeat:Wait()
end
hum:MoveTo(r.Position)
hum.WalkSpeed = oldSpeed
end

local function treadmillStand()
local ok, s = pcall(function()
local PS = require(ReplicatedStorage.Client.PlotState)
local slot = type(PS.ResolveLocalSlot) == "function" and PS.ResolveLocalSlot() or PS.GetMySlot()
local plots = type(PS.ResolveFolder) == "function" and PS.ResolveFolder() or PS.GetPlotsFolder()
local plot = plots and slot and plots:FindFirstChild(tostring(slot))
local bottom = plot and plot:FindFirstChild("TreadmillBottom")
if not (bottom and bottom:IsA("BasePart")) then return nil end
local c = localPlayer.Character local r = c and c:FindFirstChild("HumanoidRootPart") local h = c and c:FindFirstChildOfClass("Humanoid")
if not r or not h then return nil end
local feet = h.RigType == Enum.HumanoidRigType.R15 and (r.Size.Y * 0.5 + math.max(h.HipHeight, 0.5)) or (r.Size.Y * 0.5 + 2)
return (bottom.CFrame * CFrame.new(0, bottom.Size.Y * 0.5 + feet + 0.05, 0)).Position
end)
return ok and s or nil
end
local function treadmillMounted()
local s = remote("RF/Treadmill/AskRenderSnapshot")
if not s or not s:IsA("RemoteFunction") then return nil end
local ok, ids = pcall(s.InvokeServer, s)
if not ok or type(ids) ~= "table" then return nil end
return table.find(ids, localPlayer.UserId) ~= nil
end
local function treadmillReset()
local wear = remote("RF/Treadmill/AskWearStill") local doff = remote("RF/Treadmill/AskDoff") local stand = treadmillStand()
if not (wear and doff and stand) or state.Cancel then return false end
place(stand)
local function pause(t) local w = 0 while w < t and not state.Cancel do w += RunService.Heartbeat:Wait() end end
pause(0.15)
local mounted = false local mb = os.clock() + 0.7
while not state.Cancel and os.clock() < mb do pcall(wear.InvokeServer, wear) pause(0.08) if treadmillMounted() == true then mounted = true break end end
if mounted then pause(0.25) end
local released = false local rb = os.clock() + 0.7
while not state.Cancel and os.clock() < rb do pcall(doff.InvokeServer, doff) pause(0.08) if treadmillMounted() == false then released = true break end end
return mounted and released
end
local function getOffTreadmill()
for _ = 1, 3 do
local r = root() if not r or not r.Anchored or state.Cancel then return true end
local d = remote("RF/Treadmill/AskDoff") if d and d:IsA("RemoteFunction") then pcall(d.InvokeServer, d) end
local held, lim = 0, 1.5 + netPing()
while held < lim and not state.Cancel do local rr = root() if not rr or not rr.Anchored then return true end held += RunService.Heartbeat:Wait() end
end
local r = root() return not (r and r.Anchored)
end

local function fastFlyTo(target, speed, timeout)
local r = root() if not r then return false end
local speed_ = speed or DODGE_BURST_SPEED
local startTime = os.clock()
while (os.clock() - startTime) < (timeout or 3) and not state.Cancel do
local r2 = root() if not r2 then return false end
local delta = target - r2.Position
if delta.Magnitude < 1 then return true end
local dt = math.min(RunService.Heartbeat:Wait(), 0.05)
local step = delta.Unit * math.min(speed_ * dt, delta.Magnitude)
place(r2.Position + step)
end
return (root() and (root().Position - target).Magnitude <= 3) or false
end

local function runToEggFast(uid, speed, timeout)
local hum = humanoid() local r = root()
if not hum or not r then return false end
local oldSpeed = hum.WalkSpeed
hum.PlatformStand = false
hum.AutoRotate = false 
    local startTime = os.clock()
    local since = 0
    local cache = { At = 0 }
    
    while not state.Carrying and (os.clock() - startTime) < (timeout or 8) and not state.Cancel do
        local r2 = root()
        if not r2 then break end
        
        local eggPos = eggNow(uid, cache) or eggPosition(uid) or DROP_POINT
        local delta = eggPos - r2.Position
        local flatDelta = Vector3.new(delta.X, 0, delta.Z)
        local dist = flatDelta.Magnitude

        local currentSpeed = speed or 100
        if dist <= 50 then
            currentSpeed = 100
        end
        hum.WalkSpeed = currentSpeed
        
        local dt = math.min(RunService.Heartbeat:Wait(), 0.05)
        since += dt
        
        if dist > 2 then
            local dir = flatDelta.Unit
            hum:Move(dir, false)
            
            local step = dir * math.min(currentSpeed * dt, dist)
            local lookCF = CFrame.lookAt(Vector3.zero, dir)
            placeCFrame(CFrame.new(r2.Position + step) * lookCF)
        else
            hum:Move(Vector3.zero, false)
        end
        
        if since >= CFG.GrabInterval then
            since = 0
            local prompt = promptNear(eggPos, 15)
            if prompt and typeof(fireproximityprompt) == "function" then
                pcall(function() prompt.HoldDuration = 0 end)
                pcall(fireproximityprompt, prompt)
            end
            task.spawn(takeEgg, uid)
        end
    end
    
    hum:Move(Vector3.zero, false)
    hum.WalkSpeed = oldSpeed
    hum.AutoRotate = true
    return state.Carrying and state.Uid == uid
end

local function relayFlow(uid, started, releaseCamera, semiFrozen)
local function held() return state.Carrying and state.Uid == uid end
local function wait(t) local w = 0 while w < t and not state.Cancel do w += RunService.Heartbeat:Wait() end end
local function finish()
releaseCamera()
if semiFrozen then releaseView() end
dropClone()
state.IgnoreRagdoll = false
if state.TripStartCF then
placeCFrame(state.TripStartCF)
wait(0.05)
end
end
if not held() then
local synced = 0 while not held() and synced < 2.5 and not state.Cancel do synced += RunService.Heartbeat:Wait() end
if not held() then finish() return false end
end

    state.IgnoreRagdoll = true

    local dropPos = DROP_POINT
    place(dropPos)

    wait(0.3)
    dropEgg()
    wait(0.05)

    place(dropPos + Vector3.new(0, 15, 0))
    wait(0.05)

    fastFlyTo(PHOTO_POINT, DODGE_BURST_SPEED, 2)
    place(PHOTO_POINT)
    wait(0.05)

    local eggNow_ = nil
    for _ = 1, 12 do
        if state.Cancel then break end
        eggNow_ = eggPosition(uid)
        if eggNow_ then break end
        wait(0.05)
    end
    eggNow_ = eggNow_ or dropPos

    runToEggFast(uid, 100, 6)

    if state.Carrying then
        fastFlyTo(PHOTO_POINT, DODGE_BURST_SPEED, 2)
        place(PHOTO_POINT)
        wait(0.05)
    end

    local verdictBy = os.clock() + 4
    while not state.Cancel and state.Delivered < started and os.clock() < verdictBy do RunService.Heartbeat:Wait() end

    finish() return state.Delivered >= started
end

semi.DodgeRoute = function(ctx)
local function held() return state.Carrying and state.Uid == ctx.Uid end
local function near(a, b, d) return a and b and Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude <= d end
local function pinFor(point, t, stopWhen)
local w = 0
while w < t and not state.Cancel do
if stopWhen and stopWhen() then return true end
local r = root() if r and (r.Position - point).Magnitude > 1 then place(point) end
w += RunService.Heartbeat:Wait()
end
return stopWhen ~= nil and stopWhen() or false
end
if not root() then return false end
getOffTreadmill()
local eggPos = ctx.EggPos()
local at = ctx.LandFor(eggPos)
if not at then return false end
place(DODGE_BASE) pinFor(DODGE_BASE, 0.1)
local ping = netPing()
local r1Wait, r2Wait = DODGE_R1_WAIT + ping, DODGE_R2_WAIT + ping
local pickDelay = math.max(DODGE_PICK_DELAY, ping * 2.5)
local before = state.PulledAt local jumpAt = os.clock()
place(at)
local r1 = pinFor(at, r1Wait, function() return state.PulledAt > before end)
local r1At = r1 and state.PulledAt or nil local r2At = nil
if r1At then
if state.RelocPos and near(state.RelocPos, at, 25) then r2At = r1At
else
pinFor(DODGE_TRIP, DODGE_TRIP_HOLD)
place(at) local mark = state.PulledAt
pinFor(at, r2Wait, function()
if state.PulledAt > mark then
mark = state.PulledAt
if state.RelocPos and near(state.RelocPos, at, 25) then r2At = state.PulledAt return true end
end
return false
end)
end
end
if not r2At and r1At then place(DODGE_BASE) return false end
pinFor(at, math.max(0, (r2At or os.clock()) + pickDelay - os.clock()))
local since, waited = 1, 0
while not held() and waited < 2.5 and not state.Cancel do
local r = root() local egg = ctx.EggPos() or eggPos
if r and (r.Position - at).Magnitude > 1.5 then place(at) end
local dt = RunService.Heartbeat:Wait() waited += dt since += dt
if since >= CFG.GrabInterval then
since = 0
local p = promptNear(egg, 15)
if p and typeof(fireproximityprompt) == "function" then pcall(function() p.HoldDuration = 0 end) pcall(fireproximityprompt, p) end
task.spawn(takeEgg, ctx.Uid)
end
end
if not held() and not state.Cancel then ctx.Grab(ctx.Uid, 1) end
if not held() then place(DODGE_BASE) return false end
    local dropPos = DROP_POINT
    local r0 = root()
    local startX = r0 and r0.Position.X or dropPos.X
    local totalDist = math.abs(startX - dropPos.X)
    local dir = startX > dropPos.X and -1 or 1
    local travelled = 0
    while travelled < totalDist and not state.Cancel and held() do
        local dt = math.min(RunService.Heartbeat:Wait(), 0.05)
        travelled = math.min(travelled + DODGE_BURST_SPEED * dt, totalDist)
        place(Vector3.new(startX + dir * travelled, DODGE_Y, DODGE_LANE_Z))
    end
    place(dropPos)
    pinFor(dropPos, 0.15)

    return "near"
end

local function semiGo(uid, egg)
local startRoot = root() if not startRoot then return false, "no character" end
local character = localPlayer.Character local humanoid2 = character and character:FindFirstChildOfClass("Humanoid")
local startCF = startRoot.CFrame
state.TripStartCF = startCF
local cache = { At = 0, Pos = egg }
local function eggPos() return eggNow(uid, cache) or egg end
local function eggPart()
local node = workspace:FindFirstChild(uid)
local slots = workspace:FindFirstChild("AreaEggSlotsClient")
node = node or (slots and slots:FindFirstChild(uid))
if not node then return nil end
if node:IsA("BasePart") then return node end
return node:FindFirstChild("Hitbox", true) or node:FindFirstChildWhichIsA("BasePart", true)
end
local cam = workspace.CurrentCamera
local camOffset = cam and (cam.CFrame.Position - startRoot.Position) or Vector3.new(0, 8, 14)
local camRot = cam and cam.CFrame.Rotation or CFrame.new()
semi.Kind, semi.AtDrop, semi.Home, semi.Plain = nil, false, nil, false
    if Vector3.new(egg.X - startRoot.Position.X, 0, egg.Z - startRoot.Position.Z).Magnitude <= 60 then
        semi.Kind = "decoy" semi.AtDrop = true
        local spotAt = startRoot.Position
        local okF = freezeView(character, Vector3.zero, nil)
        semi.Home = okF and spotAt or nil
        return true, { Decoy = true }
    end

    semi.Kind = "semi" semi.AtDrop = true
    for _ = 1, 3 do RunService.Heartbeat:Wait() end
    local ss = os.clock()
    while not swapped() and os.clock() - ss < 5 and not state.Cancel do
        pcall(function() local r0 = root() if r0 then r0.AssemblyLinearVelocity = Vector3.zero end if humanoid2 then humanoid2:Move(Vector3.zero, false) end end)
        RunService.Heartbeat:Wait()
    end

    local freezeAt = root() local freezeSpot = freezeAt and freezeAt.Position or startCF.Position
    local function freezeNow() return freezeView(character, Vector3.zero, CFrame.new(freezeSpot + camOffset) * camRot) end
    local okF = freezeNow() if not okF then releaseView() okF = freezeNow() end
    semi.Home = okF and freezeSpot or nil
    for _ = 1, 6 do RunService.Heartbeat:Wait() end
    pcall(function()
        local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then semi.Rotate = { Hum = hum, Old = hum.AutoRotate } hum.AutoRotate = false end
    end)

    local groundSkip, groundSkipAt = nil, 0
    local function groundAt(pos, from)
        local found = nil
        pcall(function()
            if not groundSkip or os.clock() - groundSkipAt > 1 then
                groundSkip = { stealClone } groundSkipAt = os.clock()
                local slots = workspace:FindFirstChild("AreaEggSlotsClient")
                if slots then groundSkip[#groundSkip+1] = slots end
                for _, c in ipairs(workspace:GetChildren()) do
                    if c:IsA("Model") and #c.Name == 32 and c:FindFirstChild("Hitbox") then groundSkip[#groundSkip+1] = c end
                end
            end
            local list = { localPlayer.Character }
            for _, v in ipairs(groundSkip) do list[#list+1] = v end
            local p = RaycastParams.new() p.FilterType = Enum.RaycastFilterType.Exclude p.FilterDescendantsInstances = list
            p.IgnoreWater = true pcall(function() p.RespectCanCollide = true end)
            local origin = Vector3.new(pos.X, from, pos.Z)
            for _ = 1, 4 do
                local hit = workspace:Raycast(origin, Vector3.new(0, -400, 0), p)
                if not hit then break end
                if hit.Material ~= Enum.Material.Water and hit.Instance.CanCollide and hit.Instance.Transparency < 0.95 then found = hit.Position break end
                origin = hit.Position - Vector3.new(0, 0.05, 0)
            end
        end)
        return found
    end
    local function standHeight()
        local h = 3
        pcall(function()
            local c2 = localPlayer.Character local r = root()
            local hum = c2 and c2:FindFirstChildOfClass("Humanoid")
            if c2 and r then
                local box, boxSize = c2:GetBoundingBox()
                local value = r.Position.Y - (box.Position.Y - boxSize.Y / 2)
                if value > 1 and value < 12 then h = value end
                if hum and hum.HipHeight > 0.2 then local exact = hum.HipHeight + r.Size.Y / 2 if exact > 1 and exact < 12 then h = exact end end
            end
        end)
        return h + 0.05
    end
    local approachDir = nil
    pcall(function() local flat = Vector3.new(startRoot.Position.X - egg.X, 0, startRoot.Position.Z - egg.Z) if flat.Magnitude > 1 then approachDir = flat.Unit end end)
    local function landFor(at, high)
        local dir = approachDir or Vector3.new(-1, 0, 0) local stand = 2.5
        pcall(function() local part = eggPart() if part and part.CanCollide then stand = math.clamp(math.sqrt(part.Size.X^2 + part.Size.Z^2) / 2 + 2.2, 2.5, 7) end end)
        local base = Vector3.new(at.X + dir.X * stand, at.Y + 3, at.Z + dir.Z * stand)
        if high then
            local top = groundAt(base, at.Y + 160)
            if top and math.abs(top.Y - at.Y) < 150 then return Vector3.new(base.X, top.Y + standHeight(), base.Z) end
            return nil
        end
        local hit = groundAt(base, at.Y + 6)
        if hit and math.abs(hit.Y - at.Y) < 12 then return Vector3.new(base.X, hit.Y + standHeight(), base.Z) end
        hit = groundAt(base, at.Y + 40)
        if hit and math.abs(hit.Y - at.Y) < 40 then return Vector3.new(base.X, hit.Y + standHeight(), base.Z) end
        return base
    end
    semi.LandFor = landFor

    local touchWon = semi.DodgeRoute({ Uid = uid, EggPos = eggPos, LandFor = landFor, Grab = grab })
    if not touchWon then
        releaseView()
        local r = root() if r then pcall(function() r.CFrame = startCF r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero end) end
        task.wait(0.2)
        return false, "Dodge: not accepted"
    end
    semi.Plain = true
    return true, { Arrived = true, Plain = true }
end

local function instantTP(uid)
local started = os.clock()
local r = root() if not r then return false end
local semiFrozen = viewState ~= nil
local releaseCamera = semiFrozen and function() end or frozenCamera()
state.ReleaseCamera = releaseCamera
if not semiFrozen then pcall(postClone) end
local okRelay = relayFlow(uid, started, releaseCamera, semiFrozen)
return okRelay
end

local function stealAndDeliver(uid, attempt)
attempt = attempt or 1
if state.Busy then return end
state.Busy = true state.Cancel = false state.Died = false
state.Hits = 0 state.Ragdoll = false
local tripChar = localPlayer.Character
task.spawn(function()
while state.Busy and alive do
task.wait(0.05)
local now = localPlayer.Character local hum = tripChar and tripChar:FindFirstChildOfClass("Humanoid")
if now ~= tripChar or not tripChar or (hum and hum.Health <= 0) then
if state.Busy and not state.Cancel then state.Died = true state.Cancel = true end
return
end
end
end)
task.spawn(function()
local delivered = false
local failReason = nil
local ok, err = pcall(function()
local egg = eggPosition(uid) if not egg then return end
if state.Carrying and state.Uid ~= uid then
dropEgg() local w = 0 while state.Carrying and w < 1 do w += RunService.Heartbeat:Wait() end
end
state.NestBack = false
local okS, info = semiGo(uid, egg)
if not okS then failReason = info return end
local inHand = state.Carrying and state.Uid == uid
local cur = egg if not inHand then cur = eggNow(uid, { At = 0, Pos = egg }) or egg end
if not (info.Arrived or inHand) then
if info.Plain then runToEgg(uid, cur)
elseif info.Decoy then runToEgg(uid, cur, { Field = true, Ratio = 1 })
else runToEgg(uid, cur, { Field = true, Ratio = info.Ratio or 1.1, Height = 50 }) end
end
if not (state.Carrying and state.Uid == uid) and not grab(uid, 4) then
failReason = "grab failed"
return
end
delivered = instantTP(uid)
if not delivered then failReason = state.NestBack and "nest" or "delivery failed" end
end)
dropClone()
if state.ReleaseCamera then pcall(state.ReleaseCamera) state.ReleaseCamera = nil end
semi.SlowRun = false semi.AtDrop = false semi.Plain = false
if state.Died then
local from = os.clock() while os.clock() - from < 15 and (localPlayer.Character == tripChar or not root()) do task.wait(0.1) end
local calm = os.clock() while os.clock() - calm < 2.5 and not (swapped() and os.clock() - calm > 1.5) do task.wait(0.1) end
if viewState then releaseView() end
elseif viewState then
if state.Cancel and semi.Home then releaseBackHome(semi.Home) else releaseView() end
end
semi.Kind, semi.Home = nil, nil
state.TripStartCF = nil
if semi.Rotate then local info = semi.Rotate semi.Rotate = nil pcall(function() info.Hum.AutoRotate = info.Old end) end
if not ok then failReason = failReason or tostring(err) end
local why0 = tostring(failReason or "")
local willRetry = not delivered and not state.Cancel and not state.Died and attempt < MAX_ATTEMPTS and not string.find(why0, "no character", 1, true)
if willRetry then
local function wait(t) local w = 0 while w < t and not state.Cancel do w += RunService.Heartbeat:Wait() end end
if state.Carrying then dropEgg() local w = 0 while state.Carrying and w < 1 and not state.Cancel do w += RunService.Heartbeat:Wait() end end
wait(0.6) if not state.Cancel then treadmillReset() wait(0.4) end
willRetry = not state.Cancel and not state.Died and root() ~= nil
end
state.Busy = false
cooldownUntil = os.clock() + COOLDOWN
if willRetry then stealAndDeliver(uid, attempt + 1) end
end)
end

local function parentGui()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then return result end
    end
    return localPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui
end
local function make(class, props) local i = Instance.new(class) for k, v in pairs(props or {}) do i[k] = v end return i end
local function corner(p, r) make("UICorner", { CornerRadius = UDim.new(0, r or 6) }).Parent = p end
local function text(p, props) props.BackgroundTransparency = 1 props.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255) local l = make("TextLabel", props) l.Parent = p return l end

-- Optional local graphics optimization. This is a reversible visual-quality
-- toggle; it does not change the game's frame-rate cap or gameplay state.
local Lighting = game:GetService("Lighting")
local fpsBoostEnabled = false
local fpsGeneration = 0
local fpsSaved = {}
local fpsConnections = {}
local qualitySettings, originalQuality = nil, nil

local function saveAndSet(instance, property, value)
    if not instance then return end
    local ok, original = pcall(function() return instance[property] end)
    if not ok then return end
    local saved = fpsSaved[instance]
    if not saved then
        saved = {}
        fpsSaved[instance] = saved
    end
    if saved[property] == nil then saved[property] = original end
    pcall(function() instance[property] = value end)
end

local function optimizeVisual(instance)
    if not instance then return end
    pcall(function()
        if instance:IsA("BasePart") then
            saveAndSet(instance, "CastShadow", false)
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
            or instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles")
            or instance:IsA("Light") or instance:IsA("PostEffect") then
            saveAndSet(instance, "Enabled", false)
        end
    end)
end

local function restoreFPSBoost()
    fpsGeneration += 1
    for _, connection in ipairs(fpsConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(fpsConnections)

    for instance, properties in pairs(fpsSaved) do
        for property, original in pairs(properties) do
            pcall(function() instance[property] = original end)
        end
    end
    table.clear(fpsSaved)

    if qualitySettings and originalQuality ~= nil then
        pcall(function() qualitySettings.QualityLevel = originalQuality end)
    end
    qualitySettings, originalQuality = nil, nil
    fpsBoostEnabled = false
end

local function setFPSBoost(enabled)
    enabled = enabled == true
    if fpsBoostEnabled == enabled then return true end

    if not enabled then
        restoreFPSBoost()
        return true
    end

    fpsBoostEnabled = true
    fpsGeneration += 1
    local myGeneration = fpsGeneration

    saveAndSet(Lighting, "GlobalShadows", false)
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then saveAndSet(terrain, "Decoration", false) end

    table.insert(fpsConnections, workspace.DescendantAdded:Connect(optimizeVisual))
    table.insert(fpsConnections, Lighting.DescendantAdded:Connect(optimizeVisual))

    pcall(function()
        qualitySettings = settings().Rendering
        originalQuality = qualitySettings.QualityLevel
        qualitySettings.QualityLevel = Enum.QualityLevel.Level01
    end)

    -- Spread the initial scan over several frames to avoid a large one-frame hitch.
    task.spawn(function()
        local containers = { workspace, Lighting }
        for _, container in ipairs(containers) do
            local descendants = container:GetDescendants()
            for index, instance in ipairs(descendants) do
                if not fpsBoostEnabled or fpsGeneration ~= myGeneration then return end
                optimizeVisual(instance)
                if index % 250 == 0 then task.wait() end
            end
        end
    end)
    return true
end

-- Remove current and legacy GUI instances before creating the new interface.
local guiParent = parentGui()
for _, guiName in ipairs({ "S2rHub", "SourcesHub", "quveg_insta" }) do
    local oldGui = guiParent:FindFirstChild(guiName)
    if oldGui then pcall(function() oldGui:Destroy() end) end
end

local gui = make("ScreenGui", { Name = "S2rHub", DisplayOrder = 200000, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true })
gui.Parent = guiParent

local W, H = 240, 130
local window = make("Frame", { 
    Size = UDim2.fromOffset(W, H), 
    Position = UDim2.new(0.5, -W/2, 0.5, -H/2), 
    BackgroundColor3 = Color3.fromRGB(10, 8, 18), 
    BorderSizePixel = 0 
})
window.Parent = gui 
corner(window, 12)
local windowStroke = make("UIStroke", {
    Color = Color3.fromRGB(91, 55, 150),
    Thickness = 1,
    Transparency = 0.18
})
windowStroke.Parent = window

-- Violet accent bar at top
local accentBar = make("Frame", {
    Size = UDim2.new(1, 0, 0, 3),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Color3.fromRGB(139, 92, 246),
    BorderSizePixel = 0
})
accentBar.Parent = window
corner(accentBar, 0)

-- Clean title: the old SourcesHub image asset has been removed completely.
local titleLabel = text(window, { 
    Size = UDim2.new(1, -16, 0, 18), 
    Position = UDim2.fromOffset(8, 8), 
    Font = Enum.Font.GothamBold, 
    TextSize = 11, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    Text = "S2rHub Instant Steal By Khay",
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local themeLabel = text(window, { 
    Size = UDim2.fromOffset(145, 14), 
    Position = UDim2.fromOffset(8, 30), 
    Font = Enum.Font.GothamMedium, 
    TextSize = 8, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    Text = "VIOLET  •  BLACK EDITION",
    TextColor3 = Color3.fromRGB(196, 181, 253)
})

-- Compact FPS control fits in the existing header; window dimensions stay unchanged.
local fpsBtn = make("TextButton", {
    Size = UDim2.fromOffset(78, 16),
    Position = UDim2.fromOffset(154, 29),
    BackgroundColor3 = Color3.fromRGB(38, 28, 58),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextColor3 = Color3.fromRGB(216, 202, 255),
    Text = "FPS BOOST OFF",
    AutoButtonColor = true
})
fpsBtn.Parent = window
corner(fpsBtn, 5)
local fpsBtnStroke = make("UIStroke", {
    Color = Color3.fromRGB(124, 78, 210),
    Thickness = 0.7,
    Transparency = 0.35
})
fpsBtnStroke.Parent = fpsBtn
fpsBtn.MouseButton1Click:Connect(function()
    local requestedState = not fpsBoostEnabled
    local ok = pcall(setFPSBoost, requestedState)
    if not ok then
        warn("S2rHub: FPS graphics toggle could not be applied.")
    end
    fpsBtn.Text = fpsBoostEnabled and "FPS BOOST ON" or "FPS BOOST OFF"
    fpsBtn.BackgroundColor3 = fpsBoostEnabled and Color3.fromRGB(91, 43, 166) or Color3.fromRGB(38, 28, 58)
    fpsBtn.TextColor3 = fpsBoostEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(216, 202, 255)
end)

-- Info card
local infoCard = make("TextButton", { 
    Size = UDim2.new(1, -12, 0, 42), 
    Position = UDim2.fromOffset(6, 48), 
    BackgroundColor3 = Color3.fromRGB(25, 18, 40), 
    BorderSizePixel = 0, 
    Text = "", 
    AutoButtonColor = true 
})
infoCard.Parent = window 
corner(infoCard, 8)
local infoStroke = make("UIStroke", {
    Color = Color3.fromRGB(83, 55, 126),
    Thickness = 0.7,
    Transparency = 0.42
})
infoStroke.Parent = infoCard

-- Violet left border on info card
local cardAccent = make("Frame", {
    Size = UDim2.new(0, 3, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Color3.fromRGB(139, 92, 246),
    BorderSizePixel = 0
})
cardAccent.Parent = infoCard
corner(cardAccent, 0)

local iconLabel = make("ImageLabel", { 
    Size = UDim2.fromOffset(32, 32), 
    Position = UDim2.fromOffset(10, 5), 
    BackgroundTransparency = 1, 
    ScaleType = Enum.ScaleType.Fit 
})
iconLabel.Parent = infoCard

local nameLabel = text(infoCard, { 
    Size = UDim2.new(1, -48, 0, 16), 
    Position = UDim2.fromOffset(46, 5), 
    Font = Enum.Font.GothamBold, 
    TextSize = 11, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    Text = "No best egg" 
})

local valueLabel = text(infoCard, { 
    Size = UDim2.new(1, -48, 0, 14), 
    Position = UDim2.fromOffset(46, 23), 
    Font = Enum.Font.GothamMedium, 
    TextSize = 10, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    Text = "$0/s", 
    TextColor3 = Color3.fromRGB(167, 139, 250) 
})

-- Steal button (red)
local stealBtn = make("TextButton", { 
    Size = UDim2.new(1, -12, 0, 26), 
    Position = UDim2.fromOffset(6, 96), 
    BackgroundColor3 = Color3.fromRGB(124, 58, 237), 
    Font = Enum.Font.GothamBold, 
    TextSize = 13, 
    TextColor3 = Color3.fromRGB(255, 255, 255), 
    Text = "Steal", 
    AutoButtonColor = true 
})
stealBtn.Parent = window 
corner(stealBtn, 6)

-- List window
local listWindow = make("Frame", { 
    Size = UDim2.fromOffset(240, 170), 
    Position = UDim2.new(1, 8, 0, 0), 
    BackgroundColor3 = Color3.fromRGB(10, 8, 18), 
    BorderSizePixel = 0, 
    Visible = false 
})
listWindow.Parent = window 
corner(listWindow, 12)

local listScroll = make("ScrollingFrame", { 
    Size = UDim2.new(1, -8, 1, -8), 
    Position = UDim2.fromOffset(4, 4), 
    BackgroundTransparency = 1, 
    BorderSizePixel = 0, 
    ScrollBarThickness = 3, 
    ScrollBarImageColor3 = Color3.fromRGB(139, 92, 246),
    CanvasSize = UDim2.new(), 
    AutomaticCanvasSize = Enum.AutomaticSize.Y 
})
listScroll.Parent = listWindow
make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = listScroll

local selectedUid, bestUid, listOpen, manualSelected = nil, nil, false, false
local renderedListSignature = nil
infoCard.MouseButton1Click:Connect(function() listOpen = not listOpen listWindow.Visible = listOpen end)

local function updateBestEgg()
local infos = {}
for _, rec in ipairs(snapshot()) do infos[#infos + 1] = describe(rec) end
table.sort(infos, function(a, b) return a.Value > b.Value end)
local best = infos[1]
bestUid = best and best.Uid or nil

local selectedInfo = nil
if manualSelected and selectedUid then
    for _, info in ipairs(infos) do
        if info.Uid == selectedUid then selectedInfo = info break end
    end
    if not selectedInfo then
        manualSelected = false
        selectedUid = nil
    end
end

if manualSelected and selectedInfo then
    nameLabel.Text = selectedInfo.Name
    valueLabel.Text = money(selectedInfo.Value)
    iconLabel.Image = selectedInfo.Icon
elseif best then
    selectedUid = best.Uid
    nameLabel.Text = best.Name
    valueLabel.Text = money(best.Value)
    iconLabel.Image = best.Icon
else
    selectedUid = nil
    nameLabel.Text = "No eggs found"
    valueLabel.Text = "$0/s"
    iconLabel.Image = ""
end
if listOpen then
local signatureParts = {}
for _, info in ipairs(infos) do
    signatureParts[#signatureParts + 1] = table.concat({ tostring(info.Uid), info.Name, tostring(info.Value), info.Icon }, "|")
end
local listSignature = table.concat(signatureParts, "\n")
if listSignature ~= renderedListSignature then
renderedListSignature = listSignature
for _, c in ipairs(listScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
for i, info in ipairs(infos) do
local row = make("TextButton", { 
    Size = UDim2.new(1, 0, 0, 32), 
    BackgroundColor3 = Color3.fromRGB(25, 18, 40), 
    LayoutOrder = i, 
    Text = "", 
    AutoButtonColor = true 
})
row.Parent = listScroll 
corner(row, 6)

-- Red accent on list rows
local rowAccent = make("Frame", {
    Size = UDim2.new(0, 2, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Color3.fromRGB(139, 92, 246),
    BorderSizePixel = 0
})
rowAccent.Parent = row

make("ImageLabel", { 
    Size = UDim2.fromOffset(22, 22), 
    Position = UDim2.fromOffset(8, 5), 
    BackgroundTransparency = 1, 
    Image = info.Icon, 
    ScaleType = Enum.ScaleType.Fit 
}).Parent = row

text(row, { 
    Size = UDim2.new(1, -36, 0, 14), 
    Position = UDim2.fromOffset(34, 3), 
    Font = Enum.Font.GothamBold, 
    TextSize = 10, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    Text = info.Name 
})
text(row, { 
    Size = UDim2.new(1, -36, 0, 12), 
    Position = UDim2.fromOffset(34, 17), 
    Font = Enum.Font.GothamMedium, 
    TextSize = 9, 
    TextXAlignment = Enum.TextXAlignment.Left, 
    Text = money(info.Value), 
    TextColor3 = Color3.fromRGB(167, 139, 250) 
})

row.MouseButton1Click:Connect(function()
selectedUid = info.Uid 
manualSelected = true 
nameLabel.Text = info.Name 
valueLabel.Text = money(info.Value) 
iconLabel.Image = info.Icon
listOpen = false 
listWindow.Visible = false
end)
end
end
end
end

task.spawn(function() while gui.Parent do pcall(updateBestEgg) task.wait(1) end end)

stealBtn.MouseButton1Click:Connect(function()
if state.Busy then state.Cancel = true return end
if os.clock() < cooldownUntil then return end
local target = selectedUid or bestUid
if target then stealAndDeliver(target) end
end)

task.spawn(function()
while gui.Parent do
task.wait(0.1)
if state.Busy then
stealBtn.Text = "Cancel" 
stealBtn.BackgroundColor3 = Color3.fromRGB(65, 40, 105) 
stealBtn.AutoButtonColor = true
elseif os.clock() < cooldownUntil then
local remaining = math.max(0, cooldownUntil - os.clock())
stealBtn.Text = string.format("Wait %.1fs", remaining)
stealBtn.BackgroundColor3 = Color3.fromRGB(36, 24, 55)
stealBtn.AutoButtonColor = false
else
stealBtn.Text = "Steal" 
stealBtn.BackgroundColor3 = Color3.fromRGB(124, 58, 237) 
stealBtn.AutoButtonColor = true
end
end
end)

local dragConnections = {}
do
local dragging, startPos, startInput
table.insert(dragConnections, window.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
dragging, startPos, startInput = true, window.Position, input.Position 
end
end))
table.insert(dragConnections, UserInputService.InputChanged:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local d = input.Position - startInput
window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end
end))
table.insert(dragConnections, UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
dragging = false 
end
end))
end

gui.Destroying:Connect(function()
    alive = false
    state.Cancel = true

    if fpsBoostEnabled then pcall(setFPSBoost, false) end
    if viewState then pcall(releaseView) end
    if state.ReleaseCamera then
        pcall(state.ReleaseCamera)
        state.ReleaseCamera = nil
    end
    pcall(dropClone)
    pcall(shieldStop)

    for _, connection in ipairs(sessionConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(sessionConnections)

    for _, connection in ipairs(dragConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(dragConnections)
end)

shieldStart()
