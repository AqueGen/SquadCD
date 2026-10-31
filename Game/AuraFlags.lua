-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local AuraFlags = {}
ns.AuraFlags = AuraFlags

local FILTERS = {
    { "B", "HELPFUL|BIG_DEFENSIVE" },
    { "E", "HELPFUL|EXTERNAL_DEFENSIVE" },
    { "I", "HELPFUL|IMPORTANT" },
    { "R", "HELPFUL|RAID" },
}
local PARTY = { party1 = true, party2 = true, party3 = true, party4 = true }
AuraFlags.SATED = { 57723, 57724, 80354, 95809, 160455, 264689, 390435 }

local frame = CreateFrame("Frame")
local live = { keys = {}, ids = { plain = 0, secret = 0 } }

local function plain(v)
    return v ~= nil and not issecretvalue(v)
end

-- IsAuraFilteredOutByInstanceID answers false when the aura matches the filter.
local function letter(ok, filtered, l)
    if not ok then return "x" end
    if issecretvalue(filtered) then return "s" end
    if filtered == false then return l end
    if filtered == true then return "-" end
    return "x"
end

function AuraFlags.Key(unit, instanceId)
    local out = {}
    for i, f in ipairs(FILTERS) do
        local ok, filtered = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, instanceId, f[2])
        out[i] = letter(ok, filtered, f[1])
    end
    return table.concat(out)
end

local function spellFlag(fn, id, l)
    local ok, v = pcall(fn, id)
    if not ok then return "x" end
    if issecretvalue(v) then return "s" end
    return v and l or "-"
end

function AuraFlags.SpellKey(id)
    return spellFlag(C_UnitAuras.AuraIsBigDefensive, id, "B")
        .. spellFlag(C_Spell.IsExternalDefensive, id, "E")
        .. spellFlag(C_Spell.IsSpellImportant, id, "I")
        .. "?"
end

function AuraFlags.Ambiguity(entries)
    local groups = {}
    for _, e in ipairs(entries) do
        local g = (e.class or "ANY") .. ":" .. e.key
        groups[g] = groups[g] or {}
        local list = groups[g]
        list[#list + 1] = e.id
    end
    local unique, shared, none = 0, 0, 0
    for g, list in pairs(groups) do
        if g:find(":%-%-%-") then
            none = none + #list
        elseif #list == 1 then
            unique = unique + 1
        else
            shared = shared + #list
        end
    end
    return { unique = unique, shared = shared, none = none, groups = groups }
end

function AuraFlags.Catalog()
    local entries, seen = {}, {}
    for _, s in pairs(ns.Spells) do
        if s.track == "buff" or s.track == "target" then
            for _, id in ipairs(s.buffs or {}) do
                if not seen[id] then
                    seen[id] = true
                    entries[#entries + 1] = { id = id, class = s.class, key = AuraFlags.SpellKey(id) }
                end
            end
        end
    end
    table.sort(entries, function(a, b) return a.id < b.id end)
    return entries
end

function AuraFlags.Secrecy(entries)
    local counts = {}
    for _, e in ipairs(entries) do
        local ok, v = pcall(C_Secrets.ShouldSpellAuraBeSecret, e.id)
        local k = not ok and "error" or issecretvalue(v) and "secret" or tostring(v)
        counts[k] = (counts[k] or 0) + 1
    end
    return counts
end

function AuraFlags.Sated()
    local out = {}
    for _, id in ipairs(AuraFlags.SATED) do
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
        out[#out + 1] = { id = id, state = not ok and "error" or issecretvalue(aura) and "secret" or aura and "present" or "none" }
    end
    return out
end

function AuraFlags.Live()
    return live
end

local function record(unit, aura)
    local id = aura.auraInstanceID
    if not plain(id) then
        live.ids.secret = live.ids.secret + 1
        return
    end
    live.ids.plain = live.ids.plain + 1
    local key = AuraFlags.Key(unit, id)
    live.keys[key] = (live.keys[key] or 0) + 1
    local spell = aura.spellId
    if plain(spell) and type(spell) == "number" then
        ns.DB.probe = ns.DB.probe or {}
        ns.DB.probe.auraKeys = ns.DB.probe.auraKeys or {}
        ns.DB.probe.auraKeys[spell] = key
    end
end

frame:SetScript("OnEvent", function(_, _, unit, info)
    if not PARTY[unit] or not plain(info) or not plain(info.addedAuras) then return end
    for _, aura in ipairs(info.addedAuras) do
        if plain(aura) then record(unit, aura) end
    end
end)

function AuraFlags:Enable()
    frame:RegisterEvent("UNIT_AURA")
end

ns.RegisterModule("AuraFlags", AuraFlags)
