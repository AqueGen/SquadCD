local _, ns = ...

local Kicks = {}
ns.Kicks = Kicks

local SNAPSHOT_DELAY = 0.3
local INTERRUPTS = 5
local SESSION_CURRENT = 1

local frame = CreateFrame("Frame")
local CAST_EVENTS = { "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP" }
local roster, baseline = {}, {}

function Kicks.Attribute(before, after)
    local who
    for guid, n in pairs(after) do
        if n > (before[guid] or 0) then
            if who then return nil end
            who = guid
        end
    end
    return who
end

function Kicks.SpellOf(member)
    local best
    for id, s in pairs(ns.Spells) do
        if s.type == "Kick" and (not best or id < best)
            and ns.Cooldowns.Has(id, member.class, member.spec, member.talents) then
            best = id
        end
    end
    return best
end

local function snapshot()
    local snap = {}
    for _, m in ipairs(roster) do
        local ok, src = pcall(C_DamageMeter.GetCombatSessionSourceFromType, SESSION_CURRENT, INTERRUPTS, m.guid)
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
            if spell then ns.tracker:Used(guid, spell, true) end
            return
        end
    end
end

local function resolve()
    local after = snapshot()
    credit(Kicks.Attribute(baseline, after))
    for guid, n in pairs(after) do baseline[guid] = n end
end

frame:SetScript("OnEvent", function(_, event, unit, _, _, by)
    if event == "PLAYER_REGEN_ENABLED" then
        for guid, n in pairs(snapshot()) do baseline[guid] = n end
        return
    end
    if issecretvalue(unit) or type(unit) ~= "string" or not unit:find("^nameplate") then return end
    if not issecretvalue(by) and by ~= nil then
        credit(by)
        return
    end
    C_Timer.After(SNAPSHOT_DELAY, resolve)
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
    baseline = party and snapshot() or {}
end
