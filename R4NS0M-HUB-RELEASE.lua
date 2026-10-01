--[[
  R4NS0M CD-1  |  Team CHX
  Version 1.0.0
  Tabs: Main, Info, Visuals, Player, Automation, Anticheat, Antis, Alerts, Misc, Keybinds, Configs
]]
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

math.randomseed(os.time())

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

local IconAsset = GetIconAsset()

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

----------------------------------------------------
-- LOAD WINDUI (con pcall)
----------------------------------------------------
local okLib, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not okLib or not WindUI then
    warn("[R4NS0M] No se pudo cargar WindUI: " .. tostring(WindUI))
    return
end

local Window = WindUI:CreateWindow({
    Title = "R4NS0M CD-1",
    Icon = IconAsset,
    Author = "Team CHX",
    Folder = "R4NS0M_Configs",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true
})

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
for _, t in ipairs({ AntisTab }) do
    t:Paragraph({ Title = "Coming soon", Desc = "This tab has no features yet." })
end

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
        "Username: %s\nDisplay Name: %s\nExecutor: %s\nExecutions: %d",
        LocalPlayer.Name,
        LocalPlayer.DisplayName,
        currentExecutor,
        executionCount
    ),
    Image = avatarUrl,
    ImageSize = 48
})

InfoTab:Section({ Title = "Script Information" })

InfoTab:Paragraph({
    Title = "About R4NS0M CD-1",
    Desc = "A specialized DOORS script developed by Team CHX (Created by 2 developers).\nVersion: 1.0.0"
})

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
    "Gold Gun", "Green Herb", "Gween Soda", "Holy Hand Grenade", "Honcho Mug", "Mug", "Lunch Box", "Waiting Ticket", "Paper Cup", "Fih Food", "Pack Of Gween Soda", "Honey Pot", "Iron Key",
    "Knockback Stick", "Lantern", "Laser Pointer", "Leftovers", "Lighter", "Lockpicks", "Lotus",
    "Moonlight Candle", "Moonlight Float", "Multitool", "NVCS-3000", "Paper Plane",
    "Pizza", "Pocket Mirror", "Rift Jar", "Shakelight", "Shears", "Skeleton Key", "Smoothie", "Spotlight",
    "Starlight Bottle", "Starlight Jug", "Starlight Vial", "Straplight", "Tip Jar", "Vitamins",
    -- Items sacados del Explorer (Dex) que antes no se reconocian
    "Big Bomb", "Bomb", "Cheese", "Knockbomb", "Nanner", "Nanner Peel", "Rift Candle", "Rift Smoothie",
    "Snake Box", "Stop Sign",
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
ITEM_LOOKUP["lotuspetal"] = "Lotus Petal"
local SPECIAL_CATS = { ["Glitch Fragment"] = "glitch", ["Lotus Petal"] = "lotus" }
ITEM_LOOKUP["batterypack"] = "Battery Pack"

-- Alias de nombres internos reales (sacados del Explorer / Dex)
local INTERNAL_ALIASES = {
    AlarmClock = "Alarm Clock", AloeVera = "Aloe", BandagePack = "Bandage Pack", BatteryPack = "Battery Pack",
    BigBomb = "Big Bomb", Bomb = "Bomb", BoxingGloves = "Boxing Gloves", Bread = "Bread", Bulklight = "Bulklight",
    Candle = "Candle", Cheese = "Cheese", Compass = "Compass", Crucifix = "Crucifix", Donut = "Donut",
    Flashlight = "Flashlight", Glowsticks = "Glowstick", GoldGun = "Gold Gun", GoldBlaster = "Gold Gun",
    GweenSoda = "Gween Soda", HolyGrenade = "Holy Hand Grenade", KnockbackStick = "Knockback Stick",
    Knockbomb = "Knockbomb", Lantern = "Lantern", LaserPointer = "Laser Pointer", Lighter = "Lighter",
    Lockpick = "Lockpicks", Multitool = "Multitool", Nanner = "Nanner", NannerPeel = "Nanner Peel",
    Pizza = "Pizza", PocketMirror = "Pocket Mirror", RiftCandle = "Rift Candle", RiftJar = "Rift Jar",
    RiftSmoothie = "Rift Smoothie", Shakelight = "Shakelight", Shears = "Shears", SkeletonKey = "Skeleton Key",
    Smoothie = "Smoothie", SnakeBox = "Snake Box", StarBottle = "Starlight Bottle", StarJug = "Starlight Jug",
    StarVial = "Starlight Vial", StopSign = "Stop Sign", Straplight = "Straplight", TipJar = "Tip Jar",
    Vitamins = "Vitamins",
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
    TimerLever = "Time Lever"
    LeverForGate = "Lever",
    LiveHintBook = "Library Book",
    LiveBreakerPolePickup = "Breaker Pole",
    ["Sally's Toy"] = "Sally's Toy",
    SallysToy = "Sally's Toy",
    SallyToy = "Sally's Toy",
}
local STARDUST_NAMES = { Stardust = "Stardust" }
-- Entidades: { nombre, modos donde aparece ("*" = todos), tokens de nombre interno (normalizados) }
-- Fuentes: DOORS Wiki (Entities, The Great Outdoors Update, The Archives Update, The Stairwell)
local ENTITY_DEFS = {
    -- All Floors
    { "Rush", "*", { "rushmoving", "rush" } },
    { "Ambush", "*", { "ambushmoving", "ambush" } },
    { "Eyes", "*", { "eyes" } },
    { "Halt", "*", { "halt" } },
    { "Jeff", "*", { "jeff" } },
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
    -- The Archives (A-60/A-90/A-120 ahora son Bash/Ransom/Scribbles)
    { "Honcho", "Archives", { "honcho" } },
    { "Drone", "Archives", { "drone" } },
    { "Forget-Me-Nots", "Archives", { "forgetmenot", "forgetmenots" } },
    { "Teller", "Archives", { "teller" } },
    { "Alma", "Archives", { "alma" } },
    { "Portrait", "Archives", { "portrait" } },
    { "Bash", "Archives", { "a60", "bash" } },
    { "Scribbles", "Archives", { "a120", "scribbles" } },
    { "Discoloration", "Archives", { "discoloration" } },
    { "Currents", "Archives", { "currents" } },
    -- The Stairwell
    { "Creak", "Stairwell", { "creak" } },
    { "Noise", "Stairwell", { "noise" } },
    { "Stem", "Stairwell", { "stem" } },
    { "Meld", "Stairwell", { "meld" } },
    { "Cobbler", "Stairwell", { "cobbler" } },
    { "Hijack", "Stairwell", { "hijack" } },
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
    JeffTheKiller = "Jeff", A60 = "Bash", A120 = "Scribbles", Snare = "Snare",
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
        return "Glitch"
    end
    for _, t in ipairs(ENTITY_TOKENS) do
        local tok = t[1]
        if strict then
            if n == tok and (allowSkip or not STRICT_SKIP[tok]) then return t[2] end
        elseif #tok <= 4 then
            if n == tok then return t[2] end
        elseif n:sub(1, #tok) == tok then
            return t[2]
        end
    end
end

local GOLD_NAMES = { GoldPile = "Gold" }
local HIDE_NAMES = { Wardrobe = "Closet", Bed = "Bed", Toolshed = "Tool Shed", Locker = "Locker" }

local MAX_HIGHLIGHTS = 30 -- Roblox solo renderiza ~31 Highlights a la vez

local Cfg = {
    MaxDistance = 400,
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
        stairs     = { Enabled = false, Color = Color3.fromHex("#ff5fa2") },
        players    = { Enabled = false, Color = Color3.fromHex("#3b82f6") },
    }
}
-- Tracer por categoria (apagado por defecto)
for _, c in pairs(Cfg.Categories) do c.Tracer = false end

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

----------------------------------------------------
-- MODO DE JUEGO
-- Se detecta UNA vez al cargar y solo se activan los ESP/funciones de ese modo.
-- Si el modo cambia mas tarde, se vuelve a configurar solo.
----------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Setters = {}
local Mode = { Name = "Unknown", Raw = "" }

-- Categorias de ESP que existen en cada modo
local MODE_CATS = {
    Hotel     = { "doors", "dupe", "gold", "keys", "wardrobes", "chests", "objectives", "entities", "items", "drawers", "glitch", "stardust" },
    Mines     = { "doors", "gold", "keys", "wardrobes", "chests", "objectives", "entities", "items", "drawers", "lockers", "glitch", "stardust" },
    Backdoor  = { "doors", "objectives", "entities", "items", "drawers", "glitch", "stardust" },
    Outdoors  = { "doors", "gold", "keys", "entities", "items", "lotus", "stardust", "interactables", "glitch" },
    Archives  = { "doors", "entities", "items", "drawers", "interactables", "glitch", "stardust" },
    Stairwell = { "doors", "entities", "items", "interactables" },
    Rooms     = { "doors", "entities", "items", "wardrobes", "lockers", "stardust" },
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
        end
    end
    -- ESP Stairs & Ladders: solo existe en The Mines
    MODE_CATS.Mines[#MODE_CATS.Mines + 1] = "stairs"
end

-- Fools comparte entidades con Hotel; Rooms comparte A-60/A-90/A-120 con Archives
for _, n in ipairs({ "Bash", "Scribbles" }) do
    if ENTITY_MODES[n] then ENTITY_MODES[n]["Rooms"] = true end
end
local function EntityModeKey()
    return Mode.Name == "Fools" and "Hotel" or Mode.Name
end
local function CurrentEntityList()
    local out, key = {}, EntityModeKey()
    for _, d in ipairs(ENTITY_DEFS) do
        local set = ENTITY_MODES[d[1]]
        if Mode.Name == "Unknown" or set["*"] or set[key] then out[#out + 1] = d[1] end
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

local function ReadMode()
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
    pcall(function()
        WindUI:Notify({ Title = "Game Mode", Content = "Detected: " .. name .. ". Only its ESP options are loaded.", Duration = 4 })
    end)
end

local function WatchMode()
    local name = ReadMode()
    if name ~= "Unknown" and name ~= Mode.Name then ApplyMode(name) end
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

local function RemoveEntry(inst)
    local e = Tracked[inst]
    if not e then return end
    Tracked[inst] = nil
    pcall(function() e.HL:Destroy() end)
    pcall(function() e.Box:Destroy() end)
    pcall(function() e.BB:Destroy() end)
    pcall(function() e.Line:Destroy() end)
end

local function HideEntry(e)
    e.HL.Enabled = false
    e.Box.Visible = false
    e.BB.Enabled = false
    e.Line.Visible = false
end

local OnEntitySeen -- lo asigna el Entity Notifier
local ExtraSerialize, ExtraApply -- los asigna el bloque de extras

-- Si un objeto ya esta registrado, solo se reemplaza por una categoria de mayor prioridad
local PRIORITY = {
    interactables = 1, doors = 2, drawers = 2, lockers = 2,
    items = 3, chests = 3, glitch = 3, lotus = 3, stardust = 3,
    keys = 4, gold = 4, objectives = 4, wardrobes = 4,
    entities = 6, dupe = 6, players = 5, stairs = 1,
}

local function Register(inst, cat, label, opts)
    if not Active[cat] then return end -- categoria que no existe en este modo
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

    local hl = Instance.new("Highlight")
    hl.Adornee = inst
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = Holder

    -- Respaldo cuando Highlight no se ve (partes invisibles) o se pasa del limite
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = part.Size
    box.Visible = false
    box.Parent = Holder

    local bb = Instance.new("BillboardGui")
    bb.Adornee = part
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

    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Visible = false
    line.Parent = Gui

    Tracked[inst] = {
        Inst = inst, Cat = cat, Label = label, Part = part,
        HL = hl, Box = box, BB = bb, TL = tl, Line = line,
        Known = opts and opts.Known, Key = opts and opts.Key, Prompt = opts and opts.Prompt, GeoT = 0, NoGeo = false, RoomNum = opts and opts.RoomNum,
        Dist = 0, Shown = false,
    }

    inst.AncestryChanged:Connect(function(_, parent)
        if not parent then RemoveEntry(inst) end
    end)

    if OnEntitySeen and (cat == "entities" or cat == "dupe") and opts and opts.Known then
        pcall(OnEntitySeen, opts.Key or label, inst)
    end

    if Cfg.DebugVerbose then
        Dbg("REG:" .. cat, inst, "label=" .. tostring(label))
    end
end
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

local function RegisterByName(target)
    local n = target.Name
    if KEY_NAMES[n] then
        Register(target, "keys", KEY_NAMES[n])
    elseif OBJECTIVE_NAMES[n] then
        Register(target, "objectives", OBJECTIVE_NAMES[n])
    elseif STARDUST_NAMES[n] then
        Register(target, "stardust", STARDUST_NAMES[n])
    elseif GOLD_NAMES[n] then
        local value = target:GetAttribute("GoldValue")
        Register(target, "gold", value and ("Gold [" .. value .. "]") or "Gold")
    else
        return false
    end
    return true
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

-- Sube desde el prompt hasta el modelo real del item (soporta Attachment y partes genericas)
local function ResolveTarget(prompt)
    local t = prompt.Parent
    if t and t:IsA("Attachment") then t = t.Parent end
    if not t then return nil end
    if t:IsA("BasePart") then
        local pm = t.Parent
        if pm and pm:IsA("Model") and pm.Parent ~= CurrentRooms then t = pm end
    end
    while GENERIC_PARTS[t.Name] and t.Parent and t.Parent:IsA("Model") and t.Parent.Parent ~= CurrentRooms do
        t = t.Parent
    end
    return t
end

local function CleanName(name)
    return (name:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"))
end

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

local function ProcessContainerPrompt(prompt)
    local t = ResolveTarget(prompt)
    if not t or t == Workspace then return end
    if CurrentRooms and t.Parent == CurrentRooms then return end
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
                or Active.stardust or Active.glitch or Active.lotus) then return end
            local t = ResolveTarget(inst)
            if not t or Tracked[t] or RegisterByName(t) then return end

            local nn = Norm(t.Name)
            if nn:find("sally", 1, true) then
                Register(t, "objectives", "Sally's Toy")
                return
            end

            local objText = inst.ObjectText
            -- El texto que muestra el juego (ObjectText) tiene prioridad sobre el nombre del modelo
            local cands = { t.Name, t:GetAttribute("DisplayName"), objText }
            if pn == "HerbPrompt" then cands[#cands + 1] = "Green Herb" end
            local display = ResolveItem(cands)
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
        if RegisterByName(inst) then return end
        if inst:IsA("Model") then
            local n = inst.Name
            if HIDE_EXACT[n] then
                Register(inst, "wardrobes", HIDE_EXACT[n])
            elseif Active.entities and Cfg.RoomEntities and inst.Parent ~= Workspace and EntityLabel(n, true) and not HasTrackedAncestor(inst) then
                local lab = EntityLabel(n, true)
                Register(inst, "entities", lab, { Known = true, Key = lab })
            elseif CHEST_EXACT[n] then
                Register(inst, "chests", CHEST_EXACT[n])
            else
                local low = n:lower()
                if low:find("chest", 1, true) and not HasTrackedAncestor(inst) then
                    local label = "Chest"
                    if low:find("locked", 1, true) then label = "Locked Chest"
                    elseif low:find("vine", 1, true) then label = "Vine Chest" end
                    Register(inst, "chests", label)
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

local function OnDescendant(d)
    Process(d)
    ProcessStairs(d)
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
    task.spawn(function()
        local n = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            pcall(OnDescendant, d)
            n = n + 1
            if n % 300 == 0 then task.wait() end
        end
        for _, c in ipairs(Workspace:GetChildren()) do pcall(ProcessEntity, c, true) end
        if CurrentRooms then
            for _, room in ipairs(CurrentRooms:GetChildren()) do
                for _, c in ipairs(room:GetChildren()) do pcall(RegisterDoor, room, c) end
            end
        end
    end)
end

-- Conexiones (se crean una sola vez, despues de detectar el modo)
Workspace.DescendantAdded:Connect(function(d) pcall(OnDescendant, d) end)
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
            if Mode.Name ~= "Unknown" and set and not set["*"] and not set[EntityModeKey()] then
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

local function Refresh()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local currentRoom = LocalPlayer:GetAttribute("CurrentRoom")
    local list = {}

    for inst, e in pairs(Tracked) do
        if not e.Part.Parent then
            RemoveEntry(inst)
        else
            local ok = Active[e.Cat] and Cfg.Categories[e.Cat].Enabled and FilterPasses(e)
            if ok and (e.Cat == "doors" or e.Cat == "dupe") and e.RoomNum and currentRoom and e.RoomNum < currentRoom then
                ok = false -- puertas de cuartos ya superados
            end
            if ok and e.Prompt and Cfg.HideLooted then
                local pr = e.Prompt
                if not pr.Parent or pr.Enabled == false then ok = false end -- ya abierto/saqueado
            end
            if ok then
                e.Dist = (e.Part.Position - camPos).Magnitude
                ok = e.Cat == "entities" or e.Dist <= Cfg.MaxDistance
            end
            e.Shown = ok
            if ok then list[#list + 1] = e else HideEntry(e) end
        end
    end

    -- Entidades primero (prioridad para el limite de Highlights), luego por distancia
    table.sort(list, function(a, b)
        local pa = a.Cat == "entities" and 0 or 1
        local pb = b.Cat == "entities" and 0 or 1
        if pa ~= pb then return pa < pb end
        return a.Dist < b.Dist
    end)
    local now = os.clock()

    local meters = Cfg.Unit == "Meters"
    local fontEnum = FONT_MAP[Cfg.Font] or Enum.Font.Oswald
    local bbHeight = math.ceil(Cfg.TextSize * 2.5) + 6
    for i, e in ipairs(list) do
        local color = Cfg.Categories[e.Cat].Color

        if e.Cat == "doors" then
            e.Base = e.Base or e.Label
            e.Label = e.Base .. (e.Inst:FindFirstChild("Lock") and " [Locked]" or "")
        elseif e.Cat == "players" then
            local plr = Players:GetPlayerFromCharacter(e.Inst)
            if plr then e.Label = (Cfg.PlayerNames == "Username") and plr.Name or plr.DisplayName end
        end

        if now - e.GeoT > 2 then
            e.GeoT = now
            e.NoGeo = not HasVisibleGeometry(e.Inst)
        end
        local useBox = e.NoGeo or i > MAX_HIGHLIGHTS

        local hl = e.HL
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = Cfg.FillTransparency
        hl.OutlineTransparency = Cfg.OutlineTransparency
        hl.Enabled = not useBox

        local box = e.Box
        box.Visible = useBox
        if useBox then
            box.Color3 = color
            box.Transparency = math.max(0.55, Cfg.FillTransparency)
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

        local parts = {}
        if Cfg.ShowName then parts[#parts + 1] = e.Label end
        if Cfg.ShowDistance then
            local d = meters and (e.Dist * 0.28) or e.Dist
            parts[#parts + 1] = string.format(meters and "[%dm]" or "[%d]", math.floor(d + 0.5))
        end
        e.TL.Text = table.concat(parts, "\n")
        e.TL.TextColor3 = color
        e.TL.TextSize = Cfg.TextSize
        e.TL.Font = fontEnum
        e.BB.Size = UDim2.fromOffset(300, bbHeight)
        e.BB.Enabled = #parts > 0
        e.Line.BackgroundColor3 = color
    end
end

task.spawn(function()
    while true do
        pcall(Refresh)
        task.wait(0.25)
    end
end)

task.spawn(function()
    while true do
        pcall(WatchMode)
        pcall(UpdateOverlay)
        task.wait(2)
    end
end)

RunService.RenderStepped:Connect(function()
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

    for _, e in pairs(Tracked) do
        local line = e.Line
        local catCfg = Cfg.Categories[e.Cat]
        if catCfg and catCfg.Tracer and e.Shown then
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
end)

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
      desc = "Stardust pickups found in the Outdoors." },
    { id = "glitch", section = "Loot", title = "ESP Glitch Fragment",
      desc = "The rare Glitch Fragment item. Glitched Rush, Ambush and Screech are handled by ESP Entities instead." },
    { id = "lotus", section = "Loot", title = "ESP Lotus Petals",
      desc = "Lotus petals scattered around the Outdoors." },

    { id = "wardrobes", section = "Hiding & Objectives", title = "ESP Hiding Spots",
      desc = "Places you can hide in: closets, beds, lockers and tool sheds." },
    { id = "objectives", section = "Hiding & Objectives", title = "ESP Objectives",
      desc = "Room puzzle pieces: levers, library books, breaker poles and Sally's toy." },

    { id = "entities", section = "Entities", title = "ESP Entities",
      desc = "Monsters that belong to the detected game mode only. Entities from other modes are never shown. Pick which ones in the Entity Filter below." },

    { id = "players", section = "Players", title = "ESP Players",
      desc = "Marks the other players in your run with their name and distance. Choose display name or username in the Display section." },

    { id = "interactables", section = "Extras", title = "ESP Interactables",
      desc = "Any other object with an interaction prompt that does not fit another category. Can be noisy, so presets leave it off." },
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

----------------------------------------------------
-- MAIN TAB: estado del modo
----------------------------------------------------
MainTab:Section({ Title = "Game Mode" })
MainTab:Paragraph({
    Title = "Detected at load: " .. Mode.Name,
    Desc = "The script detects the game mode when it starts and only loads the ESP options and detectors that mode needs. "
        .. "If the mode changes while you play, it reconfigures itself and adds the new options at the bottom of the Visuals tab."
})
MainTab:Button({
    Title = "Re-detect Game Mode",
    Desc = "Reads the game data again. Use it if the mode was not detected correctly on load.",
    Callback = function()
        local ok, name = pcall(ReadMode)
        if ok and name ~= "Unknown" and name ~= Mode.Name then
            ApplyMode(name)
        else
            WindUI:Notify({ Title = "Game Mode", Content = "Current mode: " .. Mode.Name .. " (no change).", Duration = 3 })
        end
    end
})

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
    "Objects farther than this many studs are hidden. Entities are always shown, whatever the distance.",
    50, 2000, Cfg.MaxDistance, function(v) Cfg.MaxDistance = v end)
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
----------------------------------------------------
-- EXTRAS
--   Alerts      : Entity Notifier (DOORS achievement style popup)
--   Player      : Speed (max 90), Jump, Infinite Jump, Slide, Fly, Noclip, Fullbright
--   Automation  : Instant Proximity Prompt
--   Anti cheat  : Anticheat Manipulator (Phase Walk / Noclip), Speed Guard, floating buttons (ACM / SLIDE / FLY)
--   Keybinds    : PC hotkeys for all of the above
-- Todo va dentro de un bloque do..end para no gastar variables locales del script.
----------------------------------------------------
do
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Entidades que normalmente no vale la pena avisar (el usuario puede activarlas igual)
local NOT_WORTH = {
    Timothy = true, Snare = true, Bob = true, ["El Goblino"] = true, Grampy = true,
    Portrait = true, Monument = true, Currents = true, Jeff = true,
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
    Notify = false, NotifyStyle = "Doors Achievement", NotifySound = true, NotifyVolume = 100,
    NotifyDuration = 5, NotifyCooldown = 4, NotifyTips = true, NotifySoundId = "", NotifyIconId = "",
    NotifyFilter = {},
    -- Movement
    Speed = false, SpeedValue = 30, SpeedMethod = "Velocity", SpeedAuto = true,
    Jump = false, JumpPower = 50, InfJump = false,
    Slide = false, SlideSpeed = 55,
    Fly = false, FlySpeed = 40,
    Noclip = false, Fullbright = false,
    -- Anticheat Manipulator
    ACM = false, ACMMode = "Phase Walk", PhaseSpeed = 18, PhaseMax = 14, VoidGuard = true,
    FloatButtons = UserInputService.TouchEnabled, BtnACM = true, BtnFly = true, BtnSlide = true,
    -- Automation
    InstantPrompt = false,
    -- Keybinds (nombres de Enum.KeyCode)
    Key_ACM = "X", Key_Noclip = "N", Key_Fly = "G", Key_Speed = "B", Key_Slide = "Z",
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
    if St.Last[label] and now - St.Last[label] < Ex.NotifyCooldown then return end
    St.Last[label] = now
    ShowEntityToast(label)
end

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
    if not v then
        St.Glide, St.PhaseUntil = nil, 0
        if not Ex.Noclip then RestoreCollide() end
    end
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
    if Ex.SpeedAuto and St.SpeedCap > 0 then target = math.min(target, St.SpeedCap) end
    if now < St.Penalty then target = base end -- tras un tiron, deja que el servidor te resincronice
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

-- Auto-ajuste: si el servidor te devuelve, baja el limite y los efectos en vez de seguir chocando
function FX.Snap(now)
    St.LastSnap, St.Snaps, St.Penalty = now, St.Snaps + 1, now + 1.5
    local kind = St.BoostKind
    if kind == "speed" then
        local ref = St.SpeedCap > 0 and St.SpeedCap or Ex.SpeedValue
        if St.Cur > 0 then ref = math.min(ref, St.Cur) end
        St.SpeedCap = math.max(18, ref * 0.85)
    elseif kind == "glide" or kind == "slide" then
        St.GlideScale = math.max(0.4, St.GlideScale * 0.8)
    end
    St.Glide = nil
    FX.StopSlide()
    if now - St.LastNote > 4 then
        St.LastNote = now
        local msg = kind == "speed" and string.format("Server pulled you back. Speed limit lowered to %d.", math.floor(St.SpeedCap))
            or "Server pulled you back. Effect strength lowered."
        NotifyUI("Anti-cheat", msg)
    end
end

-- Anticheat Manipulator (Phase Walk): si hay una pared delante, calcula el grosor en linea recta y
-- te empuja SOLO hacia adelante (direccion fija) hasta el primer hueco libre. Sin zigzag ni deriva.
function FX.Phase(char, hum, root, dt, now)
    local g = St.Glide
    if g then
        local step = math.min(g.left, Ex.PhaseSpeed * St.GlideScale * dt)
        root.CFrame = root.CFrame + g.dir * step
        root.AssemblyLinearVelocity = Vector3.zero
        g.left = g.left - step
        St.PhaseUntil = now + 0.25
        St.BoostT, St.BoostKind = now, "glide"
        if g.left <= 0.01 then
            St.Glide, St.GlideCd = nil, now + 0.35
        end
        return
    end
    if now < St.GlideCd then return end
    local md = hum.MoveDirection
    if md.Magnitude < 0.05 then return end
    local dir = Vector3.new(md.X, 0, md.Z).Unit
    RayP.FilterDescendantsInstances = { char }
    OverP.FilterDescendantsInstances = { char }
    local size = Vector3.new(2.2, 4.2, 2.2)
    local hit = Workspace:Raycast(root.Position, dir * 2.8, RayP)
    local blocked = hit ~= nil and math.abs(hit.Normal.Y) < 0.6
    if not blocked then
        blocked = #Workspace:GetPartBoundsInBox(root.CFrame, size, OverP) > 0 -- ya dentro de algo
    end
    if not blocked then return end

    local exitD, seenSolid, d = nil, false, 0.5
    while d <= Ex.PhaseMax do
        local free = #Workspace:GetPartBoundsInBox(CFrame.new(root.Position + dir * d), size, OverP) == 0
        if not free then
            seenSolid = true
        elseif seenSolid then
            exitD = d
            break
        end
        d = d + 0.5
    end
    if exitD then
        St.Glide = { dir = dir, left = exitD + 0.3 }
    else
        St.GlideCd = now + 1
        if now - St.LastNote > 4 then
            St.LastNote = now
            NotifyUI("Anticheat Manipulator", "Nothing walkable within " .. Ex.PhaseMax .. " studs ahead. Not moving.")
        end
    end
end


RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local want = Ex.Noclip or (Ex.ACM and (Ex.ACMMode == "Noclip" or os.clock() < St.PhaseUntil))
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

    -- Deteccion de tirones del servidor (solo mientras un efecto esta moviendote)
    do
        local fl = Vector3.new(root.Position.X, 0, root.Position.Z)
        if St.LastFlat and now - St.BoostT < 0.5 then
            local top = math.max(St.Cur, Ex.FlySpeed, Ex.SlideSpeed, Ex.PhaseSpeed, 16)
            if (fl - St.LastFlat).Magnitude > math.max(5, top * dt * 2.5 + 4) and now - St.LastSnap > 0.6 then
                FX.Snap(now)
            end
        end
        St.LastFlat = fl
    end

    -- Speed
    if Ex.Speed and not Ex.Fly and not Slide.dir and not St.Glide then
        FX.Speed(hum, root, dt, now)
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

    -- Anticheat Manipulator: Phase Walk
    if Ex.ACM and Ex.ACMMode == "Phase Walk" then
        FX.Phase(char, hum, root, dt, now)
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

----------------------------------------------------
-- Teclas (PC)
----------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode.Name
    if k == Ex.Key_ACM then Flip("ACM", "Anticheat Manipulator")
    elseif k == Ex.Key_Noclip then Flip("Noclip", "Noclip")
    elseif k == Ex.Key_Fly then Flip("Fly", "Fly")
    elseif k == Ex.Key_Speed then Flip("Speed", "Speed")
    elseif k == Ex.Key_Slide then DoSlide() end
end)

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
MakeFloat("SLIDE", -16, DoSlide, nil, "BtnSlide")
MakeFloat("FLY", 38, function() Flip("Fly", "Fly") end, function() return Ex.Fly end, "BtnFly")

function FX.UpdateButtons()
    for _, f in ipairs(Floating) do
        f.Btn.Visible = Ex.FloatButtons and (f.Flag == nil or Ex[f.Flag] ~= false)
        local on = f.GetOn and f.GetOn() or false
        f.Stroke.Color = on and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(120, 120, 120)
    end
end

----------------------------------------------------
-- UI helpers extra
----------------------------------------------------
local KEY_CHOICES = { "X", "N", "G", "B", "Z", "V", "H", "J", "K", "L", "R", "T", "Y", "U", "M", "C", "F", "Q" }

local function AddKeybind(tab, id, title, desc, default)
    local function set(v)
        local name = typeof(v) == "EnumItem" and v.Name or tostring(v)
        local ok = pcall(function() return Enum.KeyCode[name] end)
        if ok then Ex[id] = name end
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

----------------------------------------------------
-- PLAYER TAB
----------------------------------------------------
PlayerTab:Section({ Title = "Speed" })
AddToggle(PlayerTab, "Speed", "Speed Boost", "Makes you faster than normal (up to 90).", Ex.Speed, function(v) Apply("Speed", v) end)
AddSlider(PlayerTab, "SpeedValue", "Speed", "Target speed in studs per second. Doors' normal walk speed is about 16.", 16, 90, Ex.SpeedValue, function(v) Ex.SpeedValue = v end)
AddDropdown(PlayerTab, "SpeedMethod", "Speed Method",
    "Velocity (recommended): smooth push that the server tolerates best. CFrame: small position steps. WalkSpeed: changes the value directly (easiest to detect).",
    { "Velocity", "CFrame", "WalkSpeed" }, Ex.SpeedMethod, function(v) Ex.SpeedMethod = v end)

PlayerTab:Section({ Title = "Jump" })
AddToggle(PlayerTab, "Jump", "Enable Jump", "Turns on the game's own jump and lets you set its power, also in places where the game disables it.", Ex.Jump, function(v) Apply("Jump", v) end)
AddSlider(PlayerTab, "JumpPower", "Jump Power", "How high you jump.", 20, 120, Ex.JumpPower, function(v) Ex.JumpPower = v end)
AddToggle(PlayerTab, "InfJump", "Infinite Jump", "Jump again in mid-air every time you press jump.", Ex.InfJump, function(v) Ex.InfJump = v end)

PlayerTab:Section({ Title = "Slide" })
AddToggle(PlayerTab, "Slide", "Enable Slide", "Turns on the game's own slide and adds a forward slide with a lowered camera. It stops at walls. Keybind on PC, SLIDE button on mobile.", Ex.Slide, function(v) Apply("Slide", v) end)
AddSlider(PlayerTab, "SlideSpeed", "Slide Speed", "Starting speed of the slide. It fades out smoothly.", 30, 90, Ex.SlideSpeed, function(v) Ex.SlideSpeed = v end)
PlayerTab:Button({ Title = "Slide Now", Desc = "Does one slide right now (same as the keybind).", Callback = DoSlide })

PlayerTab:Section({ Title = "Fly & Noclip" })
AddToggle(PlayerTab, "Fly", "Fly", "Fly freely. PC: Space goes up, Left Ctrl goes down. Mobile: look up or down while moving.", Ex.Fly, function(v) Apply("Fly", v) end)
AddSlider(PlayerTab, "FlySpeed", "Fly Speed", "Flight speed in studs per second.", 10, 90, Ex.FlySpeed, function(v) Ex.FlySpeed = v end)
AddToggle(PlayerTab, "Noclip", "Noclip", "Walk through walls and objects. Simple version: for the careful one, use the Anticheat Manipulator.", Ex.Noclip, function(v) Apply("Noclip", v) end)

PlayerTab:Section({ Title = "Lighting" })
AddToggle(PlayerTab, "Fullbright", "Fullbright", "Removes darkness and fog so you can see everything.", Ex.Fullbright, function(v) Apply("Fullbright", v) end)

----------------------------------------------------
-- AUTOMATION TAB
----------------------------------------------------
AutomationTab:Section({ Title = "Interaction" })
AddToggle(AutomationTab, "InstantPrompt", "Instant Proximity Prompt",
    "Removes the hold time of every interaction prompt (doors, drawers, levers, items...). Turning it off restores the original times.",
    Ex.InstantPrompt, function(v) Apply("InstantPrompt", v) end)

----------------------------------------------------
-- ANTI CHEAT TAB: Anticheat Manipulator
----------------------------------------------------
AntiCheatTab:Section({ Title = "Anticheat Manipulator" })
AntiCheatTab:Paragraph({
    Title = "What it does",
    Desc = "Phase Walk: walk normally. When a wall or door blocks you, it measures the obstacle straight ahead and pushes you forward only, in one short glide, to the first free spot, then restores collisions. "
        .. "If nothing walkable is within reach it does not move you. If the server pulls you back, the strength is lowered automatically. There is no guarantee: the server may still flag you, so use it at your own risk."
})
AddToggle(AntiCheatTab, "ACM", "Anticheat Manipulator", "Main switch. PC: keybind (Keybinds tab). Mobile: the ACM floating button.", Ex.ACM, function(v) Apply("ACM", v) end)
AddDropdown(AntiCheatTab, "ACMMode", "Mode",
    "Phase Walk: automatic forward glide through obstacles (recommended). Noclip: collisions are always off.",
    { "Phase Walk", "Noclip" }, Ex.ACMMode, function(v) Ex.ACMMode = v end)
AddSlider(AntiCheatTab, "PhaseSpeed", "Phase Speed", "Glide speed while crossing an obstacle. Higher means less time inside the wall; lower is gentler.", 6, 60, Ex.PhaseSpeed, function(v) Ex.PhaseSpeed = v end)
AddSlider(AntiCheatTab, "PhaseMax", "Max Wall Thickness", "Longest obstacle (in studs) it will cross in one glide.", 4, 24, Ex.PhaseMax, function(v) Ex.PhaseMax = v end)
AddToggle(AntiCheatTab, "VoidGuard", "Void Guard", "If you fall far below your last safe spot while phasing, noclipping or flying, you are sent back to that spot.", Ex.VoidGuard, function(v) Ex.VoidGuard = v end)

AntiCheatTab:Section({ Title = "Speed Guard" })
AddToggle(AntiCheatTab, "SpeedAuto", "Auto-Tune Speed", "When the server pulls you back while boosting, the speed limit is lowered automatically so it stops happening.", Ex.SpeedAuto, function(v) Ex.SpeedAuto = v end)
AntiCheatTab:Button({
    Title = "Reset Learned Limits",
    Desc = "Forgets the speed limit and glide strength learned from pull-backs.",
    Callback = function()
        St.SpeedCap, St.GlideScale, St.Snaps = 0, 1, 0
        NotifyUI("Anti-cheat", "Limits reset.")
    end
})

AntiCheatTab:Section({ Title = "Mobile Buttons" })
AddToggle(AntiCheatTab, "FloatButtons", "Floating Buttons", "Small draggable buttons for ACM, SLIDE and FLY. On by default on touch devices.", Ex.FloatButtons, function(v)
    Ex.FloatButtons = v
    FX.UpdateButtons()
end)
AddToggle(AntiCheatTab, "BtnACM", "ACM Button", "Show the ACM floating button.", Ex.BtnACM, function(v) Ex.BtnACM = v; FX.UpdateButtons() end)
AddToggle(AntiCheatTab, "BtnFly", "FLY Button", "Show the FLY floating button.", Ex.BtnFly, function(v) Ex.BtnFly = v; FX.UpdateButtons() end)
AddToggle(AntiCheatTab, "BtnSlide", "SLIDE Button", "Show the SLIDE floating button.", Ex.BtnSlide, function(v) Ex.BtnSlide = v; FX.UpdateButtons() end)

----------------------------------------------------
-- KEYBINDS TAB
----------------------------------------------------
KeybindsTab:Section({ Title = "Movement & Anticheat Manipulator" })
AddKeybind(KeybindsTab, "Key_ACM", "Anticheat Manipulator", "Turns the Anticheat Manipulator on or off.", Ex.Key_ACM)
AddKeybind(KeybindsTab, "Key_Noclip", "Noclip", "Turns Noclip on or off.", Ex.Key_Noclip)
AddKeybind(KeybindsTab, "Key_Fly", "Fly", "Turns Fly on or off.", Ex.Key_Fly)
AddKeybind(KeybindsTab, "Key_Speed", "Speed Boost", "Turns Speed Boost on or off.", Ex.Key_Speed)
AddKeybind(KeybindsTab, "Key_Slide", "Slide", "Does a slide (Slide must be enabled in the Player tab).", Ex.Key_Slide)

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

----------------------------------------------------
-- Guardar / cargar (las teclas y ajustes se guardan; ACM, Fly y Noclip siempre arrancan apagados)
----------------------------------------------------
local EXTRA_KEYS = {
    "Notify", "NotifyStyle", "NotifySound", "NotifyVolume", "NotifyDuration", "NotifyCooldown", "NotifyTips",
    "NotifySoundId", "NotifyIconId",
    "Speed", "SpeedValue", "SpeedMethod", "SpeedAuto", "Jump", "JumpPower", "InfJump", "Slide", "SlideSpeed", "FlySpeed",
    "Fullbright", "ACMMode", "PhaseSpeed", "PhaseMax", "VoidGuard", "FloatButtons", "BtnACM", "BtnFly", "BtnSlide", "InstantPrompt",
    "Key_ACM", "Key_Noclip", "Key_Fly", "Key_Speed", "Key_Slide",
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
    "MaxDistance", "TextSize", "Font", "ShowName", "ShowDistance", "Unit",
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

----------------------------------------------------
-- CONFIG SYSTEM
----------------------------------------------------
ConfigsTab:Section({ Title = "Config Selector" })

local configFolder = "R4NS0M_Configs"
local codesFolder = "R4NS0M_Configs/Codes"

if makefolder then
    if not isfolder(configFolder) then makefolder(configFolder) end
    if not isfolder(codesFolder) then makefolder(codesFolder) end
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
