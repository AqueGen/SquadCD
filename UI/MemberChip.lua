local _, ns = ...

local MemberChip = {}
ns.MemberChip = MemberChip

local T = ns.Theme
local E = ns.MemberEdit
local PAD, ROW_H, BUTTON_H, SPACE, GAP, DISTANCE = 8, 24, 20, 3, 10, 8
local MIN_SIZE, MAX_SIZE = 12, 40
local SIDES = { "Left", "Right", "Above", "Below" }
local LABELS = { "None", "Glyph", "Short" }
local LABEL_TEXT = { None = "None", Glyph = "Glyph", Short = "Short text" }
local BACKGROUNDS = { "None", "Default", "Black", "Slate" }
local CORNERS = { "TopLeft", "TopRight", "BottomLeft", "BottomRight" }

local chip, corner
local buttons, texts = {}, {}
local nb, nt, x, y, width = 0, 0, 0, 0, 0

local function edit(fn, ...)
    local args = { ... }
    return function()
        ns.EditMode.EditMembers(function(layout, gi) return fn(layout, gi, unpack(args)) end)
    end
end

local function text(s, color)
    nt = nt + 1
    local t = texts[nt] or chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    texts[nt] = t
    t:SetText(s)
    t:SetTextColor(unpack(color or T.muted))
    t:ClearAllPoints()
    t:SetPoint("LEFT", chip, "TOPLEFT", x, -(y + BUTTON_H / 2))
    t:Show()
    x = x + t:GetStringWidth() + 4
    return t
end

local function button(label, onClick, on, enabled, w)
    nb = nb + 1
    local b = buttons[nb] or ns.Widgets.Button(chip, "", 20)
    buttons[nb] = b
    b:SetText(label)
    w = w or math.max(22, math.ceil(b.label:GetStringWidth()) + 12)
    b:SetSize(w, BUTTON_H)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", chip, "TOPLEFT", x, -y)
    ns.Widgets.PaintChoice(b, on)
    b:SetEnabled(enabled ~= false)
    b:SetAlpha(enabled == false and 0.4 or 1)
    b:SetScript("OnClick", onClick)
    b:Show()
    x = x + w + SPACE
    return b
end

local function gap()
    x = x + GAP
end

local function newline()
    width = math.max(width, x - SPACE)
    x, y = PAD, y + ROW_H
end

local function stepper(value, lo, hi, set)
    button("-", function() set(math.max(lo, value - 1)) end, false, value > lo)
    text(tostring(value), T.text)
    button("+", function() set(math.min(hi, value + 1)) end, false, value < hi)
end

local function cornerButton(group)
    if not corner then
        corner = ns.Widgets.Button(chip, "", 26)
        corner.cells = {}
        for i, c in ipairs(CORNERS) do
            local cell = corner:CreateTexture(nil, "OVERLAY")
            cell:SetSize(5, 4)
            cell:SetPoint("TOPLEFT", corner, "TOPLEFT", 7 + ((i - 1) % 2) * 7, -5 - math.floor((i - 1) / 2) * 6)
            corner.cells[c] = cell
        end
    end
    local at = ns.LayoutGrid.MemberOrigin(group.shape.origin, group.side)
    for c, cell in pairs(corner.cells) do cell:SetColorTexture(1, 1, 1, c == at and 1 or 0.25) end
    corner:ClearAllPoints()
    corner:SetPoint("TOPLEFT", chip, "TOPLEFT", x, -y)
    corner:SetSize(26, BUTTON_H)
    corner:SetScript("OnClick", edit(function(layout, gi) return E.SetCorner(layout, gi, E.NextCorner(layout.groups[gi])) end))
    corner:Show()
    x = x + 26 + SPACE
end

local function nudge(dx, dy)
    return function()
        local step = IsShiftKeyDown() and 10 or 1
        ns.EditMode.EditMembers(function(layout, gi) return E.MoveBy(layout, gi, dx * step, dy * step) end)
    end
end

local function build()
    local layout = ns.DB.layout
    local selected = ns.EditMode.Selected()
    local group = layout.groups[selected]
    nb, nt, width = 0, 0, 0
    x, y = PAD, PAD

    text("Editing icons at party frames", T.gold)
    text("Esc or Done to finish")
    gap()
    button("Done", function() ns.EditMode.StopMembers() end, true)
    newline()

    text("Group")
    for i in ipairs(layout.groups) do
        button(tostring(i), function() ns.EditMode.Select(i) end, i == selected)
    end
    gap()
    button("Add group", edit(E.AddGroup))
    button("Remove group", edit(E.RemoveGroup), false, #layout.groups > 1)
    newline()

    if group then
        local inGroup = {}
        for _, t in ipairs(group.types) do inGroup[t] = true end
        text("Types")
        for _, t in ipairs(ns.LayoutModel.VisibleTypes(layout)) do
            local b = button(ns.LayoutRules.LABELS[t] or t, edit(E.ToggleType, t), inGroup[t])
            if not inGroup[t] then b:SetAlpha(0.6) end
        end
        newline()

        text("Side")
        for _, side in ipairs(SIDES) do
            button(side:sub(1, 1), edit(E.SetSide, side), group.side == side)
        end
        gap()
        button("Rows first", edit(E.SetAxis, "Rows"), group.shape.axis == "Rows")
        button("Columns first", edit(E.SetAxis, "Columns"), group.shape.axis == "Columns")
        gap()
        text("Per line")
        stepper(group.shape.perLine, 1, 12, function(v) edit(E.SetPerLine, v)() end)
        text("Corner")
        cornerButton(group)
        newline()

        local look = ns.LayoutModel.LookOf(layout, group, true)
        text("Icon size")
        stepper(look.iconSize, MIN_SIZE, MAX_SIZE, function(v) edit(E.SetLook, "iconSize", v)() end)
        gap()
        text("Type labels")
        for _, l in ipairs(LABELS) do
            button(LABEL_TEXT[l], edit(E.SetLook, "labels", l), look.labels == l)
        end
        newline()

        text("Background")
        for _, bg in ipairs(BACKGROUNDS) do
            button(bg, edit(E.SetLook, "background", bg), look.background == bg)
        end
        gap()
        text("Offset")
        text(group.offsetX .. ", " .. group.offsetY, T.text)
        button("<", nudge(-1, 0))
        button(">", nudge(1, 0))
        button("^", nudge(0, -1))
        button("v", nudge(0, 1))
        button("Reset", edit(E.ResetOffset))
        newline()
    end
    if not group and corner then corner:Hide() end

    for i = nb + 1, #buttons do buttons[i]:Hide() end
    for i = nt + 1, #texts do texts[i]:Hide() end
    chip:SetSize(width + PAD, y + PAD - (ROW_H - BUTTON_H))
end

local function follow()
    local holder = ns.Rows.Holder(ns.EditMode.Selected())
    chip:ClearAllPoints()
    if not holder then
        chip:SetPoint("TOP", UIParent, "TOP", 0, -100)
    elseif (holder:GetTop() or 0) + DISTANCE + chip:GetHeight() <= UIParent:GetTop() then
        chip:SetPoint("BOTTOMLEFT", holder, "TOPLEFT", 0, DISTANCE)
    else
        chip:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", 0, -DISTANCE)
    end
end

local function frame()
    if chip then return chip end
    chip = CreateFrame("Frame", "HuddleMemberChip", UIParent, "BackdropTemplate")
    tinsert(UISpecialFrames, "HuddleMemberChip")
    chip:SetFrameStrata("DIALOG")
    chip:SetClampedToScreen(true)
    chip:EnableMouse(true)
    T.Panel(chip)
    chip:SetBackdropBorderColor(unpack(T.gold))
    chip:SetScript("OnHide", function()
        if ns.EditMode.Members() then ns.EditMode.StopMembers() end
    end)
    return chip
end

function MemberChip.Refresh()
    if not ns.EditMode.Members() then
        if chip then chip:Hide() end
        ns.Rows.Outline(nil)
        return
    end
    frame()
    build()
    follow()
    chip:Show()
    ns.Rows.Outline(ns.EditMode.Selected())
end
