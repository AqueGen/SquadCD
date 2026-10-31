-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Inspect = {}
ns.Inspect = Inspect

local SPACING, BACKOFF, TRIES, TIMEOUT = 2, 15, 5, 5
local PARTY = { "party1", "party2", "party3", "party4" }

function Inspect.OnResult() end

local function anySecret(...)
    for i = 1, select("#", ...) do
        if issecretvalue((select(i, ...))) then return true end
    end
    return false
end

function Inspect.MapNodes(nodes)
    local talents = {}
    for _, n in ipairs(nodes) do
        local e = n.activeEntry
        if anySecret(e) then return nil, "secret" end
        if e then
            if anySecret(e.entryID, e.rank, n.subTreeID, n.subTreeActive) then return nil, "secret" end
            local spell = ns.TalentEntries[e.entryID]
            if spell and e.rank > 0 and (n.subTreeID == nil or n.subTreeActive) then
                talents[spell] = e.rank
            end
        end
    end
    return talents
end

function Inspect.ReadTalents(configID)
    if anySecret(configID) then return nil, "secret" end
    if configID == nil then return nil end
    local config = C_Traits.GetConfigInfo(configID)
    if anySecret(config) then return nil, "secret" end
    local treeIDs = config and config.treeIDs
    if anySecret(treeIDs) then return nil, "secret" end
    local treeID = treeIDs and treeIDs[1]
    if anySecret(treeID) then return nil, "secret" end
    if treeID == nil then return nil end
    local nodeIDs = C_Traits.GetTreeNodes(treeID)
    if anySecret(nodeIDs) then return nil, "secret" end
    local nodes = {}
    for _, nodeID in ipairs(nodeIDs or {}) do
        local info = C_Traits.GetNodeInfo(configID, nodeID)
        if anySecret(info) then return nil, "secret" end
        if info then nodes[#nodes + 1] = info end
    end
    return Inspect.MapNodes(nodes)
end

function Inspect.NewState()
    return { queue = {}, tries = {}, lastSent = -math.huge }
end

function Inspect.Add(state, guid, unit)
    if (state.tries[guid] or 0) >= TRIES then return false end
    local q = state.queue[guid]
    if q then
        q.unit = unit
    else
        state.queue[guid] = { unit = unit, at = 0 }
    end
    return true
end

function Inspect.Fail(state, guid, now)
    local n = (state.tries[guid] or 0) + 1
    state.tries[guid] = n
    local q = state.queue[guid]
    if not q then return end
    if n >= TRIES then
        state.queue[guid] = nil
    else
        q.at = now + BACKOFF
    end
end

function Inspect.Step(state, now, env)
    local f = state.inFlight
    if f and now - f.at >= TIMEOUT then
        Inspect.Fail(state, f.guid, now)
        state.inFlight = nil
    end
    if state.inFlight then return "wait", state.inFlight.at + TIMEOUT - now end
    if state.lastSent + SPACING > now then return "wait", state.lastSent + SPACING - now end
    for guid, q in pairs(state.queue) do
        if env.guid(q.unit) ~= guid then
            state.queue[guid] = nil
        elseif q.at <= now then
            if env.ready(q.unit) then
                state.inFlight = { guid = guid, unit = q.unit, at = now }
                state.lastSent = now
                return "send", q.unit
            end
            Inspect.Fail(state, guid, now)
        end
    end
    local wait
    for _, q in pairs(state.queue) do
        wait = math.min(wait or math.huge, q.at - now)
    end
    if wait then return "wait", wait end
end

function Inspect.Ready(state, guid, now)
    local f = state.inFlight
    if not f or guid ~= f.guid then return nil end
    state.inFlight = nil
    state.lastSent = now
    return f.unit
end

local function unitGuid(unit)
    local guid = UnitGUID(unit)
    if anySecret(guid) then return nil end
    return guid
end

local env = {
    guid = unitGuid,
    ready = function(unit)
        local can, online = CanInspect(unit), UnitIsConnected(unit)
        if anySecret(can, online) then return false end
        return can and online
    end,
}

local state = Inspect.NewState()
Inspect.state = state
local timerAt, token = nil, 0
local run

local function schedule(delay)
    if not next(state.queue) and not state.inFlight then return end
    delay = math.max(0, delay)
    local at = GetTime() + delay
    if timerAt and timerAt <= at then return end
    timerAt = at
    token = token + 1
    local mine = token
    C_Timer.After(delay, function()
        if mine == token then run() end
    end)
end

local function inspectOpen()
    return InspectFrame and InspectFrame:IsShown()
end

run = function()
    timerAt = nil
    if inspectOpen() then return schedule(SPACING) end
    local action, arg = Inspect.Step(state, GetTime(), env)
    if action == "send" then
        NotifyInspect(arg)
        schedule(TIMEOUT)
    elseif action == "wait" then
        schedule(arg)
    end
end

function Inspect.Queue(unit)
    local _, kind = IsInInstance()
    if anySecret(kind) or kind ~= "party" then return end
    local guid = unitGuid(unit)
    if guid == nil then return end
    if Inspect.Add(state, guid, unit) then schedule(0) end
end

function Inspect.Reset()
    state.queue, state.tries, state.inFlight = {}, {}, nil
    timerAt, token = nil, token + 1
end

local frame = CreateFrame("Frame")

function Inspect.SetActive(on)
    if on then
        frame:RegisterEvent("INSPECT_READY")
        return
    end
    frame:UnregisterEvent("INSPECT_READY")
    Inspect.Reset()
end

local function relocate(guid)
    for _, unit in ipairs(PARTY) do
        if unitGuid(unit) == guid then
            Inspect.Add(state, guid, unit)
            return
        end
    end
    state.queue[guid] = nil
end

frame:SetScript("OnEvent", function(_, _, guid)
    if anySecret(guid) then return end
    local now = GetTime()
    local unit = Inspect.Ready(state, guid, now)
    if not unit then return end
    if unitGuid(unit) ~= guid then
        Inspect.Fail(state, guid, now)
        relocate(guid)
        return schedule(SPACING)
    end
    local spec = C_SpecializationInfo.GetInspectSpecialization(unit)
    if anySecret(spec) or not ns.Specs[spec] then spec = nil end
    local valid = C_Traits.HasValidInspectData()
    local talents
    if not anySecret(valid) and valid then
        talents = Inspect.ReadTalents(Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID)
    end
    if not inspectOpen() then ClearInspectPlayer() end
    if spec then Inspect.OnResult(guid, spec, talents) end
    if spec and talents then
        state.queue[guid] = nil
    else
        Inspect.Fail(state, guid, now)
    end
    schedule(SPACING)
end)
