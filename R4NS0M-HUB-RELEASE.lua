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

-- Tabs
local MainTab       = Window:Tab({ Title = "Main",       Icon = "house" })
local VisualsTab    = Window:Tab({ Title = "Visuals",    Icon = "eye" })
local PlayerTab     = Window:Tab({ Title = "Player",     Icon = "user" })
local AutoTab       = Window:Tab({ Title = "Automation", Icon = "bot" })
local AntiCheatTab  = Window:Tab({ Title = "Anti cheat", Icon = "shield-alert" })
local AntisTab      = Window:Tab({ Title = "Antis",      Icon = "shield-check" })
local AlertsTab     = Window:Tab({ Title = "Alerts",     Icon = "bell" })
local MiscTab       = Window:Tab({ Title = "Misc",       Icon = "ellipsis" })
local KeybindsTab   = Window:Tab({ Title = "Keybinds",   Icon = "keyboard" })
local InfoTab       = Window:Tab({ Title = "Info",       Icon = "info" })
local ConfigsTab    = Window:Tab({ Title = "Configs",    Icon = "settings" })

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
    Desc = "A specialized DOORS script developed by Team CHX (Created by 2 developers).\nVersion: CD-1"
})

----------------------------------------------------
-- VISUALS / ESP
----------------------------------------------------
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Nombres oficiales de items (fuente: DOORS Wiki - Category:Items / Item Skins)
local ITEM_NAMES = {
    "Alarm Clock", "Aloe", "Bandage", "Battery", "Boxing Gloves", "Buddy", "Bulklight",
    "Bread", "Candle", "Candy", "Candy Bag", "Compass", "Crucifix", "Disc", "Donut", "Fih Flakes", "Flare", "Flashlight", "Glowstick",
    "Gold Blaster", "Green Herb", "Gween Soda", "Holy Hand Grenade", "Honcho Mug", "Honey Pot", "Iron Key",
    "Knockback Stick", "Lantern", "Laser Pointer", "Leftovers", "Lighter", "Lockpicks", "Lotus",
    "Moonlight Candle", "Moonlight Float", "Multitool", "NVCS-3000", "Paper Plane",
    "Pizza", "Pocket Mirror", "Rift Jar", "Shakelight", "Shears", "Skeleton Key", "Smoothie",
    "Starlight Bottle", "Starlight Jug", "Starlight Vial", "Straplight", "Tip Jar", "Vitamins",
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
ITEM_LOOKUP["bandagepack"] = "Bandage"
ITEM_LOOKUP["crucifixwall"] = "Crucifix" -- Crucifix incrustado en la pared (nombre interno real)
ITEM_LOOKUP["trickortreatbag"] = "Candy Bag"
ITEM_LOOKUP["treatbag"] = "Candy Bag"

-- Items con ESP propio (no entran al filtro de items normales)
ITEM_LOOKUP["glitchfragment"] = "Glitch Fragment"
ITEM_LOOKUP["lotuspetal"] = "Lotus Petal"
local SPECIAL_CATS = { ["Glitch Fragment"] = "glitch", ["Lotus Petal"] = "lotus" }
ITEM_LOOKUP["batterypack"] = "Battery"

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
                if (#n >= 5 and k:find(n, 1, true)) or (#k >= 5 and n:find(k, 1, true)) then
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
    LiveHintBook = "Library Book",
    LiveBreakerPolePickup = "Breaker Pole",
    ["Sally's Toy"] = "Sally's Toy",
    SallysToy = "Sally's Toy",
    SallyToy = "Sally's Toy",
}
local STARDUST_NAMES = { Stardust = "Stardust" }
-- Entidades (lista para el filtro de la UI)
local ENTITY_LIST = {
    "Rush", "Ambush", "Blitz", "A-60", "A-90", "A-120", "Eyes", "Screech", "Halt", "Seek", "Figure",
    "Lookman", "Haste", "Dread", "Glitch", "Glitched Rush", "Glitched Ambush", "Glitched Screech",
    "Giggle", "Grumble", "Gloombat", "Snare", "Dupe", "Void", "Jeff", "Timothy", "Jack",
}
-- Entidades del Glitch Fragment (client-side). Nombres oficiales de la wiki.
local GLITCH_TOKENS = {
    { "RNIUSHCg",  "Glitched Rush" },
    { "AR0xMBUSH", "Glitched Ambush" },
    { "SCJVEREECH", "Glitched Screech" },
}
-- Prefijos (normalizados) de nombres internos -> etiqueta. Orden importa.
local ENTITY_PREFIXES = {
    { "backdoorrush", "Blitz" }, { "blitz", "Blitz" }, { "ambush", "Ambush" }, { "rush", "Rush" },
    { "a60", "A-60" }, { "a90", "A-90" }, { "a120", "A-120" }, { "eyes", "Eyes" },
    { "screech", "Screech" }, { "halt", "Halt" }, { "seek", "Seek" }, { "figure", "Figure" },
    { "lookman", "Lookman" }, { "haste", "Haste" }, { "dread", "Dread" }, { "giggle", "Giggle" },
    { "grumble", "Grumble" }, { "gloombat", "Gloombat" }, { "snare", "Snare" }, { "dupe", "Dupe" },
    { "void", "Void" }, { "jeff", "Jeff" }, { "timothy", "Timothy" }, { "jack", "Jack" },
}

-- Nombres internos confirmados en scripts publicos de DOORS
local ENTITY_EXACT = {
    RushMoving = "Rush", AmbushMoving = "Ambush", BackdoorRush = "Blitz", BackdoorLookman = "Lookman",
    Lookman = "Lookman", Eyes = "Eyes", Screech = "Screech", Halt = "Halt",
    JeffTheKiller = "Jeff", A60 = "A-60", A120 = "A-120", Snare = "Snare",
}

local function EntityLabel(name)
    if ENTITY_EXACT[name] then return ENTITY_EXACT[name] end
    for _, g in ipairs(GLITCH_TOKENS) do
        if name:find(g[1], 1, true) then return g[2] end
    end
    local n = Norm(name)
    if n:sub(1, 6) == "glitch" then
        if n:find("ambush", 1, true) then return "Glitched Ambush" end
        if n:find("rush", 1, true) then return "Glitched Rush" end
        if n:find("screech", 1, true) then return "Glitched Screech" end
        return "Glitch"
    end
    for _, pre in ipairs(ENTITY_PREFIXES) do
        if n:sub(1, #pre[1]) == pre[1] then return pre[2] end
    end
end
local GOLD_NAMES = { GoldPile = "Gold" }
local HIDE_NAMES = { Wardrobe = "Wardrobe", Bed = "Bed", Toolshed = "Tool Shed", Locker = "Locker" }

local MAX_HIGHLIGHTS = 30 -- Roblox solo renderiza ~31 Highlights a la vez

local Cfg = {
    MaxDistance = 400,
    TextSize = 14,
    ShowName = true,
    ShowDistance = true,
    Unit = "Meters",
    FillTransparency = 0.8,
    OutlineTransparency = 0,
    Tracers = false,
    TracerOrigin = "Bottom",
    TracerThickness = 1.5,
    UnlistedItems = true,
    ItemFilter = {},
    UnlistedEntities = true,
    EntityFilter = {},
    Debug = false,
    DebugVerbose = false,
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
        glitch     = { Enabled = false, Color = Color3.fromHex("#8100a6") },
        lotus      = { Enabled = false, Color = Color3.fromHex("#ff6ff7") },
    }
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

local function Register(inst, cat, label, opts)
    if Tracked[inst] then return end
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
    bb.Size = UDim2.fromOffset(240, 44)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.LightInfluence = 0
    bb.ResetOnSpawn = false
    bb.Enabled = false
    bb.Parent = Holder

    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.fromScale(1, 1)
    tl.Font = Enum.Font.GothamBold
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
        Known = opts and opts.Known, Key = opts and opts.Key, GeoT = 0, NoGeo = false, RoomNum = opts and opts.RoomNum,
        Dist = 0, Shown = false,
    }

    inst.AncestryChanged:Connect(function(_, parent)
        if not parent then RemoveEntry(inst) end
    end)

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
local HIDE_EXACT = { Wardrobe = "Wardrobe", Toolshed = "Tool Shed" }
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

local function Process(inst)
    if inst:IsA("ProximityPrompt") then
        local pn = inst.Name
        if pn == "HidePrompt" then
            local m = inst:FindFirstAncestorWhichIsA("Model")
            if m and m ~= CurrentRooms and m.Parent ~= CurrentRooms then
                if not HIDE_NAMES[m.Name] then Dbg("HIDE?", m) end
                Register(m, "wardrobes", HIDE_NAMES[m.Name] or m.Name)
            end
        elseif pn == "ModulePrompt" or pn == "HerbPrompt" then
            local t = ResolveTarget(inst)
            if not t or Tracked[t] or RegisterByName(t) then return end

            local nn = Norm(t.Name)
            if nn:find("sally", 1, true) then
                Register(t, "objectives", "Sally's Toy")
                return
            end

            local objText = inst.ObjectText
            local cands = { t.Name, objText, t:GetAttribute("DisplayName") }
            if pn == "HerbPrompt" then cands[#cands + 1] = "Green Herb" end
            local display = ResolveItem(cands)
            if not display then
                Dbg("ITEM?", t, "prompt=" .. pn .. " objectText=" .. tostring(objText))
            end
            local special = display and SPECIAL_CATS[display]
            if special then
                Register(t, special, display, { Known = true, Key = display })
            else
                Register(t, "items", display or ((objText ~= "" and objText) or t.Name), { Known = display ~= nil, Key = display })
            end
        elseif not KNOWN_PROMPTS[pn] then
            Dbg("PROMPT?", inst.Parent or inst, "prompt=" .. pn)
        end
        return
    end

    if inst:IsA("Model") or inst:IsA("BasePart") then
        if RegisterByName(inst) then return end
        if inst:IsA("Model") then
            local n = inst.Name
            if HIDE_EXACT[n] then
                Register(inst, "wardrobes", HIDE_EXACT[n])
            elseif ENTITY_EXACT[n] == "Snare" then
                Register(inst, "entities", "Snare", { Known = true, Key = "Snare" })
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

local function ScanRoom(room)
    task.spawn(function()
        local door = room:WaitForChild("Door", 10)
        if door then
            local num = tonumber(room.Name)
            Register(door, "doors", "Door " .. (num and (num + 1) or room.Name), {
                Part = door:FindFirstChild("Door") or GetPart(door),
                RoomNum = num,
            })
        end
    end)
    for _, d in ipairs(room:GetDescendants()) do
        pcall(Process, d)
    end
    room.DescendantAdded:Connect(function(d) pcall(Process, d) end)
end

task.spawn(function()
    CurrentRooms = Workspace:WaitForChild("CurrentRooms", 60)
    if not CurrentRooms then return end
    for _, room in ipairs(CurrentRooms:GetChildren()) do ScanRoom(room) end
    CurrentRooms.ChildAdded:Connect(ScanRoom)

    -- Entidades (directamente en Workspace) + entidades del Glitch Fragment
    local IGNORE = { CurrentRooms = true, Drops = true, Camera = true, Terrain = true }

    local function ProcessEntity(m, initial)
        if not m:IsA("Model") or Tracked[m] then return end
        if IGNORE[m.Name] or Players:GetPlayerFromCharacter(m) then return end

        local label = EntityLabel(m.Name)
        local known = label ~= nil
        if not known then
            if initial then return end -- no marcar modelos que ya existian
            Dbg("ENTITY?", m)
            label = m.Name
        end

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

    for _, c in ipairs(Workspace:GetChildren()) do ProcessEntity(c, true) end
    Workspace.ChildAdded:Connect(function(c) ProcessEntity(c, false) end)

    -- Glitched entities pueden aparecer anidadas: se detectan por su nombre oficial
    Workspace.DescendantAdded:Connect(function(d)
        if d:IsA("Model") and not Tracked[d] then
            for _, g in ipairs(GLITCH_TOKENS) do
                if d.Name:find(g[1], 1, true) then
                    ProcessEntity(d, false)
                    return
                end
            end
        end
    end)

    -- Items/oro tirados al suelo
    local drops = Workspace:WaitForChild("Drops", 30)
    if drops then
        for _, d in ipairs(drops:GetDescendants()) do pcall(Process, d) end
        drops.DescendantAdded:Connect(function(d) pcall(Process, d) end)
    end
end)

----------------------------------------------------
-- Render
----------------------------------------------------
local function FilterPasses(e)
    if e.Cat == "items" then
        if e.Known then return Cfg.ItemFilter[e.Key] == true end
        return Cfg.UnlistedItems
    elseif e.Cat == "entities" then
        if e.Known then return Cfg.EntityFilter[e.Key] == true end
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
            local ok = Cfg.Categories[e.Cat].Enabled and FilterPasses(e)
            if ok and e.Cat == "doors" and e.RoomNum and currentRoom and e.RoomNum < currentRoom then
                ok = false -- puertas de cuartos ya superados
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
    for i, e in ipairs(list) do
        local color = Cfg.Categories[e.Cat].Color

        if e.Cat == "doors" then
            e.Base = e.Base or e.Label
            e.Label = e.Base .. (e.Inst:FindFirstChild("Lock") and " [Locked]" or "")
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
            parts[#parts + 1] = string.format("[%d%s]", math.floor(d + 0.5), meters and "m" or " studs")
        end
        e.TL.Text = table.concat(parts, "\n")
        e.TL.TextColor3 = color
        e.TL.TextSize = Cfg.TextSize
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
        if Cfg.Tracers and e.Shown then
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
-- UI (pestana Visuals)
----------------------------------------------------
local Setters = {}

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

local function AddDropdown(tab, id, title, values, default, cb)
    local el = tab:Dropdown({ Title = title, Values = values, Value = default, Callback = cb })
    Setters[id] = function(v) pcall(function() el:Select(v) end) end
end

local function AddColor(tab, id, title, default, cb)
    local el
    local ok = pcall(function()
        el = tab:Colorpicker({ Title = title, Default = default, Callback = cb })
    end)
    if not ok then
        pcall(function()
            el = tab:ColorPicker({ Title = title, Default = default, Callback = cb })
        end)
    end
    Setters[id] = function(v) pcall(function() el:Set(v) end) end
end

local CATEGORY_UI = {
    { id = "doors",      title = "ESP Doors",     desc = "Marks each room's exit door (hides passed rooms)." },
    { id = "gold",       title = "ESP Gold",      desc = "Gold piles, with their value when available." },
    { id = "keys",       title = "ESP Key",       desc = "Keys, Electrical Room Key and Fuses." },
    { id = "wardrobes",  title = "ESP Wardrobes", desc = "Wardrobes and other hiding spots." },
    { id = "chests",     title = "ESP Chest",     desc = "Chests, locked and vine-covered." },
    { id = "items",      title = "ESP Items",     desc = "Pickup items (filter them below)." },
    { id = "objectives", title = "ESP Objectives", desc = "Levers, Library books, Breaker Poles and Sally's Toy." },
    { id = "stardust",   title = "ESP Stardust",  desc = "Stardust pickups." },
    { id = "glitch",     title = "ESP Glitch Fragment", desc = "The rare Glitch Fragment item." },
    { id = "lotus",      title = "ESP Lotus Petal", desc = "Lotus Petals (Outdoors)." },
    { id = "entities",   title = "ESP Entities",  desc = "Rush, Ambush, A-60, A-120, Eyes, Blitz." },
}

VisualsTab:Section({ Title = "ESP Toggles" })
for _, c in ipairs(CATEGORY_UI) do
    AddToggle(VisualsTab, "cat_" .. c.id, c.title, c.desc, false, function(v)
        Cfg.Categories[c.id].Enabled = v
    end)
end

VisualsTab:Section({ Title = "Colors" })
for _, c in ipairs(CATEGORY_UI) do
    AddColor(VisualsTab, "col_" .. c.id, c.title:gsub("ESP ", "") .. " Color", Cfg.Categories[c.id].Color, function(color)
        Cfg.Categories[c.id].Color = color
    end)
end

VisualsTab:Section({ Title = "Display" })
AddSlider(VisualsTab, "MaxDistance", "Max Distance", "Studs. Objects farther than this are hidden.", 50, 2000, Cfg.MaxDistance, function(v)
    Cfg.MaxDistance = v
end)
AddToggle(VisualsTab, "ShowName", "Show Names", nil, Cfg.ShowName, function(v) Cfg.ShowName = v end)
AddToggle(VisualsTab, "ShowDistance", "Show Distance", nil, Cfg.ShowDistance, function(v) Cfg.ShowDistance = v end)
AddDropdown(VisualsTab, "Unit", "Distance Unit", { "Meters", "Studs" }, Cfg.Unit, function(v) Cfg.Unit = v end)
AddSlider(VisualsTab, "TextSize", "Text Size", nil, 10, 24, Cfg.TextSize, function(v) Cfg.TextSize = v end)
AddSlider(VisualsTab, "FillPercent", "Fill Opacity (%)", "0 = outline only.", 0, 100, math.floor((1 - Cfg.FillTransparency) * 100), function(v)
    Cfg.FillTransparency = 1 - (v / 100)
end)

VisualsTab:Section({ Title = "Tracers" })
AddToggle(VisualsTab, "Tracers", "Tracers", "Lines from the screen to each object.", Cfg.Tracers, function(v) Cfg.Tracers = v end)
AddDropdown(VisualsTab, "TracerOrigin", "Tracer Origin", { "Bottom", "Center", "Top", "Mouse" }, Cfg.TracerOrigin, function(v)
    Cfg.TracerOrigin = v
end)
AddSlider(VisualsTab, "TracerThickness", "Tracer Thickness", nil, 1, 5, Cfg.TracerThickness, function(v)
    Cfg.TracerThickness = v
end)

VisualsTab:Section({ Title = "Item Filter" })
do
    local defaults = {}
    for _, n in ipairs(ITEM_NAMES) do defaults[#defaults + 1] = n end

    local dd = VisualsTab:Dropdown({
        Title = "Items to show",
        Desc = "Only applies to ESP Items.",
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
        Callback = function()
            for _, n in ipairs(ITEM_NAMES) do Cfg.ItemFilter[n] = true end
            Setters.ItemFilter(ITEM_NAMES)
        end
    })
    VisualsTab:Button({
        Title = "Clear All Items",
        Callback = function()
            Cfg.ItemFilter = {}
            Setters.ItemFilter({})
        end
    })
end
AddToggle(VisualsTab, "UnlistedItems", "Show Unlisted Items", "Items not in the list above (uses their internal name).", Cfg.UnlistedItems, function(v)
    Cfg.UnlistedItems = v
end)

VisualsTab:Section({ Title = "Entity Filter" })
do
    local defaults = {}
    for _, n in ipairs(ENTITY_LIST) do defaults[#defaults + 1] = n end

    local dd = VisualsTab:Dropdown({
        Title = "Entities to show",
        Desc = "Only applies to ESP Entities (includes Glitch Fragment entities).",
        Values = ENTITY_LIST,
        Value = defaults,
        Multi = true,
        AllowNone = true,
        Callback = function(selected)
            local map = {}
            for _, n in ipairs(selected or {}) do map[n] = true end
            Cfg.EntityFilter = map
        end
    })
    Setters.EntityFilter = function(list) pcall(function() dd:Select(list) end) end

    VisualsTab:Button({
        Title = "Select All Entities",
        Callback = function()
            for _, n in ipairs(ENTITY_LIST) do Cfg.EntityFilter[n] = true end
            Setters.EntityFilter(ENTITY_LIST)
        end
    })
    VisualsTab:Button({
        Title = "Clear All Entities",
        Callback = function()
            Cfg.EntityFilter = {}
            Setters.EntityFilter({})
        end
    })
end
AddToggle(VisualsTab, "UnlistedEntities", "Show Unlisted Entities", "New models that appear in Workspace and are not in the list (catches unknown/custom entities).", Cfg.UnlistedEntities, function(v)
    Cfg.UnlistedEntities = v
end)

----------------------------------------------------
-- MISC: Debug Mode
----------------------------------------------------
MiscTab:Section({ Title = "Debug Mode" })
AddToggle(MiscTab, "Debug", "Debug Mode", "Logs unrecognized items, entities and prompts with their full path.", false, function(v)
    Cfg.Debug = v
end)
AddToggle(MiscTab, "DebugVerbose", "Verbose Logging", "Also logs every object the ESP registers (needs Debug Mode on).", false, function(v)
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

----------------------------------------------------
-- Guardar / cargar config de Visuals
----------------------------------------------------
local SCALAR_KEYS = {
    "MaxDistance", "TextSize", "ShowName", "ShowDistance", "Unit",
    "Tracers", "TracerOrigin", "TracerThickness", "UnlistedItems", "UnlistedEntities",
}

local function VisualsSerialize()
    local out = { Cats = {}, ItemFilter = Cfg.ItemFilter, EntityFilter = Cfg.EntityFilter, FillTransparency = Cfg.FillTransparency }
    for _, k in ipairs(SCALAR_KEYS) do out[k] = Cfg[k] end
    for id, c in pairs(Cfg.Categories) do
        out.Cats[id] = { Enabled = c.Enabled, Color = { c.Color.R, c.Color.G, c.Color.B } }
    end
    return out
end

local function VisualsApply(data)
    if type(data) ~= "table" then return end

    for _, k in ipairs(SCALAR_KEYS) do
        if data[k] ~= nil then
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
                    Setters["cat_" .. id](c.Enabled)
                end
                if type(c.Color) == "table" and #c.Color == 3 then
                    cat.Color = Color3.new(c.Color[1], c.Color[2], c.Color[3])
                    Setters["col_" .. id](cat.Color)
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
    local im = MergeFilter(data.ItemFilter, ITEM_NAMES, Setters.ItemFilter)
    if im then Cfg.ItemFilter = im end
    local em = MergeFilter(data.EntityFilter, ENTITY_LIST, Setters.EntityFilter)
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
