local _, ns = ...

local Display = {}
ns.Display = Display

local INTERVAL = 0.1
local LATE_RESCAN = 2

local live = { members = {} }
local source = live
local pending = false
local driver = CreateFrame("Frame")
local elapsed = 0

local function tick()
    local tracker = source.tracker or ns.tracker
    if not tracker then return end
    if source == live then tracker:Tick() end
    local now = GetTime()
    ns.Rows.Update(tracker, now)
    ns.Panel.Update(tracker, now)
end

local function named(m)
    if m.name then return m end
    local name = UnitName(m.unit)
    if issecretvalue(name) or name == nil then return m end
    return setmetatable({ name = name }, { __index = m })
end

local function collect(members)
    local rows, byType = {}, {}
    local own = UnitGUID("player")
    if issecretvalue(own) then own = nil end
    for _, raw in ipairs(members) do
        local m = named(raw)
        local spells = ns.LayoutRules.SpellsFor(m, m.guid == own or m.own, ns.DB.spells)
        local row, panel = ns.LayoutRules.Split(spells, ns.DB.placement)
        rows[#rows + 1] = { member = m, spells = row }
        for t, list in pairs(panel) do
            byType[t] = byType[t] or {}
            for _, spell in ipairs(list) do
                table.insert(byType[t], { member = m, spell = spell })
            end
        end
    end
    local groups = {}
    for _, t in ipairs(ns.LayoutRules.TYPES) do
        if byType[t] then groups[#groups + 1] = { type = t, entries = byType[t] } end
    end
    return rows, groups
end

local function onUpdate(_, dt)
    elapsed = elapsed + dt
    if elapsed < INTERVAL then return end
    elapsed = 0
    tick()
end

local generation = 0

function Display.Rebuild(late)
    if not ns.DB then return end
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    local members = source.members
    if #members == 0 then
        ns.Rows.Hide()
        ns.Panel.Hide()
        driver:SetScript("OnUpdate", nil)
        return
    end
    ns.Anchors.Scan()
    local rows, groups = collect(members)
    ns.Rows.Build(rows)
    ns.Panel.Build(groups)
    tick()
    driver:SetScript("OnUpdate", onUpdate)
    if late then return end
    generation = generation + 1
    local mine = generation
    C_Timer.After(LATE_RESCAN, function()
        if mine == generation and not InCombatLockdown() then Display.Rebuild(true) end
    end)
end

function Display.SetSource(src)
    source = src or live
    Display.Rebuild()
end

function Display.IsLive()
    return source == live
end

driver:SetScript("OnEvent", function()
    if pending or #source.members > 0 then Display.Rebuild() end
end)
driver:RegisterEvent("PLAYER_REGEN_ENABLED")

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    live.members = list
    if source == live then Display.Rebuild() end
end
