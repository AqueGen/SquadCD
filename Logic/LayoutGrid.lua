-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local LayoutGrid = {}
ns.LayoutGrid = LayoutGrid

local MIN_PER_LINE, MAX_PER_LINE = 1, 12
LayoutGrid.OVERFLOW_GAP = 6

function LayoutGrid.RoleOf(specId)
    local spec = ns.Specs[specId]
    if not spec then return nil end
    if spec.role == "Tank" or spec.role == "Healer" then return spec.role end
    return spec.ranged and "Ranged" or "Melee"
end

local function perLine(n)
    return math.max(MIN_PER_LINE, math.min(MAX_PER_LINE, math.floor(n or MIN_PER_LINE)))
end

local function flow(cells, axis, per, origin, gap, acrossLimit)
    per = perLine(per)
    local rows = axis ~= "Columns"
    local placed = {}
    local blockU, blockAlong, v, maxU, maxV = 0, 0, 0, 0, 0
    for first = 1, #cells, per do
        local last = math.min(first + per - 1, #cells)
        local thick = 0
        for i = first, last do thick = math.max(thick, rows and cells[i].h or cells[i].w) end
        if v > 0 and v + thick > acrossLimit then
            blockU, blockAlong, v = blockU + blockAlong + LayoutGrid.OVERFLOW_GAP, 0, 0
        end
        local u = blockU
        for i = first, last do
            local along, across = cells[i].w, cells[i].h
            if not rows then along, across = across, along end
            placed[i] = { u, v, along, across }
            u = u + along + gap
        end
        blockAlong = math.max(blockAlong, u - gap - blockU)
        maxU = math.max(maxU, u - gap)
        maxV = math.max(maxV, v + thick)
        v = v + thick + gap
    end
    local w, h = maxU, maxV
    if not rows then w, h = maxV, maxU end
    local flipX = origin == "TopRight" or origin == "BottomRight"
    local flipY = origin == "BottomLeft" or origin == "BottomRight"
    local out = {}
    for i, p in ipairs(placed) do
        local r = rows and { x = p[1], y = p[2], w = p[3], h = p[4] } or { x = p[2], y = p[1], w = p[4], h = p[3] }
        if flipX then r.x = w - r.x - r.w end
        if flipY then r.y = h - r.y - r.h end
        out[i] = r
    end
    return out, w, h
end

function LayoutGrid.Place(cells, shape, gap)
    return flow(cells, shape.axis, shape.perLine, shape.origin, gap, math.huge)
end

function LayoutGrid.PlaceSections(sections, shape, gap)
    return flow(sections, shape.axis, 1, shape.origin, gap, math.huge)
end

function LayoutGrid.MemberOrigin(origin, side)
    local bottom = origin == "BottomLeft" or origin == "BottomRight"
    local right = origin == "TopRight" or origin == "BottomRight"
    if side == "Left" then return bottom and "BottomRight" or "TopRight" end
    if side == "Right" then return bottom and "BottomLeft" or "TopLeft" end
    if side == "Above" then return right and "BottomRight" or "BottomLeft" end
    return right and "TopRight" or "TopLeft"
end

local function beside(side)
    return side == "Left" or side == "Right"
end

function LayoutGrid.PlaceMemberRow(cells, shape, side, frameHeight, gap)
    local limit = beside(side) and shape.axis ~= "Columns" and frameHeight > 0 and frameHeight or math.huge
    return flow(cells, shape.axis, shape.perLine, LayoutGrid.MemberOrigin(shape.origin, side), gap, limit)
end

local function fits(room, cell, gap)
    return math.max(1, math.floor((room + gap) / (cell + gap) + 1e-6))
end

local function ceilDiv(a, b)
    return math.ceil(a / b)
end

function LayoutGrid.FitShape(shape, side, count, cellW, cellH, lead, frameW, frameH, gap)
    if count <= 0 or shape.axis == "Columns" then return shape end
    local per
    if beside(side) then
        if frameH <= 0 then return shape end
        per = ceilDiv(count, fits(frameH, cellH, gap))
    else
        if frameW <= 0 then return shape end
        per = ceilDiv(count, ceilDiv(count, fits(frameW - lead, cellW, gap)))
    end
    local out = {}
    for k, v in pairs(shape) do out[k] = v end
    out.perLine = perLine(per)
    return out
end

function LayoutGrid.Tabs(runs, per)
    per = perLine(per)
    local out = {}
    for _, n in ipairs(runs) do
        for i = 1, n do out[#out + 1] = i == 1 or #out % per == 0 end
    end
    return out
end

local CORNER_POINT = { TopLeft = "TOPLEFT", TopRight = "TOPRIGHT", BottomLeft = "BOTTOMLEFT", BottomRight = "BOTTOMRIGHT" }
local FACING = {
    Left = { TopRight = "TOPLEFT", BottomRight = "BOTTOMLEFT" },
    Right = { TopLeft = "TOPRIGHT", BottomLeft = "BOTTOMRIGHT" },
    Above = { BottomLeft = "TOPLEFT", BottomRight = "TOPRIGHT" },
    Below = { TopLeft = "BOTTOMLEFT", TopRight = "BOTTOMRIGHT" },
}

function LayoutGrid.MemberAnchor(side, corner, away, shift)
    local point, relative = CORNER_POINT[corner], FACING[side][corner]
    if side == "Left" then return point, relative, -away, shift end
    if side == "Right" then return point, relative, away, shift end
    if side == "Above" then return point, relative, shift, away end
    return point, relative, shift, -away
end

local TAB_GAP, TAB_GAP_ACROSS = 6, 4

function LayoutGrid.Line(tab, entries, across, right, bottom)
    local e = { x = 0, y = 0, w = entries.w, h = entries.h }
    if not tab then return e.w, e.h, nil, e end
    local t
    local w, h
    if across then
        w, h = math.max(entries.w, tab.w), tab.h + TAB_GAP_ACROSS + entries.h
        t = { x = 0, y = 0, w = w, h = tab.h }
        if bottom then t.y = h - tab.h else e.y = tab.h + TAB_GAP_ACROSS end
        if right then e.x = w - entries.w end
    else
        w, h = tab.w + TAB_GAP + entries.w, math.max(entries.h, tab.h)
        t = { x = 0, y = 0, w = tab.w, h = h }
        if right then t.x = w - tab.w else e.x = tab.w + TAB_GAP end
        if bottom then e.y = h - entries.h end
    end
    return w, h, t, e
end

local roleRank = {}
local classRank = {}
local queueRank = {}
local cdRank = {}
local index = {}

local function fixed(x, y)
    local qx, qy = queueRank[x] or math.huge, queueRank[y] or math.huge
    if qx ~= qy then return qx < qy end
    local dx, dy = cdRank[x] or 0, cdRank[y] or 0
    if dx ~= dy then return dx < dy end
    local rx, ry = roleRank[x] or 0, roleRank[y] or 0
    if rx ~= ry then return rx < ry end
    local cx, cy = classRank[x] or 0, classRank[y] or 0
    if cx ~= cy then return cx < cy end
    return index[x] < index[y]
end

local function readyFirst(x, y)
    if (x.dead or false) ~= (y.dead or false) then return not x.dead end
    if x.ready ~= y.ready then return x.ready end
    if (x.unknown or false) ~= (y.unknown or false) then return not x.unknown end
    if (x.maybe or false) ~= (y.maybe or false) then return not x.maybe end
    if x.remaining ~= y.remaining then return x.remaining < y.remaining end
    return fixed(x, y)
end

local function rankOf(list, value)
    for k, v in ipairs(list) do
        if v == value then return k end
    end
    return #list + 1
end

local function rankRoles(states, roleOrder, classOrder, queue)
    for i, s in ipairs(states) do
        index[s] = i
        if queue then
            cdRank[s] = s.cd
            for k, name in ipairs(queue) do
                if s.name and name == s.name then queueRank[s] = k end
            end
        end
        if roleOrder then roleRank[s] = rankOf(roleOrder, s.role) end
        local classes = classOrder and classOrder[s.role]
        if classes then classRank[s] = rankOf(classes, s.classId) end
    end
end

local function clearRanks(states)
    for _, s in ipairs(states) do
        index[s] = nil
        roleRank[s] = nil
        classRank[s] = nil
        queueRank[s] = nil
        cdRank[s] = nil
    end
end

-- queue: member names that go first, in that order (the kick queue); everyone else follows the shorter cooldown, then role and class order.
function LayoutGrid.Sort(states, shape, roleOrder, out, classOrder, queue)
    out = out or {}
    for i = #states + 1, #out do out[i] = nil end
    for i, s in ipairs(states) do out[i] = s end
    rankRoles(states, roleOrder, classOrder, queue)
    table.sort(out, shape.sort == "ReadyFirst" and readyFirst or fixed)
    clearRanks(states)
    return out
end

function LayoutGrid.Next(states, roleOrder, classOrder, queue)
    rankRoles(states, roleOrder or {}, classOrder, queue)
    local best
    for i, s in ipairs(states) do
        if s.ready and not s.dead and not s.unknown and (not best or fixed(s, states[best])) then best = i end
    end
    clearRanks(states)
    return best
end

function LayoutGrid.ClassesIn(order, role)
    local has = {}
    for specId, spec in pairs(ns.Specs) do
        local id = LayoutGrid.ClassId(spec.class)
        if id and LayoutGrid.RoleOf(specId) == role then has[id] = true end
    end
    local out = {}
    for _, id in ipairs(order) do
        if has[id] then out[#out + 1] = id end
    end
    return out
end

function LayoutGrid.ClassId(token)
    for id, t in pairs(ns.Classes) do
        if t == token then return id end
    end
end

function LayoutGrid.Surplus(sparse, keep)
    local out = {}
    for i in pairs(sparse) do
        if type(i) == "number" and i > keep then out[#out + 1] = i end
    end
    table.sort(out)
    return out
end

function LayoutGrid.ByMember(entries)
    local out, at = {}, {}
    for _, e in ipairs(entries) do
        local key = e.member.guid or e.member
        local k = at[key]
        if not k then
            k = #out + 1
            at[key], out[k] = k, {}
        end
        table.insert(out[k], e)
    end
    return out
end

function LayoutGrid.Best(states, cds)
    local best
    for i, s in ipairs(states) do
        if not best then
            best = i
        else
            local b = states[best]
            if (s.ready or false) ~= (b.ready or false) then
                if s.ready then best = i end
            elseif s.remaining ~= b.remaining then
                if s.remaining < b.remaining then best = i end
            elseif (cds[i] or 0) < (cds[best] or 0) then
                best = i
            end
        end
    end
    return best
end

function LayoutGrid.MemberStack(groups, side)
    local out, far = {}, nil
    for i, g in ipairs(groups) do
        if g.side == side then
            local beside = side == "Left" or side == "Right"
            local away = (far or 0) + (beside and g.offsetX or g.offsetY)
            out[i] = away
            far = math.max(far or away, away + (beside and g.w or g.h))
        end
    end
    return out
end
