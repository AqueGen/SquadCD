-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local T = ns.Theme
local Widgets = ns.Widgets
local TAB_W, TAB_MIN_W, TAB_H, TAB_COLUMNS = 92, 84, 24, 7
local ROW_H = 22
local NAME_X, TYPE_X, CD_X, TAG_X = 48, 250, 360, 420
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local POTION = { id = "potion", name = "Combat potion", type = "Potion", cd = ns.Potions[1].cd }

local function Duration(cd)
    if cd < 60 then return cd .. "s" end
    if cd % 60 == 0 then return cd / 60 .. "m" end
    return ("%dm %ds"):format(cd / 60, cd % 60)
end

local function Tabs(group, select)
    local holder = CreateFrame("Frame", nil, group.frame)
    local count = #ns.Classes + 1
    local buttons = {}
    for i = 1, count do
        local class = ns.Classes[i - 1]
        local button = Widgets.Button(holder, class and T.ClassName(class) or "All", TAB_W)
        button:SetScript("OnClick", function() select(class) end)
        button.class = class
        buttons[i] = button
    end
    local _, height = ns.WidgetRules.Grid(count, TAB_COLUMNS, TAB_W, TAB_H)
    return holder, height, function(current)
        local cellW = math.max(TAB_MIN_W, math.min(TAB_W, math.floor((group.frame:GetWidth() - 2 * Widgets.PAD) / TAB_COLUMNS)))
        local cells = ns.WidgetRules.Grid(count, TAB_COLUMNS, cellW, TAB_H)
        holder:SetSize(TAB_COLUMNS * cellW, height)
        for i, button in ipairs(buttons) do
            button:SetWidth(cellW - 4)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", holder, "TOPLEFT", cells[i].x, -cells[i].y)
        end
        for _, button in ipairs(buttons) do
            Widgets.PaintChoice(button, button.class == current)
            if button.class and button.class ~= current then button.label:SetTextColor(T.ClassColor(button.class)) end
        end
    end
end

local function Text(parent, x, color)
    local s = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s:SetPoint("LEFT", parent, "LEFT", x, 0)
    s:SetJustifyH("LEFT")
    s:SetWordWrap(false)
    s:SetTextColor(unpack(color or T.text))
    return s
end

local function NewRow(list)
    local row = CreateFrame("Frame", nil, list)
    row:SetHeight(ROW_H)
    row.check = CreateFrame("CheckButton", nil, row, "MinimalCheckboxTemplate")
    row.check:SetSize(20, 20)
    row.check:SetPoint("LEFT")
    row.check:SetScript("OnClick", function(self)
        if self:GetChecked() then ns.DB.spells[row.id] = nil else ns.DB.spells[row.id] = false end
        ns.Display.Changed()
    end)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(18, 18)
    row.icon:SetPoint("LEFT", row, "LEFT", 24, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.name = Text(row, NAME_X)
    row.name:SetWidth(TYPE_X - NAME_X - 8)
    row.type = Text(row, TYPE_X, T.muted)
    row.cd = Text(row, CD_X, T.muted)
    row.tag = Text(row, TAG_X, T.muted)
    return row
end

local function Fill(row, e)
    row.id = e.id
    row.check:SetChecked(ns.DB.spells[e.id] ~= false)
    local texture = e.id == "potion" and C_Item.GetItemIconByID(ns.Potions[1].item) or (e.icon and "Interface\\Icons\\" .. e.icon)
    row.icon:SetTexture((issecretvalue(texture) or texture == nil) and QUESTION or texture)
    row.name:SetText(e.name)
    local class = ns.Spells[e.id] and ns.Spells[e.id].class
    if class then row.name:SetTextColor(T.ClassColor(class)) else row.name:SetTextColor(unpack(T.text)) end
    row.type:SetText(ns.LayoutRules.LABELS[e.type] or e.type)
    row.cd:SetText(Duration(e.cd))
    row.tag:SetText(e.untrackable and "not trackable for others" or "")
end

ns.Window.Register("spells", function(page)
    local intro = page:Group("Spells")
    intro:Note("Uncheck a spell to hide it from rows and the panel. \"not trackable for others\": the game gives addons no aura for it, so it shows on your own row only.")

    local tab
    local box = page:Group("By class")
    local tabs, tabsH, paintTabs = Tabs(box, function(class)
        tab = class
        page:Refresh()
    end)
    box:Add(tabs, tabsH, function() paintTabs(tab) end)

    local list = CreateFrame("Frame", nil, box.frame)
    local header = CreateFrame("Frame", nil, list)
    header:SetPoint("TOPLEFT")
    header:SetPoint("RIGHT")
    header:SetHeight(ROW_H)
    Text(header, NAME_X, T.gold):SetText("Spell")
    Text(header, TYPE_X, T.gold):SetText("Type")
    Text(header, CD_X, T.gold):SetText("Cooldown")
    local rows, shown, filled = {}, 0, nil
    box:Add(list, function() return (shown + 1) * ROW_H end, function()
        list:SetSize(math.max(box.frame:GetWidth() - 2 * Widgets.PAD, 1), (shown + 1) * ROW_H)
        if filled == (tab or "All") then return end
        filled = tab or "All"
        local entries = ns.LayoutRules.Catalog(tab)
        if not tab then table.insert(entries, 1, POTION) end
        list:SetHeight((#entries + 1) * ROW_H)
        for i, e in ipairs(entries) do
            local row = rows[i]
            if not row then
                row = NewRow(list)
                row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -i * ROW_H)
                row:SetPoint("RIGHT", list, "RIGHT")
                rows[i] = row
            end
            Fill(row, e)
            row:Show()
        end
        for i = #entries + 1, #rows do rows[i]:Hide() end
        shown = #entries
    end)
end)
