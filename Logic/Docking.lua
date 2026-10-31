local _, ns = ...

local Docking = {}
ns.Docking = Docking

Docking.GAP = 6
Docking.SNAP = 16
local TOUCH = 2

-- Rect: { x, y, w, h }, x to the right, y DOWN from the UIParent top-left corner.
-- WoW conversion: TOPLEFT of UIParent at (x, -y); rects and screen must share one effective scale.
-- Stored position of a section window (section.pos): { x, y } absolute, plus
-- { dockTo = id, side = "Right"|"Left"|"Above"|"Below", offset = n } when docked.
-- side is the side of the target the window sits on; offset is the distance of its
-- top (Right/Left) or left (Above/Below) edge from the target's. x, y keep the last
-- absolute spot and are the fallback when the target is missing or hidden.
-- The main panel has id "panel".

local function right(r) return r.x + r.w end
local function bottom(r) return r.y + r.h end

local function near(a, b)
    return math.abs(a - b) <= TOUCH
end

local function closer(best, cand, dist)
    if math.abs(cand) > dist then return best end
    if best and math.abs(best) <= math.abs(cand) then return best end
    return cand
end

function Docking.SideOf(rect, target, gap)
    gap = gap or Docking.GAP
    if rect.y < bottom(target) and target.y < bottom(rect) then
        local e = math.abs(rect.x - right(target) - gap)
        if e <= TOUCH then return "Right", rect.y - target.y, e end
        e = math.abs(right(rect) + gap - target.x)
        if e <= TOUCH then return "Left", rect.y - target.y, e end
    end
    if rect.x < right(target) and target.x < right(rect) then
        local e = math.abs(rect.y - bottom(target) - gap)
        if e <= TOUCH then return "Below", rect.x - target.x, e end
        e = math.abs(bottom(rect) + gap - target.y)
        if e <= TOUCH then return "Above", rect.x - target.x, e end
    end
end

function Docking.Snap(rect, others, gap, dist)
    gap = gap or Docking.GAP
    dist = dist or Docking.SNAP
    local dx, dy
    for _, a in ipairs(others) do
        if rect.y - dist < bottom(a) and bottom(rect) + dist > a.y then
            for _, d in ipairs({ right(a) + gap - rect.x, a.x - gap - right(rect), a.x - rect.x, right(a) - right(rect) }) do
                dx = closer(dx, d, dist)
            end
        end
        if rect.x - dist < right(a) and right(rect) + dist > a.x then
            for _, d in ipairs({ bottom(a) + gap - rect.y, a.y - gap - bottom(rect), a.y - rect.y, bottom(a) - bottom(rect) }) do
                dy = closer(dy, d, dist)
            end
        end
    end
    local x, y = rect.x + (dx or 0), rect.y + (dy or 0)
    local snapped = { x = x, y = y, w = rect.w, h = rect.h }
    local best, bestErr, bestSide, bestOffset
    for _, a in ipairs(others) do
        local side, offset, err = Docking.SideOf(snapped, a, gap)
        if side and a.id ~= nil and (not bestErr or err < bestErr) then
            best, bestErr, bestSide, bestOffset = a.id, err, side, offset
        end
    end
    if best == nil then return x, y end
    return x, y, best, bestSide, bestOffset
end

function Docking.Group(panels, gap)
    local clusters, seen = {}, {}
    for i = 1, #panels do
        if not seen[i] then
            seen[i] = true
            local cluster, queue = { i }, { i }
            while #queue > 0 do
                local a = table.remove(queue, 1)
                for j = 1, #panels do
                    if not seen[j] and Docking.SideOf(panels[a], panels[j], gap) then
                        seen[j] = true
                        cluster[#cluster + 1] = j
                        queue[#queue + 1] = j
                    end
                end
            end
            table.sort(cluster)
            clusters[#clusters + 1] = cluster
        end
    end
    return clusters
end

function Docking.Clamp(rect, screen)
    local x = math.min(rect.x, right(screen) - rect.w)
    x = math.max(x, screen.x)
    local y = math.min(rect.y, bottom(screen) - rect.h)
    y = math.max(y, screen.y)
    return x, y
end

local function placed(pos, target, size, gap)
    local x, y
    if pos.side == "Right" then x, y = right(target) + gap, target.y + pos.offset
    elseif pos.side == "Left" then x, y = target.x - gap - size.w, target.y + pos.offset
    elseif pos.side == "Below" then x, y = target.x + pos.offset, bottom(target) + gap
    else x, y = target.x + pos.offset, target.y - gap - size.h end
    return x, y
end

function Docking.Resolve(positions, sizes, screen, gap)
    gap = gap or Docking.GAP
    local rects, busy = {}, {}
    local function resolve(id)
        if rects[id] then return rects[id] end
        local pos, size = positions[id], sizes[id]
        if not pos or not size then return nil end
        busy[id] = true
        local x, y = pos.x, pos.y
        if pos.dockTo and not busy[pos.dockTo] then
            local target = resolve(pos.dockTo)
            if target then x, y = placed(pos, target, size, gap) end
        end
        busy[id] = nil
        local r = { x = x, y = y, w = size.w, h = size.h }
        if screen then r.x, r.y = Docking.Clamp(r, screen) end
        rects[id] = r
        return r
    end
    for id in pairs(positions) do resolve(id) end
    return rects
end
