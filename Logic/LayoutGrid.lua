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

function LayoutGrid.Cells(count, shape, size, gap)
    if count <= 0 then return {}, 0, 0 end
    local per = math.max(MIN_PER_LINE, math.min(MAX_PER_LINE, math.floor(shape.perLine or MIN_PER_LINE)))
    local rows = shape.axis ~= "Columns"
    local step = size + gap
    local lines = math.ceil(count / per)
    local along = math.min(count, per) * step - gap
    local across = lines * step - gap
    local w, h = across, along
    if rows then w, h = along, across end
    local flipX = shape.origin == "TopRight" or shape.origin == "BottomRight"
    local flipY = shape.origin == "BottomLeft" or shape.origin == "BottomRight"
    local out = {}
    for i = 0, count - 1 do
        local u, v = (i % per) * step, math.floor(i / per) * step
        local x, y = u, v
        if not rows then x, y = v, u end
        if flipX then x = w - x - size end
        if flipY then y = h - y - size end
        out[i + 1] = { x = x, y = y }
    end
    return out, w, h
end

local roleRank = {}
local index = {}

local function fixed(x, y)
    local rx, ry = roleRank[x] or 0, roleRank[y] or 0
    if rx ~= ry then return rx < ry end
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

local function rankRoles(states, roleOrder)
    for i, s in ipairs(states) do
        index[s] = i
        if roleOrder then
            local rank = #roleOrder + 1
            for k, r in ipairs(roleOrder) do
                if r == s.role then rank = k break end
            end
            roleRank[s] = rank
        end
    end
end

local function clearRanks(states)
    for _, s in ipairs(states) do
        index[s] = nil
        roleRank[s] = nil
    end
end

function LayoutGrid.Sort(states, shape, roleOrder, out)
    out = out or {}
    for i = #states + 1, #out do out[i] = nil end
    for i, s in ipairs(states) do out[i] = s end
    rankRoles(states, roleOrder)
    table.sort(out, shape.sort == "ReadyFirst" and readyFirst or fixed)
    clearRanks(states)
    return out
end

function LayoutGrid.Next(states, roleOrder)
    rankRoles(states, roleOrder or {})    local best
    for i, s in ipairs(states) do
        if s.ready and not s.dead and (not best or roleRank[s] < roleRank[states[best]]) then best = i end
    end
    clearRanks(states)
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
