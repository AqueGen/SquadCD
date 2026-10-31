local _, ns = ...

local Anchors = {}
ns.Anchors = Anchors

local MAX_DEPTH = 4
local TOKENS = { player = true, party1 = true, party2 = true, party3 = true, party4 = true }
local BLIZZARD = { "PlayerFrame", "TargetFrame", "FocusFrame", "PartyFrame", "CompactRaidFrameContainer", "CompactRaidFrameManager" }

local found = {}
local stack

local function plain(frame, method, ...)
    local ok, value = pcall(frame[method], frame, ...)
    if not ok or issecretvalue(value) then return nil end
    return value
end

Anchors.Plain = plain

local function usable(frame)
    return plain(frame, "IsForbidden") == false and plain(frame, "IsVisible") == true
end

local function unitOf(frame)
    if plain(frame, "IsObjectType", "Button") ~= true then return end
    local unit = plain(frame, "GetAttribute", "unit")
    return unit and TOKENS[unit] and unit or nil
end

local function scan(parent, depth, skip, hits)
    for _, child in ipairs({ parent:GetChildren() }) do
        if not skip[child] and usable(child) then
            local unit = unitOf(child)
            if unit and not hits[unit] then
                hits[unit] = child
            elseif depth < MAX_DEPTH then
                scan(child, depth + 1, skip, hits)
            end
        end
    end
end

local function ancestors(frame)
    local p = frame:GetParent()
    return p, p and p:GetParent()
end

local function thirdParty()
    local skip = {}
    for _, name in ipairs(BLIZZARD) do
        if _G[name] then skip[_G[name]] = true end
    end
    local hits = {}
    scan(UIParent, 1, skip, hits)
    local own = hits.player
    hits.player = nil
    if not next(hits) then return {} end
    if own then
        local a1, a2 = ancestors(own)
        for _, button in pairs(hits) do
            local b1, b2 = ancestors(button)
            if a1 == b1 or a1 == b2 or (a2 and (a2 == b1 or a2 == b2)) then
                hits.player = own
                break
            end
        end
    end
    return hits
end

local function blizzard(unit)
    local party = PartyFrame
    if party then
        for i = 1, 4 do
            local f = party["MemberFrame" .. i]
            if f and usable(f) and plain(f, "GetAttribute", "unit") == unit then return f end
        end
    end
    local compact = CompactPartyFrame
    if compact and usable(compact) and compact.memberUnitFrames then
        for _, f in ipairs(compact.memberUnitFrames) do
            if usable(f) and plain(f, "GetAttribute", "unit") == unit then return f end
        end
    end
end

function Anchors.Scan()
    local old = found
    found = thirdParty()
    local changed = false
    for unit in pairs(TOKENS) do
        found[unit] = found[unit] or blizzard(unit)
        if found[unit] ~= old[unit] then changed = true end
    end
    return changed
end

function Anchors.Stack()
    if not stack then
        stack = CreateFrame("Frame", "HuddleStack", UIParent, "BackdropTemplate")
        ns.Theme.MakeMovable(stack, function() return not ns.EditMode.Panels() end, function(point)
            ns.DB.row.point = point
            Anchors.PlaceStack()
        end)
    end
    return stack
end

function Anchors.PlaceStack()
    local p = ns.DB.row.point
    stack:ClearAllPoints()
    stack:SetPoint(p[1], UIParent, p[1], p[2], p[3])
end

function Anchors.FrameFor(unit)
    local f = found[unit]
    if f then return f, false end
    return Anchors.Stack(), true
end

function Anchors.SizeOf(frame)
    local w, h = plain(frame, "GetWidth"), plain(frame, "GetHeight")
    if type(w) ~= "number" or type(h) ~= "number" then return 0, 0 end
    return w, h
end
