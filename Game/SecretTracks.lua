-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local SecretTracks = {}
ns.SecretTracks = SecretTracks

local TICK, SETTLE, OWN_WINDOW, PLATES = 0.2, 0.3, 3, 20

local T = ns.SecretTime
local frame = CreateFrame("Frame")
local senses, tracks = {}, {}
local roster = {}
local pending, ticker, playerGuid = false, nil, nil
local status = { on = true }
local plates, plateOf, waiting = {}, {}, {}
for j = 1, PLATES do plates[j] = {} end

local function evalBool(b, t, f)
    return C_CurveUtil.EvaluateColorValueFromBoolean(b, t, f)
end

local function potionIds()
    local ids = {}
    for _, p in ipairs(ns.Potions) do ids[#ids + 1] = p.buff end
    return ids
end

local function wanted(m)
    local list = {}
    local enabled = ns.DB and ns.DB.spells or {}
    for id, s in pairs(ns.Spells) do
        local ids = s.track == "debuff" and s.debuffs or s.buffs
        if (s.track == "buff" or s.track == "target" or s.track == "debuff") and ids and enabled[id] ~= false
            and ns.Cooldowns.Has(id, m.class, m.spec, m.talents, m.race, m.pets)
            and ns.Cooldowns.Canonical(id, m) == id then
            local r = ns.Cooldowns.Resolve(id, m.spec, m.talents)
            list[#list + 1] = { id = id, kind = s.track, ids = ids, cd = r and r.cd or s.cd, dur = s.track ~= "debuff" and s.dur or nil }
        end
    end
    if enabled.potion ~= false and ns.Potions[1] then
        list[#list + 1] = { id = "potion", kind = "buff", ids = potionIds(), cd = ns.Potions[1].cd }
    end
    return list
end

local function sense(guid, unit, spell, ids, now)
    local key = guid .. ":" .. spell
    local s = senses[key]
    if not s then
        local probe, why = ns.Probes.New(unit, "HELPFUL", ids)
        if not probe then
            status.on, status.why = false, why
            return nil
        end
        s = { probe = probe, unit = unit, settleUntil = now + SETTLE }
        senses[key] = s
    elseif s.unit ~= unit or not s.used then
        ns.Probes.Point(s.probe, unit)
        ns.Probes.Enable(s.probe, true)
        s.unit, s.settleUntil, s.primed = unit, now + SETTLE, false
    end
    s.used = true
    return s
end

-- A re-pointed probe settles before its edges count, so a mob that arrives already stunned stamps nothing.
local function aim(s, unit, now)
    if s.unit ~= unit then
        s.unit = unit
        if unit then
            ns.Probes.Point(s.probe, unit)
            s.settleUntil, s.primed = now + SETTLE, false
        end
    end
    s.off = unit == nil
    ns.Probes.Enable(s.probe, unit ~= nil)
end

local function plateSense(j, spell, ids, now)
    local key = "plate" .. j .. ":" .. spell
    local s = senses[key]
    if not s then
        local probe, why = ns.Probes.New("nameplate" .. j, "HARMFUL", ids)
        if not probe then
            status.on, status.why = false, why
            return nil
        end
        s = { probe = probe, plate = j, unit = "nameplate" .. j, settleUntil = now + SETTLE }
        senses[key] = s
    end
    s.used = true
    aim(s, plates[j].unit, now)
    return s
end

local function watchList(t)
    local list = {}
    if t.kind == "debuff" then return list end
    for _, s in ipairs(t.senses) do
        if s.unit then list[#list + 1] = { unit = s.unit, ids = t.ids } end
    end
    return list
end

local function dress(t, layer)
    layer:Configure(t.cd)
    layer:Watch(watchList(t))
end

local function startTicker()
    if ticker or not next(tracks) then return end
    ticker = C_Timer.NewTicker(TICK, function() SecretTracks.Tick(GetTime()) end)
end

local function stopTicker()
    if ticker then ticker:Cancel() end
    ticker = nil
end

function SecretTracks.Rebuild(list)
    roster = list or roster
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    local now = GetTime()
    playerGuid = nil
    for _, s in pairs(senses) do s.used = false end
    local keep = {}
    for _, m in ipairs(roster) do
        if m.unit == "player" then playerGuid = m.guid end
    end
    for _, m in ipairs(roster) do
        if m.unit ~= "player" then
            for _, w in ipairs(wanted(m)) do
                local key = m.guid .. ":" .. w.id
                local t = tracks[key]
                if not t then
                    t = { guid = m.guid, spell = w.id, layers = {} }
                    tracks[key] = t
                end
                if t.cd ~= w.cd or t.dur ~= w.dur then
                    t.cd, t.dur = w.cd, w.dur
                    t.base = T.NewBase(now, w.cd, w.dur or 0)
                    t.stamps = { 0, 0 }
                end
                t.ids = w.ids
                t.senses = {}
                t.kind = w.kind
                if w.kind == "buff" then
                    t.senses[1] = sense(m.guid, m.unit, w.id, w.ids, now)
                elseif w.kind == "debuff" then
                    for j = 1, PLATES do t.senses[#t.senses + 1] = plateSense(j, w.id, w.ids, now) end
                else
                    for _, o in ipairs(roster) do
                        t.senses[#t.senses + 1] = sense(o.guid, o.unit, w.id, w.ids, now)
                    end
                end
                for layer in pairs(t.layers) do dress(t, layer) end
                keep[key] = true
            end
        end
    end
    for key, t in pairs(tracks) do
        if not keep[key] then
            for layer in pairs(t.layers) do layer.track = nil end
            tracks[key] = nil
        end
    end
    for _, s in pairs(senses) do
        if not s.used then ns.Probes.Enable(s.probe, false) end
    end
    if next(tracks) and status.on then startTicker() else stopTicker() end
end

local function write(t, now, idle)
    local base = t.base
    for s = 1, 2 do
        local slot = base.slots[s]
        t.out = t.out or { {}, {} }
        local v = t.out[s]
        local step = slot.epoch + math.floor(now - slot.epoch)
        v.stamp = t.stamps[s]
        v.coolLo, v.coolHi = T.Window(step, slot.epoch, base.U, t.cd)
        v.gateLo, v.gateHi = T.Gate(now, slot.epoch, base.U, t.cd)
        for layer in pairs(t.layers) do layer:Write(s, v) end
    end
    for layer in pairs(t.layers) do layer:SetPhase(idle) end
end

function SecretTracks.Tick(now)
    if not status.on then return end
    for _, t in pairs(tracks) do
        local idx = T.Roll(t.base, now)
        if idx then t.stamps[idx] = 0 end
    end
    for _, s in pairs(senses) do
        if s.off then
            s.ready = false
        elseif s.used then
            local ok, v = pcall(ns.Probes.Lit, s.probe)
            if ok then s.cur, s.read = v, true end
            s.ready = s.primed and now >= s.settleUntil
            if not s.ready then s.prev = s.cur end
        end
    end
    for _, t in pairs(tracks) do
        local masked = playerGuid and ns.tracker and ns.tracker:UsedWithin(playerGuid, t.spell, OWN_WINDOW)
        local w = t.base.write
        local code = T.Code(now, t.base.slots[w].epoch, t.base.U)
        local idle = 1
        for _, s in ipairs(t.senses) do
            if s.ready then
                if not masked then
                    t.stamps[w] = evalBool(s.cur, evalBool(s.prev, t.stamps[w], code), t.stamps[w])
                end
                if t.kind ~= "debuff" then idle = evalBool(s.cur, 0, idle) end
            end
        end
        if next(t.layers) then write(t, now, idle) end
    end
    for _, s in pairs(senses) do
        if s.used and not s.off then s.prev, s.primed = s.cur, s.read end
    end
end

local function point(j, unit)
    plates[j].unit = unit
    local now = GetTime()
    for _, s in pairs(senses) do
        if s.plate == j and s.used then aim(s, unit, now) end
    end
end

local function plain(fn, ...)
    local ok, v = pcall(fn, ...)
    return ok and not issecretvalue(v) and v or nil
end

function SecretTracks.PlateAdded(unit)
    if plateOf[unit] or plain(UnitCanAttack, "player", unit) ~= true then return end
    for j = 1, PLATES do
        if not plates[j].unit then
            plateOf[unit], waiting[unit] = j, nil
            point(j, unit)
            return
        end
    end
    waiting[unit] = true
end

function SecretTracks.PlateRemoved(unit)
    waiting[unit] = nil
    local j = plateOf[unit]
    if not j then return end
    plateOf[unit] = nil
    point(j, nil)
    local queued = {}
    for u in pairs(waiting) do queued[#queued + 1] = u end
    table.sort(queued)
    for _, u in ipairs(queued) do
        waiting[u] = nil
        if plain(UnitExists, u) == true then
            SecretTracks.PlateAdded(u)
            if plateOf[u] then return end
        end
    end
end

-- The own row stays on the plain tracker; only its active aura comes from the engine display.
function SecretTracks.WatchFor(member, spell)
    local s = spell == "potion" and { track = "buff" } or ns.Spells[spell]
    local ids = spell == "potion" and potionIds() or s and s.buffs
    if not member.unit or not ids or #ids == 0 or not (s.track == "buff" or s.track == "target") then return {} end
    if s.track == "buff" then return { { unit = member.unit, ids = ids } } end
    local list = {}
    for _, o in ipairs(roster) do list[#list + 1] = { unit = o.unit, ids = ids } end
    return list
end

function SecretTracks.Track(guid, spell)
    return tracks[guid .. ":" .. spell]
end

function SecretTracks.Bind(layer, guid, spell)
    SecretTracks.Unbind(layer)
    local t = status.on and tracks[guid .. ":" .. tostring(spell)]
    if not t then return false end
    t.layers[layer] = true
    layer.track = t
    dress(t, layer)
    return true
end

function SecretTracks.Unbind(layer)
    local t = layer.track
    if t then t.layers[layer] = nil end
    layer.track = nil
end

function SecretTracks.Status()
    local n, p, onPlates, watched = 0, 0, 0, 0
    for _ in pairs(tracks) do n = n + 1 end
    for _, s in pairs(senses) do
        if s.used then p = p + 1 end
        if s.used and s.plate and not s.off then onPlates = onPlates + 1 end
    end
    for _ in pairs(plateOf) do watched = watched + 1 end
    return { on = status.on, why = status.why, tracks = n, probes = p, plates = watched, platePool = PLATES, plateProbes = onPlates }
end

local SAMPLES = { 0, 1, 48, 127, 254, 255 }

local function faithful()
    for _, k in ipairs(SAMPLES) do
        if math.floor(evalBool(true, k / 255, 0) * 255 + 0.5) ~= k then return false end
        if math.floor(evalBool(false, 0, k / 255) * 255 + 0.5) ~= k then return false end
    end
    return true
end

local function checks()
    if not (C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean) then return "no curve evaluator" end
    local ok, good = pcall(faithful)
    if not ok or not good then return "curve values are not exact" end
    if C_XMLUtil and C_XMLUtil.GetTemplateInfo then
        local okT, info = pcall(C_XMLUtil.GetTemplateInfo, "CustomAuraContainerTemplate")
        if not okT or info == nil then return "no aura container template" end
    end
end

function SecretTracks.SelfTest()
    local why = checks()
    status.on, status.why = why == nil, why
    if why then stopTicker() end
end

function SecretTracks:Enable()
    SecretTracks.SelfTest()
    for i = 1, 40 do
        if plain(UnitExists, "nameplate" .. i) == true then SecretTracks.PlateAdded("nameplate" .. i) end
    end
end

ns.RegisterModule("SecretTracks", SecretTracks)

frame:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        SecretTracks.PlateAdded(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        SecretTracks.PlateRemoved(unit)
    elseif pending then
        SecretTracks.Rebuild()
    end
end)
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    SecretTracks.Rebuild(list)
end
