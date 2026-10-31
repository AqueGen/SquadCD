local _, ns = ...

local Sensors = {}
ns.Sensors = Sensors

local POLL_STEP, POLL_STEPS = 0.1, 5
local SELF_TEST_DELAY = 0.5
local INSET = 1e5

local mode, reason, retry = "unavailable", "self-test has not run", true
local host
local containers = {}
local watches = {}
local active = {}
local pending, rechecked = false, false
local selfTest
local stats, seen = {}, {}

local Sensor = {}
Sensor.__index = Sensor

local function readout(ok, v)
    if not ok then return nil, "error" end
    if issecretvalue(v) then return nil, "secret" end
    if type(v) ~= "boolean" then return nil, "error" end
    return v
end

function Sensor:Read(buffId)
    local slot = self.slots[buffId]
    if not slot then return nil, "error" end
    local shown, why = readout(pcall(slot.IsShown, slot))
    if shown ~= nil then return shown end
    local over, why2 = readout(pcall(slot.IsMouseOver, slot, INSET, -INSET, -INSET, INSET))
    if over ~= nil then return over end
    if why == "secret" or why2 == "secret" then return nil, "secret" end
    return nil, "error"
end

local function container(unit)
    if containers[unit] then return containers[unit] end
    if not host then
        host = CreateFrame("Frame", nil, UIParent)
        host:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
        host:SetSize(1, 1)
        host:EnableMouse(false)
    end
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, host, "CustomAuraContainerTemplate")
    if not ok or not c then return nil, "AuraContainer unavailable: " .. tostring(c) end
    ok = pcall(function()
        c:SetPoint("TOPLEFT", host, "TOPLEFT")
        c:EnableMouse(false)
        c:SetUnit(unit)
    end)
    if not ok then return nil, "AuraContainer setup failed" end
    containers[unit] = { frame = c, keys = {} }
    return containers[unit]
end

function Sensors.Build(unit, buffIds)
    local c, why = container(unit)
    if not c then return nil, why end
    local wanted, slots = {}, {}
    local ok, err = pcall(function()
        local f = c.frame
        f:SetEnabled(true)
        for _, id in ipairs(buffIds) do
            local key = "b" .. id
            wanted[key] = true
            local slot = f:GetAuraSlotFrame(key)
            if slot then
                f:SetAuraSlotEnabled(key, true)
            else
                slot = f:AddAuraSlot(key, "HELPFUL", { candidateFilters = { includeSpellIDs = { [id] = true } } })
                c.keys[key] = true
            end
            slots[id] = slot
        end
        for key in pairs(c.keys) do
            if not wanted[key] then f:SetAuraSlotEnabled(key, false) end
        end
    end)
    if not ok then return nil, "aura slot setup failed: " .. tostring(err) end
    return setmetatable({ unit = unit, slots = slots }, Sensor)
end

local function disable(unit)
    local c = containers[unit]
    if c then pcall(c.frame.SetEnabled, c.frame, false) end
end

function Sensors.Mode()
    return mode, reason
end

function Sensors.Stats()
    return stats, seen
end

local function judge(v, why, firstCombat)
    if v == true then
        mode, reason, retry = "plain", nil, false
    elseif why == "secret" then
        mode, reason, retry = "secret", "aura readout is secret", false
    elseif firstCombat then
        return
    elseif v == false then
        mode, reason, retry = "unavailable", "self-test did not see the player buff", true
    else
        mode, reason, retry = "unavailable", "aura readout failed", false
    end
end

local rebuild

local function runSelfTest()
    retry = false
    local aura = C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")
    if issecretvalue(aura) or aura == nil then
        mode, reason, retry = "unavailable", "no readable buff on the player to self-test", true
        return
    end
    local id = aura.spellId
    if issecretvalue(id) or type(id) ~= "number" then
        mode, reason, retry = "unavailable", "player buff id is secret", true
        return
    end
    local sensor, why = Sensors.Build("player", { id })
    if not sensor then
        mode, reason = "unavailable", why
        return
    end
    selfTest = { sensor = sensor, id = id }
    mode, reason = "unavailable", "self-test running"
    C_Timer.After(SELF_TEST_DELAY, function()
        judge(sensor:Read(id))
        rebuild(true)
    end)
end

local function buffMap(member)
    local map = {}
    local function add(id, spell, external)
        map[id] = map[id] or {}
        local list = map[id]
        list[#list + 1] = { spell = spell, external = external }
    end
    for spellId, s in pairs(ns.Spells) do
        if s.buffs and (s.track == "target" or (s.track == "buff" and ns.Cooldowns.Has(spellId, member.class, member.spec, member.talents))) then
            for _, id in ipairs(s.buffs) do add(id, spellId, s.track == "target") end
        end
    end
    local potions = {}
    for _, p in ipairs(ns.Potions) do
        if not potions[p.buff] then
            potions[p.buff] = true
            add(p.buff, "potion", false)
        end
    end
    return map
end

local function fire(w, entries)
    for _, e in ipairs(entries) do
        if e.external then
            ns.tracker:External(e.spell, w.guid)
        else
            ns.tracker:Used(w.guid, e.spell, true)
        end
    end
end

local function scan(w)
    if active[w.unit] ~= w then return end
    local count = stats[w.unit]
    for id, entries in pairs(w.map) do
        local v, why = w.sensor:Read(id)
        if v == nil then
            count[why] = count[why] + 1
        else
            count.plain = count.plain + 1
            if v then seen[id] = true end
            if v and w.last[id] == false then fire(w, entries) end
            w.last[id] = v
        end
    end
end

local function poll(w)
    if w.ticker then w.ticker:Cancel() end
    w.ticker = C_Timer.NewTicker(POLL_STEP, function() scan(w) end, POLL_STEPS)
end

local roster = {}
local regen = CreateFrame("Frame")

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
    if rechecked then
        retry = false
        if selfTest then
            disable("player")
            selfTest = nil
        end
    elseif retry and not fromSelfTest then
        runSelfTest()
    end
    for unit, w in pairs(active) do
        if w.ticker then w.ticker:Cancel() end
        watches[unit]:UnregisterAllEvents()
    end
    active = {}
    local used = {}
    if mode == "plain" then
        for _, m in ipairs(roster) do
            if m.unit ~= "player" then
                local map = buffMap(m)
                local ids = {}
                for id in pairs(map) do ids[#ids + 1] = id end
                table.sort(ids)
                local sensor = Sensors.Build(m.unit, ids)
                if sensor then
                    local w = { unit = m.unit, guid = m.guid, map = map, sensor = sensor, last = {} }
                    active[m.unit] = w
                    used[m.unit] = true
                    stats[m.unit] = stats[m.unit] or { plain = 0, secret = 0, error = 0 }
                    watchFrame(m.unit):RegisterUnitEvent("UNIT_AURA", m.unit)
                    poll(w)
                end
            end
        end
    end
    for unit in pairs(containers) do
        if unit ~= "player" and not used[unit] then disable(unit) end
    end
end

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    roster = list
    rebuild()
end

regen:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        regen:UnregisterEvent("PLAYER_REGEN_DISABLED")
        rechecked = true
        if selfTest then
            local v, why = selfTest.sensor:Read(selfTest.id)
            judge(v, why, true)
        end
        pending = true
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
