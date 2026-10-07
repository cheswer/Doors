warn("--- [R4NS0M] EXECUTING SCRIPT ---")
pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "R4NS0M", Text = "Script iniciado, cargando UI...", Duration = 6 }) end)
--[[
  R4NS0M CD-1  |  Team CHX
  Version 1.0.0
  Tabs: Main, Info, Visuals, Player, Automation, Anticheat, Antis, Alerts, Misc, Keybinds, Configs
  Ransomity is real
]]
print("[R4NS0M] Loading Services")
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

math.randomseed(os.time())

print("[R4NS0M] Services Loaded")
print("[R4NS0M] Loading Icon")
----------------------------------------------------
-- ICON LOADER (fixed)
-- El ID 107740382639133 suele ser un DECAL. assetdelivery devuelve XML
-- para decals (no un PNG), por eso no cargaba. Aqui resolvemos el ID real
-- de la imagen y validamos que lo descargado sea un PNG de verdad.
----------------------------------------------------
local ICON_ID = 107740382639133
local ICON_FILE = "R4NS0M_Icon.png"
local FALLBACK_ICON = "shield" -- icono lucide, siempre funciona

local function IsPng(data)
    return type(data) == "string" and #data > 8 and data:sub(2, 4) == "PNG"
end

local function ResolveImageId(id)
    -- Si es un Decal, saca el ID de la textura real
    local ok, result = pcall(function()
        local obj = game:GetObjects("rbxassetid://" .. id)[1]
        if obj then
            local tex = obj.Texture or obj.Image or obj.ColorMapContent
            if tex then
                return tostring(tex):match("id=(%d+)") or tostring(tex):match("(%d+)$")
            end
        end
    end)
    if ok and result then
        return result
    end
    return tostring(id)
end

local function GetIconAsset()
    local canFile = isfile and writefile and readfile and getcustomasset

    -- 1) Usar archivo cacheado si es un PNG valido
    if canFile and isfile(ICON_FILE) then
        local ok, data = pcall(readfile, ICON_FILE)
        if ok and IsPng(data) then
            local ok2, asset = pcall(getcustomasset, ICON_FILE)
            if ok2 and asset then
                return asset
            end
        elseif delfile then
            pcall(delfile, ICON_FILE) -- archivo corrupto de intentos anteriores
        end
    end

    -- 2) Resolver ID real y descargar
    local imageId = ResolveImageId(ICON_ID)

    if canFile then
        local ok, data = pcall(function()
            return game:HttpGet("https://assetdelivery.roblox.com/v1/asset/?id=" .. imageId)
        end)
        if ok and IsPng(data) then
            pcall(writefile, ICON_FILE, data)
            local ok2, asset = pcall(getcustomasset, ICON_FILE)
            if ok2 and asset then
                return asset
            end
        end
    end

    -- 3) Usar el ID de imagen resuelto directamente
    if imageId and imageId ~= tostring(ICON_ID) then
        return "rbxassetid://" .. imageId
    end

    -- 4) Fallback seguro (icono lucide de WindUI)
    return FALLBACK_ICON
end

local IconAsset = FALLBACK_ICON
pcall(function()
    -- Solo usa el PNG ya cacheado (instantaneo). Nunca espera a la red.
    if isfile and readfile and getcustomasset and isfile(ICON_FILE) then
        local data = readfile(ICON_FILE)
        if IsPng(data) then
            local asset = getcustomasset(ICON_FILE)
            if asset then IconAsset = asset end
        end
    end
end)
-- Descarga/cachea el icono en segundo plano para la proxima ejecucion
task.spawn(function() pcall(GetIconAsset) end)

print("[R4NS0M] Icon loaded")
print("[R4NS0M] Loading Execution Count")
----------------------------------------------------
-- EXECUTION COUNTER
----------------------------------------------------
local ExecCountFile = "R4NS0M_ExecCount.txt"
local executionCount = 1

if isfile and readfile and writefile then
    if isfile(ExecCountFile) then
        local ok, raw = pcall(readfile, ExecCountFile)
        local current = ok and tonumber(raw)
        if current then
            executionCount = current + 1
        end
    end
    pcall(writefile, ExecCountFile, tostring(executionCount))
end

-- Identify Executor
local currentExecutor = "Unknown Executor"
if identifyexecutor then
    currentExecutor = identifyexecutor()
elseif getexecutorname then
    currentExecutor = getexecutorname()
end

print("[R4NS0M] Execution Count loaded")
print("[R4NS0M] Loading WindUI")
----------------------------------------------------
-- LOAD WINDUI (con pcall)
----------------------------------------------------
local WindUI, Window = (function()
    local env = (getgenv and getgenv()) or _G

    -- Stubs para ejecutores (sobre todo moviles) que no traen estas funciones.
    -- WindUI las llama al cargar y daba "attempt to call a nil value".
    local permanent = {
        isfolder  = function() return false end,
        makefolder = function() end,
        cloneref  = function(o) return o end,
        gethui    = function() return game:GetService("CoreGui") end,
    }
    local temporary = {
        isfile    = function() return false end,
        readfile  = function() return "" end,
        writefile = function() end,
        listfiles = function() return {} end,
        delfile   = function() end,
        delfolder = function() end,
    }
    local addedTemp = {}
    for name, fn in pairs(permanent) do
        if type(env[name]) ~= "function" then pcall(function() env[name] = fn end) end
    end
    for name, fn in pairs(temporary) do
        if type(env[name]) ~= "function" then
            local ok = pcall(function() env[name] = fn end)
            if ok then addedTemp[#addedTemp + 1] = name end
        end
    end

    local function notify(msg)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "R4NS0M", Text = msg, Duration = 8
            })
        end)
    end

    local sources = {
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
        "https://github.com/Footagesus/WindUI/releases/download/1.6.41/main.lua",
    }

    local function withTimeout(seconds, fn)
        local done, result = false, nil
        task.spawn(function()
            local ok, r = pcall(fn)
            if ok then result = r end
            done = true
        end)
        local t0 = os.clock()
        while not done and os.clock() - t0 < seconds do task.wait(0.1) end
        if not done then warn("[R4NS0M] Timeout esperando WindUI") end
        return result
    end

    local function tryLoadRaw(url)
        local okGet, src = pcall(function() return game:HttpGet(url) end)
        if not okGet or type(src) ~= "string" or #src < 1000 then
            warn("[R4NS0M] HttpGet fallo: " .. url .. " -> " .. tostring(src))
            return nil
        end
        local fn, cerr = loadstring(src)
        if type(fn) ~= "function" then
            warn("[R4NS0M] loadstring fallo: " .. url .. " -> " .. tostring(cerr))
            return nil
        end
        local okRun, lib = pcall(fn)
        if not okRun or type(lib) ~= "table" or type(lib.CreateWindow) ~= "function" then
            warn("[R4NS0M] WindUI invalido: " .. url .. " -> " .. tostring(lib))
            return nil
        end
        return lib
    end

    local function makeWindow(lib, icon, full)
        local cfg = {
            Title = "R4NS0M CD-1",
            Icon = icon,
            Author = "Team CHX",
            Folder = "R4NS0M_Configs",
            Size = UDim2.fromOffset(580, 460),
            Theme = "Dark",
        }
        if full then
            cfg.Transparent = true
            cfg.SideBarWidth = 170
            cfg.HasOutline = true
        end
        return pcall(function() return lib:CreateWindow(cfg) end)
    end

    local lib, win
    for _, url in ipairs(sources) do
        local candidate = withTimeout(25, function() return tryLoadRaw(url) end)
        if candidate then
            -- Intenta con la config completa, luego con otro icono, luego minima
            local ok, w = makeWindow(candidate, IconAsset, true)
            if not ok then
                warn("[R4NS0M] CreateWindow fallo (config completa): " .. tostring(w))
                ok, w = makeWindow(candidate, FALLBACK_ICON, true)
            end
            if not ok then
                warn("[R4NS0M] CreateWindow fallo (icono fallback): " .. tostring(w))
                ok, w = makeWindow(candidate, FALLBACK_ICON, false)
            end
            if ok and w then
                lib, win = candidate, w
                break
            end
            warn("[R4NS0M] CreateWindow fallo (config minima): " .. tostring(w))
        end
    end

    for _, name in ipairs(addedTemp) do
        pcall(function() env[name] = nil end)
    end

    if not lib or not win then
        warn("[R4NS0M] No se pudo cargar WindUI desde ninguna fuente")
        notify("No se pudo cargar la UI. Revisa tu internet/ejecutor y reintenta.")
        return nil, nil
    end
    return lib, win
end)()

if not WindUI or not Window then
    return
end

-- Tabs (orden fijo)
local MainTab       = Window:Tab({ Title = "Main",       Icon = "house" })
local InfoTab       = Window:Tab({ Title = "Info",       Icon = "info" })
local VisualsTab    = Window:Tab({ Title = "Visuals",    Icon = "eye" })
local PlayerTab     = Window:Tab({ Title = "Player",     Icon = "user" })
local AutomationTab = Window:Tab({ Title = "Automation", Icon = "zap" })
local AntiCheatTab  = Window:Tab({ Title = "Anticheat", Icon = "shield" })
local AntisTab      = Window:Tab({ Title = "Antis",      Icon = "ban" })
local AlertsTab     = Window:Tab({ Title = "Alerts",     Icon = "bell" })
local MiscTab       = Window:Tab({ Title = "Misc",       Icon = "ellipsis" })
local KeybindsTab   = Window:Tab({ Title = "Keybinds",   Icon = "keyboard" })
local ConfigsTab    = Window:Tab({ Title = "Configs",    Icon = "settings" })

-- Tabs sin funciones todavia: un aviso para que no queden en blanco
for _, t in ipairs({}) do
    t:Paragraph({ Title = "Coming soon", Desc = "This tab has no features yet." })
end

print("[R4NS0M] WindUI loaded")
print("[R4NS0M] Loading Info Tab")
----------------------------------------------------
-- INFO TAB
----------------------------------------------------
InfoTab:Section({ Title = "Player Information" })

-- rbxthumb funciona siempre, sin depender de GetUserThumbnailAsync
local avatarUrl = string.format(
    "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
    LocalPlayer.UserId
)

InfoTab:Paragraph({
    Title = "User Profile",
    Desc = string.format(
        "Username: %s\nDisplay Name: %s\nUser ID: %d\nExecutor: %s\nExecutions: %d",
        LocalPlayer.Name,
        LocalPlayer.DisplayName,
        LocalPlayer.UserId,
        currentExecutor,
        executionCount
    ),
    Image = avatarUrl,
    ImageSize = 48
})

InfoTab:Section({ Title = "Live Session" })
local sessionPara = InfoTab:Paragraph({ Title = "Session", Desc = "Reading game data..." })
task.spawn(function()
    local RunSvc = game:GetService("RunService")
    local frames, last = 0, os.clock()
    RunSvc.RenderStepped:Connect(function() frames = frames + 1 end)
    local started = os.clock()
    while true do
        task.wait(1)
        local now = os.clock()
        local fps = math.floor(frames / math.max(now - last, 0.001) + 0.5)
        frames, last = 0, now
        local floorName, room, ping, playersN = "Lobby", "-", "?", #game:GetService("Players"):GetPlayers()
        pcall(function()
            local gd = game:GetService("ReplicatedStorage"):FindFirstChild("GameData")
            local f = gd and gd:FindFirstChild("Floor")
            if f then floorName = tostring(f.Value) end
        end)
        pcall(function() room = tostring(LocalPlayer:GetAttribute("CurrentRoom") or "-") end)
        pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms" end)
        local mins = math.floor((now - started) / 60)
        local txt = string.format(
            "Floor: %s\nCurrent Room: %s\nPlayers: %d\nFPS: %d\nPing: %s\nTime with the script: %d min",
            floorName, room, playersN, fps, ping, mins
        )
        pcall(function() sessionPara:SetDesc(txt) end)
    end
end)

InfoTab:Section({ Title = "Script Information" })

InfoTab:Paragraph({
    Title = "About R4NS0M CD-1",
    Desc = "A specialized DOORS script developed by Team CHX (Created by 2 developers).\nVersion: 1.0.0"
})

InfoTab:Paragraph({
    Title = "Where to find things",
    Desc = "Visuals: ESP, chase paths (Seek / Eyestalk) and lighting.\n"
        .. "Player: movement, speed, jump, fly, noclip.\n"
        .. "Automation: Auto Interact (with ignore list), library code, minecart, Dam Seek, Cringle.\n"
        .. "Anticheat: position / crouch spoof and manipulation.\n"
        .. "Antis: entity bypasses and the Seek / Figure combos.\n"
        .. "Alerts: entity, item, library code and Ransom notifications.\n"
        .. "Misc: revive and utilities.\n"
        .. "Keybinds: every key and floating button can be rebound.\n"
        .. "Configs: save and load your setup."
})

InfoTab:Paragraph({
    Title = "Good to know",
    Desc = "Features marked experimental may fail on some floors: check the console if something does not respond.\n"
        .. "On mobile, the floating buttons can be shown or hidden from the Keybinds tab.\n"
        .. "Changing game mode while playing reconfigures the script and adds the new options at the bottom of Visuals."
})

print("[R4NS0M] Info tab loaded")
print("[R4NS0M] Loading ESP")
print("[R4NS0M] Loading Item ESP (0/4)")
----------------------------------------------------
-- VISUALS / ESP
----------------------------------------------------
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
-- Nombres oficiales de items (fuente: DOORS Wiki - Category:Items / Item Skins)
local ITEM_NAMES = {
    "Alarm Clock", "Aloe", "Bandage", "Bandage Pack", "Battery", "Battery Pack", "Boxing Gloves", "Buddy", "Bulklight",
    "Bread", "Candle", "Candy", "Trick or Treat Bag", "Compass", "Crucifix", "Disc", "Donut", "Fih Flakes", "Flare", "Flashlight", "Glowstick",
    "Gold Gun", "Green Herb", "Gween Soda", "Holy Hand Grenade", "Honcho Mug", "Mug", "Lunch Box", "Waiting Ticket", "Paper Cup", "Fih Food", "Pack of Gween Soda", "Honey Pot", "Iron Key",
    "Knockback Stick", "Lantern", "Laser Pointer", "Leftovers", "Lighter", "Lockpicks", "Lotus",
    "Moonlight Candle", "Moonlight Float", "Multitool", "NVCS-3000", "Paper Plane",
    "Pizza", "Pocket Mirror", "Rift Jar", "Shakelight", "Shears", "Skeleton Key", "Smoothie", "Spotlight",
    "Starlight Bottle", "Starlight Jug", "Starlight Vial", "Straplight", "Tip Jar", "Vitamins",
    -- Items sacados del Explorer (Dex) que antes no se reconocian
    "Big Bomb", "Bomb", "Cheese", "Knockbomb", "Nanner", "Nanner Peel", "Rift Candle", "Rift Smoothie",
    "Snake Box", "Stop Sign", -- "Verity"
    -- Items nuevos (Dex): JerryCan, BrokenMonitor, DinkyLamp, BottleCrate, CoinRoll, PeachCobbler, Briefcase, ObjectScanner, LargeScrew
    "Fuel Can", "Broken Monitor", "Broken Lamp", "Bottle Crate", "Coin Roll", "Peach Cobbler", "Briefcase", "Scanner", "Large Screw",
    "Abraham's Hat", -- el nombre interno (Dex) se pone en PENDING_DEX_NAMES.AbrahamHat (mas abajo)
}

local function Norm(s)
    return (tostring(s):lower():gsub("[^%w]", ""))
end

local ITEM_LOOKUP = {}
for _, name in ipairs(ITEM_NAMES) do
    ITEM_LOOKUP[Norm(name)] = name
end
-- Alias: nombres internos que difieren del nombre de la wiki
ITEM_LOOKUP["bandage"] = "Bandage"
ITEM_LOOKUP["bandages"] = "Bandage"
ITEM_LOOKUP["lockpick"] = "Lockpicks"
ITEM_LOOKUP["vitamin"] = "Vitamins"
ITEM_LOOKUP["holygrenade"] = "Holy Hand Grenade"
ITEM_LOOKUP["bandagepack"] = "Bandage Pack"
ITEM_LOOKUP["glowsticks"] = "Glowstick"
ITEM_LOOKUP["straplights"] = "Straplight"
ITEM_LOOKUP["bulklights"] = "Bulklight"
ITEM_LOOKUP["crucifixwall"] = "Crucifix" -- Crucifix incrustado en la pared (nombre interno real)
ITEM_LOOKUP["treatbag"] = "Trick or Treat Bag"
ITEM_LOOKUP["candybag"] = "Trick or Treat Bag"
ITEM_LOOKUP["trickortreat"] = "Trick or Treat Bag"

-- Items con ESP propio (no entran al filtro de items normales)
ITEM_LOOKUP["glitchfragment"] = "Glitch Fragment"
ITEM_LOOKUP["glitchcube"] = "Glitch Fragment" -- nombre interno real (GlitchCube) -> se muestra como Glitch Fragment, con su propio ESP
ITEM_LOOKUP["lotuspetal"] = "Lotus Petal"
-- El MODULO del Scanner tiene su propio ESP ("Scanner Module"). Su nombre del Dex todavia no se conoce:
-- cuando lo tengas, ponlo en PENDING_DEX_NAMES (justo abajo) y se marcara solo.
-- Ojo: "Scanner" (ObjectScanner) es el item normal y va al ESP Items.
ITEM_LOOKUP["scannermodule"] = "Scanner Module"
ITEM_LOOKUP["modulescanner"] = "Scanner Module"
do
    local PENDING_DEX_NAMES = {
        ScannerModule = "Drive", -- <<< nombre del Dex del modulo del Scanner (ej. "ScannerModuleItem")
        AbrahamHat = "AbrahamHat",    -- <<< nombre del Dex del Abraham's Hat
    }
    if PENDING_DEX_NAMES.ScannerModule ~= "" then ITEM_LOOKUP[Norm(PENDING_DEX_NAMES.ScannerModule)] = "Scanner Module" end
    if PENDING_DEX_NAMES.AbrahamHat ~= "" then ITEM_LOOKUP[Norm(PENDING_DEX_NAMES.AbrahamHat)] = "Abraham's Hat" end
end
local SPECIAL_CATS = { ["Glitch Fragment"] = "glitch", ["Lotus Petal"] = "lotus", ["Scanner Module"] = "scanner", ["Stardust"] = "stardust" }
ITEM_LOOKUP["batterypack"] = "Battery Pack"
ITEM_LOOKUP["jerrycan"] = "Fuel Can"
ITEM_LOOKUP["dinkylamp"] = "Broken Lamp"
ITEM_LOOKUP["objectscanner"] = "Scanner"
ITEM_LOOKUP["gweensodapack"] = "Pack of Gween Soda"
ITEM_LOOKUP["stardustpickup"] = "Stardust" -- por si llega como item: se redirige abajo (ver SPECIAL_CATS)

-- Alias de nombres internos reales (sacados del Explorer / Dex)
local INTERNAL_ALIASES = {
    AlarmClock = "Alarm Clock", AloeVera = "Aloe", BandagePack = "Bandage Pack", BatteryPack = "Battery Pack",
    BigBomb = "Big Bomb", Bomb = "Bomb", BoxingGloves = "Boxing Gloves", Bread = "Bread", Bulklight = "Bulklight",
    Candle = "Candle", Cheese = "Cheese", Compass = "Compass", Crucifix = "Crucifix", Donut = "Donut",
    Flashlight = "Flashlight", Glowsticks = "Glowstick", GoldGun = "Gold Gun", GoldBlaster = "Gold Gun",
    GweenSoda = "Gween Soda", GweenSodaPack = "Pack of Gween Soda", HolyGrenade = "Holy Hand Grenade", KnockbackStick = "Knockback Stick",
    Knockbomb = "Knockbomb", Lantern = "Lantern", LaserPointer = "Laser Pointer", Lighter = "Lighter",
    Lockpick = "Lockpicks", Multitool = "Multitool", Nanner = "Nanner", NannerPeel = "Nanner Peel",
    Pizza = "Pizza", PocketMirror = "Pocket Mirror", RiftCandle = "Rift Candle", RiftJar = "Rift Jar",
    RiftSmoothie = "Rift Smoothie", Shakelight = "Shakelight", Shears = "Shears", SkeletonKey = "Skeleton Key",
    Smoothie = "Smoothie", SnakeBox = "Snake Box", StarBottle = "Starlight Bottle", StarJug = "Starlight Jug",
    StarVial = "Starlight Vial", StopSign = "Stop Sign", Straplight = "Straplight", TipJar = "Tip Jar",
    Vitamins = "Vitamins",
    -- Items nuevos: nombre interno (Dex) -> nombre que se muestra
    JerryCan = "Fuel Can", BrokenMonitor = "Broken Monitor", DinkyLamp = "Broken Lamp", BottleCrate = "Bottle Crate",
    CoinRoll = "Coin Roll", PeachCobbler = "Peach Cobbler", Briefcase = "Briefcase", ObjectScanner = "Scanner",
    LargeScrew = "Large Screw",
}
for k, v in pairs(INTERNAL_ALIASES) do ITEM_LOOKUP[Norm(k)] = v end

-- Resuelve el nombre canonico de un item a partir de varios textos candidatos
-- (nombre del modelo, ObjectText del prompt, etc). Evita nombres raros/parciales.
local function ResolveItem(candidates)
    for _, cand in ipairs(candidates) do
        if type(cand) == "string" and cand ~= "" then
            local n = Norm(cand)
            if ITEM_LOOKUP[n] then return ITEM_LOOKUP[n] end
        end
    end
    for _, cand in ipairs(candidates) do
        if type(cand) == "string" and #cand >= 4 then
            local n = Norm(cand)
            local best, bestLen
            for k, name in pairs(ITEM_LOOKUP) do
                if #k >= 6 and n:find(k, 1, true) then
                    if not bestLen or #k > bestLen then best, bestLen = name, #k end
                end
            end
            if best then return best end
        end
    end
end

-- Nombres internos (instancias en Workspace.CurrentRooms)
local KEY_NAMES = {
    KeyObtain = "Key",
    ElectricalKeyObtain = "Electrical Room Key",
    FuseObtain = "Fuse",
}
local OBJECTIVE_NAMES = {
    LeverForGate = "Lever",
    -- TimerLever vive directo en CurrentRooms > [sala] > TimerLever (NO dentro de Assets).
    -- El escaneo recorre todo Workspace, asi que se detecta por nombre sin importar la ruta.
    TimerLever = "Timer Lever",
    LiveHintBook = "Library Book",
    LiveBreakerPolePickup = "Breaker Pole",
    -- Stairwell: Workspace.CurrentRooms.[sala].Assets.Switches.StairwellFireAlarm (hay varias carpetas Switches;
    -- se detecta por nombre en todas, sin importar en cual este)
    StairwellFireAlarm = "Fire Alarm Lever",
    ["Sally's Toy"] = "Sally's Toy",
    SallysToy = "Sally's Toy",
    SallyToy = "Sally's Toy",
    -- Dam Seek: Workspace.CurrentRooms.100._DamHandler.Flood#.Pumps.WaterPump (# = 1, 2 o 3)
    WaterPump = "Water Pump",
}
local STARDUST_NAMES = { Stardust = "Stardust", StardustPickup = "Stardust" }

print("[R4NS0M] Item ESP loaded (1/4)")
print("[R4NS0M] Loading Entity ESP (1/4)")
-- Entidades: { nombre, modos donde aparece ("*" = todos), tokens de nombre interno (normalizados) }
-- Fuentes: DOORS Wiki (Entities, The Great Outdoors Update, The Archives Update, The Stairwell)
local ENTITY_DEFS = {
    -- All Floors
    { "Rush", "*", { "rushmoving", "rush" } },
    { "Ambush", "*", { "ambushmoving", "ambush" } },
    { "Eyes", "*", { "eyes" } },
    { "Halt", "*", { "halt" } },
    { "Jeff", "*", { "jeffthekiller", "jeff" } },
    { "Jeff the Killer", "*", { "jeffthekiller" } },
    { "Snare", "*", { "snare" } },
    { "Glitch", "*", {} },
    { "Glitched Rush", "*", {} },
    { "Glitched Ambush", "*", {} },
    -- Main Floors
    { "Seek", "Hotel Mines", { "seekmoving", "seekrig", "seek" } },
    { "Figure", "Hotel Mines", { "figureragdoll", "figurerig", "figure" } },
    { "Timothy", "Hotel Mines", { "timothy" } },
    { "Void", "Hotel Mines", { "void" } },
    { "Bob", "Hotel Mines", { "bob" } },
    { "El Goblino", "Hotel Mines", { "elgoblino", "goblino" } },
    { "Dread", "Hotel Mines", { "dread" } },
    -- The Mines
    { "Grumble", "Mines", { "grumble" } },
    { "Queen Grumble", "Mines", { "queengrumble" } },
    { "Giggle", "Hotel Mines", { "giggle" } },
    { "Gloombat", "Hotel Mines", { "gloombat" } },
    { "Firedamp", "Hotel Mines", { "firedamp" } },
    -- The Backdoor
    { "Blitz", "Hotel Mines Backdoor", { "backdoorrush", "blitz" } },
    { "Lookman", "Hotel Mines Backdoor", { "backdoorlookman", "lookman" } },
    { "Haste", "Hotel Backdoor", { "haste" } },
    -- The Outdoors
    { "Groundskeeper", "Outdoors", { "groundskeeper", "thegroundskeeper" } },
    { "Caw", "Outdoors", { "caw" } },
    { "Monument", "Outdoors", { "monument" } },
    { "Surge", "Outdoors", { "surge" } },
    { "Mandrake", "Outdoors", { "mandrake" } },
    { "Eyestalk", "Outdoors", { "eyestalk" } },
    { "Bramble", "Outdoors", { "bramble" } },
    { "Grampy", "Outdoors", { "grampy" } },
    { "World Lotus", "Outdoors", { "worldlotus", "theworldlotus" } },
    -- The Archives (A-60 / A-90 / A-120; Bash y Scribbles son sus nombres internos nuevos)
    { "Honcho", "Archives", { "honcho" } },
    { "Drone", "Archives", { "drone" } },
    { "Forget-Me-Nots", "Archives", { "forgetmenot", "forgetmenots" } },
    { "Teller", "Archives", { "teller" } },
    { "Alma", "Archives", { "alma" } },
    { "Portrait", "Archives", { "portrait" } },
    { "A-60", "Archives", { "a60", "bash", "bashmoving", "bashrig", "bashmodel", "bashentity" } },
    { "A-120", "Archives", { "a120", "scribbles" } },
    { "Discoloration", "Archives", { "discoloration" } },
    { "Currents", "Archives", { "currents" } },
    -- The Stairwell
    { "Creak", "Stairwell", { "creak" } },
    { "Noise", "*", { "noisemodel", "noise" } },
    { "Noise TV", "*", { "tvstand" } },
    { "Stem", "Stairwell", { "stem", "stemmoving", "stemrig", "stemmodel", "stementity", "stemsentity", "stems" } },
    { "Meld", "Stairwell", { "meld" } },
    { "Cobbler", "Stairwell", { "cobbler" } },
    { "Hijack", "Stairwell", { "hijack" } },
    { "Crusher", "Stairwell", { "crusher" } },
}

local ENTITY_LIST, ENTITY_MODES, ENTITY_TOKENS = {}, {}, {}
for _, d in ipairs(ENTITY_DEFS) do
    ENTITY_LIST[#ENTITY_LIST + 1] = d[1]
    local set = {}
    for m in d[2]:gmatch("%S+") do set[m] = true end
    ENTITY_MODES[d[1]] = set
    for _, tok in ipairs(d[3]) do ENTITY_TOKENS[#ENTITY_TOKENS + 1] = { tok, d[1] } end
end
table.sort(ENTITY_TOKENS, function(a, b) return #a[1] > #b[1] end) -- mas largo primero (eyestalk antes que eyes)

-- Tokens demasiado genericos para buscarlos dentro de los cuartos (decoracion)
local STRICT_SKIP = {
    portrait = true, monument = true, currents = true, bob = true, jack = true,
    void = true, dupe = true, jeff = true, timothy = true, eyes = true,
}

-- Entidades del Glitch Fragment (client-side). Nombres oficiales de la wiki.
local GLITCH_TOKENS = {
    { "RNIUSHCg",  "Glitched Rush" },
    { "AR0xMBUSH", "Glitched Ambush" },
}

-- Nombres internos confirmados en scripts publicos de DOORS
local ENTITY_EXACT = {
    RushMoving = "Rush", AmbushMoving = "Ambush", BackdoorRush = "Blitz", BackdoorLookman = "Lookman",
    Lookman = "Lookman", Eyes = "Eyes", Halt = "Halt",
    JeffTheKiller = "Jeff", A60 = "A-60", A120 = "A-120", Bash = "A-60", Scribbles = "A-120", Snare = "Snare",
}

-- Entidades sin ESP (inutil marcarlas): Ransom (A-90), Jack, Shadow, Screech (y Glitched Screech).
-- Nunca se registran, ni siquiera con "Show Unlisted Entities".
local EXCLUDED_EXACT = { jack = true, ransom = true, a90 = true, shadow = true, screech = true }
local function IsExcludedEntity(name)
    local n = Norm(name)
    if EXCLUDED_EXACT[n] then return true end
    if n:find("screech", 1, true) or n:find("ransom", 1, true) then return true end
    if n:find("shadow", 1, true) then return true end
    return name:find("SCJVEREECH", 1, true) ~= nil -- Glitched Screech (nombre interno)
end

STRICT_SKIP.__stem = { -- variantes de nombre de Stem (no es un local nuevo: el script esta cerca del limite de locales)
    stem = true, stems = true, stemsentity = true, stemmoving = true, stemrig = true, stemmodel = true, stementity = true, stemragdoll = true,
    stemmonster = true, stemchase = true, stemmover = true, stemclient = true, stemfake = true, stemreal = true,
}
-- strict = true: solo coincidencia exacta (para modelos dentro de los cuartos)
-- allowSkip = true: permite tokens de STRICT_SKIP (Timothy, Bob, Jeff, Void...). Solo se usa
-- para modelos con Humanoid/AnimationController, asi la decoracion no se marca.
-- strict = false: prefijo para nombres largos, exacto para nombres de 4 letras o menos
local function EntityLabel(name, strict, allowSkip)
    if IsExcludedEntity(name) then return nil end
    if ENTITY_EXACT[name] then return ENTITY_EXACT[name] end
    for _, g in ipairs(GLITCH_TOKENS) do
        if name:find(g[1], 1, true) then return g[2] end
    end
    local n = Norm(name)
    -- "GlitchFragment" es un item, no una entidad
    if not strict and n:sub(1, 6) == "glitch" and not n:find("fragment", 1, true) then
        if n:find("ambush", 1, true) then return "Glitched Ambush" end
        if n:find("rush", 1, true) then return "Glitched Rush" end
        return nil -- el "Glitch" generico (efectos del Glitch Fragment) aparecia sin parar: ya no se marca
    end
    -- Stem: el nombre exacto no basta (fuera de tu mano usa variantes: StemRig, StemMoving, StemModel...)
    if STRICT_SKIP.__stem[n] and (allowSkip or not strict) then return "Stem" end
    local nb = n -- nombre sin sufijo (BashMoving -> bash)
    for _, suf in ipairs({ "moving", "model", "entity", "rig" }) do
        if #nb > #suf and nb:sub(-#suf) == suf then nb = nb:sub(1, #nb - #suf) break end
    end
    for _, t in ipairs(ENTITY_TOKENS) do
        local tok = t[1]
        if strict then
            if n == tok and (allowSkip or not STRICT_SKIP[tok]) then return t[2] end
        elseif #tok <= 4 then
            if n == tok or nb == tok then return t[2] end
        elseif n:sub(1, #tok) == tok then
            return t[2]
        end
    end
end

print("[R4NS0M] Loaded Entity ESP (2/4)")
print("[R4NS0M] Loading Entity Name Cache (2/4)")
-- PERF: cache de funciones de nombres. En Outdoors se crean miles de modelos con nombres repetidos
-- (arboles, rocas...) y antes cada uno recorria ~100 tokens con gsub. Ahora cada nombre se calcula UNA vez.
do
    local rawNorm, rawExcl, rawLabel = Norm, IsExcludedEntity, EntityLabel
    local normC, normN = {}, 0
    Norm = function(x)
        if type(x) ~= "string" then return rawNorm(x) end
        local v = normC[x]
        if v == nil then
            if normN > 8000 then normC, normN = {}, 0 end
            v = rawNorm(x)
            normC[x] = v
            normN = normN + 1
        end
        return v
    end
    local exC, exN = {}, 0
    IsExcludedEntity = function(name)
        local v = exC[name]
        if v == nil then
            if exN > 8000 then exC, exN = {}, 0 end
            v = rawExcl(name) and true or false
            exC[name] = v
            exN = exN + 1
        end
        return v
    end
    local lbC, lbN = { {}, {}, {}, {} }, 0
    EntityLabel = function(name, strict, allowSkip)
        local c = lbC[(strict and 1 or 0) + (allowSkip and 2 or 0) + 1]
        local v = c[name]
        if v == nil then
            if lbN > 8000 then lbC, lbN = { {}, {}, {}, {} }, 0; c = lbC[(strict and 1 or 0) + (allowSkip and 2 or 0) + 1] end
            v = rawLabel(name, strict, allowSkip) or false
            c[name] = v
            lbN = lbN + 1
        end
        return v or nil
    end
end

print("[R4NS0M] Loaded Entity Name Cache (3/4)")
print("[R4NS0M] Loading ESP Config (3/4)")
local GOLD_NAMES = { GoldPile = "Gold" }
local HIDE_NAMES = { Wardrobe = "Closet", Bed = "Bed", Toolshed = "Tool Shed", Locker = "Locker" }

local MAX_HIGHLIGHTS = 20 -- Roblox solo renderiza ~31 Highlights a la vez; menos = menos lag (el resto usa cajas)

local Cfg = {
    MaxDistance = 400,
    MaxObjects = 120, -- tope de objetos dibujados a la vez (los mas cercanos); evita lag en mapas grandes
    TextSize = 22,
    Font = "Oswald",
    PlayerNames = "Display Name",
    ShowName = true,
    ShowDistance = true,
    Unit = "Meters",
    FillTransparency = 0.8,
    OutlineTransparency = 0,
    TracerOrigin = "Bottom",
    TracerThickness = 1.5,
    UnlistedItems = true,
    ItemFilter = {},
    UnlistedEntities = false, -- desconocidos apagado: evita marcar cosas que no son entidades
    EntityFilter = {},
    Debug = false,
    DebugVerbose = false,
    Overlay = false,
    HideLooted = true,
    AutoPreset = false,
    RoomEntities = true,
    Categories = {
        doors      = { Enabled = false, Color = Color3.fromHex("#00eaff") },
        gold       = { Enabled = false, Color = Color3.fromHex("#ffe400") },
        keys       = { Enabled = false, Color = Color3.fromHex("#12ff00") },
        wardrobes  = { Enabled = false, Color = Color3.fromHex("#007000") },
        chests     = { Enabled = false, Color = Color3.fromHex("#ffe400") },
        items      = { Enabled = false, Color = Color3.fromHex("#fc00ff") },
        objectives = { Enabled = false, Color = Color3.fromHex("#12ff00") },
        stardust   = { Enabled = false, Color = Color3.fromHex("#ff7800") },
        entities   = { Enabled = false, Color = Color3.fromHex("#ff0000") },
        dupe       = { Enabled = false, Color = Color3.fromHex("#ff0000") },
        drawers    = { Enabled = false, Color = Color3.fromHex("#d9a066") },
        lockers    = { Enabled = false, Color = Color3.fromHex("#8fa8ff") },
        interactables = { Enabled = false, Color = Color3.fromHex("#7fffd4") },
        glitch     = { Enabled = false, Color = Color3.fromHex("#8100a6") },
        lotus      = { Enabled = false, Color = Color3.fromHex("#ff6ff7") },
        scanner    = { Enabled = false, Color = Color3.fromHex("#a145ff") },
        stairs     = { Enabled = false, Color = Color3.fromHex("#ff5fa2") },
        exit       = { Enabled = false, Color = Color3.fromHex("#93ff85") },
        cart       = { Enabled = false, Color = Color3.fromHex("#6d77ff") },
        players    = { Enabled = false, Color = Color3.fromHex("#3b82f6") },
    }
}

print("[R4NS0M] Loaded ESP Config (4/4)")
print("[R4NS0M] Fully Loaded ESP")
print("[R4NS0M] Loading Tracers")
-- Tracer por categoria (apagado por defecto)
for _, c in pairs(Cfg.Categories) do c.Tracer = false end

print("[R4NS0M] Loaded Tracers")
print("[R4NS0M] Loading ESP Fonts")
-- Fuentes disponibles para el texto del ESP
local FONT_LIST = { "Oswald", "Roboto Sans", "Nunito", "Gotham Bold", "Ubuntu", "Source Sans", "Code" }
local FONT_MAP = {
    ["Oswald"] = Enum.Font.Oswald,
    ["Roboto Sans"] = Enum.Font.Roboto,
    ["Nunito"] = Enum.Font.Nunito,
    ["Gotham Bold"] = Enum.Font.GothamBold,
    ["Ubuntu"] = Enum.Font.Ubuntu,
    ["Source Sans"] = Enum.Font.SourceSansBold,
    ["Code"] = Enum.Font.Code,
}

for _, name in ipairs(ITEM_NAMES) do
    Cfg.ItemFilter[name] = true
end
for _, name in ipairs(ENTITY_LIST) do
    Cfg.EntityFilter[name] = true
end

print("[R4NS0M] Loaded ESP Fonts")
print("[R4NS0M] Loading Debug Logger")
-- Debug logger: imprime/guarda nombres reales que el script no reconoce
local DebugLog, DebugSeen = {}, {}
local function Dbg(kind, inst, extra)
    if not Cfg.Debug then return end
    local key = kind .. ":" .. inst.Name
    if DebugSeen[key] then return end
    DebugSeen[key] = true
    local okName, full = pcall(function() return inst:GetFullName() end)
    local line = string.format("[%s] %s | %s%s", kind, inst.Name, okName and full or "?", extra and (" | " .. extra) or "")
    DebugLog[#DebugLog + 1] = line
    print("[R4NS0M DEBUG] " .. line)
end

print("[R4NS0M] Loaded Debug Logger")
print("[R4NS0M] Loading Render Containers")
----------------------------------------------------
-- Contenedores de render
----------------------------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "R4NS0M_ESP_Lines"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999

local Holder = Instance.new("Folder")
Holder.Name = "R4NS0M_ESP"

local okParent = pcall(function()
    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    Gui.Parent = parent
    Holder.Parent = parent
end)
if not okParent then
    Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    Holder.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Tracked = {}

print("[R4NS0M] Loaded Render Containers")
print("[R4NS0M] Loading Gamemodes")
----------------------------------------------------
-- MODO DE JUEGO
-- Se detecta UNA vez al cargar y solo se activan los ESP/funciones de ese modo.
-- Si el modo cambia mas tarde, se vuelve a configurar solo.
----------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Setters = {}
local Mode = { Name = "Unknown", Raw = "" }
local ModeParagraph -- se crea en la pestana Main

-- Categorias de ESP que existen en cada modo
local MODE_CATS = {
    Hotel     = { "doors", "dupe", "gold", "keys", "wardrobes", "chests", "objectives", "stardust", "entities", "items", "drawers", "glitch" },
    Mines     = { "doors", "gold", "keys", "wardrobes", "chests", "objectives", "stardust", "entities", "items", "drawers", "lockers", "glitch" },
    Backdoor  = { "doors", "objectives", "stardust", "entities", "items", "drawers", "glitch" },
    Outdoors  = { "doors", "gold", "keys", "stardust", "entities", "items", "glitch", "lotus", "stardust", "interactables" },
    Archives  = { "doors", "stardust", "entities", "items", "drawers", "interactables", "glitch" },
    Stairwell = { "doors", "stardust", "entities", "items", "interactables", "glitch", "objectives", "exit", "cart" },
    Rooms     = { "doors", "stardust", "entities", "items", "wardrobes", "lockers", "glitch" },
    -- Lobby: no hay partida, solo jugadores
    Lobby     = {},
    -- Modo no detectado: solo lo basico y seguro (sin Dupe ni extras)
    Unknown   = { "doors", "gold", "keys", "wardrobes", "chests", "objectives", "entities", "items", "drawers", "lockers" },
}
MODE_CATS.Fools = MODE_CATS.Hotel
do
    local seen = {}
    for _, list in pairs(MODE_CATS) do
        if not seen[list] then
            seen[list] = true
            list[#list + 1] = "players"
            if list ~= MODE_CATS.Lobby then list[#list + 1] = "scanner" end
        end
    end
    -- ESP Stairs & Ladders: solo existe en The Mines
    MODE_CATS.Mines[#MODE_CATS.Mines + 1] = "stairs"
end
-- Test Mode: TODAS las categorias de ESP y TODAS las entidades a la vez (para probar facil)
do
    local all = {}
    for id in pairs(Cfg.Categories) do all[#all + 1] = id end
    table.sort(all)
    MODE_CATS.Test = all
end
Mode.All = function() return Mode.Name == "Unknown" or Mode.Name == "Test" end

-- Fools comparte entidades con Hotel; Rooms comparte A-60/A-120 con Archives
for _, n in ipairs({ "A-60", "A-120" }) do
    if ENTITY_MODES[n] then ENTITY_MODES[n]["Rooms"] = true end
end
local function EntityModeKey()
    return Mode.Name == "Fools" and "Hotel" or Mode.Name
end
local function CurrentEntityList()
    local out, key = {}, EntityModeKey()
    for _, d in ipairs(ENTITY_DEFS) do
        local set = ENTITY_MODES[d[1]]
        if Mode.All() or set["*"] or set[key] then out[#out + 1] = d[1] end
    end
    return out
end

local MODE_EXACT = {
    hotel = "Hotel", fools = "Fools", mines = "Mines", backdoor = "Backdoor", outdoors = "Outdoors",
    garden = "Outdoors", archives = "Archives", stairwell = "Stairwell", rooms = "Rooms",
}
local MODE_RULES = {
    { "backdoor", "Backdoor" }, { "stair", "Stairwell" }, { "archive", "Archives" },
    { "outdoor", "Outdoors" }, { "garden", "Outdoors" }, { "mine", "Mines" },
    { "hotel", "Hotel" }, { "fool", "Fools" },
}

local Active = {} -- categorias activas para el modo actual
local Rescan, OnModeApplied, PurgeInactive, ApplyPreset

local function SetActive(modeName)
    local new = {}
    for _, id in ipairs(MODE_CATS[modeName] or MODE_CATS.Unknown) do new[id] = true end
    Active = new
end

-- Force Gamemode: "Auto" = detectar solo; cualquier otro valor fuerza ese modo
local Force = { Name = "Auto" }

-- Lobby de DOORS: es un place aparte del juego y ahi GameData.Floor vale "Hotel" por defecto,
-- por eso antes se detectaba como Hotel. Main_Game destruye MainUI.LobbyFrame al entrar a una
-- partida, asi que si LobbyFrame sigue ahi (fuera del place del juego) tambien es el lobby.
local LOBBY_PLACE_ID = 6516141723
local GAME_PLACE_ID = 6839171747
local function IsLobby()
    if game.PlaceId == LOBBY_PLACE_ID then return true end
    if game.PlaceId ~= GAME_PLACE_ID then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local mu = pg and pg:FindFirstChild("MainUI")
        if mu and mu:FindFirstChild("LobbyFrame") then return true end
    end
    return false
end

local function ReadModeRaw()
    local raw, strings = {}, {}
    local gd = ReplicatedStorage:FindFirstChild("GameData")
    if gd then
        for _, c in ipairs(gd:GetChildren()) do
            if c:IsA("ValueBase") then
                local ok, v = pcall(function() return c.Value end)
                if ok and v ~= nil and typeof(v) ~= "Instance" then
                    raw[#raw + 1] = c.Name .. "=" .. tostring(v)
                    if type(v) == "string" then strings[#strings + 1] = v:lower() end
                end
            end
        end
        for k, v in pairs(gd:GetAttributes()) do
            raw[#raw + 1] = k .. "=" .. tostring(v)
            if type(v) == "string" then strings[#strings + 1] = v:lower() end
        end
    end
    Mode.Raw = table.concat(raw, "; ")

    -- 1) valor exacto (Floor = "Hotel", "Mines"...)
    for _, s in ipairs(strings) do
        if MODE_EXACT[s] then return MODE_EXACT[s] end
    end
    -- 2) coincidencia parcial
    local text = table.concat(strings, " ")
    for _, r in ipairs(MODE_RULES) do
        if text:find(r[1], 1, true) then return r[2] end
    end
    -- 3) respaldo: cuartos con nombre tipo "C-048" = Archives
    local rooms = Workspace:FindFirstChild("CurrentRooms")
    if rooms then
        for _, r in ipairs(rooms:GetChildren()) do
            if r.Name:match("^%a%-%d+$") then return "Archives" end
        end
    end
    return "Unknown"
end

local function ReadMode()
    local okR, name = pcall(ReadModeRaw) -- tambien actualiza Mode.Raw
    if Force.Name ~= "Auto" then return Force.Name end
    local okL, lobby = pcall(IsLobby)
    if okL and lobby then return "Lobby" end
    return okR and name or "Unknown"
end

local function WaitForMode(timeout)
    local t0 = os.clock()
    while true do
        local ok, name = pcall(ReadMode)
        if ok and name ~= "Unknown" then return name end
        if os.clock() - t0 >= timeout then return "Unknown" end
        task.wait(0.5)
    end
end

local function ApplyMode(name)
    Mode.Name = name
    SetActive(name)
    print("[R4NS0M] Game mode: " .. name .. " (" .. Mode.Raw .. ")")
    if PurgeInactive then PurgeInactive() end
    if OnModeApplied then pcall(OnModeApplied) end
    if Cfg.AutoPreset and ApplyPreset then pcall(ApplyPreset, name) end
    if Rescan then Rescan() end
    local forced = Force.Name ~= "Auto"
    pcall(function()
        WindUI:Notify({ Title = "Game Mode", Content = (forced and "Forced: " or "Detected: ") .. name .. ". Only its ESP options are loaded.", Duration = 4 })
    end)
    if ModeParagraph then
        pcall(function() ModeParagraph:SetTitle((forced and "Forced: " or "Detected: ") .. name) end)
    end
end

local function WatchMode()
    local name = ReadMode()
    if name ~= Mode.Name and (name ~= "Unknown" or Force.Name == "Unknown") then ApplyMode(name) end
end

-- Espera al modo ANTES de escanear nada
Mode.Name = WaitForMode(12)
SetActive(Mode.Name)
print("[R4NS0M] Game mode: " .. Mode.Name .. " (" .. Mode.Raw .. ")")

local Overlay = Instance.new("TextLabel")
Overlay.Name = "R4NS0M_Overlay"
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 0.45
Overlay.BorderSizePixel = 0
Overlay.TextColor3 = Color3.fromRGB(230, 230, 230)
Overlay.Font = Enum.Font.Code
Overlay.TextSize = 13
Overlay.TextXAlignment = Enum.TextXAlignment.Left
Overlay.TextYAlignment = Enum.TextYAlignment.Top
Overlay.TextWrapped = true
Overlay.Size = UDim2.fromOffset(300, 10)
Overlay.AutomaticSize = Enum.AutomaticSize.Y
Overlay.Position = UDim2.fromOffset(8, 70)
Overlay.Visible = false

Overlay.Parent = Gui

local function UpdateOverlay()
    Overlay.Visible = Cfg.Overlay
    if not Cfg.Overlay then return end
    local counts, total, shown = {}, 0, 0
    for _, e in pairs(Tracked) do
        counts[e.Cat] = (counts[e.Cat] or 0) + 1
        total = total + 1
        if e.Shown then shown = shown + 1 end
    end
    local list = {}
    for k, n in pairs(counts) do list[#list + 1] = k .. "=" .. n end
    table.sort(list)
    Overlay.Text = string.format(
        "R4NS0M DEBUG\nMode: %s\nRoom: %s\nTracked: %d (shown %d)\n%s\nGameData: %s",
        Mode.Name, tostring(LocalPlayer:GetAttribute("CurrentRoom")), total, shown,
        #list > 0 and table.concat(list, ", ") or "-", Mode.Raw ~= "" and Mode.Raw or "-"
    )
end
local function GetPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
    end
end

print("[R4NS0M] Loaded Gamemodes")
print("[R4NS0M] Loading Visual Instances")
-- PERF: las instancias visuales (Highlight, caja, billboard, linea) se crean SOLO cuando un objeto
-- se va a dibujar y se liberan cuando lleva unos segundos oculto. Antes se creaban 5 instancias por
-- cada objeto detectado aunque el ESP estuviera apagado.
Mode.Free = function(e)
    local hl, box, bb, line = e.HL, e.Box, e.BB, e.Line
    e.HL, e.Box, e.BB, e.TL, e.Line = nil, nil, nil, nil, nil
    e.Col, e.Fill, e.Out, e.Text, e.TS, e.TF, e.BoxT, e.HidSince = nil, nil, nil, nil, nil, nil, nil, nil
    if hl then pcall(hl.Destroy, hl) end
    if box then pcall(box.Destroy, box) end
    if bb then pcall(bb.Destroy, bb) end
    if line then pcall(line.Destroy, line) end
end

Mode.Build = function(e)
    if e.HL then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = e.Inst
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = Holder

    -- Respaldo cuando Highlight no se ve (partes invisibles) o se pasa del limite
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = e.Part
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = e.Part.Size
    box.Visible = false
    box.Parent = Holder

    local bb = Instance.new("BillboardGui")
    bb.Adornee = e.Part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(300, 80)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.LightInfluence = 0
    bb.ResetOnSpawn = false
    bb.Enabled = false
    bb.Parent = Holder

    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.fromScale(1, 1)
    tl.Font = FONT_MAP[Cfg.Font] or Enum.Font.Oswald
    tl.TextStrokeTransparency = 0.35
    tl.TextStrokeColor3 = Color3.new(0, 0, 0)
    tl.Parent = bb

    e.HL, e.Box, e.BB, e.TL = hl, box, bb, tl
end

local function RemoveEntry(inst)
    local e = Tracked[inst]
    if not e then return end
    Tracked[inst] = nil
    if e.Conn then pcall(e.Conn.Disconnect, e.Conn); e.Conn = nil end
    Mode.Free(e)
end

local function HideEntry(e)
    e.Shown = false
    if not e.HL and not e.Line then return end
    if e.HL then
        e.HL.Enabled = false
        e.Box.Visible = false
        e.BB.Enabled = false
    end
    if e.Line then e.Line.Visible = false end
    local now = os.clock()
    if not e.HidSince then
        e.HidSince = now
    elseif now - e.HidSince > 5 then
        Mode.Free(e) -- lleva 5s oculto: se liberan las instancias
    end
end

local OnEntitySeen -- lo asigna el Entity Notifier
local ExtraSerialize, ExtraApply -- los asigna el bloque de extras

-- Si un objeto ya esta registrado, solo se reemplaza por una categoria de mayor prioridad
local PRIORITY = {
    interactables = 1, doors = 2, drawers = 2, lockers = 2,
    items = 3, chests = 3, glitch = 4, scanner = 4, lotus = 3, stardust = 3,
    keys = 4, gold = 4, objectives = 4, wardrobes = 4,
    entities = 6, dupe = 6, players = 5, stairs = 1,
    exit = 4, cart = 4,
}

----------------------------------------------------
-- FIX Outdoors: madrigueras de Mandrake y oro falso.
-- Mandrake NO se marca al detectarlo: se queda "en observacion" y solo se marca si SE MUEVE
-- cerca de ti (la que te ataca). Las madrigueras (estaticas) nunca se marcan.
-- Todo vive en la tabla Watch para no gastar variables locales.
----------------------------------------------------
local Watch = { Limited = { Stem = true, Drone = true, Drones = true }, M = {}, Loop = false, Gold = setmetatable({}, { __mode = "k" }) }

local BURROW_WORDS = { "burrow", "hole", "den", "mound", "nest", "tunnel", "lair", "pit", "dirt", "hill", "spawn", "madriguera" }
function Watch.IsBurrowName(name)
    local n = name:lower()
    for _, w in ipairs(BURROW_WORDS) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

-- Para prompts/items: cualquier cosa dentro de algo llamado burrow/mandrake NO es un item ni oro
function Watch.IsBurrow(inst)
    local p, i = inst, 0
    while p and p ~= Workspace and i < 5 do
        local n = p.Name:lower()
        if n:find("burrow", 1, true) or n:find("madriguera", 1, true) or n:find("mandrake", 1, true) then
            return true
        end
        p, i = p.Parent, i + 1
    end
    return false
end

function Watch.Run()
    if Watch.Loop then return end
    Watch.Loop = true
    task.spawn(function()
        while next(Watch.M) do
            task.wait(0.2)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            for inst, w in pairs(Watch.M) do
                if not inst.Parent then
                    Watch.M[inst] = nil
                elseif hrp then
                    local ok, pos = pcall(function()
                        return inst:IsA("Model") and inst:GetPivot().Position or inst.Position
                    end)
                    if ok and pos then
                        if not w.Start then
                            w.Start = pos
                        elseif (pos - w.Start).Magnitude > 3 and (pos - hrp.Position).Magnitude <= 50 then
                            Watch.M[inst] = nil
                            Watch.Promote(inst, w.Opts)
                        end
                    end
                end
            end
        end
        Watch.Loop = false
    end)
end

local function Register(inst, cat, label, opts)
    if not Active[cat] then return end -- categoria que no existe en este modo

    -- Mandrake: se queda "en observacion" hasta que se mueva cerca de ti
    if cat == "entities" and label == "Mandrake" and not (opts and opts.Direct) then
        if not Tracked[inst] and not Watch.M[inst] and not Watch.IsBurrowName(inst.Name) then
            Watch.M[inst] = { Opts = opts }
            Watch.Run()
        end
        return
    end

    local existing = Tracked[inst]
    if existing then
        if (PRIORITY[cat] or 3) > (PRIORITY[existing.Cat] or 3) then
            RemoveEntry(inst)
        else
            return
        end
    end
    local part = (opts and opts.Part) or GetPart(inst)
    if not part then return end

    local conn = inst.AncestryChanged:Connect(function(_, parent)
        if not parent then RemoveEntry(inst) end
    end)

    Tracked[inst] = {
        Inst = inst, Cat = cat, Label = label, Part = part, Conn = conn,
        Known = opts and opts.Known, Key = opts and opts.Key, Prompt = opts and opts.Prompt, GeoT = 0, NoGeo = false, RoomNum = opts and opts.RoomNum,
        Dist = 0, Shown = false,
    }

    if OnEntitySeen and (cat == "entities" or cat == "dupe") and opts and opts.Known then
        pcall(OnEntitySeen, opts.Key or label, inst)
    end
    if cat == "items" and Watch.OnItem then
        pcall(Watch.OnItem, label, inst, opts and opts.Known, opts and opts.Key)
    end

    if Cfg.DebugVerbose then
        Dbg("REG:" .. cat, inst, "label=" .. tostring(label))
    end
end

function Watch.Promote(inst, opts)
    local o = {}
    for k, v in pairs(opts or {}) do o[k] = v end
    o.Direct = true
    Register(inst, "entities", "Mandrake", o)
end

-- Oro: solo si tiene un prompt activo y una parte visible, y no es decoracion/madriguera
function Watch.RegisterGold(target)
    if Tracked[target] or Watch.Gold[target] or Watch.IsBurrow(target) then return end
    Watch.Gold[target] = true
    task.spawn(function()
        for _ = 1, 15 do
            if not target.Parent then break end
            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and GetPart(target) then
                local visible = false
                local list = target:IsA("BasePart") and { target } or target:GetDescendants()
                for _, d in ipairs(list) do
                    if d:IsA("BasePart") and d.Transparency < 0.95 then
                        visible = true
                        break
                    end
                end
                if visible and prompt.Enabled and prompt.MaxActivationDistance > 0 then
                    local value = target:GetAttribute("GoldValue")
                    Register(target, "gold", value and ("Gold [" .. value .. "]") or "Gold", { Prompt = prompt })
                end
                break
            end
            task.wait(0.3)
        end
        Watch.Gold[target] = nil
    end)
end

print("[R4NS0M] Loaded Visual Instances")
print("[R4NS0M] Loading Workspace Element Detection")
----------------------------------------------------
-- Deteccion
----------------------------------------------------
local CurrentRooms

local function HasTrackedAncestor(inst)
    local p = inst.Parent
    while p and p ~= CurrentRooms and p ~= Workspace do
        if Tracked[p] then return true end
        p = p.Parent
    end
    return false
end

-- Si el objeto aun no tiene ninguna parte (se esta cargando), reintenta unos segundos
local function RegisterWhenReady(inst, cat, label)
    Register(inst, cat, label)
    if Tracked[inst] or GetPart(inst) then return end
    task.spawn(function()
        for _ = 1, 30 do
            task.wait(0.2)
            if not inst.Parent or Tracked[inst] then return end
            if GetPart(inst) then
                Register(inst, cat, label)
                return
            end
        end
    end)
end

local function RegisterByName(target)
    local n = target.Name
    if KEY_NAMES[n] then
        Register(target, "keys", KEY_NAMES[n])
    elseif OBJECTIVE_NAMES[n] then
        RegisterWhenReady(target, "objectives", OBJECTIVE_NAMES[n])
    elseif STARDUST_NAMES[n] then
        Register(target, "stardust", STARDUST_NAMES[n])
    elseif GOLD_NAMES[n] then
        Watch.RegisterGold(target)
    else
        return false
    end
    return true
end

-- The Stairwell: objetos propios del modo
--   Emergency Exit : Workspace.CurrentRooms.[sala].Assets.ExitSignStairwell
--   Shopping Cart  : Workspace.CurrentRooms.[sala].Assets.ShoppingCart  o  Workspace.Misc.ShoppingCart
--   Depot          : Workspace.CurrentRooms.[sala].Assets.StairwellScrapper   (Interactables)
--   Crusher        : Workspace.CurrentRooms.[sala].Assets.StairwellCrusherContainer#.StairwellCrusher.Crusher
-- (# = cualquier numero; la sala tambien puede ser cualquiera)
local STAIR_ASSETS = {
    ExitSignStairwell = { "exit", "Emergency Exit" },
    ShoppingCart = { "cart", "Shopping Cart" },
    StairwellScrapper = { "interactables", "Depot" },
}

local function InStairRoot(inst, allowMisc)
    if CurrentRooms and inst:IsDescendantOf(CurrentRooms) then return true end
    if allowMisc then
        local misc = Workspace:FindFirstChild("Misc")
        if misc and inst:IsDescendantOf(misc) then return true end
    end
    return false
end

-- Sube desde inst (incluido) y devuelve el objeto de STAIR_ASSETS mas externo, con su categoria y etiqueta.
-- Asi un prompt o una parte hija siempre resuelven al mismo objeto y no se duplican.
local function StairOwner(inst)
    local p, i, found, cat, label = inst, 0, nil, nil, nil
    while p and p ~= Workspace and i < 10 do
        local def = STAIR_ASSETS[p.Name]
        if def and (p:IsA("Model") or p:IsA("BasePart")) and InStairRoot(p, p.Name == "ShoppingCart") then
            found, cat, label = p, def[1], def[2]
        end
        p, i = p.Parent, i + 1
    end
    return found, cat, label
end

-- Crusher: se registra como entidad conocida (asi pasa el Entity Filter) con su ruta exacta
local function RegisterCrusher(inst)
    local function try()
        if Tracked[inst] then return true end
        if GetPart(inst) then
            Register(inst, "entities", "Crusher", { Known = true, Key = "Crusher" })
            return true
        end
    end
    if try() then return end
    task.spawn(function()
        for _ = 1, 30 do
            task.wait(0.2)
            if not inst.Parent then return end
            if try() then return end
        end
    end)
end

local GENERIC_PARTS = { Handle = true, Hitbox = true, Base = true, Main = true, Part = true, Model = true }
local KNOWN_PROMPTS = {
    HidePrompt = true, ModulePrompt = true, HerbPrompt = true, ActivateEventPrompt = true,
    LootPrompt = true, UnlockPrompt = true, SkullPrompt = true, Prompt = true,
    HintPrompt = true, InteractPrompt = true,
}
local HIDE_EXACT = { Wardrobe = "Closet", Toolshed = "Tool Shed" }

-- Etiqueta legible para cualquier escondite (Wardrobe -> "Closet")
local function HideLabel(name)
    if HIDE_NAMES[name] then return HIDE_NAMES[name] end
    local n = Norm(name)
    if n:find("wardrobe", 1, true) or n:find("closet", 1, true) then return "Closet" end
    if n:find("cupboard", 1, true) then return "Cupboard" end
    if n:find("locker", 1, true) then return "Locker" end
    if n:find("shed", 1, true) then return "Tool Shed" end
    if n:find("bed", 1, true) then return "Bed" end
    return (name:gsub("_", " "))
end
local CHEST_EXACT = { ChestBox = "Chest", ChestBoxLocked = "Locked Chest" }

-- Contenedores con loot: Hotel/Backdoor (Drawers), Mines (Item Lockers, Toolboxes, Makeshift Drawers)
local CONTAINER_WORDS = { "drawer", "dresser", "desk", "table", "cabinet", "shelf", "nightstand", "makeshift" }

local function ClassifyContainer(name)
    local n = Norm(name)
    if n:find("toolbox", 1, true) then return "lockers", "Toolbox" end
    if n:find("locker", 1, true) then
        if n:find("small", 1, true) or n:find("mini", 1, true) then return "lockers", "Small Locker" end
        return "lockers", "Item Locker"
    end
    for _, w in ipairs(CONTAINER_WORDS) do
        if n:find(w, 1, true) then
            return "drawers", (w == "makeshift") and "Makeshift Drawer" or "Drawer"
        end
    end
end

-- Objeto que ya tiene nombre propio conocido (item, llave, objetivo, oro, Sally...)
local function IsKnownObject(name)
    if KEY_NAMES[name] or OBJECTIVE_NAMES[name] or STARDUST_NAMES[name] or GOLD_NAMES[name] then return true end
    if Norm(name):find("sally", 1, true) then return true end
    return ResolveItem({ name }) ~= nil
end

-- Modelo que es un contenedor (cajon, casillero...) o ya esta registrado como tal
local function IsContainerModel(m)
    if not m then return false end
    if ClassifyContainer(m.Name) then return true end
    local e = Tracked[m]
    return e ~= nil and (e.Cat == "drawers" or e.Cat == "lockers" or e.Cat == "chests" or e.Cat == "wardrobes")
end

-- Sube desde el prompt hasta el modelo real del item (soporta Attachment y partes genericas).
-- FIX: ya NO sube hasta el cajon/casillero que contiene al item. Antes, un item (Sally's Toy,
-- llaves, etc.) dentro de un cajon se "convertia" en el cajon, que ya estaba registrado, y el
-- item se descartaba sin marcarse.
local function ResolveTarget(prompt)
    local t = prompt.Parent
    if t and t:IsA("Attachment") then t = t.Parent end
    if not t then return nil end
    if IsKnownObject(t.Name) then return t end -- ya es el objeto real
    if t:IsA("BasePart") then
        local pm = t.Parent
        if pm and pm:IsA("Model") and pm.Parent ~= CurrentRooms and not IsContainerModel(pm) then t = pm end
    end
    while GENERIC_PARTS[t.Name] and t.Parent and t.Parent:IsA("Model") and t.Parent.Parent ~= CurrentRooms
        and not IsContainerModel(t.Parent) and not IsKnownObject(t.Name) do
        t = t.Parent
    end
    return t
end

local function CleanName(name)
    return (name:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"))
end

local function ProcessContainerPrompt(prompt)
    -- Objetos de Stairwell (Depot, carrito, salida): se registran como un solo objeto aunque el prompt este en una parte hija
    local so, sc, sl = StairOwner(prompt)
    if so then
        if Active[sc] then RegisterWhenReady(so, sc, sl) end
        return
    end
    local t = ResolveTarget(prompt)
    if not t or t == Workspace then return end
    if Watch.IsBurrow(t) then return end
    if CurrentRooms and t.Parent == CurrentRooms and not OBJECTIVE_NAMES[t.Name] then return end
    -- Items/objetivos dentro de un cajon: se registran por su nombre aunque el cajon ya este marcado
    if RegisterByName(t) then return end
    if HasTrackedAncestor(t) then return end

    local low = Norm(t.Name)
    if low == "door" or low == "lock" or low:find("dupe", 1, true) then return end
    if t:FindFirstChild("HidePrompt", true) then return end -- escondite, no loot

    local cat, label = ClassifyContainer(t.Name)
    if cat then
        Register(t, cat, label, { Prompt = prompt })
    elseif prompt.Name == "LootPrompt" then
        Register(t, "drawers", CleanName(t.Name), { Prompt = prompt })
        Dbg("CONTAINER?", t, "LootPrompt mode=" .. Mode.Name)
    else
        Register(t, "interactables", CleanName(t.Name), { Prompt = prompt })
        Dbg("ACTIVATE?", t, "mode=" .. Mode.Name)
    end
end

local function Process(inst)
    if inst:IsA("ProximityPrompt") then
        local pn = inst.Name
        if pn == "HidePrompt" then
            if not Active.wardrobes then return end
            local m = inst:FindFirstAncestorWhichIsA("Model")
            if m and m ~= CurrentRooms and m.Parent ~= CurrentRooms then
                if not HIDE_NAMES[m.Name] then Dbg("HIDE?", m) end
                Register(m, "wardrobes", HideLabel(m.Name))
            end
        elseif pn == "ModulePrompt" or pn == "HerbPrompt" then
            if not (Active.items or Active.keys or Active.objectives or Active.gold
                or Active.stardust or Active.glitch or Active.lotus or Active.scanner) then return end
            local t = ResolveTarget(inst)
            if not t then return end
            if Watch.IsBurrow(t) or Watch.IsBurrow(inst) then return end
            if RegisterByName(t) then return end
            if Tracked[t] and not IsContainerModel(t) then return end

            local nn = Norm(t.Name)
            if nn:find("sally", 1, true) then
                RegisterWhenReady(t, "objectives", "Sally's Toy")
                return
            end

            local objText = inst.ObjectText
            -- El texto que muestra el juego (ObjectText) tiene prioridad sobre el nombre del modelo
            local cands = { t.Name, t:GetAttribute("DisplayName"), objText }
            if pn == "HerbPrompt" then cands[#cands + 1] = "Green Herb" end
            local display = ResolveItem(cands)
            if not display then
                -- Items raros (aparecen solo con "Show Unlisted Items"): se reconocen por texto y van a su ESP propio
                local blob = Norm(t.Name) .. "|" .. Norm(tostring(t:GetAttribute("DisplayName") or "")) .. "|" .. Norm(tostring(objText or ""))
                if blob:find("glitch", 1, true) then
                    display = "Glitch Fragment"
                elseif blob:find("stardust", 1, true) then
                    display = "Stardust"
                elseif blob:find("module", 1, true) and blob:find("scan", 1, true) then
                    display = "Scanner Module" -- solo el MODULO; el item ObjectScanner es "Scanner" (ESP Items)
                end
            end
            if not display and Mode.Name == "Outdoors" then return end -- en Outdoors no se marcan items desconocidos
            if Cfg.Debug then
                local byName, byText = ResolveItem({ t.Name }), ResolveItem({ objText })
                if byName and byText and byName ~= byText then
                    Dbg("ITEM-MISMATCH", t, "model=" .. byName .. " text=" .. byText)
                end
            end
            if not display then
                Dbg("ITEM?", t, "prompt=" .. pn .. " objectText=" .. tostring(objText))
            end
            local special = display and SPECIAL_CATS[display]
            if special then
                Register(t, special, display, { Known = true, Key = display })
            else
                Register(t, "items", display or CleanName(t.Name), { Known = display ~= nil, Key = display })
            end
        elseif pn == "ActivateEventPrompt" or pn == "LootPrompt" then
            if not (Active.drawers or Active.lockers or Active.interactables) then return end
            ProcessContainerPrompt(inst)
        elseif not KNOWN_PROMPTS[pn] then
            Dbg("PROMPT?", inst.Parent or inst, "prompt=" .. pn .. " mode=" .. Mode.Name)
        end
        return
    end

    if inst:IsA("Model") or inst:IsA("BasePart") then
        -- The Stairwell: Crusher (entidad) y objetos propios (Exit, Shopping Cart, Depot)
        if inst.Name == "Crusher" then
            local pr = inst.Parent
            if Active.entities and pr and pr.Name == "StairwellCrusher" and CurrentRooms and inst:IsDescendantOf(CurrentRooms) then
                RegisterCrusher(inst)
                return
            end
        else
            local sd = STAIR_ASSETS[inst.Name]
            if sd and Active[sd[1]] then
                local owner = StairOwner(inst)
                if owner then RegisterWhenReady(owner, sd[1], sd[2]) end
                return
            end
        end
        if RegisterByName(inst) then return end
        if inst:IsA("Model") then
            local n = inst.Name
            local lab = (Active.entities and Cfg.RoomEntities and inst.Parent ~= Workspace) and EntityLabel(n, true) or nil
            if HIDE_EXACT[n] then
                Register(inst, "wardrobes", HIDE_EXACT[n])
            elseif lab and not HasTrackedAncestor(inst) then
                Register(inst, "entities", lab, { Known = true, Key = lab })
            else
                local cl = CHEST_EXACT[n]
                if type(cl) == "string" then
                    Register(inst, "chests", cl)
                else
                    if cl == nil then -- se clasifica el nombre una sola vez (false = no es cofre)
                        local low = n:lower()
                        cl = false
                        if low:find("chest", 1, true) then
                            local label = "Chest"
                            if low:find("locked", 1, true) then label = "Locked Chest"
                            elseif low:find("vine", 1, true) then label = "Vine Chest" end
                            cl = { label }
                        end
                        CHEST_EXACT[n] = cl
                    end
                    if cl and not HasTrackedAncestor(inst) then Register(inst, "chests", cl[1]) end
                end
            end
        end
    end
end

local function RegisterDoor(room, door)
    if not door:IsA("Model") or door.Name ~= "Door" then return end
    local num = tonumber(room.Name)
    Register(door, "doors", "Door " .. (num and (num + 1) or room.Name), {
        Part = door:FindFirstChild("Door") or GetPart(door),
        RoomNum = num,
    })
end

local function ScanRoom(room)
    task.spawn(function()
        room:WaitForChild("Door", 10)
        for _, c in ipairs(room:GetChildren()) do RegisterDoor(room, c) end
        room.ChildAdded:Connect(function(c) RegisterDoor(room, c) end)
    end)
end

PurgeInactive = function()
    for inst, e in pairs(Tracked) do
        if not Active[e.Cat] then RemoveEntry(inst) end
    end
end

----------------------------------------------------
-- Entidades
-- Solo se marca lo que tiene un nombre conocido. Los modelos desconocidos
-- se ignoran salvo que actives "Show Unlisted Entities".
----------------------------------------------------
local IGNORE = { CurrentRooms = true, Drops = true, Camera = true, Terrain = true }

-- Nombres de la puerta falsa de Dupe. "duplicate"/"dupl..." NO cuenta.
local function IsDupeName(name)
    local l = name:lower()
    if l:find("dupl", 1, true) then return false end
    return l == "doorfake" or l == "fakedoor" or l:match("^dupe") ~= nil
end

local function RegisterEntityWhenReady(m, label, known)
    task.spawn(function()
        for _ = 1, 20 do
            if not m.Parent then return end
            if GetPart(m) then
                Register(m, "entities", label, { Known = known, Key = known and label or nil })
                return
            end
            task.wait(0.1)
        end
    end)
end

-- Modelos que aparecen directamente en Workspace (Rush, Ambush, Eyes, Screech, glitched...)
local function ProcessEntity(m, initial)
    if not Active.entities then return end
    if not m:IsA("Model") or Tracked[m] then return end
    if IGNORE[m.Name] or IsDupeName(m.Name) or IsExcludedEntity(m.Name) or Players:GetPlayerFromCharacter(m) then return end

    local label = EntityLabel(m.Name, false)
    if label then
        RegisterEntityWhenReady(m, label, true)
        return
    end
    if initial or not Cfg.UnlistedEntities then return end
    Dbg("ENTITY?", m, "mode=" .. Mode.Name)
    RegisterEntityWhenReady(m, CleanName(m.Name), false)
end

-- Dupe: SOLO la puerta falsa (nombre exacto), SOLO dentro de CurrentRooms y SOLO en modos con Dupe.
-- Ya no se sube por los ancestros: una puerta normal nunca se marca como Dupe.
local function ProcessDupe(m)
    if not Active.dupe or not m:IsA("Model") or Tracked[m] then return end
    if not CurrentRooms or not m:IsDescendantOf(CurrentRooms) then return end
    if m.Name == "Door" or not IsDupeName(m.Name) then return end

    local room = m
    while room.Parent and room.Parent ~= CurrentRooms do room = room.Parent end
    Dbg("DUPE", m, "room=" .. room.Name .. " mode=" .. Mode.Name)
    Register(m, "dupe", "Dupe [Fake Door]", { Known = true, Key = "Dupe", RoomNum = tonumber(room.Name) })
end

-- Entidades con rig dentro de cuartos (Figure, Seek, Drone...): solo nombre EXACTO conocido
local function ProcessRig(m)
    if not Active.entities or not Cfg.RoomEntities then return end
    if not m or not m:IsA("Model") or m == Workspace or Tracked[m] then return end
    if Players:GetPlayerFromCharacter(m) or IGNORE[m.Name] or IsDupeName(m.Name) or IsExcludedEntity(m.Name) or HasTrackedAncestor(m) then return end

    local label = EntityLabel(m.Name, true, true)
    if not label then
        Dbg("RIG?", m, "mode=" .. Mode.Name) -- solo se registra en el log, NO se marca
        return
    end
    RegisterEntityWhenReady(m, label, true)
end

-- Escaleras y escaleras de mano (TrussPart = parte escalable de Roblox + nombres Ladder/Stairs)
local function StairLabel(name)
    local n = Norm(name)
    if n:find("ladder", 1, true) then return "Ladder" end
    if n == "stairs" or n == "stair" or n:find("staircase", 1, true) then return "Stairs" end
    return nil
end

local function ProcessStairs(d)
    if not Active.stairs or Tracked[d] then return end
    if d:IsA("TrussPart") then
        local owner = d
        local p = d.Parent
        if p and p:IsA("Model") and p ~= Workspace and p ~= CurrentRooms
            and not (CurrentRooms and p.Parent == CurrentRooms) and not Players:GetPlayerFromCharacter(p) then
            owner = p
        end
        if not Tracked[owner] and not HasTrackedAncestor(owner) then
            Register(owner, "stairs", "Ladder")
        end
    elseif d:IsA("Model") then
        local lab = StairLabel(d.Name)
        if lab and not HasTrackedAncestor(d) and not Players:GetPlayerFromCharacter(d) then
            Register(d, "stairs", lab)
        end
    end
end

-- Noise: Workspace.Camera.NoiseModel   |   TV de Noise: Workspace.CurrentRooms.[sala].Assets.TV_Stand
-- FIX: Hijack tambien puede venir como NoiseModel. Se mira el nombre, atributos y descendientes
-- buscando "hijack" y se espera un momento a que el modelo cargue sus hijos antes de etiquetarlo.
local function HasWord(v, w)
    return type(v) == "string" and v:lower():find(w, 1, true) ~= nil
end
local function NoiseIsHijack(d)
    if HasWord(d.Name, "hijack") then return true end
    for k, v in pairs(d:GetAttributes()) do
        if HasWord(k, "hijack") or HasWord(v, "hijack") then return true end
    end
    local n = 0
    for _, x in ipairs(d:GetDescendants()) do
        if HasWord(x.Name, "hijack") then return true end
        for k, v in pairs(x:GetAttributes()) do
            if HasWord(k, "hijack") or HasWord(v, "hijack") then return true end
        end
        n = n + 1
        if n > 300 then break end
    end
    return false
end
local function DescribeChildren(d)
    local out = {}
    for _, c in ipairs(d:GetChildren()) do out[#out + 1] = c.ClassName .. ":" .. c.Name end
    for k, v in pairs(d:GetAttributes()) do out[#out + 1] = "@" .. k .. "=" .. tostring(v) end
    return table.concat(out, ", ")
end

local function ProcessNoise(d)
    if not Active.entities or Tracked[d] then return end
    if not (d:IsA("Model") or d:IsA("BasePart")) then return end
    local nm = d.Name
    if nm == "NoiseModel" then
        local cam = Workspace:FindFirstChild("Camera")
        if not (cam and d.Parent == cam) then return end
        Dbg("NOISEMODEL", d, DescribeChildren(d)) -- con Debug activado imprime lo que tiene dentro
        task.spawn(function()
            local t0 = os.clock()
            local label = "Noise"
            while d.Parent and os.clock() - t0 < 1.2 do
                if NoiseIsHijack(d) then label = "Hijack" break end
                task.wait(0.1)
            end
            if not d.Parent then return end
            for _ = 1, 20 do
                if not d.Parent then return end
                if GetPart(d) then
                    Register(d, "entities", label, { Known = true, Key = label })
                    return
                end
                task.wait(0.1)
            end
        end)
    elseif nm == "TV_Stand" then
        local p = d.Parent
        if p and p.Name == "Assets" and CurrentRooms and d:IsDescendantOf(CurrentRooms) then
            RegisterEntityWhenReady(d, "Noise TV", true)
        end
    end
end

-- FIX Bash/Stem/Hijack: modelos de entidad que viven en Workspace.Camera o dentro de tu personaje
-- (no en Workspace directo). Antes solo se veian "agarrados" porque ahi si se escaneaban.
local function ProcessLoose(d)
    if not Active.entities or Tracked[d] or not d:IsA("Model") then return end
    if d.Name == "NoiseModel" then return end
    local p = d.Parent
    local cam = Workspace:FindFirstChild("Camera")
    local char = LocalPlayer.Character
    if not ((cam and p == cam) or (char and p == char)) then return end
    if IsExcludedEntity(d.Name) then return end
    local label = EntityLabel(d.Name, false)
    if not label or label == "Mandrake" then return end
    local set = ENTITY_MODES[label]
    if not Mode.All() and set and not set["*"] and not set[EntityModeKey()] then return end
    Dbg("LOOSE", d, "label=" .. label)
    RegisterEntityWhenReady(d, label, true)
end

local function OnDescendant(d)
    -- PERF: solo estas clases importan; el resto (Decals, Sounds, Attachments, Scripts...) se descarta ya
    if not (d:IsA("ProximityPrompt") or d:IsA("Model") or d:IsA("BasePart") or d:IsA("Humanoid") or d:IsA("AnimationController")) then return end
    -- Stem: se detecta donde este (no solo en tu mano). Nombre exacto/variantes, solo en modos donde existe.
    if d:IsA("Model") and Active.entities and not Tracked[d] and STRICT_SKIP.__stem[Norm(d.Name)] then
        local set = ENTITY_MODES["Stem"]
        if (Mode.Name == "Unknown" or Mode.Name == "Test" or (set and set[EntityModeKey()]))
            and not Players:GetPlayerFromCharacter(d) and not HasTrackedAncestor(d) then
            Dbg("STEM", d, "mode=" .. Mode.Name)
            RegisterEntityWhenReady(d, "Stem", true)
        end
    end
    Process(d)
    ProcessStairs(d)
    ProcessNoise(d)
    ProcessLoose(d)
    if d:IsA("Model") then
        if IsDupeName(d.Name) then ProcessDupe(d) end
        -- Entidades glitched pueden aparecer anidadas: se detectan por su nombre oficial
        if Active.entities and not Tracked[d] then
            for _, g in ipairs(GLITCH_TOKENS) do
                if d.Name:find(g[1], 1, true) then
                    ProcessEntity(d, false)
                    break
                end
            end
        end
    elseif d:IsA("Humanoid") or d:IsA("AnimationController") then
        ProcessRig(d.Parent)
    end
end

Rescan = function()
    Mode.Gen = (Mode.Gen or 0) + 1
    local gen = Mode.Gen
    task.spawn(function()
        local n, t0 = 0, os.clock()
        for _, d in ipairs(Workspace:GetDescendants()) do
            pcall(OnDescendant, d)
            n = n + 1
            -- PERF: presupuesto de ~4ms por frame (antes 300 objetos fijos, que en Outdoors dejaba tirones)
            if n % 100 == 0 and os.clock() - t0 > 0.004 then
                task.wait()
                t0 = os.clock()
                if Mode.Gen ~= gen then return end -- empezo un rescan nuevo: este se cancela
            end
        end
        for _, c in ipairs(Workspace:GetChildren()) do pcall(ProcessEntity, c, true) end
        if CurrentRooms then
            for _, room in ipairs(CurrentRooms:GetChildren()) do
                for _, c in ipairs(room:GetChildren()) do pcall(RegisterDoor, room, c) end
            end
        end
    end)
end

print("[R4NS0M] Loaded Workspace Element Detection")
print("[R4NS0M] Loading Mode Connections")
-- Conexiones (se crean una sola vez, despues de detectar el modo)
-- PERF: los objetos nuevos (el mapa de Outdoors carga miles) entran a una cola y se procesan con un
-- presupuesto de ~3ms por frame, en vez de todos de golpe dentro del evento.
do
    local queue, head, tail = {}, 1, 0
    Workspace.DescendantAdded:Connect(function(d)
        if d:IsA("ProximityPrompt") or d:IsA("Model") or d:IsA("BasePart") or d:IsA("Humanoid") or d:IsA("AnimationController") then
            tail = tail + 1
            queue[tail] = d
        end
    end)
    RunService.Heartbeat:Connect(function()
        if head > tail then return end
        local t0 = os.clock()
        while head <= tail do
            local d = queue[head]
            queue[head] = nil
            head = head + 1
            if d.Parent then pcall(OnDescendant, d) end
            if head % 10 == 0 and os.clock() - t0 > 0.003 then break end
        end
        if head > tail then head, tail = 1, 0 end
    end)
end
Workspace.ChildAdded:Connect(function(c) pcall(ProcessEntity, c, false) end)

CurrentRooms = Workspace:FindFirstChild("CurrentRooms")
task.spawn(function()
    if not CurrentRooms then
        CurrentRooms = Workspace:WaitForChild("CurrentRooms", 60)
        if CurrentRooms then Rescan() end
    end
    if not CurrentRooms then
        Dbg("NOROOMS", Workspace, "CurrentRooms not found")
        return
    end
    for _, room in ipairs(CurrentRooms:GetChildren()) do ScanRoom(room) end
    CurrentRooms.ChildAdded:Connect(ScanRoom)
end)
Rescan()

print("[R4NS0M] Loaded Mode Connections")
print("[R4NS0M] Loading Player ESP")
----------------------------------------------------
-- Jugadores (ESP Players)
----------------------------------------------------
do
    local function TrackPlayer(plr)
        if plr == LocalPlayer then return end
        local function onChar(char)
            task.spawn(function()
                local root = char:WaitForChild("HumanoidRootPart", 10)
                if not root or not char.Parent then return end
                local name = (Cfg.PlayerNames == "Username") and plr.Name or plr.DisplayName
                Register(char, "players", name, { Known = true, Key = plr.Name })
            end)
        end
        if plr.Character then onChar(plr.Character) end
        plr.CharacterAdded:Connect(onChar)
    end
    for _, p in ipairs(Players:GetPlayers()) do TrackPlayer(p) end
    Players.PlayerAdded:Connect(TrackPlayer)
end

print("[R4NS0M] Loaded Player ESP")
print("[R4NS0M] Loading Rendering")
----------------------------------------------------
-- Render
----------------------------------------------------
local function FilterPasses(e)
    if e.Cat == "items" then
        if e.Known then return Cfg.ItemFilter[e.Key] == true end
        return Cfg.UnlistedItems
    elseif e.Cat == "entities" then
        if e.Known then
            local set = ENTITY_MODES[e.Key]
            if not Mode.All() and set and not set["*"] and not set[EntityModeKey()] then
                return false -- entidad de otro modo
            end
            return Cfg.EntityFilter[e.Key] == true
        end
        return Cfg.UnlistedEntities
    end
    return true
end

local function HasVisibleGeometry(inst)
    if inst:IsA("BasePart") then return inst.Transparency < 0.95 end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("BasePart") and d.Transparency < 0.95 then return true end
    end
    return false
end

Mode.Sort = function(a, b)
    local pa = a.Cat == "entities" and 0 or 1
    local pb = b.Cat == "entities" and 0 or 1
    if pa ~= pb then return pa < pb end
    return a.Dist < b.Dist
end

local function Refresh()
    local cam = Workspace.CurrentCamera
    if not cam then return end

    -- PERF: si no hay ninguna categoria activada no se recorre nada y se liberan las instancias
    local any = false
    for id, c in pairs(Cfg.Categories) do
        if c.Enabled and Active[id] then any = true break end
    end
    if not any then
        for _, e in pairs(Tracked) do
            if e.Shown or e.HL or e.Line then Mode.Free(e) end
            e.Shown = false
        end
        Mode.TracerList = nil
        return
    end

    local camPos = cam.CFrame.Position
    local currentRoom = LocalPlayer:GetAttribute("CurrentRoom")
    local list, n = {}, 0
    local maxDist = Cfg.MaxDistance

    for inst, e in pairs(Tracked) do
        local part = e.Part
        if not part.Parent then
            RemoveEntry(inst)
        else
            local cat = e.Cat
            local ok = Active[cat] and Cfg.Categories[cat].Enabled and FilterPasses(e)
            if ok and (cat == "doors" or cat == "dupe") and e.RoomNum and currentRoom and e.RoomNum < currentRoom then
                ok = false -- puertas de cuartos ya superados
            end
            if ok and e.Prompt and Cfg.HideLooted then
                local pr = e.Prompt
                if not pr.Parent or pr.Enabled == false then ok = false end -- ya abierto/saqueado
            end
            if ok then
                local d = (part.Position - camPos).Magnitude
                e.Dist = d
                ok = (cat == "entities" and not (Watch.Limited[e.Key] or Watch.Limited[e.Label])) or d <= maxDist
            end
            if ok then
                n = n + 1
                list[n] = e
            else
                HideEntry(e)
            end
        end
    end

    -- Orden (entidades primero, luego por distancia) solo si hace falta: limite de Highlights o de objetos
    local maxHL = Watch.MaxHL or MAX_HIGHLIGHTS
    local cap = math.min(Cfg.MaxObjects or 120, Watch.PerfCap or math.huge)
    if n > maxHL or n > cap then
        table.sort(list, Mode.Sort)
        for i = cap + 1, n do
            HideEntry(list[i])
            list[i] = nil
        end
        if n > cap then n = cap end
    end

    local now = os.clock()
    local meters = Cfg.Unit == "Meters"
    local fontEnum = FONT_MAP[Cfg.Font] or Enum.Font.Oswald
    local textSize = Cfg.TextSize
    local bbHeight = math.ceil(textSize * 2.5) + 6
    local fillT, outT = Cfg.FillTransparency, Cfg.OutlineTransparency
    local showName, showDist = Cfg.ShowName, Cfg.ShowDistance
    local tracers, tn = {}, 0

    for i = 1, n do
        local e = list[i]
        local cat = e.Cat
        local cc = Cfg.Categories[cat]
        local color = cc.Color
        e.Shown = true
        e.HidSince = nil
        if not e.HL then Mode.Build(e) end

        if cat == "doors" then
            e.Base = e.Base or e.Label
            e.Label = e.Base .. (e.Inst:FindFirstChild("Lock") and " [Locked]" or "")
        elseif cat == "players" then
            local plr = Players:GetPlayerFromCharacter(e.Inst)
            if plr then e.Label = (Cfg.PlayerNames == "Username") and plr.Name or plr.DisplayName end
        end

        -- PERF: revisar la geometria visible (GetDescendants) solo cada 6s
        if now - e.GeoT > 6 then
            e.GeoT = now
            e.NoGeo = not HasVisibleGeometry(e.Inst)
        end
        local useBox = e.NoGeo or i > maxHL

        local hl, box, bb, tl = e.HL, e.Box, e.BB, e.TL

        -- PERF: solo se escriben propiedades cuando cambian
        if e.Col ~= color or e.Fill ~= fillT or e.Out ~= outT then
            e.Col, e.Fill, e.Out = color, fillT, outT
            hl.FillColor = color
            hl.OutlineColor = color
            hl.FillTransparency = fillT
            hl.OutlineTransparency = outT
            box.Color3 = color
            box.Transparency = math.max(0.55, fillT)
            tl.TextColor3 = color
            if e.Line then e.Line.BackgroundColor3 = color end
        end

        hl.Enabled = not useBox
        box.Visible = useBox
        if useBox then
            -- las cajas de entidades/jugadores se actualizan siempre; el resto cada 1.5s
            if cat == "entities" or cat == "players" or cat == "dupe" or now - (e.BoxT or 0) > 1.5 then
                e.BoxT = now
                if e.Inst:IsA("Model") then
                    local okb, cf, size = pcall(e.Inst.GetBoundingBox, e.Inst)
                    if okb then
                        box.CFrame = e.Part.CFrame:ToObjectSpace(cf)
                        box.Size = size
                    end
                else
                    box.CFrame = CFrame.new()
                    box.Size = e.Part.Size
                end
            end
        end

        local dtxt
        if showDist then
            local d = meters and (e.Dist * 0.28) or e.Dist
            dtxt = string.format(meters and "[%dm]" or "[%d]", math.floor(d + 0.5))
        end
        local text
        if showName then
            text = showDist and (e.Label .. "\n" .. dtxt) or e.Label
        else
            text = dtxt or ""
        end
        if e.Text ~= text then
            e.Text = text
            tl.Text = text
        end
        if e.TS ~= textSize or e.TF ~= fontEnum then
            e.TS, e.TF = textSize, fontEnum
            tl.TextSize = textSize
            tl.Font = fontEnum
            bb.Size = UDim2.fromOffset(300, bbHeight)
        end
        bb.Enabled = text ~= ""

        -- Tracers: la linea solo se crea si la categoria tiene tracer y se dibuja desde RenderStepped
        if cc.Tracer then
            if not e.Line then
                local line = Instance.new("Frame")
                line.BorderSizePixel = 0
                line.AnchorPoint = Vector2.new(0.5, 0.5)
                line.Visible = false
                line.BackgroundColor3 = color
                line.Parent = Gui
                e.Line = line
            end
            tn = tn + 1
            tracers[tn] = e
        elseif e.Line and e.Line.Visible then
            e.Line.Visible = false
        end
    end

    Mode.TracerList = tracers
end

task.spawn(function()
    while true do
        pcall(Refresh)
        task.wait(math.max(1 / math.max(Cfg.RefreshRate or 4, 1), Watch.PerfInterval or 0))
    end
end)

task.spawn(function()
    while true do
        pcall(WatchMode)
        pcall(UpdateOverlay)
        task.wait(2)
    end
end)

-- PERF: solo se recorren los objetos con tracer activo (antes se recorrian TODOS cada frame)
RunService.RenderStepped:Connect(function()
    local tracers = Mode.TracerList
    if not tracers or #tracers == 0 then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end

    local vp = cam.ViewportSize
    local origin
    if Cfg.TracerOrigin == "Center" then
        origin = Vector2.new(vp.X / 2, vp.Y / 2)
    elseif Cfg.TracerOrigin == "Top" then
        origin = Vector2.new(vp.X / 2, 0)
    elseif Cfg.TracerOrigin == "Mouse" then
        origin = UserInputService:GetMouseLocation()
    else
        origin = Vector2.new(vp.X / 2, vp.Y)
    end

    for i = 1, #tracers do
        local e = tracers[i]
        local line = e.Line
        if line then
            if e.Shown and e.Part.Parent then
                local v = cam:WorldToViewportPoint(e.Part.Position)
                if v.Z > 0 then
                    local target = Vector2.new(v.X, v.Y)
                    local diff = target - origin
                    line.Size = UDim2.fromOffset(diff.Magnitude, Cfg.TracerThickness)
                    line.Position = UDim2.fromOffset((origin.X + target.X) / 2, (origin.Y + target.Y) / 2)
                    line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
                    line.Visible = true
                else
                    line.Visible = false
                end
            elseif line.Visible then
                line.Visible = false
            end
        end
    end
end)

print("[R4NS0M] Loaded Rendering")
print("[R4NS0M] Loading Visuals UI")
----------------------------------------------------
-- UI (pestana Visuals): solo se crean las opciones del modo detectado
----------------------------------------------------
Setters.ItemFilter = function() end
Setters.EntityFilter = function() end
Setters.FillPercent = function() end

local function AddToggle(tab, id, title, desc, default, cb)
    local el = tab:Toggle({ Title = title, Desc = desc, Value = default, Callback = cb })
    Setters[id] = function(v) pcall(function() el:Set(v) end) end
end

local function AddSlider(tab, id, title, desc, min, max, default, cb)
    local el = tab:Slider({
        Title = title, Desc = desc, Step = 1,
        Value = { Min = min, Max = max, Default = default },
        Callback = cb
    })
    Setters[id] = function(v) pcall(function() el:Set(v) end) end
end

local function AddDropdown(tab, id, title, desc, values, default, cb)
    local el = tab:Dropdown({ Title = title, Desc = desc, Values = values, Value = default, Callback = cb })
    Setters[id] = function(v) pcall(function() el:Select(v) end) end
end

local function AddColor(tab, id, title, desc, default, cb)
    local el
    local ok = pcall(function()
        el = tab:Colorpicker({ Title = title, Desc = desc, Default = default, Callback = cb })
    end)
    if not ok then
        pcall(function()
            el = tab:ColorPicker({ Title = title, Desc = desc, Default = default, Callback = cb })
        end)
    end
    Setters[id] = function(v) pcall(function() el:Set(v) end) end
end

local CATEGORY_UI = {
    { id = "doors", section = "Navigation", title = "ESP Doors",
      desc = "Marks the exit door of every room ahead as 'Door N' (adds [Locked] when it needs a key). Doors of rooms you already passed are hidden." },
    { id = "dupe", section = "Navigation", title = "ESP Dupe (Fake Doors)",
      desc = "Marks only the trapped fake doors made by Dupe, labeled 'Dupe [Fake Door]'. Real doors are never tagged as Dupe. It only shows up in rooms where Dupe is active." },

    { id = "stairs", section = "Navigation", title = "ESP Stairs & Ladders",
      desc = "Marks the ladders and stairs of The Mines (climbable trusses and objects named Ladder or Stairs). Only available in that mode. Presets leave it off." },

    { id = "gold", section = "Loot", title = "ESP Gold",
      desc = "Gold piles on the floor. Shows the amount in brackets when the game exposes it." },
    { id = "keys", section = "Loot", title = "ESP Keys & Fuses",
      desc = "Keys, Electrical Room keys and Fuses needed to unlock doors or start machinery." },
    { id = "chests", section = "Loot", title = "ESP Chests",
      desc = "Regular, locked and vine-covered chests. Locked chests need a key or lockpicks." },
    { id = "drawers", section = "Loot", title = "ESP Drawers",
      desc = "Loot containers: drawers, desks, dressers, cabinets and makeshift drawers. Hidden after you open them (see Hide Looted Containers)." },
    { id = "lockers", section = "Loot", title = "ESP Lockers & Toolboxes",
      desc = "Item lockers, small lockers and toolboxes that contain loot. These are not hiding spots. Hidden after you open them." },
    { id = "items", section = "Loot", title = "ESP Items",
      desc = "Pickup items lying around (Flashlight, Lockpicks, Vitamins, Crucifix...). Choose which ones to show in the Item Filter below." },
    { id = "stardust", section = "Loot", title = "ESP Stardust",
      desc = "Stardust pickups (internally StardustPickup). They have their own ESP and never show in ESP Items." },
    { id = "glitch", section = "Loot", title = "ESP Glitch Fragment",
      desc = "The rare Glitch Fragment (internally GlitchCube). It has its own ESP and never shows in ESP Items. Glitched Rush, Ambush and Screech are handled by ESP Entities instead." },
    { id = "scanner", section = "Loot", title = "ESP Scanner Module",
      desc = "The module for the Scanner. It has its own ESP and never shows in ESP Items (the Scanner item itself is listed in ESP Items). Needs its Dex name in PENDING_DEX_NAMES to be detected." },
    { id = "lotus", section = "Loot", title = "ESP Lotus Petals",
      desc = "Lotus petals scattered around the Outdoors." },

    { id = "wardrobes", section = "Hiding & Objectives", title = "ESP Hiding Spots",
      desc = "Places you can hide in: closets, beds, lockers and tool sheds." },
    { id = "objectives", section = "Hiding & Objectives", title = "ESP Objectives",
      desc = "Room puzzle pieces: levers, timer levers, library books, breaker poles, Sally's toy (also when they are inside a drawer) and the Stairwell fire alarm lever." },

    { id = "exit", section = "Stairwell", title = "ESP Emergency Exit",
      desc = "Marks the emergency exit sign of the Stairwell rooms. Only available in The Stairwell." },
    { id = "cart", section = "Stairwell", title = "ESP Shopping Cart",
      desc = "Marks the shopping carts of the Stairwell (inside rooms or loose in the map). Only available in The Stairwell." },

    { id = "entities", section = "Entities", title = "ESP Entities",
      desc = "Monsters that belong to the detected game mode only. Entities from other modes are never shown. Pick which ones in the Entity Filter below." },

    { id = "players", section = "Players", title = "ESP Players",
      desc = "Marks the other players in your run with their name and distance. Choose display name or username in the Display section." },

    { id = "interactables", section = "Extras", title = "ESP Interactables",
      desc = "Any other object with an interaction prompt that does not fit another category (in The Stairwell it also marks the Depots). Can be noisy, so presets leave it off." },
}

local UICreated, SectionCreated = {}, {}

local function EnsureCategoryUI(id)
    if UICreated[id] or not Active[id] then return end
    for _, c in ipairs(CATEGORY_UI) do
        if c.id == id then
            UICreated[id] = true
            if not SectionCreated[c.section] then
                SectionCreated[c.section] = true
                VisualsTab:Section({ Title = c.section })
            end
            AddToggle(VisualsTab, "cat_" .. c.id, c.title, c.desc, Cfg.Categories[c.id].Enabled, function(v)
                Cfg.Categories[c.id].Enabled = v
            end)
            AddColor(VisualsTab, "col_" .. c.id, "Color: " .. (c.title:gsub("ESP ", "")),
                "Highlight, label and tracer color for this category.", Cfg.Categories[c.id].Color, function(color)
                    Cfg.Categories[c.id].Color = color
                end)
            AddToggle(VisualsTab, "tr_" .. c.id, "Tracer: " .. (c.title:gsub("ESP ", "")),
                "Draws a line from the tracer origin to every object of this category. Independent from the other categories.",
                Cfg.Categories[c.id].Tracer, function(v)
                    Cfg.Categories[c.id].Tracer = v
                end)
            return
        end
    end
end

-- Presets: activa todo lo del modo detectado (excepto Interactables, que es ruidoso)
ApplyPreset = function(modeName)
    local list = MODE_CATS[modeName]
    if not list then return false end
    for _, id in ipairs(list) do
        if id ~= "interactables" and id ~= "stairs" then
            Cfg.Categories[id].Enabled = true
            if Setters["cat_" .. id] then Setters["cat_" .. id](true) end
        end
    end
    return true
end

print("[R4NS0M] Loaded Visuals UI")
print("[R4NS0M] Loading Main Tab")
----------------------------------------------------
-- MAIN TAB: estado del modo
----------------------------------------------------
MainTab:Section({ Title = "Game Mode" })
ModeParagraph = MainTab:Paragraph({
    Title = "Detected at load: " .. Mode.Name,
    Desc = "The script detects the game mode when it starts and only loads the ESP options and detectors that mode needs. "
        .. "If the mode changes while you play, it reconfigures itself and adds the new options at the bottom of the Visuals tab."
})
MainTab:Button({
    Title = "Re-detect Game Mode",
    Desc = "Reads the game data again. Use it if the mode was not detected correctly on load.",
    Callback = function()
        local ok, name = pcall(ReadMode)
        if ok and name ~= Mode.Name and (name ~= "Unknown" or Force.Name == "Unknown") then
            ApplyMode(name)
        else
            WindUI:Notify({ Title = "Game Mode", Content = "Current mode: " .. Mode.Name .. " (no change).", Duration = 3 })
        end
    end
})

-- Force Gamemode (el lobby se detecta solo como "Lobby" en modo Auto)
local FORCE_LABELS = {
    ["Auto (detect)"] = "Auto",
    ["Outdoors"] = "Outdoors",
    ["Backdoors"] = "Backdoor",
    ["Hotel"] = "Hotel",
    ["Mines"] = "Mines",
    ["Stairwells"] = "Stairwell",
    ["Super Hard Mode (Fools)"] = "Fools",
    ["Archives"] = "Archives",
    ["Rooms"] = "Rooms",
    ["Unknown"] = "Unknown",
    ["Test Mode (all ESP + entities)"] = "Test",
}
MainTab:Dropdown({
    Title = "Force Gamemode",
    Desc = "Forces the script to use a specific mode instead of auto-detecting it. Choose Auto (detect) to go back to normal detection (the Lobby is detected automatically).",
    Values = { "Auto (detect)", "Outdoors", "Backdoors", "Hotel", "Mines", "Stairwells", "Super Hard Mode (Fools)", "Archives", "Rooms", "Unknown", "Test Mode (all ESP + entities)" },
    Value = "Auto (detect)",
    Callback = function(label)
        local mode = FORCE_LABELS[label]
        if not mode then return end
        Force.Name = mode
        local ok, name = pcall(ReadMode)
        if ok and name and (name ~= Mode.Name) then
            ApplyMode(name)
        else
            WindUI:Notify({ Title = "Game Mode", Content = "Mode: " .. Mode.Name .. " (no change).", Duration = 3 })
        end
    end
})

print("[R4NS0M] Loaded Main Tab")
print("[R4NS0M] Loading Visuals Tab")
----------------------------------------------------
-- VISUALS TAB
----------------------------------------------------
VisualsTab:Section({ Title = "Mode Presets" })
AddToggle(VisualsTab, "AutoPreset", "Auto-enable ESP for this Mode",
    "Turns on every ESP of the detected mode when the mode is detected or changes. It never turns anything off.",
    Cfg.AutoPreset, function(v)
        Cfg.AutoPreset = v
        if v then ApplyPreset(Mode.Name) end
    end)
VisualsTab:Button({
    Title = "Enable All ESP for Current Mode",
    Desc = "One-click: enables every ESP category that exists in the detected mode (Interactables stays off).",
    Callback = function()
        if ApplyPreset(Mode.Name) then
            WindUI:Notify({ Title = "Preset", Content = "Enabled the ESP for " .. Mode.Name .. ".", Duration = 3 })
        else
            WindUI:Notify({ Title = "Preset", Content = "Mode not detected yet (" .. Mode.Name .. ").", Duration = 3 })
        end
    end
})

-- Categorias del modo actual
for _, c in ipairs(CATEGORY_UI) do EnsureCategoryUI(c.id) end

VisualsTab:Section({ Title = "Display" })
AddSlider(VisualsTab, "MaxDistance", "Max Distance",
    "Objects farther than this many studs are hidden. Entities are always shown, except the ones in the \"Entities with distance limit\" list.",
    50, 2000, Cfg.MaxDistance, function(v) Cfg.MaxDistance = v end)
AddSlider(VisualsTab, "MaxObjects", "Max ESP Objects",
    "Most objects drawn at once (the closest ones win; entities always have priority). Lower it if the game lags, mainly in The Outdoors.",
    20, 400, Cfg.MaxObjects, function(v) Cfg.MaxObjects = v end)
AddToggle(VisualsTab, "HideLooted", "Hide Looted Containers",
    "Hides drawers, lockers and chests once they have been opened or emptied.",
    Cfg.HideLooted, function(v) Cfg.HideLooted = v end)
AddToggle(VisualsTab, "ShowName", "Show Names", "Shows the name label above each marked object.",
    Cfg.ShowName, function(v) Cfg.ShowName = v end)
AddToggle(VisualsTab, "ShowDistance", "Show Distance", "Shows how far each marked object is from you.",
    Cfg.ShowDistance, function(v) Cfg.ShowDistance = v end)
AddDropdown(VisualsTab, "Unit", "Distance Unit", "Meters (studs x 0.28) or raw stud values. Only the number is shown, never the word 'studs'.",
    { "Meters", "Studs" }, Cfg.Unit, function(v) Cfg.Unit = v end)
AddSlider(VisualsTab, "TextSize", "Text Size", "Size of the name and distance labels.",
    10, 40, Cfg.TextSize, function(v) Cfg.TextSize = v end)
AddDropdown(VisualsTab, "Font", "Text Font", "Font used by the ESP name and distance labels.",
    FONT_LIST, Cfg.Font, function(v)
        if FONT_MAP[v] then Cfg.Font = v end
    end)
AddSlider(VisualsTab, "FillPercent", "Fill Opacity (%)", "0 = outline only, 100 = fully filled highlight.",
    0, 100, math.floor((1 - Cfg.FillTransparency) * 100), function(v)
        Cfg.FillTransparency = 1 - (v / 100)
    end)
AddDropdown(VisualsTab, "PlayerNames", "Player Name Type", "Whether ESP Players shows display names or usernames.",
    { "Display Name", "Username" }, Cfg.PlayerNames, function(v) Cfg.PlayerNames = v end)

VisualsTab:Section({ Title = "Tracers" })
VisualsTab:Paragraph({
    Title = "Per-category tracers",
    Desc = "Turn tracers on only for the ESP you want using the 'Tracer: ...' toggle under each category above. Origin and thickness below apply to all of them."
})
AddDropdown(VisualsTab, "TracerOrigin", "Tracer Origin", "Where the tracer lines start.",
    { "Bottom", "Center", "Top", "Mouse" }, Cfg.TracerOrigin, function(v) Cfg.TracerOrigin = v end)
AddSlider(VisualsTab, "TracerThickness", "Tracer Thickness", "Line width in pixels.",
    1, 5, Cfg.TracerThickness, function(v) Cfg.TracerThickness = v end)

-- Filtro de items (solo si el modo tiene ESP Items)
local ItemFilterCreated = false
local function EnsureItemFilterUI()
    if ItemFilterCreated or not Active.items then return end
    ItemFilterCreated = true
    VisualsTab:Section({ Title = "Item Filter" })

    local defaults = {}
    for _, n in ipairs(ITEM_NAMES) do
        if Cfg.ItemFilter[n] then defaults[#defaults + 1] = n end
    end

    local dd = VisualsTab:Dropdown({
        Title = "Items to show",
        Desc = "Choose which items ESP Items marks. Unchecked items stay hidden.",
        Values = ITEM_NAMES,
        Value = defaults,
        Multi = true,
        AllowNone = true,
        Callback = function(selected)
            local map = {}
            for _, n in ipairs(selected or {}) do map[n] = true end
            Cfg.ItemFilter = map
        end
    })
    Setters.ItemFilter = function(list) pcall(function() dd:Select(list) end) end

    VisualsTab:Button({
        Title = "Select All Items",
        Desc = "Show every item in the list.",
        Callback = function()
            for _, n in ipairs(ITEM_NAMES) do Cfg.ItemFilter[n] = true end
            Setters.ItemFilter(ITEM_NAMES)
        end
    })
    VisualsTab:Button({
        Title = "Clear All Items",
        Desc = "Hide every listed item (useful to pick just a few afterwards).",
        Callback = function()
            Cfg.ItemFilter = {}
            Setters.ItemFilter({})
        end
    })
    AddToggle(VisualsTab, "UnlistedItems", "Show Unlisted Items",
        "Also marks pickups that are not in the list above, using their in-game name.",
        Cfg.UnlistedItems, function(v) Cfg.UnlistedItems = v end)
end

-- Filtro de entidades (solo las del modo actual)
local EntityFilterCreated = false
local EntityDD
local function EnsureEntityFilterUI()
    if not Active.entities then return end
    local list = CurrentEntityList()

    if EntityFilterCreated then
        -- el modo cambio: solo actualizar la lista
        pcall(function() EntityDD:Refresh(list) end)
        local selected = {}
        for _, n in ipairs(list) do
            if Cfg.EntityFilter[n] then selected[#selected + 1] = n end
        end
        Setters.EntityFilter(selected)
        return
    end
    EntityFilterCreated = true
    VisualsTab:Section({ Title = "Entity Filter" })

    EntityDD = VisualsTab:Dropdown({
        Title = "Entities to show",
        Desc = "Only lists the entities of the detected mode. Unchecked entities are not marked.",
        Values = list,
        Value = list,
        Multi = true,
        AllowNone = true,
        Callback = function(selected)
            local map = {}
            for _, n in ipairs(selected or {}) do map[n] = true end
            Cfg.EntityFilter = map
        end
    })
    Setters.EntityFilter = function(l) pcall(function() EntityDD:Select(l) end) end

    VisualsTab:Button({
        Title = "Select All Entities",
        Desc = "Show every entity of this mode.",
        Callback = function()
            local l = CurrentEntityList()
            for _, n in ipairs(l) do Cfg.EntityFilter[n] = true end
            Setters.EntityFilter(l)
        end
    })
    VisualsTab:Button({
        Title = "Clear All Entities",
        Desc = "Hide every entity (useful to pick just a few afterwards).",
        Callback = function()
            Cfg.EntityFilter = {}
            Setters.EntityFilter({})
        end
    })
    AddToggle(VisualsTab, "UnlistedEntities", "Show Unlisted Entities",
        "Also marks NEW models that appear in Workspace with an unknown name. Off by default because it can mark objects that are not entities.",
        Cfg.UnlistedEntities, function(v) Cfg.UnlistedEntities = v end)
    AddToggle(VisualsTab, "RoomEntities", "Scan Rooms for Entities",
        "Also finds entities that live inside rooms (Figure, Seek, Snare, Teller...). Only exact internal names are matched, so decorations are never marked.",
        Cfg.RoomEntities, function(v) Cfg.RoomEntities = v end)
end

EnsureItemFilterUI()
EnsureEntityFilterUI()

-- Cuando cambia el modo: agrega las opciones nuevas y actualiza la lista de entidades
OnModeApplied = function()
    for _, c in ipairs(CATEGORY_UI) do EnsureCategoryUI(c.id) end
    EnsureItemFilterUI()
    EnsureEntityFilterUI()
end

pcall(function()
    WindUI:Notify({ Title = "Game Mode", Content = "Detected: " .. Mode.Name .. ". Only its ESP options are loaded.", Duration = 4 })
end)

print("[R4NS0M] Loaded Visuals Tab")
print("[R4NS0M] Loading Debug Mode")
----------------------------------------------------
-- MISC: Debug Mode
----------------------------------------------------
MiscTab:Section({ Title = "Debug Mode" })
AddToggle(MiscTab, "Debug", "Debug Mode", "Records anything the ESP does not recognize (item, entity or prompt) with its full path, so you can report the exact name and get it fixed.", false, function(v)
    Cfg.Debug = v
end)
AddToggle(MiscTab, "DebugVerbose", "Verbose Logging", "Also logs every object the ESP registers. Needs Debug Mode on and can print a lot.", false, function(v)
    Cfg.DebugVerbose = v
end)
MiscTab:Button({
    Title = "Print ESP Summary",
    Desc = "Shows how many objects are tracked per category right now.",
    Callback = function()
        local counts = {}
        for _, e in pairs(Tracked) do counts[e.Cat] = (counts[e.Cat] or 0) + 1 end
        local parts = {}
        for cat, n in pairs(counts) do parts[#parts + 1] = cat .. "=" .. n end
        table.sort(parts)
        local msg = #parts > 0 and table.concat(parts, ", ") or "nothing tracked yet"
        print("[R4NS0M] ESP summary: " .. msg)
        WindUI:Notify({ Title = "ESP Summary", Content = msg, Duration = 5 })
    end
})
MiscTab:Button({
    Title = "Copy Debug Log",
    Desc = "Copies everything logged so far to the clipboard.",
    Callback = function()
        local text = #DebugLog > 0 and table.concat(DebugLog, "\n") or "(empty)"
        if setclipboard then
            setclipboard(text)
            WindUI:Notify({ Title = "Debug", Content = "Copied " .. #DebugLog .. " entries.", Duration = 3 })
        else
            print(text)
            WindUI:Notify({ Title = "Debug", Content = "No clipboard support; printed to console.", Duration = 3 })
        end
    end
})
MiscTab:Button({
    Title = "Clear Debug Log",
    Callback = function()
        DebugLog, DebugSeen = {}, {}
        WindUI:Notify({ Title = "Debug", Content = "Log cleared.", Duration = 2 })
    end
})

AddToggle(MiscTab, "Overlay", "Debug Overlay", "On-screen panel: detected mode, room, GameData and tracked counts.", false, function(v)
    Cfg.Overlay = v
    UpdateOverlay()
end)
MiscTab:Button({
    Title = "Copy Game Info",
    Desc = "Copies the detected mode, GameData values, room names and Workspace contents. Send it when the mode is detected wrong.",
    Callback = function()
        pcall(ReadMode)
        local lines = {
            "PlaceId: " .. tostring(game.PlaceId),
            "Mode: " .. Mode.Name,
            "GameData: " .. (Mode.Raw ~= "" and Mode.Raw or "-"),
            "CurrentRoom attr: " .. tostring(LocalPlayer:GetAttribute("CurrentRoom")),
        }
        local rooms = Workspace:FindFirstChild("CurrentRooms")
        if rooms then
            local names = {}
            for _, r in ipairs(rooms:GetChildren()) do names[#names + 1] = r.Name end
            lines[#lines + 1] = "CurrentRooms: " .. table.concat(names, ",")
        else
            lines[#lines + 1] = "CurrentRooms: missing"
        end
        local top = {}
        for _, c in ipairs(Workspace:GetChildren()) do top[#top + 1] = c.ClassName .. ":" .. c.Name end
        lines[#lines + 1] = "Workspace: " .. table.concat(top, ", ")
        local text = table.concat(lines, "\n")
        if setclipboard then
            setclipboard(text)
            WindUI:Notify({ Title = "Debug", Content = "Game info copied.", Duration = 3 })
        else
            print(text)
            WindUI:Notify({ Title = "Debug", Content = "No clipboard support; printed to console.", Duration = 3 })
        end
    end
})

MiscTab:Button({
    Title = "Copy Nearby Objects (30 studs)",
    Desc = "Copies the names/paths of models and prompts around you. Stand next to the thing that fails and press it.",
    Callback = function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            WindUI:Notify({ Title = "Debug", Content = "Character not found.", Duration = 3 })
            return
        end
        local origin, out = root.Position, {}
        for _, d in ipairs(Workspace:GetDescendants()) do
            if #out >= 120 then break end
            local pos
            if d:IsA("ProximityPrompt") then
                local par = d.Parent
                pos = par and (par:IsA("BasePart") and par.Position or (par:IsA("Attachment") and par.WorldPosition))
            elseif d:IsA("Model") and not Players:GetPlayerFromCharacter(d) then
                local okp, cf = pcall(d.GetPivot, d)
                pos = okp and cf.Position
            end
            if pos and (pos - origin).Magnitude <= 30 then
                if d:IsA("ProximityPrompt") then
                    out[#out + 1] = string.format("Prompt | %s | ObjectText=%s | %s", d.Name, tostring(d.ObjectText), d:GetFullName())
                else
                    out[#out + 1] = string.format("Model | %s | %s", d.Name, d:GetFullName())
                end
            end
        end
        local text = "Mode: " .. Mode.Name .. "\n" .. (#out > 0 and table.concat(out, "\n") or "(nothing nearby)")
        if setclipboard then
            setclipboard(text)
            WindUI:Notify({ Title = "Debug", Content = "Copied " .. #out .. " objects.", Duration = 3 })
        else
            print(text)
            WindUI:Notify({ Title = "Debug", Content = "No clipboard support; printed to console.", Duration = 3 })
        end
    end
})

print("[R4NS0M] Loaded Debug Mode")
----------------------------------------------------
-- EXTRAS
--   Alerts      : Entity Notifier (DOORS achievement style popup)
--   Player      : Speed (max 90), Jump, Infinite Jump, Slide, Fly, Noclip, Fullbright
--   Automation  : Instant Proximity Prompt
--   Anti cheat  : Anticheat Manipulator (= Velocity Manipulation), Void Guard, floating buttons (ACM / SLIDE / FLY)
--   Keybinds    : PC hotkeys for all of the above
-- Todo va dentro de un bloque do..end para no gastar variables locales del script.
----------------------------------------------------
print("[R4NS0M] Loading Alerts")

do
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Entidades que normalmente no vale la pena avisar (el usuario puede activarlas igual)
local NOT_WORTH = {
    Timothy = true, Snare = true, Bob = true, ["El Goblino"] = true, Grampy = true,
    Portrait = true, Monument = true, Currents = true, Jeff = true, Crusher = true, ["Noise TV"] = true,
}

-- Consejos cortos (solo donde la mecanica es conocida)
local ENTITY_TIPS = {
    Rush = "Hide in a closet now!",
    Ambush = "Hide in a closet. It can come back several times.",
    Blitz = "Hide in a closet!",
    Seek = "Run and follow the path. Avoid the hands.",
    Figure = "Stay quiet. Crouch and keep your distance.",
    Eyes = "Do not look at it.",
    Lookman = "Do not look at it.",
    Halt = "Turn around when you see it.",
    Dupe = "Fake doors are trapped. Do not open them.",
}

local Ex = {
    -- Notifier
    Notify = true, NotifyStyle = "Doors Achievement", NotifySound = true, NotifyVolume = 100,
    NotifyDuration = 5, NotifyCooldown = 4, NotifyTips = true, NotifySoundId = "", NotifyIconId = "",
    NotifyFilter = {},
    -- Movement
    Speed = false, SpeedValue = 30, SpeedMethod = "Velocity",
    SpeedHack = false, SpeedHackValue = 30, DisableAnticheat = false, VelocityManipulationMode = "Velocity", PositionSpoof = false, CrouchSpoof = false, AutoHeartbeatMinigame = false,
    BypassGiggle = false, BypassDupe = false, BypassEyes = false, BypassLookman = false, BypassGloombatEggs = false, BypassSeekObstructions = false, BypassVacuum = false, BypassKillbricks = false, BypassSeekingWall = false, BypassSnare = false, BypassBanana = false, BypassJeff = false,
    RemoveScreech = false, RemoveHalt = false, RemoveA90 = false, RemoveDread = false, RemoveSurge = false, NoScreechDamage = false, NoHaltDamage = false, NoA90Damage = false, NoSurgeDamage = false,
    RemoveSeekTrigger = false, RemoveFigure = false, AutoRevive = false, FigureGodmode = false, RemoveBasementGate = false, RemovePaintingsDoor = false, RemoveSkeletonDoor = false,
    Key_PosSpoof = "H",
    Jump = false, JumpPower = 50, InfJump = false,
    Slide = false, SlideSpeed = 55,
    Fly = false, FlySpeed = 40,
    Noclip = false, Fullbright = false,
    -- Anticheat Manipulator
    ACM = false, VoidGuard = true, -- ACM ahora usa el metodo Velocity Manipulation
    FloatButtons = UserInputService.TouchEnabled, BtnACM = true, BtnFly = true, BtnSpeedHack = true,
    -- Automation
    InstantPrompt = false,
    -- Keybinds (nombres de Enum.KeyCode)
    Key_ACM = "X", Key_Noclip = "N", Key_Fly = "G", Key_Speed = "B", Key_Slide = "Z", Key_SpeedHack = "C",
    Key_Hub = "RightShift", -- abrir / cerrar el hub
}
for _, n in ipairs(ENTITY_LIST) do Ex.NotifyFilter[n] = not NOT_WORTH[n] end
Ex.NotifyFilter.Dupe = true

local FX = {}
-- Estado agrupado en una tabla (Lua limita las variables locales por bloque)
local St = {
    Seen = setmetatable({}, { __mode = "k" }), Last = {},
    ReadyAt = os.clock() + 5, -- ignora lo que ya existia al cargar el script
    PhaseUntil = 0, LastLight = 0,
    Cur = 0, SpeedCap = 0, GlideScale = 1, Penalty = 0, LastSnap = 0, LastNote = 0, Snaps = 0,
    BoostT = 0, BoostKind = "", LastAttr = 0, LastPrompt = 0, GlideCd = 0,
    PromptOrig = setmetatable({}, { __mode = "k" }),
    BadgeSound = "rbxassetid://10469938989", -- sonido de badge/logro de DOORS
}

local function AssetUrl(v)
    v = tostring(v or ""):gsub("%s", "")
    if v == "" then return nil end
    if v:match("^%d+$") then return "rbxassetid://" .. v end
    return v
end

local function NotifyUI(title, content)
    pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = 2 }) end)
end

----------------------------------------------------
-- TOASTS (estilo logro de DOORS)
----------------------------------------------------
local function PlayToastSound()
    if not Ex.NotifySound then return end
    local s = Instance.new("Sound")
    s.SoundId = AssetUrl(Ex.NotifySoundId) or St.BadgeSound
    s.Volume = Ex.NotifyVolume / 100
    s.Parent = SoundService
    s:Play()
    Debris:AddItem(s, 8)
end

-- Clona la interfaz real de logros del juego (MainUI.AchievementsHolder.Achievement)
-- y reproduce la misma animacion que usa DOORS al desbloquear un badge:
--   1) el contenedor crece (Quad In, 0.8s)   2) la tarjeta entra desde la derecha (0.5s) mientras el brillo se desvanece (0.75s)
--   3) se queda en pantalla   4) la tarjeta sale (0.5s)   5) el contenedor se cierra (Quad InOut, 0.5s)
-- El encabezado ("Achievement Unlocked") no se toca, para que sea identico al original.
-- Si no existe o tiene otra estructura, devuelve false y se usa el toast propio.
local function NativeToast(title, desc, reason)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("MainUI")
    local holder = main and main:FindFirstChild("AchievementsHolder")
    local template = holder and holder:FindFirstChild("Achievement")
    if not template then return false end
    -- si la interfaz de logros del juego esta oculta/desactivada, el aviso no se veria: se usa el propio
    local okv, vis = pcall(function() return main.Enabled ~= false and holder.Visible ~= false end)
    if okv and not vis then return false end

    local a = template:Clone()
    local frame = a:FindFirstChild("Frame")
    local titleLabel = a:FindFirstChild("Title", true)
    if not frame or not titleLabel or not titleLabel:IsA("TextLabel") then
        a:Destroy()
        return false
    end

    a.Name = "R4NS0M_Alert"
    titleLabel.Text = title
    local d = a:FindFirstChild("Desc", true)
    if d and d:IsA("TextLabel") then d.Text = desc or "" end
    local r = a:FindFirstChild("Reason", true)
    if r and r:IsA("TextLabel") then r.Text = reason or "" end

    local icon = AssetUrl(Ex.NotifyIconId)
    local img = frame:FindFirstChild("ImageLabel")
    if icon and img and img:IsA("ImageLabel") then img.Image = icon end

    local glow = frame:FindFirstChild("Glow", true)
    local snd = a:FindFirstChildWhichIsA("Sound", true)
    if snd then
        snd.SoundId = AssetUrl(Ex.NotifySoundId) or St.BadgeSound
        snd.Volume = Ex.NotifySound and (Ex.NotifyVolume / 100) or 0
    end

    local target = template.Size
    if target.Y.Scale <= 0 then target = UDim2.new(1, 0, 0.2, 0) end

    a.Visible = true
    a.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(1.1, 0, 0, 0)
    a.Parent = holder

    -- El sonido suena al instante, igual que en el juego
    if Ex.NotifySound then
        if snd then pcall(function() snd:Play() end) else PlayToastSound() end
    end

    TweenService:Create(a, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = target }):Play()
    task.spawn(function()
        task.wait(0.8)
        if not a.Parent then return end
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 0, 0) }):Play()
        if glow and glow:IsA("ImageLabel") then
            TweenService:Create(glow, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
        end
        task.wait(Ex.NotifyDuration)
        if not a.Parent then return end
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(1.1, 0, 0, 0) }):Play()
        task.wait(0.5)
        if not a.Parent then return end
        TweenService:Create(a, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Size = UDim2.new(1, 0, -0.1, 0) }):Play()
        task.wait(0.5)
        a:Destroy()
    end)
    return true
end

local function GetToastHost()
    if St.Host and St.Host.Parent then return St.Host end
    local f = Instance.new("Frame")
    f.Name = "R4NS0M_Toasts"
    f.BackgroundTransparency = 1
    f.AnchorPoint = Vector2.new(1, 0)
    f.Position = UDim2.new(1, -12, 0, 64)
    f.Size = UDim2.fromOffset(300, 420)
    f.Parent = Gui
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    l.Parent = f
    St.Host = f
    return f
end

local function CustomToast(title, desc, accent)
    accent = accent or Color3.fromRGB(255, 0, 0)
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.ClipsDescendants = true
    wrap.Size = UDim2.fromOffset(300, 66)
    wrap.LayoutOrder = -math.floor(os.clock() * 100)
    wrap.Parent = GetToastHost()

    local card = Instance.new("Frame")
    card.Size = UDim2.fromScale(1, 1)
    card.Position = UDim2.fromOffset(320, 0)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.Parent = wrap
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = card
    local cs = Instance.new("UIStroke"); cs.Thickness = 2; cs.Color = accent; cs.Parent = card

    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.fromOffset(48, 48)
    iconBox.Position = UDim2.fromOffset(9, 9)
    iconBox.BackgroundColor3 = accent
    iconBox.BackgroundTransparency = 0.75
    iconBox.BorderSizePixel = 0
    iconBox.Parent = card
    local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 8); ic.Parent = iconBox

    local iconId = AssetUrl(Ex.NotifyIconId)
    if iconId then
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.Size = UDim2.fromScale(1, 1)
        img.Image = iconId
        img.Parent = iconBox
    else
        local bang = Instance.new("TextLabel")
        bang.BackgroundTransparency = 1
        bang.Size = UDim2.fromScale(1, 1)
        bang.Text = "!"
        bang.TextColor3 = accent
        bang.Font = Enum.Font.GothamBold
        bang.TextSize = 30
        bang.Parent = iconBox
    end

    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position = UDim2.fromOffset(66, 8)
    t.Size = UDim2.new(1, -76, 0, 22)
    t.Text = title
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 17
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextTruncate = Enum.TextTruncate.AtEnd
    t.Parent = card

    local dsc = Instance.new("TextLabel")
    dsc.BackgroundTransparency = 1
    dsc.Position = UDim2.fromOffset(66, 31)
    dsc.Size = UDim2.new(1, -76, 0, 28)
    dsc.Text = desc or ""
    dsc.TextColor3 = Color3.fromRGB(190, 190, 190)
    dsc.Font = Enum.Font.Gotham
    dsc.TextSize = 13
    dsc.TextWrapped = true
    dsc.TextXAlignment = Enum.TextXAlignment.Left
    dsc.TextYAlignment = Enum.TextYAlignment.Top
    dsc.Parent = card

    PlayToastSound()
    TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }):Play()
    task.delay(Ex.NotifyDuration + 0.45, function()
        if not wrap.Parent then return end
        TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(320, 0) }):Play()
        task.wait(0.45)
        wrap:Destroy()
    end)
end

function FX.ShowToast(title, desc, reason, accent)
    if Ex.NotifyStyle == "Doors Achievement" then
        local ok, shown = pcall(NativeToast, title, desc, reason)
        if ok and shown then return end
    end
    pcall(CustomToast, title, desc, accent)
end

local function ShowEntityToast(label)
    local tip = ""
    if Ex.NotifyTips then tip = ENTITY_TIPS[label] or "Be careful!" end
    FX.ShowToast(label .. " has appeared!", tip, "Mode: " .. Mode.Name, Cfg.Categories.entities.Color)
end

-- Llamado desde Register() cuando aparece una entidad conocida (o Dupe)

OnEntitySeen = function(label, inst)
    if not Ex.Notify or os.clock() < St.ReadyAt then return end
    if St.Seen[inst] then return end
    St.Seen[inst] = true
    if not Ex.NotifyFilter[label] then return end
    local now = os.clock()
    local cd = Ex.NotifyCooldown
    if label:find("Glitch", 1, true) then cd = math.max(cd, 20) end
    if St.Last[label] and now - St.Last[label] < cd then return end
    St.Last[label] = now
    ShowEntityToast(label)
end

-- Detector independiente del ESP: avisa aunque el ESP este apagado o el modelo aun no tenga partes.
-- (Mandrake se omite: lo gestiona el ESP, que solo lo marca cuando se mueve y te ataca.)
Workspace.ChildAdded:Connect(function(m)
    if not m:IsA("Model") or Players:GetPlayerFromCharacter(m) then return end
    local ok, label = pcall(EntityLabel, m.Name, false)
    if ok and label and label ~= "Mandrake" then pcall(OnEntitySeen, label, m) end
end)
	
print("[R4NS0M] Loaded Alerts")
print("[R4NS0M] Loading Player Tab")
----------------------------------------------------
-- Estado del personaje
----------------------------------------------------
local function GetParts()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then return char, hum, root end
    return nil
end

local Hooks = {}
local NoclipParts = {}
local Saved = {}

local function RestoreCollide()
    for p, v in pairs(NoclipParts) do
        if p.Parent then p.CanCollide = v end
        NoclipParts[p] = nil
    end
end

local function Apply(id, v)
    Ex[id] = v
    local h = Hooks[id]
    if h then pcall(h, v) end
    if FX.UpdateButtons then FX.UpdateButtons() end
end

-- Desde teclas/botones: cambia el estado y tambien el switch de la interfaz
local function SetFeature(id, v)
    Apply(id, v)
    if Setters[id] then Setters[id](v) end
end

local function Flip(id, label)
    SetFeature(id, not Ex[id])
    NotifyUI(label, Ex[id] and "Enabled" or "Disabled")
end

Hooks.Speed = function(v)
    local _, hum = GetParts()
    St.Cur = 0
    if not hum then return end
    if v then
        Saved.WS = Saved.WS or hum.WalkSpeed
    elseif Saved.WS then
        if St.WSTouched then hum.WalkSpeed = Saved.WS end
        St.WSTouched, Saved.WS = nil, nil
    end
end

Hooks.SpeedHack = function(v)
    local _, hum = GetParts()
    if not hum then return end
    if v then
        Saved.HackWS = Saved.HackWS or hum.WalkSpeed
    elseif Saved.HackWS then
        hum.WalkSpeed = Saved.HackWS
        Saved.HackWS = nil
    end
end

-- Activa/restaura los atributos propios del juego ("CanJump", "CanSlide"...) para que el salto y el slide
-- nativos de DOORS funcionen. Busca cualquier atributo booleano del personaje/jugador con ese nombre.
function FX.GameAbility(kind, on)
    local char = LocalPlayer.Character
    if not char then return end
    St.Attr = St.Attr or {}
    local main = "Can" .. (kind == "jump" and "Jump" or "Slide")
    local targets = { [main] = (LocalPlayer:GetAttribute(main) ~= nil) and LocalPlayer or char }
    for _, holder in ipairs({ char, LocalPlayer }) do
        for name, val in pairs(holder:GetAttributes()) do
            local l = name:lower()
            if type(val) == "boolean" and l:find(kind, 1, true)
                and (l:find("can", 1, true) or l:find("enable", 1, true) or l:find("allow", 1, true)) then
                targets[name] = holder
            end
        end
    end
    for name, holder in pairs(targets) do
        local id = holder.Name .. ":" .. name
        if on then
            if St.Attr[id] == nil then St.Attr[id] = { holder, holder:GetAttribute(name) } end
            if holder:GetAttribute(name) ~= true then holder:SetAttribute(name, true) end
        elseif St.Attr[id] then
            local saved = St.Attr[id]
            pcall(function() saved[1]:SetAttribute(name, saved[2]) end)
            St.Attr[id] = nil
        end
    end
end

Hooks.Jump = function(v)
    FX.GameAbility("jump", v)
    local _, hum = GetParts()
    if not hum then return end
    if v then
        if Saved.JumpPower == nil then
            Saved.JumpPower, Saved.UseJP = hum.JumpPower, hum.UseJumpPower
        end
    elseif Saved.JumpPower ~= nil then
        hum.UseJumpPower = Saved.UseJP
        hum.JumpPower = Saved.JumpPower
        Saved.JumpPower, Saved.UseJP = nil, nil
    end
end

Hooks.Slide = function(v)
    FX.GameAbility("slide", v)
    if not v and FX.StopSlide then FX.StopSlide() end
end

print("[R4NS0M] Loaded Player Tab")
print("[R4NS0M] Loading Automation")
-- Instant Proximity Prompt: HoldDuration = 0 en todos los prompts (y los que aparezcan despues)
function FX.MakeInstant(pp)
    if not pp:IsA("ProximityPrompt") then return end
    if St.PromptOrig[pp] == nil then St.PromptOrig[pp] = pp.HoldDuration end
    pp.HoldDuration = 0
end

Hooks.InstantPrompt = function(v)
    if v then
        task.spawn(function()
            local n = 0
            for _, d in ipairs(Workspace:GetDescendants()) do
                if not Ex.InstantPrompt then return end
                if d:IsA("ProximityPrompt") then pcall(FX.MakeInstant, d) end
                n = n + 1
                if n % 400 == 0 then task.wait() end
            end
        end)
        if not St.PromptConn then
            St.PromptConn = Workspace.DescendantAdded:Connect(function(d)
                if Ex.InstantPrompt and d:IsA("ProximityPrompt") then task.defer(pcall, FX.MakeInstant, d) end
            end)
        end
    else
        if St.PromptConn then St.PromptConn:Disconnect(); St.PromptConn = nil end
        for pp, orig in pairs(St.PromptOrig) do
            if pp.Parent then pp.HoldDuration = orig end
            St.PromptOrig[pp] = nil
        end
    end
end

Hooks.Fly = function(v)
    local _, hum, root = GetParts()
    if not hum then return end
    hum.PlatformStand = v and true or false
    if not v then root.AssemblyLinearVelocity = Vector3.zero end
end

Hooks.Noclip = function(v)
    if not v and not Ex.ACM then RestoreCollide() end
end

Hooks.ACM = function(v)
    if not v and not Ex.Noclip then RestoreCollide() end
end

Hooks.Fullbright = function(v)
    if v then
        if not St.Light then
            St.Light = {
                Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
    elseif St.Light then
        for k, val in pairs(St.Light) do pcall(function() Lighting[k] = val end) end
        St.Light = nil
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    NoclipParts, Saved = {}, {}
    St.PhaseUntil, St.LastSafe, St.Glide, St.LastFlat, St.Attr, St.Cur, St.WSTouched = 0, nil, nil, nil, nil, 0, nil
    if FX.StopSlide then pcall(FX.StopSlide) end
end)

print("[R4NS0M] Loaded Automation")
print("[R4NS0M] Loading Anticheat Tab")
----------------------------------------------------
-- Slide
----------------------------------------------------
local Slide = { t0 = 0, dur = 0.7, dir = nil, cd = 0 }

function FX.StopSlide()
    Slide.dir = nil
    if Slide.LV then pcall(function() Slide.LV:Destroy() end); Slide.LV = nil end
    if Slide.Att then pcall(function() Slide.Att:Destroy() end); Slide.Att = nil end
    local _, hum = GetParts()
    if hum then hum.CameraOffset = Vector3.zero end
end

local function DoSlide()
    if not Ex.Slide then
        NotifyUI("Slide", "Turn on Slide in the Player tab first.")
        return
    end
    local _, hum, root = GetParts()
    if not hum then return end
    local now = os.clock()
    if now < Slide.cd then return end
    local md = hum.MoveDirection
    local look = root.CFrame.LookVector
    local dir
    if md.Magnitude > 0.05 then
        dir = Vector3.new(md.X, 0, md.Z).Unit
    else
        dir = Vector3.new(look.X, 0, look.Z).Unit
    end
    FX.StopSlide()
    Slide.dir, Slide.t0, Slide.cd = dir, now, now + Slide.dur + 0.4
    St.BoostT, St.BoostKind = now, "slide"
    -- Un LinearVelocity vence al controlador del Humanoid (mover la velocidad a mano se quedaba corto)
    pcall(function()
        local att = Instance.new("Attachment")
        att.Name = "R4_SlideAtt"
        att.Parent = root
        Slide.Att = att
        local lv = Instance.new("LinearVelocity")
        lv.Name = "R4_Slide"
        lv.Attachment0 = att
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
        lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
        lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
        lv.ForceLimitsEnabled = false
        lv.PlaneVelocity = Vector2.new(dir.X * Ex.SlideSpeed * St.GlideScale, dir.Z * Ex.SlideSpeed * St.GlideScale)
        lv.Parent = root
        Slide.LV = lv
    end)
end

----------------------------------------------------
-- Motor de movimiento
----------------------------------------------------
local RayP = RaycastParams.new()
RayP.FilterType = Enum.RaycastFilterType.Exclude
RayP.RespectCanCollide = true
local OverP = OverlapParams.new()
OverP.FilterType = Enum.RaycastFilterType.Exclude
OverP.RespectCanCollide = true

-- Speed Boost: sube la velocidad con rampa suave y respeta el limite aprendido del servidor
function FX.Speed(hum, root, dt, now)
    local base
    if Ex.SpeedMethod == "WalkSpeed" then
        if Saved.WS == nil then Saved.WS = hum.WalkSpeed end
        base = Saved.WS
    else
        if St.WSTouched and Saved.WS then hum.WalkSpeed = Saved.WS; St.WSTouched = nil end
        base = hum.WalkSpeed
    end
    local target = Ex.SpeedValue
    local md = hum.MoveDirection
    if md.Magnitude < 0.05 or target <= base then
        St.Cur = base
        if Ex.SpeedMethod == "WalkSpeed" and St.WSTouched then hum.WalkSpeed = base end
        return
    end
    St.Cur = math.min(target, math.max(St.Cur, base) + 45 * dt) -- rampa: nada de saltos bruscos
    St.BoostT, St.BoostKind = now, "speed"
    local f = Vector3.new(md.X, 0, md.Z).Unit
    if Ex.SpeedMethod == "WalkSpeed" then
        hum.WalkSpeed, St.WSTouched = St.Cur, true
    elseif Ex.SpeedMethod == "CFrame" then
        root.CFrame = root.CFrame + f * ((St.Cur - base) * dt)
    else
        local v = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(f.X * St.Cur, v.Y, f.Z * St.Cur)
    end
end

-- Anticheat Manipulator: ahora es el Velocity Manipulation (vive en el bloque ANTI CHEAT BYPASS,
-- lee Ex.ACM y Ex.VelocityManipulationMode). El antiguo Phase Walk se elimino.

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local want = Ex.Noclip
    if want then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                if NoclipParts[p] == nil then NoclipParts[p] = p.CanCollide end
                p.CanCollide = false
            end
        end
    elseif next(NoclipParts) then
        RestoreCollide()
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local now = os.clock()

    -- Fullbright (el juego cambia la iluminacion por cuarto, asi que se reaplica)
    if Ex.Fullbright and now - St.LastLight > 0.2 then
        St.LastLight = now
        pcall(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        end)
    end

    -- Instant Proximity Prompt: algunos prompts recuperan su tiempo de espera, asi que se reaplica
    if Ex.InstantPrompt and now - St.LastPrompt > 0.5 then
        St.LastPrompt = now
        for pp in pairs(St.PromptOrig) do
            if pp.Parent and pp.HoldDuration ~= 0 then pp.HoldDuration = 0 end
        end
    end

    local char, hum, root = GetParts()
    if not char then return end

    -- Ultima posicion segura (para Void Guard)
    if hum.FloorMaterial ~= Enum.Material.Air then St.LastSafe = root.CFrame end
    if Ex.VoidGuard and St.LastSafe and (Ex.Noclip or Ex.ACM or Ex.Fly)
        and root.Position.Y < St.LastSafe.Position.Y - 60 then
        root.CFrame = St.LastSafe + Vector3.new(0, 3, 0)
        root.AssemblyLinearVelocity = Vector3.zero
    end

    -- Speed
    if Ex.Speed and not Ex.Fly and not Slide.dir and not St.Glide then
        FX.Speed(hum, root, dt, now)
    end

    -- Speed Hack: cambia el WalkSpeed de verdad (1-100); se reaplica cada frame
    if Ex.SpeedHack and not Ex.Fly then
        local want = Ex.SpeedHackValue
        if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
    end

    -- Jump (atributos del juego + valores del Humanoid)
    if Ex.Jump then
        if now - St.LastAttr > 0.25 then
            St.LastAttr = now
            pcall(FX.GameAbility, "jump", true)
        end
        pcall(function()
            hum.UseJumpPower = true
            hum.JumpPower = Ex.JumpPower
            hum.JumpHeight = Ex.JumpPower ^ 2 / (2 * Workspace.Gravity)
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end)
    end
    if Ex.Slide and now - St.LastAttr > 0.25 then
        St.LastAttr = now
        pcall(FX.GameAbility, "slide", true)
    end

    -- Slide
    if Slide.dir then
        local a = (now - Slide.t0) / Slide.dur
        local blockedAhead = false
        if not (Ex.Noclip or Ex.ACM) then
            RayP.FilterDescendantsInstances = { char }
            local hit = Workspace:Raycast(root.Position, Slide.dir * 2.6, RayP)
            blockedAhead = hit ~= nil and math.abs(hit.Normal.Y) < 0.6
        end
        if a >= 1 or blockedAhead then
            FX.StopSlide()
        else
            local sp = Ex.SlideSpeed * St.GlideScale * (1 - a) ^ 1.5
            St.BoostT, St.BoostKind = now, "slide"
            if Slide.LV and Slide.LV.Parent then
                Slide.LV.PlaneVelocity = Vector2.new(Slide.dir.X * sp, Slide.dir.Z * sp)
            else
                local v = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(Slide.dir.X * sp, v.Y, Slide.dir.Z * sp)
            end
            hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.new(0, -1.4, 0), math.min(1, dt * 14))
        end
    end

    -- Fly
    if Ex.Fly then
        local cam = Workspace.CurrentCamera
        local md = hum.MoveDirection
        local vert = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then vert = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = -1 end
        if vert == 0 and IS_MOBILE and cam and md.Magnitude > 0.05 then
            local pitch = cam.CFrame.LookVector.Y
            if math.abs(pitch) > 0.15 then vert = math.clamp(pitch * 1.5, -1, 1) end
        end
        root.AssemblyLinearVelocity = Vector3.new(md.X * Ex.FlySpeed, vert * Ex.FlySpeed, md.Z * Ex.FlySpeed)
        St.BoostT, St.BoostKind = now, "fly"
    end

end)

UserInputService.JumpRequest:Connect(function()
    local _, hum = GetParts()
    if not hum then return end
    if Ex.InfJump then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    elseif Ex.Jump and hum.FloorMaterial ~= Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping) -- salto aunque el juego lo haya bloqueado
    end
end)

print("[R4NS0M] Loaded Anticheat Tab")
print("[R4NS0M] Loading PC Keybinds")
----------------------------------------------------
-- Teclas (PC)
----------------------------------------------------
FX.HubOpen = true
FX.ToggleHub = function()
    local ok = false
    if type(Window.Toggle) == "function" then
        ok = pcall(function() Window:Toggle() end)
    end
    if not ok then
        if FX.HubOpen then
            ok = pcall(function() Window:Close() end)
        else
            ok = pcall(function() Window:Open() end)
        end
    end
    if ok then FX.HubOpen = not FX.HubOpen end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode.Name
    if k == Ex.Key_Hub then
        -- pequeno retraso: si la tecla se estaba reasignando en la pestana Keybinds, no se abre/cierra
        local pressed = os.clock()
        task.delay(0.08, function()
            if (FX.LastKeySet or 0) >= pressed - 0.05 then return end
            FX.ToggleHub()
        end)
    elseif k == Ex.Key_ACM then Flip("ACM", "Anticheat Manipulator")
    elseif k == Ex.Key_Noclip then Flip("Noclip", "Noclip")
    elseif k == Ex.Key_Fly then Flip("Fly", "Fly")
    elseif k == Ex.Key_Speed then Flip("Speed", "Speed")
    elseif k == Ex.Key_SpeedHack then Flip("SpeedHack", "Speed Hack")
    elseif k == Ex.Key_Slide then DoSlide()
    elseif k == Ex.Key_PosSpoof then Flip("PositionSpoof", "Position Spoof") end
end)

print("[R4NS0M] Loaded PC Keybinds")
print("[R4NS0M] Loading Mobile Floating Buttons")
----------------------------------------------------
-- Botones flotantes (movil): ACM, Slide y Fly. Se pueden arrastrar.
----------------------------------------------------
local Floating = {}
local function MakeFloat(text, y, onTap, getOn, flag)
    local b = Instance.new("TextButton")
    b.Name = "R4NS0M_Float_" .. text
    b.Size = UDim2.fromOffset(46, 46)
    b.Position = UDim2.new(1, -66, 0.5, y)
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    b.BackgroundTransparency = 0.2
    b.AutoButtonColor = false
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Visible = false
    b.ZIndex = 50
    b.Parent = Gui
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = b
    local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = Color3.fromRGB(120, 120, 120); st.Parent = b

    local dragging, moved = false, false
    local startPt, startPos = Vector2.zero, Vector2.zero
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, moved = true, false
            startPt = Vector2.new(input.Position.X, input.Position.Y)
            startPos = b.AbsolutePosition
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = Vector2.new(input.Position.X, input.Position.Y) - startPt
            if d.Magnitude > 10 then moved = true end
            if moved then b.Position = UDim2.fromOffset(startPos.X + d.X, startPos.Y + d.Y) end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = false
            if not moved then pcall(onTap) end
        end
    end)
    Floating[#Floating + 1] = { Btn = b, Stroke = st, GetOn = getOn, Flag = flag }
end

MakeFloat("ACM", -70, function() Flip("ACM", "Anticheat Manipulator") end, function() return Ex.ACM end, "BtnACM")
MakeFloat("FLY", 38, function() Flip("Fly", "Fly") end, function() return Ex.Fly end, "BtnFly")
MakeFloat("SPD", 146, function() Flip("SpeedHack", "Speed Hack") end, function() return Ex.SpeedHack end, "BtnSpeedHack")

function FX.UpdateButtons()
    for _, f in ipairs(Floating) do
        f.Btn.Visible = Ex.FloatButtons and (f.Flag == nil or Ex[f.Flag] ~= false)
        local on = f.GetOn and f.GetOn() or false
        f.Stroke.Color = on and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(120, 120, 120)
    end
end

print("[R4NS0M] Loaded Mobile Floating Buttons")
print("[R4NS0M] Loading Extra UI Helpers")
----------------------------------------------------
-- UI helpers extra
----------------------------------------------------
local KEY_CHOICES = { "RightShift", "RightControl", "Insert", "Home", "X", "N", "G", "B", "Z", "V", "H", "J", "K", "L", "R", "T", "Y", "U", "M", "C", "F", "Q" }

local function AddKeybind(tab, id, title, desc, default)
    local function set(v)
        local name = typeof(v) == "EnumItem" and v.Name or tostring(v)
        local ok = pcall(function() return Enum.KeyCode[name] end)
        if ok then Ex[id] = name end
        FX.LastKeySet = os.clock() -- para no abrir/cerrar el hub al reasignar una tecla
    end
    local el
    local ok = pcall(function()
        el = tab:Keybind({ Title = title, Desc = desc, Value = default, Callback = set })
    end)
    if ok and el then
        Setters[id] = function(v) pcall(function() el:Set(v) end) end
    else
        local dd = tab:Dropdown({ Title = title, Desc = desc, Values = KEY_CHOICES, Value = default, Callback = set })
        Setters[id] = function(v) pcall(function() dd:Select(v) end) end
    end
end

local function AddInput(tab, id, title, desc, placeholder, value)
    local el = tab:Input({
        Title = title, Desc = desc, Placeholder = placeholder, Value = value,
        Callback = function(t) Ex[id] = tostring(t or "") end
    })
    Setters[id] = function(v) pcall(function() el:Set(v) end) end
end

print("[R4NS0M] Loaded Extra UI Helpers")
print("[R4NS0M] Loading Alerts Tab")
----------------------------------------------------
-- ALERTS TAB: Entity Notifier
----------------------------------------------------
local function NotifyList()
    local list = {}
    for _, n in ipairs(CurrentEntityList()) do list[#list + 1] = n end
    if Active.dupe then list[#list + 1] = "Dupe" end
    return list
end

local function NotifySelected()
    local out = {}
    for _, n in ipairs(NotifyList()) do
        if Ex.NotifyFilter[n] then out[#out + 1] = n end
    end
    return out
end

AlertsTab:Section({ Title = "Entity Notifier" })
AddToggle(AlertsTab, "Notify", "Entity Notifier",
    "Shows a DOORS achievement-style popup with a sound when one of the selected entities appears, for example \"Rush has appeared!\". It works even if ESP Entities is off.",
    Ex.Notify, function(v) Ex.Notify = v end)

local NotifyDD = AlertsTab:Dropdown({
    Title = "Notify me about",
    Desc = "Only the entities of the detected mode are listed. Harmless or low-value ones (Timothy, Snare, Bob, Jeff...) start unchecked, but you can turn them on.",
    Values = NotifyList(),
    Value = NotifySelected(),
    Multi = true,
    AllowNone = true,
    Callback = function(selected)
        local set = {}
        for _, n in ipairs(selected or {}) do set[n] = true end
        for _, n in ipairs(NotifyList()) do Ex.NotifyFilter[n] = set[n] == true end
    end
})
Setters.NotifyFilter = function(list) pcall(function() NotifyDD:Select(list) end) end

function FX.RefreshNotify()
    pcall(function() NotifyDD:Refresh(NotifyList()) end)
    Setters.NotifyFilter(NotifySelected())
end

AlertsTab:Button({
    Title = "Select Recommended",
    Desc = "Checks only the dangerous entities of this mode.",
    Callback = function()
        for _, n in ipairs(NotifyList()) do Ex.NotifyFilter[n] = not NOT_WORTH[n] end
        Setters.NotifyFilter(NotifySelected())
    end
})
AlertsTab:Button({
    Title = "Select All",
    Desc = "Notify about every entity of this mode.",
    Callback = function()
        for _, n in ipairs(NotifyList()) do Ex.NotifyFilter[n] = true end
        Setters.NotifyFilter(NotifySelected())
    end
})
AlertsTab:Button({
    Title = "Clear All",
    Desc = "Uncheck every entity.",
    Callback = function()
        for _, n in ipairs(NotifyList()) do Ex.NotifyFilter[n] = false end
        Setters.NotifyFilter({})
    end
})

AlertsTab:Section({ Title = "Notification Settings" })
AddDropdown(AlertsTab, "NotifyStyle", "Notification Style",
    "Doors Achievement clones the game's own badge popup with the same animation and the badge sound. Custom Toast draws a simple popup if the game's one is missing.",
    { "Doors Achievement", "Custom Toast" }, Ex.NotifyStyle, function(v) Ex.NotifyStyle = v end)
AddToggle(AlertsTab, "NotifySound", "Play Sound", "Plays a sound with every notification.", Ex.NotifySound, function(v) Ex.NotifySound = v end)
AddSlider(AlertsTab, "NotifyVolume", "Volume (%)", "Loudness of the notification sound.", 0, 100, Ex.NotifyVolume, function(v) Ex.NotifyVolume = v end)
AddSlider(AlertsTab, "NotifyDuration", "Duration (seconds)", "How long the popup stays on screen.", 2, 12, Ex.NotifyDuration, function(v) Ex.NotifyDuration = v end)
AddSlider(AlertsTab, "NotifyCooldown", "Cooldown per Entity (seconds)", "Avoids spam when the same entity appears several times in a row (glitched entities, Ambush returns...).", 0, 30, Ex.NotifyCooldown, function(v) Ex.NotifyCooldown = v end)
AddToggle(AlertsTab, "NotifyTips", "Show Tips", "Adds a short survival tip under the message (Hide in a closet, Do not look at it...).", Ex.NotifyTips, function(v) Ex.NotifyTips = v end)
AddInput(AlertsTab, "NotifySoundId", "Custom Sound ID (optional)", "Roblox audio asset ID to use instead of the default sound. Leave empty for the default.", "e.g. 1234567890", Ex.NotifySoundId)
AddInput(AlertsTab, "NotifyIconId", "Custom Icon ID (optional)", "Roblox image asset ID shown in the popup. Leave empty for the default icon.", "e.g. 1234567890", Ex.NotifyIconId)
AlertsTab:Button({
    Title = "Test Notification",
    Desc = "Shows a sample \"Rush has appeared!\" popup using your current settings.",
    Callback = function() ShowEntityToast("Rush") end
})

local prevApplied = OnModeApplied
OnModeApplied = function()
    if prevApplied then prevApplied() end
    FX.RefreshNotify()
end

print("[R4NS0M] Loaded Alerts Tab")
----------------------------------------------------
-- PLAYER TAB
----------------------------------------------------
PlayerTab:Section({ Title = "Speed" })
AddToggle(PlayerTab, "Speed", "Speed Boost", "Makes you faster than normal (up to 90).", Ex.Speed, function(v) Apply("Speed", v) end)
AddSlider(PlayerTab, "SpeedValue", "Speed", "Target speed in studs per second. Doors' normal walk speed is about 16.", 4, 100, Ex.SpeedValue, function(v) Ex.SpeedValue = v end)
AddDropdown(PlayerTab, "SpeedMethod", "Speed Method",
    "Velocity (recommended): smooth push that the server tolerates best. CFrame: small position steps. WalkSpeed: changes the value directly (easiest to detect).",
    { "Velocity", "CFrame", "WalkSpeed" }, Ex.SpeedMethod, function(v) Ex.SpeedMethod = v end)
AddToggle(PlayerTab, "SpeedHack", "Speed Hack", "Changes your real walk speed (1-100). Works together with the Anticheat Bypass.", Ex.SpeedHack, function(v) Apply("SpeedHack", v) end)
AddSlider(PlayerTab, "SpeedHackValue", "Speed Hack Value", "Walk speed in studs per second.", 1, 100, Ex.SpeedHackValue, function(v) Ex.SpeedHackValue = v end)

PlayerTab:Section({ Title = "Jump" })
AddToggle(PlayerTab, "Jump", "Enable Jump", "Turns on the game's own jump and lets you set its power, also in places where the game disables it.", Ex.Jump, function(v) Apply("Jump", v) end)
AddSlider(PlayerTab, "JumpPower", "Jump Power", "How high you jump.", 20, 120, Ex.JumpPower, function(v) Ex.JumpPower = v end)
AddToggle(PlayerTab, "InfJump", "Infinite Jump", "Jump again in mid-air every time you press jump.", Ex.InfJump, function(v) Ex.InfJump = v end)

PlayerTab:Section({ Title = "Slide" })
AddToggle(PlayerTab, "Slide", "Enable Slide", "Turns on the game's own slide and adds a forward slide with a lowered camera. It stops at walls. Keybind on PC, SLIDE button on mobile.", Ex.Slide, function(v) Apply("Slide", v) end)
AddSlider(PlayerTab, "SlideSpeed", "Slide Speed", "Starting speed of the slide. It fades out smoothly.", 30, 90, Ex.SlideSpeed, function(v) Ex.SlideSpeed = v end)

PlayerTab:Section({ Title = "Fly & Noclip" })
AddToggle(PlayerTab, "Fly", "Fly", "Fly freely. PC: Space goes up, Left Ctrl goes down. Mobile: look up or down while moving.", Ex.Fly, function(v) Apply("Fly", v) end)
AddSlider(PlayerTab, "FlySpeed", "Fly Speed", "Flight speed in studs per second.", 10, 90, Ex.FlySpeed, function(v) Ex.FlySpeed = v end)
AddToggle(PlayerTab, "Noclip", "Noclip", "Walk through walls and objects. Simple version: for the careful one, use the Anticheat Manipulator.", Ex.Noclip, function(v) Apply("Noclip", v) end)

PlayerTab:Section({ Title = "Lighting" })
AddToggle(PlayerTab, "Fullbright", "Fullbright", "Removes darkness and fog so you can see everything.", Ex.Fullbright, function(v) Apply("Fullbright", v) end)

print("[R4NS0M] Loaded Player Tab")
print("[R4NS0M] Loading Automation Tab")
----------------------------------------------------
-- AUTOMATION TAB
----------------------------------------------------
AutomationTab:Section({ Title = "Interaction" })
AddToggle(AutomationTab, "InstantPrompt", "Instant Proximity Prompt",
    "Removes the hold time of every interaction prompt (doors, drawers, levers, items...). Turning it off restores the original times.",
    Ex.InstantPrompt, function(v) Apply("InstantPrompt", v) end)

print("[R4NS0M] Loaded Automation Tab")
print("[R4NS0M] Loading Anticheat Tab")
----------------------------------------------------
-- ANTI CHEAT TAB: Anticheat Manipulator
----------------------------------------------------
AntiCheatTab:Section({ Title = "Anticheat Manipulator" })
AntiCheatTab:Paragraph({
    Title = "What it does",
    Desc = "The Anticheat Manipulator now uses Velocity Manipulation: it moves your character forward very slowly (or pivots it relative to the camera), "
        .. "which mitigates the game's anti-noclip so you can walk through walls and doors. There is no guarantee: the server may still flag you, so use it at your own risk."
})
AddToggle(AntiCheatTab, "ACM", "Anticheat Manipulator", "Main switch. PC: keybind (Keybinds tab). Mobile: the ACM floating button.", Ex.ACM, function(v) Apply("ACM", v) end)
AddDropdown(AntiCheatTab, "VelocityManipulationMode", "Manipulation Method",
    "Velocity: a tiny forward push (recommended). Pivot: moves the character relative to the camera.",
    { "Velocity", "Pivot" }, Ex.VelocityManipulationMode, function(v) Ex.VelocityManipulationMode = v end)
AddToggle(AntiCheatTab, "VoidGuard", "Void Guard", "If you fall far below your last safe spot while phasing, noclipping or flying, you are sent back to that spot.", Ex.VoidGuard, function(v) Ex.VoidGuard = v end)

-- ============================================================================================
-- ANTI CHEAT BYPASS
-- Ladder method (Climbing), Velocity Manipulation, Position Spoof, Crouch Spoof, __namecall hook,
-- collision clone, plus the Bypass / Remove / No Damage / Floor bypass toggles.
-- Todo vive dentro de una funcion propia para no gastar variables locales del script.
-- ============================================================================================
;(function()
local Env = {
	hookmetamethod = hookmetamethod, newcclosure = newcclosure, getnamecallmethod = getnamecallmethod,
	firetouchinterest = firetouchinterest, isnetworkowner = isnetworkowner, cloneref = cloneref,
}

local function CloneReference(Object)
	if Env.cloneref then
		return Env.cloneref(Object)
	end
	return Object
end

local Services = setmetatable({}, {
	__index = function(Self, Name)
		return CloneReference(game:GetService(Name))
	end
})

local Globals = {}
local Connections = {}
local Functions = {}
local Objects = { Entities = {}, SeekObstructions = {}, SeekBridges = {}, Obstructions = {} }

-- Toggles / Options leen directamente el estado del hub (Ex)
local ValueAliases = { NoclipToggle = "Noclip", VelocityManipulationToggle = "ACM" } -- Velocity Manipulation = Anticheat Manipulator
local function MakeProxy()
	return setmetatable({}, {
		__index = function(_, Key)
			local Real = ValueAliases[Key] or Key
			return setmetatable({}, {
				__index = function(_, Field)
					if Field == "Value" then return Ex[Real] end
				end
			})
		end
	})
end
local Toggles = MakeProxy()
local Options = MakeProxy()

Functions.CheckCompatability = function(Array)
	for _, Name in Array do
		if not Env[Name] then
			return false
		end
	end
	return true
end

Functions.Notify = function(Data)
	NotifyUI(Data.Title or "", Data.Body or "")
end

local LocalPlayer = Services.Players.LocalPlayer
local Character, Humanoid, RootPart, Camera
local Collision, CollisionClone, CollisionPart, CollisionPartClone
local RemotesFolder = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
local CurrentRooms = Services.Workspace:FindFirstChild("CurrentRooms")
local Floor = "Hotel"
local Ready = false
local FakeEvents = {}
local Modules = {}

Globals.AnticheatDisabled = false
Globals.SpoofOffset = 0
Globals.LastCrouchFire = tick()

local EntityDistances = {
	["RushMoving"]    = 85,
	["AmbushMoving"]  = 150,
	["A60"]           = 125,
	["A120"]          = 85,
	["GlitchRush"]    = 90,
	["GlitchAmbush"]  = 175,
	["BackdoorRush"]  = 85,
	["CustomEntity"]  = 85,
}

Functions.IsCrouching = function()
	if Floor == "Fools" or Floor == "OldHotel" then
		return Character:GetAttribute("Crouching")
	end
	return CollisionPart.CollisionGroup == "PlayerCrouching"
end

Functions.GetNearestEntity = function(CheckDisabled, List, UseRaycasting)
	local Nearest = { Distance = math.huge, Object = nil }

	for _, Entity in Services.Workspace:GetChildren() do
		if Entity and EntityDistances[Entity.Name] and Entity.PrimaryPart then
			local Distance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position)
			if Distance < EntityDistances[Entity.Name] and Distance < Nearest.Distance then
				if not CheckDisabled or Entity:GetAttribute("Inactive") ~= true then
					Nearest.Distance = Distance
					Nearest.Object = Entity
				end
			end
		end
	end
	return Nearest.Object
end

Functions.GetNearestFigure = function()
	local Nearest = { Distance = math.huge, Object = nil }
	local FigureNames = { FigureRig = true, FigureRagdoll = true, Figure = true }

	for _, Object in Objects.Entities do
		if Object:IsA("Model") and Object.PrimaryPart and FigureNames[Object.Name] then
			local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
			if Distance < Nearest.Distance and Distance < 25 then
				Nearest.Distance = Distance
				Nearest.Object = Object
			end
		end
	end
	return Nearest.Object
end

print("[R4NS0M] Loaded Anticheat Tab")
print("[R4NS0M] Loading Anti Functions")
-- ============================================================================================
-- __namecall hook (Crouch, Heartbeat minigame, MotorReplication)
-- ============================================================================================
local MainHook
if Functions.CheckCompatability({"hookmetamethod", "newcclosure", "getnamecallmethod"}) then
	MainHook = Env.hookmetamethod(game, "__namecall", Env.newcclosure(function(Self, ...)
		local Args = { ... }
		local ArgCount = select("#", ...)
		local Method = Env.getnamecallmethod()

		if Self.Name == "Crouch" and Method == "FireServer" then
			if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then
				Args[1] = true
			end
			Args[2] = true
		end

		if Self.Name == "ClutchHeartbeat" and Method == "FireServer" and Toggles.AutoHeartbeatMinigame.Value or Self.Name == "HideMonster" and Method == "FireServer" and Toggles.AutoHeartbeatMinigame.Value then
			return
		end

		if Self.Name == "MotorReplication" and Method == "FireServer" then
			local DoBypass = (Toggles.BypassEyes.Value and Globals.IsEyes) or (Toggles.BypassLookman.Value and Globals.IsLookman)
			if DoBypass then
				if Floor == "Fools" or Floor == "OldHotel" then
					Args[1] = 0 Args[2] = (Globals.SpoofOffset == 200 and 65 or -65) Args[3] = 0 Args[4] = false
					ArgCount = math.max(ArgCount, 4)
				else
					Args[1] = -650
					ArgCount = math.max(ArgCount, 1)
				end
			end
		end

		return MainHook(Self, table.unpack(Args, 1, ArgCount))
	end))
end

-- ============================================================================================
-- Hooks de los toggles (se llaman desde Apply cuando cambia el valor)
-- ============================================================================================
Hooks.DisableAnticheat = function(Value)
	if Globals.AnticheatDisabled == true and not Value then
		if RemotesFolder and RemotesFolder:FindFirstChild("ClimbLadder") then
			RemotesFolder.ClimbLadder:FireServer()
		end
		Globals.AnticheatDisabled = false
	end
end

Hooks.PositionSpoof = function(Value)
	if not (RootPart and Humanoid and RemotesFolder) then return end
	if Floor ~= "Fools" and Floor ~= "OldHotel" then
		if Value then
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
			Humanoid.HipHeight = 0.05
			RemotesFolder.Crouch:FireServer(true, true)
		else
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 2.346, 0)
			Humanoid.HipHeight = 2.396
		end
	end
end

Hooks.CrouchSpoof = function(Value)
	if RemotesFolder and RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end

Hooks.BypassGiggle = function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "GiggleCeiling" then
			Object:WaitForChild("Hitbox").CanTouch = not Value
		end
	end
end
Hooks.BypassDupe = function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "DoorFake" or Object.Name == "FakeDoor" then
			Object:WaitForChild("Hidden").CanTouch = not Value
			if Object:FindFirstChild("Lock") then
				Object.Lock.UnlockPrompt.Enabled = not Value
			end
		end
	end
end
Hooks.BypassEyes = function(Value)
	if Value and Globals.IsEyes and RemotesFolder then
		if Floor == "Fools" or Floor == "OldHotel" then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end
Hooks.BypassLookman = function(Value)
	if Value and Globals.IsLookman and RemotesFolder then
		if Floor == "Fools" or Floor == "OldHotel" then
			RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
		else
			RemotesFolder.MotorReplication:FireServer(-650)
		end
	end
end
Hooks.BypassGloombatEggs = function(Value)
	for _, Object in Objects.Entities do
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Value
			end
		end
	end
end
Hooks.BypassSeekObstructions = function(Value)
	for _, Object in Objects.SeekObstructions do
		Object.CanTouch = not Value
		if Object.Name == "SeekFloodline" then
			Object.CanCollide = Value
		end
	end
	for _, Object in Objects.SeekBridges do
		Object.CanCollide = Value
		Object.Transparency = Value and 0 or 1
	end
end
Hooks.BypassVacuum = function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "SideroomSpace" then
			Object:WaitForChild("Collision").CanCollide = Value
			Object:WaitForChild("Collision").CanTouch = not Value
		end
	end
end
Hooks.BypassKillbricks = function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == "Lava" then Object.CanTouch = not Value end
	end
end
Hooks.BypassSeekingWall = function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == "ScaryWall" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanTouch = not Value
					Part.CanCollide = not Value
				end
			end
		end
	end
end
Hooks.BypassSnare = function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "Snare" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = not Value end
			end
		end
	end
end
Hooks.BypassBanana = function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "BananaPeel" then Object.CanTouch = not Value end
	end
end
Hooks.BypassJeff = function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "JeffTheKiller" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanCollide = not Value
					Part.CanTouch = not Value
				end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	end
end

-- Remove / No Damage
Hooks.NoScreechDamage = function(Value)
	if not (FakeEvents.Screech and FakeEvents.Screech_Real and RemotesFolder) then return end
	if Value then
		FakeEvents.Screech.Parent = RemotesFolder
		FakeEvents.Screech_Real.Parent = nil
	else
		FakeEvents.Screech_Real.Parent = RemotesFolder
		FakeEvents.Screech.Parent = nil
	end
end
Hooks.NoHaltDamage = function(Value)
	if not (FakeEvents.Shade and FakeEvents.Shade_Real and RemotesFolder) then return end
	if Value then
		FakeEvents.Shade.Parent = RemotesFolder
		FakeEvents.Shade_Real.Parent = nil
	else
		FakeEvents.Shade_Real.Parent = RemotesFolder
		FakeEvents.Shade.Parent = nil
	end
end
Hooks.NoA90Damage = function(Value)
	if RemotesFolder and RemotesFolder:FindFirstChild("A90") and FakeEvents.A90 and FakeEvents.A90_Real then
		if Value then
			FakeEvents.A90.Parent = RemotesFolder
			FakeEvents.A90_Real.Parent = nil
		else
			FakeEvents.A90_Real.Parent = RemotesFolder
			FakeEvents.A90.Parent = nil
		end
	end
end
Hooks.NoSurgeDamage = function(Value)
	if RemotesFolder and RemotesFolder:FindFirstChild("SurgeRemote") and FakeEvents.Surge and FakeEvents.Surge_Real then
		if Value then
			FakeEvents.Surge.Parent = RemotesFolder
			FakeEvents.Surge_Real.Parent = nil
		else
			FakeEvents.Surge_Real.Parent = RemotesFolder
			FakeEvents.Surge.Parent = nil
		end
	end
end

-- FIX Remove Screech: antes Modules.Screech solo se buscaba UNA vez al aparecer el personaje; si MainUI/Initiator todavia
-- no existia (o el modulo se cargaba despues) quedaba en nil y el toggle no hacia nada. Ahora el modulo se busca al
-- activar el toggle (con reintentos), se vigila si aparece mas tarde, y ademas se elimina cualquier Screech que ya este vivo.
local function FindClientModule(Name)
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	local mu = pg and pg:FindFirstChild("MainUI")
	local ini = mu and mu:FindFirstChild("Initiator")
	local mg = ini and ini:FindFirstChild("Main_Game")
	local rl = mg and mg:FindFirstChild("RemoteListener")
	local mods = rl and rl:FindFirstChild("Modules")
	if not mods then return nil end
	return mods:FindFirstChild(Name) or mods:FindFirstChild(Name .. "_Disabled")
end

local function KillLiveScreech()
	-- Screech vivo (Workspace / Camera) + efectos de GlitchScreech que ya existan
	for _, Parent in { Services.Workspace, Services.Workspace.CurrentCamera } do
		if Parent then
			for _, Obj in Parent:GetChildren() do
				local L = Obj.Name:lower()
				if (L == "screech" or L == "glitchscreech" or L:find("scjvereech", 1, true)) and Obj ~= LocalPlayer.Character then
					pcall(function() Obj:Destroy() end)
				end
			end
		end
	end
end

Functions.ApplyRemoveScreech = function()
	local Value = Ex.RemoveScreech
	if not (Modules.GlitchScreech and Modules.GlitchScreech.Parent) then
		local FR = Services.ReplicatedStorage:FindFirstChild("FloorReplicated")
		if FR then
			for _, D in FR:GetDescendants() do
				if D.Name == "GlitchScreech" or D.Name == "GlitchScreech_Disabled" then Modules.GlitchScreech = D break end
			end
		end
	end
	local M = FindClientModule("Screech")
	if M then
		Modules.Screech = M
		M.Name = Value and "Screech_Disabled" or "Screech"
	end
	local GS = Modules.GlitchScreech
	if GS and GS.Parent then
		GS.Name = Value and "GlitchScreech_Disabled" or "GlitchScreech"
	end
	if Value then pcall(KillLiveScreech) end
end

Hooks.RemoveScreech = function(Value)
	Functions.ApplyRemoveScreech()
	if not Value then return end
	-- reintentos por si MainUI todavia no cargo (pasa justo al entrar a la partida)
	task.spawn(function()
		for _ = 1, 40 do
			if not Ex.RemoveScreech then return end
			if FindClientModule("Screech") then
				Functions.ApplyRemoveScreech()
				break
			end
			task.wait(0.5)
		end
	end)
end

-- mientras Remove Screech este activo: se re-aplica y se limpia cada 0.5s (el juego puede volver a crear el modulo/modelo)
task.spawn(function()
	while true do
		task.wait(0.5)
		if Ex.RemoveScreech then
			pcall(Functions.ApplyRemoveScreech)
		end
	end
end)
Hooks.RemoveHalt = function(Value)
	if Modules.Shade then
		Modules.Shade.Name = Value and "Shade_Disabled" or "Shade"
	end
end
Hooks.RemoveA90 = function(Value)
	if Modules.A90 then
		Modules.A90.Name = Value and "A90_Disabled" or "A90"
	end
end
Hooks.RemoveDread = function(Value)
	if Modules.Dread then
		Modules.Dread.Name = Value and "Dread_Disabled" or "Dread"
	end
end
Hooks.RemoveSurge = function(Value)
	if Globals.SurgeFrame then
		Globals.SurgeFrame.Name = (Value and "SurgeVignette_Disabled" or "SurgeVignette")
	end
end

-- Floor bypass: Basement Gate / Paintings Door / Skeleton Door
-- FIX: antes SOLO se detectaban en Fools / OldHotel (en cualquier otro modo el objeto nunca se registraba y el
-- toggle fallaba con un PivotTo(nil)). Ahora se detectan por nombre en TODOS los modos, se guarda su posicion
-- original al verlos, se mueven lejos Y se les quita colision/toque, y mientras el toggle siga activo se re-aplica.
local ObstructionNames = { ThingToOpen = "RemoveBasementGate", MovingDoor = "RemovePaintingsDoor", Wax_Door = "RemoveSkeletonDoor" }
Functions.SetObstructionRemoved = function(Object, Value)
	if not Object or not Object.Parent then return end
	if Object:GetAttribute("OriginalPosition") == nil then
		local ok, Pivot = pcall(function() return Object:GetPivot() end)
		if ok then Object:SetAttribute("OriginalPosition", Pivot) end
	end
	local Original = Object:GetAttribute("OriginalPosition")
	if Value then
		-- ya esta lejos: no repetir
		local ok, Cur = pcall(function() return Object:GetPivot().Position end)
		if ok and Cur.Y > -9000 then
			pcall(function() Object:PivotTo(CFrame.new(-10000, -10000, -10000)) end)
		end
		local Parts = Object:IsA("BasePart") and { Object } or Object:GetDescendants()
		for _, Part in Parts do
			if Part:IsA("BasePart") then
				if Part:GetAttribute("OrigCollide") == nil then
					Part:SetAttribute("OrigCollide", Part.CanCollide)
					Part:SetAttribute("OrigTouch", Part.CanTouch)
				end
				Part.CanCollide = false
				Part.CanTouch = false
			end
		end
	else
		if typeof(Original) == "CFrame" then
			pcall(function() Object:PivotTo(Original) end)
		end
		local Parts = Object:IsA("BasePart") and { Object } or Object:GetDescendants()
		for _, Part in Parts do
			if Part:IsA("BasePart") and Part:GetAttribute("OrigCollide") ~= nil then
				Part.CanCollide = Part:GetAttribute("OrigCollide")
				Part.CanTouch = Part:GetAttribute("OrigTouch")
				Part:SetAttribute("OrigCollide", nil)
				Part:SetAttribute("OrigTouch", nil)
			end
		end
	end
end

for ObjName, ToggleName in ObstructionNames do
	Hooks[ToggleName] = function(Value)
		-- por si el objeto aun no se habia registrado: se busca de nuevo en todo el Workspace
		for _, Object in Services.Workspace:GetDescendants() do
			if Object.Name == ObjName and (Object:IsA("Model") or Object:IsA("BasePart")) and not table.find(Objects.Obstructions, Object) then
				table.insert(Objects.Obstructions, Object)
			end
		end
		for _, Object in Objects.Obstructions do
			if Object.Name == ObjName then
				pcall(Functions.SetObstructionRemoved, Object, Value)
			end
		end
	end
end

-- re-aplicacion periodica (el juego mueve estas puertas con tweens/animaciones y a veces las devuelve)
task.spawn(function()
	while true do
		task.wait(0.4)
		for ObjName, ToggleName in ObstructionNames do
			if Ex[ToggleName] then
				for _, Object in Objects.Obstructions do
					if Object.Name == ObjName and Object.Parent then
						pcall(Functions.SetObstructionRemoved, Object, true)
					end
				end
			end
		end
	end
end)

-- ============================================================================================
-- Objetos del mapa (Lava, Snare, Giggle, Dupe, Seek, Jeff, Figure, puertas...)
-- ============================================================================================
Functions.HandleObject = function(Object)
	local Name = Object.Name

	if Name == "Lava" then
		if Toggles.BypassKillbricks.Value then Object.CanTouch = false end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ScaryWall" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekingWall.Value
				Part.CanCollide = not Toggles.BypassSeekingWall.Value

				local Connection1 = Part:GetPropertyChangedSignal("CanTouch"):Connect(function()
					if Part.CanTouch == Toggles.BypassSeekingWall.Value then
						Part.CanTouch = not Toggles.BypassSeekingWall.Value
					end
				end)
				local Connection2 = Part:GetPropertyChangedSignal("CanCollide"):Connect(function()
					if Part.CanCollide == Toggles.BypassSeekingWall.Value then
						Part.CanCollide = not Toggles.BypassSeekingWall.Value
					end
				end)

				table.insert(Connections, Connection1)
				table.insert(Connections, Connection2)
			end
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "GiggleCeiling" then
		if Toggles.BypassGiggle.Value then Object:WaitForChild("Hitbox").CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "GloomPile" then
		if Toggles.BypassGloombatEggs.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = false
				end
			end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = false end
		end)

		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)
	elseif Name == "TriggerEventCollision" and Functions.CheckCompatability({"firetouchinterest"}) then
		if (Floor == "Fools" or Floor == "OldHotel") and Toggles.RemoveSeekTrigger.Value then
			task.spawn(function()
				while Object:IsDescendantOf(game) do
					for _, Part in Object:GetChildren() do
						if Part:IsA("BasePart") then
							Env.firetouchinterest(RootPart, Part, 0)
							task.wait()
							Env.firetouchinterest(RootPart, Part, 1)
						end
					end
					task.wait()
				end
			end)
		end
	elseif Name == "DoorFake" or Name == "FakeDoor" then
		if Object.Parent and Object:FindFirstChild("Hidden") then
			if Toggles.BypassDupe.Value then
				Object:WaitForChild("Hidden").CanTouch = false
				local Lock = Object:FindFirstChild("Lock")
				if Lock and Lock:FindFirstChild("UnlockPrompt") then Lock.UnlockPrompt.Enabled = false end
			end
			table.insert(Objects.Entities, Object)
		end
	elseif Name == "SideroomSpace" then
		if Toggles.BypassVacuum.Value then
			Object:WaitForChild("Collision").CanCollide = true
			Object:WaitForChild("Collision").CanTouch = false
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Snare" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end)
		table.insert(Connections, Connection)
		table.insert(Objects.Entities, Object)
	elseif Name == "Seek_Arm" or Name == "ChandelierObstruction" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekObstructions.Value
				table.insert(Objects.SeekObstructions, Part)
			end
		end
	elseif Name == "SeekFloodline" then
		Object.CanCollide = Toggles.BypassSeekObstructions.Value
		local FloodConn = Object:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if Object.CanCollide ~= Toggles.BypassSeekObstructions.Value then
				Object.CanCollide = Toggles.BypassSeekObstructions.Value
			end
		end)
		Object.Destroying:Once(function() FloodConn:Disconnect() end)
		table.insert(Objects.SeekObstructions, Object)
	elseif Name == "Bridge" then
		for _, Child in Object:GetChildren() do
			if Child.Name == "PlayerBarrier" and Child.Size.Y == 2.75 and (Child.Rotation.X == 0 or Child.Rotation.X == 180) then
				local NewBridge = Child:Clone()
				NewBridge.CFrame = NewBridge.CFrame * CFrame.new(0, 0, -5)
				NewBridge.Name = tostring(math.random(100000, 999999))
				NewBridge.Size = Vector3.new(NewBridge.Size.X, NewBridge.Size.Y, 11)
				NewBridge.Parent = Object
				NewBridge.CanCollide = Toggles.BypassSeekObstructions.Value
				NewBridge.Color = Color3.fromRGB(0, 255, 255)
				NewBridge.Transparency = Toggles.BypassSeekObstructions.Value and 0 or 1
				NewBridge.Material = Enum.Material.ForceField
				table.insert(Objects.SeekBridges, NewBridge)
			end
			task.wait()
		end
	elseif Object:GetAttribute("RawName") and Object:GetAttribute("RawName"):find("Halt") or Object:GetAttribute("Shade") == true then
		local HaltLogConn
		HaltLogConn = Services.LogService.MessageOut:Connect(function(Message)
			if Message == "client teleporting" then
				if Globals.AnticheatDisabled then
					Globals.AnticheatDisabled = false
					Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
				end
				HaltLogConn:Disconnect()
			end
		end)
	elseif Name == "BananaPeel" then
		if Toggles.BypassBanana.Value then Object.CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "JeffTheKiller" then
		if Toggles.BypassJeff.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanCollide = false Part.CanTouch = false end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	elseif Name == "Figure" or Name == "FigureRig" or Name == "FigureRagdoll" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = false
			end
		end
		table.insert(Objects.Entities, Object)
		if Toggles.RemoveFigure.Value and Functions.CheckCompatability({"isnetworkowner"}) then
			if Floor == "Mines" then
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						task.spawn(function()
							if Env.isnetworkowner(Part) then
								Part.Position = Vector3.new(-49999, -49999, -49999)
							end
						end)
					end
				end
			elseif Floor == "OldHotel" or Floor == "Fools" then
				CurrentRooms.ChildAdded:Wait()
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						Part.CanCollide = false
						task.spawn(function()
							while Env.isnetworkowner(Part) do
								Part.Position = Vector3.new(math.random(-29999,29999), math.random(-29999,29999), math.random(-29999,29999))
								task.wait()
							end
						end)
					end
				end
			end
		end
	elseif ObstructionNames[Name] and (Object:IsA("Model") or Object:IsA("BasePart")) then
		-- Gate / Paintings Door / Skeleton Door: en TODOS los modos (ya no solo Fools / OldHotel)
		if not table.find(Objects.Obstructions, Object) then
			pcall(function() Object:SetAttribute("OriginalPosition", Object:GetPivot()) end)
			table.insert(Objects.Obstructions, Object)
		end
		if Ex[ObstructionNames[Name]] then
			Functions.SetObstructionRemoved(Object, true)
		end
	end
end

Globals.ObjectQueue = {}
local AllowedInstances = {
	Lava = true, JeffTheKiller = true, Snare = true, FakeDoor = true, DoorFake = true, SideroomSpace = true,
	FigureRig = true, FigureRagdoll = true, Figure = true, Seek_Arm = true, ChandelierObstruction = true, ScaryWall = true,
	TriggerEventCollision = true, GiggleCeiling = true, GloomPile = true, SeekFloodline = true, Bridge = true,
	BananaPeel = true, Wax_Door = true, ThingToOpen = true, MovingDoor = true,
}
Functions.QueueObject = function(Object)
	if not AllowedInstances[Object.Name] and not (Object:GetAttribute("RawName") and Object:GetAttribute("RawName"):find("Halt")) and Object:GetAttribute("Shade") ~= true then
		return
	end
	table.insert(Globals.ObjectQueue, Object)
end

-- ============================================================================================
-- Personaje: collision clone, ladder disabler, spoofs, velocity manipulation
-- ============================================================================================
local CharacterOldConnectionKeys = {
	"MainHandler", "SHMFixer", "AnticheatDisabler", "AnticheatEnableDetector1", "AnticheatEnableDetector2", "AutoReviveHandler",
}

Functions.HandleCharacter = function(NewCharacter)
	for _, Key in CharacterOldConnectionKeys do
		if Connections[Key] then
			Connections[Key]:Disconnect()
			Connections[Key] = nil
		end
	end

	local NewHumanoid = NewCharacter:WaitForChild("Humanoid", 15)
	local NewCollision = NewCharacter:WaitForChild("Collision", 15)
	if not NewHumanoid or not NewCollision or not NewCharacter:FindFirstChild("HumanoidRootPart") then return end

	Character = NewCharacter
	Humanoid = NewHumanoid
	RootPart = NewCharacter:FindFirstChild("HumanoidRootPart")
	Camera   = Services.Workspace.CurrentCamera

	Collision = NewCollision
	CollisionPart  = NewCharacter:FindFirstChild("CollisionPart") or NewCharacter:FindFirstChild("Collision")
	CollisionClone = Collision:Clone()
	CollisionClone.Parent = NewCharacter
	CollisionClone.Name = "CollisionClone"
	CollisionClone.Massless = true

	CollisionPartClone = CollisionPart:Clone()
	CollisionPartClone.Parent = NewCharacter
	CollisionPartClone.Name = "CollisionPartClone"
	CollisionPartClone.CanCollide = false
	CollisionPartClone.Massless = true

	if CollisionPartClone:FindFirstChild("CollisionCrouch") then
		CollisionPartClone.CollisionCrouch:Destroy()
	end

	Connections.AutoReviveHandler = LocalPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
		if LocalPlayer:GetAttribute("Alive") == false and Toggles.AutoRevive.Value then
			if Floor == "Fools" or Floor == "OldHotel" then
				while LocalPlayer:GetAttribute("Alive") ~= true do
					RemotesFolder.Revive:FireServer()
					task.wait(0.5)
				end
			end
		end
	end)

	Connections.SHMFixer = RootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		task.wait()
		if Floor == "Fools" and RootPart.Anchored and Character:GetAttribute("Hiding") ~= true then
			RootPart.Anchored = false
		end
	end)

	Globals.AnticheatDisabled = false

	Connections.AnticheatDisabler = Character:GetAttributeChangedSignal("Climbing"):Connect(function()
		if Character:GetAttribute("Climbing") == true and Toggles.DisableAnticheat.Value and not Globals.AnticheatDisabled then
			task.wait(0.25)
			Character:SetAttribute("Climbing", false)
			Functions.Notify({ Title = "Successfully disabled the anticheat.", Body = "It will be re-enabled after a cutscene or halt room." })
			Globals.AnticheatDisabled = true
		end
	end)

	local CutsceneRemote = RemotesFolder and RemotesFolder:WaitForChild("Cutscene", 10)
	if CutsceneRemote then
		Connections.AnticheatEnableDetector1 = CutsceneRemote.OnClientEvent:Connect(function(CutsceneName)
			if Globals.AnticheatDisabled and not CutsceneName:find("SewerSeek") then
				Globals.AnticheatDisabled = false
				Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
			end
		end)
	end

	local EnemyRemote = RemotesFolder and RemotesFolder:WaitForChild("UseEnemyModule", 10)
	if EnemyRemote then
		Connections.AnticheatEnableDetector2 = EnemyRemote.OnClientEvent:Connect(function(ModuleName)
			if ModuleName == "Void" or ModuleName == "Glitch" then
				if Globals.AnticheatDisabled then
					Globals.AnticheatDisabled = false
					Functions.Notify({ Title = "The anticheat has been re-enabled.", Body = "Interact with a ladder to disable it again." })
				end
				local LatestRoom = Services.ReplicatedStorage:FindFirstChild("GameData") and Services.ReplicatedStorage.GameData:FindFirstChild("LatestRoom")
				if LatestRoom then LocalPlayer:SetAttribute("CurrentRoom", LatestRoom.Value) end
			end
		end)
	end

	Globals.ManipulateBody = Instance.new("BodyVelocity")
	Globals.ManipulateBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Globals.LastCrouchFire = tick()
	Globals.OriginalC1 = Character.LowerTorso.Root.C1

	local MainUI = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
	local MainFrame = MainUI and MainUI:FindFirstChild("MainFrame")
	if MainFrame and MainFrame:FindFirstChild("SurgeVignette") then
		Globals.SurgeFrame = MainFrame.SurgeVignette
		if Toggles.RemoveSurge.Value then
			Globals.SurgeFrame.Name = "SurgeVignette_Disabled"
		end
	end

	local UIModules = MainUI and MainUI:FindFirstChild("Initiator") and MainUI.Initiator:FindFirstChild("Main_Game")
	UIModules = UIModules and UIModules:FindFirstChild("RemoteListener") and UIModules.RemoteListener:FindFirstChild("Modules")
	if UIModules then
		Modules.A90     = UIModules:FindFirstChild("A90")
		Modules.Screech = UIModules:FindFirstChild("Screech")
		Modules.Dread   = UIModules:FindFirstChild("Dread")
		if Toggles.RemoveScreech.Value and Modules.Screech then Modules.Screech.Name = "Screech_Disabled" end
		if Toggles.RemoveA90.Value and Modules.A90 then Modules.A90.Name = "A90_Disabled" end
		if Toggles.RemoveDread.Value and Modules.Dread then Modules.Dread.Name = "Dread_Disabled" end
	end

	Connections.MainHandler = Services.RunService.RenderStepped:Connect(function()
		if not (Character and Character.Parent and RootPart and RootPart.Parent and Collision and CollisionClone and CollisionPart) then return end

		if Services.Workspace:FindFirstChild("Camera") then
			Camera = Services.Workspace:FindFirstChild("Camera")
		end

		Globals.IsEyes    = Services.Workspace:FindFirstChild("Eyes") ~= nil or Services.Workspace:FindFirstChild("Lookman") ~= nil
		Globals.IsLookman = Services.Workspace:FindFirstChild("BackdoorLookman") ~= nil

		Character:SetAttribute("Sliding", Globals.Sliding)
		if Character:GetAttribute("Crouching") ~= Functions.IsCrouching() then
			Character:SetAttribute("Crouching", Functions.IsCrouching())
		end

		if (Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value) and RemotesFolder:FindFirstChild("Crouch") then
			RemotesFolder.Crouch:FireServer(true, true)
		end

		if Floor ~= "Fools" and Floor ~= "OldHotel" and not Camera:FindFirstChild("MinecartRig") then
			RootPart.CanCollide = false
		end

		for _, Part in Character:GetChildren() do
			if Part:IsA("BasePart") then Part.CanCollide = false end
		end

		if Floor == "OldHotel" or Floor == "Fools" then
			local SpoofOffset = Toggles.PositionSpoof.Value and Functions.GetNearestEntity() and 200 or Toggles.FigureGodmode.Value and Functions.GetNearestFigure() and 200 or 0
			Globals.SpoofOffset = SpoofOffset
			Collision.Position = RootPart.Position + Vector3.new(0, SpoofOffset, 0)
			Collision.CanCollide = false
			if Floor == "Fools" then
				Collision.CollisionCrouch.CanCollide = false
				CollisionClone.CollisionCrouch.CanCollide = false
			end
			RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
		else
			Collision.CanCollide = false
			if Collision:FindFirstChild("CollisionCrouch") then Collision.CollisionCrouch.CanCollide = false end

			if CollisionClone:FindFirstChild("CollisionCrouch") then
				local IsCrouch = Functions.IsCrouching()
				CollisionClone.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or IsCrouch)
				CollisionClone.CollisionCrouch.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value or not IsCrouch)
			else
				RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.VelocityManipulationToggle.Value)
			end

			if Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
				Character.LowerTorso.Root.C1 = Globals.OriginalC1 * CFrame.new(0, Toggles.PositionSpoof.Value and -2.346 or 0, 0)
			end

			local SpoofY = Toggles.PositionSpoof.Value and 2.328 or 0.18
			Collision.Position     = RootPart.Position + Vector3.new(0, SpoofY, 0)
			CollisionPart.Position = RootPart.Position + Vector3.new(0, SpoofY, 0)

			if Collision:FindFirstChild("CollisionCrouch") and CollisionClone:FindFirstChild("CollisionCrouch") then
				local CrouchY = Toggles.PositionSpoof.Value and 1.328 or -0.982
				Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, CrouchY, 0)
				CollisionClone.CollisionCrouch.CollisionGroup = Collision.CollisionCrouch.CollisionGroup
			end
			if CollisionClone:FindFirstChild("CollisionCrouch") then
				CollisionClone.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 0.75 or -0.982, 0)
			end
		end

		CollisionClone.CollisionGroup = Collision.CollisionGroup
		CollisionClone.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 1.75 or 0.18, 0)

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == "Velocity" then
			Globals.ManipulateBody.Parent = RootPart
			Globals.ManipulateBody.Velocity = RootPart.CFrame.LookVector * 2.25
		else
			Globals.ManipulateBody.Parent = nil
		end

		if Toggles.VelocityManipulationToggle.Value and Options.VelocityManipulationMode.Value == "Pivot" and Floor ~= "Fools" and Floor ~= "OldHotel" then
			Character:PivotTo(Camera:GetPivot() * CFrame.new(0, 0, 2560))
		end

		local DoEyesBypass = (Toggles.BypassEyes.Value and Globals.IsEyes) or (Toggles.BypassLookman.Value and Globals.IsLookman)
		if DoEyesBypass then
			if Floor == "Fools" or Floor == "OldHotel" then
				RemotesFolder.MotorReplication:FireServer(0, (Globals.SpoofOffset == 200 and 65 or -65), 0, false)
			else
				RemotesFolder.MotorReplication:FireServer(-650)
			end
		end

		if RemotesFolder:FindFirstChild("Crouch") and tick() - Globals.LastCrouchFire > 0.1 then
			local IsCrouch = Functions.IsCrouching()
			if Toggles.CrouchSpoof.Value or Toggles.PositionSpoof.Value then IsCrouch = true end
			RemotesFolder.Crouch:FireServer(IsCrouch, true)
			Globals.LastCrouchFire = tick()
		end
	end)
end

-- ============================================================================================
-- Inicio: espera al juego, prepara remotes falsos y engancha el personaje
-- ============================================================================================
task.spawn(function()
	local GameData = Services.ReplicatedStorage:WaitForChild("GameData", 20)
	local FloorValue = GameData and GameData:WaitForChild("Floor", 10)
	if not (GameData and FloorValue) then return end
	Floor = FloorValue.Value

	if not RemotesFolder then
		if Services.ReplicatedStorage:FindFirstChild("EntityInfo") then
			RemotesFolder = Services.ReplicatedStorage:FindFirstChild("EntityInfo")
		elseif Services.ReplicatedStorage:FindFirstChild("Bricks") then
			RemotesFolder = Services.ReplicatedStorage:FindFirstChild("Bricks")
		end
	end
	if not RemotesFolder then return end
	if Floor == "Hotel" and RemotesFolder.Name == "Bricks" then
		Floor = "OldHotel"
	end
	CurrentRooms = CurrentRooms or Services.Workspace:WaitForChild("CurrentRooms", 20)

	FakeEvents.Screech = Instance.new("RemoteEvent")
	FakeEvents.Shade   = Instance.new("RemoteEvent")
	FakeEvents.A90     = Instance.new("RemoteEvent")
	FakeEvents.Surge   = Instance.new("RemoteEvent")
	FakeEvents.Screech.Name = "Screech"
	FakeEvents.Shade.Name   = "ShadeResult"
	FakeEvents.A90.Name     = "A90"
	FakeEvents.Surge.Name   = "SurgeRemote"
	FakeEvents.Screech_Real = RemotesFolder:FindFirstChild("Screech")
	FakeEvents.Shade_Real   = RemotesFolder:FindFirstChild("ShadeResult")
	FakeEvents.A90_Real     = RemotesFolder:FindFirstChild("A90")
	FakeEvents.Surge_Real   = RemotesFolder:FindFirstChild("SurgeRemote")

	if RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed") then
		local RealRemote = RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed")
		RealRemote:Destroy()

		local FakeRemote = Instance.new("RemoteEvent", RemotesFolder)
		FakeRemote.Name = "FootstepRemoteThatWeNeed"
	end

	local ClientModules = Services.ReplicatedStorage:FindFirstChild("ModulesClient") or Services.ReplicatedStorage:FindFirstChild("ClientModules")
	if ClientModules and ClientModules:FindFirstChild("EntityModules") then
		Modules.Glitch = ClientModules.EntityModules:FindFirstChild("Glitch")
		Modules.Shade  = ClientModules.EntityModules:FindFirstChild("Shade")
		Modules.Void   = ClientModules.EntityModules:FindFirstChild("Void")
		if Toggles.RemoveHalt.Value and Modules.Shade then Modules.Shade.Name = "Shade_Disabled" end
	end

	local FloorReplicated = Services.ReplicatedStorage:FindFirstChild("FloorReplicated")
	if FloorReplicated then
		Connections.FloorReplicatedHandler = FloorReplicated.DescendantAdded:Connect(function(Object)
			if Object.Name == "GlitchScreech" then
				Modules.GlitchScreech = Object
				if Toggles.RemoveScreech.Value then Object.Name = "GlitchScreech_Disabled" end
			end
		end)
	end

	Connections.QueueConnection = Services.RunService.RenderStepped:Connect(function()
		local Object = table.remove(Globals.ObjectQueue, 1)
		if Object and Object.Parent then
			pcall(Functions.HandleObject, Object)
		end
	end)
	for _, Object in Services.Workspace:GetDescendants() do
		Functions.QueueObject(Object)
	end
	Connections.InstanceHandler = Services.Workspace.DescendantAdded:Connect(function(Object)
		Functions.QueueObject(Object)
	end)

	Ready = true

	if LocalPlayer.Character then
		task.spawn(function() Functions.HandleCharacter(LocalPlayer.Character) end)
	end
	LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
		if Connections.MainHandler then
			Connections.MainHandler:Disconnect()
			Connections.MainHandler = nil
		end
		task.wait(0.5)
		Functions.HandleCharacter(NewCharacter)
	end)
end)

print("[R4NS0M] Loaded Anti Functions")
print("[R4NS0M] Loading Anticheat and Anti UI")
-- ============================================================================================
-- Interfaz: pestaña Anticheat y Antis
-- ============================================================================================
AntiCheatTab:Section({ Title = "Bypass" })
AddToggle(AntiCheatTab, "DisableAnticheat", "Anticheat Bypass",
	"Completely disables the anticheat, after interacting with a ladder. It comes back after a cutscene, a Halt room, Void or Glitch: use a ladder again.",
	Ex.DisableAnticheat, function(v) Apply("DisableAnticheat", v) end)
AddToggle(AntiCheatTab, "PositionSpoof", "Position Spoof",
	"Moves your real position underground while your body stays visible at floor level for other players, so they see you standing normally. Protects you from rush-like entities.",
	Ex.PositionSpoof, function(v) Apply("PositionSpoof", v) end)
AddToggle(AntiCheatTab, "CrouchSpoof", "Crouch Spoof",
	"Makes the game think you are always crouching.",
	Ex.CrouchSpoof, function(v) Apply("CrouchSpoof", v) end)
AddToggle(AntiCheatTab, "AutoHeartbeatMinigame", "Auto Heartbeat Minigame",
	"Prevents the 'Figure' minigame from ever failing.",
	Ex.AutoHeartbeatMinigame, function(v) Ex.AutoHeartbeatMinigame = v end)

AntisTab:Section({ Title = "Bypass" })
for _, B in ipairs({
	{ "BypassGiggle", "Bypass Giggle", "Prevents 'Giggle' from attacking you." },
	{ "BypassDupe", "Bypass Dupe", "Prevents you from open 'Dupe' fake doors." },
	{ "BypassEyes", "Bypass Eyes", "Prevents 'Eyes' from hurting you." },
	{ "BypassLookman", "Bypass Lookman", "Prevents 'Lookman' from hurting you." },
	{ "BypassGloombatEggs", "Bypass Gloombat Eggs", "Prevents taking damage from stepping on 'Gloombat' eggs." },
	{ "BypassSeekObstructions", "Bypass Seek Obstructions", "Prevents obstacles in the 'Seek' chase from harming you." },
	{ "BypassVacuum", "Bypass Vacuum", "Prevents you from falling into 'Vacuum' fake doors." },
	{ "BypassKillbricks", "Bypass Killbricks", "Prevents 'Lava' from hurting you." },
	{ "BypassSeekingWall", "Bypass Seeking Wall", "Prevents 'ScaryWall' from hurting you." },
	{ "BypassSnare", "Bypass Snare", "Prevents 'Snare' from trapping you." },
	{ "BypassBanana", "Bypass Banana", "Prevents 'Banana Peel' from slipping you up (sometimes doesn't work)." },
	{ "BypassJeff", "Bypass Jeff", "Prevents 'Jeff the Killer' from stabbing you (sometimes doesn't work)." },
}) do
	AddToggle(AntisTab, B[1], B[2], B[3], Ex[B[1]], function(v) Apply(B[1], v) end)
end

AntisTab:Section({ Title = "Remove" })
for _, B in ipairs({
	{ "RemoveScreech", "Remove Screech", "Prevents 'Screech' from spawning." },
	{ "RemoveHalt", "Remove Halt", "Prevents 'Halt' from spawning." },
	{ "RemoveA90", "Remove A-90", "Prevents 'A-90' from spawning." },
	{ "RemoveDread", "Remove Dread", "Prevents 'Dread' from spawning." },
	{ "RemoveSurge", "Remove Surge", "Prevents 'Surge' from spawning." },
	{ "NoScreechDamage", "No Screech Damage", "Prevents 'Screech' from hurting you." },
	{ "NoHaltDamage", "No Halt Damage", "Prevents 'Halt' from hurting you." },
	{ "NoA90Damage", "No A-90 Damage", "Prevents 'A-90' from hurting you." },
	{ "NoSurgeDamage", "No Surge Damage", "Prevents 'Surge' from hurting you." },
}) do
	AddToggle(AntisTab, B[1], B[2], B[3], Ex[B[1]], function(v) Apply(B[1], v) end)
end

AntisTab:Section({ Title = "Floor bypass" })
AddToggle(AntisTab, "RemoveSeekTrigger", "Delete Seek Trigger", "Disables the 'Seek' chase trigger (Old Hotel / Fools).", Ex.RemoveSeekTrigger, function(v) Ex.RemoveSeekTrigger = v end)
AddToggle(AntisTab, "RemoveFigure", "Delete Figure", "Completely removes the entity 'Figure' (doesn't always work).", Ex.RemoveFigure, function(v) Ex.RemoveFigure = v end)
AddToggle(AntisTab, "AutoRevive", "Infinite Revives", "Automatically revives after dying, with unlimited respawns (Old Hotel / Fools).", Ex.AutoRevive, function(v) Ex.AutoRevive = v end)
AddToggle(AntisTab, "FigureGodmode", "Figure Godmode", "Prevents 'Figure' from hurting you (Old Hotel / Fools).", Ex.FigureGodmode, function(v) Ex.FigureGodmode = v end)
AddToggle(AntisTab, "RemoveBasementGate", "Remove Basement Gate", "Removes the gate from basement rooms.", Ex.RemoveBasementGate, function(v) Apply("RemoveBasementGate", v) end)
AddToggle(AntisTab, "RemovePaintingsDoor", "Remove Paintings Door", "Removes the fireplace doors from painting rooms.", Ex.RemovePaintingsDoor, function(v) Apply("RemovePaintingsDoor", v) end)
AddToggle(AntisTab, "RemoveSkeletonDoor", "Remove Skeleton Door", "Removes the skeleton door from the infirmary.", Ex.RemoveSkeletonDoor, function(v) Apply("RemoveSkeletonDoor", v) end)
end)()

print("[R4NS0M] Loaded Anticheat and Anti UI")
print("[R4NS0M] Loading Extra Functions")
-- ============================================================================================
-- FUNCIONES EXTRA
--   Automation : Auto Breaker Box, Infinite Items, Auto Interact, Prompt Reach, Prompt Clip
--   Misc       : Disable Idle Kick
--   Antis      : Meld (Stop Growth / Remove sin quitar cuerdas ni puertas)
-- Todo vive en esta funcion para no gastar variables locales del script.
-- ============================================================================================
;(function()
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local Hui = (gethui and gethui()) or game:GetService("CoreGui")

local function RemotesFolder()
	return RS:FindFirstChild("RemotesFolder") or RS:FindFirstChild("EntityInfo") or RS:FindFirstChild("Bricks")
end
local function Rooms() return Workspace:FindFirstChild("CurrentRooms") end
local function Char() return LocalPlayer.Character end
local function HasItem(Name, OnlyCharacter)
	local c = Char()
	if not OnlyCharacter then
		local bp = LocalPlayer:FindFirstChild("Backpack")
		local it = bp and bp:FindFirstChild(Name)
		if it then return it end
	end
	return c and c:FindFirstChild(Name) or nil
end

Ex.AutoBreakerBox = false
Ex.InfiniteItems = false
Ex.InfiniteItemsList = { "Lockpicks", "Skeleton Key", "Shears", "Multitool" }
Ex.AutoInteract = false
Ex.PromptReach = 1
Ex.PromptClip = false
Ex.DisableIdleKick = false
Ex.MeldStopGrowth = false
Ex.MeldRemove = false

local Prompts = setmetatable({}, { __mode = "k" }) -- prompt -> { dist, los }

-- ------------------------------------------------------------------------------------------
-- Prompt Reach / Prompt Clip (guarda los valores originales y los restaura al apagar)
-- ------------------------------------------------------------------------------------------
local function ApplyReach(pp)
	if not pp:IsA("ProximityPrompt") or pp:GetAttribute("FakePrompt") then return end
	local o = Prompts[pp]
	if not o then
		o = { Dist = pp.MaxActivationDistance, LOS = pp.RequiresLineOfSight }
		Prompts[pp] = o
	end
	pp.MaxActivationDistance = o.Dist * Ex.PromptReach
	pp.RequiresLineOfSight = Ex.PromptClip and false or o.LOS
end
local function ReapplyAllReach()
	for pp in pairs(Prompts) do
		if pp.Parent then
			pcall(function()
				local o = Prompts[pp]
				pp.MaxActivationDistance = o.Dist * Ex.PromptReach
				pp.RequiresLineOfSight = Ex.PromptClip and false or o.LOS
			end)
		end
	end
end
-- la primera vez hay que registrar los valores originales de TODOS los prompts existentes
local function ScanReach()
	task.spawn(function()
		local n = 0
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") then pcall(ApplyReach, d) end
			n = n + 1
			if n % 400 == 0 then task.wait() end
		end
		ReapplyAllReach()
	end)
end
Hooks.PromptReach = function() ScanReach() end
Hooks.PromptClip = function() ScanReach() end

-- ------------------------------------------------------------------------------------------
-- Auto Breaker Box (remote EBF)
-- ------------------------------------------------------------------------------------------
local Breaker = { Interacted = false, Notified = false, Hooked = setmetatable({}, { __mode = "k" }) }
local function HookBreaker(obj)
	if Breaker.Hooked[obj] then return end
	Breaker.Hooked[obj] = true
	task.spawn(function()
		local sg = obj:WaitForChild("SurfaceGui", 15)
		local frame = sg and sg:WaitForChild("Frame", 5)
		local code = frame and frame:WaitForChild("Code", 5)
		if not code then return end
		if Ex.AutoBreakerBox and not Breaker.Notified then
			Breaker.Notified = true
			NotifyUI("Auto Breaker Box", "Interact with the breaker box once. It will be solved automatically.")
		end
		code:GetPropertyChangedSignal("Text"):Connect(function()
			if Ex.AutoBreakerBox then
				local rf = RemotesFolder()
				local r = rf and rf:FindFirstChild("EBF")
				if r then pcall(function() r:FireServer() end) end
			end
			Breaker.Interacted = true
		end)
	end)
end
Hooks.AutoBreakerBox = function(v)
	if not v then return end
	local rooms = Rooms()
	local br = rooms and rooms:FindFirstChild("ElevatorBreaker", true)
	if br then
		HookBreaker(br)
		if Breaker.Interacted then
			local rf = RemotesFolder()
			local r = rf and rf:FindFirstChild("EBF")
			if r then pcall(function() r:FireServer() end) end
		else
			NotifyUI("Auto Breaker Box", "Interact with the breaker box once. It will be solved automatically.")
		end
	end
end

-- ------------------------------------------------------------------------------------------
-- Infinite Items (Lockpicks / Skeleton Key / Shears / Multitool): sin gastar usos
-- El prompt de candado real se esconde y se pone uno falso. Al usarlo se suelta el
-- item, y cuando aparece en Drops se vuelve a recoger a la vez que se dispara el prompt real.
-- ------------------------------------------------------------------------------------------
local IF = { Fakes = {}, Real = setmetatable({}, { __mode = "k" }), Container = Instance.new("Folder") }
IF.Container.Name = "R4_PromptContainer"
pcall(function() IF.Container.Parent = Hui end)
local TOOL_DISPLAY = { Lockpick = "Lockpicks", SkeletonKey = "Skeleton Key", Shears = "Shears", Multitool = "Multitool" }
local LOCK_NAMES = { UnlockPrompt = true, SkullPrompt = true, LockPrompt = true, ThingToEnable = true, FusesPrompt = true }

local function IsLockPrompt(p)
	return LOCK_NAMES[p.Name]
		or (p.Parent and p.Parent:GetAttribute("Locked") == true)
		or (p.Parent and p.Parent.Parent and p.Parent.Parent.Name == "Locker_Small_Locked" and p.Name == "ActivateEventPrompt")
end

local function InfListHas(display)
	for _, n in ipairs(Ex.InfiniteItemsList or {}) do
		if n == display then return true end
	end
	return false
end

local function MakeFake(real)
	if IF.Real[real] or real:GetAttribute("FakePrompt") or not IsLockPrompt(real) or not fireproximityprompt then return end
	local parent = real.Parent
	if not parent then return end
	local fake = real:Clone()
	fake:SetAttribute("FakePrompt", true)
	fake.Parent = parent
	IF.Fakes[fake] = real
	IF.Real[real] = fake
	pcall(function() real.Parent = IF.Container end)
	local conn = real:GetPropertyChangedSignal("Enabled"):Connect(function() fake.Enabled = real.Enabled end)
	real:GetPropertyChangedSignal("ActionText"):Once(function() -- el candado cambio de estado: se devuelve el real
		pcall(function() real.Parent = parent end)
		fake:Destroy()
		conn:Disconnect()
		IF.Real[real] = nil
	end)
	real.Destroying:Once(function() fake:Destroy(); conn:Disconnect(); IF.Real[real] = nil end)
	fake.Enabled = real.Enabled
end

local function RemoveFakes()
	for fake, real in pairs(IF.Fakes) do
		pcall(function()
			if real and fake.Parent then real.Parent = fake.Parent end
			fake:Destroy()
		end)
		IF.Fakes[fake] = nil
		if real then IF.Real[real] = nil end
	end
end

Hooks.InfiniteItems = function(v)
	if not fireproximityprompt then
		NotifyUI("Infinite Items", "Your executor has no fireproximityprompt. This feature is disabled.")
		return
	end
	if v then
		task.spawn(function()
			local n = 0
			for _, d in ipairs(Workspace:GetDescendants()) do
				if not Ex.InfiniteItems then return end
				if d:IsA("ProximityPrompt") then pcall(MakeFake, d) end
				n = n + 1
				if n % 400 == 0 then task.wait() end
			end
		end)
	else
		RemoveFakes()
	end
end

PPS.PromptTriggered:Connect(function(Object)
	if not Object:GetAttribute("FakePrompt") then return end
	local real = IF.Fakes[Object]
	if not real then return end
	local char = Char()
	if not char then return end

	local Tool
	for _, N in { "Lockpick", "Shears", "SkeletonKey", "Key", "GeneratorFuse", "KeyElectrical", "KeyBackdoor", "KeyIron", "Multitool" } do
		Tool = char:FindFirstChild(N)
		if Tool then break end
	end
	local Parent = Object.Parent
	local PName = Parent and Parent.Name or ""
	local Lock = IsLockPrompt(Object)

	if Lock then
		local has = false
		for _, K in { "Key", "GeneratorFuse", "KeyBackdoor", "KeyElectrical", "KeyIron", "Lockpick", "SkeletonKey", "Shears", "Multitool" } do
			if HasItem(K, true) then has = true break end
		end
		if not has then
			for _, K in { "Key", "GeneratorFuse", "KeyElectrical", "KeyIron" } do
				if HasItem(K) then has = true break end
			end
		end
		if not has then return end
	end
	local vine = PName == "CuttableVines" or PName == "Chest_Vine" or PName == "Cellar"
	if vine and not HasItem("Shears", true) and not HasItem("Multitool", true) then return end
	if PName == "SkullLock" and not HasItem("SkeletonKey", true) then return end
	if (PName == "Lock1" or PName == "Lock2") and not HasItem("Lockpick", true) and not HasItem("Multitool", true) then return end
	if HasItem("Shears", true) and Lock and not vine then return end

	local AnyTool = char:FindFirstChildOfClass("Tool")
	local display = AnyTool and TOOL_DISPLAY[AnyTool.Name]
	local rf = RemotesFolder()
	local Drops = Workspace:FindFirstChild("Drops")
	if AnyTool and display and Ex.InfiniteItems and InfListHas(display) and rf and rf:FindFirstChild("DropItem") and Drops then
		Drops.ChildAdded:Once(function(NewTool)
			local pickup = NewTool:FindFirstChild("ModulePrompt") or NewTool:WaitForChild("ModulePrompt", 3)
			if pickup then pcall(fireproximityprompt, pickup) end
			pcall(fireproximityprompt, real)
		end)
		rf.DropItem:FireServer(AnyTool)
	else
		pcall(fireproximityprompt, real)
	end
end)

-- ------------------------------------------------------------------------------------------
-- Auto Interact (version ligera): dispara los prompts cercanos
-- ------------------------------------------------------------------------------------------
local AI_BLACKLIST = {
	HidePrompt = true, RiftPrompt = true, StarRiftPrompt = true, InteractPrompt = true, ClimbPrompt = true,
	DonatePrompt = true, DialoguePrompt = true, RevivePrompt = true, EnterPrompt = true, AnimatePrompt = true,
	ToolEventPrompt = true, Prompt = true, PropPrompt = true, UnlockPrompt = true, SkullPrompt = true, LockPrompt = true,
	ThingToEnable = true, FusesPrompt = true, LongPushPrompt = true, BigPropPrompt = true, PushPrompt = true,
}
local AI = { Last = 0, Set = setmetatable({}, { __mode = "k" }), Static = setmetatable({}, { __mode = "k" }) }

-- ------------------------------------------------------------------------------------------
-- Ignorar asientos (sentarse) y cosas de Jeff / innecesarias.
-- La actualizacion nueva cambia el nombre del prompt, asi que no se depende de un nombre exacto:
-- se detecta por clase (Seat/VehicleSeat), por nombre, ActionText/ObjectText y por la cadena de padres.
-- ------------------------------------------------------------------------------------------
local AI_SIT_WORDS = { "sit", "seat", "chair", "sofa", "couch", "bench", "stool", "throne", "armchair", "recliner" }
local AI_JEFF_WORDS = { "jeff", "shop", "purchase", "buy", "vendor", "merchant", "store", "cashier", "sell" }
local AI_JUNK_WORDS = { "donate", "tithe", "dialogue", "talk", "revive", "emote", "dance", "gift" }

local function AIHas(str, list)
	if type(str) ~= "string" or str == "" then return false end
	str = str:lower()
	for _, w in ipairs(list) do
		if str:find(w, 1, true) then return true end
	end
	return false
end

-- "sit" puede aparecer dentro de otras palabras (visit...): se comparan como palabra suelta
local function AIWord(str, list)
	if type(str) ~= "string" or str == "" then return false end
	str = str:gsub("(%l)(%u)", "%1 %2"):gsub("[^%a]+", " "):lower()
	for w in str:gmatch("%a+") do
		for _, k in ipairs(list) do
			if w == k or w == k .. "s" then return true end
		end
	end
	return false
end

local function AIIsSeat(inst)
	return inst:IsA("Seat") or inst:IsA("VehicleSeat")
end

local function AIStaticSkip(pp)
	-- texto del prompt: "Sit", "Sentarse", etc.
	local at, ot = pp.ActionText, pp.ObjectText
	if AIWord(pp.Name, AI_SIT_WORDS) or AIWord(at, AI_SIT_WORDS) or AIWord(ot, AI_SIT_WORDS) then return true end
	if type(at) == "string" and (at:lower():find("sent", 1, true) or at:lower():find("siénta", 1, true)) then return true end
	if AIWord(pp.Name, AI_JEFF_WORDS) or AIWord(at, AI_JEFF_WORDS) or AIWord(ot, AI_JEFF_WORDS) then return true end
	if AIWord(pp.Name, AI_JUNK_WORDS) or AIWord(at, AI_JUNK_WORDS) then return true end

	-- el prompt puede estar en una parte que es un asiento, o junto/dentro de un modelo con asiento
	local par = pp.Parent
	if not par then return false end
	if AIIsSeat(par) then return true end

	-- cadena de padres (hasta 6 niveles): nombre de silla/sofa, atributos de Jeff/tienda, asiento hermano
	local cur, depth = par, 0
	while cur and cur ~= Workspace and depth < 6 do
		if AIIsSeat(cur) then return true end
		local n = cur.Name
		if AIWord(n, AI_SIT_WORDS) or AIWord(n, AI_JEFF_WORDS) then return true end
		if cur:GetAttribute("JeffShop") or cur:GetAttribute("Shop") or cur:GetAttribute("ShopItem") or cur:GetAttribute("Price") or cur:GetAttribute("Cost") then return true end
		-- un asiento directamente dentro de este contenedor (silla = modelo con Seat) -> es prompt de sentarse
		if depth <= 1 and not cur:IsA("Folder") then
			for _, c in ipairs(cur:GetChildren()) do
				if AIIsSeat(c) then return true end
			end
		end
		cur = cur.Parent
		depth = depth + 1
	end
	return false
end

-- Red de seguridad: si por cualquier motivo el personaje termina sentado, se levanta solo
task.spawn(function()
	while true do
		task.wait(0.15)
		if Ex.AutoInteract then
			pcall(function()
				local _, hum = GetParts()
				if hum and hum.Sit and hum.SeatPart and (hum.SeatPart:IsA("Seat") or hum.SeatPart:IsA("VehicleSeat")) then
					hum.Sit = false
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end)
		end
	end
end)

local function AISkip(pp)
	if Ex.AIExtraSkip and Ex.AIExtraSkip(pp) then return true end
	if AI_BLACKLIST[pp.Name] or pp:GetAttribute("FakePrompt") or pp:GetAttribute("AutoInteractIgnore") then return true end
	local par = pp.Parent
	if not par then return true end
	local st = AI.Static[pp]
	if st == nil then
		st = AIStaticSkip(pp) and true or false
		AI.Static[pp] = st
	end
	if st then return true end
	local Drops = Workspace:FindFirstChild("Drops")
	if Drops and pp:IsDescendantOf(Drops) then return true end
	local n = par.Name
	if n == "GlitchCube" or n == "TrackLever" or n == "Padlock" or n == "MinesAnchor" or n == "ElevatorBreaker"
		or n == "KeyObtainFake" or n == "TithingPlate" then return true end
	if par.Parent and (par.Parent.Name == "DoorFake" or par.Parent.Name == "FakeDoor" or par.Parent.Name == "IndustrialGate") then return true end
	if par:GetAttribute("JeffShop") or par:GetAttribute("Locked") == true then return true end
	if pp.Name == "ActivateEventPrompt" and pp.ActionText == "Close" then return true end
	-- no recoger un item que ya tienes (llaves) ni vendas con la vida llena
	if n == "KeyObtain" and (HasItem("Key") or HasItem("KeyBackdoor")) then return true end
	if n == "ElectricalKeyObtain" and HasItem("KeyElectrical") then return true end
	if n == "AlarmClock" and HasItem("AlarmClock") then return true end
	if n == "Bandage" then
		local _, hum = GetParts()
		if hum and hum.Health >= hum.MaxHealth and not HasItem("BandagePack") then return true end
	end
	return false
end

task.spawn(function()
	while true do
		task.wait(0.1)
		if Ex.AutoInteract and fireproximityprompt then
			local _, _, root = GetParts()
			if root then
				local cur = LocalPlayer:GetAttribute("CurrentRoom")
				for pp in pairs(AI.Set) do
					if not pp.Parent then
						AI.Set[pp] = nil
					elseif pp.Enabled and not AISkip(pp) then
						local pr = pp:GetAttribute("ParentRoom")
						if not (pr and cur and tonumber(pr) ~= tonumber(cur)) then
							local par = pp.Parent
							local pos
							if par:IsA("BasePart") then pos = par.Position
							elseif par:IsA("Attachment") then pos = par.WorldPosition
							elseif par:IsA("Model") then pos = par:GetPivot().Position end
							if pos and (pos - root.Position).Magnitude <= pp.MaxActivationDistance then
								pcall(fireproximityprompt, pp)
							end
						end
					end
				end
			end
		end
	end
end)

-- ------------------------------------------------------------------------------------------
-- Avisos de oxigeno / haste, cerrar closet sin espera, sin aceleracion, alcance de puertas, sonidos
-- ------------------------------------------------------------------------------------------
Ex.NotifyOxygen = false
Ex.NotifyHaste = false
Ex.NoClosetDelay = false
Ex.NoAcceleration = false
Ex.DoorReach = false
Ex.NoFootsteps = false
Ex.NoPromptSounds = false

-- Texto flotante simple (se desvanece solo)
local Cap = { Gui = nil, Label = nil, Token = 0 }
local function Caption(text)
	pcall(function()
		if not Cap.Gui or not Cap.Gui.Parent then
			local g = Instance.new("ScreenGui")
			g.Name = "R4_Caption"
			g.ResetOnSpawn = false
			g.IgnoreGuiInset = true
			g.DisplayOrder = 50
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.AnchorPoint = Vector2.new(0.5, 1)
			l.Position = UDim2.new(0.5, 0, 0.82, 0)
			l.Size = UDim2.new(0.6, 0, 0, 34)
			l.Font = Enum.Font.GothamBold
			l.TextSize = 24
			l.TextColor3 = Color3.new(1, 1, 1)
			l.Parent = g
			g.Parent = Hui
			Cap.Gui, Cap.Label = g, l
		end
		Cap.Token = Cap.Token + 1
		local tk = Cap.Token
		Cap.Label.Text = text
		Cap.Label.TextTransparency = 0
		Cap.Label.TextStrokeTransparency = 0.4
		task.delay(2.5, function()
			if Cap.Token == tk and Cap.Label and Cap.Label.Parent then
				TweenService:Create(Cap.Label, TweenInfo.new(1.2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
	end)
end

-- Oxigeno: avisa cada vez que baja
local OxyConn, OxyLast
local function HookOxygen(char)
	if OxyConn then OxyConn:Disconnect(); OxyConn = nil end
	if not char then return end
	OxyLast = char:GetAttribute("Oxygen")
	OxyConn = char:GetAttributeChangedSignal("Oxygen"):Connect(function()
		local n = char:GetAttribute("Oxygen")
		if Ex.NotifyOxygen and type(n) == "number" and type(OxyLast) == "number" and n < OxyLast then
			Caption("Oxygen: " .. (math.floor(n * 10) / 10) .. "%")
		end
		OxyLast = n
	end)
end
HookOxygen(LocalPlayer.Character)
LocalPlayer.CharacterAdded:Connect(HookOxygen)

-- Haste: tiempo restante antes de que aparezca
local HasteTimer, HasteConn
task.spawn(function()
	while true do
		pcall(function()
			local fr = RS:FindFirstChild("FloorReplicated")
			local t = fr and fr:FindFirstChild("DigitalTimer")
			if t and t ~= HasteTimer then
				HasteTimer = t
				if HasteConn then HasteConn:Disconnect() end
				HasteConn = t:GetPropertyChangedSignal("Value"):Connect(function()
					if not Ex.NotifyHaste then return end
					local v = math.max(0, math.floor(tonumber(t.Value) or 0))
					Caption(string.format("%02d:%02d", math.floor(v / 60), v % 60))
				end)
			end
		end)
		task.wait(3)
	end
end)

-- Cerrar closet sin espera
local ClosetLast = 0
RunService.Heartbeat:Connect(function()
	if not Ex.NoClosetDelay then return end
	local now = os.clock()
	if now - ClosetLast < 0.1 then return end
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) then return end
	local cp = char:FindFirstChild("CollisionPart") or char:FindFirstChild("Collision")
	if hum.MoveDirection ~= Vector3.zero
		and ((cp and cp:IsA("BasePart") and cp.Anchored) or root.Anchored)
		and char:GetAttribute("AnimatingClient") ~= true
		and char:GetAttribute("Hiding") == true then
		local rf = RemotesFolder()
		local r = rf and rf:FindFirstChild("CamLock")
		if r then
			ClosetLast = now
			pcall(function() r:FireServer() end)
		end
	end
end)

-- Sin aceleracion: el personaje frena al instante (se guarda y restaura la fisica original)
local AccelOrig = setmetatable({}, { __mode = "k" })
local function ApplyAccel(on)
	local char = LocalPlayer.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			if on then
				if AccelOrig[p] == nil then AccelOrig[p] = p.CustomPhysicalProperties or false end
				local b = p.CustomPhysicalProperties
				p.CustomPhysicalProperties = PhysicalProperties.new(100, b and b.Friction or 0.3, b and b.Elasticity or 0, b and b.FrictionWeight or 1, b and b.ElasticityWeight or 1)
			elseif AccelOrig[p] ~= nil then
				p.CustomPhysicalProperties = AccelOrig[p] or nil
				AccelOrig[p] = nil
			end
		end
	end
end
Hooks.NoAcceleration = function(v) ApplyAccel(v) end
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.6)
	if Ex.NoAcceleration then ApplyAccel(true) end
end)

-- Alcance de puertas: abre las puertas cercanas (75 studs) sin acercarte
local DoorDone = setmetatable({}, { __mode = "k" })
local DoorHooked = setmetatable({}, { __mode = "k" })
local DoorLast = 0
RunService.Heartbeat:Connect(function()
	if not Ex.DoorReach then return end
	local now = os.clock()
	if now - DoorLast < 0.25 then return end
	DoorLast = now
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local rooms = Rooms()
	if not (root and rooms) then return end
	for _, room in ipairs(rooms:GetChildren()) do
		local model = room:FindFirstChild("Door")
		if model and not DoorDone[model] then
			local part = model:FindFirstChild("Door")
			local ce = model:FindFirstChild("ClientOpen")
			if part and part:IsA("BasePart") and ce then
				if not DoorHooked[model] then
					DoorHooked[model] = true
					local snd = part:FindFirstChild("Open")
					if snd and snd:IsA("Sound") then
						snd.Played:Once(function() DoorDone[model] = true end)
					end
				end
				if (part.Position - root.Position).Magnitude < 75 then
					pcall(function() ce:FireServer() end)
				end
			end
		end
	end
end)

-- Sonidos: pasos e interacciones
local FootConn
local function HookFootsteps(char)
	if FootConn then FootConn:Disconnect(); FootConn = nil end
	if not char then return end
	FootConn = char.ChildAdded:Connect(function(o)
		if Ex.NoFootsteps and o:IsA("Sound") and o.Name == "Sound" then o.Volume = 0 end
	end)
end
HookFootsteps(LocalPlayer.Character)
LocalPlayer.CharacterAdded:Connect(HookFootsteps)

local function SetPromptSounds(mute)
	pcall(function()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		local mg = pg and pg:FindFirstChild("MainUI") and pg.MainUI:FindFirstChild("Initiator")
		mg = mg and mg:FindFirstChild("Main_Game")
		local ps = mg and mg:FindFirstChild("PromptService")
		if ps then
			if ps:FindFirstChild("Triggered") then ps.Triggered.Volume = mute and 0 or 0.04 end
			if ps:FindFirstChild("Holding") then ps.Holding.Volume = mute and 0 or 0.1 end
			if ps:FindFirstChild("Notification") then ps.Notification.Volume = mute and 0 or 0.03 end
		end
		local cap = mg and mg:FindFirstChild("Reminder") and mg.Reminder:FindFirstChild("Caption")
		if cap and cap:IsA("Sound") then cap.Volume = mute and 0 or 0.1 end
	end)
end
Hooks.NoPromptSounds = function(v) SetPromptSounds(v) end
task.spawn(function()
	while true do
		task.wait(1.5)
		if Ex.NoPromptSounds then SetPromptSounds(true) end
	end
end)

-- ------------------------------------------------------------------------------------------
-- Disable Idle Kick
-- ------------------------------------------------------------------------------------------
Hooks.DisableIdleKick = function(v)
	if getconnections then
		pcall(function()
			for _, c in ipairs(getconnections(LocalPlayer.Idled)) do
				if v then c:Disable() else c:Enable() end
			end
		end)
	end
end
LocalPlayer.Idled:Connect(function()
	if Ex.DisableIdleKick then
		pcall(function()
			local vu = game:GetService("VirtualUser")
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
	end
end)

print("[R4NS0M] Loading Meld Scripts")
-- ------------------------------------------------------------------------------------------
-- MELD (The Stairwell)
--  * Stop Growth : desactiva los scripts / modulos de Meld (lo que lo hace crecer). NO toca partes, asi las cuerdas
--                  y las puertas de Meld se quedan exactamente como estan.
--  * Remove Meld : oculta y quita colision/toque a las partes de Meld, EXCEPTO cuerdas y puertas.
-- No se conoce la estructura exacta de Meld en el Dex, asi que todo se hace por NOMBRE (contiene "meld") y las
-- palabras de abajo se pueden editar. Con Debug Mode activado se imprime lo que se encuentra.
-- ------------------------------------------------------------------------------------------
local MELD_KEEP = { "rope", "cord", "cable", "chain", "string", "wire", "door", "gate", "puerta", "cuerda" }
local Meld = { Orig = setmetatable({}, { __mode = "k" }), Scripts = setmetatable({}, { __mode = "k" }), Conn = nil, Loop = false }

local function IsMeldName(n) return type(n) == "string" and n:lower():find("meld", 1, true) ~= nil end
local function KeepName(n)
	n = n:lower()
	for _, w in ipairs(MELD_KEEP) do
		if n:find(w, 1, true) then return true end
	end
	return false
end
-- raiz Meld de una instancia (la mas cercana hacia arriba que tenga "meld" en el nombre)
local function MeldRoot(inst)
	local p, i = inst, 0
	while p and p ~= Workspace and i < 12 do
		if IsMeldName(p.Name) and (p:IsA("Model") or p:IsA("Folder") or p:IsA("BasePart")) then return p end
		p, i = p.Parent, i + 1
	end
end
local function UnderKeep(part, root)
	local p, i = part, 0
	while p and i < 12 do
		if KeepName(p.Name) then return true end
		if p == root then break end
		p, i = p.Parent, i + 1
	end
	return false
end

local function MeldHidePart(part)
	if part:IsA("BasePart") then
		if not Meld.Orig[part] then Meld.Orig[part] = { T = part.Transparency, C = part.CanCollide, Touch = part.CanTouch } end
		part.Transparency, part.CanCollide, part.CanTouch = 1, false, false
	elseif part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") or part:IsA("Light") then
		if not Meld.Orig[part] then Meld.Orig[part] = { En = part.Enabled } end
		part.Enabled = false
	elseif part:IsA("Decal") or part:IsA("Texture") then
		if not Meld.Orig[part] then Meld.Orig[part] = { T = part.Transparency } end
		part.Transparency = 1
	end
end

local function MeldRestoreAll()
	for obj, o in pairs(Meld.Orig) do
		pcall(function()
			if o.En ~= nil then obj.Enabled = o.En
			elseif obj:IsA("BasePart") then obj.Transparency, obj.CanCollide, obj.CanTouch = o.T, o.C, o.Touch
			else obj.Transparency = o.T end
		end)
		Meld.Orig[obj] = nil
	end
end

local function MeldHandle(d)
	-- Stop Growth: scripts y modulos con "meld" en el nombre
	if Ex.MeldStopGrowth then
		if (d:IsA("Script") or d:IsA("LocalScript")) and (IsMeldName(d.Name) or MeldRoot(d)) then
			if Meld.Scripts[d] == nil then Meld.Scripts[d] = d.Disabled end
			pcall(function() d.Disabled = true end)
			if Cfg.Debug then print("[R4NS0M MELD] script disabled: " .. d:GetFullName()) end
		elseif d:IsA("ModuleScript") and IsMeldName(d.Name) and not d.Name:find("_Disabled", 1, true) then
			Meld.Scripts[d] = d.Name
			pcall(function() d.Name = d.Name .. "_Disabled" end)
			if Cfg.Debug then print("[R4NS0M MELD] module disabled: " .. d:GetFullName()) end
		end
	end
	-- Remove Meld: oculta todo menos cuerdas y puertas
	if Ex.MeldRemove and (d:IsA("BasePart") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Light") or d:IsA("Decal") or d:IsA("Texture")) then
		local root = MeldRoot(d)
		if root and not Players:GetPlayerFromCharacter(root) and not UnderKeep(d, root) then
			MeldHidePart(d)
		end
	end
end

local function MeldScanAll()
	task.spawn(function()
		local n = 0
		local scopes = { Workspace, RS, LocalPlayer:FindFirstChild("PlayerGui") }
		for _, scope in ipairs(scopes) do
			if scope then
				for _, d in ipairs(scope:GetDescendants()) do
					if not (Ex.MeldStopGrowth or Ex.MeldRemove) then return end
					pcall(MeldHandle, d)
					n = n + 1
					if n % 300 == 0 then task.wait() end
				end
			end
		end
	end)
end

local function MeldRefresh()
	if Ex.MeldStopGrowth or Ex.MeldRemove then
		if not Meld.Conn then
			Meld.Conn = Workspace.DescendantAdded:Connect(function(d) task.defer(pcall, MeldHandle, d) end)
		end
		MeldScanAll()
		if not Meld.Loop then
			Meld.Loop = true
			task.spawn(function() -- el juego puede recrear / re-encender cosas: se repasa cada 3s
				while Ex.MeldStopGrowth or Ex.MeldRemove do
					task.wait(3)
					MeldScanAll()
				end
				Meld.Loop = false
			end)
		end
	else
		if Meld.Conn then Meld.Conn:Disconnect(); Meld.Conn = nil end
	end
end

Hooks.MeldStopGrowth = function(v)
	if not v then
		for obj, old in pairs(Meld.Scripts) do
			pcall(function()
				if typeof(old) == "string" then obj.Name = old else obj.Disabled = old end
			end)
			Meld.Scripts[obj] = nil
		end
	end
	MeldRefresh()
end
Hooks.MeldRemove = function(v)
	if not v then MeldRestoreAll() end
	MeldRefresh()
end

print("[R4NS0M] Loaded Meld Scripts")

-- mantiene el Reach / Clip en los prompts nuevos
Workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then
		AI.Set[d] = true
		if Ex.PromptReach ~= 1 or Ex.PromptClip then task.defer(pcall, ApplyReach, d) end
		if Ex.InfiniteItems then task.delay(0.3, function() pcall(MakeFake, d) end) end
	end
end)
task.spawn(function()
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then AI.Set[d] = true end
	end
end)
Workspace.DescendantAdded:Connect(function(d)
	if d.Name == "ElevatorBreaker" then HookBreaker(d) end
end)

print("[R4NS0M] Loaded Extra Functions")
print("[R4NS0M] Loading more UI")
-- ------------------------------------------------------------------------------------------
-- Interfaz
-- ------------------------------------------------------------------------------------------
AutomationTab:Section({ Title = "Automation" })
AddToggle(AutomationTab, "AutoBreakerBox", "Auto Breaker Box",
	"Automatically solves the elevator breaker box. Interact with it once and the rest is done for you.",
	Ex.AutoBreakerBox, function(v) Apply("AutoBreakerBox", v) end)
AddToggle(AutomationTab, "AutoInteract", "Auto Interact",
	"Automatically triggers nearby prompts (items, gold, levers...). It skips hiding spots, locks, dropped items, glitch fragments and fake doors.",
	Ex.AutoInteract, function(v) Ex.AutoInteract = v end)
AddToggle(AutomationTab, "InfiniteItems", "Infinite Items",
	"Lets the selected items open locks, vines and chests without losing uses. Needs fireproximityprompt. Works by hiding the real lock prompt and replacing it with a fake one.",
	Ex.InfiniteItems, function(v) Apply("InfiniteItems", v) end)
do
	local dd = AutomationTab:Dropdown({
		Title = "Infinite Items List",
		Desc = "Items that will not be consumed while Infinite Items is on.",
		Values = { "Lockpicks", "Skeleton Key", "Shears", "Multitool" },
		Value = Ex.InfiniteItemsList,
		Multi = true,
		AllowNone = true,
		Callback = function(selected)
			local out = {}
			for _, n in ipairs(selected or {}) do out[#out + 1] = n end
			Ex.InfiniteItemsList = out
		end
	})
	Setters.InfiniteItemsList = function(list) pcall(function() dd:Select(list) end) end
end
AutomationTab:Section({ Title = "Prompts" })
AddSlider(AutomationTab, "PromptReach", "Prompt Reach Multiplier", "Multiplies how far away you can interact with prompts (1 = normal).", 1, 3, Ex.PromptReach, function(v) Apply("PromptReach", v) end)
AddToggle(AutomationTab, "PromptClip", "Prompt Clip", "Lets you interact with prompts through walls.", Ex.PromptClip, function(v) Apply("PromptClip", v) end)
AddToggle(AutomationTab, "DoorReach", "Door Reach", "Opens doors from further away (up to 75 studs).", Ex.DoorReach, function(v) Apply("DoorReach", v) end)

AlertsTab:Section({ Title = "Environment" })
AddToggle(AlertsTab, "NotifyOxygen", "Notify Oxygen Level", "Shows how much oxygen you have left every time it drops.", Ex.NotifyOxygen, function(v) Apply("NotifyOxygen", v) end)
AddToggle(AlertsTab, "NotifyHaste", "Notify Haste Time", "Shows the time remaining before 'Haste' spawns.", Ex.NotifyHaste, function(v) Apply("NotifyHaste", v) end)

PlayerTab:Section({ Title = "Movement" })
AddToggle(PlayerTab, "NoClosetDelay", "Remove Closet Delay", "Removes the short window where you can't exit a closet after the animation finishes.", Ex.NoClosetDelay, function(v) Apply("NoClosetDelay", v) end)
AddToggle(PlayerTab, "NoAcceleration", "Remove Acceleration", "Your character stops right away instead of sliding while moving.", Ex.NoAcceleration, function(v) Apply("NoAcceleration", v) end)

MiscTab:Section({ Title = "Sounds" })
AddToggle(MiscTab, "NoFootsteps", "Remove Footstep Sounds", "Mutes the sound of walking.", Ex.NoFootsteps, function(v) Apply("NoFootsteps", v) end)
AddToggle(MiscTab, "NoPromptSounds", "Remove Interacting Sounds", "Mutes the sounds of interacting with prompts. Turning it off restores them.", Ex.NoPromptSounds, function(v) Apply("NoPromptSounds", v) end)

MiscTab:Section({ Title = "Misc" })
AddToggle(MiscTab, "DisableIdleKick", "Disable Idle Kick", "Prevents the kick for being idle for 20 minutes.", Ex.DisableIdleKick, function(v) Apply("DisableIdleKick", v) end)

AntisTab:Section({ Title = "Meld (The Stairwell)" })
AntisTab:Paragraph({
	Title = "How Meld removal works",
	Desc = "Both options work by name (anything called 'meld'). Stop Growth only disables Meld's scripts/modules, so its ropes and doors stay untouched. "
		.. "Remove Meld hides the rest of its parts but always keeps ropes, cables, chains and doors. Turn on Debug Mode to print what was found.",
})
AddToggle(AntisTab, "MeldStopGrowth", "Stop Meld Growth", "Disables the scripts that make Meld grow. Ropes and doors are not removed.", Ex.MeldStopGrowth, function(v) Apply("MeldStopGrowth", v) end)
AddToggle(AntisTab, "MeldRemove", "Remove Meld (keep ropes & doors)", "Hides Meld and removes its collision/touch, except its ropes and doors.", Ex.MeldRemove, function(v) Apply("MeldRemove", v) end)
end)()

AntiCheatTab:Section({ Title = "Mobile Buttons" })
AddToggle(AntiCheatTab, "FloatButtons", "Floating Buttons", "Small draggable buttons for ACM, SLIDE and FLY. On by default on touch devices.", Ex.FloatButtons, function(v)
    Ex.FloatButtons = v
    FX.UpdateButtons()
end)
AddToggle(AntiCheatTab, "BtnACM", "ACM Button", "Show the ACM floating button.", Ex.BtnACM, function(v) Ex.BtnACM = v; FX.UpdateButtons() end)
AddToggle(AntiCheatTab, "BtnFly", "FLY Button", "Show the FLY floating button.", Ex.BtnFly, function(v) Ex.BtnFly = v; FX.UpdateButtons() end)

print("[R4NS0M] Loading Batch 2")
-- ============================================================================================
-- BATCH 2
--   Automation : Guess Library Code, Auto Steer Minecart, Auto Complete Dam Seek / Cringle, Auto Interact Ignore List
--   Alerts     : Notify Library Code (texto abajo + aviso)
--   Misc       : Revive
-- ============================================================================================
;(function()
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local function Remotes() return RS:FindFirstChild("RemotesFolder") or RS:FindFirstChild("EntityInfo") or RS:FindFirstChild("Bricks") end
local function Rooms() return Workspace:FindFirstChild("CurrentRooms") end
local function Toast(t, d) pcall(FX.ShowToast, t, d or "", "", Color3.fromRGB(255, 200, 80)) end
local function CurRoom() return tonumber(LocalPlayer:GetAttribute("CurrentRoom")) or 0 end
local function FloorName()
	local gd = RS:FindFirstChild("GameData")
	local f = gd and gd:FindFirstChild("Floor")
	return f and f.Value or ""
end

Ex.NotifyLibraryCode = false
Ex.GuessLibraryCode = false
Ex.AutoSteerMinecart = false
Ex.AIIgnore = {
	["Jeff Items"] = true, ["Meld Chords"] = true, ["Share Gold Plate"] = true, ["Portraits"] = true,
	["Terminals"] = true, ["Stems"] = true, ["Ladders"] = true, ["Locks (Key/Shears/Lockpick)"] = true,
	["Chairs"] = true, ["Shopping Cart"] = true, ["Archives Box"] = true, ["Dropped Items"] = true,
	["Cobbler Items"] = true, ["Stairwell Items/Salvage"] = true, ["Glitch Fragments"] = true,
}

-- ------------------------------------------------------------------------------------------
-- Auto Interact: Ignore List (se enlaza desde AISkip por Ex.AIExtraSkip)
-- Se decide por palabras en el nombre del prompt, sus textos y la cadena de padres (cache por prompt).
-- ------------------------------------------------------------------------------------------
local AICache = setmetatable({}, { __mode = "k" })
local function Chain(pp)
	local parts = { pp.Name, pp.ActionText, pp.ObjectText }
	local cur, d = pp.Parent, 0
	while cur and cur ~= Workspace and d < 8 do
		parts[#parts + 1] = cur.Name
		cur = cur.Parent
		d = d + 1
	end
	return table.concat(parts, " "):lower(), parts
end
local function Words(str)
	local out = {}
	str = str:gsub("(%l)(%u)", "%1 %2"):gsub("[^%a]+", " "):lower()
	for w in str:gmatch("%a+") do out[w] = true end
	return out
end
local function Category(pp)
	local flat, parts = Chain(pp)
	local compact = flat:gsub("[^%a]", "")
	local raw = table.concat(parts, " ")
	local w = Words(raw)
	if w.jeff or w.shop or compact:find("jeffshop", 1, true) then return "Jeff Items" end
	if compact:find("meld", 1, true) and (compact:find("chord", 1, true) or w.chord or w.chords) then return "Meld Chords" end
	if compact:find("tithing", 1, true) or compact:find("sharegold", 1, true) or compact:find("goldplate", 1, true) then return "Share Gold Plate" end
	if w.portrait or w.portraits or w.painting then return "Portraits" end
	if w.terminal or w.terminals then return "Terminals" end
	if w.stem or w.stems then return "Stems" end
	if w.ladder or w.ladders then return "Ladders" end
	if compact:find("unlock", 1, true) or compact:find("skeletonkey", 1, true) or w.shears or w.lockpick or w.lockpicks then return "Locks (Key/Shears/Lockpick)" end
	if w.chair or w.chairs or w.sofa or w.couch or w.seat or w.armchair then return "Chairs" end
	if compact:find("shoppingcart", 1, true) then return "Shopping Cart" end
	if compact:find("archive", 1, true) and (w.box or w.boxes or compact:find("box", 1, true)) then return "Archives Box" end
	if w.cobbler or compact:find("cobbler", 1, true) then return "Cobbler Items" end
	if w.salvage or w.scrap or w.scrapper then return "Stairwell Items/Salvage" end
	if compact:find("glitchcube", 1, true) or compact:find("glitchfragment", 1, true) then return "Glitch Fragments" end
	return false
end
local AIItemCache = setmetatable({}, { __mode = "k" })
local function ItemOf(pp)
	local cands = { pp.ObjectText, pp.Parent and pp.Parent.Name, pp.Parent and pp.Parent.Parent and pp.Parent.Parent.Name }
	for _, c in ipairs(cands) do
		if type(c) == "string" and c ~= "" then
			local canon = ITEM_LOOKUP[Norm(c)]
			if canon then return canon end
		end
	end
	return false
end
Ex.AIExtraSkip = function(pp)
	local c = AICache[pp]
	if c == nil then
		local ok, r = pcall(Category, pp)
		c = ok and r or false
		AICache[pp] = c
	end
	if c and Ex.AIIgnore[c] then return true end
	local it = AIItemCache[pp]
	if it == nil then
		local ok, r = pcall(ItemOf, pp)
		it = ok and r or false
		AIItemCache[pp] = it
	end
	if it and Ex.AIItemIgnore and Ex.AIItemIgnore[it] then return true end
	if Ex.AIIgnore["Dropped Items"] then
		local Drops = Workspace:FindFirstChild("Drops")
		if Drops and pp:IsDescendantOf(Drops) then return true end
	end
	return false
end

-- ------------------------------------------------------------------------------------------
-- Library Code (papel + libros)
-- ------------------------------------------------------------------------------------------
local function GetLibraryCode()
	local char = LocalPlayer.Character
	local bp = LocalPlayer:FindFirstChild("Backpack")
	local paper = (char and (char:FindFirstChild("LibraryHintPaper") or char:FindFirstChild("LibraryHintPaperHard")))
		or (bp and (bp:FindFirstChild("LibraryHintPaper") or bp:FindFirstChild("LibraryHintPaperHard")))
	local fools = FloorName() == "Fools"
	local len = fools and 10 or 5
	if not (paper and paper:FindFirstChild("UI")) then return nil, string.rep("_", len), len end
	local perm = LocalPlayer.PlayerGui:FindFirstChild("PermUI")
	local hints = perm and perm:FindFirstChild("Hints")
	if not hints then return nil, string.rep("_", len), len end
	local code = {}
	for i = 1, len do code[i] = "_" end
	for _, hint in ipairs(hints:GetChildren()) do
		for _, ui in ipairs(paper.UI:GetChildren()) do
			local idx = tonumber(ui.Name)
			if hint:IsA("ImageLabel") and ui:IsA("ImageLabel") and idx and code[idx]
				and hint.ImageRectOffset == ui.ImageRectOffset and hint:FindFirstChild("TextLabel") then
				code[idx] = hint.TextLabel.Text
			end
		end
	end
	local s = table.concat(code)
	return (not s:find("_", 1, true)) and s or nil, s, len
end

-- texto abajo en pantalla (mismo estilo que el aviso de oxigeno)
local codeGui, codeLabel
local function EnsureCodeLabel()
	if codeLabel and codeLabel.Parent then return codeLabel end
	local gui = Instance.new("ScreenGui")
	gui.Name = "R4NS0M_LibCode"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 1)
	l.Position = UDim2.new(0.5, 0, 1, -90)
	l.Size = UDim2.new(0.8, 0, 0, 34)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 24
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.3
	l.Visible = false
	l.Parent = gui
	codeGui, codeLabel = gui, l
	return l
end

local libNotified = false
task.spawn(function()
	local lastRoom = 0
	while true do
		task.wait(0.4)
		pcall(function()
			local room = CurRoom()
			if room < lastRoom - 5 then libNotified = false end -- nueva partida
			lastRoom = room
			if not Ex.NotifyLibraryCode then
				if codeLabel then codeLabel.Visible = false end
				return
			end
			local full, shown = GetLibraryCode()
			local l = EnsureCodeLabel()
			-- solo en la puerta/sala 50: se quita al abrir la puerta 51
			l.Visible = room == 50
			l.Text = "Library Code: " .. shown:gsub(".", "%0 ")
			if full and not libNotified and room == 50 then
				libNotified = true
				Toast("Padlock code found!", "The code is: " .. full)
			end
		end)
	end
end)

-- Guess Library Code: prueba codigos aleatorios con las cifras que ya conoces (solo sala 50)
local Used, Tries = {}, 0
task.spawn(function()
	while true do
		task.wait(0.05)
		if Ex.GuessLibraryCode and CurRoom() == 50 then
			pcall(function()
				local rem = Remotes()
				local pl = rem and rem:FindFirstChild("PL")
				if not (pl and Workspace:FindFirstChild("Padlock", true)) then return end
				local _, tpl = GetLibraryCode()
				local code, n = nil, 0
				repeat
					code = tpl:gsub("_", function() return tostring(math.random(0, 9)) end)
					n = n + 1
				until not Used[code] or n >= 10
				Used[code] = true
				pl:FireServer(code)
			end)
		elseif next(Used) and CurRoom() < 45 then
			Used = {}
		end
	end
end)

-- ------------------------------------------------------------------------------------------
-- Revive (el remote sirve aunque el tiempo del boton ya se haya acabado)
-- ------------------------------------------------------------------------------------------
local function DoRevive()
	local rem = Remotes()
	local r = rem and rem:FindFirstChild("Revive")
	if not r then Toast("Revive", "Remote not found.") return end
	pcall(function() r:FireServer() end)
	Toast("Revive", "Revive sent.")
end

-- ------------------------------------------------------------------------------------------
-- Auto Complete Cringle / Dam Seek
-- ------------------------------------------------------------------------------------------
local function CompleteCringle()
	local rooms = Rooms()
	local part = rooms and rooms:FindFirstChild("RippleExitDoor", true)
	local char = LocalPlayer.Character
	if part and char then
		char:PivotTo(part:GetPivot())
		Toast("Cringle", "Teleported to the exit.")
	else
		Toast("Cringle", "RippleExitDoor not found.")
	end
end

local damBusy = false
local function CompleteDam()
	if damBusy then return end
	local rooms = Rooms()
	local char = LocalPlayer.Character
	if not (rooms and char) then return end
	local pumps = {}
	for _, o in ipairs(rooms:GetDescendants()) do
		if o.Name == "WaterPump" and o:IsA("Model") then pumps[#pumps + 1] = o end
	end
	if #pumps == 0 then Toast("Dam Seek", "No water pumps found. Be in room 100.") return end
	damBusy = true
	task.spawn(function()
		local origin = char:GetPivot()
		local cutscene = false
		local rem = Remotes()
		local conn
		if rem and rem:FindFirstChild("Cutscene") then
			conn = rem.Cutscene.OnClientEvent:Connect(function()
				cutscene = true
				task.wait(7)
				cutscene = false
			end)
		end
		Toast("Dam Seek", "Completing the valves, please wait.")
		local done = {}
		table.sort(pumps, function(a, b) return a:GetPivot().Y > b:GetPivot().Y end)
		for _, pump in ipairs(pumps) do
			local t0 = os.clock()
			local wheel = pump:FindFirstChild("Wheel")
			local wsnd = wheel and wheel:FindFirstChild("Sound")
			local pconn = wsnd and wsnd.Played:Connect(function() done[pump] = true end)
			while pump.Parent and not done[pump] and os.clock() - t0 < 6 do
				task.wait(0.1)
				if not cutscene then
					pcall(function() char:PivotTo(pump:GetPivot()) end)
					local prompt = pump:FindFirstChild("ValvePrompt", true)
					if prompt and prompt.Enabled and fireproximityprompt then
						pcall(fireproximityprompt, prompt)
					elseif not prompt or not prompt.Enabled then
						done[pump] = true
					end
				end
			end
			if pconn then pconn:Disconnect() end
			done[pump] = true
		end
		if conn then conn:Disconnect() end
		pcall(function() char:PivotTo(origin) end)
		damBusy = false
		Toast("Dam Seek", "Valves completed.")
	end)
end

-- ------------------------------------------------------------------------------------------
-- Auto Steer Minecart (Seek, Mines piso 2): RunnerNodes -> giro por nodo + agacharse en DuckBoard
-- ------------------------------------------------------------------------------------------
local Cart = { Nodes = {}, Ducks = {}, Seen = setmetatable({}, { __mode = "k" }), Ducked = false, Nearest = nil }
local TURN_DIST, DUCK_DIST = 30, 30

local function IsBehind(p1, p2)
	local a = (p1.CFrame + p1.CFrame.LookVector).Position
	local b = (p1.CFrame + p1.CFrame.LookVector * -1).Position
	return (a - p2.Position).Magnitude > (b - p2.Position).Magnitude
end
local function GetDirection(p1, p2)
	local r = p1.CFrame.RightVector:Dot(p1.Position - p2.Position)
	if r > 0.5 then return IsBehind(p1, p2) and "Right" or "Left" end
	if r < -0.5 then return IsBehind(p1, p2) and "Left" or "Right" end
	return "Straight"
end
local function NodeId(n) return tonumber(n.Name:split("MinecartNode")[2]) end

local function SetupRunnerNodes(folder)
	if Cart.Seen[folder] then return end
	Cart.Seen[folder] = true
	task.spawn(function()
		local function closest(node)
			local best, bd = nil, math.huge
			local id = NodeId(node)
			for _, o in ipairs(folder:GetChildren()) do
				local oid = NodeId(o)
				if o ~= node and oid and id and oid > id then
					local d = (node.Position - o.Position).Magnitude
					if d < bd and o:GetAttribute("DistanceBlacklist") ~= true then bd, best = d, o end
				end
			end
			return best
		end
		for _, node in ipairs(folder:GetChildren()) do
			local id = NodeId(node)
			if node:GetAttribute("DeathType") then node:SetAttribute("DistanceBlacklist", true) end
			for i = 1, 20 do
				local nx = id and folder:FindFirstChild("MinecartNode" .. id + i)
				if nx and nx:GetAttribute("DeathType") ~= nil then node:SetAttribute("DistanceBlacklist", true) end
			end
			local pv = id and folder:FindFirstChild("MinecartNode" .. id - 1)
			if pv and pv:GetAttribute("ForceConnect") then node:SetAttribute("DistanceBlacklist", nil) end
			task.wait()
		end
		for _, node in ipairs(folder:GetChildren()) do
			if node:GetAttribute("ForceConnect") then
				local nx = closest(node)
				if nx then
					node:SetAttribute("Turn", GetDirection(node, nx))
					Cart.Nodes[#Cart.Nodes + 1] = node
				end
			end
			task.wait()
		end
	end)
end

local function ScanCart(o)
	if o.Name == "RunnerNodes" then SetupRunnerNodes(o)
	elseif o.Name == "DuckBoard" then Cart.Ducks[#Cart.Ducks + 1] = o end
end
local function HookRooms()
	local rooms = Rooms()
	if not rooms then return end
	for _, o in ipairs(rooms:GetDescendants()) do ScanCart(o) end
	rooms.DescendantAdded:Connect(ScanCart)
end
task.spawn(function()
	local rooms = Workspace:WaitForChild("CurrentRooms", 30)
	if rooms then HookRooms() end
end)

local function InCart() return workspace.CurrentCamera and workspace.CurrentCamera:FindFirstChild("MinecartRig") ~= nil end
local mainGame
local function MainGame()
	if mainGame then return mainGame end
	pcall(function()
		mainGame = require(LocalPlayer.PlayerGui:WaitForChild("MainUI").Initiator.Main_Game)
	end)
	return mainGame
end

-- sobrescribe el vector de movimiento solo mientras vas en el minecart
pcall(function()
	if not require then return end
	local controls = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	local orig = controls.GetMoveVector
	controls.GetMoveVector = function(...)
		if Ex.AutoSteerMinecart and Cart.Nearest and InCart() then
			local turn = Cart.Nearest:GetAttribute("Turn")
			return turn == "Left" and Vector3.new(-1, 0, 0) or turn == "Right" and Vector3.new(1, 0, 0) or Vector3.zero
		end
		return orig(...)
	end
end)

local lastCart = 0
RunService.Heartbeat:Connect(function()
	if not Ex.AutoSteerMinecart or not InCart() or os.clock() - lastCart < 0.1 then return end
	lastCart = os.clock()
	local near, nd = nil, math.huge
	for _, n in ipairs(Cart.Nodes) do
		if n.Parent then
			local d = LocalPlayer:DistanceFromCharacter(n.Position)
			if d < TURN_DIST and d < nd then near, nd = n, d end
		end
	end
	Cart.Nearest = near
	local duck = false
	for _, b in ipairs(Cart.Ducks) do
		if b.Parent and b.PrimaryPart and LocalPlayer:DistanceFromCharacter(b.PrimaryPart.Position) < DUCK_DIST then duck = true break end
	end
	local mg = MainGame()
	if mg and mg.crouch then
		if duck and not Cart.Ducked then pcall(mg.crouch, true) Cart.Ducked = true
		elseif not duck and Cart.Ducked then pcall(mg.crouch, false) Cart.Ducked = false end
	end
end)

-- ------------------------------------------------------------------------------------------
-- Interfaz
-- ------------------------------------------------------------------------------------------
AutomationTab:Section({ Title = "Floors" })
AddToggle(AutomationTab, "AutoSteerMinecart", "Auto Steer Minecart", "Completes the Seek minecart chase (Mines floor 2): steers at each turn and crouches under boards.", Ex.AutoSteerMinecart, function(v) Ex.AutoSteerMinecart = v end)
AutomationTab:Button({ Title = "Auto Complete Dam Seek", Desc = "Teleports to each water pump (highest first) and interacts with it, then returns you. Be in room 100.", Callback = CompleteDam })
AutomationTab:Button({ Title = "Auto Complete Cringle", Desc = "Teleports you to the end of the quest.", Callback = CompleteCringle })

AutomationTab:Section({ Title = "Library" })
AddToggle(AutomationTab, "GuessLibraryCode", "Guess Library Code", "Tries random codes on the padlock in room 50, keeping the digits you already know. You still need to collect some books.", Ex.GuessLibraryCode, function(v) Ex.GuessLibraryCode = v end)

AutomationTab:Section({ Title = "Auto Interact Ignore List" })
do
	local names = {}
	for k in pairs(Ex.AIIgnore) do names[#names + 1] = k end
	table.sort(names)
	local all = {}
	for _, k in ipairs(names) do all[#all + 1] = k end
	local dd = AutomationTab:Dropdown({
		Title = "Ignore List",
		Desc = "Types of objects Auto Interact will NOT touch (all selected by default). Detection is by name/text. Specific items have their own list below.",
		Values = names,
		Value = all,
		Multi = true,
		AllowNone = true,
		Callback = function(selected)
			local set = {}
			for _, n in ipairs(selected or {}) do set[n] = true end
			Ex.AIIgnore = set
		end,
	})
	local function SetAll(on)
		local set, list = {}, {}
		if on then
			for _, n in ipairs(names) do set[n] = true list[#list + 1] = n end
		end
		Ex.AIIgnore = set
		pcall(function() dd:Select(list) end)
	end
	AutomationTab:Button({ Title = "Ignore everything", Desc = "Selects every entry of the ignore list.", Callback = function() SetAll(true) end })
	AutomationTab:Button({ Title = "Ignore nothing", Desc = "Clears the ignore list: Auto Interact will touch everything.", Callback = function() SetAll(false) end })
end

AlertsTab:Section({ Title = "Library" })
AddToggle(AlertsTab, "NotifyLibraryCode", "Notify Library Code", "Shows the 5 digits at the bottom of the screen (_ for the ones you don't have yet; you need the paper and the matching books). Hides when door 51 opens, and notifies when complete.", Ex.NotifyLibraryCode, function(v) Ex.NotifyLibraryCode = v if v then libNotified = false end end)

MiscTab:Section({ Title = "Revive" })
MiscTab:Button({ Title = "Revive", Desc = "Sends the revive request. Works even after the revive timer ran out (needs a revive available).", Callback = DoRevive })
end)()

print("[R4NS0M] Loading Batch 3")
-- ============================================================================================
-- BATCH 3
--   Player  : Infinite Jump tambien con el boton de saltar de DOORS (celular)
--   Visuals : Show Seek Path / Show Eyestalk Path (Lines por defecto o Nodes)
--   Alerts  : Notify Items (lista + unlisted)
--   ESP     : Stem de Workspace.LiveEntities
-- ============================================================================================
;(function()
local PathfindingService = game:GetService("PathfindingService")
local function Toast(t, d) pcall(FX.ShowToast, t, d or "", "", Color3.fromRGB(255, 200, 80)) end

Ex.ShowSeekPath = false
Ex.ShowEyestalkPath = false
Ex.PathMode = "Lines"
Ex.NotifyItems = false
Ex.NotifyUnlistedItems = false
Ex.NotifyItemFilter = {}
-- por defecto solo lo importante/roto; la lista completa sigue disponible en el dropdown
local ESSENTIAL_ITEMS = { "Crucifix", "Gold Gun", "Lockpicks", "Skeleton Key", "Holy Hand Grenade", "Shears", "Multitool", "Big Bomb", "Knockbomb", "Laser Pointer" }
for _, n in ipairs(ESSENTIAL_ITEMS) do Ex.NotifyItemFilter[n] = true end

-- ------------------------------------------------------------------------------------------
-- Infinite Jump en celular: el boton de saltar de DOORS no dispara JumpRequest
-- ------------------------------------------------------------------------------------------
do
	local lastBtn
	local function DoJump()
		if not Ex.InfJump then return end
		local _, hum = GetParts()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(function()
				local ui = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
				local mf = ui and ui:FindFirstChild("MainFrame")
				local mb = mf and mf:FindFirstChild("MobileButtons")
				local jb = mb and mb:FindFirstChild("JumpButton")
				if jb and jb ~= lastBtn then
					lastBtn = jb
					jb.MouseButton1Click:Connect(DoJump)
					jb.Activated:Connect(DoJump)
				end
			end)
		end
	end)
end

-- ------------------------------------------------------------------------------------------
-- Seek / Eyestalk Path
-- ------------------------------------------------------------------------------------------
local PathRoot = Instance.new("Folder")
PathRoot.Name = "R4NS0M_Paths"
PathRoot.Parent = Workspace
local Paths = {} -- key -> { kind, points, folder }

local function PathColor(kind) return kind == "seek" and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 255, 255) end
local function Enabled(kind) return kind == "seek" and Ex.ShowSeekPath or Ex.ShowEyestalkPath end

local function Erase(p)
	if p.folder then p.folder:Destroy() p.folder = nil end
end
local function Render(p)
	Erase(p)
	if not Enabled(p.kind) or #p.points == 0 then return end
	local f = Instance.new("Folder")
	f.Name = "P"
	f.Parent = PathRoot
	p.folder = f
	local color = PathColor(p.kind)
	local lines = Ex.PathMode ~= "Nodes"
	local prevAtt
	for _, pos in ipairs(p.points) do
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Position = pos
		if lines then
			part.Size = Vector3.one * 0.3
			part.Transparency = 1
		else
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.one * 1.5
			part.Material = Enum.Material.Neon
			part.Color = color
			part.Transparency = 0.15
		end
		part.Parent = f
		if lines then
			local att = Instance.new("Attachment")
			att.Parent = part
			if prevAtt then
				local b = Instance.new("Beam")
				b.Attachment0 = prevAtt
				b.Attachment1 = att
				b.FaceCamera = true
				b.Width0, b.Width1 = 0.25, 0.25
				b.Brightness = 10
				b.LightInfluence = 0
				b.LightEmission = 1
				b.Color = ColorSequence.new(color)
				b.Parent = part
			end
			prevAtt = att
		end
	end
end
local function SetPath(key, kind, points)
	local p = Paths[key]
	if not p then p = { kind = kind } Paths[key] = p end
	p.points = points
	Render(p)
end
local function RedrawAll() for _, p in pairs(Paths) do Render(p) end end
Ex.ClearSeekPaths = function()
	for k, p in pairs(Paths) do
		if p.kind == "seek" then Erase(p) Paths[k] = nil end
	end
end

-- Seek: las luces guia (SeekGuidingLight) de cada cuarto, ordenadas siguiendo el camino mas cercano
local function RoomOf(inst)
	local rooms = Workspace:FindFirstChild("CurrentRooms")
	local cur = inst
	while cur and cur.Parent ~= rooms do cur = cur.Parent end
	return cur
end
local seekToken = {}
local function RebuildSeek(room)
	if not room or not room.Parent then return end
	local lights = {}
	local folder = room:FindFirstChild("PathLights", true)
	if folder then
		-- orden real de aparicion de las luces (el juego las agrega en secuencia)
		for _, d in ipairs(folder:GetChildren()) do
			if d.Name == "SeekGuidingLight" then
				local pos = d:IsA("BasePart") and d.Position or (d:IsA("Model") and d:GetPivot().Position)
				if pos then lights[#lights + 1] = pos end
			end
		end
		if #lights > 0 then
			SetPath("seek:" .. room.Name, "seek", lights)
			return
		end
	end
	for _, d in ipairs(room:GetDescendants()) do
		if d.Name == "SeekGuidingLight" then
			local pos = d:IsA("BasePart") and d.Position or (d:IsA("Model") and d:GetPivot().Position)
			if pos then lights[#lights + 1] = pos end
		end
	end
	if #lights == 0 then return end
	local entrance = room:FindFirstChild("RoomEntrance")
	local start = entrance and entrance:IsA("BasePart") and entrance.Position or lights[1]
	local ordered, cur = {}, start
	while #lights > 0 do
		local bi, bd = 1, math.huge
		for i, p in ipairs(lights) do
			local dd = (p - cur).Magnitude
			if dd < bd then bi, bd = i, dd end
		end
		cur = table.remove(lights, bi)
		ordered[#ordered + 1] = cur
	end
	SetPath("seek:" .. room.Name, "seek", ordered)
end
local function OnSeekLight(d)
	if d.Name ~= "SeekGuidingLight" then return end
	local room = RoomOf(d)
	if not room then return end
	seekToken[room] = (seekToken[room] or 0) + 1
	local tok = seekToken[room]
	task.delay(0.5, function()
		if seekToken[room] == tok then pcall(RebuildSeek, room) end
	end)
end

-- Eyestalk: camino calculado desde ti hasta RoomExit en cuartos "Eyestalk"
local eyeBusy = setmetatable({}, { __mode = "k" })
local function SetupEyestalk(room)
	if eyeBusy[room] then return end
	local raw = room:GetAttribute("RawName")
	if not (type(raw) == "string" and raw:find("Eyestalk", 1, true)) then return end
	eyeBusy[room] = true
	task.spawn(function()
		local exitPart = room:WaitForChild("RoomExit", 30)
		room:WaitForChild("RoomEntrance", 30)
		while room.Parent and not room:GetAttribute("PathFoundR4N") do
			if Ex.ShowEyestalkPath and exitPart then
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					local path = PathfindingService:CreatePath({
						AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 2, AgentRadius = 1, AgentHeight = 1,
					})
					local ok = pcall(function() path:ComputeAsync(root.Position, exitPart.Position) end)
					if ok and path.Status == Enum.PathStatus.Success then
						room:SetAttribute("PathFoundR4N", true)
						local pts = {}
						for _, w in ipairs(path:GetWaypoints()) do pts[#pts + 1] = w.Position end
						SetPath("eye:" .. room.Name, "eye", pts)
						break
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

task.spawn(function()
	local rooms = Workspace:WaitForChild("CurrentRooms", 60)
	if not rooms then return end
	for _, d in ipairs(rooms:GetDescendants()) do OnSeekLight(d) end
	for _, r in ipairs(rooms:GetChildren()) do SetupEyestalk(r) end
	rooms.DescendantAdded:Connect(OnSeekLight)
	rooms.ChildAdded:Connect(function(r)
		task.wait(0.5)
		SetupEyestalk(r)
	end)
	-- cuartos que se borran: se limpian sus caminos
	rooms.ChildRemoved:Connect(function(r)
		for _, pre in ipairs({ "seek:", "eye:" }) do
			local p = Paths[pre .. r.Name]
			if p then Erase(p) Paths[pre .. r.Name] = nil end
		end
	end)
end)

-- ------------------------------------------------------------------------------------------
-- Stem: Workspace.LiveEntities.StemsEntity
-- ------------------------------------------------------------------------------------------
task.spawn(function()
	local le = Workspace:WaitForChild("LiveEntities", 120)
	if not le then return end
	local function try(d)
		if d:IsA("Model") and d.Name:lower():find("stem", 1, true) then
			task.defer(function()
				if Active.entities then pcall(RegisterEntityWhenReady, d, "Stem", true) end
			end)
		end
	end
	for _, d in ipairs(le:GetChildren()) do try(d) end
	le.ChildAdded:Connect(try)
end)

-- ------------------------------------------------------------------------------------------
-- Notify Items (se llama desde Register cuando se marca un item)
-- ------------------------------------------------------------------------------------------
local itemReady = os.clock() + 5 -- ignora lo que ya existia al cargar
local itemSeen = setmetatable({}, { __mode = "k" })
Watch.OnItem = function(label, inst, known, key)
	if not Ex.NotifyItems or os.clock() < itemReady or itemSeen[inst] then return end
	itemSeen[inst] = true
	if known then
		if not Ex.NotifyItemFilter[key or label] then return end
	elseif not Ex.NotifyUnlistedItems then
		return
	end
	local desc = ""
	pcall(function()
		local part = Tracked[inst] and Tracked[inst].Part
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if part and root then desc = math.floor((part.Position - root.Position).Magnitude + 0.5) .. " studs away" end
	end)
	Toast(label .. " spawned", desc)
end

-- ------------------------------------------------------------------------------------------
-- Interfaz
-- ------------------------------------------------------------------------------------------
VisualsTab:Section({ Title = "Chase Paths" })
AddToggle(VisualsTab, "ShowSeekPath", "Show Seek Path", "Draws the correct path during the Seek chase.", Ex.ShowSeekPath, function(v) Ex.ShowSeekPath = v RedrawAll() end)
AddToggle(VisualsTab, "ShowEyestalkPath", "Show Eyestalk Path", "Draws the safe path to the exit in Eyestalk rooms (calculated from where you stand).", Ex.ShowEyestalkPath, function(v) Ex.ShowEyestalkPath = v RedrawAll() end)
AddDropdown(VisualsTab, "PathMode", "Path Style", "Lines draws a continuous line; Nodes draws one ball per point.", { "Lines", "Nodes" }, Ex.PathMode, function(v)
	if type(v) == "table" then v = v[1] end
	Ex.PathMode = v or "Lines"
	RedrawAll()
end)

AlertsTab:Section({ Title = "Items" })
AddToggle(AlertsTab, "NotifyItems", "Notify Items", "Shows a notification when a selected item appears in the level.", Ex.NotifyItems, function(v) Ex.NotifyItems = v end)
AddToggle(AlertsTab, "NotifyUnlistedItems", "Notify Unlisted Items", "Also notifies pickups that are not in the list below.", Ex.NotifyUnlistedItems, function(v) Ex.NotifyUnlistedItems = v end)
do
	local ddItems = AlertsTab:Dropdown({
		Title = "Items to notify",
		Desc = "Every item is in the list, but only the important ones are selected by default (Crucifix, Gold Gun, Lockpicks, Skeleton Key...).",
		Values = ITEM_NAMES,
		Value = ESSENTIAL_ITEMS,
		Multi = true,
		AllowNone = true,
		Callback = function(selected)
			local map = {}
			for _, n in ipairs(selected or {}) do map[n] = true end
			Ex.NotifyItemFilter = map
		end,
	})
	local function SetItems(list)
		local map = {}
		for _, n in ipairs(list) do map[n] = true end
		Ex.NotifyItemFilter = map
		pcall(function() ddItems:Select(list) end)
	end
	AlertsTab:Button({ Title = "Notify all items", Desc = "Selects every item in the list.", Callback = function()
		local all = {}
		for _, n in ipairs(ITEM_NAMES) do all[#all + 1] = n end
		SetItems(all)
	end })
	AlertsTab:Button({ Title = "Notify only essentials", Desc = "Back to the default selection.", Callback = function() SetItems(ESSENTIAL_ITEMS) end })
	AlertsTab:Button({ Title = "Notify nothing", Desc = "Clears the selection.", Callback = function() SetItems({}) end })
end
end)()

print("[R4NS0M] Loading Batch 4")
-- ============================================================================================
-- BATCH 4: etiquetas vivas del ESP (Time Lever con su tiempo, Water Pump hecha) y limpieza del Seek Path
-- ============================================================================================
;(function()
local hooked = setmetatable({}, { __mode = "k" })
local used = setmetatable({}, { __mode = "k" })

task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(function()
			for inst, e in pairs(Tracked) do
				local n = inst.Name
				if n == "TimerLever" then
					if not hooked[inst] then
						hooked[inst] = true
						local main = inst:FindFirstChild("Main")
						local snd = main and main:FindFirstChild("SoundToPlay")
						if snd then snd.Played:Once(function() used[inst] = true end) end
					end
					local label = "??:??"
					if used[inst] then
						label = "00:00"
					else
						local tt = inst:FindFirstChild("TakeTimer")
						local tl = tt and tt:FindFirstChild("TextLabel")
						local txt = tl and tl.Text
						if type(txt) == "string" and txt:match("^%d%d:%d%d$") then label = txt end
					end
					e.Label = "Time Lever [" .. label .. "]"
				elseif n == "WaterPump" then
					if not hooked[inst] then
						hooked[inst] = true
						local wheel = inst:FindFirstChild("Wheel")
						local snd = wheel and wheel:FindFirstChild("Sound")
						if snd then snd.Played:Once(function() used[inst] = true end) end
					end
					e.Label = used[inst] and "Water Pump [Done]" or "Water Pump"
				end
			end
		end)
	end
end)

-- Seek Path: al terminar la persecucion se borra el camino dibujado
Workspace.DescendantAdded:Connect(function(d)
	if d.Name == "SeekMovingNewClone" then
		d.Destroying:Once(function()
			if Ex.ClearSeekPaths then pcall(Ex.ClearSeekPaths) end
		end)
	end
end)
end)()

print("[R4NS0M] Loading Batch 5")
-- ============================================================================================
-- BATCH 5
--   Antis  : Bypass Seek, Bypass Figure
--   Alerts : Notify Ransom (aparece en Workspace antes del jumpscare)
-- ============================================================================================
;(function()
local RS = game:GetService("ReplicatedStorage")
local function Toast(t, d) pcall(FX.ShowToast, t, d or "", "", Color3.fromRGB(255, 200, 80)) end

Ex.BypassSeek = false
Ex.BypassFigure = false
Ex.NotifyRansom = true
Ex.AutoPositionSpoof = false

-- entidades tipo Rush: mientras exista una activa en el Workspace hace falta el spoof
local RUSHLIKE = { "RushMoving", "AmbushMoving", "A60", "A120", "GlitchRush", "GlitchAmbush", "BackdoorRush", "FrozenAmbush" }
local function RushPresent()
	for _, name in ipairs(RUSHLIKE) do
		local m = Workspace:FindFirstChild(name)
		if m and m:GetAttribute("Inactive") ~= true then return true end
	end
	return false
end

-- ------------------------------------------------------------------------------------------
-- Notify Ransom: el modelo entra al Workspace antes de que el cliente muestre el jumpscare
-- ------------------------------------------------------------------------------------------
local ransomSeen = setmetatable({}, { __mode = "k" })
local function CheckRansom(c)
	if not Ex.NotifyRansom or ransomSeen[c] then return end
	local n = c.Name:lower()
	if n:find("ransom", 1, true) or n == "a90" or n == "a-90" then
		ransomSeen[c] = true
		Toast("Ransom has spawned", "It appeared in the Workspace. Get ready before it reaches you.")
	end
end
Workspace.ChildAdded:Connect(CheckRansom)

-- ------------------------------------------------------------------------------------------
-- Combos: se activan/restauran los toggles que ya existen, sin pisar lo que ya tenias encendido
-- ------------------------------------------------------------------------------------------
local savedState = {}
local function Combo(tag, ids, on)
	for _, id in ipairs(ids) do
		local key = tag .. id
		if on then
			if savedState[key] == nil then savedState[key] = Ex[id] and true or false end
			if not Ex[id] then SetFeature(id, true) end
		else
			if savedState[key] == false then SetFeature(id, false) end
			savedState[key] = nil
		end
	end
end

-- Jumpscare del Seek: se desactivan los modulos del jumpscare mientras el bypass este activo
local function SeekJumpscareModules(on)
	local roots = {}
	local fr = RS:FindFirstChild("FloorReplicated")
	if fr then roots[#roots + 1] = fr end
	pcall(function()
		local rl = LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener
		roots[#roots + 1] = rl
	end)
	for _, r in ipairs(roots) do
		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("ModuleScript") then
				local l = d.Name:lower()
				if on then
					if l:find("seek", 1, true) and l:find("jumpscare", 1, true) and not l:find("_disabled", 1, true) then
						d:SetAttribute("R4NOrig", d.Name)
						d.Name = d.Name .. "_Disabled"
					end
				elseif d:GetAttribute("R4NOrig") then
					d.Name = d:GetAttribute("R4NOrig")
					d:SetAttribute("R4NOrig", nil)
				end
			end
		end
	end
end
do
	local fr = RS:FindFirstChild("FloorReplicated")
	if fr then
		fr.DescendantAdded:Connect(function(d)
			if Ex.BypassSeek and d:IsA("ModuleScript") then
				task.defer(SeekJumpscareModules, true)
			end
		end)
	end
end

local SEEK_IDS = { "BypassSeekObstructions", "RemoveSeekTrigger" }
local FIGURE_IDS = { "CrouchSpoof", "AutoHeartbeatMinigame", "FigureGodmode" }

-- Persecucion de Seek en curso
local chase = false
Workspace.DescendantAdded:Connect(function(d)
	if d.Name == "SeekMovingNewClone" or d.Name == "SeekMoving" then
		chase = true
		d.Destroying:Once(function() task.delay(1, function() chase = false end) end)
	end
end)

-- Position Spoof automatico: solo mientras el Seek persigue o hay un Figure cerca
local autoSpoof = false
task.spawn(function()
	while true do
		task.wait(0.2)
		pcall(function()
			local want = false
			if Ex.AutoPositionSpoof and RushPresent() then want = true end
			if Ex.BypassSeek and chase then want = true end
			if Ex.BypassFigure and Functions.GetNearestFigure then
				local ok, fig = pcall(Functions.GetNearestFigure)
				if ok and fig then want = true end
			end
			if want and not Ex.PositionSpoof then
				autoSpoof = true
				SetFeature("PositionSpoof", true)
			elseif not want and autoSpoof then
				autoSpoof = false
				if Ex.PositionSpoof then SetFeature("PositionSpoof", false) end
			end
		end)
	end
end)

-- ------------------------------------------------------------------------------------------
-- Interfaz
-- ------------------------------------------------------------------------------------------
AntisTab:Section({ Title = "Bypass Combos" })
AddToggle(AntisTab, "BypassSeek", "Bypass Seek",
	"Experimental. Disables the Seek jumpscare, bypasses its obstacles, deletes the trigger where supported (Old Hotel / Fools) and moves you underground automatically while the chase is running.",
	Ex.BypassSeek, function(v)
		Ex.BypassSeek = v
		Combo("seek:", SEEK_IDS, v)
		SeekJumpscareModules(v)
	end)
AddToggle(AntisTab, "BypassFigure", "Bypass Figure",
	"Experimental. Crouch Spoof + Auto Heartbeat Minigame + Figure Godmode, and moves you underground automatically while a Figure is near.",
	Ex.BypassFigure, function(v)
		Ex.BypassFigure = v
		Combo("fig:", FIGURE_IDS, v)
	end)

AddToggle(AntiCheatTab, "AutoPositionSpoof", "Auto Position Spoof",
	"Turns Position Spoof on only while a Rush-like entity (Rush, Ambush, A-60, A-120, Glitch...) exists, and returns you to normal as soon as it despawns. Leave the manual Position Spoof off to use it.",
	Ex.AutoPositionSpoof, function(v) Ex.AutoPositionSpoof = v end)

AlertsTab:Section({ Title = "Entities" })
AddToggle(AlertsTab, "NotifyRansom", "Notify Ransom", "Notifies as soon as Ransom enters the Workspace, before its jumpscare reaches you.", Ex.NotifyRansom, function(v) Ex.NotifyRansom = v end)
end)()

print("[R4NS0M] Loading Batch 6")
-- ============================================================================================
-- BATCH 6
--   Visuals : rendimiento del ESP (modo ligero + deteccion de lag) y lista de entidades con limite de distancia
--   Alerts  : aviso cuando una entidad desaparece
--   Automation : lista de items ignorados del Auto Interact
-- ============================================================================================
;(function()
local Players = game:GetService("Players")
local RunSvc = game:GetService("RunService")
local function Toast(t, d) pcall(FX.ShowToast, t, d or "", "", Color3.fromRGB(255, 200, 80)) end

Ex.PerfMode = false
Ex.AutoPerf = true
Ex.NotifyDespawn = false
Cfg.RefreshRate = Cfg.RefreshRate or 4

-- ------------------------------------------------------------------------------------------
-- Rendimiento del ESP
--   nivel 0: normal | 1-3: menos Highlights (se usan cajas, mas baratas), menos objetos y refresco mas lento
-- ------------------------------------------------------------------------------------------
local MAXHL    = { 20, 12, 8, 4 }
local INTERVAL = { 0, 0.15, 0.3, 0.6 }
local CAP      = { math.huge, 100, 60, 35 }
local perfLevel = 0
local function ApplyPerf()
	local eff = perfLevel
	if Ex.PerfMode then eff = math.max(eff, 2) end
	Watch.MaxHL = MAXHL[eff + 1]
	Watch.PerfInterval = INTERVAL[eff + 1]
	Watch.PerfCap = CAP[eff + 1]
end
ApplyPerf()
do
	local frames, last = 0, os.clock()
	RunSvc.RenderStepped:Connect(function() frames = frames + 1 end)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			local fps = frames / math.max(now - last, 0.001)
			frames, last = 0, now
			if Ex.AutoPerf then
				-- histeresis amplia para no oscilar (en celulares con tope de 30 FPS no baja de nivel)
				if fps < 22 and perfLevel < 3 then perfLevel = perfLevel + 1
				elseif fps > 40 and perfLevel > 0 then perfLevel = perfLevel - 1 end
			elseif perfLevel ~= 0 then
				perfLevel = 0
			end
			ApplyPerf()
		end
	end)
end

-- ------------------------------------------------------------------------------------------
-- Aviso de despawn: solo para entidades que antes se vieron aparecer y que estan en tu lista de avisos
-- ------------------------------------------------------------------------------------------
local live = setmetatable({}, { __mode = "k" })
local function Track(m)
	if not m:IsA("Model") or Players:GetPlayerFromCharacter(m) then return end
	local ok, label = pcall(EntityLabel, m.Name, false)
	if ok and label and label ~= "Mandrake" then live[m] = label end
end
for _, c in ipairs(Workspace:GetChildren()) do Track(c) end
Workspace.ChildAdded:Connect(Track)
local lastDespawn = {}
Workspace.ChildRemoved:Connect(function(m)
	local label = live[m]
	if not label then return end
	live[m] = nil
	if not Ex.NotifyDespawn then return end
	if not (Ex.NotifyFilter and Ex.NotifyFilter[label]) then return end
	local now = os.clock()
	if lastDespawn[label] and now - lastDespawn[label] < 3 then return end
	lastDespawn[label] = now
	Toast(label .. " has despawned", "You are safe from it now.")
end)

-- ------------------------------------------------------------------------------------------
-- Interfaz
-- ------------------------------------------------------------------------------------------
VisualsTab:Section({ Title = "ESP Performance" })
AddToggle(VisualsTab, "PerfMode", "ESP Performance Mode", "Draws fewer Highlights (cheaper boxes instead), fewer objects and refreshes slower. Use it if the game lags.", Ex.PerfMode, function(v) Ex.PerfMode = v ApplyPerf() end)
AddToggle(VisualsTab, "AutoPerf", "Auto Performance", "Lightens the ESP by itself when your FPS drops, and restores it when they recover.", Ex.AutoPerf, function(v) Ex.AutoPerf = v end)
AddSlider(VisualsTab, "RefreshRate", "ESP Refresh Rate", "How many times per second the ESP updates (lower = less lag).", 2, 10, Cfg.RefreshRate, function(v) Cfg.RefreshRate = v end)

VisualsTab:Section({ Title = "Entity Distance Limit" })
do
	local names = {}
	for k in pairs(ENTITY_MODES) do names[#names + 1] = k end
	table.sort(names)
	local sel = {}
	for k in pairs(Watch.Limited) do sel[#sel + 1] = k end
	table.sort(sel)
	VisualsTab:Dropdown({
		Title = "Entities with distance limit",
		Desc = "These entities obey Max Distance and disappear when far away. Remove one from the list to go back to the normal behavior (always shown).",
		Values = names,
		Value = sel,
		Multi = true,
		AllowNone = true,
		Callback = function(selected)
			local set = {}
			for _, n in ipairs(selected or {}) do set[n] = true end
			Watch.Limited = set
		end,
	})
end

AlertsTab:Section({ Title = "Entity Despawn" })
AddToggle(AlertsTab, "NotifyDespawn", "Notify Despawn", "Tells you when an entity you were notified about is gone. Uses the same entity selection as the spawn alerts.", Ex.NotifyDespawn, function(v) Ex.NotifyDespawn = v end)

-- ------------------------------------------------------------------------------------------
-- Auto Interact: items ignorados
-- ------------------------------------------------------------------------------------------
local JUNK = { "Paper Plane", "Fih Flakes", "Fih Food", "Paper Cup", "Mug", "Honcho Mug", "Lunch Box", "Leftovers", "Broken Monitor", "Broken Lamp", "Bottle Crate", "Coin Roll", "Large Screw", "Briefcase", "Nanner Peel", "Tip Jar", "Honey Pot" }
local function ToSet(list) local s = {} for _, n in ipairs(list) do s[n] = true end return s end
Ex.AIItemIgnore = ToSet(JUNK)

AutomationTab:Section({ Title = "Auto Interact Ignored Items" })
do
	local dd = AutomationTab:Dropdown({
		Title = "Ignored Items",
		Desc = "Auto Interact will not pick these up. Default: Paper Plane, Fih Flakes and other useless items.",
		Values = ITEM_NAMES,
		Value = JUNK,
		Multi = true,
		AllowNone = true,
		Callback = function(selected) Ex.AIItemIgnore = ToSet(selected or {}) end,
	})
	local function SetItems(list)
		Ex.AIItemIgnore = ToSet(list)
		pcall(function() dd:Select(list) end)
	end
	AutomationTab:Button({ Title = "Ignore all items", Desc = "Auto Interact will not pick up any item.", Callback = function()
		local all = {}
		for _, n in ipairs(ITEM_NAMES) do all[#all + 1] = n end
		SetItems(all)
	end })
	AutomationTab:Button({ Title = "Ignore no items", Desc = "Auto Interact will pick up every item.", Callback = function() SetItems({}) end })
	AutomationTab:Button({ Title = "Restore default ignored items", Desc = "Back to the useless items list.", Callback = function() SetItems(JUNK) end })
end
end)()

print("[R4NS0M] Loading Batch 7")
-- ============================================================================================
-- BATCH 7: SPEEDRUN TIMER
--   Estilo timer de speedrun: digitos grandes, estados por color, splits por sala con delta contra tu PB.
--   Arranca solo al moverte (joystick, WASD/flechas, saltar, agacharse, Anticheat Manipulation); la camara no cuenta.
-- ============================================================================================
;(function()
local UIS = game:GetService("UserInputService")
local RunSvc = game:GetService("RunService")
local HttpSvc = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local function Toast(t, d) pcall(FX.ShowToast, t, d or "", "", Color3.fromRGB(255, 200, 80)) end

Ex.TimerShow = true
Ex.TimerPosition = "Top Right"
Ex.TimerScale = 100
Ex.TimerOpacity = 80
Ex.TimerSplits = true
Ex.TimerButtons = true
Ex.TimerAutoStart = true
Ex.TimerAutoSplit = true
Ex.TimerStopRoom = 0
Ex.Key_TimerToggle = "K"
Ex.Key_TimerStop = "O"
Ex.Key_TimerReset = "L"

-- ------------------------------------------------------------------------------------------
-- Estado y PB (guardado por piso)
-- ------------------------------------------------------------------------------------------
local FILE = "R4NS0M_Speedrun.json"
local PB = {}
pcall(function()
	if isfile and isfile(FILE) then PB = HttpSvc:JSONDecode(readfile(FILE)) end
end)
local function SavePB() pcall(function() if writefile then writefile(FILE, HttpSvc:JSONEncode(PB)) end end) end

local T = { state = "ready", acc = 0, t0 = 0, list = {}, highest = 0, delta = nil, newPB = false }
local function Elapsed() return T.state == "running" and (T.acc + os.clock() - T.t0) or T.acc end
local function CurRoom() return tonumber(LocalPlayer:GetAttribute("CurrentRoom")) or 0 end
local function FloorName()
	local gd = RS:FindFirstChild("GameData")
	local f = gd and gd:FindFirstChild("Floor")
	local v = f and tostring(f.Value) or ""
	return v ~= "" and v or "Lobby"
end

-- ------------------------------------------------------------------------------------------
-- Formato
-- ------------------------------------------------------------------------------------------
local function Fmt(t)
	if t < 0 then t = 0 end
	local ms = math.floor((t % 1) * 1000)
	local total = math.floor(t)
	local s, m, h = total % 60, math.floor(total / 60) % 60, math.floor(total / 3600)
	local main = h > 0 and string.format("%d:%02d:%02d", h, m, s) or string.format("%02d:%02d", m, s)
	return main, string.format(".%03d", ms)
end
local function FmtFull(t) local a, b = Fmt(t) return a .. b end
local function FmtDelta(d)
	local sign = d < 0 and "-" or "+"
	d = math.abs(d)
	if d >= 60 then return sign .. string.format("%d:%04.1f", math.floor(d / 60), d % 60) end
	return sign .. string.format("%.2f", d)
end

local C = {
	ready = Color3.fromRGB(170, 170, 180), run = Color3.fromRGB(80, 255, 120), behind = Color3.fromRGB(255, 90, 90),
	pause = Color3.fromRGB(255, 210, 80), done = Color3.fromRGB(110, 175, 255), gold = Color3.fromRGB(255, 215, 0),
	dim = Color3.fromRGB(150, 150, 160), text = Color3.fromRGB(230, 230, 235),
}

-- ------------------------------------------------------------------------------------------
-- Interfaz del timer
-- ------------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "R4NS0M_Timer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local W = 230
local function S(n) return math.max(1, math.floor(n * (Ex.TimerScale or 100) / 100 + 0.5)) end

local function Label(parent, name)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.TextColor3 = C.text
	l.Font = Enum.Font.GothamBold
	l.TextStrokeTransparency = 0.6
	l.Parent = parent
	return l
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
panel.BorderSizePixel = 0
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.Parent = gui
local corner = Instance.new("UICorner", panel)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(70, 70, 82)
stroke.Thickness = 1
local pad = Instance.new("UIPadding", panel)
local list = Instance.new("UIListLayout", panel)
list.SortOrder = Enum.SortOrder.LayoutOrder

-- cabecera (se arrastra desde aqui)
local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundTransparency = 1
header.LayoutOrder = 1
header.Parent = panel
local title = Label(header, "Title")
title.Text = "R4NS0M  SPEEDRUN"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = C.dim
title.Size = UDim2.fromScale(0.6, 1)
local info = Label(header, "Info")
info.Font = Enum.Font.Gotham
info.TextXAlignment = Enum.TextXAlignment.Right
info.TextColor3 = C.dim
info.Position = UDim2.fromScale(0.5, 0)
info.Size = UDim2.fromScale(0.5, 1)

-- splits
local splitsFrame = Instance.new("Frame")
splitsFrame.Name = "Splits"
splitsFrame.BackgroundTransparency = 1
splitsFrame.AutomaticSize = Enum.AutomaticSize.Y
splitsFrame.LayoutOrder = 2
splitsFrame.Parent = panel
local sl = Instance.new("UIListLayout", splitsFrame)
sl.SortOrder = Enum.SortOrder.LayoutOrder
local rows = {}
for i = 1, 5 do
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.LayoutOrder = i
	f.Visible = false
	f.Parent = splitsFrame
	local n = Label(f, "N") n.TextXAlignment = Enum.TextXAlignment.Left n.Size = UDim2.fromScale(0.34, 1) n.TextColor3 = C.dim
	local d = Label(f, "D") d.Font = Enum.Font.RobotoMono d.TextXAlignment = Enum.TextXAlignment.Right d.Position = UDim2.fromScale(0.34, 0) d.Size = UDim2.fromScale(0.28, 1)
	local t = Label(f, "T") t.Font = Enum.Font.RobotoMono t.TextXAlignment = Enum.TextXAlignment.Right t.Position = UDim2.fromScale(0.62, 0) t.Size = UDim2.fromScale(0.38, 1)
	rows[i] = { f = f, n = n, d = d, t = t }
end

-- digitos grandes
local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.BackgroundTransparency = 1
timerFrame.LayoutOrder = 3
timerFrame.Parent = panel
local big = Label(timerFrame, "Big")
big.Font = Enum.Font.RobotoMono
big.RichText = true
big.TextXAlignment = Enum.TextXAlignment.Right
big.Size = UDim2.fromScale(1, 1)

-- PB y delta
local sub = Instance.new("Frame")
sub.Name = "Sub"
sub.BackgroundTransparency = 1
sub.LayoutOrder = 4
sub.Parent = panel
local pbLabel = Label(sub, "PB") pbLabel.Font = Enum.Font.RobotoMono pbLabel.TextXAlignment = Enum.TextXAlignment.Left pbLabel.TextColor3 = C.dim pbLabel.Size = UDim2.fromScale(0.6, 1)
local deltaLabel = Label(sub, "Delta") deltaLabel.Font = Enum.Font.RobotoMono deltaLabel.TextXAlignment = Enum.TextXAlignment.Right deltaLabel.Position = UDim2.fromScale(0.5, 0) deltaLabel.Size = UDim2.fromScale(0.5, 1)

-- botones
local btnFrame = Instance.new("Frame")
btnFrame.Name = "Buttons"
btnFrame.BackgroundTransparency = 1
btnFrame.LayoutOrder = 5
btnFrame.Parent = panel
local bl = Instance.new("UIListLayout", btnFrame)
bl.FillDirection = Enum.FillDirection.Horizontal
bl.SortOrder = Enum.SortOrder.LayoutOrder
local function Button(text, order)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	b.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
	b.TextColor3 = C.text
	b.BorderSizePixel = 0
	b.Parent = btnFrame
	Instance.new("UICorner", b)
	return b
end
local btnMain = Button("Start", 1)
local btnStop = Button("Stop", 2)
local btnReset = Button("Reset", 3)

-- ------------------------------------------------------------------------------------------
-- Tamano / posicion / opacidad
-- ------------------------------------------------------------------------------------------
local PRESETS = {
	["Top Left"]      = { Vector2.new(0, 0),   UDim2.new(0, 12, 0, 64) },
	["Top Center"]    = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 64) },
	["Top Right"]     = { Vector2.new(1, 0),   UDim2.new(1, -12, 0, 64) },
	["Middle Left"]   = { Vector2.new(0, 0.5), UDim2.new(0, 12, 0.5, 0) },
	["Middle Right"]  = { Vector2.new(1, 0.5), UDim2.new(1, -12, 0.5, 0) },
	["Bottom Left"]   = { Vector2.new(0, 1),   UDim2.new(0, 12, 1, -16) },
	["Bottom Center"] = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -16) },
	["Bottom Right"]  = { Vector2.new(1, 1),   UDim2.new(1, -12, 1, -16) },
}
local PRESET_NAMES = { "Top Left", "Top Center", "Top Right", "Middle Left", "Middle Right", "Bottom Left", "Bottom Center", "Bottom Right" }
local function Place(name)
	local p = PRESETS[name]
	if not p then return end
	panel.AnchorPoint, panel.Position = p[1], p[2]
end

local RenderAll -- forward
local function Layout()
	local inner = S(W) - S(12)
	panel.Size = UDim2.fromOffset(S(W), 0)
	corner.CornerRadius = UDim.new(0, S(6))
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, S(5)), UDim.new(0, S(6))
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, S(6)), UDim.new(0, S(6))
	list.Padding = UDim.new(0, S(2))
	panel.BackgroundTransparency = 1 - (Ex.TimerOpacity or 80) / 100
	stroke.Transparency = math.clamp(panel.BackgroundTransparency + 0.2, 0, 1)

	header.Size = UDim2.fromOffset(inner, S(16))
	title.TextSize, info.TextSize = S(10), S(10)
	splitsFrame.Size = UDim2.fromOffset(inner, 0)
	splitsFrame.Visible = Ex.TimerSplits
	for _, r in ipairs(rows) do
		r.f.Size = UDim2.fromOffset(inner, S(16))
		r.n.TextSize, r.d.TextSize, r.t.TextSize = S(11), S(11), S(11)
	end
	timerFrame.Size = UDim2.fromOffset(inner, S(46))
	big.TextSize = S(38)
	sub.Size = UDim2.fromOffset(inner, S(16))
	pbLabel.TextSize, deltaLabel.TextSize = S(11), S(11)
	btnFrame.Visible = Ex.TimerButtons
	btnFrame.Size = UDim2.fromOffset(inner, S(26))
	bl.Padding = UDim.new(0, S(4))
	for _, b in ipairs({ btnMain, btnStop, btnReset }) do
		b.Size = UDim2.new(1 / 3, -S(3), 1, 0)
		b.TextSize = S(11)
	end
	gui.Enabled = Ex.TimerShow
	if RenderAll then RenderAll() end
end

-- ------------------------------------------------------------------------------------------
-- Dibujo del estado
-- ------------------------------------------------------------------------------------------
local lastBig = ""
local function Colour()
	if T.state == "ready" then return C.ready end
	if T.state == "paused" then return C.pause end
	if T.state == "finished" then return T.newPB and C.gold or C.done end
	if T.delta and T.delta > 0 then return C.behind end
	return C.run
end
local function DrawBig()
	local main, ms = Fmt(Elapsed())
	local txt = string.format('%s<font size="%d">%s</font>', main, S(22), ms)
	if txt ~= lastBig then lastBig = txt big.Text = txt end
	big.TextColor3 = Colour()
end
local function DrawInfo()
	local fl = FloorName()
	info.Text = fl .. "  -  Room " .. CurRoom()
	local pb = PB[fl]
	pbLabel.Text = pb and ("PB " .. FmtFull(pb.pb)) or "PB --:--.---"
	if T.delta then
		deltaLabel.Text = FmtDelta(T.delta)
		deltaLabel.TextColor3 = T.delta > 0 and C.behind or C.run
	else
		deltaLabel.Text = ""
	end
	local labels = { ready = "Start", running = "Pause", paused = "Resume", finished = "Restart" }
	btnMain.Text = labels[T.state]
end
local function DrawSplits()
	local n = #T.list
	local first = math.max(1, n - 4)
	for i = 1, 5 do
		local rec, r = T.list[first + i - 1], rows[i]
		if rec then
			r.f.Visible = true
			r.n.Text = "Room " .. rec.room
			r.t.Text = FmtFull(rec.t)
			if rec.delta then
				r.d.Text = FmtDelta(rec.delta)
				r.d.TextColor3 = rec.delta > 0 and C.behind or C.run
			else
				r.d.Text = "-"
				r.d.TextColor3 = C.dim
			end
		else
			r.f.Visible = false
		end
	end
end
RenderAll = function() DrawBig() DrawInfo() DrawSplits() end

-- ------------------------------------------------------------------------------------------
-- Control del timer
-- ------------------------------------------------------------------------------------------
local function Reset()
	T.state, T.acc, T.t0, T.list, T.highest, T.delta, T.newPB = "ready", 0, 0, {}, 0, nil, false
	RenderAll()
end
local function Start()
	if T.state ~= "ready" then return end
	T.acc, T.t0, T.list, T.highest, T.delta, T.newPB = 0, os.clock(), {}, CurRoom(), nil, false
	T.state = "running"
	RenderAll()
end
local function Pause()
	if T.state ~= "running" then return end
	T.acc = Elapsed()
	T.state = "paused"
	RenderAll()
end
local function Resume()
	if T.state ~= "paused" then return end
	T.t0 = os.clock()
	T.state = "running"
	RenderAll()
end
local function Finish()
	if T.state ~= "running" and T.state ~= "paused" then return end
	T.acc = Elapsed()
	T.state = "finished"
	local fl = FloorName()
	-- solo cuenta como PB si llegaste al menos a 10 salas (evita guardar paradas accidentales)
	if fl ~= "Lobby" and #T.list >= 10 and (not PB[fl] or T.acc < PB[fl].pb) then
		local splits = {}
		for _, rec in ipairs(T.list) do splits[tostring(rec.room)] = rec.t end
		PB[fl] = { pb = T.acc, splits = splits }
		SavePB()
		T.newPB = true
		Toast("New personal best!", FmtFull(T.acc) .. "  -  " .. fl)
	else
		Toast("Run finished", FmtFull(T.acc))
	end
	RenderAll()
end
local function Toggle()
	if T.state == "ready" then Start()
	elseif T.state == "running" then Pause()
	elseif T.state == "paused" then Resume()
	else Reset() Start() end
end
Ex.TimerToggle, Ex.TimerFinish, Ex.TimerReset = Toggle, Finish, Reset

btnMain.Activated:Connect(Toggle)
btnStop.Activated:Connect(Finish)
btnReset.Activated:Connect(Reset)

-- split automatico al entrar a una sala nueva
LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
	local room = CurRoom()
	if T.state == "running" and Ex.TimerAutoSplit and room > T.highest then
		T.highest = room
		local t = Elapsed()
		local pb = PB[FloorName()]
		local ref = pb and pb.splits and pb.splits[tostring(room)]
		local delta = ref and (t - ref) or nil
		T.list[#T.list + 1] = { room = room, t = t, delta = delta }
		T.delta = delta or T.delta
		if Ex.TimerStopRoom and Ex.TimerStopRoom > 0 and room >= Ex.TimerStopRoom then
			Finish()
			return
		end
	end
	RenderAll()
end)

-- ------------------------------------------------------------------------------------------
-- Arranque automatico: joystick, WASD/flechas, saltar, agacharse y Anticheat Manipulation (la camara no cuenta)
-- ------------------------------------------------------------------------------------------
local START_KEYS = {
	W = true, A = true, S = true, D = true, Up = true, Down = true, Left = true, Right = true,
	Space = true, LeftControl = true, C = true, ButtonA = true, ButtonB = true,
}
local function AutoStart() if Ex.TimerAutoStart and T.state == "ready" then Start() end end

UIS.InputBegan:Connect(function(input)
	if UIS:GetFocusedTextBox() then return end
	local name = input.KeyCode.Name
	if name == Ex.Key_TimerToggle then Toggle() return end
	if name == Ex.Key_TimerStop then Finish() return end
	if name == Ex.Key_TimerReset then Reset() return end
	if START_KEYS[name] then AutoStart() end
end)
UIS.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 and input.Position.Magnitude > 0.25 then AutoStart() end
end)

-- botones de saltar / agacharse del movil
do
	local hooked = setmetatable({}, { __mode = "k" })
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(function()
				local ui = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
				local mf = ui and ui:FindFirstChild("MainFrame")
				local mb = mf and mf:FindFirstChild("MobileButtons")
				if not mb then return end
				for _, b in ipairs(mb:GetChildren()) do
					local n = b.Name:lower()
					if b:IsA("GuiButton") and not hooked[b] and (n:find("jump", 1, true) or n:find("crouch", 1, true) or n:find("duck", 1, true)) then
						hooked[b] = true
						b.MouseButton1Down:Connect(AutoStart)
					end
				end
			end)
		end
	end)
end

-- movimiento real del personaje (joystick del movil/consola o teclado) y Anticheat Manipulation
task.spawn(function()
	while true do
		task.wait(0.1)
		if T.state == "ready" and Ex.TimerAutoStart then
			pcall(function()
				local _, hum = GetParts()
				if (hum and hum.MoveDirection.Magnitude > 0.1) or Ex.ACM then Start() end
			end)
		end
	end
end)

-- refresco de los digitos (30 veces por segundo, solo mientras corre)
do
	local acc = 0
	RunSvc.RenderStepped:Connect(function(dt)
		if T.state ~= "running" or not Ex.TimerShow then return end
		acc = acc + dt
		if acc >= 1 / 30 then
			acc = 0
			DrawBig()
		end
	end)
end
task.spawn(function()
	while true do
		task.wait(1)
		if Ex.TimerShow then pcall(DrawInfo) end
	end
end)

-- ------------------------------------------------------------------------------------------
-- Arrastrar la ventana (cambia la posicion a libre)
-- ------------------------------------------------------------------------------------------
do
	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(i.Position.X, i.Position.Y)
			local ap = panel.AbsolutePosition
			panel.AnchorPoint = Vector2.zero
			panel.Position = UDim2.fromOffset(ap.X, ap.Y)
			startPos = Vector2.new(ap.X, ap.Y)
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart
			local vp = gui.AbsoluteSize
			local sz = panel.AbsoluteSize
			panel.Position = UDim2.fromOffset(
				math.clamp(startPos.X + d.X, 0, math.max(vp.X - sz.X, 0)),
				math.clamp(startPos.Y + d.Y, 0, math.max(vp.Y - sz.Y, 0))
			)
		end
	end)
end

Place(Ex.TimerPosition)
Layout()

-- ------------------------------------------------------------------------------------------
-- Opciones en el hub (Misc)
-- ------------------------------------------------------------------------------------------
MiscTab:Section({ Title = "Speedrun Timer" })
AddToggle(MiscTab, "TimerShow", "Show Speedrun Timer", "Shows the timer on screen. Drag its title bar to move it anywhere.", Ex.TimerShow, function(v) Ex.TimerShow = v Layout() end)
MiscTab:Button({ Title = "Start / Pause / Resume", Desc = "Starts the timer, pauses it, or resumes it (Restart after a finished run).", Callback = Toggle })
MiscTab:Button({ Title = "Stop (finish run)", Desc = "Ends the run. If you reached at least 10 rooms and it is faster than your best, it is saved as your personal best for that floor.", Callback = Finish })
MiscTab:Button({ Title = "Reset", Desc = "Clears the timer and the splits so it can start again.", Callback = Reset })
AddDropdown(MiscTab, "TimerPosition", "Timer Position", "Preset corners and edges. Dragging the title bar overrides it.", PRESET_NAMES, Ex.TimerPosition, function(v)
	if type(v) == "table" then v = v[1] end
	if v then Ex.TimerPosition = v Place(v) end
end)
AddSlider(MiscTab, "TimerScale", "Timer Size (%)", "Scales the whole timer.", 50, 150, Ex.TimerScale, function(v) Ex.TimerScale = v Layout() end)
AddSlider(MiscTab, "TimerOpacity", "Timer Background (%)", "How solid the timer background is.", 0, 100, Ex.TimerOpacity, function(v) Ex.TimerOpacity = v Layout() end)
AddToggle(MiscTab, "TimerSplits", "Show Splits", "Shows the last room splits with their difference against your personal best.", Ex.TimerSplits, function(v) Ex.TimerSplits = v Layout() end)
AddToggle(MiscTab, "TimerButtons", "Show Buttons", "Shows the Start / Stop / Reset buttons on the timer (useful on mobile).", Ex.TimerButtons, function(v) Ex.TimerButtons = v Layout() end)
AddToggle(MiscTab, "TimerAutoStart", "Auto Start On Move", "Starts by itself the first time you move: joystick, WASD / arrows, jump, crouch or Anticheat Manipulation. Moving the camera does not count.", Ex.TimerAutoStart, function(v) Ex.TimerAutoStart = v end)
AddToggle(MiscTab, "TimerAutoSplit", "Auto Split Rooms", "Records a split each time you enter a new room.", Ex.TimerAutoSplit, function(v) Ex.TimerAutoSplit = v end)
AddSlider(MiscTab, "TimerStopRoom", "Auto Stop At Room", "Finishes the run when you reach this room (0 = off).", 0, 300, Ex.TimerStopRoom, function(v) Ex.TimerStopRoom = v end)
end)()

print("[R4NS0M] Loaded more UI")
print("[R4NS0M] Loading Keybinds Tab")
----------------------------------------------------
-- KEYBINDS TAB
----------------------------------------------------
KeybindsTab:Section({ Title = "Hub" })
AddKeybind(KeybindsTab, "Key_Hub", "Open / Close Hub", "Shows or hides this menu with one key (default: Right Shift).", Ex.Key_Hub)
KeybindsTab:Section({ Title = "Movement & Anticheat Manipulator" })
AddKeybind(KeybindsTab, "Key_ACM", "Anticheat Manipulator", "Turns the Anticheat Manipulator (Velocity Manipulation) on or off.", Ex.Key_ACM)
AddKeybind(KeybindsTab, "Key_Noclip", "Noclip", "Turns Noclip on or off.", Ex.Key_Noclip)
AddKeybind(KeybindsTab, "Key_Fly", "Fly", "Turns Fly on or off.", Ex.Key_Fly)
AddKeybind(KeybindsTab, "Key_Speed", "Speed Boost", "Turns Speed Boost on or off.", Ex.Key_Speed)
AddKeybind(KeybindsTab, "Key_SpeedHack", "Speed Hack", "Turns Speed Hack (real walk speed) on or off. On mobile there is a floating SPD button.", Ex.Key_SpeedHack)
AddKeybind(KeybindsTab, "Key_TimerToggle", "Timer: Start / Pause", "Starts, pauses or resumes the speedrun timer.", Ex.Key_TimerToggle)
AddKeybind(KeybindsTab, "Key_TimerStop", "Timer: Stop", "Finishes the speedrun timer run.", Ex.Key_TimerStop)
AddKeybind(KeybindsTab, "Key_TimerReset", "Timer: Reset", "Resets the speedrun timer.", Ex.Key_TimerReset)
AddKeybind(KeybindsTab, "Key_Slide", "Slide", "Does a slide (Slide must be enabled in the Player tab).", Ex.Key_Slide)
AddKeybind(KeybindsTab, "Key_PosSpoof", "Position Spoof", "Turns Position Spoof on or off.", Ex.Key_PosSpoof)

-- Diagnostico de movimiento (para Jump / Slide nativos)
MiscTab:Section({ Title = "Movement Diagnostics" })
MiscTab:Button({
    Title = "Copy Character Info",
    Desc = "Copies the character's attributes, Humanoid values and any remote named like jump, slide, crouch or speed. Send it if Jump or Slide still misbehave in your game mode.",
    Callback = function()
        local out = {}
        local char = LocalPlayer.Character
        for _, pair in ipairs({ { "Character", char }, { "Player", LocalPlayer } }) do
            if pair[2] then
                for k, v in pairs(pair[2]:GetAttributes()) do
                    out[#out + 1] = string.format("%s attr %s = %s", pair[1], k, tostring(v))
                end
            end
        end
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            out[#out + 1] = string.format("Humanoid WalkSpeed=%s JumpPower=%s JumpHeight=%s UseJumpPower=%s",
                tostring(hum.WalkSpeed), tostring(hum.JumpPower), tostring(hum.JumpHeight), tostring(hum.UseJumpPower))
        end
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") then
                local l = d.Name:lower()
                if l:find("jump", 1, true) or l:find("slide", 1, true) or l:find("crouch", 1, true) or l:find("speed", 1, true) then
                    out[#out + 1] = d.ClassName .. " " .. d:GetFullName()
                end
            end
        end
        local text = #out > 0 and table.concat(out, "\n") or "(nothing found)"
        if setclipboard then
            setclipboard(text)
            WindUI:Notify({ Title = "Debug", Content = "Copied " .. #out .. " lines.", Duration = 3 })
        else
            print(text)
            WindUI:Notify({ Title = "Debug", Content = "No clipboard support; printed to console.", Duration = 3 })
        end
    end
})

FX.UpdateButtons()

print("[R4NS0M] Loaded Keybinds Tab")
print("[R4NS0M] Loading Config presets")
----------------------------------------------------
-- Guardar / cargar (las teclas y ajustes se guardan; ACM, Fly y Noclip siempre arrancan apagados)
----------------------------------------------------
local EXTRA_KEYS = {
    "Notify", "NotifyStyle", "NotifySound", "NotifyVolume", "NotifyDuration", "NotifyCooldown", "NotifyTips",
    "NotifySoundId", "NotifyIconId",
    "Speed", "SpeedValue", "SpeedMethod", "SpeedHack", "SpeedHackValue", "DisableAnticheat", "VelocityManipulationMode", "PositionSpoof", "CrouchSpoof", "AutoHeartbeatMinigame", "BypassGiggle", "BypassDupe", "BypassEyes", "BypassLookman", "BypassGloombatEggs", "BypassSeekObstructions", "BypassVacuum", "BypassKillbricks", "BypassSeekingWall", "BypassSnare", "BypassBanana", "BypassJeff", "RemoveScreech", "RemoveHalt", "RemoveA90", "RemoveDread", "RemoveSurge", "NoScreechDamage", "NoHaltDamage", "NoA90Damage", "NoSurgeDamage", "RemoveSeekTrigger", "RemoveFigure", "AutoRevive", "FigureGodmode", "RemoveBasementGate", "RemovePaintingsDoor", "RemoveSkeletonDoor", "Key_PosSpoof", "NotifyLibraryCode", "GuessLibraryCode", "AutoSteerMinecart", "BypassSeek", "BypassFigure", "NotifyRansom", "TimerShow", "TimerPosition", "TimerScale", "TimerOpacity", "TimerSplits", "TimerButtons", "TimerAutoStart", "TimerAutoSplit", "TimerStopRoom", "AutoPositionSpoof", "NotifyDespawn", "PerfMode", "AutoPerf", "ShowSeekPath", "ShowEyestalkPath", "PathMode", "NotifyItems", "NotifyUnlistedItems", "BtnSpeedHack", "Jump", "JumpPower", "InfJump", "Slide", "SlideSpeed", "FlySpeed",
    "Fullbright", "VoidGuard", "AutoBreakerBox", "InfiniteItems", "InfiniteItemsList", "AutoInteract", "PromptReach", "PromptClip", "DisableIdleKick", "MeldStopGrowth", "MeldRemove", "FloatButtons", "BtnACM", "BtnFly", "InstantPrompt",
    "NotifyOxygen", "NotifyHaste", "NoClosetDelay", "NoAcceleration", "DoorReach", "NoFootsteps", "NoPromptSounds",
    "Key_ACM", "Key_Noclip", "Key_Fly", "Key_Speed", "Key_SpeedHack", "Key_TimerToggle", "Key_TimerStop", "Key_TimerReset", "Key_Slide", "Key_Hub",
}

ExtraSerialize = function()
    local out = { NotifyFilter = Ex.NotifyFilter }
    for _, k in ipairs(EXTRA_KEYS) do out[k] = Ex[k] end
    return out
end

ExtraApply = function(data)
    if type(data) ~= "table" then return end
    for _, k in ipairs(EXTRA_KEYS) do
        local v = data[k]
        if v ~= nil and type(v) == type(Ex[k]) then
            Ex[k] = v
            if Setters[k] then Setters[k](v) end
        end
    end
    if type(data.NotifyFilter) == "table" then
        for name, on in pairs(data.NotifyFilter) do
            if type(on) == "boolean" then Ex.NotifyFilter[name] = on end
        end
        Setters.NotifyFilter(NotifySelected())
    end
    FX.UpdateButtons()
end
end

----------------------------------------------------
-- Guardar / cargar config de Visuals
----------------------------------------------------
local SCALAR_KEYS = {
    "MaxDistance", "MaxObjects", "RefreshRate", "TextSize", "Font", "ShowName", "ShowDistance", "Unit",
    "TracerOrigin", "TracerThickness", "PlayerNames", "UnlistedItems", "UnlistedEntities", "RoomEntities", "HideLooted", "AutoPreset",
}

local function VisualsSerialize()
    local out = { Cats = {}, ItemFilter = Cfg.ItemFilter, EntityFilter = Cfg.EntityFilter, FillTransparency = Cfg.FillTransparency }
    for _, k in ipairs(SCALAR_KEYS) do out[k] = Cfg[k] end
    if ExtraSerialize then out.Extra = ExtraSerialize() end
    for id, c in pairs(Cfg.Categories) do
        out.Cats[id] = { Enabled = c.Enabled, Tracer = c.Tracer, Color = { c.Color.R, c.Color.G, c.Color.B } }
    end
    return out
end

local function VisualsApply(data)
    if type(data) ~= "table" then return end
    if ExtraApply then pcall(ExtraApply, data.Extra) end

    for _, k in ipairs(SCALAR_KEYS) do
        if data[k] ~= nil and (k ~= "Font" or FONT_MAP[data[k]]) then
            Cfg[k] = data[k]
            if Setters[k] then Setters[k](data[k]) end
        end
    end

    if type(data.FillTransparency) == "number" then
        Cfg.FillTransparency = data.FillTransparency
        Setters.FillPercent(math.floor((1 - data.FillTransparency) * 100))
    end

    if type(data.Cats) == "table" then
        for id, c in pairs(data.Cats) do
            local cat = Cfg.Categories[id]
            if cat and type(c) == "table" then
                if c.Enabled ~= nil then
                    cat.Enabled = c.Enabled
                    if Setters["cat_" .. id] then Setters["cat_" .. id](c.Enabled) end
                end
                if c.Tracer ~= nil then
                    cat.Tracer = c.Tracer == true
                    if Setters["tr_" .. id] then Setters["tr_" .. id](cat.Tracer) end
                end
                if type(c.Color) == "table" and #c.Color == 3 then
                    cat.Color = Color3.new(c.Color[1], c.Color[2], c.Color[3])
                    if Setters["col_" .. id] then Setters["col_" .. id](cat.Color) end
                end
            end
        end
    end

    -- Filtros: lo no guardado (items/entidades nuevos) queda activado por defecto
    local function MergeFilter(saved, names, setter)
        if type(saved) ~= "table" then return nil end
        local map, list = {}, {}
        for _, n in ipairs(names) do
            local on = saved[n]
            if on == nil then on = true end
            map[n] = on
            if on then list[#list + 1] = n end
        end
        setter(list)
        return map
    end
    local im = MergeFilter(data.ItemFilter, ITEM_NAMES, function(l) Setters.ItemFilter(l) end)
    if im then Cfg.ItemFilter = im end
    local em = MergeFilter(data.EntityFilter, ENTITY_LIST, function(l) Setters.EntityFilter(l) end)
    if em then Cfg.EntityFilter = em end
end

print("[R4NS0M] Loaded Config presets")
print("[R4NS0M] Loading Config System")
----------------------------------------------------
-- CONFIG SYSTEM
----------------------------------------------------
ConfigsTab:Section({ Title = "Config Selector" })

local configFolder = "R4NS0M_Configs"
local codesFolder = "R4NS0M_Configs/Codes"

if makefolder then
    if isfolder then
        if not isfolder(configFolder) then pcall(makefolder, configFolder) end
        if not isfolder(codesFolder) then pcall(makefolder, codesFolder) end
    else
        pcall(makefolder, configFolder)
        pcall(makefolder, codesFolder)
    end
end

local selectedConfig = ""
local newConfigName = ""
local configCodeInput = ""

local currentConfigData = {
    Version = "CD-1",
    Settings = {
        WalkSpeed = 16,
        ESP = true,
        AutoInteract = false
    }
}

local function Snapshot()
    currentConfigData.Visuals = VisualsSerialize()
    return HttpService:JSONEncode(currentConfigData)
end

-- Limpia nombres: solo letras, numeros, espacios, _ y -
local function Sanitize(name)
    return (tostring(name):gsub("[^%w_%- ]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function GetConfigList()
    local files = {}
    if listfiles and isfolder and isfolder(configFolder) then
        for _, file in ipairs(listfiles(configFolder)) do
            if file:sub(-5) == ".json" then
                local fileName = file:match("([^/\\]+)%.json$")
                if fileName then
                    table.insert(files, fileName)
                end
            end
        end
    end
    if #files == 0 then
        table.insert(files, "No configs found")
    end
    return files
end

local function RefreshDropdown(dropdown, values)
    -- WindUI usa :Refresh(); SetValues queda como respaldo
    if dropdown.Refresh then
        dropdown:Refresh(values)
    elseif dropdown.SetValues then
        dropdown:SetValues(values)
    end
end

local function ReadJson(path)
    return pcall(function()
        return HttpService:JSONDecode(readfile(path)) -- Decode, no Encode
    end)
end

local initialList = GetConfigList()

local ConfigDropdown = ConfigsTab:Dropdown({
    Title = "Select Saved Config",
    Values = initialList,
    Value = initialList[1],
    Callback = function(option)
        if option ~= "No configs found" then
            selectedConfig = option
        else
            selectedConfig = ""
        end
    end
})

ConfigsTab:Button({
    Title = "Refresh Config List",
    Desc = "Reloads the list of saved configuration files.",
    Callback = function()
        RefreshDropdown(ConfigDropdown, GetConfigList())
        WindUI:Notify({ Title = "Configs", Content = "Config list refreshed!", Duration = 2 })
    end
})

ConfigsTab:Button({
    Title = "Load Selected Config",
    Desc = "Loads settings from the selected config.",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "No configs found" then
            WindUI:Notify({ Title = "Error", Content = "Please select a valid config first.", Duration = 3 })
            return
        end

        local filePath = configFolder .. "/" .. selectedConfig .. ".json"
        if isfile and isfile(filePath) then
            local success, data = ReadJson(filePath)
            if success and type(data) == "table" then
                currentConfigData = data
                VisualsApply(data.Visuals)
                WindUI:Notify({ Title = "Configs", Content = "Loaded '" .. selectedConfig .. "' successfully!", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to load configuration file.", Duration = 3 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Config file not found.", Duration = 3 })
        end
    end
})

ConfigsTab:Button({
    Title = "Overwrite Selected Config",
    Desc = "Overwrites the currently selected config with current settings.",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "No configs found" then
            WindUI:Notify({ Title = "Error", Content = "Select a config from the dropdown to overwrite.", Duration = 3 })
            return
        end

        if writefile then
            local filePath = configFolder .. "/" .. selectedConfig .. ".json"
            writefile(filePath, Snapshot())
            WindUI:Notify({ Title = "Configs", Content = "Overwrote '" .. selectedConfig .. "' successfully!", Duration = 3 })
        else
            WindUI:Notify({ Title = "Error", Content = "Your executor does not support file writing.", Duration = 3 })
        end
    end
})

ConfigsTab:Section({ Title = "Create New Config" })

ConfigsTab:Input({
    Title = "New Config Name",
    Placeholder = "Enter name for new config...",
    Callback = function(text)
        newConfigName = Sanitize(text)
    end
})

ConfigsTab:Button({
    Title = "Save New Config",
    Desc = "Saves settings into a new file and adds it to the list.",
    Callback = function()
        if newConfigName == "" or newConfigName == "No configs found" then
            WindUI:Notify({ Title = "Error", Content = "Please enter a valid name (letters, numbers, - and _).", Duration = 3 })
            return
        end

        if writefile then
            local filePath = configFolder .. "/" .. newConfigName .. ".json"
            writefile(filePath, Snapshot())

            RefreshDropdown(ConfigDropdown, GetConfigList())
            selectedConfig = newConfigName

            WindUI:Notify({ Title = "Configs", Content = "Created new config '" .. newConfigName .. "'!", Duration = 3 })
        else
            WindUI:Notify({ Title = "Error", Content = "Your executor does not support file writing.", Duration = 3 })
        end
    end
})

ConfigsTab:Section({ Title = "Short Code Sharing (12 Chars)" })

local function GenerateShortCode()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local code = "CD-"
    for _ = 1, 9 do
        local rand = math.random(1, #chars)
        code = code .. chars:sub(rand, rand)
    end
    return code
end

ConfigsTab:Button({
    Title = "Generate 12-Char Share Code",
    Desc = "Generates a random 12-character code (Format: CD-XXXXXXXXX).",
    Callback = function()
        local randomCode = GenerateShortCode()
        local filePath = codesFolder .. "/" .. randomCode .. ".json"

        if writefile then
            writefile(filePath, Snapshot())

            if setclipboard then
                setclipboard(randomCode)
                WindUI:Notify({ Title = "Share Code", Content = "Code '" .. randomCode .. "' copied to clipboard!", Duration = 3 })
            else
                print("Generated Code: " .. randomCode)
                WindUI:Notify({ Title = "Share Code", Content = "Code printed to console: " .. randomCode, Duration = 3 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Your executor does not support file operations.", Duration = 3 })
        end
    end
})

ConfigsTab:Input({
    Title = "Import Code",
    Placeholder = "Enter 12-char code (e.g. CD-a9X2kP1zL)...",
    Callback = function(text)
        configCodeInput = Sanitize(text)
    end
})

ConfigsTab:Button({
    Title = "Import Config from Code",
    Desc = "Loads configuration matching the 12-character code.",
    Callback = function()
        if configCodeInput == "" then
            WindUI:Notify({ Title = "Error", Content = "Please enter a valid code.", Duration = 3 })
            return
        end

        local filePath = codesFolder .. "/" .. configCodeInput .. ".json"
        if isfile and isfile(filePath) then
            local success, data = ReadJson(filePath)
            if success and type(data) == "table" then
                currentConfigData = data
                VisualsApply(data.Visuals)
                WindUI:Notify({ Title = "Configs", Content = "Imported config from code '" .. configCodeInput .. "'!", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Corrupted code file.", Duration = 3 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Code not found or invalid.", Duration = 3 })
        end
    end
})

Window:SelectTab(1)
print("[R4NS0M] Loaded Config System")
warn("--- [R4NS0M] RUNNING SCRIPT ---")
