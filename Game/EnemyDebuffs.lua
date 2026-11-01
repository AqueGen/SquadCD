-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local EnemyDebuffs = {}
ns.EnemyDebuffs = EnemyDebuffs

local POOL_SIZE, MAX_PLATES = 20, 40
local POLL_STEP, POLL_STEPS = 0.1, 5
local DEDUPE, SETTLE, OWN_CAST_WINDOW = 1, 0.3, 3

local pool = {}
local byUnit = {}
local overflow = {}
local map = {}
local noId = {}
local secretIds = {}
local lastFire = {}
local roster = {}
local pending = false
local party = false
local events

local function exists(unit)
    local v = UnitExists(unit)
    return not issecretvalue(v) and v == true
end

local function debuffMap(list)
    local m, missing = {}, {}
    for spellId, s in pairs(ns.Spells) do
        if s.track == "debuff" then
            for _, member in ipairs(list) do
                if ns.Cooldowns.Has(spellId, member.class, member.spec, member.talents, member.race, member.pets) then
                    if s.debuffs then
                        for _, id in ipairs(s.debuffs) do
                            m[id] = m[id] or {}
                            m[id][#m[id] + 1] = spellId
                        end
                    else
                        missing[#missing + 1] = spellId
                    end
                    break
                end
            end
        end
    end
    for _, spells in pairs(m) do table.sort(spells) end
    table.sort(missing)
    return m, missing
end

local function playerGuid()
    for _, member in ipairs(roster) do
        if member.unit == "player" then return member.guid end
    end
end

local function fire(spells)
    local now = GetTime()
    local own = playerGuid()
    for _, spellId in ipairs(spells) do
        if not lastFire[spellId] or now - lastFire[spellId] >= DEDUPE then
            lastFire[spellId] = now
            if not (own and ns.tracker:UsedWithin(own, spellId, OWN_CAST_WINDOW)) then
                ns.tracker:External(spellId, nil, own)
            end
        end
    end
end

local function scan(e)
    if byUnit[e.unit] ~= e then return end
    local settling = GetTime() - e.attachedAt < SETTLE
    for id, spells in pairs(map) do
        if not secretIds[id] then
            local v, why = e.sensor:Read(id)
            if why == "secret" then secretIds[id] = true end
            if v ~= nil then
                if v and e.last[id] == false and not settling then fire(spells) end
                e.last[id] = v
            end
        end
    end
end

local function poll(e)
    e.left = POLL_STEPS
    if e.ticker then return end
    e.ticker = C_Timer.NewTicker(POLL_STEP, function()
        e.left = e.left - 1
        if e.left <= 0 then
            e.ticker:Cancel()
            e.ticker = nil
        end
        scan(e)
    end)
end

local attach

local function release(e)
    if e.ticker then e.ticker:Cancel() end
    e.ticker = nil
    e.frame:UnregisterAllEvents()
    byUnit[e.unit] = nil
    e.unit = nil
end

function attach(unit)
    if not party or ns.Group.Mode() ~= "party" or byUnit[unit] then return end
    local attackable = UnitCanAttack("player", unit)
    if issecretvalue(attackable) or not attackable then return end
    for _, e in ipairs(pool) do
        if e.sensor and not e.unit then
            e.unit, e.last, e.attachedAt = unit, {}, GetTime()
            byUnit[unit] = e
            overflow[unit] = nil
            e.sensor:SetUnit(unit)
            e.frame:RegisterUnitEvent("UNIT_AURA", unit)
            poll(e)
            return
        end
    end
    overflow[unit] = true
end

local function detach(unit)
    overflow[unit] = nil
    local e = byUnit[unit]
    if not e then return end
    release(e)
    local queued = {}
    for u in pairs(overflow) do queued[#queued + 1] = u end
    table.sort(queued)
    for _, u in ipairs(queued) do
        if exists(u) then
            attach(u)
            if byUnit[u] then return end
        else
            overflow[u] = nil
        end
    end
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
    secretIds = {}
    for _, e in ipairs(pool) do
        if e.unit then release(e) end
    end
    overflow = {}
    party = ns.Group.Mode() == "party"
    for _, event in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" }) do
        if party then events:RegisterEvent(event) else events:UnregisterEvent(event) end
    end
    map, noId = {}, {}
    if party then map, noId = debuffMap(roster) end
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
            if exists(unit) then attach(unit) end
        end
    end
end

local function named(spellId)
    return { id = spellId, name = ns.Spells[spellId].name }
end

function EnemyDebuffs.SecretIds()
    return secretIds
end

function EnemyDebuffs.Status()
    local secret, missing = {}, {}
    for id in pairs(secretIds) do
        local spells = map[id]
        secret[#secret + 1] = { id = id, name = spells and ns.Spells[spells[1]].name or tostring(id) }
    end
    table.sort(secret, function(a, b) return a.id < b.id end)
    for _, spellId in ipairs(noId) do missing[#missing + 1] = named(spellId) end
    return { secret = secret, noId = missing, pool = POOL_SIZE }
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
    else
        secretIds = {}
        if pending then rebuild() end
    end
end)

function EnemyDebuffs:Enable()
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    rebuild()
end

ns.RegisterModule("EnemyDebuffs", EnemyDebuffs)
