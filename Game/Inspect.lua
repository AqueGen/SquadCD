local _, ns = ...

local Inspect = {}
ns.Inspect = Inspect

local SPACING, BACKOFF, TRIES, TIMEOUT = 2, 15, 5, 5

function Inspect.OnResult() end

local queue = {}
local inFlight
local lastSent = -math.huge
local scheduled = false
local frame = CreateFrame("Frame")

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
    if configID == nil then return nil end
    if issecretvalue(configID) then return nil, "secret" end
    local config = C_Traits.GetConfigInfo(configID)
    local treeID = config and config.treeIDs and config.treeIDs[1]
    if anySecret(treeID) then return nil, "secret" end
    if not treeID then return nil end
    local nodes = {}
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
        local info = C_Traits.GetNodeInfo(configID, nodeID)
        if info then nodes[#nodes + 1] = info end
    end
    return Inspect.MapNodes(nodes)
end

local step

local function schedule(delay)
    if scheduled or not next(queue) then return end
    scheduled = true
    C_Timer.After(math.max(0, delay), step)
end

local function fail(guid, now)
    local q = queue[guid]
    if not q then return end
    q.tries = q.tries + 1
    if q.tries >= TRIES then
        queue[guid] = nil
    else
        q.at = now + BACKOFF
    end
end

local function inspectOpen()
    return InspectFrame and InspectFrame:IsShown()
end

step = function()
    scheduled = false
    local now = GetTime()
    if inFlight and now - inFlight.at >= TIMEOUT then
        fail(inFlight.guid, now)
        inFlight = nil
    end
    if inFlight then return schedule(inFlight.at + TIMEOUT - now) end
    if now - lastSent < SPACING then return schedule(lastSent + SPACING - now) end
    if inspectOpen() then return schedule(SPACING) end
    local wait
    for guid, q in pairs(queue) do
        local current = UnitGUID(q.unit)
        if anySecret(current) or current ~= guid then
            queue[guid] = nil
        elseif q.at <= now then
            local can, online = CanInspect(q.unit), UnitIsConnected(q.unit)
            if not anySecret(can, online) and can and online then
                NotifyInspect(q.unit)
                inFlight = { guid = guid, unit = q.unit, at = now }
                lastSent = now
                return schedule(TIMEOUT)
            end
            fail(guid, now)
        end
        if queue[guid] then
            wait = math.min(wait or math.huge, queue[guid].at - now)
        end
    end
    if wait then schedule(math.max(wait, SPACING)) end
end

function Inspect.Queue(unit)
    local _, kind = IsInInstance()
    if anySecret(kind) or kind ~= "party" then return end
    local guid = UnitGUID(unit)
    if guid == nil or anySecret(guid) or queue[guid] then return end
    queue[guid] = { unit = unit, tries = 0, at = 0 }
    schedule(0)
end

function Inspect.SetActive(on)
    if on then
        frame:RegisterEvent("INSPECT_READY")
        return
    end
    frame:UnregisterEvent("INSPECT_READY")
    queue, inFlight = {}, nil
end

frame:SetScript("OnEvent", function(_, _, guid)
    if not inFlight or anySecret(guid) or guid ~= inFlight.guid then return end
    local unit = inFlight.unit
    inFlight = nil
    local spec = C_SpecializationInfo.GetInspectSpecialization(unit)
    if anySecret(spec) or not ns.Specs[spec] then spec = nil end
    local talents = Inspect.ReadTalents(Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID)
    if not inspectOpen() then ClearInspectPlayer() end
    if spec then
        queue[guid] = nil
        Inspect.OnResult(guid, spec, talents)
    else
        fail(guid, GetTime())
    end
    schedule(SPACING)
end)
