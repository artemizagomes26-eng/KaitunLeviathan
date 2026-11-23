if getgenv and getgenv().QuantumKaitunLoaded and not (getgenv().ForceReload) then
    print("[Quantum Kaitun] Already loaded. Set getgenv().ForceReload = true to reload.")
    return
end

local G = (getgenv and getgenv()) or _G
G.ForceReload = false
G.QuantumKaitunLoaded = true

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local RootPart = Character:FindFirstChild("HumanoidRootPart")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local Modules = ReplicatedStorage:FindFirstChild("Modules")
local Net = Modules and Modules:FindFirstChild("Net")

local CommF = Remotes and Remotes:FindFirstChild("CommF_")
local CommE = Remotes and Remotes:FindFirstChild("CommE")
local Validator2 = Remotes and Remotes:FindFirstChild("Validator2")
local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit = Net and Net:FindFirstChild("RE/RegisterHit")
local ShootGunEvent = Net and Net:FindFirstChild("RE/ShootGunEvent")
local SeedRemote = Net and Net:FindFirstChild("seed")

local Defaults = {
    FullyLeviathan = false,
    AutoFindLeviathan = false,
    IgnoreSeaEvents = true,
    FastAttack = true,
    FastAttackDelay = 0.3,
    AutoShootGun = true,
    DragonstormMode = "Spread Damage",
    BribeSpy = true,
    AutoSailBackTiki = true,
    AutoHaki = true,
    AutoSkills = true,
    AttackRange = 500,
    BoatSpeed = 220,
    ShowStatus = true,
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookInterval = 60,
    MenuKeybind = "G",
}

local ConfigKeys = {}
for key in pairs(Defaults) do
    ConfigKeys[#ConfigKeys + 1] = key
end
table.sort(ConfigKeys)
for _, key in ipairs(ConfigKeys) do
    if G[key] == nil then G[key] = Defaults[key] end
end

local ConfigFolder = "QuantumKaitun"
local ConfigFile = ConfigFolder .. "/" .. tostring(LocalPlayer.Name):gsub("[^%w_%-]", "_") .. "_leviathan.json"

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = deepCopy(v) end
    return copy
end

local function saveConfig()
    if type(makefolder) ~= "function" or type(writefile) ~= "function" then return end
    pcall(function()
        if type(isfolder) == "function" and not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        local data = {}
        for _, key in ipairs(ConfigKeys) do
            if G[key] ~= nil then data[key] = deepCopy(G[key]) end
        end
        writefile(ConfigFile, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    pcall(function()
        if not isfile(ConfigFile) then return end
        local raw = readfile(ConfigFile)
        if type(raw) ~= "string" or raw == "" then return end
        local data = HttpService:JSONDecode(raw)
        if type(data) ~= "table" then return end
        for _, key in ipairs(ConfigKeys) do
            if data[key] ~= nil then G[key] = data[key] end
        end
    end)
end

loadConfig()

local StatusText = "Ready"
local StatusListeners = {}
local SendNotify = function() end

local function setStatus(text)
    StatusText = tostring(text)
    for _, fn in ipairs(StatusListeners) do pcall(fn, StatusText) end
end

local function notify(title, content)
    pcall(SendNotify, title, content)
end

local function refreshRemotes()
    Remotes = Remotes or ReplicatedStorage:FindFirstChild("Remotes")
    Modules = Modules or ReplicatedStorage:FindFirstChild("Modules")
    Net = Net or (Modules and Modules:FindFirstChild("Net"))
    CommF = CommF or (Remotes and Remotes:FindFirstChild("CommF_"))
    CommE = CommE or (Remotes and Remotes:FindFirstChild("CommE"))
    Validator2 = Validator2 or (Remotes and Remotes:FindFirstChild("Validator2"))
    RegisterAttack = RegisterAttack or (Net and Net:FindFirstChild("RE/RegisterAttack"))
    RegisterHit = RegisterHit or (Net and Net:FindFirstChild("RE/RegisterHit"))
    ShootGunEvent = ShootGunEvent or (Net and Net:FindFirstChild("RE/ShootGunEvent"))
    SeedRemote = SeedRemote or (Net and Net:FindFirstChild("seed"))
end

refreshRemotes()

local function getParts()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local NoclipOn = false
local LastNoclip = 0

local function noClip(enabled)
    local char, hrp, hum = getParts()
    if not char or not hrp or not hum or hum.Health <= 0 then return end
    if enabled then
        if NoclipOn and os.clock() - LastNoclip < 0.5 then return end
        NoclipOn = true
        LastNoclip = os.clock()
    else
        NoclipOn = false
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not enabled end
    end
end

local TWEEN_PART = "QuantumKaitunTween"
local CurrentTween = nil
local Tweening = false
local HoldCFrame = nil
local LiveHold = nil
local AttackTarget = nil
local AttackStand = nil

local function getTweenPart()
    local part = workspace:FindFirstChild(TWEEN_PART)
    if part and part:IsA("BasePart") then return part end
    part = Instance.new("Part")
    part.Name = TWEEN_PART
    part.Size = Vector3.new(1, 1, 1)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Transparency = 1
    part.Parent = workspace
    return part
end

local function clearHover()
    HoldCFrame = nil
    LiveHold = nil
end

local function resolveTarget(target)
    if typeof(target) == "function" then
        local ok, result = pcall(target)
        if ok and result then return result, target end
        return nil, nil
    elseif typeof(target) == "Vector3" then
        return CFrame.new(target), nil
    elseif typeof(target) == "CFrame" then
        return target, nil
    elseif typeof(target) == "Instance" and target:IsA("BasePart") then
        return target.CFrame, nil
    end
    return nil, nil
end

local function tweenTo(target, abortCheck)
    local startChar = LocalPlayer.Character
    local _, startHRP = getParts()
    if not startHRP or G.StopTween then return false end
    local targetCF, live = resolveTarget(target)
    if not targetCF or targetCF.Position.Y < 0 then return false end
    HoldCFrame, LiveHold = nil, nil
    local _, _, startHum = getParts()
    if startHum and (startHum.Sit or startHum.SeatPart) then
        pcall(function()
            startHum.Sit = false
            startHum.PlatformStand = false
            startHRP.CFrame = startHRP.CFrame + Vector3.new(0, 8, 0)
        end)
        task.wait(0.2)
    end
    local part = getTweenPart()
    part.CFrame = startHRP.CFrame
    noClip(true)
    if CurrentTween then pcall(function() CurrentTween:Cancel() end) end
    local tween = nil
    if not live then
        local distance = (targetCF.Position - startHRP.Position).Magnitude
        tween = TweenService:Create(part, TweenInfo.new(math.max(distance / 280, 0.05), Enum.EasingStyle.Linear), { CFrame = targetCF })
        CurrentTween = tween
    end
    Tweening = true
    local aborted, arrived, seated = false, false, false
    local nextAbort = 0
    local connection = RunService.Stepped:Connect(function(_, dt)
        local char, hrp, hum = getParts()
        if not hrp or char ~= startChar or not hum or hum.Health <= 0 or hrp.Position.Y < 0 then
            aborted = true
            if tween then pcall(function() tween:Cancel() end) end
            return
        end
        if hum.SeatPart then
            seated = true
            arrived = true
            if tween then pcall(function() tween:Cancel() end) end
            return
        end
        if live then
            local goal = resolveTarget(live)
            if not goal or goal.Position.Y < 0 then
                aborted = true
            else
                local delta = goal.Position - part.Position
                local dist = delta.Magnitude
                if dist <= 5 then
                    arrived = true
                else
                    part.CFrame = CFrame.new(part.Position + delta.Unit * math.min(dist, 280 * dt))
                        * (part.CFrame - part.CFrame.Position)
                end
            end
        end
        if not aborted and not seated then
            hrp.CFrame = part.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        if abortCheck and not aborted and tick() >= nextAbort then
            nextAbort = tick() + 0.1
            local ok, stop = pcall(abortCheck)
            if ok and stop then aborted = true end
        end
    end)
    pcall(function()
        if live then
            local timeout = tick() + 30
            repeat task.wait() until arrived or aborted or tick() > timeout
        elseif tween then
            tween:Play()
            repeat task.wait() until seated or aborted or tween.PlaybackState ~= Enum.PlaybackState.Playing
        end
    end)
    pcall(function() connection:Disconnect() end)
    if tween and CurrentTween == tween then CurrentTween = nil end
    Tweening = false
    if not aborted and not seated then
        if live then LiveHold = live else HoldCFrame = targetCF end
    end
    return not aborted
end

local function stopTween()
    G.StopTween = true
    if CurrentTween then pcall(function() CurrentTween:Cancel() end) end
    CurrentTween = nil
    Tweening = false
    noClip(false)
    clearHover()
    task.defer(function() task.wait(0.1) G.StopTween = false end)
end

RunService.Heartbeat:Connect(function(dt)
    if G.StopTween then return end
    local _, hrp, hum = getParts()
    if not hrp or (hum and hum.SeatPart) or Tweening then return end
    if CurrentTween and CurrentTween.PlaybackState == Enum.PlaybackState.Playing then return end
    local goal
    if AttackTarget then
        if not AttackTarget.Parent then
            AttackTarget, AttackStand = nil, nil
        else
            local ok, cf = pcall(AttackStand)
            if ok and cf and cf.Position.Y >= 0 then goal = cf end
        end
    end
    if not goal and LiveHold then
        local ok, cf = pcall(LiveHold)
        if ok and cf then
            if cf.Position.Y < 0 then clearHover() return end
            goal = cf
        end
    end
    if not goal then goal = HoldCFrame end
    if not goal or goal.Position.Y < 0 then clearHover() return end
    if not LiveHold then HoldCFrame = goal end
    hrp.AssemblyLinearVelocity = Vector3.zero
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    local dist = (goal.Position - hrp.Position).Magnitude
    if dist <= 3 then
        hrp.CFrame = goal
    else
        hrp.CFrame = hrp.CFrame:Lerp(goal, math.min(dist, 280 * (dt or 1 / 60)) / dist)
    end
end)

local function liveCF(cf)
    return function() return cf end
end

local function modelRoot(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head")
        or model:FindFirstChildWhichIsA("BasePart", true)
end

local function isAlive(model)
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    local health = model:FindFirstChild("Health")
    if health and health:IsA("ValueBase") and health.Value <= 0 then return false end
    return hum ~= nil or (health and health:IsA("ValueBase")) or true
end

local function findLeviathan()
    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
    if not seaBeasts then return nil, nil end
    for _, child in ipairs(seaBeasts:GetChildren()) do
        if child.Name == "Leviathan Segment" and isAlive(child) then
            local root = modelRoot(child)
            if root then return child, root end
        end
    end
    for _, child in ipairs(seaBeasts:GetChildren()) do
        if child.Name == "Leviathan" and isAlive(child) then
            local root = modelRoot(child)
            if root then return child, root end
        end
    end
    return nil, nil
end

local function leviathanExists()
    return findLeviathan() ~= nil
end

local function facePosition(position)
    local _, hrp, hum = getParts()
    if not hrp or not position then return end
    if hum and (hum.Sit or hum.SeatPart) then return end
    local flat = Vector3.new(position.X - hrp.Position.X, 0, position.Z - hrp.Position.Z)
    if flat.Magnitude < 0.5 then return end
    pcall(function()
        hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat.Unit)
    end)
end

local function attackCFrameFrom(origin, target)
    if not origin or not target then return nil end
    local delta = target - origin
    if delta.Magnitude < 0.1 then return nil end
    return CFrame.lookAt(origin, origin + delta.Unit)
end

local function findToolByTooltip(tooltip)
    local char, _, hum = getParts()
    if not char or not hum or not LocalPlayer.Backpack then return nil end
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and equipped.ToolTip == tooltip then return equipped end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == tooltip then return tool end
    end
    return nil
end

local function equipTooltip(tooltip)
    local _, _, hum = getParts()
    local tool = findToolByTooltip(tooltip)
    if tool and hum then pcall(function() hum:EquipTool(tool) end) end
    return tool
end

local function pressKey(key)
    local code = key == "Space" and Enum.KeyCode.Space or Enum.KeyCode[tostring(key):upper()]
    if not code then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, code, false, game)
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(false, code, false, game)
    end)
end

local function autoHaki()
    if not G.AutoHaki or not CommF then return end
    local char = getParts()
    if char and not char:FindFirstChild("HasBuso") then
        pcall(function() CommF:InvokeServer("Buso") end)
    end
end

local function autoSkills()
    if not G.AutoSkills then return end
    local char, hrp, hum = getParts()
    if not char or not hrp or not hum or hum.Health <= 0 then return end
    for _, tooltip in ipairs({ "Melee", "Sword", "Blox Fruit" }) do
        local tool = findToolByTooltip(tooltip)
        if tool then
            equipTooltip(tooltip)
            pressKey("Z")
            pressKey("X")
            if tooltip ~= "Blox Fruit" then pressKey("C") end
            break
        end
    end
end

local HitCache = nil
local HitOrigin = nil
local HitAt = 0

local function buildHitList(origin, range)
    local now = os.clock()
    if HitCache and HitOrigin and now - HitAt < 0.08 and (origin - HitOrigin).Magnitude < 30 then
        return HitCache
    end
    local list = HitCache or {}
    table.clear(list)
    range = range or G.AttackRange
    local folders = { workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("SeaBeasts"), workspace:FindFirstChild("Characters") }
    for _, folder in ipairs(folders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model ~= LocalPlayer.Character and isAlive(model) then
                    local root = modelRoot(model)
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if root then
                        local dist = (origin - root.Position).Magnitude
                        if dist <= range then
                            local part = model:FindFirstChild("Head") or root
                            if part and part:IsA("BasePart") then
                                list[#list + 1] = { model = model, part = part, root = root, distance = dist }
                            end
                        end
                    elseif hum and hum.Health > 0 then
                        local head = model:FindFirstChild("Head")
                        if head then
                            local dist = (origin - head.Position).Magnitude
                            if dist <= range then
                                list[#list + 1] = { model = model, part = head, root = head, distance = dist }
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    HitCache, HitOrigin, HitAt = list, origin, now
    return list
end

local function attackToken()
    return tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
end

local function fastAttack()
    refreshRemotes()
    if not G.FastAttack then return end
    local char, hrp, hum = getParts()
    if not char or not hrp or not hum or hum.Health <= 0 then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.ToolTip == "Gun" then
        tool = equipTooltip("Melee") or equipTooltip("Sword") or equipTooltip("Blox Fruit")
        if not tool then return end
    end
    local hits = buildHitList(hrp.Position, G.AttackRange)
    if #hits == 0 then return end
    local target = hits[1]
    facePosition(target.root.Position)
    if RegisterAttack then
        pcall(function() RegisterAttack:FireServer(G.FastAttackDelay or 0.3) end)
    end
    if RegisterHit then
        local parts = {}
        for _, hit in ipairs(hits) do
            parts[#parts + 1] = { hit.model, hit.part }
        end
        pcall(function()
            RegisterHit:FireServer(target.part, parts, nil, nil, attackToken())
        end)
    end
    autoHaki()
end

local shootFunc = nil
local upvalueIndex = {}
local validatorReady = false

local function initDragonRuntime()
    if validatorReady then return end
    pcall(function()
        local controller = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CombatController"))
        for _, value in ipairs(debug.getupvalues(controller.Attack)) do
            if type(value) == "function" then
                for index, up in ipairs(debug.getupvalues(value)) do
                    if up == 727595 then
                        shootFunc = value
                        upvalueIndex = {
                            u25 = index - 3, u21 = index - 2, u24 = index - 1,
                            u20 = index, u22 = index + 1, u23 = index + 2, u26 = index + 3,
                        }
                        break
                    end
                end
                if shootFunc then break end
            end
        end
    end)
    validatorReady = shootFunc ~= nil
end

local function fireDragonValidator()
    if not shootFunc or not Validator2 then return false end
    local ok = pcall(function()
        local u20 = debug.getupvalue(shootFunc, upvalueIndex.u20)
        local u21 = debug.getupvalue(shootFunc, upvalueIndex.u21)
        local u22 = debug.getupvalue(shootFunc, upvalueIndex.u22)
        local u23 = debug.getupvalue(shootFunc, upvalueIndex.u23)
        local u24 = debug.getupvalue(shootFunc, upvalueIndex.u24)
        local u25 = debug.getupvalue(shootFunc, upvalueIndex.u25)
        local u26 = debug.getupvalue(shootFunc, upvalueIndex.u26)
        local u79 = u25 * u21
        local u80 = (u24 * u21 + u25 * u20) % u22
        u80 = (u80 * u22 + u79) % u23
        u24 = math.floor(u80 / u22)
        u25 = u80 - u24 * u22
        u26 = u26 + 1
        debug.setupvalue(shootFunc, upvalueIndex.u24, u24)
        debug.setupvalue(shootFunc, upvalueIndex.u25, u25)
        debug.setupvalue(shootFunc, upvalueIndex.u26, u26)
        Validator2:FireServer(math.floor(u80 / u23 * 16777215), u26)
    end)
    return ok
end

local function autoShootGun()
    refreshRemotes()
    if not G.AutoShootGun then return end
    local char, hrp, hum = getParts()
    if not char or not hrp or not hum or hum.Health <= 0 then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "Dragonstorm" then
        local dragon = nil
        if LocalPlayer.Backpack then
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                if item.Name == "Dragonstorm" then dragon = item break end
            end
        end
        if not dragon then
            if CommF then pcall(function() CommF:InvokeServer("CraftPrehistoricItem", "Dragonstorm") end) end
            return
        end
        pcall(function() hum:EquipTool(dragon) end)
        return
    end
    local hits = buildHitList(hrp.Position, 900)
    if #hits == 0 then return end
    local target = hits[1]
    facePosition(target.root.Position)
    initDragonRuntime()
    if not fireDragonValidator() then return end
    if ShootGunEvent then
        local count = G.DragonstormMode == "Single Damage" and 1 or 3
        for _ = 1, count do
            pcall(function() ShootGunEvent:FireServer(target.root.Position, { target.part }) end)
        end
    end
    autoHaki()
end

local bribeCache, bribeCacheAt = nil, 0

local function bribeStatus()
    if bribeCache and os.clock() - bribeCacheAt < 2 then return bribeCache end
    if not CommF then return nil end
    local ok, result = pcall(function() return CommF:InvokeServer("InfoLeviathan", "1") end)
    if not ok then return nil end
    local n = tonumber(result)
    bribeCache = n or 5
    bribeCacheAt = os.clock()
    return bribeCache
end

local function bribeSpy()
    if not G.BribeSpy or not CommF then return end
    local status = bribeStatus()
    if status == nil or status == -1 or status == 5 then return end
    for _ = 1, 4 do
        setStatus("Bribing the Spy")
        pcall(function() CommF:InvokeServer("InfoLeviathan", "2") end)
        task.wait(0.4)
        status = bribeStatus()
        if status == nil or status == -1 or status == 5 then return end
    end
end

local TikiCF = CFrame.new(-16206.9014, 7.75799561, 404.552002)
local BoatDealerCF = CFrame.new(-16917.1523, 8.59936905, 511.799042)
local CruiseFar = CFrame.new(-9000000000, 30.0003, -1244.8584)

local function getOwnBoat()
    local boats = workspace:FindFirstChild("Boats")
    if not boats then return nil end
    for _, boat in ipairs(boats:GetChildren()) do
        local owner = boat:FindFirstChild("Owner")
        if owner and tostring(owner.Value) == LocalPlayer.Name then return boat end
    end
    return nil
end

local function isSeated(seat)
    local _, _, hum = getParts()
    return hum ~= nil and seat ~= nil and seat.Parent ~= nil and hum.SeatPart == seat
end

local function unseat()
    local _, hrp, hum = getParts()
    if not hum then return true end
    for _ = 1, 3 do
        if not hum.Sit and hum.SeatPart == nil then return true end
        pcall(function()
            local char = LocalPlayer.Character
            local seat = hum.SeatPart
            if char and seat and seat.Parent then
                local weld = seat:FindFirstChild("SeatWeld")
                local p1 = weld and weld.Part1
                if weld and ((not p1) or (p1:IsA("BasePart") and p1:IsDescendantOf(char))) then
                    weld:Destroy()
                end
            end
            hum.Sit = false
            hum.PlatformStand = false
            if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 8, 0) end
        end)
        task.wait(0.25)
    end
    return false
end

local function boardSeat(seat)
    if not seat or not seat.Parent then return false end
    local deadline = os.clock() + 12
    while G.FullyLeviathan and os.clock() < deadline do
        if isSeated(seat) then return true end
        if not seat or not seat.Parent then return false end
        local _, hrp, hum = getParts()
        if hum and (hum.Sit or hum.SeatPart) then unseat() end
        if hrp then
            tweenTo(function()
                if seat and seat.Parent then return seat.CFrame * CFrame.new(0, 2, 0) end
                return nil
            end, function()
                local _, _, nowHum = getParts()
                return nowHum ~= nil and nowHum.SeatPart ~= nil
            end)
        end
        task.wait(0.2)
    end
    return isSeated(seat)
end

local function buyBoat()
    if not CommF then return false end
    unseat()
    local deadline = os.clock() + 60
    while G.FullyLeviathan and os.clock() < deadline do
        local _, hrp = getParts()
        if hrp and (hrp.Position - BoatDealerCF.Position).Magnitude < 20 then break end
        tweenTo(liveCF(BoatDealerCF))
        task.wait(0.3)
    end
    pcall(function() CommF:InvokeServer("BuyBoat", "Beast Hunter") end)
    task.wait(1)
    return getOwnBoat() ~= nil
end

local function steerAngle(seat, targetPos)
    local look = (seat.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
    local toTarget = ((targetPos - seat.Position) * Vector3.new(1, 0, 1)).Unit
    local angle = math.deg(math.acos(math.clamp(look:Dot(toTarget), -1, 1)))
    if look:Cross(toTarget).Y < 0 then angle = -angle end
    return angle
end

local function steerTo(seat, targetPos, speed)
    local start = os.clock()
    local lastPos = seat.Position
    local lastCheck = os.clock()
    local stalls = 0
    while G.FullyLeviathan and os.clock() - start < 600 do
        if not seat or not seat.Parent or not isSeated(seat) then return false end
        local pos = seat.Position
        local flat = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
        local dist = flat.Magnitude
        setStatus("Sailing back to Tiki (" .. math.floor(dist) .. "m)")
        if dist <= 40 then return true end
        if os.clock() - lastCheck >= 30 then
            if (pos - lastPos).Magnitude < 200 then
                stalls = stalls + 1
                if stalls >= 2 then return false end
                unseat()
                task.wait(0.3)
                if not boardSeat(seat) then return false end
            else
                stalls = 0
            end
            lastPos, lastCheck = pos, os.clock()
        end
        local angle = steerAngle(seat, targetPos)
        pcall(function()
            seat.MaxSpeed = speed
            seat.TurnSpeed = speed
            if math.abs(angle) > 8 then
                seat.CFrame = CFrame.lookAt(pos, Vector3.new(targetPos.X, pos.Y, targetPos.Z))
                seat.Throttle = 0.2
                seat.ThrottleFloat = 0.2
            else
                seat.Throttle = 1
                seat.ThrottleFloat = 1
            end
        end)
        task.wait()
    end
    pcall(function()
        seat.Throttle = 0
        seat.ThrottleFloat = 0
    end)
    return false
end

local function sailBackToTiki()
    if not G.AutoSailBackTiki then return false end
    local boat = getOwnBoat() or (buyBoat() and getOwnBoat())
    if not boat then return false end
    local seat = boat:FindFirstChild("VehicleSeat")
    if not seat or not boardSeat(seat) then return false end
    return steerTo(seat, TikiCF.Position, G.BoatSpeed or 220)
end

local function fightLeviathan()
    local model, root = findLeviathan()
    if not model or not root then return false end
    setStatus("Fighting Leviathan")
    while G.FullyLeviathan and isAlive(model) do
        local _, hrp, hum = getParts()
        if not hrp or not hum or hum.Health <= 0 then return false end
        if hum.Sit or hum.SeatPart then unseat() end
        local current, currentRoot = findLeviathan()
        if not current then break end
        model, root = current, currentRoot
        local stand = Vector3.new(root.Position.X, math.max(root.Position.Y + 40, 80), root.Position.Z)
        AttackTarget = model
        AttackStand = function()
            if not model or not model.Parent or not isAlive(model) then return nil end
            local r = modelRoot(model)
            if not r then return nil end
            local p = Vector3.new(r.Position.X, math.max(r.Position.Y + 40, 80), r.Position.Z)
            local flat = Vector3.new(r.Position.X - p.X, 0, r.Position.Z - p.Z)
            if flat.Magnitude < 0.5 then return CFrame.new(p) end
            return CFrame.lookAt(p, p + flat.Unit)
        end
        if (stand - hrp.Position).Magnitude > 12 then
            tweenTo(AttackStand, function() return not G.FullyLeviathan or not model or not model.Parent end)
        end
        if G.AutoShootGun and findToolByTooltip("Gun") then
            autoShootGun()
        else
            fastAttack()
            autoSkills()
        end
        autoHaki()
        task.wait(0.08)
    end
    AttackTarget, AttackStand = nil, nil
    return true
end

local function findBoatAndSail()
    local boat = getOwnBoat() or (buyBoat() and getOwnBoat())
    if not boat then return false end
    local seat = boat:FindFirstChild("VehicleSeat")
    if not seat or not boardSeat(seat) then return false end
    noClip(true)
    local lastCheck = 0
    while G.FullyLeviathan do
        if leviathanExists() then return true end
        if not seat or not seat.Parent or not isSeated(seat) then
            boat = getOwnBoat()
            seat = boat and boat:FindFirstChild("VehicleSeat")
            if not seat or not boardSeat(seat) then return false end
        end
        if os.clock() - lastCheck >= 0.3 then
            lastCheck = os.clock()
            setStatus("Searching for Leviathan")
        end
        local _, hrp = getParts()
        if not hrp then break end
        local target = G.AutoSailBackTiki and CruiseFar or CruiseFar
        local flat = Vector3.new(target.Position.X - hrp.Position.X, 0, target.Position.Z - hrp.Position.Z)
        if flat.Magnitude > 0 then
            local step = math.min(flat.Magnitude, (G.BoatSpeed or 220) * RunService.Heartbeat:Wait())
            local np = hrp.Position + flat.Unit * step
            pcall(function()
                hrp.CFrame = CFrame.lookAt(Vector3.new(np.X, 120, np.Z), Vector3.new(np.X, 120, np.Z - 1))
                hrp.AssemblyLinearVelocity = Vector3.zero
            end)
        end
    end
    return false
end

local function gateFound()
    local map = workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("LeviathanGate") then return true end
    local origin = ReplicatedStorage:FindFirstChild("WorldOrigin")
    local locations = origin and origin:FindFirstChild("Locations")
    return locations ~= nil and locations:FindFirstChild("Frozen Dimension") ~= nil
end

local LoopGeneration = 0
local Respawning = false

local function mainLeviathanLoop(generation)
    while G.FullyLeviathan and generation == LoopGeneration and not Respawning do
        if leviathanExists() or gateFound() then
            bribeSpy()
            if not unseat() then
                setStatus("Unable to leave the boat")
            end
            fightLeviathan()
            if G.AutoSailBackTiki then sailBackToTiki() end
            if G.FullyLeviathan then
                setStatus("Waiting for the next Leviathan")
                task.wait(5)
            end
        else
            local _, huntHRP = getParts()
            if not G.IgnoreSeaEvents and huntHRP then
                local hits = buildHitList(huntHRP.Position, 900)
                if #hits > 0 then
                    fastAttack()
                    autoShootGun()
                end
            end
            if G.AutoFindLeviathan then
                findBoatAndSail()
            else
                task.wait(1)
            end
        end
        task.wait(0.2)
    end
end

local function startLoops()
    if not G.FullyLeviathan or Respawning then return end
    LoopGeneration = LoopGeneration + 1
    local generation = LoopGeneration
    task.spawn(function() mainLeviathanLoop(generation) end)
    task.spawn(function()
        while G.FullyLeviathan and generation == LoopGeneration and not Respawning do
            if not getParts() or not isSeated(getOwnBoat() and getOwnBoat():FindFirstChild("VehicleSeat") or nil) then
                fastAttack()
            end
            task.wait(G.FastAttack and 0.12 or 0.5)
        end
    end)
    task.spawn(function()
        while G.FullyLeviathan and generation == LoopGeneration and not Respawning do
            local _, _, hum = getParts()
            if hum and hum.SeatPart == nil then autoSkills() end
            task.wait(0.8)
        end
    end)
end

local function stopLoops()
    LoopGeneration = LoopGeneration + 1
    stopTween()
    noClip(false)
    AttackTarget, AttackStand = nil, nil
end

local function onDeath()
    Respawning = true
    stopTween()
    clearHover()
    AttackTarget, AttackStand = nil, nil
    setStatus("Respawning - toggle stays enabled")
end

local function bindCharacter(char)
    Character = char
    Humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
    RootPart = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
    if Humanoid then
        pcall(function() Humanoid.Died:Connect(onDeath) end)
    end
    Respawning = false
    if G.FullyLeviathan then
        task.defer(startLoops)
    end
end

bindCharacter(Character)
LocalPlayer.CharacterAdded:Connect(bindCharacter)

task.spawn(function()
    local vu = VirtualUser
    while true do
        LocalPlayer.Idled:Wait()
        pcall(function()
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(math.max(10, G.WebhookInterval or 60))
        if G.WebhookEnabled and G.WebhookURL and G.WebhookURL ~= "" then
            local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
            if requestFn then
                pcall(requestFn, {
                    Url = G.WebhookURL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode({
                        username = "Quantum Kaitun",
                        content = "**Status:** " .. StatusText .. "\n**Players:** " .. #Players:GetPlayers(),
                    }),
                })
            end
        end
    end
end)

local StatusGui = nil
local StatusLabel = nil
local function syncStatusGui()
    if G.ShowStatus and not StatusGui then
        pcall(function()
            local container = (gethui and gethui()) or game:GetService("CoreGui")
            StatusGui = Instance.new("ScreenGui")
            StatusGui.Name = "QuantumKaitunStatus"
            StatusGui.ResetOnSpawn = false
            StatusLabel = Instance.new("TextLabel")
            StatusLabel.Size = UDim2.new(1, 0, 0, 26)
            StatusLabel.BackgroundTransparency = 0.45
            StatusLabel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
            StatusLabel.TextColor3 = Color3.fromRGB(225, 240, 255)
            StatusLabel.Font = Enum.Font.GothamBold
            StatusLabel.TextSize = 14
            StatusLabel.Parent = StatusGui
            pcall(function() StatusGui.Parent = container end)
            if not StatusGui.Parent then StatusGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        end)
    elseif StatusGui then
        pcall(function() StatusGui.Enabled = G.ShowStatus == true end)
    end
end

local function addStatusListener(fn)
    StatusListeners[#StatusListeners + 1] = fn
end

addStatusListener(function(text)
    if StatusLabel then pcall(function() StatusLabel.Text = "Quantum Kaitun | " .. text end) end
end)

task.spawn(function()
    while true do
        pcall(syncStatusGui)
        task.wait(0.5)
    end
end)

local Fluent = nil
local Window = nil

local function buildUI()
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)
    if not Fluent then error("Fluent could not be loaded") end
    SendNotify = function(title, content)
        pcall(function() Fluent:Notify({ Title = title or "Quantum Kaitun", Content = content or "", Duration = 4 }) end)
    end
    Window = Fluent:CreateWindow({
        Title = "Quantum Kaitun | Leviathan",
        SubTitle = "English version",
        TabWidth = 160,
        Size = UDim2.fromOffset(520, 400),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode[G.MenuKeybind or "G"],
    })

    local function toggle(tab, id, title, key, callback)
        tab:AddToggle(id, {
            Title = title,
            Default = G[key] == true,
            Callback = function(state)
                G[key] = state
                saveConfig()
                if callback then callback(state) end
            end,
        })
    end

    local function slider(tab, id, title, key, min, max)
        tab:AddSlider(id, {
            Title = title,
            Default = G[key],
            Min = min,
            Max = max,
            Rounding = 2,
            Callback = function(value)
                G[key] = value
                saveConfig()
            end,
        })
    end

    local function input(tab, id, title, key)
        tab:AddInput(id, {
            Title = title,
            Default = G[key],
            Callback = function(value)
                G[key] = value
                saveConfig()
            end,
        })
    end

    local Main = Window:AddTab({ Title = "Main", Icon = "anchor" })
    local Hunt = Window:AddTab({ Title = "Leviathan Hunt", Icon = "compass" })
    local Combat = Window:AddTab({ Title = "Combat", Icon = "swords" })
    local Boat = Window:AddTab({ Title = "Boat", Icon = "ship" })
    local Web = Window:AddTab({ Title = "Webhook", Icon = "link" })

    toggle(Main, "main.enabled", "Fully Leviathan", "FullyLeviathan", function(state)
        if state then
            setStatus("Fully Leviathan enabled")
            startLoops()
        else
            stopLoops()
            setStatus("Fully Leviathan disabled")
        end
    end)
    toggle(Main, "main.status", "Show status overlay", "ShowStatus")

    toggle(Hunt, "hunt.find", "Auto Find Leviathan", "AutoFindLeviathan")
    toggle(Hunt, "hunt.ignore", "Ignore Sea Events While Finding", "IgnoreSeaEvents")
    toggle(Hunt, "hunt.bribe", "Bribe the Spy", "BribeSpy")
    toggle(Hunt, "hunt.sailback", "Auto Sail Back to Tiki", "AutoSailBackTiki")

    toggle(Combat, "combat.fast", "Fast Attack", "FastAttack")
    slider(Combat, "combat.delay", "Fast Attack Delay", "FastAttackDelay", 0, 1)
    toggle(Combat, "combat.gun", "Auto Shoot Gun (Dragonstorm)", "AutoShootGun")
    Combat:AddDropdown("combat.mode", {
        Title = "Dragonstorm Mode",
        Values = { "Spread Damage", "Single Damage" },
        Default = G.DragonstormMode,
        Multi = false,
        Callback = function(value)
            G.DragonstormMode = value
            saveConfig()
        end,
    })
    toggle(Combat, "combat.haki", "Auto Haki", "AutoHaki")
    toggle(Combat, "combat.skills", "Auto Skills", "AutoSkills")
    slider(Combat, "combat.range", "Attack Range", "AttackRange", 100, 1500)

    slider(Boat, "boat.speed", "Boat Speed", "BoatSpeed", 50, 500)

    toggle(Web, "web.enabled", "Webhook Enabled", "WebhookEnabled")
    input(Web, "web.url", "Webhook URL", "WebhookURL")
    slider(Web, "web.interval", "Interval (seconds)", "WebhookInterval", 10, 600)

    Window:SelectTab(1)
    pcall(notify, "Quantum Kaitun", "Loaded successfully")
end

task.spawn(function()
    local ok, err = pcall(buildUI)
    if not ok then
        warn("[Quantum Kaitun] UI failed: " .. tostring(err))
        notify("Quantum Kaitun", "UI failed: " .. tostring(err))
    end
end)

setStatus("Ready")
print("[Quantum Kaitun] Loaded")
