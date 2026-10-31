-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Demo = {}
ns.Demo = Demo

local MEMBERS = {
    { guid = "SquadCDDemo1", unit = "player", class = "DEMONHUNTER", spec = 581, name = "Vexhal", race = 10, own = true },
    { guid = "SquadCDDemo2", unit = "party1", class = "PRIEST", spec = 256, name = "Lumenia" },
    { guid = "SquadCDDemo3", unit = "party2", class = "MAGE", spec = 64, name = "Frostwyn", race = 2, unread = true },
    { guid = "SquadCDDemo4", unit = "party3", class = "PALADIN", spec = 70, name = "Aurik" },
    { guid = "SquadCDDemo5", unit = "party4", class = "MONK", spec = 269, name = "Kaito" },
}
local CHARGED = 204021

local mode = "Off"

local function fits(s, spec)
    if #(s.specs or {}) == 0 then return true end
    for _, id in ipairs(s.specs) do
        if id == spec then return true end
    end
    return false
end

local function talentsFor(class, spec)
    local ids = {}
    for id, s in pairs(ns.Spells) do
        if s.class == class and s.talentGated and fits(s, spec) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    local t, taken = {}, {}
    for _, id in ipairs(ids) do
        local s = ns.Spells[id]
        if not taken[s.type] or id == CHARGED then
            taken[s.type] = true
            t[id] = 1
        end
    end
    if class == ns.Spells[CHARGED].class then
        for add in pairs(ns.Spells[CHARGED].chargeAdds or {}) do t[add] = 1 end
    end
    return t
end

local function members(count)
    local list = {}
    for i = 1, count do
        local m = MEMBERS[i]
        list[i] = {
            guid = m.guid, unit = m.unit, class = m.class, spec = m.spec, race = m.race, name = m.name, own = m.own,
            talents = not m.unread and talentsFor(m.class, m.spec) or nil,
        }
    end
    return list
end

local function first(m, kind)
    for _, s in ipairs(ns.LayoutRules.SpellsFor(m, m.own, {})) do
        if s.type == kind and s.id ~= CHARGED then return s.id end
    end
end

local function start(count)
    local shift
    local tracker = ns.Tracker.New(function() return GetTime() - (shift or 0) end)
    local list = members(count)
    tracker:SetMembers(list)
    local function used(m, id, ago, certain)
        if not id then return end
        shift = ago
        tracker:Used(m.guid, id, certain)
        shift = nil
    end
    local dh, priest, mage, paladin, monk = unpack(list)
    used(dh, first(dh, "Personal"), 20, true)
    used(dh, CHARGED, 5, true)
    if count > 1 then
        used(priest, first(priest, "External"), 30, false)
        used(mage, first(mage, "Kick"), 8, true)
        used(mage, first(mage, "Personal"), 60, true)
        used(paladin, first(paladin, "Stun"), 15, true)
        used(paladin, "potion", 100, true)
        used(monk, first(monk, "Burst"), 50, true)
    end
    ns.Display.SetSource({ members = list, tracker = tracker })
end

function Demo.Set(next)
    if next ~= "Off" and next ~= "Me" and next ~= "Group" then return end
    if InCombatLockdown() then
        print("SquadCD: demo is available out of combat only.")
        return
    end
    mode = next
    if mode == "Off" then
        ns.Display.SetSource(nil)
    else
        start(mode == "Me" and 1 or #MEMBERS)
    end
    ns.EditMode.DemoChanged()
    if ns.Window then ns.Window.Refresh() end
end

function Demo.Mode()
    return mode
end

function Demo.Running()
    return mode ~= "Off"
end

function Demo.Toggle()
    Demo.Set(mode == "Off" and "Group" or "Off")
end

function SquadCD_Demo()
    Demo.Toggle()
end

local SLASH_MODES = { off = "Off", me = "Me", group = "Group" }

ns.Slash("demo", function(rest)
    local picked = SLASH_MODES[(rest or ""):lower()]
    if picked then Demo.Set(picked) else Demo.Toggle() end
end)
