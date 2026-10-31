-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Profiles = ns.Profiles

local Switch = {}
ns.ProfileSwitch = Switch

local RETRY = 1
local waiting = false

local function character()
    return (UnitName("player") or "?") .. "-" .. (GetNormalizedRealmName() or "?")
end

function Switch.KeyOf(specId)
    return Profiles.Key(character(), specId)
end

function Switch.CurrentSpec()
    local index = GetSpecialization and GetSpecialization()
    return index and GetSpecializationInfo(index) or nil
end

-- id, name per spec of the player's class, in the game's order.
function Switch.Specs()
    local list = {}
    for i = 1, (GetNumSpecializations and GetNumSpecializations() or 0) do
        local id, name = GetSpecializationInfo(i)
        if id then list[#list + 1] = { id = id, name = name } end
    end
    return list
end

local function busy()
    return ns.EditMode.Panels() or ns.EditMode.Members()
end

function Switch.Use(name)
    if busy() then
        if not waiting then
            waiting = true
            print("SquadCD: profile " .. name .. " applies after the edit mode is done.")
        end
        C_Timer.After(RETRY, function() Switch.Use(name) end)
        return
    end
    waiting = false
    if ns.Preview.Cancel(ns.DB) then ns.Display.Changed() end
    if Profiles.Switch(ns.DB, name) then
        ns.Display.Changed()
        ns.Window.Refresh()
    end
end

function Switch.UseSpecProfile()
    local spec = Switch.CurrentSpec()
    if spec then Switch.Use(Profiles.ForSpec(ns.DB, Switch.KeyOf(spec))) end
end

function Switch:Enable()
    local events = CreateFrame("Frame")
    events:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    events:RegisterEvent("PLAYER_LOGOUT")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGOUT" then
            Profiles.Pack(ns.DB)
        else
            Switch.UseSpecProfile()
        end
    end)
    Switch.UseSpecProfile()
end

ns.RegisterModule("ProfileSwitch", Switch)

ns.Slash("profile", function(name)
    if name == "" then
        print("SquadCD: profile " .. ns.DB.profile .. ". Profiles: " .. table.concat(Profiles.Names(ns.DB), ", "))
    elseif ns.DB.profiles[name] then
        Switch.Use(name)
    else
        print("SquadCD: no profile named " .. name .. ".")
    end
end)
