-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Rules = ns.WidgetRules

local Widgets = {}
local UI = LibStub("LibVelvet-1.0")

-- The settings window's look; anything it lacks (TYPES, ClassColor...) comes from the in-game theme.
ns.SettingsTheme = setmetatable({
    bg = UI.T.bg, panel = UI.T.panel, border = UI.T.border, control = UI.T.control, gold = UI.T.gold,
    text = UI.T.text, muted = UI.T.muted, selected = UI.T.selected, FLAT = UI.FLAT,
}, { __index = ns.Theme })

local T = ns.SettingsTheme
local PAD, GAP, TITLE_H = UI.PAD, UI.GAP, 32
local LABEL_W, CONTROL_W, NOTE_W = 170, 220, 540
Widgets.PAD, Widgets.LABEL_W, Widgets.CONTROL_W = PAD, LABEL_W, CONTROL_W

local function ShowTooltip(owner, spec)
    if not spec.tooltip then return end
    local text = type(spec.tooltip) == "function" and spec.tooltip() or spec.tooltip
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(spec.label or spec.text, 1, 1, 1)
    GameTooltip:AddLine(text, nil, nil, nil, true)
    GameTooltip:Show()
end

local function Hover(region, spec)
    if region.SetMotionScriptsWhileDisabled then region:SetMotionScriptsWhileDisabled(true) end
    region:SetScript("OnEnter", function(self) ShowTooltip(self, spec) end)
    region:SetScript("OnLeave", GameTooltip_Hide)
end

local function HookHover(region, spec)
    region:HookScript("OnEnter", function(self) ShowTooltip(self, spec) end)
    region:HookScript("OnLeave", GameTooltip_Hide)
end

function Widgets.PaintChoice(button, selected)
    button:SetBackdropColor(unpack(selected and T.selected or UI.T.segfill))
    button:SetBackdropBorderColor(unpack(T.control))
    button.label:SetTextColor(unpack(selected and UI.T.selLabel or T.text))
    if not button.underline then
        button.underline = button:CreateTexture(nil, "ARTWORK")
        button.underline:SetPoint("BOTTOMLEFT", 1, 1)
        button.underline:SetPoint("BOTTOMRIGHT", -1, 1)
        button.underline:SetHeight(2)
        button.underline:SetColorTexture(unpack(UI.T.underline))
    end
    button.underline:SetShown(selected and true or false)
end

function Widgets.Button(parent, text, width)
    return UI.Button(parent, text, width)
end

function Widgets.SpellTooltip(owner, id)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if id == "potion" then
        GameTooltip:SetItemByID(ns.Potions[1].item)
    else
        GameTooltip:SetSpellByID(id)
    end
    GameTooltip:Show()
end

function Widgets.Grip(frame, minW, minH, onDone)
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    -- The grip sizes the window itself instead of StartSizing, which in CastAhead's identical
    -- window now and then set a size of its own on the first frame and ran off under the cursor.
    grip:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local left, top = frame:GetLeft(), frame:GetTop()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        local scale = frame:GetEffectiveScale()
        local x0, y0 = GetCursorPosition()
        local w0, h0 = frame:GetSize()
        local maxW = UIParent:GetWidth() * UIParent:GetEffectiveScale() / scale - left
        self:SetScript("OnUpdate", function(grabbed)
            if not IsMouseButtonDown("LeftButton") then
                grabbed:GetScript("OnMouseUp")(grabbed)
                return
            end
            local x, y = GetCursorPosition()
            frame:SetSize(Rules.GripSize(w0, h0, (x - x0) / scale, (y0 - y) / scale, minW, minH, maxW, top))
        end)
    end)
    grip:SetScript("OnMouseUp", function(self)
        if not self:GetScript("OnUpdate") then return end
        self:SetScript("OnUpdate", nil)
        if onDone then onDone() end
    end)
end

local Group = {}
Group.__index = Group

function Group:Add(frame, height, refresh, visible)
    self.items[#self.items + 1] = { frame = frame, height = height, refresh = refresh, visible = visible }
end

function Group:Check(spec)
    local group = self
    local check = UI.Checkbox(self.frame, 22)
    check.text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.text:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check.text:SetText(spec.label)
    check:SetHitRectInsets(0, -(check.text:GetStringWidth() + 6), 0, 0)
    check:SetScript("OnClick", function(self)
        spec.set(self:GetChecked() and true or false)
        group.page:Refresh()
    end)
    Hover(check, spec)
    self:Add(check, 24, function()
        check:SetChecked(spec.get() and true or false)
    end, spec.visible)
end

function Group:Slider(spec)
    local holder = CreateFrame("Frame", nil, self.frame)
    holder:SetSize(LABEL_W + CONTROL_W, 22)
    holder:EnableMouse(true)
    Hover(holder, spec)
    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT")
    label:SetWidth(LABEL_W - 8)
    label:SetJustifyH("LEFT")
    local slider = UI.Slider(holder, CONTROL_W)
    slider:SetPoint("LEFT", holder, "LEFT", LABEL_W, 0)
    local format = spec.format or "%d"
    local function Caption(value)
        label:SetText(spec.label .. ": " .. format:format(value))
    end
    HookHover(slider.widget, spec)
    slider:Setup(spec.min, spec.max, spec.step or 1)
    slider.onChange = function(value)
        spec.set(value)
        Caption(value)
    end
    self:Add(holder, 24, function()
        slider:SetValue(spec.get(), true)
        Caption(slider:GetValue())
    end, spec.visible)
end

function Group:Segmented(spec)
    local group = self
    local holder = CreateFrame("Frame", nil, self.frame)
    local count = #spec.options
    local controlW = spec.width or CONTROL_W
    holder:SetSize(LABEL_W + controlW, 22)
    holder:EnableMouse(true)
    Hover(holder, spec)
    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT")
    label:SetWidth(LABEL_W - 8)
    label:SetJustifyH("LEFT")
    label:SetText(spec.label)
    local set = UI.Segments(holder, spec.options, controlW, 22, function(value)
        spec.set(value)
        group.page:Refresh()
    end)
    set:SetPoint("LEFT", holder, "LEFT", LABEL_W, 0)
    if spec.note then
        local note = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("LEFT", holder, "LEFT", LABEL_W + controlW + 10, 0)
        note:SetPoint("RIGHT", self.frame, "RIGHT", -PAD, 0)
        note:SetJustifyH("LEFT")
        note:SetTextColor(unpack(T.muted))
        note:SetText(spec.note)
    end
    self:Add(holder, 22, function()
        set:Select(spec.get())
    end, spec.visible)
end

function Group:Button(spec)
    local group = self
    local button = Widgets.Button(self.frame, spec.text or spec.label, spec.width or 180)
    button:SetScript("OnClick", function()
        spec.onClick()
        group.page:Refresh()
    end)
    Hover(button, spec)
    self:Add(button, 22, nil, spec.visible)
end

function Group:Note(spec)
    if type(spec) ~= "table" then spec = { text = spec } end
    local box = self.frame
    local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetWidth(NOTE_W)
    text:SetJustifyH("LEFT")
    text:SetSpacing(2)
    text:SetTextColor(unpack(spec.color or T.muted))
    text:SetText(type(spec.text) == "function" and "" or spec.text)
    self:Add(text, function()
        if type(spec.text) == "function" then text:SetText(spec.text()) end
        local room = (box:GetWidth() or 0) - 2 * PAD
        text:SetWidth(room > 100 and math.min(NOTE_W, room) or NOTE_W)
        return text:GetStringHeight()
    end, nil, spec.visible)
end

local Page = {}
Page.__index = Page

function Widgets.NewPage(host)
    local frame = CreateFrame("Frame", nil, host)
    frame:SetPoint("TOPLEFT")
    frame:SetPoint("TOPRIGHT")
    frame:SetHeight(1)
    frame:Hide()
    return setmetatable({ frame = frame, groups = {} }, Page)
end

function Page:Group(title)
    local box = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT")
    box:SetPoint("RIGHT", self.frame, "RIGHT", -PAD, 0)
    box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    box.title:SetPoint("TOPLEFT", PAD, -8)
    box.title:SetText(type(title) == "string" and title or "")
    UI.PaintGroup(box, title and title ~= "" and box.title or nil)
    local group = setmetatable({ page = self, frame = box, items = {}, visible = self.visible, title = title }, Group)
    self.groups[#self.groups + 1] = group
    return group
end

local function Height(item)
    return type(item.height) == "function" and item.height() or item.height
end

local function LayoutGroup(group)
    local heights = {}
    for index, item in ipairs(group.items) do
        local shown = not item.visible or item.visible()
        item.frame:SetShown(shown)
        if shown and item.refresh then item.refresh() end
        heights[index] = { height = Height(item), shown = shown }
    end
    local offsets, total = Rules.Stack(heights, GAP)
    for index, item in ipairs(group.items) do
        if offsets[index] then
            item.frame:ClearAllPoints()
            item.frame:SetPoint("TOPLEFT", group.frame, "TOPLEFT", PAD, -(TITLE_H + offsets[index]))
        end
    end
    return TITLE_H + total + PAD
end

function Page:Refresh()
    local blocks = {}
    for index, group in ipairs(self.groups) do
        local shown = not group.visible or group.visible()
        group.frame:SetShown(shown)
        if shown and type(group.title) == "function" then group.frame.title:SetText(group.title()) end
        local height = shown and LayoutGroup(group) or nil
        group.frame:SetHeight(height or 1)
        blocks[index] = { height = height or 0, shown = shown }
    end
    local offsets, total = Rules.Stack(blocks, PAD)
    for index, group in ipairs(self.groups) do
        group.offset = offsets[index]
        if offsets[index] then
            group.frame:ClearAllPoints()
            group.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -offsets[index])
            group.frame:SetPoint("RIGHT", self.frame, "RIGHT", -PAD, 0)
        end
    end
    self.frame:SetHeight(math.max(total, 1))
    self.frame:GetParent():SetHeight(math.max(total, 1))
end

function Page:Find(key)
    for _, group in ipairs(self.groups) do
        if group.key == key then return group end
    end
end

function Page:Fail()
    for _, group in ipairs(self.groups) do
        group.frame:Hide()
    end
    self.groups = {}
    self.visible = nil
    self:Group("This page failed to build"):Note("The error is in the error log (BugSack). Every other page still works.")
end

ns.Widgets = Widgets
