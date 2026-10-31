-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Probes = {}
ns.Probes = Probes

local INSET = 1e5
local STRIDE = 50000
local PROBE_X = -11

local host

local function initElement(b)
    pcall(b.SetSize, b, 1, 1)
    pcall(b.SetMouseClickEnabled, b, false)
    pcall(b.SetMouseMotionEnabled, b, false)
end

-- The engine lays a present aura out as one STRIDE-wide element and resizes the probe to fit it,
-- so the probe reaches across the screen only while the aura is up; the hit-test answers that as a secret boolean.
function Probes.New(unit, filter, ids)
    if not host then
        host = CreateFrame("Frame", nil, UIParent)
        host:SetPoint("TOPLEFT", UIParent, "TOPLEFT", PROBE_X, 0)
        host:SetSize(1, 1)
        host:EnableMouse(false)
    end
    local ok, f = pcall(CreateFrame, "AuraContainer", nil, host, "CustomAuraContainerTemplate")
    if not ok or not f then return nil, "AuraContainer unavailable: " .. tostring(f) end
    local set = {}
    for _, id in ipairs(ids) do set[id] = true end
    local okSetup, err = pcall(function()
        f:SetSize(1, 1)
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", PROBE_X, 0)
        f:EnableMouse(false)
        f:AddAuraGroup("a", filter, {
            maxFrameCount = 1,
            candidateFilters = { includeSpellIDs = set },
            initializeFrame = initElement,
            layout = { elementWidth = STRIDE, elementHeight = 1 },
        })
        f:SetUnit(unit)
        f:SetEnabled(true)
    end)
    if not okSetup then return nil, "aura group setup failed: " .. tostring(err) end
    return f
end

function Probes.Lit(p)
    return p:IsMouseOver(INSET, -INSET, 0, 0)
end

function Probes.Point(p, unit)
    pcall(p.SetUnit, p, unit)
end

function Probes.Enable(p, on)
    pcall(p.SetEnabled, p, on)
end
