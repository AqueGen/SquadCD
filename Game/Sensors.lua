-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Sensors = {}
ns.Sensors = Sensors

local POLL_STEP, POLL_STEPS = 0.1, 5
local SELF_TEST_DELAY = 0.5
local OWN_CAST_WINDOW = 3

local mode, reason = "unavailable", "self-test has not run"
local needTest, running, judgeLater, rechecked = true, false, false, false
local containers = {}
local watches = {}
local active = {}
local pending = false
local selfTest
local stats, seen = {}, {}
local roster = {}

local Sensor = {}
Sensor.__index = Sensor

local function readout(ok, v)
    if not ok then return nil, "error" end
    if issecretvalue(v) then return nil, "secret" end
    if type(v) ~= "boolean" then return nil, "error" end
    return v
end

function Sensor:Read(buffId)
    local probe = self.probes[buffId]
    if not probe then return nil, "error" end
    return readout(pcall(ns.Probes.Lit, probe))
end

local function newProbe(unit, filter, id)
    return ns.Probes.New(unit, filter, { id })
end

local function container(unit)
    local c = containers[unit]
    if not c then
        c = { probes = {} }
        containers[unit] = c
    end
    return c
end

function Sensor:SetUnit(unit)
    self.unit = unit
    for _, f in pairs(self.probes) do ns.Probes.Point(f, unit) end
end

function Sensor:SetEnabled(on)
    for _, f in pairs(self.probes) do ns.Probes.Enable(f, on) end
end

function Sensors.Build(unit, buffIds, filter)
    filter = filter or "HELPFUL"
    local c = container(unit)
    if c.broken then return nil, c.broken end
    local wanted, probes = {}, {}
    for _, id in ipairs(buffIds) do
        local key = filter .. id
        wanted[key] = true
        local f = c.probes[key]
        if not f then
            local why
            f, why = newProbe(unit, filter, id)
            if not f then
                c.broken = why
                return nil, why
            end
            c.probes[key] = f
        end
        pcall(f.SetEnabled, f, true)
        probes[id] = f
    end
    for key, f in pairs(c.probes) do
        if not wanted[key] then pcall(f.SetEnabled, f, false) end
    end
    c.filter = filter
    return setmetatable({ unit = unit, probes = probes, c = c }, Sensor)
end

local function setEnabled(unit, on)
    local c = containers[unit]
    if not c then return end
    for _, f in pairs(c.probes) do pcall(f.SetEnabled, f, on) end
end

function Sensors.Mode()
    return mode, reason
end

function Sensors.Stats()
    return stats, seen
end

local function fail(why, retry)
    mode, reason, needTest = "unavailable", why, retry
end

local loose = {}

function Sensors.Geometry(unit, id)
    local key = unit .. ":" .. id
    local f = loose[key]
    if not f then
        local why
        f, why = newProbe(unit, "HELPFUL", id)
        if not f then return why end
        loose[key] = f
        pcall(f.SetEnabled, f, true)
    end
    local v, why = readout(pcall(ns.Probes.Lit, f))
    local okW, width = pcall(f.GetWidth, f)
    local w = not okW and "error" or issecretvalue(width) and "secret" or tostring(width)
    return ("hit %s, width %s"):format(why or tostring(v), w)
end

local function verdict(buffV, buffWhy, ctrlV, ctrlWhy, when)
    if buffWhy == "secret" or ctrlWhy == "secret" then
        local s = selfTest or {}
        mode, reason, needTest = "secret", ("aura readout is secret%s (buff %s %s, control %s %s)"):format(
            when, tostring(s.id), buffWhy or tostring(buffV), tostring(s.control), ctrlWhy or tostring(ctrlV)), false
    elseif buffWhy or ctrlWhy then
        fail("aura readout failed" .. when, false)
    elseif ctrlV then
        fail("aura readout is always shown (control buff read as present)" .. when, false)
    elseif buffV then
        mode, reason, needTest = "plain", nil, false
    else
        return false
    end
    return true
end

local function readSelfTest()
    local s = selfTest
    local v, why = s.sensor:Read(s.id)
    local cv, cwhy = s.sensor:Read(s.control)
    return v, why, cv, cwhy
end

local function control(own, id)
    local mine = { [id] = true }
    for _, s in pairs(ns.Spells) do
        if s.buffs and (s.class == nil or s.class == own or s.track == "target") then
            for _, b in ipairs(s.buffs) do mine[b] = true end
        end
    end
    local best
    for _, s in pairs(ns.Spells) do
        for _, b in ipairs(s.buffs or {}) do
            if not mine[b] and (not best or b < best) then best = b end
        end
    end
    return best
end

local rebuild

local function finishSelfTest()
    judgeLater = false
    running = false
    local v, why, cv, cwhy = readSelfTest()
    if not verdict(v, why, cv, cwhy, "") then fail("self-test did not see the player buff", true) end
    rebuild(true)
end

local function runSelfTest()
    needTest = false
    local aura = C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")
    if issecretvalue(aura) or aura == nil then return fail("no readable buff on the player to self-test", true) end
    local id = aura.spellId
    if issecretvalue(id) or type(id) ~= "number" then return fail("player buff id is secret", true) end
    local _, own = UnitClass("player")
    if issecretvalue(own) then return fail("player class is secret", true) end
    local ctrl = control(own, id)
    local sensor, why = Sensors.Build("player", { id, ctrl })
    if not sensor then return fail(why, false) end
    selfTest = { sensor = sensor, id = id, control = ctrl }
    running = true
    mode, reason = "unavailable", "self-test running"
    C_Timer.After(SELF_TEST_DELAY, function()
        if InCombatLockdown() then
            judgeLater = true
            return
        end
        finishSelfTest()
    end)
end

local function buffMap(member, own)
    local map = {}
    local function add(id, spell, external)
        map[id] = map[id] or {}
        local list = map[id]
        list[#list + 1] = { spell = spell, external = external }
    end
    for spellId, s in pairs(ns.Spells) do
        if s.buffs and (s.track == "target" or (not own and s.track == "buff" and ns.Cooldowns.Has(spellId, member.class, member.spec, member.talents, member.race, member.pets))) then
            for _, id in ipairs(s.buffs) do add(id, spellId, s.track == "target") end
        end
    end
    if own then return map end
    local potions = {}
    for _, p in ipairs(ns.Potions) do
        if not potions[p.buff] then
            potions[p.buff] = true
            add(p.buff, "potion", false)
        end
    end
    return map
end

local function playerGuid()
    for _, m in ipairs(roster) do
        if m.unit == "player" then return m.guid end
    end
end

local function fire(w, entries)
    local own = playerGuid()
    for _, e in ipairs(entries) do
        if e.external then
            if not (own and ns.tracker:UsedWithin(own, e.spell, OWN_CAST_WINDOW)) then
                ns.tracker:External(e.spell, w.guid, own)
            end
        else
            ns.tracker:Used(w.guid, e.spell, true)
        end
    end
end

local function count(t, v, why)
    local key = why or tostring(v)
    t[key] = t[key] + 1
end

local function scan(w)
    if active[w.unit] ~= w then return end
    local guid = UnitGUID(w.unit)
    if issecretvalue(guid) or guid ~= w.guid then return end
    local s = stats[w.unit]
    for id, entries in pairs(w.map) do
        local v, why = nil, "secret"
        if not w.secret[id] then
            v, why = w.sensor:Read(id)
        end
        count(s.read, v, why)
        if why == "secret" then w.secret[id] = true end
        if v ~= nil then
            if v then seen[id] = true end
            if v and w.last[id] ~= true then s.last = entries[1].spell end
            if v and w.last[id] == false then fire(w, entries) end
            w.last[id] = v
        end
    end
end

local function poll(w)
    w.left = POLL_STEPS
    if w.ticker then return end
    w.ticker = C_Timer.NewTicker(POLL_STEP, function()
        w.left = w.left - 1
        if w.left <= 0 then
            w.ticker:Cancel()
            w.ticker = nil
        end
        scan(w)
    end)
end

local regen = CreateFrame("Frame")
local playerWatch = CreateFrame("Frame")

local function watchFrame(unit)
    local f = watches[unit]
    if not f then
        f = CreateFrame("Frame")
        f:SetScript("OnEvent", function()
            local w = active[unit]
            if w then poll(w) end
        end)
        watches[unit] = f
    end
    return f
end

function rebuild(fromSelfTest)
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    local raid = ns.Group.Mode() == "raid"
    if selfTest and not running then
        if rechecked then
            setEnabled("player", false)
            selfTest = nil
        else
            setEnabled("player", not raid)
        end
    end
    if needTest and not running and not fromSelfTest and not raid then runSelfTest() end
    if needTest and not running and not raid then
        playerWatch:RegisterUnitEvent("UNIT_AURA", "player")
    else
        playerWatch:UnregisterAllEvents()
    end
    for unit, w in pairs(active) do
        if w.ticker then w.ticker:Cancel() end
        watches[unit]:UnregisterAllEvents()
    end
    active = {}
    local used = {}
    if mode == "plain" then
        for _, m in ipairs(roster) do
            local own = m.unit == "player"
            local map = buffMap(m, own)
            local ids, wanted = {}, {}
            for id in pairs(map) do wanted[id] = true end
            if own and selfTest then
                wanted[selfTest.id] = true
                if selfTest.control then wanted[selfTest.control] = true end
            end
            for id in pairs(wanted) do ids[#ids + 1] = id end
            table.sort(ids)
            local sensor = Sensors.Build(m.unit, ids)
            if sensor then
                local w = { unit = m.unit, guid = m.guid, map = map, sensor = sensor, last = {}, secret = {} }
                active[m.unit] = w
                used[m.unit] = true
                local old = stats[m.unit]
                stats[m.unit] = old and old.guid == m.guid and old or {
                    guid = m.guid,
                    read = { ["true"] = 0, ["false"] = 0, secret = 0, error = 0 },
                }
                watchFrame(m.unit):RegisterUnitEvent("UNIT_AURA", m.unit)
                poll(w)
            end
        end
    end
    for unit, c in pairs(containers) do
        if not used[unit] and c.filter ~= "HARMFUL" and not (unit == "player" and selfTest) then setEnabled(unit, false) end
    end
end

playerWatch:SetScript("OnEvent", function()
    if not InCombatLockdown() then rebuild() end
end)

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    roster = list
    rebuild()
end

regen:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        if selfTest and not running and mode == "plain" then
            local v, why, cv, cwhy = readSelfTest()
            if verdict(v, why, cv, cwhy, " in combat") then
                rechecked = true
                regen:UnregisterEvent("PLAYER_REGEN_DISABLED")
                pending = true
            end
        end
    elseif judgeLater then
        finishSelfTest()
    elseif pending then
        rebuild()
    end
end)

function Sensors:Enable()
    regen:RegisterEvent("PLAYER_REGEN_DISABLED")
    regen:RegisterEvent("PLAYER_REGEN_ENABLED")
    rebuild()
end

ns.RegisterModule("Sensors", Sensors)
