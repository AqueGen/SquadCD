local addonName, ns = ...

ns.DEFAULTS = {
    version = 2,
    layout = ns.LayoutModel.Defaults(),
    row = { point = { "CENTER", -360, 120 } },
    spells = {},
    window = {},
    timers = {},
}

local copy = ns.Copy

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
    ns.LayoutModel.Migrate(db)
    db.layout = ns.LayoutModel.Normalize(db.layout)
    db.placement, db.panel = nil, nil
    if type(db.row) == "table" then db.row = { point = db.row.point } end
    local defaults = {}
    for k, v in pairs(ns.DEFAULTS) do
        if k ~= "layout" then defaults[k] = v end
    end
    fill(db, defaults)
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
