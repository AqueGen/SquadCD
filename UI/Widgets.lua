local _, ns = ...

local Rules = ns.WidgetRules

local Widgets = {}

local T = ns.Theme
local PAD, GAP, TITLE_H = 10, 6, 26
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
    button:SetBackdropColor(unpack(selected and T.selected or T.panel))
    button:SetBackdropBorderColor(unpack(selected and T.gold or T.control))
    button.label:SetTextColor(unpack(selected and T.gold or T.text))
end

function Widgets.Button(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 22)
    button:SetBackdrop(T.FLAT)
    button:SetBackdropColor(unpack(T.panel))
    button:SetBackdropBorderColor(unpack(T.control))
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("CENTER")
    button.label:SetTextColor(unpack(T.text))
    button:SetFontString(button.label)
    button:SetText(text)
    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.06)
    return button
end

local Group = {}
Group.__index = Group

function Group:Add(frame, height, refresh, visible)
    self.items[#self.items + 1] = { frame = frame, height = height, refresh = refresh, visible = visible }
end

function Group:Check(spec)
    local group = self
    local check = CreateFrame("CheckButton", nil, self.frame, "MinimalCheckboxTemplate")
    check:SetSize(22, 22)
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
    local slider = CreateFrame("Frame", nil, holder, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("LEFT", holder, "LEFT", LABEL_W, 0)
    slider:SetSize(CONTROL_W, 19)
    local step, format = spec.step or 1, spec.format or "%d"
    local suppress = false
    local function Caption(value)
        label:SetText(spec.label .. ": " .. format:format(value))
    end
    HookHover(slider.Slider, spec)
    slider:Init(spec.get(), spec.min, spec.max, (spec.max - spec.min) / step, {})
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if suppress then return end
        value = spec.min + math.floor((value - spec.min) / step + 0.5) * step
        value = tonumber(("%.4f"):format(value))
        spec.set(value)
        Caption(value)
    end, holder)
    self:Add(holder, 24, function()
        local value = spec.get()
        suppress = true
        slider:SetValue(value)
        suppress = false
        Caption(value)
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
    local width = math.floor((controlW + count - 1) / count)
    local last = controlW - (count - 1) * (width - 1)
    local buttons = {}
    for index, option in ipairs(spec.options) do
        local button = Widgets.Button(holder, option.text, index == count and last or width)
        button:SetPoint("LEFT", holder, "LEFT", LABEL_W + (index - 1) * (width - 1), 0)
        button.value = option.value
        button:SetScript("OnClick", function(self)
            spec.set(self.value)
            group.page:Refresh()
        end)
        buttons[index] = button
    end
    if spec.note then
        local note = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("LEFT", holder, "LEFT", LABEL_W + controlW + 10, 0)
        note:SetTextColor(unpack(T.muted))
        note:SetText(spec.note)
    end
    self:Add(holder, 22, function()
        local current = spec.get()
        for _, button in ipairs(buttons) do
            Widgets.PaintChoice(button, button.value == current)
        end
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
    text:SetTextColor(unpack(spec.color or T.muted))
    text:SetText(type(spec.text) == "function" and "" or spec.text)
    -- Wraps to the box on a narrow window, never wider than a comfortable line
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
    box:SetBackdrop(T.FLAT)
    box:SetBackdropColor(unpack(T.panel))
    box:SetBackdropBorderColor(unpack(T.border))
    -- Anchored from the start so notes measure the box's width on the page's first layout
    box:SetPoint("TOPLEFT")
    box:SetPoint("RIGHT", self.frame, "RIGHT", -PAD, 0)
    box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    box.title:SetPoint("TOPLEFT", PAD, -8)
    box.title:SetTextColor(unpack(T.gold))
    box.title:SetText(title or "")
    local group = setmetatable({ page = self, frame = box, items = {}, visible = self.visible }, Group)
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
        local height = shown and LayoutGroup(group) or nil
        group.frame:SetHeight(height or 1)
        blocks[index] = { height = height or 0, shown = shown }
    end
    local offsets, total = Rules.Stack(blocks, PAD)
    for index, group in ipairs(self.groups) do
        if offsets[index] then
            group.frame:ClearAllPoints()
            group.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -offsets[index])
            group.frame:SetPoint("RIGHT", self.frame, "RIGHT", -PAD, 0)
        end
    end
    self.frame:SetHeight(math.max(total, 1))
    self.frame:GetParent():SetHeight(math.max(total, 1))
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
