-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Widgets = ns.Widgets
local Rules = ns.WidgetRules
local T = ns.SettingsTheme
local UI = LibStub("LibVelvet-1.0")

local Window = {}

local DEFAULT_W, DEFAULT_H = 860, 560
local MIN_W, MIN_H = 820, 420
local TITLE_H, MENU_W, ENTRY_H, GAP, PAD = 28, 150, 20, 4, 8
local PAGES = {
    { key = "about", label = "What SquadCD does" },
    { key = "presets", label = "Presets and types" },
    { key = "panels", label = "Panels" },
    { key = "members", label = "At party frames" },
    { key = "spells", label = "Spells" },
    { key = "status", label = "Status" },
}

local frame, menu, scroll, host, demo, unlock
local pages, builders, entries = {}, {}, {}
local current

local function Saved()
    return ns.DB.window
end

local function BuildPage(key)
    local page = Widgets.NewPage(host)
    local ok = xpcall(function() builders[key](page) end, function(err) geterrorhandler()(err) end)
    if not ok then page:Fail() end
    pages[key] = page
    return page
end

local function Paint()
    for key, entry in pairs(entries) do
        UI.PaintNav(entry, key == current and "selected" or "normal")
    end
    demo:SetText(ns.Demo.Running() and "Stop demo" or "Demo")
    unlock:SetText(ns.EditMode.Panels() and "Done" or "Move the panels")
end

local function BuildMenu()
    local y = -PAD
    for _, item in ipairs(PAGES) do
        local entry = UI.NavEntry(menu, item.label, MENU_W - 2 * PAD, ENTRY_H)
        entry:SetScript("OnClick", function() Window.Show(item.key) end)
        entry:SetPoint("TOPLEFT", menu, "TOPLEFT", PAD, y)
        entries[item.key] = entry
        y = y - ENTRY_H - GAP
    end
end

local function SavePosition()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local saved = Saved()
    saved.point, saved.relativePoint, saved.x, saved.y = point, relativePoint, x, y
end

local function TitleButton(parent, text, width, anchor, onClick)
    local button = Widgets.Button(parent, text, width)
    button:SetPoint("RIGHT", anchor, anchor == parent and "RIGHT" or "LEFT", anchor == parent and -(TITLE_H - 22) / 2 or -GAP, 0)
    button:SetScript("OnClick", function()
        onClick()
        Window.Refresh()
    end)
    return button
end

local function Build()
    frame = CreateFrame("Frame", "SquadCDSettings", UIParent, "BackdropTemplate")
    tinsert(UISpecialFrames, "SquadCDSettings")
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

    local saved = Saved()
    frame:SetSize(Rules.Size(saved.width, saved.height, MIN_W, MIN_H, DEFAULT_W, DEFAULT_H))
    if saved.point then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    else
        frame:SetPoint("CENTER")
    end

    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT")
    title:SetPoint("TOPRIGHT")
    title:SetHeight(TITLE_H)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() frame:StartMoving() end)
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)
    local name = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", PAD, 0)
    name:SetTextColor(unpack(T.gold))
    name:SetText("SquadCD")

    local close = TitleButton(title, "X", 22, title, function() frame:Hide() end)
    unlock = TitleButton(title, "Move the panels", 110, close, ns.EditMode.TogglePanels)
    demo = TitleButton(title, "Demo", 80, unlock, ns.Demo.Toggle)

    menu = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    menu:SetPoint("TOPLEFT", 0, -TITLE_H)
    menu:SetPoint("BOTTOMLEFT")
    menu:SetWidth(MENU_W)
    menu:SetBackdrop(T.FLAT)
    menu:SetBackdropColor(unpack(T.panel))
    menu:SetBackdropBorderColor(unpack(T.border))

    local signature = menu:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    signature:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", PAD, PAD)
    signature:SetText("|cFF0057B7Made|r |cFFFFD700in Ukraine|r")

    scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll.scrollBarHideable = true
    scroll:SetPoint("TOPLEFT", menu, "TOPRIGHT", PAD, -PAD)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, PAD + 12)
    host = CreateFrame("Frame", nil, scroll)
    host:SetSize(1, 1)
    scroll:SetScrollChild(host)
    scroll:SetScript("OnSizeChanged", function(_, width)
        host:SetWidth(width)
        if current and pages[current] then pages[current]:Refresh() end
    end)

    Widgets.Grip(frame, MIN_W, MIN_H, function()
        local s = Saved()
        s.width, s.height = frame:GetSize()
        SavePosition()
    end)

    BuildMenu()
end

function Window.Register(key, build)
    builders[key] = build
end

function Window.Refresh()
    if not frame or not frame:IsShown() then return end
    Paint()
    if current and pages[current] then pages[current]:Refresh() end
end

function Window.Show(key)
    if not ns.DB then return end
    if ns.Wizard and ns.Wizard.IsOpen() then
        ns.Wizard.Open()
        return
    end
    if not frame then Build() end
    key = key or current or (ns.DB.seenAbout and "presets" or "about")
    ns.DB.seenAbout = true
    if current and pages[current] and current ~= key then
        pages[current].frame:Hide()
    end
    current = key
    local page = pages[key] or BuildPage(key)
    page.frame:Show()
    frame:Show()
    Paint()
    page:Refresh()
    scroll:SetVerticalScroll(0)
end

function Window.Hide()
    if not frame or not frame:IsShown() then return false end
    frame:Hide()
    return true
end

function Window.Toggle()
    if frame and frame:IsShown() then
        frame:Hide()
    else
        Window.Show()
    end
end

ns.Window = Window
ns.ToggleWindow = Window.Toggle
