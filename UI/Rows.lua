local _, ns = ...

local Rows = {}
ns.Rows = Rows

local T = ns.Theme
local SLOT_W, PAD = 60, 4

local SIDES = {
    LEFT = { "RIGHT", "LEFT", -1, 0, "RIGHT", -1 },
    RIGHT = { "LEFT", "RIGHT", 1, 0, "LEFT", 1 },
    ABOVE = { "BOTTOMLEFT", "TOPLEFT", 0, 1, "LEFT", 1 },
    BELOW = { "TOPLEFT", "BOTTOMLEFT", 0, -1, "LEFT", 1 },
}

local rows, slots, active = {}, {}, 0

local function row(i)
    if not rows[i] then
        rows[i] = { frame = CreateFrame("Frame", nil, UIParent), icons = {} }
    end
    return rows[i]
end

local function slot(stack, i)
    if not slots[i] then
        local f = CreateFrame("Frame", nil, stack)
        local name = f:CreateFontString(nil, "OVERLAY")
        name:SetFont(T.FONT, 11, "OUTLINE")
        name:SetPoint("LEFT", 4, 0)
        f.name = name
        slots[i] = f
    end
    return slots[i]
end

local function layoutStack(stacked, size, spacing)
    local stack = ns.Anchors.Stack()
    local byGuid = {}
    for _, f in ipairs(slots) do f:Hide() end
    if #stacked == 0 then
        stack:Hide()
        return byGuid
    end
    T.Panel(stack)
    stack:EnableMouse(not ns.DB.panel.locked)
    stack:SetSize(SLOT_W + PAD * 2, #stacked * (size + spacing) - spacing + PAD * 2)
    ns.Anchors.PlaceStack()
    for i, m in ipairs(stacked) do
        local f = slot(stack, i)
        f:SetSize(SLOT_W, size)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", PAD, -PAD - (i - 1) * (size + spacing))
        f.name:SetText(ns.LayoutRules.ShortName(m.name or m.class, 8))
        f.name:SetTextColor(T.ClassColor(m.class))
        f:Show()
        byGuid[m.guid] = f
    end
    stack:Show()
    return byGuid
end

function Rows.Build(entries)
    local cfg = ns.DB.row
    local size, spacing = cfg.size, cfg.spacing
    local side = SIDES[cfg.side] or SIDES.LEFT
    local stacked = {}
    for _, e in ipairs(entries) do
        local anchor, isStack = ns.Anchors.FrameFor(e.member.unit)
        e.anchor = not isStack and anchor or nil
        if isStack then stacked[#stacked + 1] = e.member end
    end
    local stackSlots = layoutStack(stacked, size, spacing)

    for i = #entries + 1, #rows do rows[i].frame:Hide() end
    active = #entries
    local step = size + spacing
    for i, e in ipairs(entries) do
        local r = row(i)
        local anchor = e.anchor or stackSlots[e.member.guid]
        local dir = e.anchor and side or SIDES.RIGHT
        local n = math.min(#e.spells, cfg.max)
        r.guid, r.count, r.own = e.member.guid, n, e.own
        r.frame:ClearAllPoints()
        r.frame:SetSize(math.max(1, n * step - spacing), size)
        r.frame:SetPoint(dir[1], anchor, dir[2], dir[3] * (spacing + 1), dir[4] * (spacing + 1))
        for k = 1, n do
            local icon = r.icons[k] or ns.Icon.New(r.frame)
            r.icons[k] = icon
            icon:SetSpell(e.spells[k], e.member, size)
            icon.frame:ClearAllPoints()
            icon.frame:SetPoint(dir[5], r.frame, dir[5], dir[6] * (k - 1) * step, 0)
            icon.frame:Show()
        end
        for k = n + 1, #r.icons do r.icons[k].frame:Hide() end
        r.frame:SetShown(n > 0)
    end
end

function Rows.Update(tracker, now, sight)
    for i = 1, active do
        local r = rows[i]
        for k = 1, r.count do
            local icon = r.icons[k]
            local state = tracker:State(r.guid, icon.spell.id, icon.buf)
            if state then
                state.unknown = state.ready and ns.LayoutRules.Unknown(icon.spell.id, r.own, sight.plain, sight.secret)
            end
            icon:Update(state, now)
        end
    end
end

function Rows.Hide()
    for _, r in ipairs(rows) do r.frame:Hide() end
    active = 0
    ns.Anchors.Stack():Hide()
end
