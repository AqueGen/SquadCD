-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Kicks = {}
ns.Kicks = Kicks

local INTERRUPTS = 5
local SESSION_OVERALL = 0

local PRIMARY = {
    [65] = 96231, [66] = 96231, [70] = 96231,
    [102] = 78675, [103] = 106839, [104] = 106839,
    [253] = 147362, [254] = 147362, [255] = 187707,
}

local frame = CreateFrame("Frame")
local CAST_EVENTS = { "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP" }
local roster, baseline, credited = {}, {}, {}
local stats = { attributed = 0 }

function Kicks.Stats()
    return stats
end

function Kicks.Deltas(before, after)
    local list = {}
    for guid, n in pairs(after) do
        if before[guid] and n > before[guid] then list[#list + 1] = guid end
    end
    table.sort(list)
    return list
end

function Kicks.Attribute(before, after)
    local list = Kicks.Deltas(before, after)
    if #list == 1 then return list[1] end
end

function Kicks.SpellOf(member)
    local function has(id) return ns.Cooldowns.Has(id, member.class, member.spec, member.talents, member.race, member.pets) end
    local primary = PRIMARY[member.spec]
    if primary and has(primary) then return primary end
    local owned, free, gated
    for id, s in pairs(ns.Spells) do
        if s.type == "Kick" and has(id) then
            local owns = false
            for _, spec in ipairs(s.specs or {}) do
                if spec == member.spec then owns = true end
            end
            local tier = owns and 1 or (not s.talentGated and 2 or 3)
            if tier == 1 then
                owned = (not owned or id < owned) and id or owned
            elseif tier == 2 then
                free = (not free or id < free) and id or free
            else
                gated = (not gated or id < gated) and id or gated
            end
        end
    end
    return owned or free or gated
end

local function snapshot()
    local snap = {}
    if InCombatLockdown() then return snap end
    for _, m in ipairs(roster) do
        local ok, src = pcall(C_DamageMeter.GetCombatSessionSourceFromType, SESSION_OVERALL, INTERRUPTS, m.guid)
        if ok and not issecretvalue(src) and type(src) == "table" then
            local total = src.totalAmount
            if not issecretvalue(total) and type(total) == "number" then snap[m.guid] = total end
        end
    end
    return snap
end

local function credit(guid)
    for _, m in ipairs(roster) do
        if m.guid == guid then
            local spell = Kicks.SpellOf(m)
            if spell then
                stats.attributed = stats.attributed + 1
                ns.tracker:Used(guid, spell, true)
            end
            return
        end
    end
end

local function settle()
    local after = snapshot()
    local own
    for _, m in ipairs(roster) do
        if m.unit == "player" then own = m.guid end
    end
    for _, guid in ipairs(Kicks.Deltas(baseline, after)) do
        if not credited[guid] and guid ~= own then credit(guid) end
    end
    for guid, n in pairs(after) do baseline[guid] = n end
    credited = {}
end

frame:SetScript("OnEvent", function(_, event, unit, _, _, by)
    if event == "PLAYER_REGEN_ENABLED" then
        settle()
        return
    end
    if issecretvalue(unit) or type(unit) ~= "string" or not unit:find("^nameplate") then return end
    local hostile = UnitCanAttack("player", unit)
    if issecretvalue(hostile) or not hostile then return end
    if issecretvalue(by) or by == nil then return end
    credited[by] = true
    credit(by)
end)

-- Own kick result: a kick cast is a hit when an interrupt credited to the player follows within WAIT, else a miss.
local WAIT, SHOW = 1, 3
local own

local hits = {}

function Kicks.OwnResult(now)
    if not own or now - own.at > SHOW then return nil end
    if own.hit then return "hit" end
    if own.late then return "late" end
    return now - own.at > WAIT and "miss" or "cast"
end

-- A party member's interrupt seen on an enemy unit, shown on their bar like your own hit.
function Kicks.HitResult(guid, now)
    local at = guid and hits[guid]
    if at and now - at <= SHOW then return "hit" end
end

local ownEvents = CreateFrame("Frame")
ownEvents:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
ownEvents:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
ownEvents:SetScript("OnEvent", function(_, event, unit, _, spellId, by)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if issecretvalue(spellId) then return end
        local s = ns.Spells[spellId]
        if s and s.type == "Kick" then own = { at = GetTime(), hit = false } end
        return
    end
    if issecretvalue(by) or by == nil then return end
    local now = GetTime()
    hits[by] = now
    if not own or own.hit or now - own.at > WAIT then return end
    if by == UnitGUID("player") then own.hit = true else own.late = true end
end)

-- Can party members' targets (marks, names) be read at all under 12.x? Answers decide the kick-target feature.
local function readout(fn, unit)
    local ok, v = pcall(fn, unit)
    if not ok then return "error" end
    if issecretvalue(v) then return "secret" end
    return tostring(v)
end

function Kicks.TargetProbe()
    local lines = {}
    for _, unit in ipairs({ "focus", "party1target", "party2target", "party3target", "party4target" }) do
        lines[#lines + 1] = ("%s: exists %s, mark %s, name %s"):format(unit,
            readout(UnitExists, unit), readout(GetRaidTargetIndex, unit), readout(UnitName, unit))
    end
    return lines
end

ns.Slash("targetprobe", function()
    for _, line in ipairs(Kicks.TargetProbe()) do print("SquadCD targetprobe: " .. line) end
end)

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    roster = list
    local party = ns.Group.Mode() == "party"
    for _, event in ipairs(CAST_EVENTS) do
        if party then frame:RegisterEvent(event) else frame:UnregisterEvent(event) end
    end
    if party then frame:RegisterEvent("PLAYER_REGEN_ENABLED") else frame:UnregisterEvent("PLAYER_REGEN_ENABLED") end
    local kept = {}
    for _, m in ipairs(party and list or {}) do kept[m.guid] = baseline[m.guid] end
    baseline = kept
    for guid, n in pairs(snapshot()) do baseline[guid] = baseline[guid] or n end
end
