-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Parts = ns.LayoutParts
local Model = ns.LayoutModel
local Widgets = ns.Widgets
local T = ns.SettingsTheme

local STYLES = { { value = "Bars", text = "Bars" }, { value = "Icons", text = "Icons" } }
local GROWS = { { value = "TopLeft", text = "Down" }, { value = "BottomLeft", text = "Up" } }
local ROW_H, NAME_W, MAX_ROWS = 24, 180, 5

local function layout()
    return ns.DB.layout
end

local function kickSection()
    local place, at = Model.PlaceOf(layout(), "Kick")
    return place == "panel" and layout().sections[at] or nil
end

local function editSection(fn)
    if kickSection() then Parts.Edit(function(l) fn(l, kickSection()) end) end
end

-- Members with a kick, by name: the live party, or the demo party when solo.
local function groupNames()
    local names = {}
    local live = ns.Display.HasMembers()
    local members = live and ns.Group.Members() or ns.Demo.Source(5).members
    for _, m in ipairs(members) do
        local name = m.name
        if live then
            local ok, n = pcall(UnitName, m.unit)
            name = ok and type(n) == "string" and not issecretvalue(n) and n or nil
        end
        if name and ns.Kicks.SpellOf(m) then names[#names + 1] = name end
    end
    return names
end

local function tracker(page)
    local group = page:Group("Kick tracker")
    group:Check({
        label = "Track kicks",
        get = function() return Model.PlaceOf(layout(), "Kick") ~= "off" end,
        set = function(on) Parts.Edit(Model.SetTracked, "Kick", on) end,
    })
    group:Segmented({
        label = "Show as", options = STYLES,
        get = function() return layout().kickStyle end,
        set = function(v) Parts.Edit(function(l) l.kickStyle = v end) end,
        visible = function() return kickSection() ~= nil end,
    })
    group:Note({ text = "Bars: one bar per member that fills as the kick comes back. Icons: one icon per member.", visible = function() return kickSection() ~= nil end })
    group:Check({
        label = "Own window",
        get = function() return kickSection() ~= nil and kickSection().ownWindow end,
        set = function(on) editSection(function(_, s) s.ownWindow = on end) end,
        visible = function() return kickSection() ~= nil and layout().overlay == "OnePanel" end,
    })
    group:Segmented({
        label = "Grows", options = GROWS,
        get = function() return (kickSection().shape or layout().panelShape).origin == "BottomLeft" and "BottomLeft" or "TopLeft" end,
        set = function(v)
            editSection(function(l, s)
                s.shape = s.shape or ns.Copy(l.panelShape)
                s.shape.origin = v
            end)
        end,
        visible = function() return kickSection() ~= nil and Model.OwnWindow(layout(), kickSection()) end,
    })
    group:Note({ text = "Kicks are at the party frames now; the panel options apply when they are in the panel (Presets and types).", visible = function() return Model.PlaceOf(layout(), "Kick") == "member" end })
    group:Button({ text = "Move the panels", width = 140, onClick = function() ns.EditMode.TogglePanels() end, visible = function() return kickSection() ~= nil end })
end

local ARRANGE = { { value = "Split", text = "Cast below" }, { value = "Row", text = "One row" }, { value = "Column", text = "One column" } }

local function focusGroup(page)
    local group = page:Group("Focus target")
    group.key = "focus"
    local function on() return kickSection() ~= nil and layout().kickFocus end
    group:Note({ text = "Your focus target, its cast and the casts it is expected to make next, next to the kick tracker. In Move the panels a drag moves all three together, Alt-drag moves one piece.", visible = function() return kickSection() ~= nil end })
    group:Check({
        label = "Show focus target",
        tooltip = "Raid mark and name of your focus target.",
        get = function() return layout().kickFocus end,
        set = function(v) Parts.Edit(function(l) l.kickFocus = v end) end,
        visible = function() return kickSection() ~= nil end,
    })
    group:Check({
        label = "Show focus cast",
        tooltip = "What your focus target is casting now: spell, icon and progress.",
        get = function() return layout().kickFocusCast end,
        set = function(v) Parts.Edit(function(l) l.kickFocusCast = v end) end,
        visible = on,
    })
    group:Check({
        label = "Show focus next casts",
        tooltip = "The casts CastAhead expects next from your focus target, with seconds until each.",
        get = function() return layout().kickFocusNext end,
        set = function(v) Parts.Edit(function(l) l.kickFocusNext = v end) end,
        visible = function() return on() and type(CastAheadAPI) == "table" end,
    })
    group:Note({ text = "Next casts need the CastAhead addon.", color = T.muted, visible = function() return on() and type(CastAheadAPI) ~= "table" end })
    group:Segmented({
        label = "Arrangement", options = ARRANGE,
        get = function() return layout().focusArrange end,
        set = function(v) Parts.Edit(function(l) l.focusArrange, l.focusPos = v, {} end) end,
        visible = on,
    })
    group:Note({ text = "Custom: you moved the pieces yourself. Pick an arrangement to line them up again.", color = T.muted, visible = function() return on() and layout().focusArrange == "Custom" end })
    group:Slider({
        label = "Text size", min = 8, max = 24,
        get = function() return layout().kickFocusSize end,
        set = function(v) Parts.Edit(function(l) l.kickFocusSize = v end) end,
        visible = on,
    })
    group:Slider({
        label = "Box width", min = 100, max = 320,
        tooltip = "Width of the focus target and cast boxes. Longer names are cut at the edge.",
        get = function() return layout().focusWidth end,
        set = function(v) Parts.Edit(function(l) l.focusWidth = v end) end,
        visible = on,
    })
    group:Button({
        text = "Reset focus layout", width = 140, visible = on,
        onClick = function() Parts.Edit(function(l) l.focusArrange, l.focusPos = "Split", {} end) end,
    })
end

local function queue(page)
    local group = page:Group("Who kicks first")
    group:Note("The kick list puts these members first, in this order, and the next-to-kick mark follows it. Members you have not placed come after, by role and class.")
    local holder = CreateFrame("Frame", nil, group.frame)
    local rows = {}
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Frame", nil, holder)
        row:SetSize(NAME_W + 2 * 64, ROW_H)
        row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(i - 1) * (ROW_H + 2))
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT")
        row.name:SetWidth(NAME_W - 8)
        row.name:SetJustifyH("LEFT")
        row.up = Widgets.Button(row, "Up", 60)
        row.up:SetPoint("LEFT", row, "LEFT", NAME_W, 0)
        row.down = Widgets.Button(row, "Down", 60)
        row.down:SetPoint("LEFT", row.up, "RIGHT", 4, 0)
        local function step(dir)
            local names = Model.QueueFor(layout(), groupNames())
            Parts.Edit(function(l)
                Model.SetQueue(l, names)
                Model.MoveInQueue(l, row.member, dir)
            end)
            group.page:Refresh()
        end
        row.up:SetScript("OnClick", function() step(-1) end)
        row.down:SetScript("OnClick", function() step(1) end)
        rows[i] = row
    end
    local height = ROW_H
    group:Add(holder, function() return height end, function()
        local names = Model.QueueFor(layout(), groupNames())
        for i, row in ipairs(rows) do
            local name = names[i]
            row:SetShown(name ~= nil)
            if name then
                row.member = name
                row.name:SetText(("%d. %s"):format(i, name))
                row.up:SetEnabled(i > 1)
                row.up:SetAlpha(i > 1 and 1 or 0.35)
                row.down:SetEnabled(i < #names)
                row.down:SetAlpha(i < #names and 1 or 0.35)
            end
        end
        height = math.max(1, math.min(#names, MAX_ROWS)) * (ROW_H + 2)
        holder:SetSize(NAME_W + 2 * 64, height)
    end)
    group:Note({ text = "No party: the list shows the demo party.", visible = function() return not ns.Display.HasMembers() end, color = T.muted })
end

ns.Window.Register("kicks", function(page)
    tracker(page)
    focusGroup(page)
    queue(page)
end, { preview = "panel", focus = "panel" })
