-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local PanelPreview = {}
ns.PanelPreview = PanelPreview

local INTERVAL = 0.1
local MEMBERS = 5
local CAPTION = "Preview: the Demo party, 5 members"
local EMPTY = "The panel is empty: every type is off, hidden or at party frames."

local pane, host, panel, source
local listening = false
local elapsed = 0
local sight = { live = false, plain = true, secret = {} }

local function update()
    sight.timers = ns.DB.layout.timers
    panel.Update(source.tracker, GetTime(), sight)
end

local function tick(_, dt)
    elapsed = elapsed + dt
    if elapsed < INTERVAL then return end
    elapsed = 0
    update()
end

function PanelPreview.Stop()
    if pane then pane:SetScript("OnUpdate", nil) end
end

function PanelPreview.Attach(target)
    if pane == target then return end
    PanelPreview.Stop()
    pane = target
    host = CreateFrame("Frame", nil, pane.stage)
    panel = ns.Panel.New({ parent = host })
    pane:SetCaption(CAPTION)
    pane:HookScript("OnHide", PanelPreview.Stop)
    if not listening then
        listening = true
        ns.Display.OnChanged(PanelPreview.Refresh)
    end
end

function PanelPreview.Refresh()
    if not pane or not pane:IsShown() then return end
    source = ns.Demo.Source(MEMBERS)
    local lines = ns.Display.Lines(source.members)
    local w, h = panel.Build(lines)
    if #lines == 0 then
        PanelPreview.Stop()
        pane:SetOff(EMPTY)
        return
    end
    host:SetSize(w, h)
    pane:SetOff(nil)
    pane:Fit(host, w, h)
    update()
    elapsed = 0
    pane:SetScript("OnUpdate", tick)
end
