-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
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

local NONE = {}
local sight = {}

local function tick()
    local tracker = source.tracker or ns.tracker
    if not tracker then return end
    local isLive = source == live
    if isLive then tracker:Tick() end
    sight.live = isLive
    sight.plain = not isLive or ns.Sensors.Mode() == "plain"
    sight.secret = isLive and ns.EnemyDebuffs.SecretIds() or NONE
    sight.timers = ns.DB.layout.timers
    local now = GetTime()
    ns.Rows.Update(tracker, now, sight)
    ns.Panel.Update(tracker, now, sight)
end

local function named(m)
    if m.name then return m end
    local name = UnitName(m.unit)
    if issecretvalue(name) or name == nil then return m end
    return setmetatable({ name = name }, { __index = m })
end

local function collect(members)
    local list = {}
    local own = UnitGUID("player")
    if issecretvalue(own) then own = nil end
    for i, raw in ipairs(members) do
        local m = named(raw)
        local isOwn = m.guid == own or m.own or false
        list[i] = { member = m, own = isOwn, spells = ns.LayoutRules.SpellsFor(m, isOwn, ns.DB.spells) }
    end
    return ns.LayoutRules.Route(ns.DB.layout, list)
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
    if InCombatLockdown() or ns.EditMode.Dragging() then
        pending = true
        return
    end
    local forced = pending or not late
    pending = false
    local members = source.members
    if #members == 0 then
        ns.Rows.Hide()
        ns.Panel.Hide()
        ns.EditMode.Refresh()
        driver:SetScript("OnUpdate", nil)
        return
    end
    local solo = ns.Group.Mode() == "solo"
    if not ns.Anchors.Scan(solo) and not forced then return end
    local lines, rows = collect(members)
    ns.Rows.Build(rows, solo and source == live)
    ns.Panel.Build(lines)
    ns.EditMode.Refresh()
    tick()
    driver:SetScript("OnUpdate", onUpdate)
    if late then return end
    generation = generation + 1
    local mine = generation
    C_Timer.After(LATE_RESCAN, function()
        if mine == generation and not InCombatLockdown() then Display.Rebuild(true) end
    end)
end

function Display.Lines(members)
    return (collect(members))
end

function Display.Route(members)
    return collect(members)
end

local warned = false
local listeners = {}

function Display.OnChanged(fn)
    listeners[#listeners + 1] = fn
end

function Display.Changed()
    if InCombatLockdown() and not warned then
        warned = true
        print("SquadCD: the change applies when combat ends.")
    end
    Display.Rebuild()
    for _, fn in ipairs(listeners) do fn() end
end

function Display.Flush()
    if pending then Display.Rebuild() end
end

function Display.SetSource(src)
    source = src or live
    Display.Rebuild()
end

function Display.HasMembers()
    return #live.members > 0
end

function Display.IsLive()
    return source == live
end

driver:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then warned = false end
    if event ~= "PLAYER_REGEN_ENABLED" then
        Display.Rebuild()
    elseif pending then
        Display.Rebuild()
    elseif #source.members > 0 then
        Display.Rebuild(true)
    end
end)
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("DISPLAY_SIZE_CHANGED")
driver:RegisterEvent("UI_SCALE_CHANGED")

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    live.members = list
    if source == live then Display.Rebuild() end
end
