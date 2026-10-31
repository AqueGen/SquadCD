-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Wizard = {}
ns.Wizard = Wizard

local T = ns.SettingsTheme
local Widgets = ns.Widgets
local Parts = ns.LayoutParts

local DEFAULT_W, DEFAULT_H, MIN_W, MIN_H = 760, 600, 660, 420
local TITLE_H, HEAD_H, FOOT_H, PAD = 28, 54, 40, 8
local SIZES = { { value = 22, text = "Small" }, { value = 26, text = "Medium" }, { value = 32, text = "Large" } }
local STEPS = {
    { title = "Preset", hint = "A starting point for the whole layout. Every choice can be changed later in the SquadCD settings (/squadcd)." },
    { title = "Types and order", hint = "Panel, next to each party frame, or off, and the order of the types." },
    { title = "Size and position", hint = "How big the panel icons are, and where the panels sit on screen." },
}

local held = ns.Preview.New()
local frame, scroll, host, stepTitle, stepHint, stepText, back, nextButton, finish
local pages, builders = {}, {}
local current, wanted, keep, reopen = 1, false, false, false

local function editing()
    return ns.EditMode.Panels() or ns.EditMode.Members()
end

local function close(kept)
    keep = kept
    frame:Hide()
end

local function seeIt(page)
    local group = page:Group("See it on screen")
    Parts.Demo(group)
    group:Note({
        text = "No party? Set the demo to Whole group to see your choices on screen.",
        visible = function() return not ns.Display.HasMembers() and not ns.Demo.Running() end,
    })
end

builders[1] = function(page)
    seeIt(page)
    local group = page:Group("Presets")
    group:Note("Click a preset to use it as the starting point. Cancel puts back the layout you had before the wizard.")
    Parts.PresetCards(group, {
        pick = function(n)
            Parts.Edit(ns.LayoutModel.ApplyPreset, n)
            page:Refresh()
        end,
        used = function() return ns.DB.layout.preset end,
    })
end

builders[2] = function(page)
    seeIt(page)
    Parts.TypesTable(page)
end

local function nearest(size)
    local best = SIZES[1].value
    for _, s in ipairs(SIZES) do
        if math.abs(s.value - size) < math.abs(best - size) then best = s.value end
    end
    return best
end

builders[3] = function(page)
    seeIt(page)
    local size = page:Group("Size")
    size:Segmented({
        label = "Panel icon size", options = SIZES,
        get = function() return nearest(ns.DB.layout.panelLook.iconSize) end,
        set = function(v) Parts.Edit(function(layout) layout.panelLook.iconSize = v end) end,
    })
    size:Note("Exact sizes, and the icons at party frames, are on the Panels and At party frames pages.")
    local position = page:Group("Position")
    position:Note("Move the panels closes the wizard, keeps your choices and outlines every panel. Drag a panel where you want it, then click Done.")
    position:Button({
        text = "Move the panels", width = 140,
        onClick = function()
            if InCombatLockdown() then
                ns.EditMode.StartPanels()
                return
            end
            reopen = false
            close(true)
            ns.EditMode.StartPanels()
        end,
    })
    position:Note("Icons at party frames follow your party frames.")
end

local function buildPage(step)
    local page = Widgets.NewPage(host)
    local ok = xpcall(function() builders[step](page) end, function(err) geterrorhandler()(err) end)
    if not ok then page:Fail() end
    pages[step] = page
    return page
end

local function showStep(step)
    current = step
    for k, page in pairs(pages) do
        if k ~= step then page.frame:Hide() end
    end
    local page = pages[step] or buildPage(step)
    stepTitle:SetText(STEPS[step].title)
    stepHint:SetText(STEPS[step].hint)
    stepText:SetText(("Step %d of %d"):format(step, #STEPS))
    back:SetEnabled(step > 1)
    back:SetAlpha(step > 1 and 1 or 0.35)
    nextButton:SetShown(step < #STEPS)
    finish:SetShown(step == #STEPS)
    page.frame:Show()
    page:Refresh()
    scroll:SetVerticalScroll(0)
end

local function build()
    frame = CreateFrame("Frame", "SquadCDWizard", UIParent, "BackdropTemplate")
    tinsert(UISpecialFrames, "SquadCDWizard")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop(T.FLAT)
    frame:SetBackdropColor(unpack(T.bg))
    frame:SetBackdropBorderColor(unpack(T.border))
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_W, MIN_H)
    frame:EnableMouse(true)
    frame:SetSize(DEFAULT_W, DEFAULT_H)
    frame:SetPoint("CENTER")

    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT")
    title:SetPoint("TOPRIGHT")
    title:SetHeight(TITLE_H)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() frame:StartMoving() end)
    title:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local name = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", PAD, 0)
    name:SetTextColor(unpack(T.gold))
    name:SetText("SquadCD - Layout wizard")
    local x = Widgets.Button(title, "X", 22)
    x:SetPoint("RIGHT", title, "RIGHT", -(TITLE_H - 22) / 2, 0)
    x:SetScript("OnClick", function() close(false) end)
    stepText = title:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    stepText:SetPoint("RIGHT", x, "LEFT", -PAD, 0)
    stepText:SetTextColor(unpack(T.muted))

    stepTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    stepTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + 2, -(TITLE_H + 6))
    stepTitle:SetTextColor(unpack(T.gold))
    stepHint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    stepHint:SetPoint("TOPLEFT", stepTitle, "BOTTOMLEFT", 0, -6)
    stepHint:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    stepHint:SetJustifyH("LEFT")
    stepHint:SetTextColor(unpack(T.muted))

    scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll.scrollBarHideable = true
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -(TITLE_H + HEAD_H))
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, FOOT_H)
    host = CreateFrame("Frame", nil, scroll)
    host:SetSize(1, 1)
    scroll:SetScrollChild(host)
    scroll:SetScript("OnSizeChanged", function(_, width)
        host:SetWidth(width)
        if pages[current] then pages[current]:Refresh() end
    end)

    local cancel = Widgets.Button(frame, "Cancel", 80)
    cancel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD + 1)
    cancel:SetScript("OnClick", function() close(false) end)
    local signature = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    signature:SetPoint("LEFT", cancel, "RIGHT", 12, 0)
    signature:SetText("|cFF0057B7Made|r |cFFFFD700in Ukraine|r")
    finish = Widgets.Button(frame, "Finish", 80)
    finish:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, PAD + 1)
    finish:SetScript("OnClick", function() close(true) end)
    nextButton = Widgets.Button(frame, "Next", 80)
    nextButton:SetPoint("BOTTOMRIGHT", finish, "BOTTOMRIGHT")
    nextButton:SetScript("OnClick", function() showStep(current + 1) end)
    back = Widgets.Button(frame, "Back", 80)
    back:SetPoint("RIGHT", finish, "LEFT", -6, 0)
    back:SetScript("OnClick", function() showStep(current - 1) end)
    Widgets.Grip(frame, MIN_W, MIN_H)

    frame:SetScript("OnHide", function(self)
        if self:IsShown() then return end
        if keep then
            held.Apply()
        elseif held.Cancel(ns.DB) then
            ns.Display.Changed()
        end
        keep = false
        if reopen then
            reopen = false
            C_Timer.After(0, function()
                if not Wizard.IsOpen() then ns.Window.Show() end
            end)
        end
    end)
end

function Wizard.Show()
    if not frame then build() end
    reopen = ns.Window.Hide()
    if ns.Preview.Cancel(ns.DB) then ns.Display.Changed() end
    held.Hold(ns.DB)
    keep = false
    frame:Show()
    showStep(1)
end

function Wizard.IsOpen()
    return frame ~= nil and frame:IsShown()
end

local function try()
    if not wanted or not ns.DB or InCombatLockdown() or editing() then return end
    wanted = false
    Wizard.Show()
    ns.DB.wizardDue = nil
end

function Wizard.Open()
    if Wizard.IsOpen() then
        frame:Raise()
        return
    end
    if editing() then
        print("SquadCD: finish the edit mode first (Done), then open the layout wizard.")
        return
    end
    wanted = true
    if InCombatLockdown() then print("SquadCD: the layout wizard opens when combat ends.") end
    try()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then
        if ns.DB then held.Cancel(ns.DB) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if ns.DB and ns.DB.wizardDue then wanted = true end
        C_Timer.After(0, try)
    else
        try()
    end
end)
