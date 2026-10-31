-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Persist = {}
ns.Persist = Persist

function Persist.Save(tracker)
    ns.DB.timers = tracker:Snapshot(GetServerTime(), GetTime())
end

function Persist.Load(tracker)
    Persist.tracker = tracker
    tracker:Restore(ns.DB.timers, GetServerTime(), GetTime())
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function()
    if Persist.tracker and ns.DB then
        Persist.Save(Persist.tracker)
    end
end)
