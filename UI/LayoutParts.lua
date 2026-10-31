-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Parts = {}
ns.LayoutParts = Parts

local T = ns.SettingsTheme
local Widgets = ns.Widgets
local CHIP_GAP, CHIP_H = 4, 22

Parts.SIDES = { { value = "Left", text = "Left" }, { value = "Right", text = "Right" }, { value = "Above", text = "Above" }, { value = "Below", text = "Below" } }
local AXES = { { value = "Rows", text = "Rows first" }, { value = "Columns", text = "Columns first" } }
local CORNERS = {
    { value = "TopLeft", text = "Top left" }, { value = "TopRight", text = "Top right" },
    { value = "BottomLeft", text = "Bottom left" }, { value = "BottomRight", text = "Bottom right" },
}
local SORTS = { { value = "Fixed", text = "Fixed" }, { value = "ReadyFirst", text = "Ready first" } }
local LABELS = { { value = "None", text = "None" }, { value = "Icon", text = "Icon" }, { value = "Glyph", text = "Letter" }, { value = "Short", text = "Short text" }, { value = "Full", text = "Full text" } }
local BACKGROUNDS = { { value = "Default", text = "Default" }, { value = "Black", text = "Black" }, { value = "Slate", text = "Slate" }, { value = "None", text = "None" } }
local WIDE, LABELS_W = 280, 300

function Parts.Edit(fn, ...)
    fn(ns.DB.layout, ...)
    ns.LayoutModel.Normalize(ns.DB.layout)
    ns.Display.Changed()
end

function Parts.Label(t)
    return ns.LayoutRules.LABELS[t] or t
end

function Parts.Mark(parent, size)
    local mark = CreateFrame("Frame", nil, parent)
    mark:SetSize(size, size)
    mark.fill = mark:CreateTexture(nil, "BACKGROUND")
    mark.fill:SetAllPoints(mark)
    mark.glyph = mark:CreateTexture(nil, "ARTWORK")
    mark.glyph:SetAllPoints(mark)
    return mark, function(t)
        local style = T.TYPES[t] or T.TYPES.Personal
        mark.fill:SetColorTexture(style.fill[1], style.fill[2], style.fill[3], 1)
        mark.glyph:SetTexture(ns.Icon.TypeIcon(t))
        mark.glyph:SetVertexColor(unpack(style.text))
    end
end

local function both(a, b)
    return function()
        return (not a or a()) and (not b or b())
    end
end

function Parts.Look(group, opts)
    local function setting(key)
        return function(value) opts.set(key, value) end
    end
    local function get(key)
        return function() return opts.get()[key] end
    end
    local backdrop = both(opts.visible, opts.backdrop)
    group:Slider({ label = "Icon size", min = opts.member and 12 or 20, max = 40, get = get("iconSize"), set = setting("iconSize"), visible = opts.visible })
    local labels = opts.member and { LABELS[1], LABELS[2], LABELS[3], LABELS[4] } or LABELS
    group:Segmented({ label = "Type labels", options = labels, width = opts.member and WIDE or LABELS_W, get = get("labels"), set = setting("labels"), visible = opts.visible })
    group:Segmented({ label = "Background", options = BACKGROUNDS, width = WIDE, get = get("background"), set = setting("background"), visible = backdrop })
    if opts.member then return end
    group:Slider({ label = "Opacity", min = 0, max = 100, step = 5, format = "%d%%", get = get("opacity"), set = setting("opacity"), visible = backdrop })
    group:Slider({
        label = "Name letters", min = 3, max = 6, get = get("nameLetters"), set = setting("nameLetters"), visible = opts.visible,
        tooltip = "Letters of each name under the icons.",
    })
end

function Parts.Shape(group, opts)
    local function setting(key)
        return function(value) opts.set(key, value) end
    end
    local function get(key)
        return function() return opts.get()[key] end
    end
    group:Segmented({ label = "Fill order", options = AXES, get = get("axis"), set = setting("axis"), visible = opts.visible })
    group:Slider({ label = "Icons per line", min = 1, max = 12, get = get("perLine"), set = setting("perLine"), visible = opts.visible })
    group:Segmented({ label = "Grows from corner", options = CORNERS, width = WIDE, get = get("origin"), set = setting("origin"), visible = opts.visible })
    if opts.member then return end
    group:Segmented({
        label = "Order inside a type", options = SORTS, get = get("sort"), set = setting("sort"), visible = opts.visible,
        note = "Fixed: role and class priority",
    })
end

local function newChip(holder)
    local chip = Widgets.Button(holder, "", 60)
    chip.rail = chip:CreateTexture(nil, "ARTWORK")
    chip.rail:SetPoint("TOPLEFT", 1, -1)
    chip.rail:SetPoint("BOTTOMLEFT", 1, 1)
    chip.rail:SetWidth(4)
    chip.label:ClearAllPoints()
    chip.label:SetPoint("LEFT", chip, "LEFT", 10, 0)
    return chip
end

function Parts.Types(group, opts)
    local holder = CreateFrame("Frame", nil, group.frame)
    local chips, height = {}, CHIP_H
    local add = Widgets.Button(holder, "Add type", 80)
    add:SetScript("OnClick", function(self)
        local list = opts.choices()
        if #list == 0 or not MenuUtil then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            for _, t in ipairs(list) do
                root:CreateButton(Parts.Label(t), function()
                    opts.add(t)
                    group.page:Refresh()
                end)
            end
        end)
    end)
    group:Add(holder, function() return height end, function()
        local room = math.max((group.frame:GetWidth() or 0) - 2 * Widgets.PAD, 200)
        local x, y = 0, 0
        local types = opts.get()
        local function place(frame, w)
            if x > 0 and x + w > room then x, y = 0, y + CHIP_H + CHIP_GAP end
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", holder, "TOPLEFT", x, -y)
            x = x + w + CHIP_GAP
        end
        for i, t in ipairs(types) do
            local chip = chips[i] or newChip(holder)
            chips[i] = chip
            chip.type = t
            chip:SetText(Parts.Label(t))
            local fill = (T.TYPES[t] or T.TYPES.Personal).fill
            chip.rail:SetColorTexture(fill[1], fill[2], fill[3], 1)
            local w = math.floor(chip.label:GetStringWidth() + 20)
            chip:SetWidth(w)
            chip:SetScript("OnClick", function(self)
                opts.remove(self.type)
                group.page:Refresh()
            end)
            chip:Show()
            place(chip, w)
        end
        for i = #types + 1, #chips do chips[i]:Hide() end
        local any = #opts.choices() > 0
        add:SetEnabled(any)
        add:SetAlpha(any and 1 or 0.35)
        place(add, 80)
        height = y + CHIP_H
        holder:SetSize(room, height)
    end, opts.visible)
end

local DEMO = { { value = "Off", text = "Off" }, { value = "Me", text = "Only me" }, { value = "Group", text = "Whole group" } }

function Parts.Demo(group)
    group:Segmented({
        label = "Demo", options = DEMO,
        get = function() return ns.Demo.Mode() end,
        set = function(mode) ns.Demo.Set(mode) end,
        tooltip = "Sample members and cooldowns, so you can see the layout without a party. Out of combat only.",
    })
end

Parts.PRESETS = {
    { name = "Everything together, horizontal", hint = "One panel, types side by side" },
    { name = "Everything together, vertical", hint = "One panel, types stacked" },
    { name = "At party frames, left + panel", hint = "Defensives, burst, racials left of each frame" },
    { name = "At party frames, right + panel", hint = "Defensives, burst, racials right of each frame" },
    { name = "At party frames, below + panel", hint = "For party frames in a row" },
    { name = "At party frames, above + panel", hint = "For party frames in a row" },
}
local COLUMNS, CARD_GAP, CARD_H, THUMB_W, THUMB_H = 3, 8, 132, 120, 62
local CARD_FILL = { 20 / 255, 22 / 255, 27 / 255, 0.9 }
local FRAME_FILL = { 0x5B / 255, 0x3F / 255, 0x6E / 255, 1 }
local THUMB = { "Burst", "Personal", "External", "Group", "Kick", "Control", "Dispel", "Purge", "Movement" }
local PANEL = { "Kick", "Control", "Dispel", "Purge" }

local function fill(t)
    local c = T.TYPES[t].fill
    return { c[1], c[2], c[3], 1 }
end

local function thumbRects(kind)
    local out = {}
    local function rect(x, y, w, h, color) out[#out + 1] = { x, y, w, h, color } end
    local function panel(x)
        rect(x, 6, 26, 30, CARD_FILL)
        for i, t in ipairs(PANEL) do
            rect(x + 2, 9 + (i - 1) * 6, 2, 4, fill(t))
            rect(x + 6, 9 + (i - 1) * 6, t == "Kick" and 16 or 9, 4, fill(t))
        end
    end
    if kind == 1 then
        rect(4, 14, 112, 34, CARD_FILL)
        for i, t in ipairs(THUMB) do
            rect(7 + (i - 1) * 12, 17, 10, 2, fill(t))
            rect(7 + (i - 1) * 12, 21, t == "Kick" and 10 or 6, 22, fill(t))
        end
    elseif kind == 2 then
        rect(8, 3, 44, 56, CARD_FILL)
        for i, t in ipairs(THUMB) do
            rect(11, 6 + (i - 1) * 6, 3, 4, fill(t))
            rect(16, 6 + (i - 1) * 6, t == "Kick" and 30 or 6 + (i - 1) * 7 % 5 * 4, 4, fill(t))
        end
    elseif kind == 3 or kind == 4 then
        local left = kind == 3
        panel(left and 4 or 88)
        for i = 1, 5 do
            local frame, row, y = left and 84 or 6, left and 64 or 34, 4 + (i - 1) * 11
            rect(frame, y, 26, 9, FRAME_FILL)
            rect(row, y + 1, 3, 6, fill("Burst"))
            rect(row + 4, y + 1, 6, 6, fill("Personal"))
            rect(row + 11, y + 1, 3, 6, fill("External"))
        end
    else
        panel(88)
        local below = kind == 5
        for i = 1, 5 do
            local x = 4 + (i - 1) * 16
            rect(x, below and 8 or 44, 14, 9, FRAME_FILL)
            rect(x, below and 19 or 36, 3, 6, fill("Burst"))
            rect(x + 4, below and 19 or 36, 6, 6, fill("Personal"))
            rect(x, below and 27 or 28, 6, 6, fill("External"))
        end
    end
    return out
end

local function newCard(parent, n, onClick)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetBackdrop(T.FLAT)
    card:SetBackdropColor(unpack(T.panel))
    card:SetHeight(CARD_H)
    card.thumb = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card.thumb:SetPoint("TOPLEFT", 8, -8)
    card.thumb:SetPoint("TOPRIGHT", -8, -8)
    card.thumb:SetHeight(THUMB_H + 6)
    card.thumb:SetBackdrop(T.FLAT)
    card.thumb:SetBackdropColor(unpack(T.bg))
    card.thumb:SetBackdropBorderColor(0, 0, 0, 0)
    local canvas = CreateFrame("Frame", nil, card.thumb)
    canvas:SetSize(THUMB_W, THUMB_H)
    canvas:SetPoint("CENTER")
    for _, r in ipairs(thumbRects(n)) do
        local tex = canvas:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", canvas, "TOPLEFT", r[1], -r[2])
        tex:SetSize(r[3], r[4])
        tex:SetColorTexture(unpack(r[5]))
    end
    card.badge = CreateFrame("Frame", nil, card.thumb, "BackdropTemplate")
    card.badge:SetPoint("TOPRIGHT", -4, -4)
    card.badge:SetFrameLevel(canvas:GetFrameLevel() + 2)
    card.badge:SetSize(60, 16)
    card.badge:SetBackdrop(T.FLAT)
    card.badge:SetBackdropBorderColor(0, 0, 0, 0)
    card.badge.text = card.badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.badge.text:SetPoint("CENTER")
    card.name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.name:SetPoint("TOPLEFT", card.thumb, "BOTTOMLEFT", 0, -8)
    card.name:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    card.name:SetJustifyH("LEFT")
    card.name:SetText(Parts.PRESETS[n].name)
    card.hint = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.hint:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
    card.hint:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    card.hint:SetJustifyH("LEFT")
    card.hint:SetTextColor(unpack(T.muted))
    card.hint:SetText(Parts.PRESETS[n].hint)
    local hover = card:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.05)
    card:SetScript("OnClick", function() onClick(n) end)
    return card
end

local function paintCard(card, used, previewing)
    local color = previewing and { 0.3, 0.8, 0.4, 1 } or used and T.gold or T.border
    card:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    card.badge:SetShown(used or previewing)
    if previewing then
        card.badge:SetBackdropColor(0.3, 0.8, 0.4, 1)
        card.badge.text:SetText("Preview")
        card.badge.text:SetTextColor(0.05, 0.16, 0.07)
    elseif used then
        card.badge:SetBackdropColor(T.gold[1], T.gold[2], T.gold[3], 1)
        card.badge.text:SetText("In use")
        card.badge.text:SetTextColor(0.08, 0.08, 0.08)
    end
    card.badge:SetWidth(math.ceil(card.badge.text:GetStringWidth()) + 12)
end

function Parts.PresetCards(group, opts)
    local holder = CreateFrame("Frame", nil, group.frame)
    local cards = {}
    for n = 1, #Parts.PRESETS do cards[n] = newCard(holder, n, opts.pick) end
    local rows = math.ceil(#Parts.PRESETS / COLUMNS)
    local height = rows * CARD_H + (rows - 1) * CARD_GAP
    group:Add(holder, height, function()
        local room = math.max((group.frame:GetWidth() or 0) - 2 * Widgets.PAD, 300)
        local w = math.floor((room - (COLUMNS - 1) * CARD_GAP) / COLUMNS)
        holder:SetSize(room, height)
        local used, showing = opts.used(), opts.showing and opts.showing()
        for n, card in ipairs(cards) do
            local col, row = (n - 1) % COLUMNS, math.floor((n - 1) / COLUMNS)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", holder, "TOPLEFT", col * (w + CARD_GAP), -row * (CARD_H + CARD_GAP))
            card:SetWidth(w)
            paintCard(card, used == n and showing ~= n, showing == n)
        end
    end)
end

local PLACES = { { value = "panel", text = "Panel", w = 56 }, { value = "member", text = "At party frames", w = 104 }, { value = "off", text = "Off", w = 44 } }
local ROW_H, NAME_X, PLACE_X, SPLIT_X, ORDER_X = 24, 27, 160, 380, 452

local function newTypeRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)
    row.mark, row.paint = Parts.Mark(row, 16)
    row.mark:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row, "LEFT", NAME_X, 0)
    row.name:SetWidth(PLACE_X - NAME_X - 6)
    row.name:SetJustifyH("LEFT")
    row.places = {}
    local x = PLACE_X
    for i, p in ipairs(PLACES) do
        local b = Widgets.Button(row, p.text, p.w)
        b:SetPoint("LEFT", row, "LEFT", x, 0)
        b.value = p.value
        row.places[i] = b
        x = x + p.w - 1
    end
    row.split = LibStub("LibVelvet-1.0").Checkbox(row, 22)
    row.split:SetPoint("LEFT", row, "LEFT", SPLIT_X, 0)
    row.split.text = row.split:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.split.text:SetPoint("LEFT", row.split, "RIGHT", 2, 0)
    row.split.text:SetText("Split")
    row.number = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.number:SetPoint("RIGHT", row, "LEFT", ORDER_X + 18, 0)
    row.up = Widgets.Button(row, "Up", 40)
    row.up:SetPoint("LEFT", row, "LEFT", ORDER_X + 24, 0)
    row.down = Widgets.Button(row, "Down", 44)
    row.down:SetPoint("LEFT", row.up, "RIGHT", 4, 0)
    return row
end

function Parts.TypesTable(page)
    local Model = ns.LayoutModel
    local group = page:Group("Types: where they show and their order")
    group:Note("Panel: a section of the group panel (Panels page). At party frames: next to each member's party frame (At party frames page). Off: not shown. Split shows stuns and crowd control as two types.")
    local holder = CreateFrame("Frame", nil, group.frame)
    local header = CreateFrame("Frame", nil, holder)
    header:SetPoint("TOPLEFT")
    header:SetSize(560, 18)
    for _, h in ipairs({ { "Type", NAME_X }, { "Show in", PLACE_X }, { "Split", SPLIT_X }, { "Order", ORDER_X } }) do
        local s = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        s:SetPoint("LEFT", header, "LEFT", h[2], 0)
        s:SetTextColor(unpack(T.gold))
        s:SetText(h[1])
    end
    local rows = {}
    for i = 1, #ns.LayoutRules.TYPES do
        local row = newTypeRow(holder)
        row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(18 + (i - 1) * ROW_H))
        row:SetPoint("RIGHT", holder, "RIGHT")
        for _, b in ipairs(row.places) do
            b:SetScript("OnClick", function(self)
                Parts.Edit(Model.SetPlace, row.type, self.value)
                page:Refresh()
            end)
        end
        row.split:SetScript("OnClick", function(self)
            Parts.Edit(Model.SetSplit, self:GetChecked() and true or false)
            page:Refresh()
        end)
        row.up:SetScript("OnClick", function()
            Parts.Edit(Model.MoveInOrder, row.type, -1)
            page:Refresh()
        end)
        row.down:SetScript("OnClick", function()
            Parts.Edit(Model.MoveInOrder, row.type, 1)
            page:Refresh()
        end)
        rows[i] = row
    end
    local count = 0
    group:Add(holder, function() return 18 + count * ROW_H end, function()
        local layout = ns.DB.layout
        local order = layout.typeOrder
        count = #order
        holder:SetSize(math.max((group.frame:GetWidth() or 0) - 2 * Widgets.PAD, 300), 18 + count * ROW_H)
        for i, row in ipairs(rows) do
            local t = order[i]
            row:SetShown(t ~= nil)
            if t then
                row.type = t
                row.paint(t)
                row.name:SetText(Parts.Label(t))
                local place = Model.PlaceOf(layout, t)
                for _, b in ipairs(row.places) do Widgets.PaintChoice(b, b.value == place) end
                local merged = t == "Control" or t == "Stun" or t == "CC"
                row.split:SetShown(merged)
                row.split:SetChecked(layout.split)
                row.number:SetText(i)
                row.number:SetTextColor(unpack(place == "off" and T.muted or T.text))
                row.up:SetEnabled(i > 1)
                row.up:SetAlpha(i > 1 and 1 or 0.35)
                row.down:SetEnabled(i < count)
                row.down:SetAlpha(i < count and 1 or 0.35)
            end
        end
    end)
    group:Note("Up and Down set the order of types inside every panel section and member group. A type alone in its panel section moves its whole section past the next section in the panel; sections in their own window keep their place.")
end
