local _, ns = ...

local EnemyDebuffs = {}
ns.EnemyDebuffs = EnemyDebuffs

local POOL_SIZE, MAX_PLATES = 20, 40
local POLL_STEP, POLL_STEPS = 0.1, 5
local DEDUPE = 1

local pool = {}
local byUnit = {}
local map = {}
local secretIds = {}
local lastFire = {}
local roster = {}
local pending = false
local party = false
local events

local function debuffMap(list)
    local m = {}
    for spellId, s in pairs(ns.Spells) do
        if s.track == "debuff" then
            for _, member in ipairs(list) do
                if ns.Cooldowns.Has(spellId, member.class, member.spec, member.talents) then
                    for _, id in ipairs(s.buffs or { spellId }) do
                        m[id] = m[id] or {}
                        m[id][#m[id] + 1] = spellId
                    end
                    break
                end
            end
        end
    end
    return m
end

local function fire(spells)
    local now = GetTime()
    for _, spellId in ipairs(spells) do
        if not lastFire[spellId] or now - lastFire[spellId] >= DEDUPE then
            lastFire[spellId] = now
            ns.tracker:External(spellId, nil)
        end
    end
end

local function scan(e)
    if byUnit[e.unit] ~= e then return end
    for id, spells in pairs(map) do
        local v, why = e.sensor:Read(id)
        if why == "secret" then secretIds[id] = true end
        if v ~= nil then
            if v and e.last[id] == false then fire(spells) end
            e.last[id] = v
        end
    end
end

local function poll(e)
    if e.ticker then e.ticker:Cancel() end
    e.ticker = C_Timer.NewTicker(POLL_STEP, function() scan(e) end, POLL_STEPS)
end

local function release(e)
    if e.ticker then e.ticker:Cancel() end
    e.frame:UnregisterAllEvents()
    byUnit[e.unit] = nil
    e.unit = nil
end

local function attach(unit)
    if not party or byUnit[unit] then return end
    local attackable = UnitCanAttack("player", unit)
    if issecretvalue(attackable) or not attackable then return end
    for _, e in ipairs(pool) do
        if e.sensor and not e.unit then
            e.unit, e.last = unit, {}
            byUnit[unit] = e
            e.sensor:SetUnit(unit)
            e.frame:RegisterUnitEvent("UNIT_AURA", unit)
            poll(e)
            return
        end
    end
end

local function detach(unit)
    local e = byUnit[unit]
    if e then release(e) end
end

local function newEntry()
    local e = {}
    e.frame = CreateFrame("Frame")
    e.frame:SetScript("OnEvent", function()
        if e.unit then poll(e) end
    end)
    return e
end

local function rebuild()
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    for _, e in ipairs(pool) do
        if e.unit then release(e) end
    end
    party = ns.Group.Mode() == "party"
    for _, event in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" }) do
        if party then events:RegisterEvent(event) else events:UnregisterEvent(event) end
    end
    map = party and debuffMap(roster) or {}
    local ids = {}
    for id in pairs(map) do ids[#ids + 1] = id end
    table.sort(ids)
    local build = party and #ids > 0
    for i = 1, POOL_SIZE do
        local e = pool[i]
        if not e then
            e = newEntry()
            pool[i] = e
        end
        if build then
            e.sensor = ns.Sensors.Build("nameplate" .. i, ids, "HARMFUL")
        elseif e.sensor then
            e.sensor:SetEnabled(false)
            e.sensor = nil
        end
    end
    if party then
        for i = 1, MAX_PLATES do
            local unit = "nameplate" .. i
            if UnitExists(unit) then attach(unit) end
        end
    end
end

function EnemyDebuffs.Status()
    local list = {}
    for id in pairs(secretIds) do
        local spells = map[id]
        list[#list + 1] = { id = id, name = spells and ns.Spells[spells[1]].name or tostring(id) }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return { secret = list, pool = POOL_SIZE }
end

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    roster = list
    rebuild()
end

events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        attach(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        detach(unit)
    elseif pending then
        rebuild()
    end
end)

function EnemyDebuffs:Enable()
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    rebuild()
end

ns.RegisterModule("EnemyDebuffs", EnemyDebuffs)
