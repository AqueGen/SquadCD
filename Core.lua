local addonName, ns = ...

ns.DEFAULTS = {
    version = 1,
    placement = {
        Personal = "Row", Burst = "Row", Racial = "Row", Potion = "Row",
        External = "Panel", Kick = "Panel", Stun = "Panel", CC = "Panel", Group = "Panel",
        Dispel = "Off", Purge = "Off", Movement = "Off",
    },
    row = { side = "LEFT", size = 24, spacing = 2, max = 8 },
    panel = { point = { "CENTER", 0, -200 }, size = 22, locked = false },
    spells = {},
    window = {},
    timers = {},
}

local function copy(v)
    if type(v) ~= "table" then
        return v
    end
    local t = {}
    for k, x in pairs(v) do
        t[k] = copy(x)
    end
    return t
end

local function fill(db, defaults)
    for k, v in pairs(defaults) do
        if db[k] == nil then
            db[k] = copy(v)
        elseif type(v) == "table" and type(db[k]) == "table" then
            fill(db[k], v)
        end
    end
end

function ns.Defaults(db)
    fill(db, ns.DEFAULTS)
    return db
end

local modules = {}

function ns.RegisterModule(name, module)
    if modules[name] then
        return
    end
    modules[name] = module
    modules[#modules + 1] = module
end

local subcommands = {}

function ns.Slash(sub, fn)
    subcommands[sub:lower()] = fn
end

SLASH_HUDDLE1 = "/huddle"
SlashCmdList.HUDDLE = function(msg)
    local sub, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    if sub == "" then
        if ns.ToggleWindow then
            ns.ToggleWindow()
        end
        return
    end
    local fn = subcommands[sub:lower()]
    if fn then
        fn(rest)
        return
    end
    local names = {}
    for name in pairs(subcommands) do
        names[#names + 1] = name
    end
    table.sort(names)
    print("Huddle: unknown command. Use /huddle " .. (#names > 0 and table.concat(names, " | ") or "(none registered)"))
end

function Huddle_OnCompartmentClick()
    if ns.ToggleWindow then
        ns.ToggleWindow()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then
            return
        end
        HuddleDB = HuddleDB or {}
        ns.DB = ns.Defaults(HuddleDB)
    else
        for _, module in ipairs(modules) do
            if module.Enable then
                xpcall(function() module:Enable() end, geterrorhandler())
            end
        end
    end
end)
