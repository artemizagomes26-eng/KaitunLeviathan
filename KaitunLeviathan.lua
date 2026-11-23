if getgenv and getgenv().KaitunLeviathanLoaded and not (getgenv().ForceReload) then
    print("[Kaitun Leviathan] Ja carregado. Use getgenv().ForceReload = true para recarregar.")
    return
end

local G = (getgenv and getgenv()) or _G
G.ForceReload = false
G.KaitunLeviathanLoaded = true

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
local CommF = Remotes and Remotes:FindFirstChild("CommF_")

local Defaults = {
    AutoLeviathanFull = false,
    Mode = "Capitao",
    FollowTarget = "",
    Language = "Portugues",
    MenuKeybind = "G",
    SilentAim = true,
    SelectWeapon = "Sword",
    SkillMelee = { "Z", "X", "C" },
    SkillSword = { "Z", "X" },
    SkillFruit = { "X" },
    SkillGun = { "Z", "X" },
    FastAttack = false,
    FastAttack_Mode = "2",
    AutoBuso = true,
    AutoKen = false,
    AutoV3 = false,
    AutoV4 = false,
    DragonGunFarm = false,
    DragonGunLeviathan = false,
    RemoveFog = false,
    AntiDracoAura = false,
    AutoFastMode = false,
    FPSBoost = false,
    BoatHeight = 150,
    BoatSpeed = 250,
    PlayerTweenSpeed = 275,
    CruiseReturn = true,
    HuntFightEvents = false,
    HuntSelectEvents = {},
    SoloSeaFarm = false,
    RespawnRebuy = false,
    AutoCraftScrolls = false,
    CraftQuality = "None",
    AutoRandomFruit = false,
    AutoStoreFruits = false,
    WebhookURL = "",
    WebhookUsername = "Kaitun Leviathan",
    AutoWebhook = false,
    WebhookInterval = 60,
    WebhookSendProgress = false,
    WebhookSendBribeReady = false,
    WebhookSendLeviathan = false,
    WebhookSendHeartSpawn = false,
    WebhookSendHeartGot = false,
    WebhookSendLowPlayers = false,
    ShowInfoUI = false,
    FloatingBall = true,
}

local ConfigKeys = {}
for key in pairs(Defaults) do
    ConfigKeys[#ConfigKeys + 1] = key
end
table.sort(ConfigKeys)

for _, key in ipairs(ConfigKeys) do
    if G[key] == nil then
        G[key] = Defaults[key]
    end
end

local ConfigFolder = "KaitunLeviathan"
local safeName = tostring(LocalPlayer.Name):gsub("[^%w_%-]", "_")
local ConfigFile = ConfigFolder .. "/" .. safeName .. "_config.json"

local function clampNumber(value, fallback, minimum, maximum)
    return math.clamp(tonumber(value) or fallback, minimum, maximum)
end

G.BoatSpeed = clampNumber(G.BoatSpeed, 250, 50, 500)
G.BoatHeight = clampNumber(G.BoatHeight, 150, 30, 500)
G.PlayerTweenSpeed = clampNumber(G.PlayerTweenSpeed, 275, 50, 500)
G.WebhookInterval = clampNumber(G.WebhookInterval, 60, 10, 3600)

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function saveConfig()
    if type(makefolder) ~= "function" or type(writefile) ~= "function" then
        return
    end
    pcall(function()
        if type(isfolder) == "function" and not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end
        local data = {}
        for _, key in ipairs(ConfigKeys) do
            if G[key] ~= nil then
                data[key] = deepCopy(G[key])
            end
        end
        writefile(ConfigFile, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return
    end
    pcall(function()
        if not isfile(ConfigFile) then
            return
        end
        local raw = readfile(ConfigFile)
        if type(raw) ~= "string" or raw == "" then
            return
        end
        local data = HttpService:JSONDecode(raw)
        if type(data) ~= "table" then
            return
        end
        for _, key in ipairs(ConfigKeys) do
            if data[key] ~= nil then
                G[key] = data[key]
            end
        end
    end)
end

loadConfig()

local StatusText = "Aguardando"
local StatusListeners = {}
local SendNotify = function() end

local function setStatus(text)
    StatusText = tostring(text)
    for _, listener in ipairs(StatusListeners) do
        pcall(listener, StatusText)
    end
end

local function addStatusListener(fn)
    StatusListeners[#StatusListeners + 1] = fn
end

local function notify(title, content)
    pcall(SendNotify, title, content)
end

local LanguageText = {
    pt = {
        ready = "Kaitun Leviathan pronto",
        start = "Iniciando kaitun",
        stop = "Kaitun parado",
        hunting = "Procurando o Leviathan",
        sailing = "Navegando",
        fighting = "Atacando o Leviathan",
        seaEvent = "Evento marinho: ",
        heart = "Coração congelado encontrado",
        bribe = "Subornando o espião",
        gate = "Abrindo o portão do Leviathan",
        tiki = "Voltando para Tiki",
        boat = "Comprando barco",
        seat = "Entrando no barco",
        dead = "Derrotado",
        waiting = "Aguardando",
    },
    en = {
        ready = "Kaitun Leviathan ready",
        start = "Starting kaitun",
        stop = "Kaitun stopped",
        hunting = "Hunting Leviathan",
        sailing = "Sailing",
        fighting = "Attacking Leviathan",
        seaEvent = "Sea event: ",
        heart = "Frozen Heart found",
        bribe = "Bribing the spy",
        gate = "Opening Leviathan gate",
        tiki = "Returning to Tiki",
        boat = "Buying a boat",
        seat = "Boarding boat",
        dead = "Defeated",
        waiting = "Waiting",
    },
    es = {
        ready = "Kaitun Leviathan listo",
        start = "Iniciando kaitun",
        stop = "Kaitun detenido",
        hunting = "Buscando al Leviathan",
        sailing = "Navegando",
        fighting = "Atacando al Leviathan",
        seaEvent = "Evento marino: ",
        heart = "Corazon congelado encontrado",
        bribe = "Sobornando al espia",
        gate = "Abriendo la puerta",
        tiki = "Volviendo a Tiki",
        boat = "Comprando barco",
        seat = "Subiendo al barco",
        dead = "Derrotado",
        waiting = "Esperando",
    },
}

local function languageCode()
    local name = tostring(G.Language or ""):lower()
    if name:find("ingl") or name == "en" or name == "english" then
        return "en"
    end
    if name:find("espa") or name == "es" or name == "spanish" then
        return "es"
    end
    return "pt"
end

local function T(key)
    local dict = LanguageText[languageCode()] or LanguageText.pt
    return dict[key] or LanguageText.pt[key] or key
end

local function getCharacterParts()
    local char = LocalPlayer.Character
    if not char then
        return nil, nil, nil
    end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function refreshCharacter()
    Character = LocalPlayer.Character or Character
    Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

local NoclipOn = false
local LastNoclipApply = 0

local function noClip(enabled)
    if not Character or not RootPart or not Humanoid or Humanoid.Health <= 0 then
        return
    end
    if enabled then
        if NoclipOn and os.clock() - LastNoclipApply < 0.5 then
            return
        end
        NoclipOn = true
        LastNoclipApply = os.clock()
    else
        NoclipOn = false
    end
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

local TWEEN_PART_NAME = "KaitunTweenPart"
local CurrentTween = nil
local Tweening = false
local TpActive = false
local HoldCFrame = nil
local LiveHoldFn = nil
local AttackModel = nil
local AttackStandFn = nil

local function getTweenPart()
    local part = workspace:FindFirstChild(TWEEN_PART_NAME)
    if part and part:IsA("BasePart") then
        return part
    end
    part = Instance.new("Part")
    part.Name = TWEEN_PART_NAME
    part.Size = Vector3.new(1, 1, 1)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Massless = true
    part.Transparency = 1
    part.Parent = workspace
    return part
end

local function clearHover()
    HoldCFrame = nil
    LiveHoldFn = nil
end

local function resolveTarget(target)
    if typeof(target) == "function" then
        local ok, result = pcall(target)
        if ok and result then
            return result, target
        end
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
    local _, startHRP = getCharacterParts()
    if not startHRP or G.StopTween then
        return false
    end
    local targetCF, liveTarget = resolveTarget(target)
    if not targetCF or targetCF.Position.Y < 0 then
        return false
    end
    HoldCFrame = nil
    LiveHoldFn = nil
    local _, _, startHum = getCharacterParts()
    if startHum and startHum.SeatPart and (startHum.SeatPart.Position - targetCF.Position).Magnitude <= 40 then
        return true
    end
    if startHum and (startHum.Sit or startHum.SeatPart ~= nil) then
        pcall(function()
            startHum.Sit = false
            startHum.PlatformStand = false
            startHRP.CFrame = startHRP.CFrame + Vector3.new(0, 10, 0)
        end)
        task.wait(0.2)
    end
    local part = getTweenPart()
    part.CFrame = startHRP.CFrame
    noClip(true)
    if CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
    local tween = nil
    if not liveTarget then
        local distance = (targetCF.Position - startHRP.Position).Magnitude
        local duration = math.max(distance / G.PlayerTweenSpeed, 0.05)
        tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCF })
        CurrentTween = tween
    end
    Tweening = true
    TpActive = true
    local aborted = false
    local arrived = false
    local seatedStop = false
    local nextAbortAt = 0
    local connection = RunService.Stepped:Connect(function(_, deltaTime)
        local dt = deltaTime or 1 / 60
        local char, hrp, hum = getCharacterParts()
        if not hrp or char ~= startChar or not hum or hum.Health <= 0 or hrp.Position.Y < 0 then
            aborted = true
            if tween then pcall(function() tween:Cancel() end) end
            return
        end
        if hum.SeatPart ~= nil then
            seatedStop = true
            arrived = true
            if tween then pcall(function() tween:Cancel() end) end
            return
        end
        if liveTarget then
            local goal, _ = resolveTarget(liveTarget)
            if not goal or goal.Position.Y < 0 then
                aborted = true
                if tween then pcall(function() tween:Cancel() end) end
            else
                local delta = goal.Position - part.Position
                local dist = delta.Magnitude
                if dist <= 5 then
                    arrived = true
                else
                    part.CFrame = CFrame.new(part.Position + delta.Unit * math.min(dist, G.PlayerTweenSpeed * dt))
                        * (part.CFrame - part.CFrame.Position)
                end
            end
        end
        if not aborted and not seatedStop then
            hrp.CFrame = part.CFrame
            hrp.AssemblyLinearVelocity = Vector3.zero
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        if abortCheck and not aborted and tick() >= nextAbortAt then
            nextAbortAt = tick() + 0.1
            local ok, stop = pcall(abortCheck)
            if ok and stop then
                aborted = true
                if tween then pcall(function() tween:Cancel() end) end
            end
        end
    end)
    pcall(function()
        if liveTarget then
            local timeout = tick() + math.max(8, (targetCF.Position - startHRP.Position).Magnitude / G.PlayerTweenSpeed + 8)
            repeat
                task.wait()
            until arrived or aborted or tick() > timeout
        elseif tween then
            tween:Play()
            repeat
                task.wait()
            until seatedStop or aborted or tween.PlaybackState ~= Enum.PlaybackState.Playing
        end
    end)
    pcall(function() connection:Disconnect() end)
    if tween and CurrentTween == tween then CurrentTween = nil end
    Tweening = false
    TpActive = false
    if not aborted and not seatedStop then
        if liveTarget then
            LiveHoldFn = liveTarget
        else
            HoldCFrame = targetCF
        end
    end
    return not aborted
end

local function stopTweenAll()
    G.StopTween = true
    if CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
    Tweening = false
    TpActive = false
    noClip(false)
    clearHover()
    task.defer(function()
        task.wait(0.1)
        G.StopTween = false
    end)
end

RunService.Heartbeat:Connect(function(dt)
    if G.StopTween then return end
    local _, hrp, hum = getCharacterParts()
    if not hrp or (hum and hum.SeatPart ~= nil) or TpActive then return end
    if CurrentTween and CurrentTween.PlaybackState == Enum.PlaybackState.Playing then return end
    local goal = nil
    if AttackModel then
        if not AttackModel.Parent then
            AttackModel, AttackStandFn = nil, nil
        else
            local ok, cf = pcall(AttackStandFn)
            if ok and cf and cf.Position.Y >= 0 then
                goal = cf
            elseif ok and cf then
                AttackModel, AttackStandFn = nil, nil
            end
        end
    end
    if not goal and LiveHoldFn then
        local ok, cf = pcall(LiveHoldFn)
        if ok and cf then
            if cf.Position.Y < 0 then
                clearHover()
                return
            end
            goal = cf
        end
    end
    if not goal then goal = HoldCFrame end
    if not goal then return end
    if goal.Position.Y < 0 then
        clearHover()
        return
    end
    if not LiveHoldFn then HoldCFrame = goal end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
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
        local step = math.min(dist, G.PlayerTweenSpeed * (dt or 1 / 60))
        hrp.CFrame = hrp.CFrame:Lerp(goal, step / dist)
    end
end)

local function liveFixedCF(cf)
    return function()
        return cf
    end
end

local function liveSeatCF(seat)
    return function()
        if seat and seat.Parent then
            return seat.CFrame * CFrame.new(0, 3, 0)
        end
        return nil
    end
end

local function seatTakenByOther(seat, hum)
    local occupant = seat.Occupant
    if occupant ~= nil and occupant ~= hum then return true end
    local weld = seat:FindFirstChild("SeatWeld")
    if weld then
        local p1 = weld.Part1
        if p1 and p1:IsA("BasePart") then
            local owner = p1:FindFirstAncestorWhichIsA("Model")
            local otherHum = owner and owner:FindFirstChildOfClass("Humanoid")
            if otherHum and otherHum ~= hum then return true end
        end
    end
    return false
end

local function breakPhantomSeat(seat)
    local char, hrp, hum = getCharacterParts()
    if not hum then return false end
    local target = seat or hum.SeatPart
    pcall(function()
        hum.Sit = false
        hum.PlatformStand = false
    end)
    if target and target.Parent then
        local weld = target:FindFirstChild("SeatWeld")
        local p1 = weld and weld.Part1
        if weld and ((not p1) or (p1:IsA("BasePart") and char and p1:IsDescendantOf(char))) then
            pcall(function() weld:Destroy() end)
        end
    end
    if hrp then
        pcall(function()
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 5, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
    end
    clearHover()
    task.wait(0.15)
    local _, _, hum2 = getCharacterParts()
    return hum2 == nil or not hum2.Sit
end

local function checkItem(name, findMode)
    local _, _, hum = getCharacterParts()
    if not hum or not LocalPlayer.Backpack then return nil end
    if findMode == "Find" then
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if string.find(v.Name, name, 1, true) then return v end
        end
        return nil
    end
    local char = LocalPlayer.Character
    return (char and char:FindFirstChild(name)) or LocalPlayer.Backpack:FindFirstChild(name)
end

local function hasItem(name)
    return checkItem(name) ~= nil
end

local function equip(name)
    local _, _, hum = getCharacterParts()
    if not hum or hum.Health <= 0 or not LocalPlayer.Backpack then return end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        local match = false
        if name == "Melee" or name == "Sword" or name == "Gun" or name == "Blox Fruit" then
            match = tool.ToolTip == name
        else
            match = tool.Name == name
        end
        if match then
            pcall(function() hum:EquipTool(tool) end)
            return
        end
    end
end

local function pressKey(key)
    local code = key == "Space" and Enum.KeyCode.Space or Enum.KeyCode[tostring(key):upper()]
    if not code then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, code, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, code, false, game)
    end)
end

local function skillListFor(weapon)
    if weapon == "Melee" then return G.SkillMelee end
    if weapon == "Sword" then return G.SkillSword end
    if weapon == "Blox Fruit" then return G.SkillFruit end
    if weapon == "Gun" then return G.SkillGun end
    return {}
end

local skillCooldown = false
local lastAllWeapon = 0

local function cooldownReady(cd)
    local ok, result = pcall(function()
        return cd.Size.X.Scale == 0
    end)
    return ok and result
end

local function useReadySkills()
    if skillCooldown then return end
    if tick() - lastAllWeapon >= 10 then
        skillCooldown = true
        lastAllWeapon = tick()
        for _, name in ipairs({ "Melee", "Sword", "Gun", "Blox Fruit" }) do
            equip(name)
            task.wait()
        end
        task.wait(0.3)
        skillCooldown = false
    end
    local skillsGui = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui.Main and LocalPlayer.PlayerGui.Main.Skills
    if not skillsGui then return end
    for _, weaponGui in ipairs(skillsGui:GetChildren()) do
        for _, skillGui in ipairs(weaponGui:GetChildren()) do
            if table.find({ "Z", "X", "C", "V", "F" }, skillGui.Name) then
                local cd = skillGui:FindFirstChild("Cooldown", true)
                local level = skillGui:FindFirstChild("Level")
                local key = skillGui.Name
                local allowed = skillListFor(weaponGui.Name)
                if cd and level and table.find(allowed, key) and cooldownReady(cd) then
                    local current = checkItem(weaponGui.Name)
                    local levelValue = tonumber(level.Text:match("%d+"))
                    if current and current.Level and levelValue and levelValue <= current.Level.Value then
                        task.spawn(function()
                            skillCooldown = true
                            equip(weaponGui.Name)
                            pressKey(key)
                            task.wait(0.5)
                            skillCooldown = false
                        end)
                    end
                end
            end
        end
    end
end

local function autoHaki()
    if not G.AutoBuso or not CommF then return end
    local char = LocalPlayer.Character
    if char and not char:FindFirstChild("HasBuso") then
        pcall(function() CommF:InvokeServer("Buso") end)
    end
end

local CommE = Remotes and Remotes:FindFirstChild("CommE")

local function autoRaceAbilities()
    if G.AutoKen and CommE then
        task.spawn(function()
            pcall(function() CommE:FireServer("Ken", true) end)
        end)
    end
    if G.AutoV3 and CommE then
        task.spawn(function()
            pcall(function() CommE:FireServer("ActivateAbility") end)
        end)
    end
    if G.AutoV4 then
        task.spawn(function()
            local awakening = LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Awakening")
            if awakening and awakening:FindFirstChild("RemoteFunction") then
                pcall(function() awakening.RemoteFunction:InvokeServer(true) end)
            end
        end)
    end
end

local AttackNet = nil
local RegisterAttack = nil
local RegisterHit = nil
local SeedRemote = nil
local ObfuscatedRemote = nil
local ObfuscatedId = nil
local HitCache = nil
local HitOrigin = nil
local HitAt = 0
local SeedCache = nil
local SeedAt = 0

local function cloneRef(inst)
    if typeof(cloneref) == "function" then
        return cloneref(inst)
    end
    return inst
end

local function captureObfuscated(remote)
    if remote and remote:IsA("RemoteEvent") and remote:GetAttribute("Id") then
        ObfuscatedRemote = remote
        ObfuscatedId = remote:GetAttribute("Id")
    end
end

for _, folderName in ipairs({ "Util", "Common", "Remotes", "Assets", "FX" }) do
    local folder = ReplicatedStorage:FindFirstChild(folderName)
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            captureObfuscated(child)
        end
        folder.ChildAdded:Connect(captureObfuscated)
    end
end

local function ensureAttackRemotes()
    if not AttackNet then
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        AttackNet = modules and modules:FindFirstChild("Net")
    end
    if not AttackNet then return false end
    RegisterAttack = RegisterAttack or AttackNet:FindFirstChild("RE/RegisterAttack") or AttackNet:FindFirstChild("RegisterAttack")
    RegisterHit = RegisterHit or AttackNet:FindFirstChild("RE/RegisterHit") or AttackNet:FindFirstChild("RegisterHit")
    SeedRemote = SeedRemote or AttackNet:FindFirstChild("seed")
    return RegisterAttack ~= nil and RegisterHit ~= nil
end

local function buildHitList(character, origin)
    local now = os.clock()
    if HitCache and HitOrigin and now - HitAt < 0.1 and (origin - HitOrigin).Magnitude < 40 then
        return HitCache
    end
    local hitList = HitCache or {}
    table.clear(hitList)
    for _, folderName in ipairs({ "Enemies", "Characters" }) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model ~= character then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 and (root.Position - origin).Magnitude <= 60 then
                        for _, part in ipairs(model:GetChildren()) do
                            if part:IsA("BasePart") then
                                hitList[#hitList + 1] = { model, part }
                            end
                        end
                    end
                end
            end
        end
    end
    HitCache, HitOrigin, HitAt = hitList, origin, now
    return hitList
end

local function getAttackSeed()
    local now = os.clock()
    if SeedCache and now - SeedAt < 1 then return SeedCache end
    if SeedRemote then
        local ok, seed = pcall(function() return SeedRemote:InvokeServer() end)
        if ok and seed then
            SeedCache, SeedAt = seed, now
            return seed
        end
    end
    return SeedCache or 1
end

local function fastM1()
    local char = LocalPlayer.Character
    if not char or not RootPart then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local weaponType = tool:GetAttribute("WeaponType")
    if weaponType ~= "Melee" and weaponType ~= "Sword" then return end
    if not ensureAttackRemotes() then return end
    local hitList = buildHitList(char, RootPart.Position)
    if #hitList == 0 then return end
    pcall(function()
        local okNet, netApi = pcall(function() return require(AttackNet) end)
        if okNet and netApi and netApi.RemoteEvent then
            pcall(netApi.RemoteEvent, netApi, "RegisterHit", true)
        end
        RegisterAttack:FireServer()
        local head = hitList[1][1] and hitList[1][1]:FindFirstChild("Head")
        if not head then return end
        if G.FastAttack_Mode == "1" then
            RegisterHit:FireServer(head, hitList)
        else
            RegisterHit:FireServer(head, hitList, {}, tostring(LocalPlayer.UserId):sub(2, 4)
                .. tostring(coroutine.running()):sub(11, 15))
        end
        if ObfuscatedRemote and ObfuscatedId then
            local key = math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
            local encName = string.gsub("RE/RegisterHit", ".", function(c)
                return string.char(bit32.bxor(string.byte(c), key))
            end)
            local encId = bit32.bxor(ObfuscatedId + 909090, getAttackSeed() * 2)
            cloneRef(ObfuscatedRemote):FireServer(encName, encId, head, hitList)
        end
    end)
end

local ShootGunEvent = nil
local Validator2 = nil
local shootFunc = nil
local upvalueIndex = {}
local dragonReady = false
local LIMB_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "HumanoidRootPart",
}

local function randomLimb(character)
    if not character then return nil end
    local available = {}
    for _, name in ipairs(LIMB_PARTS) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            available[#available + 1] = part
        end
    end
    if #available == 0 then return character:FindFirstChild("HumanoidRootPart") end
    return available[math.random(1, #available)]
end

local function initDragon()
    if dragonReady then return end
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
    dragonReady = shootFunc ~= nil
end

local function fireDragonShot(pos, hit)
    if not shootFunc or not Validator2 or not ShootGunEvent then return end
    pcall(function()
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
        ShootGunEvent:FireServer(pos, { hit })
    end)
end

local function closestSeaTarget()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, 450
    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
    if seaBeasts then
        for _, e in ipairs(seaBeasts:GetChildren()) do
            local root = e:FindFirstChild("HumanoidRootPart")
            local hp = e:FindFirstChild("Health")
            if root and hp and hp:IsA("ValueBase") and hp.Value > 0 then
                local segment = e:FindFirstChild("Leviathan Segment")
                if segment then
                    local dist = (segment.Position - hrp.Position).Magnitude
                    if dist < bestDist then bestDist, best = dist, segment end
                end
                local dist = (root.Position - hrp.Position).Magnitude
                if dist < bestDist then bestDist, best = dist, randomLimb(e) or root end
            end
        end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, e in ipairs(enemies:GetChildren()) do
            local hp = e:FindFirstChild("Health")
            if hp and hp:IsA("ValueBase") and hp.Value > 0 then
                local root = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Engine")
                local hum = e:FindFirstChildOfClass("Humanoid")
                if root and (hum or e:FindFirstChild("VehicleSeat")) then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < bestDist then bestDist, best = dist, randomLimb(e) or root end
                end
            end
        end
    end
    return best
end

local function startDragonAttack()
    task.spawn(function()
        while G.DragonGunFarm and G.AutoLeviathanFull do
            pcall(function()
                initDragon()
                if not ShootGunEvent then
                    local modules = ReplicatedStorage:FindFirstChild("Modules")
                    local net = modules and modules:FindFirstChild("Net")
                    ShootGunEvent = net and net:FindFirstChild("RE/ShootGunEvent")
                end
                if not Validator2 then
                    Validator2 = Remotes and Remotes:FindFirstChild("Validator2")
                end
                if not ShootGunEvent or not Validator2 then return end
                local target = closestSeaTarget()
                if not target then return end
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if not tool or tool.Name ~= "Dragonstorm" then
                    equip("Dragonstorm")
                    return
                end
                fireDragonShot(target.Position, target)
            end)
            task.wait()
        end
    end)
end

local function faceTargetCF(standPos, model)
    if not model or not model.Parent or model:IsA("BasePart") then return nil end
    local best, bestDist = nil, nil
    local stack, visited = { model }, 0
    while #stack > 0 and visited < 150 do
        local node = table.remove(stack)
        for _, child in ipairs(node:GetChildren()) do
            visited = visited + 1
            if child:IsA("BasePart") then
                local flat = Vector3.new(child.Position.X - standPos.X, 0, child.Position.Z - standPos.Z)
                local d = flat.Magnitude
                if d > 1 and (bestDist == nil or d < bestDist) then
                    best, bestDist = child, d
                end
            elseif child:IsA("Model") then
                stack[#stack + 1] = child
            end
        end
    end
    if not best then return nil end
    local flat = Vector3.new(best.Position.X - standPos.X, 0, best.Position.Z - standPos.Z)
    if flat.Magnitude < 1 then return nil end
    return CFrame.lookAt(standPos, standPos + flat.Unit)
end

local function eventRoot(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("RootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
        or model:FindFirstChildWhichIsA("BasePart", true)
end

local function seaStand(mob, root)
    if not root then return nil end
    local standPos = Vector3.new(root.Position.X, 120, root.Position.Z)
    return faceTargetCF(standPos, mob) or CFrame.new(standPos)
end

local function mobAlive(mob)
    if not mob or not mob.Parent then return false end
    local health = mob:FindFirstChild("Health")
    if health and health:IsA("ValueBase") and health.Value <= 0 then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return (health ~= nil and health:IsA("ValueBase")) or hum ~= nil
end

local function findSeaMob(maxDistance, exclude)
    maxDistance = maxDistance or 1500
    local data = {
        { name = "Terrorshark", config = "Terrorshark", folder = "Enemies", skill = false },
        { name = "Piranha", config = "Piranha", folder = "Enemies", skill = false },
        { name = "Shark", config = "Shark", folder = "Enemies", skill = false },
        { name = "FishBoat", config = "Ghost Ship", folder = "Enemies", skill = true },
        { name = "PirateBrigade", config = "Pirate Brigade Ship", folder = "Enemies", skill = true },
        { name = "PirateGrandBrigade", config = "Pirate Grand Brigade Ship", folder = "Enemies", skill = true },
        { name = "PirateBasic", config = "Pirate Basic Ship", folder = "Enemies", skill = true },
        { name = "SeaBeast1", config = "Sea Beast", folder = "SeaBeasts", skill = true },
    }
    local selected = G.HuntSelectEvents
    local hasFilter = type(selected) == "table" and #selected > 0
    local _, hrp = getCharacterParts()
    if not hrp then return nil, nil, false end
    for _, info in ipairs(data) do
        if not hasFilter or table.find(selected, info.config) then
            local folder = workspace:FindFirstChild(info.folder)
            if folder then
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob.Name == info.name and not (exclude and exclude[mob]) then
                        local root = eventRoot(mob)
                        if mobAlive(mob) and root and (root.Position - hrp.Position).Magnitude <= maxDistance then
                            return mob, root, info.skill
                        end
                    end
                end
            end
        end
    end
    return nil, nil, false
end

local function leviathanIsDead(model)
    if not model then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    local health = model:FindFirstChild("Health")
    if health and (health:IsA("NumberValue") or health:IsA("IntValue")) and health.Value <= 0 then
        return true
    end
    return false
end

local function leviathanHP(model)
    if not model then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health end
    local health = model:FindFirstChild("Health")
    if health and (health:IsA("NumberValue") or health:IsA("IntValue")) then
        return health.Value
    end
    return nil
end

local leviathanCache, leviathanCacheAt = nil, 0

local function findLeviathan()
    local now = os.clock()
    if leviathanCache and now - leviathanCacheAt < 0.25 then
        return leviathanCache[1], leviathanCache[2]
    end
    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
    local model, part = nil, nil
    if seaBeasts then
        for _, child in ipairs(seaBeasts:GetChildren()) do
            if child.Name == "Leviathan Segment" and not leviathanIsDead(child) then
                model = child
                part = eventRoot(child)
                if part then break end
                model = nil
            end
        end
        if not model then
            local boss = seaBeasts:FindFirstChild("Leviathan")
            if boss and not leviathanIsDead(boss) then
                model = boss
                part = eventRoot(boss)
            end
        end
    end
    leviathanCache, leviathanCacheAt = { model, part }, now
    return model, part
end

local function leviathanExists()
    local model = findLeviathan()
    return model ~= nil
end

local function leviathanStand(model, part)
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart")
        or model.PrimaryPart or model:FindFirstChild("Head") or part
    if not root then return nil end
    local standPos = Vector3.new(root.Position.X, root.Position.Y + 75, root.Position.Z)
    return faceTargetCF(standPos, model) or CFrame.new(standPos)
end

local IsSittingOn
local Unseat
local BoardSeat
local BoardSeatRetry
local ForceUnseat

IsSittingOn = function(seat)
    local _, _, hum = getCharacterParts()
    return hum ~= nil and seat ~= nil and seat.Parent ~= nil and hum.SeatPart == seat
end

local function isOnBoat()
    local _, _, hum = getCharacterParts()
    return hum ~= nil and (hum.SeatPart ~= nil or hum.Sit)
end

Unseat = function()
    clearHover()
    for _ = 1, 3 do
        local _, hrp, hum = getCharacterParts()
        if not hum or (not hum.Sit and hum.SeatPart == nil) then return true end
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
            if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 10, 0) end
        end)
        local start = os.clock()
        while os.clock() - start < 2 do
            local _, _, hum2 = getCharacterParts()
            if not hum2 or (not hum2.Sit and hum2.SeatPart == nil) then return true end
            pcall(function()
                hum2.Sit = false
                hum2.PlatformStand = false
            end)
            task.wait(0.2)
        end
    end
    return false
end

ForceUnseat = function(seconds)
    local deadline = os.clock() + (seconds or 10)
    while G.AutoLeviathanFull and os.clock() < deadline do
        local _, _, hum = getCharacterParts()
        if not hum or (not hum.Sit and hum.SeatPart == nil) then return true end
        Unseat()
        task.wait(0.3)
    end
    local _, _, hum = getCharacterParts()
    return hum == nil or (not hum.Sit and hum.SeatPart == nil)
end

local BoatFindRange = 5000
local AbandonedBoats = setmetatable({}, { __mode = "k" })

local function isBeastHunterBoat(boat)
    return boat ~= nil and boat.Name == "Beast Hunter"
end

local function boatOwnerMatch(boat, player)
    local owner = boat and boat:FindFirstChild("Owner")
    if not owner or not player then return false end
    return tostring(owner.Value) == player.Name
end

local function boatOf(seat)
    local node = seat
    while node do
        if node.Parent and node.Parent.Name == "Boats" then return node end
        node = node.Parent
    end
    return nil
end

local function abandonIfTooFar(seat)
    if not seat or not seat.Parent then return false end
    local boat = boatOf(seat)
    if not isBeastHunterBoat(boat) or not boatOwnerMatch(boat, LocalPlayer) then return false end
    local _, hrp = getCharacterParts()
    if not hrp then return false end
    if (hrp.Position - seat.Position).Magnitude > BoatFindRange then
        AbandonedBoats[boat] = true
        setStatus("Barco muito longe, comprando outro")
        return true
    end
    return false
end

local function boatDead(boat)
    if not boat then return false end
    for _, name in ipairs({ "Humanoid", "Health", "HumanoidRootPart" }) do
        local value = boat:FindFirstChild(name)
        if value and value:IsA("ValueBase") then
            local ok, result = pcall(function() return value.Value end)
            if ok and result ~= nil then return result <= 0 end
        elseif value and value:IsA("Humanoid") then
            return value.Health <= 0
        end
    end
    return false
end

local function ownedBoats()
    local result = {}
    local boats = workspace:FindFirstChild("Boats")
    if not boats then return result end
    for _, boat in ipairs(boats:GetChildren()) do
        if isBeastHunterBoat(boat) and boatOwnerMatch(boat, LocalPlayer) and not AbandonedBoats[boat] then
            result[#result + 1] = boat
        end
    end
    return result
end

local function getOwnBoat(includeDead)
    local boats = ownedBoats()
    local _, hrp = getCharacterParts()
    if not hrp then return boats[1] end
    local best, bestDist = nil, math.huge
    for _, boat in ipairs(boats) do
        if includeDead or not boatDead(boat) then
            local seat = boat:FindFirstChild("VehicleSeat")
            if seat then
                local dist = (seat.Position - hrp.Position).Magnitude
                if dist < bestDist then best, bestDist = boat, dist end
            end
        end
    end
    return best
end

BoardSeat = function(seat, timeout)
    timeout = timeout or 15
    if not seat or not seat.Parent or abandonIfTooFar(seat) then return false end
    local deadline = os.clock() + timeout
    while G.AutoLeviathanFull and os.clock() < deadline do
        if not seat or not seat.Parent or abandonIfTooFar(seat) then return false end
        local _, hrp, hum = getCharacterParts()
        if hum and hum.SeatPart == seat then
            clearHover()
            return true
        end
        if hum and (hum.Sit or hum.SeatPart ~= nil) then
            Unseat()
            task.wait(0.3)
        end
        if hrp then
            tweenTo(liveSeatCF(seat), function()
                if not G.AutoLeviathanFull or not seat or not seat.Parent then return true end
                local _, _, humNow = getCharacterParts()
                return humNow ~= nil and humNow.SeatPart ~= nil
            end)
        end
        task.wait(0.2)
    end
    return IsSittingOn(seat)
end

BoardSeatRetry = function(seat, timeout, attempts)
    for _ = 1, (attempts or 3) do
        if not seat or not seat.Parent then return false end
        if BoardSeat(seat, timeout) then return true end
        Unseat()
        task.wait(0.5)
    end
    return false
end

local BoatDealerCF = CFrame.new(-16917.1523, 8.59936905, 511.799042)
local CruiseWP_A = CFrame.new(-44541.7617, 30.0003204, -1244.8584)
local CruiseWP_B = CFrame.new(-90000, 30.0003204, -1244.8584)
local CruiseWP_Far = CFrame.new(-9000000000, 30.0003204, -1244.8584)
local TikiWaypointCF = CFrame.new(-2044.52, 27.82, -701.59)
local TikiReturnCF = CFrame.new(-16206.9014, 7.75799561, 404.552002)
local CruiseToB = false
local CruiseCheckPos = nil
local CruiseCheckAt = 0
local CruiseStalls = 0
local LastSailAt = 0

local function buyOwnBoat(message)
    setStatus(message or T("boat"))
    local _, _, hum = getCharacterParts()
    if hum and (hum.Sit or hum.SeatPart ~= nil) then Unseat() end
    local start = os.clock()
    while G.AutoLeviathanFull and os.clock() - start < 90 do
        local _, hrp = getCharacterParts()
        if hrp and (hrp.Position - BoatDealerCF.Position).Magnitude <= 20 then break end
        tweenTo(liveFixedCF(BoatDealerCF))
        task.wait(0.5)
    end
    if not CommF then return false end
    pcall(function() CommF:InvokeServer("BuyBoat", "Beast Hunter") end)
    task.wait(1)
    return getOwnBoat() ~= nil
end

local function sailBoatStream(seat, speed)
    speed = speed or G.BoatSpeed
    if not seat or not seat.Parent then return false end
    LastSailAt = os.clock()
    local _, hrp = getCharacterParts()
    if not hrp then return false end
    local dt = RunService.Heartbeat:Wait() or 1 / 60
    if (seat.Position or hrp.Position).Y < 0 then
        AbandonedBoats[seat.Parent] = true
        Unseat()
        return false
    end
    local pos = hrp.Position
    local target = G.CruiseReturn and (CruiseToB and CruiseWP_B or CruiseWP_A) or CruiseWP_Far
    local zone = target.Position
    local flat = Vector3.new(zone.X - pos.X, 0, zone.Z - pos.Z)
    local dist = flat.Magnitude
    if G.CruiseReturn and dist <= 40 then
        CruiseToB = not CruiseToB
        target = CruiseToB and CruiseWP_B or CruiseWP_A
        zone = target.Position
        flat = Vector3.new(zone.X - pos.X, 0, zone.Z - pos.Z)
        dist = flat.Magnitude
    end
    if os.clock() - CruiseCheckAt >= 15 then
        if CruiseCheckPos and Vector3.new(pos.X - CruiseCheckPos.X, 0, pos.Z - CruiseCheckPos.Z).Magnitude < 200 then
            CruiseStalls = CruiseStalls + 1
            if CruiseStalls >= 2 then
                CruiseStalls = 0
                CruiseCheckPos = nil
            else
                setStatus("Barco parado, reiniciando rota")
                Unseat()
                task.wait(0.3)
                if seat.Parent then BoardSeatRetry(seat, 10) end
                CruiseCheckPos = nil
            end
        else
            CruiseStalls = 0
            CruiseCheckPos = pos
        end
        CruiseCheckAt = os.clock()
    end
    local step = math.min(dist, speed * dt)
    local np = pos + (dist > 0 and flat.Unit or Vector3.zero) * step
    local y = G.BoatHeight
    pcall(function()
        hrp.CFrame = CFrame.lookAt(Vector3.new(np.X, y, np.Z), Vector3.new(np.X, y, np.Z - 1), Vector3.new(0, 1, 0))
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)
    return true
end

local function sailBoatTurn(seat, targetPos, speed, fixedY)
    speed = speed or G.BoatSpeed
    local flat = Vector3.new(targetPos.X - seat.Position.X, 0, targetPos.Z - seat.Position.Z)
    if flat.Magnitude < 0.5 then return end
    LastSailAt = os.clock()
    local dt = RunService.Heartbeat:Wait() or 1 / 60
    local yaw = math.atan2(flat.X, flat.Z) + math.pi
    local move = flat.Unit * speed * dt
    local newPos = seat.Position + move
    pcall(function()
        seat.CFrame = CFrame.new(newPos.X, fixedY or seat.Position.Y, newPos.Z) * CFrame.Angles(0, yaw, 0)
    end)
end

local function steerAngle(seat, targetPos)
    local cf = seat.CFrame
    local look = (cf.LookVector * Vector3.new(1, 0, 1)).Unit
    local toTarget = ((targetPos - cf.Position) * Vector3.new(1, 0, 1)).Unit
    local angle = math.deg(math.acos(math.clamp(look:Dot(toTarget), -1, 1)))
    if look:Cross(toTarget).Y < 0 then angle = -angle end
    return angle
end

local function sailToCF(seat, targetCF, speed, heartCheck)
    speed = speed or G.BoatSpeed
    local targetPos = targetCF.Position
    local boat = seat and seat.Parent and seat.Parent:IsA("Model") and seat.Parent or nil
    local prim = boat and boat.PrimaryPart or nil
    local originalMaxSpeed = seat.MaxSpeed
    local originalTurnSpeed = seat.TurnSpeed
    local originalTorque = seat.Torque
    local start = os.clock()
    local lastCheckPos = seat.Position
    local lastCheckAt = os.clock()
    local lastHeartCheckAt = 0
    local arrived = false
    local stalls = 0
    while G.AutoLeviathanFull and os.clock() - start < 900 do
        LastSailAt = os.clock()
        if not seat or not seat.Parent or not IsSittingOn(seat) then break end
        if heartCheck and os.clock() - lastHeartCheckAt >= 1 then
            lastHeartCheckAt = os.clock()
            if not heartCheck(seat) then break end
        end
        if os.clock() - lastCheckAt >= 30 then
            local moved = (seat.Position - lastCheckPos).Magnitude
            if moved < 200 then
                stalls = stalls + 1
                if stalls >= 2 then
                    break
                end
                setStatus("Barco lento, reiniciando")
                if Unseat() then
                    task.wait(0.5)
                    if not BoardSeatRetry(seat) then break end
                end
            else
                stalls = 0
            end
            lastCheckPos = seat.Position
            lastCheckAt = os.clock()
        end
        local pos = seat.Position
        local flat = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
        local distance = flat.Magnitude
        setStatus("Voltando para Tiki (" .. math.floor(distance) .. "m)")
        if distance <= 40 then
            arrived = true
            break
        end
        pcall(function()
            seat.MaxSpeed = speed
            seat.TurnSpeed = speed
        end)
        local angle = steerAngle(seat, targetPos)
        if math.abs(angle) <= 5 then
            pcall(function()
                seat.Throttle = 1
                seat.ThrottleFloat = 1
                if prim then
                    prim.Throttle = 1
                    prim.ThrottleFloat = 1
                end
            end)
        else
            pcall(function()
                seat.CFrame = CFrame.lookAt(pos, Vector3.new(targetPos.X, pos.Y, targetPos.Z))
                if prim then
                    prim.CFrame = CFrame.lookAt(prim.Position, Vector3.new(targetPos.X, prim.Position.Y, targetPos.Z))
                end
                seat.Throttle = 0
                seat.ThrottleFloat = 0
                if prim then
                    prim.Throttle = 0
                    prim.ThrottleFloat = 0
                end
            end)
        end
        task.wait()
    end
    pcall(function()
        seat.Throttle = 0
        seat.ThrottleFloat = 0
        seat.MaxSpeed = originalMaxSpeed
        seat.TurnSpeed = originalTurnSpeed
        seat.Torque = originalTorque
        if prim then
            prim.Throttle = 0
            prim.ThrottleFloat = 0
        end
    end)
    return arrived
end

local function getHeart()
    local map = workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("FrozenHeart") or nil
end

local function getHeartPos(heart)
    if not heart then return nil end
    if heart:IsA("BasePart") then return heart.Position end
    if heart:IsA("Model") then
        local part = heart.PrimaryPart or heart:FindFirstChildWhichIsA("BasePart")
            or heart:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end
    return nil
end

local function returnToTiki(speed)
    speed = speed or 120
    local boat = getOwnBoat()
    if not boat then
        setStatus("Sem barco para voltar")
        return false
    end
    local driverSeat = boat:FindFirstChild("VehicleSeat")
    if not driverSeat then return false end
    if not BoardSeatRetry(driverSeat) then return false end
    setStatus(T("tiki"))
    local function heartCheck(seat)
        local pos = getHeartPos(getHeart())
        if not pos then return false end
        return (pos - seat.Position).Magnitude <= 3000
    end
    local start = os.clock()
    while G.AutoLeviathanFull and os.clock() - start < 1800 do
        local heartPos = getHeartPos(getHeart())
        if not heartPos then break end
        if not driverSeat or not driverSeat.Parent or not IsSittingOn(driverSeat) then
            boat = getOwnBoat()
            driverSeat = boat and boat:FindFirstChild("VehicleSeat")
            if not driverSeat or not BoardSeatRetry(driverSeat) then break end
        end
        if (heartPos - driverSeat.Position).Magnitude > 3000 then
            sailToCF(driverSeat, CFrame.new(heartPos.X, driverSeat.Position.Y, heartPos.Z), speed)
            task.wait(1.5)
        else
            local first = sailToCF(driverSeat, TikiWaypointCF, speed, heartCheck)
            if first then
                local second = sailToCF(driverSeat, TikiReturnCF, speed, heartCheck)
                if second then
                    pcall(function() driverSeat.CFrame = TikiReturnCF end)
                    return true
                end
            end
        end
    end
    return false
end

local function harpoonPitch(from, to)
    local dx, dy, dz = to.X - from.X, to.Y - from.Y, to.Z - from.Z
    return math.atan2(dy, math.sqrt(dx * dx + dz * dz))
end

local function harpoonHeart()
    local boat = getOwnBoat()
    if not boat then return false end
    local driverSeat = boat:FindFirstChild("VehicleSeat")
    if not driverSeat then return false end
    local heart = getHeart()
    local heartPos = getHeartPos(heart)
    if not heartPos then return false end
    if heartPos.Y < 110 then return true end
    local harpoon = boat:FindFirstChild("Harpoon")
    local harpoonSeat = harpoon and harpoon:FindFirstChild("Seat")
    if not harpoonSeat then return false end
    local boatStartY = driverSeat.Position.Y
    local fires = 0
    while G.AutoLeviathanFull and fires < 10 do
        local currentHeart = getHeart()
        local currentPos = getHeartPos(currentHeart)
        if not currentHeart or not currentPos then break end
        if currentPos.Y < 110 then break end
        if not BoardSeatRetry(driverSeat) then break end
        local approachStart = os.clock()
        while G.AutoLeviathanFull and os.clock() - approachStart < 60 do
            if not driverSeat or not driverSeat.Parent then break end
            local hp = getHeartPos(getHeart())
            if not hp then break end
            local targetPoint = Vector3.new(hp.X + 300, boatStartY, hp.Z)
            sailBoatTurn(driverSeat, targetPoint, G.BoatSpeed, boatStartY)
            if not IsSittingOn(driverSeat) then break end
            if (driverSeat.Position - targetPoint).Magnitude < 10 then break end
        end
        if not IsSittingOn(driverSeat) then break end
        local adjustStart = os.clock()
        while G.AutoLeviathanFull and os.clock() - adjustStart < 15 do
            if not driverSeat or not driverSeat.Parent or not IsSittingOn(driverSeat) then break end
            local hp = getHeartPos(getHeart())
            if not hp then break end
            local pos = driverSeat.Position
            local flat = Vector3.new(hp.X - pos.X, 0, hp.Z - pos.Z)
            if flat.Magnitude < 0.5 then break end
            local yaw = math.atan2(flat.X, flat.Z) + math.pi
            pcall(function()
                driverSeat.CFrame = CFrame.new(pos.X, boatStartY, pos.Z) * CFrame.Angles(0, yaw, 0)
            end)
            local look = driverSeat.CFrame.LookVector
            local dir = flat.Unit
            if math.acos(math.clamp(look.X * dir.X + look.Z * dir.Z, -1, 1)) <= 0.02 then break end
            task.wait()
        end
        if not Unseat() then break end
        task.wait(0.3)
        if not BoardSeatRetry(harpoonSeat) then break end
        local muzzle = harpoon:FindFirstChild("Muzzle") or harpoon:FindFirstChild("Tip")
            or harpoon.PrimaryPart or harpoonSeat
        local hpAtFire = getHeartPos(getHeart())
        local pitch = muzzle and hpAtFire and (harpoonPitch(muzzle.Position, hpAtFire) + math.rad(3)) or math.rad(45)
        pcall(function()
            CommF:InvokeServer("FireHarpoon", pitch, 0, harpoon, workspace:GetServerTimeNow())
        end)
        fires = fires + 1
        local grabbed = false
        local waitStart = os.clock()
        while G.AutoLeviathanFull and os.clock() - waitStart < 10 do
            if driverSeat and driverSeat.Parent then
                local pos = driverSeat.Position
                if math.abs(pos.Y - boatStartY) > 5 then
                    pcall(function()
                        driverSeat.CFrame = CFrame.new(pos.X, boatStartY, pos.Z)
                            * (driverSeat.CFrame - driverSeat.CFrame.Position)
                    end)
                end
            end
            local finalPos = getHeartPos(getHeart())
            if not finalPos then break end
            if finalPos.Y < 110 then
                grabbed = true
                break
            end
            task.wait(0.5)
        end
        if grabbed then break end
        Unseat()
        task.wait(0.3)
    end
    Unseat()
    local finalPos = getHeartPos(getHeart())
    return finalPos ~= nil and finalPos.Y < 110
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

local function doBribe()
    if not CommF then return nil end
    local ok, result = pcall(function() return CommF:InvokeServer("InfoLeviathan", "2") end)
    if ok then return result end
    return nil
end

local function bribeUntilDone()
    local s0 = bribeStatus()
    if s0 == nil or s0 == 5 or s0 == -1 then return end
    for index = 1, 4 do
        setStatus(T("bribe") .. " " .. index .. "/4")
        doBribe()
        task.wait(0.5)
        local s = bribeStatus()
        if s == nil or s == 5 or s == -1 then break end
    end
end

local function openLeviathanGate()
    local map = workspace:FindFirstChild("Map")
    local gate = map and map:FindFirstChild("LeviathanGate")
    if not gate then return false end
    setStatus(T("gate"))
    bribeUntilDone()
    local root = eventRoot(gate)
    if root then
        tweenTo(liveFixedCF(CFrame.new(root.Position.X, root.Position.Y + 5, root.Position.Z)))
    end
    task.wait(2)
    return true
end

local function fightSeaEvent(mob, root, useSkills, shouldBreak)
    local start = os.clock()
    while G.AutoLeviathanFull and os.clock() - start < 600 do
        if shouldBreak and shouldBreak() then break end
        if not mob or not mob.Parent or not mobAlive(mob) then break end
        local currentRoot = eventRoot(mob)
        if not currentRoot then break end
        local stand = seaStand(mob, currentRoot)
        setStatus(T("seaEvent") .. mob.Name)
        AttackModel = mob
        AttackStandFn = function()
            local r = eventRoot(mob)
            return r and seaStand(mob, r) or nil
        end
        local _, hrp, hum = getCharacterParts()
        if hum and (hum.Sit or hum.SeatPart ~= nil) then ForceUnseat(5) end
        if stand and hrp and (stand.Position - hrp.Position).Magnitude > 10 then
            tweenTo(AttackStandFn, function()
                return not G.AutoLeviathanFull or not mob or not mob.Parent or (shouldBreak and shouldBreak())
            end)
        end
        if not isOnBoat() then
            if G.DragonGunFarm then
                equip("Dragonstorm")
            elseif useSkills and hrp and stand and (stand.Position - hrp.Position).Magnitude <= 80 then
                useReadySkills()
            else
                equip(hasItem(G.SelectWeapon) and G.SelectWeapon or "Sword")
            end
        end
        autoHaki()
        task.wait(0.05)
    end
    AttackModel = nil
    AttackStandFn = nil
    task.wait(0.3)
end

local FightLeviathan

FightLeviathan = function(shouldBreak, waitSeconds)
    local model, part = findLeviathan()
    if not model then return false end
    waitSeconds = waitSeconds or 6
    local waitStart = os.clock()
    while G.AutoLeviathanFull and os.clock() - waitStart < waitSeconds do
        if shouldBreak and shouldBreak() then return false end
        if not findLeviathan() then return false end
        setStatus(T("fighting") .. " " .. string.format("%.1f", waitSeconds - (os.clock() - waitStart)) .. "s")
        task.wait(0.2)
    end
    local killed = false
    local start = os.clock()
    local missingSince = nil
    while G.AutoLeviathanFull and os.clock() - start < 900 do
        if shouldBreak and shouldBreak() then break end
        local _, _, hum = getCharacterParts()
        if not hum or hum.Health <= 0 then break end
        if hum and (hum.Sit or hum.SeatPart ~= nil) then
            if not ForceUnseat(20) then break end
        end
        model, part = findLeviathan()
        if model then
            missingSince = nil
            if leviathanIsDead(model) then
                killed = true
                break
            end
        else
            missingSince = missingSince or os.clock()
            if os.clock() - missingSince >= 15 then
                killed = true
                break
            end
            task.wait(0.2)
        end
        if model then
            local hp = leviathanHP(model)
            if hum.Health < 3000 then
                setStatus("Vida baixa, subindo para evasion")
                local fleeY = RootPart and RootPart.Position.Y + 1050 or 1050
                local fleeStart = os.clock()
                while G.AutoLeviathanFull and os.clock() - fleeStart < 600 do
                    local _, hrp2, hum2 = getCharacterParts()
                    if not hrp2 or not hum2 then break end
                    if hum2.Health >= 5000 then break end
                    if hum2.Sit or hum2.SeatPart then
                        pcall(function() hum2.Sit = false end)
                    end
                    hrp2.CFrame = CFrame.new(hrp2.Position.X, fleeY, hrp2.Position.Z)
                    task.wait(0.2)
                end
            end
            setStatus(T("fighting") .. (hp and (" - " .. math.floor(hp) .. " HP") or ""))
            AttackModel = model
            AttackStandFn = function()
                if not model.Parent or leviathanIsDead(model) then return nil end
                local _, p = findLeviathan()
                return leviathanStand(model, p or part)
            end
            local stand = AttackStandFn()
            if stand then
                local _, hrp = getCharacterParts()
                if not hrp or (stand.Position - hrp.Position).Magnitude > 10 then
                    tweenTo(AttackStandFn, function()
                        return not G.AutoLeviathanFull or not model or not model.Parent
                    end)
                end
            end
            if G.DragonGunLeviathan and hasItem("Dragonstorm") then
                initDragon()
                equip("Dragonstorm")
                local target = closestSeaTarget()
                if target then fireDragonShot(target.Position, target) end
            else
                equip(hasItem(G.SelectWeapon) and G.SelectWeapon or "Sword")
                useReadySkills()
                fastM1()
            end
            autoHaki()
            autoRaceAbilities()
        end
        task.wait(0.05)
    end
    AttackModel = nil
    AttackStandFn = nil
    return killed
end

local function waitForTeammates(boat, seat, maxWait)
    local start = os.clock()
    while G.AutoLeviathanFull do
        if maxWait and os.clock() - start >= maxWait then return boat, seat end
        if not boat or not boat.Parent then return nil, nil end
        if #Players:GetPlayers() < 4 then
            if not seat or not seat.Parent then
                boat = getOwnBoat()
                seat = boat and boat:FindFirstChild("VehicleSeat")
            end
        else
            return boat, seat
        end
        task.wait(1)
    end
    return boat, seat
end

local function heartFinishPhase()
    if not getOwnBoat() then
        buyOwnBoat(T("boat"))
    end
    if not harpoonHeart() then return end
    task.wait(5)
    local boat = getOwnBoat()
    local seat = boat and boat:FindFirstChild("VehicleSeat")
    if seat and not IsSittingOn(seat) then BoardSeatRetry(seat) end
    task.wait(10)
    local returned = returnToTiki(120)
    local start = os.clock()
    while G.AutoLeviathanFull and os.clock() - start < 1800 do
        local heart = getHeart()
        if not heart then break end
        local gone = false
        if heart:IsA("BasePart") then
            gone = heart.Transparency >= 1
        elseif heart:IsA("Model") then
            local primary = heart.PrimaryPart
            gone = primary == nil or primary.Transparency >= 1
        end
        if gone then break end
        if returned and seat and IsSittingOn(seat) then
            pcall(function()
                seat.ThrottleFloat = 1
                seat.SteerFloat = 0
            end)
        end
        task.wait(2)
    end
    Unseat()
    buyOwnBoat(T("boat"))
end

local HuntStart = nil

local function captainHuntPhase()
    HuntStart = HuntStart or os.clock()
    local map = workspace:FindFirstChild("Map")
    local success = leviathanExists() or (map and map:FindFirstChild("LeviathanGate") ~= nil)
    local boat = nil
    local seat = nil
    if not success then
        boat = getOwnBoat()
        if not boat then
            buyOwnBoat(T("boat"))
            boat = getOwnBoat()
        end
        if not boat then return end
        seat = boat:FindFirstChild("VehicleSeat")
        if not seat or not BoardSeatRetry(seat) then return end
        noClip(true)
    end
    local lastHuntCheck = 0
    local lastTeamCheck = 0
    local lastMobCheck = 0
    while G.AutoLeviathanFull and not success do
        if not boat or not boat.Parent or AbandonedBoats[boat] then return end
        if not IsSittingOn(seat) then
            if not BoardSeatRetry(seat, 5, 2) then return end
        end
        if os.clock() - lastHuntCheck >= 0.2 then
            lastHuntCheck = os.clock()
            map = workspace:FindFirstChild("Map")
            if leviathanExists() or (map and map:FindFirstChild("LeviathanGate")) then
                setStatus("Portao do Leviathan encontrado")
                success = true
                break
            end
            setStatus(T("hunting") .. " " .. math.floor(os.clock() - HuntStart) .. "s")
        end
        if os.clock() - lastTeamCheck >= 1 then
            lastTeamCheck = os.clock()
            if not G.SoloSeaFarm and #Players:GetPlayers() < 4 then
                boat, seat = waitForTeammates(boat, seat)
                if not boat or not seat then return end
            end
        end
        if G.HuntFightEvents and os.clock() - lastMobCheck >= 0.5 then
            lastMobCheck = os.clock()
            local mob, root, skill = findSeaMob(5000)
            if mob and root then
                if not Unseat() then
                    setStatus("Nao consegui sair do barco")
                end
                local stuck = {}
                while G.AutoLeviathanFull do
                    map = workspace:FindFirstChild("Map")
                    if leviathanExists() or (map and map:FindFirstChild("LeviathanGate")) then break end
                    local nextMob, nextRoot, nextSkill = findSeaMob(5000, stuck)
                    if not nextMob or not nextRoot then break end
                    fightSeaEvent(nextMob, nextRoot, nextSkill, function()
                        local m = workspace:FindFirstChild("Map")
                        return leviathanExists() or (m and m:FindFirstChild("LeviathanGate") ~= nil)
                    end)
                    if mobAlive(nextMob) then stuck[nextMob] = true end
                    task.wait(0.5)
                end
                if seat and seat.Parent then BoardSeatRetry(seat) end
            end
        end
        if sailBoatStream(seat, G.BoatSpeed) == false then
            local newBoat = getOwnBoat()
            local newSeat = newBoat and newBoat:FindFirstChild("VehicleSeat")
            if newSeat and BoardSeatRetry(newSeat) then
                boat, seat = newBoat, newSeat
            else
                buyOwnBoat(T("boat"))
            end
        end
    end
    if not success then return end
    HuntStart = nil
    if not Unseat() then return end
    openLeviathanGate()
    local killed = FightLeviathan(nil, 6)
    if not killed then
        setStatus("Leviathan nao derrotado")
        return
    end
    setStatus(T("dead"))
    if not getOwnBoat() then buyOwnBoat(T("boat")) end
    local heartStart = os.clock()
    while G.AutoLeviathanFull and os.clock() - heartStart < 900 do
        if getHeart() then
            setStatus(T("heart"))
            break
        end
        task.wait(1)
    end
    task.wait(20)
    heartFinishPhase()
end

local function followerBoard(boat)
    local seat = boat:FindFirstChild("VehicleSeat")
    if not seat then return nil end
    if not BoardSeatRetry(seat, 10, 3) then return nil end
    return seat
end

local function followerLoop()
    while G.AutoLeviathanFull and G.Mode == "Seguidor" do
        local targetName = G.FollowTarget
        local target = targetName ~= "" and Players:FindFirstChild(targetName) or nil
        if not target then
            setStatus("Sem alvo para seguir")
            task.wait(2)
        else
            local boat = getOwnBoat() or getOwnBoat(true)
            local seat = boat and followerBoard(boat)
            local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local _, hrp = getCharacterParts()
                if seat and hrp and (hrp.Position - targetRoot.Position).Magnitude > 300 then
                    pcall(function()
                        seat.CFrame = CFrame.lookAt(seat.Position, Vector3.new(targetRoot.Position.X, seat.Position.Y, targetRoot.Position.Z))
                        seat.Throttle = 1
                        seat.ThrottleFloat = 1
                    end)
                end
            end
            local heart = getHeart()
            if heart then
                if seat then Unseat() end
                harpoonHeart()
            end
            task.wait(0.5)
        end
    end
end

local WebhookCache = {}

local function requestHttp(url, payload)
    local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
    if not requestFn then return false, "sem request" end
    local ok, response = pcall(requestFn, {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })
    if not ok then return false, response end
    return true, response
end

local function sendWebhook(content, title, ping)
    if not G.AutoWebhook or not G.WebhookURL or G.WebhookURL == "" then return end
    local key = tostring(content)
    if WebhookCache[key] and os.time() - WebhookCache[key] < 5 then return end
    WebhookCache[key] = os.time()
    local payload = {
        username = G.WebhookUsername,
        content = ping and "@everyone\n" .. content or content,
        embeds = { { title = title or "Kaitun Leviathan", description = content, color = 3447003 } },
    }
    task.spawn(function()
        local ok, response = requestHttp(G.WebhookURL, payload)
        if not ok then
            print("[Webhook] " .. tostring(response))
        end
    end)
end

local function buildProgress()
    local players = #Players:GetPlayers()
    local s = bribeStatus()
    return table.concat({
        "**Status:** " .. StatusText,
        "**Jogadores:** " .. players,
        "**Suborno:** " .. (s and tostring(s) .. "/5" or "?"),
        "**Modo:** " .. tostring(G.Mode),
    }, "\n")
end

task.spawn(function()
    while true do
        task.wait(math.max(10, G.WebhookInterval or 60))
        if G.AutoWebhook and G.WebhookSendProgress then
            pcall(sendWebhook, buildProgress(), "Progresso")
        end
    end
end)

task.spawn(function()
    local prevBribe, prevLeviathan, prevHeart, prevHeartGot, prevLow = nil, false, false, false, false
    while true do
        task.wait(1)
        if not G.AutoWebhook or not G.WebhookURL or G.WebhookURL == "" then
            prevBribe, prevLeviathan, prevHeart, prevHeartGot, prevLow = nil, false, false, false, false
        else
            pcall(function()
                if G.WebhookSendBribeReady then
                    local s = bribeStatus()
                    local ready = s ~= nil and s ~= -1 and s ~= 5
                    if ready and prevBribe == false then
                        sendWebhook("Suborno disponivel: " .. tostring(s) .. "/5", "Suborno")
                    end
                    prevBribe = ready
                end
                if G.WebhookSendLeviathan then
                    local now = leviathanExists()
                    if now and not prevLeviathan then sendWebhook("Leviathan apareceu!", "Leviathan") end
                    prevLeviathan = now
                end
                if G.WebhookSendHeartSpawn then
                    local now = getHeart() ~= nil
                    if now and not prevHeart then sendWebhook("Coração congelado apareceu", "Coração") end
                    prevHeart = now
                end
                if G.WebhookSendHeartGot then
                    local pos = getHeartPos(getHeart())
                    local got = pos ~= nil and pos.Y < 110
                    if got and not prevHeartGot then sendWebhook("Coração capturado", "Coração") end
                    prevHeartGot = got
                end
                if G.WebhookSendLowPlayers then
                    local count = #Players:GetPlayers()
                    local low = count < 5
                    if low and not prevLow then
                        sendWebhook("Poucos jogadores: " .. count .. "\n" .. buildProgress(), "Servidor", true)
                    end
                    prevLow = low
                end
            end)
        end
    end
end)

local function removeFog()
    pcall(function()
        local lighting = game:GetService("Lighting")
        local layers = lighting:FindFirstChild("LightingLayers")
        if layers then layers:Destroy() end
        lighting.FogEnd = 100000
    end)
end

local function applyFPSBoost()
    pcall(function()
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.ShadowSoftness = 0
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("BasePart") then
                object.Material = Enum.Material.Plastic
                object.Reflectance = 0
            elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Smoke") then
                object.Enabled = false
            end
        end
        workspace.DescendantAdded:Connect(function(object)
            if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Smoke") then
                pcall(function() object.Enabled = false end)
            end
        end)
    end)
end

local function applyAntiDracoAura()
    pcall(function()
        if setreadonly and getreadonly then
            local ok, settingsTable = pcall(getreadonly, game:GetService("ReplicatedStorage"))
            if ok then return end
        end
    end)
end

local function applyFastMode()
    pcall(function()
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("BasePart") then
                object.Material = Enum.Material.Plastic
            end
        end
    end)
end

task.spawn(function()
    while true do
        pcall(function()
            local rocks = workspace:FindFirstChild("Rocks")
            if rocks then rocks:Destroy() end
        end)
        task.wait(0.5)
    end
end)

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
        pcall(function()
            if type(sethiddenproperty) == "function" then
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            else
                LocalPlayer.SimulationRadius = math.huge
            end
        end)
        task.wait(1)
    end
end)

local FruitBlacklist = { "Kitsune", "Dragon", "Spirit", "Dough", "Buddha" }

local function autoStoreFruits()
    while G.AutoStoreFruits and G.AutoLeviathanFull do
        pcall(function()
            local fruit = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if fruit and fruit.ToolTip == "Blox Fruit" then
                CommF:InvokeServer("StoreFruit", fruit.Name)
            end
        end)
        task.wait(5)
    end
end

local function autoRandomFruit()
    while G.AutoRandomFruit and G.AutoLeviathanFull do
        pcall(function()
            local _, result = CommF:InvokeServer("CandyCane", "Buy", false)
            if result then notify("Kaitun", "Fruta comprada") end
        end)
        task.wait(30)
    end
end

local function autoCraft()
    while G.AutoCraftScrolls and G.AutoLeviathanFull do
        pcall(function()
            local quality = G.CraftQuality
            if quality and quality ~= "None" then
                CommF:InvokeServer("CraftScroll", quality)
            end
        end)
        task.wait(10)
    end
end

local function startAutomation()
    task.spawn(function()
        while G.AutoLeviathanFull do
            if G.Mode == "Capitao" then
                pcall(captainHuntPhase)
            else
                pcall(followerLoop)
            end
            task.wait(1)
        end
    end)
    task.spawn(function()
        while G.AutoLeviathanFull do
            pcall(function()
                if G.FastAttack and not isOnBoat() then fastM1() end
                autoHaki()
            end)
            task.wait(G.FastAttack and 0.12 or 0.5)
        end
    end)
    if G.DragonGunFarm then startDragonAttack() end
    if G.AutoStoreFruits then task.spawn(autoStoreFruits) end
    if G.AutoRandomFruit then task.spawn(autoRandomFruit) end
    if G.AutoCraftScrolls then task.spawn(autoCraft) end
    if G.RemoveFog then removeFog() end
    if G.FPSBoost then applyFPSBoost() end
    if G.AntiDracoAura then applyAntiDracoAura() end
    if G.AutoFastMode then applyFastMode() end
end

local function stopAutomation()
    stopTweenAll()
    noClip(false)
    AttackModel = nil
    AttackStandFn = nil
end

local InfoGui = nil
local InfoLabel = nil

local function createInfoUI()
    if InfoGui then return end
    local container = gethui and gethui() or game:GetService("CoreGui")
    InfoGui = Instance.new("ScreenGui")
    InfoGui.Name = "KaitunLeviathanInfo"
    InfoGui.ResetOnSpawn = false
    InfoGui.IgnoreGuiInset = true
    InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, 0, 0, 28)
    InfoLabel.Position = UDim2.new(0, 0, 0, 0)
    InfoLabel.BackgroundTransparency = 0.45
    InfoLabel.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    InfoLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
    InfoLabel.Font = Enum.Font.GothamBold
    InfoLabel.TextSize = 14
    InfoLabel.Parent = InfoGui
    pcall(function() InfoGui.Parent = container end)
    if not InfoGui.Parent then
        InfoGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    addStatusListener(function(text)
        if InfoLabel then
            pcall(function()
                InfoLabel.Text = "Kaitun Leviathan | " .. text .. " | Jogadores: " .. #Players:GetPlayers()
            end)
        end
    end)
end

task.spawn(function()
    while true do
        if G.ShowInfoUI and not InfoGui then
            pcall(createInfoUI)
        elseif InfoGui then
            InfoGui.Enabled = G.ShowInfoUI == true
        end
        task.wait(0.5)
    end
end)

local Fluent = nil
local SaveManager = nil
local InterfaceManager = nil
local Window = nil

local function buildUI()
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)
    if not Fluent then
        warn("[Kaitun] UI indisponivel")
        return
    end
    pcall(function()
        SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
        InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
    SendNotify = function(title, content)
        pcall(function()
            Fluent:Notify({ Title = title or "Kaitun", Content = content or "", Duration = 4 })
        end)
    end

    Window = Fluent:CreateWindow({
        Title = "Kaitun Leviathan",
        SubTitle = "Auto find / attack / sail back",
        TabWidth = 160,
        Size = UDim2.fromOffset(520, 380),
        Acrylic = true,
        Theme = "Dark",
        MinKeyCode = Enum.KeyCode[G.MenuKeybind or "G"],
    })

    local function addToggle(tab, id, title, key, callback)
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

    local function addSlider(tab, id, title, key, min, max)
        tab:AddSlider(id, {
            Title = title,
            Default = G[key],
            Min = min,
            Max = max,
            Rounding = 0,
            Callback = function(value)
                G[key] = value
                saveConfig()
            end,
        })
    end

    local function addDropdown(tab, id, title, key, values, callback)
        tab:AddDropdown(id, {
            Title = title,
            Values = values,
            Default = G[key],
            Multi = false,
            Callback = function(value)
                G[key] = value
                saveConfig()
                if callback then callback(value) end
            end,
        })
    end

    local Main = Window:AddTab("Principal")
    local HuntTab = Window:AddTab("Caca")
    local CombatTab = Window:AddTab("Combate")
    local BoatTab = Window:AddTab("Barco")
    local WebTab = Window:AddTab("Webhook")
    local ConfigTab = Window:AddTab("Config")

    Main:AddToggle("main.enabled", {
        Title = "Auto Leviathan Full",
        Default = G.AutoLeviathanFull,
        Callback = function(state)
            G.AutoLeviathanFull = state
            if state then
                setStatus(T("start"))
                startAutomation()
            else
                stopAutomation()
                setStatus(T("stop"))
            end
            saveConfig()
        end,
    })

    addDropdown(Main, "main.language", "Idioma", "Language", { "Portugues", "English", "Espanol" })
    addDropdown(Main, "main.mode", "Modo", "Mode", { "Capitao", "Seguidor" })

    local playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then playerNames[#playerNames + 1] = player.Name end
    end
    addDropdown(Main, "main.follow", "Seguir jogador", "FollowTarget", #playerNames > 0 and playerNames or { "Nenhum" })

    addToggle(Main, "main.info", "Painel de status", "ShowInfoUI")
    addToggle(Main, "main.ball", "Botao flutuante", "FloatingBall")

    addToggle(HuntTab, "hunt.events", "Atacar eventos marinhos na caca", "HuntFightEvents")
    local eventValues = {
        "Terrorshark", "Piranha", "Shark", "Ghost Ship",
        "Pirate Brigade Ship", "Pirate Grand Brigade Ship", "Pirate Basic Ship", "Sea Beast",
    }
    HuntTab:AddDropdown("hunt.select", {
        Title = "Eventos permitidos (vazio = todos)",
        Values = eventValues,
        Default = G.HuntSelectEvents,
        Multi = true,
        Callback = function(value)
            G.HuntSelectEvents = value
            saveConfig()
        end,
    })
    addToggle(HuntTab, "hunt.solo", "Farm marinho solo", "SoloSeaFarm")
    addToggle(HuntTab, "hunt.respawn", "Recomprar ao morrer", "RespawnRebuy")

    addDropdown(CombatTab, "combat.weapon", "Arma", "SelectWeapon", { "Melee", "Sword", "Gun", "Blox Fruit" })
    addToggle(CombatTab, "combat.fast", "Fast attack", "FastAttack")
    addDropdown(CombatTab, "combat.fastmode", "Modo fast attack", "FastAttack_Mode", { "1", "2" })
    addToggle(CombatTab, "combat.buso", "Buso automatico", "AutoBuso")
    addToggle(CombatTab, "combat.ken", "Ken automatico", "AutoKen")
    addToggle(CombatTab, "combat.v3", "Race V3", "AutoV3")
    addToggle(CombatTab, "combat.v4", "Race V4", "AutoV4")
    addToggle(CombatTab, "combat.dfarm", "Dragonstorm em eventos", "DragonGunFarm")
    addToggle(CombatTab, "combat.dlev", "Dragonstorm no Leviathan", "DragonGunLeviathan")

    addSlider(BoatTab, "boat.speed", "Velocidade do barco", "BoatSpeed", 50, 500)
    addSlider(BoatTab, "boat.height", "Altura do barco", "BoatHeight", 30, 500)
    addSlider(BoatTab, "boat.tween", "Velocidade do teleporte", "PlayerTweenSpeed", 50, 500)
    addToggle(BoatTab, "boat.return", "Voltar para Tiki", "CruiseReturn")

    WebTab:AddInput("web.url", {
        Title = "URL do webhook",
        Default = G.WebhookURL,
        Callback = function(value)
            G.WebhookURL = value
            saveConfig()
        end,
    })
    WebTab:AddInput("web.name", {
        Title = "Nome do bot",
        Default = G.WebhookUsername,
        Callback = function(value)
            G.WebhookUsername = value
            saveConfig()
        end,
    })
    addToggle(WebTab, "web.enabled", "Webhook ativo", "AutoWebhook")
    addSlider(WebTab, "web.interval", "Intervalo (s)", "WebhookInterval", 10, 600)
    addToggle(WebTab, "web.progress", "Enviar progresso", "WebhookSendProgress")
    addToggle(WebTab, "web.bribe", "Avisar suborno", "WebhookSendBribeReady")
    addToggle(WebTab, "web.leviathan", "Avisar Leviathan", "WebhookSendLeviathan")
    addToggle(WebTab, "web.heartspawn", "Avisar coracao", "WebhookSendHeartSpawn")
    addToggle(WebTab, "web.heartgot", "Avisar captura", "WebhookSendHeartGot")
    addToggle(WebTab, "web.low", "Avisar servidor vazio", "WebhookSendLowPlayers")
    WebTab:AddButton({
        Title = "Enviar agora",
        Callback = function() pcall(sendWebhook, buildProgress(), "Manual") end,
    })

    addToggle(ConfigTab, "config.fog", "Remover nebula", "RemoveFog")
    addToggle(ConfigTab, "config.fps", "FPS boost", "FPSBoost")
    addToggle(ConfigTab, "config.fastmode", "Fast mode", "AutoFastMode")
    addToggle(ConfigTab, "config.draco", "Anti Draco Aura", "AntiDracoAura")
    addToggle(ConfigTab, "config.craft", "Craft automatico", "AutoCraftScrolls")
    addDropdown(ConfigTab, "config.quality", "Qualidade do scroll", "CraftQuality", { "None", "Low", "Mid", "High" })
    addToggle(ConfigTab, "config.fruit", "Fruta aleatoria", "AutoRandomFruit")
    addToggle(ConfigTab, "config.store", "Guardar frutas", "AutoStoreFruits")
    ConfigTab:AddButton({
        Title = "Salvar config",
        Callback = function()
            saveConfig()
            notify("Kaitun", "Config salva")
        end,
    })

    pcall(function()
        if not SaveManager or not InterfaceManager then return end
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        InterfaceManager.Settings.MenuKeybind = G.MenuKeybind or "G"
        InterfaceManager:SetFolder("KaitunLeviathan")
        SaveManager:SetFolder("KaitunLeviathan/configs")
        InterfaceManager:BuildInterfaceSection(ConfigTab)
        SaveManager:BuildConfigSection(ConfigTab)
        SaveManager:LoadAutoloadConfig()
    end)

    Window:SelectTab(1)
    pcall(notify, T("ready"), "Kaitun Leviathan carregado")
end

task.spawn(buildUI)

local BallGui = nil
local BallConnections = {}

local function destroyFloatingBall()
    for _, connection in ipairs(BallConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(BallConnections)
    if BallGui then
        pcall(function() BallGui:Destroy() end)
        BallGui = nil
    end
end

local function createFloatingBall()
    if BallGui then return end
    BallGui = Instance.new("ScreenGui")
    BallGui.Name = "KaitunLeviathanBall"
    BallGui.ResetOnSpawn = false
    BallGui.IgnoreGuiInset = true
    BallGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    BallGui.DisplayOrder = 999

    local ball = Instance.new("TextButton")
    ball.Name = "Orb"
    ball.Size = UDim2.fromOffset(52, 52)
    ball.Position = UDim2.fromOffset(16, 200)
    ball.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    ball.BackgroundTransparency = 0.05
    ball.AutoButtonColor = false
    ball.Text = "KL"
    ball.Font = Enum.Font.GothamBold
    ball.TextSize = 15
    ball.TextColor3 = Color3.fromRGB(240, 240, 245)
    ball.Parent = BallGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ball

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(96, 205, 255)
    stroke.Transparency = 0.2
    stroke.Parent = ball

    local parentOk = pcall(function()
        BallGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not parentOk or not BallGui.Parent then
        BallGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local dragging, moved, last, travelled = false, false, nil, 0
    BallConnections[#BallConnections + 1] = ball.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            last = nil
            travelled = 0
        end
    end)
    BallConnections[#BallConnections + 1] = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local now = Vector2.new(input.Position.X, input.Position.Y)
        local step = last and (now - last) or Vector2.zero
        last = now
        travelled = travelled + step.Magnitude
        if travelled > 5 then moved = true end
        if step.Magnitude > 0 then
            local screen = BallGui.AbsoluteSize
            if screen.X <= 0 or screen.Y <= 0 then
                screen = workspace.CurrentCamera.ViewportSize
            end
            local size = ball.AbsoluteSize
            local pos = ball.Position
            local x = pos.X.Scale * screen.X + pos.X.Offset + step.X
            local y = pos.Y.Scale * screen.Y + pos.Y.Offset + step.Y
            ball.Position = UDim2.fromOffset(
                math.clamp(x, 0, math.max(0, screen.X - size.X)),
                math.clamp(y, 0, math.max(0, screen.Y - size.Y))
            )
        end
    end)
    BallConnections[#BallConnections + 1] = UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = false
        if moved then return end
        if Window and Window.Root then
            Window.Root.Visible = not Window.Root.Visible
            Window.Minimized = not Window.Root.Visible
        end
    end)
end

task.spawn(function()
    while true do
        if G.FloatingBall and not BallGui then
            pcall(createFloatingBall)
        elseif not G.FloatingBall and BallGui then
            destroyFloatingBall()
        end
        task.wait(0.5)
    end
end)

setStatus(T("ready"))
print("[Kaitun Leviathan] Carregado")
