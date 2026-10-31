-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local OwnCasts = {}
ns.OwnCasts = OwnCasts

local frame = CreateFrame("Frame")
local stats = { secret = 0, used = 0 }
local replacers, potions = {}, {}
local me

for id, s in pairs(ns.Spells) do
    for _, r in ipairs(s.replaces or {}) do
        replacers[r] = replacers[r] or {}
        table.insert(replacers[r], id)
    end
end
for _, list in pairs(replacers) do table.sort(list) end
for _, p in ipairs(ns.Potions) do potions[p.spell] = true end

function OwnCasts.Resolve(spellId, member)
    if potions[spellId] then return "potion" end
    local function has(id) return member ~= nil and ns.Cooldowns.Has(id, member.class, member.spec, member.talents, member.race) end
    if ns.Spells[spellId] and has(spellId) then return spellId end
    for _, id in ipairs(replacers[spellId] or {}) do
        if has(id) then return id end
    end
    if ns.Spells[spellId] then return spellId end
end

function OwnCasts.Stats()
    return stats
end

frame:SetScript("OnEvent", function(_, _, unit, _, spellId)
    if issecretvalue(unit) or unit ~= "player" then return end
    if issecretvalue(spellId) then
        stats.secret = stats.secret + 1
        return
    end
    local id = OwnCasts.Resolve(spellId, me)
    if not id then return end
    local guid = UnitGUID("player")
    if issecretvalue(guid) or guid == nil then return end
    stats.used = stats.used + 1
    ns.tracker:Used(guid, id, true)
end)

function OwnCasts.Enable()
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end

function OwnCasts.Disable()
    frame:UnregisterAllEvents()
end

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    me = nil
    for _, m in ipairs(list) do
        if m.unit == "player" then me = m end
    end
    if ns.Group.Mode() == "party" then OwnCasts.Enable() else OwnCasts.Disable() end
end
