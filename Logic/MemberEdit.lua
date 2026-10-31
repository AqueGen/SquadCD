local _, ns = ...

local MemberEdit = {}
ns.MemberEdit = MemberEdit

local Model = ns.LayoutModel

MemberEdit.MAX_OFFSET = 400
local STACK_GAP = 6
local MIN_SIZE, MAX_SIZE = 12, 40

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local copy = ns.Copy

local function groupOf(layout, gi)
    return layout.groups[gi]
end

function MemberEdit.ToggleType(layout, gi, type)
    local g = groupOf(layout, gi)
    if not g then return layout end
    local place, at = Model.PlaceOf(layout, type)
    Model.SetPlace(layout, type, "off")
    if not (place == "member" and at == gi) then
        g.types[#g.types + 1] = type
    end
    return layout
end

function MemberEdit.SetSide(layout, gi, side)
    local g = groupOf(layout, gi)
    if g then g.side = side end
    return layout
end

function MemberEdit.SetAxis(layout, gi, axis)
    local g = groupOf(layout, gi)
    if g then g.shape.axis = axis end
    return layout
end

function MemberEdit.SetPerLine(layout, gi, n)
    local g = groupOf(layout, gi)
    if g then g.shape.perLine = clamp(n, 1, 12) end
    return layout
end

function MemberEdit.SetCorner(layout, gi, corner)
    local g = groupOf(layout, gi)
    if g then g.shape.origin = corner end
    return layout
end

local RIGHT = { TopRight = true, BottomRight = true }
local BOTTOM = { BottomLeft = true, BottomRight = true }
local OPPOSITE = { TopLeft = "BottomRight", TopRight = "BottomLeft", BottomLeft = "TopRight", BottomRight = "TopLeft" }

function MemberEdit.PickCorner(g, clicked)
    local beside = g.side == "Left" or g.side == "Right"
    local right = RIGHT[beside and g.shape.origin or clicked]
    local bottom = BOTTOM[beside and clicked or g.shape.origin]
    return (bottom and "Bottom" or "Top") .. (right and "Right" or "Left")
end

function MemberEdit.NextCorner(g)
    return MemberEdit.PickCorner(g, OPPOSITE[g.shape.origin] or "BottomRight")
end

function MemberEdit.SetLook(layout, gi, key, value)
    local g = groupOf(layout, gi)
    if not g then return layout end
    local look = copy(Model.LookOf(layout, g, true))
    if key == "iconSize" then value = clamp(value, MIN_SIZE, MAX_SIZE) end
    look[key] = value
    g.look = look
    return layout
end

local function setOffset(g, x, y)
    g.offsetX = clamp(x, -MemberEdit.MAX_OFFSET, MemberEdit.MAX_OFFSET)
    g.offsetY = clamp(y, -MemberEdit.MAX_OFFSET, MemberEdit.MAX_OFFSET)
end

function MemberEdit.MoveBy(layout, gi, dx, dy)
    local g = groupOf(layout, gi)
    if not g then return layout end
    if g.side == "Left" then
        setOffset(g, g.offsetX - dx, g.offsetY - dy)
    elseif g.side == "Below" then
        setOffset(g, g.offsetX + dx, g.offsetY + dy)
    else
        setOffset(g, g.offsetX + dx, g.offsetY - dy)
    end
    return layout
end

local function stacked(layout, gi, side)
    for i = 1, gi - 1 do
        if layout.groups[i].side == side then
            local first = layout.groups[1]
            if side == "Left" or side == "Right" then return STACK_GAP, first.offsetY end
            return first.offsetX, STACK_GAP
        end
    end
end

function MemberEdit.ResetOffset(layout, gi)
    local g = groupOf(layout, gi)
    if not g then return layout end
    local x, y = stacked(layout, gi, g.side)
    if not x then
        local fresh = Model.NewGroup({}, g.side)
        x, y = fresh.offsetX, fresh.offsetY
    end
    setOffset(g, x, y)
    return layout
end

function MemberEdit.AddGroup(layout)
    local g = Model.NewGroup({}, "Right")
    local x, y = stacked(layout, #layout.groups + 1, g.side)
    local first = layout.groups[1]
    if x then
        g.offsetX, g.offsetY = x, y
    elseif first then
        g.offsetX, g.offsetY = first.offsetX, first.offsetY
    end
    layout.groups[#layout.groups + 1] = g
    return #layout.groups
end

function MemberEdit.RemoveGroup(layout, gi)
    if #layout.groups < 2 or not groupOf(layout, gi) then return layout end
    local removed = table.remove(layout.groups, gi)
    local types = layout.groups[1].types
    for _, t in ipairs(removed.types) do types[#types + 1] = t end
    return layout
end
